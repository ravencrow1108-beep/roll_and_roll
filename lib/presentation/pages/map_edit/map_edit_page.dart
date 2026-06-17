import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../create_save/create_save_page.dart';
import '../adventure/adventure_page.dart';
import '../map_editor/map_editor_page.dart';

/// 主持地图编辑页面：选择地图、查看详情并等待所有玩家准备后开始布置
class MapEditPage extends StatefulWidget {
  const MapEditPage({
    required this.playerName,
    required this.role,
    this.saveFilePath,
    super.key,
  });

  final String playerName;
  final String role;
  final String? saveFilePath;

  @override
  State<MapEditPage> createState() => _MapEditPageState();
}

class _MapEditPageState extends State<MapEditPage> {
  MapData? _selectedMap;
  String? _saveFilePath;
  String _saveFileName = '未选择';
  List<MapData> _loadedMaps = [];
  List<PlayerPosition> _loadedPositions = [];
  List<CharacterData> _loadedCharacters = [];

  bool _isReady = false;
  bool _hasStarted = false;

  StreamSubscription<String>? _msgSub;

  @override
  void initState() {
    super.initState();
    _saveFilePath = (widget.saveFilePath?.isEmpty ?? true)
        ? null
        : widget.saveFilePath;
    if (_saveFilePath != null) {
      _saveFileName = _saveFilePath!.split('/').last.split('\\').last;
      _loadSaveData();
    }

    // Listen for player_ready messages
    final server = RoomSession.instance.serverHandle;
    if (server != null) {
      _msgSub = server.messages.listen(_handleMessage);
    }

    RoomSession.instance.readyMembersNotifier.addListener(_onReadyChanged);
    RoomSession.instance.startAdventureNotifier.addListener(_onAdventureEnded);
  }

  void _onReadyChanged() {
    if (mounted) setState(() {});
  }

  void _onAdventureEnded() {
    if (!RoomSession.instance.startAdventureNotifier.value && mounted) {
      setState(() {
        _hasStarted = false;
        _isReady = false;
      });
    }
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message.trim()) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      if (type == 'player_ready') {
        final name = data['name'] as String? ?? '';
        RoomSession.instance.onPlayerReady(name);
        _checkAllReady();
      }
    } catch (_) {}
  }

  /// Check if all non-host members are ready, and if so, start adventure directly.
  void _checkAllReady() {
    final session = RoomSession.instance;
    final allMembers = session.membersNotifier.value;
    final readyMembers = session.readyMembersNotifier.value;

    final nonHost = allMembers
        .where((m) => m != session.hostNameNotifier.value)
        .toList();
    if (nonHost.isEmpty && _selectedMap != null && !_hasStarted) {
      // 仅房主一人，直接开始冒险
      _hasStarted = true;
      _startAdventureDirectly();
      return;
    }

    final allReady = nonHost.every((m) => readyMembers.contains(m));
    if (allReady && _selectedMap != null && !_hasStarted) {
      _hasStarted = true;
      _startAdventureDirectly();
    }
  }

  /// 直接从存档读取角色位置并开始冒险
  Future<void> _startAdventureDirectly() async {
    final session = RoomSession.instance;
    session.mapNotifier.value = _selectedMap;
    session.startAdventureNotifier.value = true;

    // 从存档加载玩家位置
    List<PlayerPosition> positions = [];
    if (_saveFilePath != null) {
      try {
        final save = await SaveData.fromZip(_saveFilePath!);
        positions = save.playerPositions;
      } catch (_) {}
    }
    session.playerPositionsNotifier.value = positions;

    session.broadcast({
      'type': 'adventure_started',
      'map': _selectedMap!.toJson(),
      'positions': positions.map((p) => p.toJson()).toList(),
    });

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdventurePage(
          playerName: widget.playerName,
          role: widget.role,
          saveFilePath: _saveFilePath,
        ),
      ),
    );
  }

  Future<void> _loadSaveData() async {
    if (_saveFilePath == null) return;
    try {
      final save = await SaveData.fromZip(_saveFilePath!);
      _loadedMaps = save.maps;
      _loadedPositions = save.playerPositions;
      _loadedCharacters = save.characters;
    } catch (_) {
      _loadedMaps = [];
      _loadedPositions = [];
      _loadedCharacters = [];
    }
    setState(() {});
  }

  Future<void> _pickSaveFile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择存档文件',
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _saveFilePath = result.files.single.path!;
      _saveFileName = result.files.single.name;
      _selectedMap = null;
      _isReady = false;
    });
    _loadSaveData();
  }

  void _selectMap(MapData m) {
    setState(() => _selectedMap = m);
  }

  Future<void> _editMap(MapData m, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapEditorPage(
          mapData: m,
          onSave: (updated) {
            setState(() {
              _loadedMaps[index] = updated;
              if (_selectedMap?.name == m.name) {
                _selectedMap = updated;
              }
            });
            _saveMapUpdate(updated, index);
          },
          saveFilePath: _saveFilePath,
        ),
      ),
    );
  }

  Future<void> _saveMapUpdate(MapData updated, int index) async {
    if (_saveFilePath == null) return;
    final save = await SaveData.fromZip(_saveFilePath!);
    final newMaps = List<MapData>.from(save.maps);
    if (index < newMaps.length) {
      newMaps[index] = updated;
    }
    final newSave = SaveData(
      createdAt: save.createdAt,
      characters: save.characters,
      maps: newMaps,
      items: save.items,
      rules: save.rules,
      playerPositions: save.playerPositions,
    );
    await newSave.packToZip(_saveFilePath!);
    _loadSaveData();
  }

  Future<void> _navigateToCreateSave() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateSavePage(allowMapEdit: true),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _saveFilePath = result;
        _saveFileName = result.split('/').last.split('\\').last;
        _selectedMap = null;
        _isReady = false;
      });
      _loadSaveData();
    }
  }

  void _markReady() {
    setState(() => _isReady = true);
    _checkAllReady();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    RoomSession.instance.readyMembersNotifier.removeListener(_onReadyChanged);
    RoomSession.instance.startAdventureNotifier.removeListener(
      _onAdventureEnded,
    );
    super.dispose();
  }

  /// 根据已选地图切换显示地图详情或选择列表
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── 已选定地图 → 地图详情 + 准备状态 ──
    if (_selectedMap != null) {
      return _buildMapView(theme);
    }

    // ── 地图选择页 ──
    return _buildMapSelection(theme);
  }

  /// 构建地图详情视图 — 大图预览 + 角色位置标记 + 准备就绪按钮
  Widget _buildMapView(ThemeData theme) {
    final m = _selectedMap!;
    // 有位置记录就用位置，否则给每个角色分配默认位置（均匀排列）
    List<PlayerPosition> positionsForMap;
    if (_loadedPositions.isNotEmpty) {
      positionsForMap = _loadedPositions.toList();
    } else if (_loadedCharacters.isNotEmpty) {
      final count = _loadedCharacters.length;
      final spacing = 0.8 / (count + 1);
      positionsForMap = List.generate(count, (i) {
        return PlayerPosition(
          name: _loadedCharacters[i].name,
          x: spacing * (i + 1) + 0.1,
          y: 0.5,
        );
      });
    } else {
      positionsForMap = [];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(m.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedMap = null),
        ),
      ),
      body: Column(
        children: [
          // ── 大地图预览（填满剩余空间） ──
          Expanded(
            child: _MapPreview(mapData: m, positions: positionsForMap),
          ),
          // ── 底部信息栏 ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${m.width}×${m.height} · ${m.unit}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (m.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    m.description,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (positionsForMap.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: positionsForMap
                        .map((p) => _positionChip(p, theme))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                _buildReadyStatus(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isReady ? null : _markReady,
                    icon: Icon(
                      _isReady
                          ? Icons.check_circle
                          : Icons.rocket_launch_outlined,
                    ),
                    label: Text(
                      _isReady ? '已准备，等待所有玩家…' : '开始冒险',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _positionChip(PlayerPosition p, ThemeData theme) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final color = colors[p.name.hashCode.abs() % colors.length];
    final char = _loadedCharacters.isNotEmpty
        ? _loadedCharacters.cast<CharacterData?>().firstWhere(
            (c) => c?.name == p.name,
            orElse: () => null,
          )
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (char?.portraitBase64 != null && char!.portraitBase64.isNotEmpty)
            ClipOval(
              child: Image.memory(
                base64Decode(char.portraitBase64),
                width: 18,
                height: 18,
                fit: BoxFit.cover,
              ),
            )
          else
            Icon(Icons.person_pin_circle, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            p.name,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${p.x}, ${p.y})',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// 构建地图选择列表与存档加载界面
  Widget _buildMapSelection(ThemeData theme) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          RoomSession.instance.broadcast({'type': 'return_to_room'});
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('选择地图'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              RoomSession.instance.broadcast({'type': 'return_to_room'});
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主持模式 · ${widget.playerName}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ── 存档选择 ──
                Text(
                  '从存档中选择地图',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.save_outlined),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_saveFileName)),
                              IconButton(
                                icon: const Icon(Icons.save_as_outlined),
                                tooltip: '另存为',
                                onPressed: _pickSaveFile,
                              ),
                              IconButton(
                                icon: const Icon(Icons.folder_open),
                                tooltip: '选择存档文件',
                                onPressed: _pickSaveFile,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── 已加载的地图列表 ──
                if (_loadedMaps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _loadedMaps.length,
                      itemBuilder: (_, i) {
                        final m = _loadedMaps[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: const Icon(
                                Icons.map_outlined,
                                color: Colors.teal,
                              ),
                            ),
                            title: Text(
                              m.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${m.width}×${m.height} · ${m.description.isNotEmpty ? m.description : "无描述"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: '编辑地图',
                                  onPressed: () => _editMap(m, i),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            onTap: () => _selectMap(m),
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (_saveFilePath != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '该存档中没有地图',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],

                const SizedBox(height: 24),

                // ── 创建 / 编辑地图 ──
                Text(
                  '或创建 / 编辑地图',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _navigateToCreateSave,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text(
                      '创建 / 编辑地图 (打开创建存档)',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建玩家准备状态指示面板
  Widget _buildReadyStatus() {
    final session = RoomSession.instance;
    final allMembers = session.membersNotifier.value;
    final readyMembers = session.readyMembersNotifier.value;
    final hostName = session.hostNameNotifier.value;
    final players = allMembers.where((m) => m != hostName).toList();

    if (players.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              Text('暂无玩家加入', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '玩家准备状态',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...players.map((name) {
              final ready = readyMembers.contains(name);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      ready ? Icons.check_circle : Icons.hourglass_empty,
                      size: 18,
                      color: ready ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(name),
                    const SizedBox(width: 8),
                    Text(
                      ready ? '已准备' : '未准备',
                      style: TextStyle(
                        color: ready ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 大地图预览组件：可缩放平移 + 角色位置标记
class _MapPreview extends StatefulWidget {
  const _MapPreview({required this.mapData, required this.positions});

  final MapData mapData;
  final List<PlayerPosition> positions;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  Size? _naturalSize;
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _decodeSize();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _decodeSize() async {
    final b64 = widget.mapData.imageBase64;
    if (b64.isEmpty) return;
    try {
      final bytes = base64Decode(b64);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      _naturalSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mapData;
    if (m.imageBase64.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '地图 "${m.name}" 暂无图片',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${m.width}×${m.height} · ${m.unit}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (_naturalSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final imgW = _naturalSize!.width;
    final imgH = _naturalSize!.height;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final scale =
            (constraints.maxWidth / imgW) < (constraints.maxHeight / imgH)
            ? constraints.maxWidth / imgW
            : constraints.maxHeight / imgH;
        final renderW = imgW * scale;
        final renderH = imgH * scale;
        final ox = (constraints.maxWidth - renderW) / 2;
        final oy = (constraints.maxHeight - renderH) / 2;

        return Stack(
          children: [
            Center(
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 0.3,
                maxScale: 5.0,
                child: SizedBox(
                  width: renderW,
                  height: renderH,
                  child: Image.memory(
                    base64Decode(m.imageBase64),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            ...widget.positions.map((p) {
              final px = ox + p.x * renderW;
              final py = oy + p.y * renderH;
              final colors = [
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
              ];
              final color = colors[p.name.hashCode.abs() % colors.length];
              return Positioned(
                left: px - 12,
                top: py - 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

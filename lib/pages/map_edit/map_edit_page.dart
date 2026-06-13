import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../room_state.dart';
import '../../save_data.dart';
import '../create_save/create_save_page.dart';
import '../token_placement/token_placement_page.dart';

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
  }

  void _onReadyChanged() {
    if (mounted) setState(() {});
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

  /// Check if all non-host members are ready, and if so, start token placement.
  void _checkAllReady() {
    final session = RoomSession.instance;
    final allMembers = session.membersNotifier.value;
    final readyMembers = session.readyMembersNotifier.value;

    final nonHost = allMembers
        .where((m) => m != session.hostNameNotifier.value)
        .toList();
    if (nonHost.isEmpty) return;

    final allReady = nonHost.every((m) => readyMembers.contains(m));
    if (allReady && _selectedMap != null && !_hasStarted) {
      _hasStarted = true;
      session.mapNotifier.value = _selectedMap;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TokenPlacementPage(
              playerName: widget.playerName,
              role: widget.role,
              map: _selectedMap!,
              saveFilePath: _saveFilePath,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadSaveData() async {
    if (_saveFilePath == null) return;
    try {
      final save = await SaveData.fromZip(_saveFilePath!);
      _loadedMaps = save.maps;
    } catch (_) {
      _loadedMaps = [];
    }
    setState(() {});
  }

  Future<void> _pickSaveFile() async {
    final result = await FilePicker.platform.pickFiles(
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
    super.dispose();
  }

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

  Widget _buildMapView(ThemeData theme) {
    final m = _selectedMap!;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedMap = null),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (m.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  m.description,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 12),
              Text('尺寸: ${m.width} × ${m.height} · 单位: ${m.unit}'),
              if (m.imageBase64.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(m.imageBase64),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              if (_saveFilePath != null) ...[
                const SizedBox(height: 16),
                Text(
                  '已加载存档: $_saveFileName',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 32),

              // ── 玩家准备状态 ──
              _buildReadyStatus(),
              const SizedBox(height: 16),

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
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
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

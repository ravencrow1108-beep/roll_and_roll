import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../create_save/create_save_page.dart';
import '../adventure/adventure_page.dart';
import '../map_editor/map_editor_page.dart';
import '../map_preview/map_preview_page.dart';

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
    });
    _loadSaveData();
  }

  Future<void> _selectMap(MapData m) async {
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

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPreviewPage(
          mapData: m,
          positions: positionsForMap,
          characters: _loadedCharacters,
          saveFileName: _saveFilePath != null ? _saveFileName : null,
          onBack: () => Navigator.of(context).pop(),
          onStart: _markReady,
        ),
      ),
    );
    // 返回后清空选中状态
    if (mounted) setState(() => _selectedMap = null);
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
      });
      _loadSaveData();
    }
  }

  void _markReady() {
    _startAdventureDirectly();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _buildMapSelection(theme);
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

}

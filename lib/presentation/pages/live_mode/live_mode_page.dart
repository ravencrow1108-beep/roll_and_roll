import 'dart:convert';
import 'dart:developer' as dev;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/models/models.dart';
import '../../widgets/character_detail_panel.dart';
import '../adventure/map_display.dart';
import 'live_window_io.dart' if (dart.library.html) 'live_window_stub.dart'
    as live_window;

/// ──────────────────────────────────────────────────────
///  直播模式：三步设置 → GM 窗口（角色列表+地图+骰子）+ 独立玩家窗口
///  仅支持桌面端（Windows / macOS / Linux）
/// ──────────────────────────────────────────────────────
class LiveModePage extends StatefulWidget {
  const LiveModePage({super.key});

  @override
  State<LiveModePage> createState() => _LiveModePageState();
}

bool get _isDesktop {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

enum _LiveStage { pickSave, pickMap, pickChars, adventure }

class _LiveModePageState extends State<LiveModePage> {
  _LiveStage _stage = _LiveStage.pickSave;
  SaveData? _save;
  String? _savePath;
  String _saveFileName = '未选择';
  bool _isLoading = false;

  MapData? _selectedMap;
  final Set<String> _selectedCharNames = {};

  final TextEditingController _diceCtrl = TextEditingController();
  final List<String> _diceHistory = [];

  Object? _playerWindow;

  String? _selectedPlayerName;
  CharacterData? _deployCharacter;
  final List<PlayerPosition> _playerPositions = [];

  @override
  void dispose() {
    _diceCtrl.dispose();
    _closePlayerWindow();
    super.dispose();
  }

  Future<void> _closePlayerWindow() async {
    final ctrl = _playerWindow;
    _playerWindow = null;
    await live_window.closePlayerWindow(ctrl);
  }

  Future<void> _openPlayerWindow() async {
    await _closePlayerWindow();
    if (!_isDesktop) return;
    final args = jsonEncode({
      'savePath': _savePath,
      'selectedNames': _selectedCharNames.toList(),
      'mapName': _selectedMap?.name,
    });
    dev.log('[LiveMode] _openPlayerWindow: args.length=${args.length}');
    final ctrl = await live_window.openPlayerWindow(args);
    dev.log('[LiveMode] _openPlayerWindow: ctrl=$ctrl');
    _playerWindow = ctrl;
  }

  // ── STEP 1 ──
  Future<void> _loadSave() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择存档文件', type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    setState(() => _isLoading = true);
    try {
      final save = await SaveData.fromZip(path);
      if (!mounted) return;
      setState(() {
        _save = save;
        _savePath = path;
        _saveFileName = result.files.single.name;
        _isLoading = false;
        _selectedCharNames.clear();
        _playerPositions..clear()..addAll(save.playerPositions);
        if (save.maps.isEmpty) {
          _stage = _LiveStage.pickSave;
        } else if (save.maps.length == 1) {
          _selectedMap = save.maps.first;
          _stage = _LiveStage.pickChars;
        } else {
          _stage = _LiveStage.pickMap;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red));
    }
  }

  void _selectMap(MapData m) =>
      setState(() { _selectedMap = m; _stage = _LiveStage.pickChars; });

  void _toggleChar(String name) => setState(() =>
      _selectedCharNames.contains(name) ? _selectedCharNames.remove(name) : _selectedCharNames.add(name));

  void _selectAllChars() =>
      setState(() => _selectedCharNames.addAll((_save?.characters ?? []).map((c) => c.name)));

  void _clearAllChars() => setState(() => _selectedCharNames.clear());

  void _startAdventure() {
    setState(() => _stage = _LiveStage.adventure);
    _openPlayerWindow();
  }

  // ── dice ──
  void _rollDice(int sides) {
    final roll = (DateTime.now().millisecondsSinceEpoch % sides) + 1;
    final text = 'd$sides = $roll';
    setState(() {
      _diceHistory.insert(0, '\u{1F3B2} $text');
      if (_diceHistory.length > 30) _diceHistory.removeLast();
    });
  }

  void _rollCustomDice() {
    final t = _diceCtrl.text.trim();
    if (t.isEmpty) return;
    try {
      final result = DiceExpression.roll(t);
      final out = result.toString();
      setState(() {
        _diceHistory.insert(0, '\u{1F3B2} $t = $out');
        if (_diceHistory.length > 30) _diceHistory.removeLast();
      });
    } catch (_) {}
  }

  // ── map ──
  void _onPlayerTapped(String name) => setState(() => _selectedPlayerName = name);
  void _onDeployCharacter(CharacterData c) => setState(() => _deployCharacter = c);

  void _onPlaceDeploy(Offset relativePos) {
    if (_deployCharacter == null) return;
    setState(() {
      _playerPositions.removeWhere((p) => p.name == _deployCharacter!.name);
      _playerPositions.add(PlayerPosition(
        name: _deployCharacter!.name, x: relativePos.dx, y: relativePos.dy));
      _deployCharacter = null;
    });
  }

  void _onRemovePlayer(String name) => setState(() {
    _playerPositions.removeWhere((p) => p.name == name);
    _selectedPlayerName = null;
  });

  void _onPositionChanged(int index, PlayerPosition newPos) {
    setState(() {
      if (index >= 0 && index < _playerPositions.length) _playerPositions[index] = newPos;
    });
  }

  /// 给指定角色添加装备（从规则书模板选择）
  void _onAddEquipment(String characterName) {
    if (_save == null) return;
    final chars = _save!.characters;
    final idx = chars.indexWhere((c) => c.name == characterName);
    if (idx == -1) return;
    final c = chars[idx];
    final templates = _save!.rules.equipmentTemplates;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('规则书中没有装备模板'), backgroundColor: Colors.orange));
      return;
    }
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchCtrl.text.toLowerCase();
          final filtered = templates
              .where((t) =>
                  t.name.toLowerCase().contains(query) ||
                  t.slot.toLowerCase().contains(query) ||
                  t.effect.toLowerCase().contains(query))
              .toList();
          return AlertDialog(
            title: Text('添加装备 · $characterName'),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '搜索装备名称/位置/效果…',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Text('无匹配装备模板', style: TextStyle(fontSize: 13, color: Colors.grey))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
                              return ListTile(
                                dense: true,
                                title: Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${t.slot}${t.ac > 0 ? ' · AC${t.ac}' : ''}${t.effect.isNotEmpty ? ' · ${t.effect}' : ''}',
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  final newEq = Map<String, EquipmentData?>.from(c.equipment);
                                  newEq[t.slot] = t;
                                  _updateCharacter(characterName, c.copyWith(equipment: newEq));
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
          );
        },
      ),
    );
  }

  /// 给指定角色添加物品（从规则书模板选择）
  void _onAddItem(String characterName) {
    if (_save == null) return;
    final chars = _save!.characters;
    final idx = chars.indexWhere((c) => c.name == characterName);
    if (idx == -1) return;
    final c = chars[idx];
    final templates = _save!.rules.itemTemplates;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('规则书中没有物品模板'), backgroundColor: Colors.orange));
      return;
    }
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchCtrl.text.toLowerCase();
          final filtered = templates
              .where((t) =>
                  t.name.toLowerCase().contains(query) ||
                  t.type.toLowerCase().contains(query) ||
                  t.effect.toLowerCase().contains(query))
              .toList();
          return AlertDialog(
            title: Text('添加物品 · $characterName'),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '搜索物品名称/类型/效果…',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Text('无匹配物品模板', style: TextStyle(fontSize: 13, color: Colors.grey))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
                              return ListTile(
                                dense: true,
                                title: Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${t.type}${t.effect.isNotEmpty ? ' · ${t.effect}' : ''}${t.value > 0 ? ' · 💎${t.value}' : ''}',
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  _updateCharacter(characterName, c.copyWith(
                                    backpack: [...c.backpack, t],
                                  ));
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
          );
        },
      ),
    );
  }

  /// 更新角色并重建 _save
  void _updateCharacter(String name, CharacterData updated) {
    if (_save == null) return;
    final chars = _save!.characters.toList();
    final idx = chars.indexWhere((c) => c.name == name);
    if (idx == -1) return;
    chars[idx] = updated;
    setState(() {
      _save = SaveData(
        createdAt: _save!.createdAt,
        characters: chars,
        maps: _save!.maps,
        playerPositions: _playerPositions,
        rules: _save!.rules,
      );
    });
  }

  // ── save ──
  Future<void> _saveProgress() async {
    if (_save == null || _savePath == null || _selectedMap == null) return;
    setState(() => _isLoading = true);
    try {
      final updatedMaps = _save!.maps.toList();
      for (int i = 0; i < updatedMaps.length; i++) {
        if (updatedMaps[i].name == _selectedMap!.name) updatedMaps[i] = _selectedMap!;
      }
      final updatedSave = SaveData(createdAt: DateTime.now().toIso8601String(),
          characters: _save!.characters, maps: updatedMaps,
          playerPositions: _playerPositions, rules: _save!.rules);
      await updatedSave.packToZip(_savePath!);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('进度已保存'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return _buildUnsupported(context);
    switch (_stage) {
      case _LiveStage.pickSave: return _buildPickSave();
      case _LiveStage.pickMap: return _buildPickMap();
      case _LiveStage.pickChars: return _buildPickChars();
      case _LiveStage.adventure: return _buildAdventure();
    }
  }

  Widget _buildUnsupported(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(appBar: AppBar(title: const Text('直播模式')), body: Center(child: Padding(
      padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.desktop_windows_outlined, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text('直播模式仅支持桌面端', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('请使用 Windows、macOS 或 Linux 版本运行直播模式。\n移动端和 Web 端暂不支持。',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
    ]))));
  }

  Widget _buildPickSave() {
    final theme = Theme.of(context);
    return Scaffold(appBar: AppBar(title: const Text('直播模式')), body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.videocam_outlined, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text('选择存档开始直播', style: theme.textTheme.titleMedium),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _loadSave,
          icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.folder_open),
          label: const Text('选择存档', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
    ])));
  }

  Widget _buildPickMap() {
    final theme = Theme.of(context);
    final maps = _save?.maps ?? [];
    return Scaffold(appBar: AppBar(title: const Text('选择地图'),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _stage = _LiveStage.pickSave))),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('直播模式 · $_saveFileName', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text('选择一个地图', style: theme.textTheme.titleMedium), const SizedBox(height: 16),
          Expanded(child: ListView.builder(itemCount: maps.length, itemBuilder: (_, i) {
            final m = maps[i];
            return Card(child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.teal.shade100, child: const Icon(Icons.map_outlined, color: Colors.teal)),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${m.width}×${m.height} · ${m.unit}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => _selectMap(m)));
          })),
  ]))));
  }

  Widget _buildPickChars() {
    final theme = Theme.of(context);
    final chars = _save?.characters ?? [];
    final mapName = _selectedMap?.name ?? '';
    return Scaffold(appBar: AppBar(title: const Text('选择角色'),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
        final maps = _save?.maps ?? [];
        setState(() => _stage = maps.length > 1 ? _LiveStage.pickMap : _LiveStage.pickSave);
      }),
      actions: [
        TextButton(onPressed: _selectAllChars, child: const Text('全选')),
        TextButton(onPressed: _clearAllChars, child: const Text('清空')),
      ]),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('直播模式 · 选择角色', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4), Text('地图: $mapName', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 12),
          if (chars.isEmpty) Center(child: Text('该存档中没有角色', style: TextStyle(color: Colors.grey.shade600)))
          else Expanded(child: ListView.builder(itemCount: chars.length, itemBuilder: (_, i) {
            final c = chars[i]; final sel = _selectedCharNames.contains(c.name);
            return Card(child: CheckboxListTile(value: sel, onChanged: (_) => _toggleChar(c.name),
              secondary: CircleAvatar(backgroundImage: c.portraitBase64.isNotEmpty ? MemoryImage(base64Decode(c.portraitBase64)) : null,
                  child: c.portraitBase64.isEmpty ? const Icon(Icons.person) : null),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${c.className} · ${c.race} · Lv${c.level}')));
          })),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _selectedCharNames.isEmpty ? null : _startAdventure,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: Text(_selectedCharNames.isEmpty ? '请至少选择一个角色' : '开始直播 (已选${_selectedCharNames.length}个角色)',
                style: const TextStyle(fontSize: 16)))),
  ]))));
  }

  // ═══════════════════════════════════════
  //  Stage 3: adventure
  // ═══════════════════════════════════════
  Widget _buildAdventure() {
    final m = _selectedMap!;
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 800;

    final mapDisplay = MapDisplay(
      mapData: m, positions: _playerPositions, enemies: m.enemies, isGM: true,
      playerName: '主持', character: null, characters: _save?.characters ?? [],
      backpackItems: const [],
      onPositionChanged: _onPositionChanged, onPlayerTap: _onPlayerTapped,
      onRemovePlayer: _onRemovePlayer,
      onEditHp: null, onAddNote: null, onDeleteNote: null,
    );

    return Scaffold(appBar: AppBar(title: Text('直播 · ${m.name}'),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () async {
        await _closePlayerWindow();
        if (mounted) setState(() => _stage = _LiveStage.pickChars);
      }),
      actions: [
        if ((_save?.maps.length ?? 0) > 1)
          PopupMenuButton<MapData>(icon: const Icon(Icons.map_outlined), tooltip: '切换地图',
            onSelected: (newMap) => setState(() => _selectedMap = newMap),
            itemBuilder: (_) => _save!.maps.map((map) => PopupMenuItem(value: map, child: Text(map.name))).toList()),
        IconButton(icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            tooltip: '保存进度', onPressed: _isLoading ? null : _saveProgress),
        IconButton(icon: const Icon(Icons.open_in_new), tooltip: '重新打开玩家窗口', onPressed: _openPlayerWindow),
        IconButton(icon: const Icon(Icons.refresh), tooltip: '回到选角', onPressed: () async {
          await _closePlayerWindow();
          if (mounted) setState(() => _stage = _LiveStage.pickChars);
        }),
      ]),
      body: isWide ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── left: character grid / detail ──
        _LiveLeftPanel(
          selectedPlayerName: _selectedPlayerName,
          loadedCharacters: _save?.characters ?? [], playerPositions: _playerPositions,
          onTapCharacter: (name) => setState(() => _selectedPlayerName = name),
          onCloseDetail: () => setState(() => _selectedPlayerName = null),
          onDeployCharacter: _onDeployCharacter,
          onAddEquipment: _onAddEquipment,
          onAddItem: _onAddItem,
        ),
        // ── center: map ──
        Expanded(child: _DeployOverlay(deployCharacter: _deployCharacter,
          imageAreaKey: mapDisplay.imageAreaKey, onPlace: _onPlaceDeploy,
          onCancel: () => setState(() => _deployCharacter = null),
          child: SafeArea(child: mapDisplay))),
        // ── right: dice (white bg) ──
        Container(width: 200, decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: Color(0xFFE0E0E0), width: 1))),
          child: Column(children: [
            Expanded(child: _buildDiceResultsPanel(theme)),
            _buildDicePanel(theme),
        ])),
      ]) : Column(children: [
        Expanded(child: SafeArea(child: mapDisplay)), _buildDicePanel(theme)]));
  }

  Widget _buildDiceResultsPanel(ThemeData theme) {
    return Container(padding: const EdgeInsets.all(8), color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.casino, size: 16, color: Colors.deepPurple), const SizedBox(width: 6),
          const Text('投掷记录', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const Spacer(),
          if (_diceHistory.isNotEmpty) GestureDetector(
            onTap: () => setState(() => _diceHistory.clear()),
            child: const Icon(Icons.clear_all, size: 16, color: Colors.grey)),
        ]),
        const SizedBox(height: 6),
        Expanded(child: _diceHistory.isEmpty
            ? Center(child: Text('暂无投掷记录', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)))
            : ListView.builder(itemCount: _diceHistory.length, itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(_diceHistory[i], style: TextStyle(fontSize: 12, fontFamily: 'monospace',
                  color: i == 0 ? Colors.deepPurple : Colors.grey.shade700,
                  fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400)))),
        ),
    ]));
  }

  Widget _buildDicePanel(ThemeData theme) {
    final dice = [4, 6, 8, 10, 12, 20];
    return Container(padding: const EdgeInsets.all(8), color: Colors.white,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(spacing: 4, runSpacing: 4, children: dice.map((s) => ElevatedButton(
          onPressed: () => _rollDice(s),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero, backgroundColor: Colors.white, foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300)),
          child: Text('d$s', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: TextField(controller: _diceCtrl, decoration: const InputDecoration(
              hintText: '2d6+3', border: OutlineInputBorder(), isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 4),
          ElevatedButton(onPressed: _rollCustomDice, style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: const Text('🎲')),
    ])]));
  }
}

// ═══════════════════════════════════════
//  Left panel: character grid or detail
// ═══════════════════════════════════════
class _LiveLeftPanel extends StatelessWidget {
  const _LiveLeftPanel({required this.selectedPlayerName,
    required this.loadedCharacters, required this.playerPositions,
    required this.onTapCharacter, required this.onCloseDetail, this.onDeployCharacter,
    this.onAddEquipment, this.onAddItem});

  final String? selectedPlayerName;
  final List<CharacterData> loadedCharacters;
  final List<PlayerPosition> playerPositions;
  final ValueChanged<String> onTapCharacter;
  final VoidCallback onCloseDetail;
  final void Function(CharacterData c)? onDeployCharacter;
  final void Function(String name)? onAddEquipment;
  final void Function(String name)? onAddItem;

  @override
  Widget build(BuildContext context) {
    if (selectedPlayerName != null) {
      final char = loadedCharacters.cast<CharacterData?>().firstWhere(
        (c) => c?.name == selectedPlayerName, orElse: () => null);
      if (char != null) {
        return Container(width: 260, decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), width: 1))),
          child: Column(children: [
            Container(padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
              child: Row(children: [
                const SizedBox(width: 4),
                Text(char.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onCloseDetail,
                    tooltip: '关闭', visualDensity: VisualDensity.compact),
            ])),
            const Divider(height: 1),
            Expanded(child: CharacterDetailPanel(
              character: char, showClose: false,
              onAddEquipment: onAddEquipment,
              onAddItem: onAddItem,
            )),
        ]));
      }
    }
    return _LiveCharacterGrid(characters: loadedCharacters, playerPositions: playerPositions,
      onTapCharacter: onTapCharacter, onDeployCharacter: onDeployCharacter);
  }
}

/// Character grid panel
class _LiveCharacterGrid extends StatelessWidget {
  const _LiveCharacterGrid({required this.characters, required this.playerPositions,
    required this.onTapCharacter, this.onDeployCharacter});

  final List<CharacterData> characters;
  final List<PlayerPosition> playerPositions;
  final void Function(String name) onTapCharacter;
  final void Function(CharacterData c)? onDeployCharacter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(width: 220, decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3), width: 1))),
      child: Column(children: [
        Container(padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Row(children: [
            const Icon(Icons.people_outline, size: 18), const SizedBox(width: 6),
            Text('角色列表', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('右键上场', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ])),
        const Divider(height: 1),
        Expanded(child: characters.isEmpty
          ? const Center(child: Text('暂无角色', style: TextStyle(fontSize: 12, color: Colors.grey)))
          : GridView.builder(padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.85),
              itemCount: characters.length, itemBuilder: (_, i) {
                final c = characters[i];
                final onMap = playerPositions.any((p) => p.name == c.name);
                return Card(child: InkWell(borderRadius: BorderRadius.circular(10),
                  onTap: () => onTapCharacter(c.name),
                  onSecondaryTapDown: onDeployCharacter != null ? (d) => _showMenu(context, c, onDeployCharacter!, d.globalPosition) : null,
                  child: Padding(padding: const EdgeInsets.all(6),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Stack(children: [
                        CircleAvatar(radius: 22,
                          backgroundImage: c.portraitBase64.isNotEmpty ? MemoryImage(base64Decode(c.portraitBase64)) : null,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: c.portraitBase64.isEmpty ? Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)) : null),
                        if (onMap) const Positioned(right: 0, bottom: 0,
                          child: Icon(Icons.check_circle, size: 14, color: Colors.green)),
                      ]),
                      const SizedBox(height: 4),
                      Text(c.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]))));
              })),
    ]));
  }

  static void _showMenu(BuildContext ctx, CharacterData c, void Function(CharacterData) fn, Offset pos) {
    final overlay = Overlay.of(ctx, rootOverlay: true).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    showMenu<String>(context: ctx,
      position: RelativeRect.fromRect(Rect.fromLTWH(pos.dx, pos.dy, 1, 1), Offset.zero & overlay.size),
      items: [const PopupMenuItem(value: 'deploy', child: ListTile(
          leading: Icon(Icons.add_location, color: Colors.green), title: Text('上场'), contentPadding: EdgeInsets.zero))],
    ).then((v) { if (v == 'deploy') fn(c); });
  }
}

/// Deploy overlay: click map to place character
class _DeployOverlay extends StatelessWidget {
  const _DeployOverlay({required this.deployCharacter, required this.imageAreaKey,
    required this.onPlace, required this.onCancel, required this.child});

  final CharacterData? deployCharacter;
  final GlobalKey imageAreaKey;
  final void Function(Offset relativePos) onPlace;
  final VoidCallback onCancel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (deployCharacter != null) GestureDetector(
        onTapUp: (details) {
          final rb = imageAreaKey.currentContext?.findRenderObject() as RenderBox?;
          if (rb == null) return;
          final local = rb.globalToLocal(details.globalPosition);
          final size = rb.size;
          if (size.isEmpty) return;
          onPlace(Offset((local.dx / size.width).clamp(0.0, 1.0), (local.dy / size.height).clamp(0.0, 1.0)));
        },
        child: Container(color: Colors.black26, child: Center(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 30,
              backgroundImage: deployCharacter!.portraitBase64.isNotEmpty
                  ? MemoryImage(base64Decode(deployCharacter!.portraitBase64)) : null,
              backgroundColor: Colors.deepPurple.withValues(alpha: 0.3),
              child: deployCharacter!.portraitBase64.isEmpty
                  ? Text(deployCharacter!.name.isNotEmpty ? deployCharacter!.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)) : null),
            const SizedBox(height: 8),
            Text('点击地图放置「${deployCharacter!.name}」', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextButton(onPressed: onCancel, child: const Text('取消', style: TextStyle(color: Colors.white70))),
        ])))),
    ]);
  }
}

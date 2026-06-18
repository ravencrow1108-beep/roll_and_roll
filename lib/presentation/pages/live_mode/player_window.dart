import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../../../data/models/models.dart';
import '../adventure/map_display.dart';

/// 直播模式玩家视角窗口：地图 + 角色位置 + 角色背包
class LivePlayerWindow extends StatefulWidget {
  const LivePlayerWindow({
    required this.savePath,
    required this.selectedNames,
    this.mapName,
    super.key,
  });

  factory LivePlayerWindow.fromRawJson(String rawJson) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (e) {
      dev.log('[PlayerWindow] JSON 解析失败: $e, rawJson=$rawJson');
      data = {};
    }
    final savePath = data['savePath'] as String? ?? '';
    final names = (data['selectedNames'] as List<dynamic>?)
            ?.map((n) => n.toString())
            .toList() ??
        [];
    final mapName = data['mapName'] as String?;
    dev.log('[PlayerWindow] fromRawJson: savePath=$savePath, selectedNames=$names, mapName=$mapName');
    return LivePlayerWindow(savePath: savePath, selectedNames: names, mapName: mapName);
  }

  final String savePath;
  final List<String> selectedNames;
  final String? mapName;

  @override
  State<LivePlayerWindow> createState() => _LivePlayerWindowState();
}

class _LivePlayerWindowState extends State<LivePlayerWindow> {
  List<CharacterData> _characters = [];
  MapData? _mapData;
  List<PlayerPosition> _positions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    dev.log('[PlayerWindow] _loadData start: savePath=${widget.savePath}');
    if (widget.savePath.isEmpty) {
      dev.log('[PlayerWindow] savePath 为空，无法加载');
      setState(() {
        _loading = false;
        _error = '存档路径为空，请联系主持重新打开窗口';
      });
      return;
    }
    try {
      dev.log('[PlayerWindow] 开始读取 ZIP: ${widget.savePath}');
      final save = await SaveData.fromZip(widget.savePath);
      if (!mounted) return;
      dev.log('[PlayerWindow] ZIP 加载成功: characters=${save.characters.length}, maps=${save.maps.length}, positions=${save.playerPositions.length}');
      setState(() {
        _characters = save.characters
            .where((c) => widget.selectedNames.contains(c.name))
            .toList();
        _mapData = widget.mapName != null
            ? save.maps.cast<MapData?>().firstWhere(
                  (m) => m?.name == widget.mapName,
                  orElse: () => save.maps.isNotEmpty ? save.maps.first : null,
                )
            : (save.maps.isNotEmpty ? save.maps.first : null);
        _positions = save.playerPositions
            .where((p) => widget.selectedNames.contains(p.name))
            .toList();
        _loading = false;
        _error = null;
        dev.log('[PlayerWindow] 过滤后: characters=${_characters.length}, mapData=${_mapData?.name}, positions=${_positions.length}');
      });
    } catch (e, st) {
      dev.log('[PlayerWindow] 加载失败: $e\n$st');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载存档失败: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('玩家视角 - 加载失败'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.red)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () { setState(() { _loading = true; _error = null; }); _loadData(); },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_mapData != null ? '玩家视角 · ${_mapData!.name}' : '玩家视角 - 直播模式'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final hasMap = _mapData != null;
    final hasChars = _characters.isNotEmpty;

    if (!hasMap && !hasChars) {
      return const Center(child: Text('暂无角色数据'));
    }

    // ── 左右布局：左侧角色卡片 + 右侧地图 ──
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 左侧：角色信息 ──
        SizedBox(
          width: 280,
          child: hasChars
              ? _buildCharacterCards()
              : const Center(child: Text('暂无角色数据')),
        ),
        const VerticalDivider(width: 1),
        // ── 右侧：地图 ──
        Expanded(
          child: hasMap
              ? MapDisplay(
                  mapData: _mapData!,
                  positions: _positions,
                  enemies: _mapData!.enemies,
                  isGM: false,
                  playerName: '玩家',
                  character: null,
                  characters: _characters,
                  backpackItems: const [],
                  onPlayerTap: null,
                  onEditHp: null,
                  onAddNote: null,
                  onDeleteNote: null,
                  onRemovePlayer: null,
                  onPositionChanged: null,
                )
              : const Center(child: Text('暂无地图数据')),
        ),
      ],
    );
  }

  /// 左侧角色卡片列表 — 装备/物品/技能直接展示，无需展开
  Widget _buildCharacterCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _characters.length,
      itemBuilder: (_, i) {
        final c = _characters[i];
        final onMap = _positions.any((p) => p.name == c.name);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 头部：头像 + 名称 + HP ──
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: c.portraitBase64.isNotEmpty
                              ? MemoryImage(base64Decode(c.portraitBase64))
                              : null,
                          child: c.portraitBase64.isEmpty
                              ? Text(c.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))
                              : null,
                        ),
                        if (onMap)
                          const Positioned(
                            right: 0, bottom: 0,
                            child: Icon(Icons.location_on, size: 12, color: Colors.green),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${c.className} · ${c.race} · Lv${c.level}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // ── HP 条 ──
                _buildHpBar(c),
                const SizedBox(height: 6),
                // ── 属性 ──
                _buildStats(c),
                const SizedBox(height: 4),
                // ── 装备 ──
                if (c.equipment.entries.any((e) => e.value != null)) ...[
                  const Divider(height: 16),
                  _sectionTitle('装备'),
                  ...c.equipment.entries
                      .where((e) => e.value != null)
                      .map((e) => _buildEquipRow(e.key, e.value!)),
                ],
                // ── 物品 ──
                if (c.backpack.isNotEmpty) ...[
                  const Divider(height: 16),
                  _sectionTitle('物品'),
                  ...c.backpack.map(_buildItemRow),
                ],
                // ── 技能 ──
                if (c.skills.isNotEmpty) ...[
                  const Divider(height: 16),
                  _sectionTitle('技能'),
                  ...c.skills.map(_buildSkillRow),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHpBar(CharacterData c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: c.maxHp > 0 ? (c.hp / c.maxHp).clamp(0.0, 1.0) : 0,
          minHeight: 6,
          backgroundColor: Colors.grey.shade800,
          valueColor: AlwaysStoppedAnimation<Color>(
            (c.maxHp > 0 ? c.hp / c.maxHp : 0) > 0.5
                ? Colors.green
                : (c.maxHp > 0 ? c.hp / c.maxHp : 0) > 0.25
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildStats(CharacterData c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8, runSpacing: 4,
        children: [
          _statChip('力量', c.strength, Colors.red),
          _statChip('敏捷', c.dexterity, Colors.green),
          _statChip('体质', c.constitution, Colors.orange),
          _statChip('智力', c.intelligence, Colors.blue),
          _statChip('感知', c.wisdom, Colors.purple),
          _statChip('魅力', c.charisma, Colors.pink),
        ],
      ),
    );
  }

  Widget _buildEquipRow(String slot, EquipmentData eq) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(children: [
        const Icon(Icons.shield_outlined, size: 14, color: Colors.deepPurpleAccent),
        const SizedBox(width: 6),
        Expanded(child: Text(eq.name, style: const TextStyle(fontSize: 13))),
        Text(slot, style: TextStyle(fontSize: 10, color: Colors.orange.shade300)),
        if (eq.ac > 0) ...[
          const SizedBox(width: 4),
          Text('AC${eq.ac}', style: TextStyle(fontSize: 10, color: Colors.lightBlue.shade200)),
        ],
      ]),
    );
  }

  Widget _buildItemRow(ItemData item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(children: [
        const Icon(Icons.category_outlined, size: 14, color: Colors.deepPurpleAccent),
        const SizedBox(width: 6),
        Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
        if (item.value > 0) Text('💎${item.value}', style: const TextStyle(fontSize: 11)),
      ]),
    );
  }

  Widget _buildSkillRow(SkillData s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_fix_high, size: 14, color: Colors.tealAccent),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (s.damages.isNotEmpty)
            Wrap(spacing: 4, children: s.damages.map((d) => Text(
              '${d.expression ?? ""}${d.damageType != null ? " ${d.damageType}" : ""}',
              style: TextStyle(fontSize: 11, color: Colors.red.shade300),
            )).toList()),
          if (s.description != null && s.description!.isNotEmpty)
            Text(s.description!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ])),
      ]),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
      ),
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text('$label: $value',
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
    );
  }
}

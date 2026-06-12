import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'save_data.dart';

class CreateSavePage extends StatefulWidget {
  const CreateSavePage({this.allowMapEdit = true, super.key});

  /// 是否允许编辑地图（玩家为 false，主持为 true）
  final bool allowMapEdit;

  @override
  State<CreateSavePage> createState() => _CreateSavePageState();
}

extension on _CreateSavePageState {
  bool get _allowMap => widget.allowMapEdit;
  int get _tabCount => _allowMap ? 3 : 2;
}

class _ClassEdit {
  final TextEditingController ctrl = TextEditingController();

  _ClassEdit({String text = ''}) {
    ctrl.text = text;
  }

  void dispose() => ctrl.dispose();
}

class _PersonalityEdit {
  final TextEditingController traitCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  _PersonalityEdit({String trait = '', String description = ''}) {
    traitCtrl.text = trait;
    descCtrl.text = description;
  }

  void dispose() {
    traitCtrl.dispose();
    descCtrl.dispose();
  }
}

class _CharEdit {
  final nameCtrl = TextEditingController(text: '无名冒险者');
  final List<_ClassEdit> classes = [_ClassEdit(text: '战士')];
  final raceCtrl = TextEditingController();
  String race = '人类';
  bool raceCustom = false;
  int level = 1;
  List<SkillData> skills = [];
  List<_PersonalityEdit> personalities = [];
  List<ItemData> backpack = [];
  final Map<String, int> baseStats = {
    '力量': 10,
    '敏捷': 10,
    '体质': 10,
    '智力': 10,
    '感知': 10,
    '魅力': 10,
  };
  final Map<String, int> customStats = {};

  void dispose() {
    nameCtrl.dispose();
    raceCtrl.dispose();
    for (final c in classes) {
      c.dispose();
    }
    for (final p in personalities) {
      p.dispose();
    }
  }

  CharacterData toCharacterData() => CharacterData(
    name: nameCtrl.text.trim(),
    className: classes.isNotEmpty ? classes.first.ctrl.text.trim() : '',
    additionalClasses: classes
        .skip(1)
        .map((c) => c.ctrl.text.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
    race: raceCustom ? raceCtrl.text.trim() : race,
    level: level,
    skills: skills,
    personalities: personalities
        .map(
          (p) => PersonalityData(
            trait: p.traitCtrl.text.trim(),
            description: p.descCtrl.text.trim().isEmpty
                ? null
                : p.descCtrl.text.trim(),
          ),
        )
        .toList(),
    backpack: backpack,
    strength: baseStats['力量'] ?? 0,
    dexterity: baseStats['敏捷'] ?? 0,
    constitution: baseStats['体质'] ?? 0,
    intelligence: baseStats['智力'] ?? 0,
    wisdom: baseStats['感知'] ?? 0,
    charisma: baseStats['魅力'] ?? 0,
    customStats: Map<String, int>.from(customStats),
  );
}

class _CreateSavePageState extends State<CreateSavePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isSaving = false;

  final List<_CharEdit> _chars = [_CharEdit()];
  int _charIndex = 0;

  _CharEdit get _cur => _chars[_charIndex];

  // ---------- 地图 / 物品 ----------
  final List<MapData> _maps = [];
  final List<ItemData> _items = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _chars) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCharacter() {
    setState(() {
      _chars.add(_CharEdit());
      _charIndex = _chars.length - 1;
    });
  }

  void _switchCharacter(int? idx) {
    if (idx != null) setState(() => _charIndex = idx);
  }

  int _getStat(String s) => _cur.baseStats[s] ?? _cur.customStats[s] ?? 0;

  void _setStat(String s, int v) {
    if (_cur.baseStats.containsKey(s)) {
      _cur.baseStats[s] = v;
    } else {
      _cur.customStats[s] = v;
    }
  }

  void _adjustStat(String stat, int delta) {
    setState(() {
      final cur = _getStat(stat);
      final nv = cur + delta;
      if (nv < 0 || nv > 99) return;
      _setStat(stat, nv);
    });
  }

  void _addClass() {
    setState(() => _cur.classes.add(_ClassEdit()));
  }

  void _removeClass(int index) {
    if (_cur.classes.length <= 1) return;
    setState(() {
      _cur.classes[index].dispose();
      _cur.classes.removeAt(index);
    });
  }

  void _addCustomStat() {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加自定义属性'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '属性名称',
                border: OutlineInputBorder(),
                hintText: '如: 幸运、灵巧',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '初始值 (0~20)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              if (_cur.baseStats.containsKey(name) ||
                  _cur.customStats.containsKey(name)) {
                return; // duplicate
              }
              final val = int.tryParse(valueCtrl.text.trim()) ?? 10;
              setState(() => _cur.customStats[name] = val.clamp(0, 20));
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _removeCustomStat(String name) {
    setState(() => _cur.customStats.remove(name));
  }

  void _removeBaseStat(String stat) {
    setState(() => _cur.baseStats.remove(stat));
  }

  void _addPersonality() {
    setState(() => _cur.personalities.add(_PersonalityEdit()));
  }

  void _removePersonality(int index) {
    setState(() {
      _cur.personalities[index].dispose();
      _cur.personalities.removeAt(index);
    });
  }

  void _addMap() {
    showDialog(
      context: context,
      builder: (ctx) =>
          _MapDialog(onSave: (map) => setState(() => _maps.add(map))),
    );
  }

  void _addSkill() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final diceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加技能'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '技能名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diceCtrl,
                decoration: const InputDecoration(
                  labelText: '伤害骰子表达式',
                  border: OutlineInputBorder(),
                  hintText: '如: 2d6+3, 1d8+1d4, d20+力量, 2d6+敏捷',
                  helperText: '支持多骰子组合与属性加成（力量/敏捷/体质/智力/感知/魅力）',
                  helperMaxLines: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final s = nameCtrl.text.trim();
              if (s.isEmpty) return;
              final diceText = diceCtrl.text.trim();
              setState(
                () => _cur.skills.add(
                  SkillData(
                    name: s,
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    diceType: diceText.isEmpty ? null : diceText,
                  ),
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _removeMap(int index) {
    setState(() => _maps.removeAt(index));
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) =>
          _ItemDialog(onSave: (item) => setState(() => _items.add(item))),
    );
  }

  void _addBackpackItem() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加背包物品'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '物品名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final s = nameCtrl.text.trim();
              if (s.isEmpty) return;
              final item = ItemData(
                name: s,
                type: '背包物品',
                description: descCtrl.text.trim(),
              );
              setState(() {
                _cur.backpack.add(item);
                _items.add(item);
              });
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _removeBackpackItem(int index) {
    setState(() => _cur.backpack.removeAt(index));
  }

  Future<void> _saveToFile() async {
    final first = _chars.first.nameCtrl.text.trim();
    if (first.isEmpty) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先输入角色名称'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final save = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: _chars.map((c) => c.toCharacterData()).toList(),
        maps: _maps,
        items: _items,
      );
      final jsonString = save.toJsonString();
      final fileName =
          '${_chars.first.nameCtrl.text.trim()}_${DateTime.now().millisecondsSinceEpoch}.json';
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '保存存档文件',
        fileName: fileName,
        type: FileType.any,
      );
      if (outputPath == null) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      final file = File(outputPath);
      await file.writeAsString(jsonString, flush: true);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '存档已保存 (角色:${_chars.length} 地图:${_maps.length} 物品:${_items.length})',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, outputPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[const Tab(icon: Icon(Icons.person), text: '角色')];
    if (_allowMap) {
      tabs.add(const Tab(icon: Icon(Icons.map_outlined), text: '地图'));
    }
    tabs.add(const Tab(icon: Icon(Icons.inventory_2_outlined), text: '物品'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建存档'),
        bottom: TabBar(controller: _tabController, tabs: tabs),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 20,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '角色 ${_charIndex + 1}/${_chars.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_chars.length > 1)
                              IconButton(
                                onPressed: () {
                                  final items = List.generate(
                                    _chars.length,
                                    (i) => PopupMenuItem(
                                      value: i,
                                      child: Text(_chars[i].nameCtrl.text),
                                    ),
                                  );
                                  showMenu<int>(
                                    context: context,
                                    items: items,
                                    position: const RelativeRect.fromLTRB(
                                      100,
                                      100,
                                      100,
                                      100,
                                    ),
                                  ).then(_switchCharacter);
                                },
                                icon: const Icon(Icons.swap_horiz),
                                tooltip: '切换角色',
                              ),
                            TextButton.icon(
                              onPressed: _addCharacter,
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('添加角色'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _CharacterTab(
                          nameCtrl: _cur.nameCtrl,
                          classes: _cur.classes,
                          onAddClass: _addClass,
                          onRemoveClass: _removeClass,
                          race: _cur.race,
                          raceCustom: _cur.raceCustom,
                          raceCtrl: _cur.raceCtrl,
                          onRaceChanged: (v) {
                            if (v == '__custom__') {
                              setState(() => _cur.raceCustom = true);
                            } else {
                              setState(() {
                                _cur.raceCustom = false;
                                _cur.race = v ?? '人类';
                              });
                            }
                          },
                          level: _cur.level,
                          onLevelChanged: (v) => setState(() => _cur.level = v),
                          skills: _cur.skills,
                          onAddSkill: _addSkill,
                          backpack: _cur.backpack,
                          onAddBackpackItem: _addBackpackItem,
                          onRemoveBackpackItem: _removeBackpackItem,
                          personalities: _cur.personalities,
                          onAddPersonality: _addPersonality,
                          onRemovePersonality: _removePersonality,
                          baseStats: _cur.baseStats,
                          customStats: _cur.customStats,
                          onAddCustomStat: _addCustomStat,
                          onRemoveCustomStat: _removeCustomStat,
                          onRemoveBaseStat: _removeBaseStat,
                          onAdjust: _adjustStat,
                        ),
                      ),
                    ],
                  ),
                  if (_allowMap)
                    _MapListTab(
                      maps: _maps,
                      onAdd: _addMap,
                      onDelete: _removeMap,
                    ),
                  _ItemListTab(items: _items, onAdd: _addItem),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveToFile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving ? '保存中...' : '保存存档',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 角色 Tab ───
class _CharacterTab extends StatelessWidget {
  const _CharacterTab({
    required this.nameCtrl,
    required this.classes,
    required this.onAddClass,
    required this.onRemoveClass,
    required this.race,
    required this.raceCustom,
    required this.raceCtrl,
    required this.onRaceChanged,
    required this.level,
    required this.onLevelChanged,
    required this.skills,
    required this.onAddSkill,
    required this.backpack,
    required this.onAddBackpackItem,
    required this.onRemoveBackpackItem,
    required this.personalities,
    required this.onAddPersonality,
    required this.onRemovePersonality,
    required this.baseStats,
    required this.customStats,
    required this.onAddCustomStat,
    required this.onRemoveCustomStat,
    required this.onRemoveBaseStat,
    required this.onAdjust,
  });

  final TextEditingController nameCtrl;
  final List<_ClassEdit> classes;
  final VoidCallback onAddClass;
  final void Function(int index) onRemoveClass;
  final String race;
  final bool raceCustom;
  final TextEditingController raceCtrl;
  final ValueChanged<String?> onRaceChanged;
  final int level;
  final ValueChanged<int> onLevelChanged;
  final List<SkillData> skills;
  final VoidCallback onAddSkill;
  final List<ItemData> backpack;
  final VoidCallback onAddBackpackItem;
  final void Function(int index) onRemoveBackpackItem;
  final List<_PersonalityEdit> personalities;
  final VoidCallback onAddPersonality;
  final void Function(int index) onRemovePersonality;
  final Map<String, int> baseStats;
  final Map<String, int> customStats;
  final VoidCallback onAddCustomStat;
  final void Function(String name) onRemoveCustomStat;
  final void Function(String stat) onRemoveBaseStat;
  final void Function(String stat, int delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '角色信息',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: '角色名称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '职业 (${classes.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddClass,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加职业'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(classes.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: classes[i].ctrl,
                      decoration: InputDecoration(
                        labelText: '职业名称',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '#${i + 1}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (classes.length > 1)
                    IconButton(
                      onPressed: () => onRemoveClass(i),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: '删除职业',
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '性格 (${personalities.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddPersonality,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加性格'),
              ),
            ],
          ),
          if (personalities.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...List.generate(personalities.length, (i) {
              final p = personalities[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      size: 20,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: p.traitCtrl,
                            decoration: InputDecoration(
                              labelText: '性格特征',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '#${i + 1}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: p.descCtrl,
                            decoration: const InputDecoration(
                              labelText: '描述（可选）',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemovePersonality(i),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: '删除性格',
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: raceCustom ? '__custom__' : race,
            decoration: const InputDecoration(
              labelText: '种族',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '人类', child: Text('人类')),
              DropdownMenuItem(value: '精灵', child: Text('精灵')),
              DropdownMenuItem(value: '矮人', child: Text('矮人')),
              DropdownMenuItem(value: '半身人', child: Text('半身人')),
              DropdownMenuItem(value: '龙裔', child: Text('龙裔')),
              DropdownMenuItem(value: '兽人', child: Text('兽人')),
              DropdownMenuItem(value: '__custom__', child: Text('自定义…')),
            ],
            onChanged: onRaceChanged,
          ),
          if (raceCustom) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: raceCtrl,
              decoration: const InputDecoration(
                labelText: '自定义种族名称',
                border: OutlineInputBorder(),
                hintText: '如: 半精灵、魔裔',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('等级', style: TextStyle(fontSize: 16)),
              const Spacer(),
              IconButton(
                onPressed: level > 1 ? () => onLevelChanged(level - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$level',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onLevelChanged(level + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '技能 (${skills.length})',
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddSkill,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加技能'),
              ),
            ],
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...skills.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.casino,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (s.description != null &&
                            s.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (s.diceType != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🎲 ${s.diceType}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '背包与装备 (${backpack.length})',
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddBackpackItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加物品'),
              ),
            ],
          ),
          if (backpack.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...List.generate(backpack.length, (i) {
              final item = backpack[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.backpack_outlined,
                          size: 20,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.description.isNotEmpty)
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => onRemoveBackpackItem(i),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: '移出背包',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          Text(
            '属性分配',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...baseStats.entries.map((e) {
            final icon = switch (e.key) {
              '力量' => Icons.fitness_center,
              '敏捷' => Icons.directions_run,
              '体质' => Icons.favorite_outline,
              '智力' => Icons.psychology_outlined,
              '感知' => Icons.visibility_outlined,
              '魅力' => Icons.emoji_emotions_outlined,
              _ => Icons.star_outline,
            };
            return _StatLine(
              e.key,
              e.value,
              icon,
              e.value < 99,
              onAdjust,
              canDelete: true,
              onDelete: () => onRemoveBaseStat(e.key),
            );
          }),
          ...customStats.entries.map(
            (e) => _StatLine(
              e.key,
              e.value,
              Icons.star_outline,
              e.value < 99,
              onAdjust,
              canDelete: true,
              onDelete: () => onRemoveCustomStat(e.key),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddCustomStat,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加属性'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine(
    this.label,
    this.value,
    this.icon,
    this.canIncrement,
    this.onAdjust, {
    this.canDelete = false,
    this.onDelete,
  });

  final String label;
  final int value;
  final IconData icon;
  final bool canIncrement;
  final void Function(String, int) onAdjust;
  final bool canDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              child: Text(label, style: const TextStyle(fontSize: 16)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onAdjust(label, -1) : null,
              tooltip: '减少',
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: canIncrement ? () => onAdjust(label, 1) : null,
              tooltip: '增加',
            ),
            if (canDelete && onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 22,
                ),
                onPressed: onDelete,
                tooltip: '删除属性',
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 地图列表 Tab ───
class _MapListTab extends StatelessWidget {
  const _MapListTab({
    required this.maps,
    required this.onAdd,
    required this.onDelete,
  });

  final List<MapData> maps;
  final VoidCallback onAdd;
  final void Function(int index) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '地图列表',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '已添加 ${maps.length} 张地图',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('添加地图', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: maps.isEmpty
                ? Center(
                    child: Text(
                      '暂无地图，点击上方按钮添加',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: maps.length,
                    itemBuilder: (_, i) {
                      final m = maps[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // 缩略图
                              Container(
                                width: 72,
                                height: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.memory(
                                  base64Decode(m.imageBase64),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.map_outlined,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      '${m.width} × ${m.height} ${m.unit}'
                                      '${m.tiles.isNotEmpty ? ' · ${m.tiles.length} 地块' : ''}'
                                      '${m.description.isNotEmpty ? ' · ${m.description}' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => onDelete(i),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                tooltip: '删除地图',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── 物品列表 Tab ───
class _ItemListTab extends StatelessWidget {
  const _ItemListTab({required this.items, required this.onAdd});

  final List<ItemData> items;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '物品列表',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '已添加 ${items.length} 件物品',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('添加物品', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      '暂无物品，点击上方按钮添加',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            it.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            '${it.type} · ×${it.quantity} · ${it.weight}磅 · ${it.value}金币${it.description.isNotEmpty ? ' · ${it.description}' : ''}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── 添加地图对话框 ───
class _MapDialog extends StatefulWidget {
  const _MapDialog({required this.onSave});

  final void Function(MapData) onSave;

  @override
  State<_MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<_MapDialog> {
  final _nameCtrl = TextEditingController(text: '无名地图');
  final _descCtrl = TextEditingController();
  final _widthCtrl = TextEditingController(text: '20');
  final _heightCtrl = TextEditingController(text: '20');
  String? _imageBase64;
  String? _imageFileName;
  double _aspectRatio = 1.0;
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();
    _widthCtrl.addListener(_onWidthChanged);
  }

  void _onWidthChanged() {
    final w = double.tryParse(_widthCtrl.text.trim());
    if (w != null && w > 0 && _hasImage && _aspectRatio > 0) {
      final h = (w / _aspectRatio).round();
      _heightCtrl.text = '$h';
    }
  }

  @override
  void dispose() {
    _widthCtrl.removeListener(_onWidthChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    // 解码图片获取像素尺寸，计算宽高比
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final pw = frame.image.width.toDouble();
    final ph = frame.image.height.toDouble();
    frame.image.dispose();
    codec.dispose();
    final ratio = ph > 0 ? pw / ph : 1.0;

    setState(() {
      _imageBase64 = base64Encode(bytes);
      _imageFileName = file.name;
      _aspectRatio = ratio;
      _hasImage = true;
    });

    // 根据宽高比自动更新长度
    _onWidthChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加地图'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '地图名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // ── 上传图片（必选）──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(
                  _hasImage ? Icons.check_circle : Icons.image_outlined,
                  color: _hasImage ? Colors.green : null,
                ),
                label: Text(_imageFileName ?? '上传地图图片 *'),
                style: _hasImage
                    ? null
                    : OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                      ),
              ),
            ),
            if (_hasImage) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  base64Decode(_imageBase64!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '宽度（米）',
                      border: OutlineInputBorder(),
                      suffixText: '米',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '×',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: '长度（米）',
                      border: const OutlineInputBorder(),
                      suffixText: '米',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            if (!_hasImage || _imageBase64 == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请先上传地图图片'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            widget.onSave(
              MapData(
                name: name,
                description: _descCtrl.text.trim(),
                width: int.tryParse(_widthCtrl.text.trim()) ?? 20,
                height: int.tryParse(_heightCtrl.text.trim()) ?? 20,
                imageBase64: _imageBase64!,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

// ─── 添加物品对话框 ───
class _ItemDialog extends StatefulWidget {
  const _ItemDialog({required this.onSave});

  final void Function(ItemData) onSave;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _nameCtrl = TextEditingController(text: '无名物品');
  final _descCtrl = TextEditingController();
  String _type = '杂物';
  int _quantity = 1, _weight = 0, _value = 0;

  static const _types = ['武器', '防具', '药水', '卷轴', '杂物', '饰品', '食物', '材料'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加物品'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '物品名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: '类型',
                border: OutlineInputBorder(),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? '杂物'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '数量',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _quantity = int.tryParse(v) ?? 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '重量(磅)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _weight = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '价值(金币)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _value = int.tryParse(v) ?? 0,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            widget.onSave(
              ItemData(
                name: name,
                type: _type,
                description: _descCtrl.text.trim(),
                quantity: _quantity,
                weight: _weight,
                value: _value,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

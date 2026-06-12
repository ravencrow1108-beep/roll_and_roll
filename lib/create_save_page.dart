import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'save_data.dart';

class CreateSavePage extends StatefulWidget {
  const CreateSavePage({super.key});

  @override
  State<CreateSavePage> createState() => _CreateSavePageState();
}

class _CharEdit {
  final nameCtrl = TextEditingController(text: '无名冒险者');
  final classCtrl = TextEditingController(text: '战士');
  List<String> additionalClasses = [];
  String race = '人类';
  int level = 1;
  List<SkillData> skills = [];
  int strength = 10, dexterity = 10, constitution = 10;
  int intelligence = 10, wisdom = 10, charisma = 10;
  int remainingPoints = 15;

  void dispose() {
    nameCtrl.dispose();
    classCtrl.dispose();
  }

  CharacterData toCharacterData() => CharacterData(
        name: nameCtrl.text.trim(),
        className: classCtrl.text.trim(),
        additionalClasses: additionalClasses,
        race: race,
        level: level,
        skills: skills,
        strength: strength,
        dexterity: dexterity,
        constitution: constitution,
        intelligence: intelligence,
        wisdom: wisdom,
        charisma: charisma,
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _chars) { c.dispose(); }
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

  int _getStat(String s) {
    switch (s) {
      case '力量': return _cur.strength;
      case '敏捷': return _cur.dexterity;
      case '体质': return _cur.constitution;
      case '智力': return _cur.intelligence;
      case '感知': return _cur.wisdom;
      case '魅力': return _cur.charisma;
      default: return 0;
    }
  }

  void _setStat(String s, int v) {
    switch (s) {
      case '力量': _cur.strength = v;
      case '敏捷': _cur.dexterity = v;
      case '体质': _cur.constitution = v;
      case '智力': _cur.intelligence = v;
      case '感知': _cur.wisdom = v;
      case '魅力': _cur.charisma = v;
    }
  }

  void _adjustStat(String stat, int delta) {
    setState(() {
      final cur = _getStat(stat);
      final nv = cur + delta;
      if (nv < 0 || nv > 20) return;
      if (delta > 0 && _cur.remainingPoints <= 0) return;
      _setStat(stat, nv);
      _cur.remainingPoints -= delta;
    });
  }

  void _addMap() {
    showDialog(
      context: context,
      builder: (ctx) => _MapDialog(
        onSave: (map) => setState(() => _maps.add(map)),
      ),
    );
  }

  void _addClass() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加职业'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
                labelText: '职业名称', border: OutlineInputBorder())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
              onPressed: () {
                final s = ctrl.text.trim();
                if (s.isNotEmpty) setState(() => _cur.additionalClasses.add(s));
                Navigator.pop(ctx);
              },
              child: const Text('添加')),
        ],
      ),
    );
  }

  void _addSkill() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String dice = '无';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) {
        return AlertDialog(
          title: const Text('添加技能'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: '技能名称', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: '描述（可选）', border: OutlineInputBorder()),
                  maxLines: 2),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: dice,
                decoration: const InputDecoration(
                    labelText: '伤害骰子', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: '无', child: Text('无')),
                  DropdownMenuItem(value: 'd4', child: Text('d4')),
                  DropdownMenuItem(value: 'd6', child: Text('d6')),
                  DropdownMenuItem(value: 'd8', child: Text('d8')),
                  DropdownMenuItem(value: 'd10', child: Text('d10')),
                  DropdownMenuItem(value: 'd12', child: Text('d12')),
                  DropdownMenuItem(value: 'd20', child: Text('d20')),
                ],
                onChanged: (v) => setDlg(() => dice = v ?? '无'),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
                onPressed: () {
                  final s = nameCtrl.text.trim();
                  if (s.isEmpty) return;
                  setState(() => _cur.skills.add(SkillData(
                      name: s,
                      description:
                          descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      diceType: dice == '无' ? null : dice)));
                  Navigator.pop(ctx);
                },
                child: const Text('添加')),
          ],
        );
      }),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) => _ItemDialog(
        onSave: (item) => setState(() => _items.add(item)),
      ),
    );
  }

  Future<void> _saveToFile() async {
    final first = _chars.first.nameCtrl.text.trim();
    if (first.isEmpty) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('请先输入角色名称'), backgroundColor: Colors.orange),
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
              '存档已保存 (角色:${_chars.length} 地图:${_maps.length} 物品:${_items.length})'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建存档'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: '角色'),
            Tab(icon: Icon(Icons.map_outlined), text: '地图'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: '物品'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(children: [
                        const Icon(Icons.people, size: 20, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text('角色 ${_charIndex + 1}/${_chars.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_chars.length > 1)
                          IconButton(
                              onPressed: () {
                                final items = List.generate(
                                    _chars.length,
                                    (i) => PopupMenuItem(
                                        value: i,
                                        child: Text(_chars[i].nameCtrl.text)));
                                showMenu<int>(
                                        context: context,
                                        items: items,
                                        position: const RelativeRect.fromLTRB(
                                            100, 100, 100, 100))
                                    .then(_switchCharacter);
                              },
                              icon: const Icon(Icons.swap_horiz),
                              tooltip: '切换角色'),
                        TextButton.icon(
                            onPressed: _addCharacter,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('添加角色')),
                      ]),
                    ),
                    _CharacterTab(
                      nameCtrl: _cur.nameCtrl,
                      classCtrl: _cur.classCtrl,
                      additionalClasses: _cur.additionalClasses,
                      onAddClass: _addClass,
                      race: _cur.race,
                      onRaceChanged: (v) => setState(() => _cur.race = v ?? '人类'),
                      level: _cur.level,
                      onLevelChanged: (v) => setState(() => _cur.level = v),
                      skills: _cur.skills,
                      onAddSkill: _addSkill,
                      strength: _cur.strength,
                      dexterity: _cur.dexterity,
                      constitution: _cur.constitution,
                      intelligence: _cur.intelligence,
                      wisdom: _cur.wisdom,
                      charisma: _cur.charisma,
                      remainingPoints: _cur.remainingPoints,
                      onAdjust: _adjustStat,
                    ),
                  ]),
                  _MapListTab(maps: _maps, onAdd: _addMap),
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
                  label: Text(_isSaving ? '保存中...' : '保存存档',
                      style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
    required this.classCtrl,
    required this.additionalClasses,
    required this.onAddClass,
    required this.race,
    required this.onRaceChanged,
    required this.level,
    required this.onLevelChanged,
    required this.skills,
    required this.onAddSkill,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.remainingPoints,
    required this.onAdjust,
  });

  final TextEditingController nameCtrl;
  final TextEditingController classCtrl;
  final List<String> additionalClasses;
  final VoidCallback onAddClass;
  final String race;
  final ValueChanged<String?> onRaceChanged;
  final int level;
  final ValueChanged<int> onLevelChanged;
  final List<SkillData> skills;
  final VoidCallback onAddSkill;
  final int strength, dexterity, constitution;
  final int intelligence, wisdom, charisma;
  final int remainingPoints;
  final void Function(String stat, int delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('角色信息',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
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
          TextFormField(
            controller: classCtrl,
            decoration: const InputDecoration(
              labelText: '职业',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shield_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('附加职业 (${additionalClasses.length})',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Spacer(),
            TextButton.icon(
                onPressed: onAddClass,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加职业')),
          ]),
          if (additionalClasses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 8,
                children: additionalClasses
                    .map((c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 13))))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: race,
            decoration: const InputDecoration(
                labelText: '种族', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: '人类', child: Text('人类')),
              DropdownMenuItem(value: '精灵', child: Text('精灵')),
              DropdownMenuItem(value: '矮人', child: Text('矮人')),
              DropdownMenuItem(value: '半身人', child: Text('半身人')),
              DropdownMenuItem(value: '龙裔', child: Text('龙裔')),
              DropdownMenuItem(value: '兽人', child: Text('兽人')),
            ],
            onChanged: onRaceChanged,
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('等级', style: TextStyle(fontSize: 16)),
            const Spacer(),
            IconButton(
                onPressed: level > 1
                    ? () => onLevelChanged(level - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline)),
            SizedBox(
                width: 36,
                child: Text('$level',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(
                onPressed: () => onLevelChanged(level + 1),
                icon: const Icon(Icons.add_circle_outline)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text('技能 (${skills.length})',
                style: const TextStyle(fontSize: 16)),
            const Spacer(),
            TextButton.icon(
                onPressed: onAddSkill,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加技能')),
          ]),
          if (skills.isNotEmpty)
            Wrap(
              spacing: 8,
              children: skills
                  .map((s) => Chip(
                      label: Text(
                          s.diceType != null ? '${s.name} (${s.diceType})' : s.name,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
            ),
          const SizedBox(height: 24),
          Row(children: [
            Text('属性分配',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Card(
              color: remainingPoints > 0
                  ? Colors.deepPurple.shade50
                  : Colors.grey.shade100,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '剩余点数：$remainingPoints',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        remainingPoints > 0 ? Colors.deepPurple : Colors.grey,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _StatLine('力量', strength, Icons.fitness_center,
              remainingPoints > 0 && strength < 20, onAdjust),
          _StatLine('敏捷', dexterity, Icons.directions_run,
              remainingPoints > 0 && dexterity < 20, onAdjust),
          _StatLine('体质', constitution, Icons.favorite_outline,
              remainingPoints > 0 && constitution < 20, onAdjust),
          _StatLine('智力', intelligence, Icons.psychology_outlined,
              remainingPoints > 0 && intelligence < 20, onAdjust),
          _StatLine('感知', wisdom, Icons.visibility_outlined,
              remainingPoints > 0 && wisdom < 20, onAdjust),
          _StatLine('魅力', charisma, Icons.emoji_emotions_outlined,
              remainingPoints > 0 && charisma < 20, onAdjust),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine(
      this.label, this.value, this.icon, this.canIncrement, this.onAdjust);

  final String label;
  final int value;
  final IconData icon;
  final bool canIncrement;
  final void Function(String, int) onAdjust;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          SizedBox(
              width: 48,
              child:
                  Text(label, style: const TextStyle(fontSize: 16))),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed:
                value > 0 ? () => onAdjust(label, -1) : null,
            tooltip: '减少',
          ),
          SizedBox(
            width: 36,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed:
                canIncrement ? () => onAdjust(label, 1) : null,
            tooltip: '增加',
          ),
        ]),
      ),
    );
  }
}

// ─── 地图列表 Tab ───
class _MapListTab extends StatelessWidget {
  const _MapListTab({required this.maps, required this.onAdd});

  final List<MapData> maps;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('地图列表',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('已添加 ${maps.length} 张地图',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label:
                  const Text('添加地图', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: maps.isEmpty
                ? Center(
                    child: Text('暂无地图，点击上方按钮添加',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: maps.length,
                    itemBuilder: (_, i) {
                      final m = maps[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.map_outlined,
                              color: Colors.deepPurple),
                          title: Text(m.name,
                              style: const TextStyle(fontSize: 16)),
                          subtitle: Text(
                              '${m.width}×${m.height} · ${m.tiles.length} 地块${m.description.isNotEmpty ? ' · ${m.description}' : ''}'),
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
          Text('物品列表',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('已添加 ${items.length} 件物品',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label:
                  const Text('添加物品', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('暂无物品，点击上方按钮添加',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.deepPurple),
                          title: Text(it.name,
                              style: const TextStyle(fontSize: 16)),
                          subtitle: Text(
                              '${it.type} · ×${it.quantity} · ${it.weight}磅 · ${it.value}金币${it.description.isNotEmpty ? ' · ${it.description}' : ''}'),
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
  int _width = 20, _height = 20;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加地图'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: '地图名称', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: '描述', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: '宽度', border: OutlineInputBorder()),
                onChanged: (v) => _width = int.tryParse(v) ?? 20,
              ),
            ),
            const SizedBox(width: 12),
            Text('×',
                style:
                    TextStyle(fontSize: 20, color: Colors.grey[600])),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: '高度', border: OutlineInputBorder()),
                onChanged: (v) => _height = int.tryParse(v) ?? 20,
              ),
            ),
          ]),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            widget.onSave(MapData(
              name: name,
              description: _descCtrl.text.trim(),
              width: _width,
              height: _height,
            ));
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

  static const _types = [
    '武器',
    '防具',
    '药水',
    '卷轴',
    '杂物',
    '饰品',
    '食物',
    '材料'
  ];

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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: '物品名称', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
                labelText: '类型', border: OutlineInputBorder()),
            items: _types
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? '杂物'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: '描述', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: '数量', border: OutlineInputBorder()),
                onChanged: (v) => _quantity = int.tryParse(v) ?? 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: '重量(磅)',
                    border: OutlineInputBorder()),
                onChanged: (v) => _weight = int.tryParse(v) ?? 0,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: '价值(金币)',
                border: OutlineInputBorder()),
            onChanged: (v) => _value = int.tryParse(v) ?? 0,
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            widget.onSave(ItemData(
              name: name,
              type: _type,
              description: _descCtrl.text.trim(),
              quantity: _quantity,
              weight: _weight,
              value: _value,
            ));
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

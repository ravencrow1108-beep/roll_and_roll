import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/models/models.dart';
import '../map_editor/map_editor_page.dart';
import 'char_edit_models.dart';
import 'character_tab.dart';
import 'map_dialog.dart';
import 'map_list_tab.dart';
import 'rules_tab.dart';

/// 创建/编辑存档页面：标签页管理角色、地图与规则的完整编辑
class CreateSavePage extends StatefulWidget {
  const CreateSavePage({this.allowMapEdit = true, super.key})
    : _filePath = null,
      _editCharacters = null,
      _editMaps = null,
      _editRules = null;

  /// 编辑已有存档
  const CreateSavePage.edit({
    required String this._filePath,
    required List<CharacterData> characters,
    required List<MapData> maps,
    RuleData? rules,
    this.allowMapEdit = true,
    super.key,
  }) : _editCharacters = characters,
       _editMaps = maps,
       _editRules = rules;

  /// 是否允许编辑地图（玩家为 false，主持为 true）
  final bool allowMapEdit;

  final String? _filePath;
  final List<CharacterData>? _editCharacters;
  final List<MapData>? _editMaps;
  final RuleData? _editRules;

  bool get isEditMode => _filePath != null;

  @override
  State<CreateSavePage> createState() => _CreateSavePageState();
}

extension on _CreateSavePageState {
  bool get _allowMap => widget.allowMapEdit;
  int get _tabCount => _allowMap ? 3 : 2;
}

class _CreateSavePageState extends State<CreateSavePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isSaving = false;

  final List<CharEdit> _chars = [CharEdit()];
  int _charIndex = 0;

  CharEdit get _cur => _chars[_charIndex];

  // ---------- 地图 / 规则 ----------
  final List<MapData> _maps = [];
  final List<String> _turnSettings = [];
  final List<String> _phaseSettings = ['先攻', '战斗'];
  int _backpackSlotMax = 40;
  final List<ItemData> _itemTemplates = [];
  final List<String> _equipmentSlots = ['头盔', '身甲', '手甲', '腿甲', '饰品'];
  final List<EquipmentData> _equipmentTemplates = [];
  final List<SkillData> _skillTemplates = [];
  final List<String> _damageTypes = [
    '火焰',
    '寒冷',
    '雷电',
    '毒素',
    '暗蚀',
    '光耀',
    '力场',
    '精神',
    '坏死',
    '穿刺',
    '挥砍',
    '钝击',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);

    // Pre-populate in edit mode
    if (widget.isEditMode) {
      final editChars = widget._editCharacters ?? [];
      if (editChars.isNotEmpty) {
        _chars.clear();
        for (final c in editChars) {
          _chars.add(_charDataToEdit(c));
        }
      }
      _maps.addAll(widget._editMaps ?? []);
      if (widget._editRules case final r?) {
        _turnSettings.addAll(r.turnSettings);
        _phaseSettings
          ..clear()
          ..addAll(r.phaseSettings);
        _backpackSlotMax = r.backpackSlotMax;
        _itemTemplates.addAll(r.itemTemplates);
        _equipmentSlots
          ..clear()
          ..addAll(r.equipmentSlots);
        _equipmentTemplates.addAll(r.equipmentTemplates);
        _skillTemplates.addAll(r.skillTemplates);
        _damageTypes
          ..clear()
          ..addAll(r.damageTypes);
      }
      // init equipment map for each char
      for (final ce in _chars) {
        ce.equipment.clear();
        for (final slot in _equipmentSlots) {
          ce.equipment[slot] = null;
        }
      }
    }
  }

  CharEdit _charDataToEdit(CharacterData c) {
    final ce = CharEdit();
    ce.nameCtrl.text = c.name;
    ce.classes.clear();
    ce.classes.add(ClassEdit(text: c.className));
    for (final ac in c.additionalClasses) {
      ce.classes.add(ClassEdit(text: ac));
    }
    ce.race = c.race;
    ce.level = c.level;
    ce.skills = c.skills.toList();
    ce.personalities = c.personalities
        .map(
          (p) =>
              PersonalityEdit(trait: p.trait, description: p.description ?? ''),
        )
        .toList();
    ce.backpack = c.backpack.toList();
    ce.equipment.addAll(Map<String, EquipmentData?>.from(c.equipment));
    for (final slot in _equipmentSlots) {
      ce.equipment.putIfAbsent(slot, () => null);
    }
    ce.baseStats['力量'] = c.strength;
    ce.baseStats['敏捷'] = c.dexterity;
    ce.baseStats['体质'] = c.constitution;
    ce.baseStats['智力'] = c.intelligence;
    ce.baseStats['感知'] = c.wisdom;
    ce.baseStats['魅力'] = c.charisma;
    ce.customStats.addAll(Map<String, int>.from(c.customStats));
    ce.hp = c.hp;
    ce.maxHp = c.maxHp;
    ce.portraitBase64 = c.portraitBase64;
    if (c.portraitBase64.isNotEmpty) {
      ce.portraitBytes = base64Decode(c.portraitBase64);
    }
    return ce;
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
      _chars.add(CharEdit());
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

  void _setStatValue(String stat, int value) {
    setState(() {
      if (value < 0 || value > 99) return;
      _setStat(stat, value);
    });
  }

  void _addClass() {
    setState(() => _cur.classes.add(ClassEdit()));
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
    setState(() => _cur.personalities.add(PersonalityEdit()));
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
          MapDialog(onSave: (map) => setState(() => _maps.add(map))),
    );
  }

  void _removeSkill(int index) {
    setState(() => _cur.skills.removeAt(index));
  }

  void _editSkill(int index, SkillData oldSkill) {
    final nameCtrl = TextEditingController(text: oldSkill.name);
    final descCtrl = TextEditingController(text: oldSkill.description ?? '');
    String imageBase64 = oldSkill.imageBase64 ?? '';
    final damages = <_SkillDamageRow>[
      for (final d in oldSkill.damages)
        _SkillDamageRow(
          exprCtrl: TextEditingController(text: d.expression ?? ''),
          dmgType: d.damageType,
        ),
    ];
    if (damages.isEmpty) {
      damages.add(_SkillDamageRow(exprCtrl: TextEditingController()));
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('编辑技能'),
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
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      dialogTitle: '选择技能图标',
                      type: FileType.image,
                    );
                    if (result != null && result.files.single.path != null) {
                      final bytes = await File(
                        result.files.single.path!,
                      ).readAsBytes();
                      setDialogState(() => imageBase64 = base64Encode(bytes));
                    }
                  },
                  icon: const Icon(Icons.image, size: 18),
                  label: Text(imageBase64.isEmpty ? '上传图标' : '已选择图标'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      '技能伤害',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setDialogState(
                        () => damages.add(
                          _SkillDamageRow(exprCtrl: TextEditingController()),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                ...List.generate(
                  damages.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: damages[i].exprCtrl,
                            decoration: const InputDecoration(
                              labelText: '表达式',
                              hintText: '1d6+3',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String?>(
                            initialValue:
                                _damageTypes.contains(damages[i].dmgType)
                                ? damages[i].dmgType
                                : null,
                            decoration: const InputDecoration(
                              labelText: '伤害类型',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  '无',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              ..._damageTypes.map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => damages[i].dmgType = v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: damages.length <= 1
                              ? null
                              : () => setDialogState(() => damages.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  _cur.skills[index] = SkillData(
                    name: name,
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    imageBase64: imageBase64.isEmpty ? null : imageBase64,
                    damages: damages
                        .where((r) => r.exprCtrl.text.trim().isNotEmpty)
                        .map(
                          (r) => SkillDamage(
                            expression: r.exprCtrl.text.trim(),
                            damageType: r.dmgType,
                          ),
                        )
                        .toList(),
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeMap(int index) {
    setState(() => _maps.removeAt(index));
  }

  Future<void> _editMapInList(int index) async {
    final map = _maps[index];

    // 从存档加载已有角色位置
    List<PlayerPosition> positions = [];
    if (widget.isEditMode && widget._filePath != null) {
      try {
        final save = await SaveData.fromZip(widget._filePath!);
        positions = save.playerPositions;
      } catch (_) {}
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapEditorPage(
          mapData: map,
          onSave: (updated) => setState(() => _maps[index] = updated),
          saveFilePath: widget.isEditMode ? widget._filePath : null,
          initialPositions: positions,
        ),
      ),
    );
  }

  void _removeBackpackItem(int index) {
    setState(() => _cur.backpack.removeAt(index));
  }

  void _addItemFromTemplate(ItemData template) {
    if (_cur.backpack.length >= _backpackSlotMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('背包已满'), duration: Duration(seconds: 1)),
      );
      return;
    }
    setState(() => _cur.backpack.add(template));
  }

  Future<void> _pickPortrait() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择角色头像',
      type: FileType.image,
    );
    if (result == null || result.files.single.path == null) return;
    final bytes = await File(result.files.single.path!).readAsBytes();
    if (!mounted) return;
    setState(() {
      _cur.portraitBytes = bytes;
      _cur.portraitBase64 = base64Encode(bytes);
    });
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认保存'),
        content: const Text('当前操作会覆盖旧的存档，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _isSaving = true);
    try {
      final save = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: _chars.map((c) => c.toCharacterData()).toList(),
        maps: _maps,
        rules: RuleData(
          turnSettings: List<String>.from(_turnSettings),
          phaseSettings: List<String>.from(_phaseSettings),
          backpackSlotMax: _backpackSlotMax,
          itemTemplates: List<ItemData>.from(_itemTemplates),
          equipmentSlots: List<String>.from(_equipmentSlots),
          equipmentTemplates: List<EquipmentData>.from(_equipmentTemplates),
          skillTemplates: List<SkillData>.from(_skillTemplates),
          damageTypes: List<String>.from(_damageTypes),
        ),
      );

      if (widget.isEditMode) {
        // Edit mode: overwrite existing file
        await save.packToZip(widget._filePath!);
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('存档已更新'), backgroundColor: Colors.green),
        );
        return;
      }

      final fileName =
          '${_chars.first.nameCtrl.text.trim()}_${DateTime.now().millisecondsSinceEpoch}.zip';
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: '保存存档文件 (ZIP)',
        fileName: fileName,
        type: FileType.any,
      );
      if (outputPath == null) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      if (!outputPath.endsWith('.zip')) {
        outputPath = '$outputPath.zip';
      }
      await save.packToZip(outputPath);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('存档已保存 (角色:${_chars.length} 地图:${_maps.length})'),
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

  /// 另存为：始终弹出文件选择器保存到新文件
  Future<void> _saveAs() async {
    setState(() => _isSaving = true);
    try {
      final save = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: _chars.map((c) => c.toCharacterData()).toList(),
        maps: _maps,
        rules: RuleData(
          turnSettings: List<String>.from(_turnSettings),
          phaseSettings: List<String>.from(_phaseSettings),
          backpackSlotMax: _backpackSlotMax,
          itemTemplates: List<ItemData>.from(_itemTemplates),
          equipmentSlots: List<String>.from(_equipmentSlots),
          equipmentTemplates: List<EquipmentData>.from(_equipmentTemplates),
          skillTemplates: List<SkillData>.from(_skillTemplates),
          damageTypes: List<String>.from(_damageTypes),
        ),
      );

      final first = _chars.first.nameCtrl.text.trim();
      final fileName =
          '${first.isEmpty ? 'archive' : first}_${DateTime.now().millisecondsSinceEpoch}.zip';
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: '另存为',
        fileName: fileName,
        type: FileType.any,
      );
      if (outputPath == null) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      if (!outputPath.endsWith('.zip')) {
        outputPath = '$outputPath.zip';
      }
      await save.packToZip(outputPath);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已另存为 $outputPath'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, outputPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('另存失败：$e'), backgroundColor: Colors.red),
      );
    }
  }

  /// 构建标签页布局，包含角色编辑、地图列表与规则设置面板
  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[const Tab(icon: Icon(Icons.person), text: '角色')];
    if (_allowMap) {
      tabs.add(const Tab(icon: Icon(Icons.map_outlined), text: '地图'));
    }
    tabs.add(const Tab(icon: Icon(Icons.rule), text: '规则'));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? '修改存档' : '创建存档'),
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
                        child: CharacterTab(
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
                          hp: _cur.hp,
                          maxHp: _cur.maxHp,
                          onHpChanged: (v) => setState(() => _cur.hp = v),
                          onMaxHpChanged: (v) => setState(() => _cur.maxHp = v),
                          skills: _cur.skills,
                          onRemoveSkill: _removeSkill,
                          onEditSkill: _editSkill,
                          skillTemplates: _skillTemplates,
                          onAddSkillFromTemplate: (s) {
                            setState(
                              () => _cur.skills.add(
                                SkillData(
                                  name: s.name,
                                  description: s.description,
                                  imageBase64: s.imageBase64,
                                  damages: List<SkillDamage>.from(s.damages),
                                ),
                              ),
                            );
                          },
                          backpack: _cur.backpack,
                          itemTemplates: _itemTemplates,
                          onAddBackpackItem: _addItemFromTemplate,
                          onRemoveBackpackItem: _removeBackpackItem,
                          equipment: _cur.equipment,
                          equipmentSlots: _equipmentSlots,
                          equipmentTemplates: _equipmentTemplates,
                          onEquipItem: (slot, eq) {
                            setState(() => _cur.equipment[slot] = eq);
                          },
                          onUnequipItem: (slot) {
                            setState(() => _cur.equipment[slot] = null);
                          },
                          personalities: _cur.personalities,
                          onAddPersonality: _addPersonality,
                          onRemovePersonality: _removePersonality,
                          baseStats: _cur.baseStats,
                          customStats: _cur.customStats,
                          onAddCustomStat: _addCustomStat,
                          onRemoveCustomStat: _removeCustomStat,
                          onRemoveBaseStat: _removeBaseStat,
                          onAdjust: _adjustStat,
                          onStatChanged: _setStatValue,
                          portraitBase64: _cur.portraitBase64,
                          portraitBytes: _cur.portraitBytes,
                          onPickPortrait: _pickPortrait,
                        ),
                      ),
                    ],
                  ),
                  if (_allowMap)
                    MapListTab(
                      maps: _maps,
                      onAdd: _addMap,
                      onDelete: _removeMap,
                      onEdit: (i) => _editMapInList(i),
                    ),
                  RulesTab(
                    turnSettings: _turnSettings,
                    phaseSettings: _phaseSettings,
                    backpackSlotMax: _backpackSlotMax,
                    itemTemplates: _itemTemplates,
                    equipmentSlots: _equipmentSlots,
                    equipmentTemplates: _equipmentTemplates,
                    onAddItemTemplate: (item) {
                      setState(() => _itemTemplates.add(item));
                    },
                    onRemoveItemTemplate: (i) {
                      setState(() => _itemTemplates.removeAt(i));
                    },
                    onEditItemTemplate: (i, item) {
                      setState(() => _itemTemplates[i] = item);
                    },
                    onAddEquipmentTemplate: (eq) {
                      setState(() => _equipmentTemplates.add(eq));
                    },
                    onRemoveEquipmentTemplate: (i) {
                      setState(() => _equipmentTemplates.removeAt(i));
                    },
                    onEditEquipmentTemplate: (i, eq) {
                      setState(() => _equipmentTemplates[i] = eq);
                    },
                    skillTemplates: _skillTemplates,
                    onAddSkillTemplate: (s) {
                      setState(() => _skillTemplates.add(s));
                    },
                    onRemoveSkillTemplate: (i) {
                      setState(() => _skillTemplates.removeAt(i));
                    },
                    onEditSkillTemplate: (i, s) {
                      setState(() => _skillTemplates[i] = s);
                    },
                    damageTypes: _damageTypes,
                    onAddDamageType: (t) {
                      if (t.isEmpty) return;
                      setState(() => _damageTypes.add(t));
                    },
                    onRemoveDamageType: (i) {
                      setState(() => _damageTypes.removeAt(i));
                    },
                    onAddEquipmentSlot: (name) {
                      if (name.isEmpty) return;
                      setState(() {
                        _equipmentSlots.add(name);
                        for (final ce in _chars) {
                          ce.equipment[name] = null;
                        }
                      });
                    },
                    onRemoveEquipmentSlot: (i) {
                      final slot = _equipmentSlots[i];
                      setState(() {
                        _equipmentSlots.removeAt(i);
                        for (final ce in _chars) {
                          ce.equipment.remove(slot);
                        }
                      });
                    },
                    onBackpackSlotMaxChanged: (v) {
                      setState(() => _backpackSlotMax = v);
                    },
                    onAddTurn: () {
                      setState(() => _turnSettings.add(''));
                    },
                    onRemoveTurn: (i) {
                      setState(() => _turnSettings.removeAt(i));
                    },
                    onTurnChanged: (i, v) {
                      setState(() => _turnSettings[i] = v);
                    },
                    onAddPhase: () {
                      setState(() => _phaseSettings.add(''));
                    },
                    onRemovePhase: (i) {
                      setState(() => _phaseSettings.removeAt(i));
                    },
                    onPhaseChanged: (i, v) {
                      setState(() => _phaseSettings[i] = v);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
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
                        _isSaving
                            ? '保存中...'
                            : (widget.isEditMode ? '保存修改' : '保存存档'),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAs,
                      icon: const Icon(Icons.save_as_outlined),
                      label: const Text('另存为', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillDamageRow {
  final TextEditingController exprCtrl;
  String? dmgType;
  _SkillDamageRow({required this.exprCtrl, this.dmgType});
}

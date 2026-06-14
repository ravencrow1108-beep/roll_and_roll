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

  Future<void> _editMapInList(int index) async {
    final map = _maps[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapEditorPage(
          mapData: map,
          onSave: (updated) => setState(() => _maps[index] = updated),
        ),
      ),
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
    setState(() => _isSaving = true);
    try {
      final save = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: _chars.map((c) => c.toCharacterData()).toList(),
        maps: _maps,
        rules: RuleData(
          turnSettings: List<String>.from(_turnSettings),
          phaseSettings: List<String>.from(_phaseSettings),
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
            ),
          ],
        ),
      ),
    );
  }
}

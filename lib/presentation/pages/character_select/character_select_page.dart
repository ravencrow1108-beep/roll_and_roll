import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../adventure/adventure_page.dart';
import '../create_save/char_edit_models.dart';
import '../create_save/character_tab.dart';

/// 角色选择页面：加载存档角色、编辑技能并准备开始冒险
class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({
    required this.playerName,
    required this.role,
    this.saveFilePath,
    this.hostSaveName = '',
    super.key,
  });

  final String playerName;
  final String role;
  final String? saveFilePath;
  final String hostSaveName;

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  CharacterData? _character;
  String? _saveFilePath;
  String _saveFileName = '未选择';
  List<CharacterData> _loadedCharacters = [];

  bool _isReady = false;
  bool _hostSettingUp = false;
  String _hostSaveName = '';

  StreamSubscription<String>? _msgSub;

  @override
  void initState() {
    super.initState();
    _saveFilePath = (widget.saveFilePath?.isEmpty ?? true)
        ? null
        : widget.saveFilePath;
    _hostSaveName = widget.hostSaveName;
    if (_saveFilePath != null) {
      _saveFileName = _saveFilePath!.split('/').last.split('\\').last;
      _loadSaveData();
    }

    // Listen for server messages (adventure_started)
    final client = RoomSession.instance.clientHandle;
    if (client != null) {
      _msgSub = client.messages.listen(_handleMessage);
    }
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message.trim()) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      if (type == 'adventure_started') {
        if (!mounted) return;
        if (data['map'] != null) {
          RoomSession.instance.mapNotifier.value = MapData.fromJson(
            data['map'] as Map<String, dynamic>,
          );
        }
        final positions = data['positions'] as List<dynamic>?;
        if (positions != null) {
          RoomSession.instance.playerPositionsNotifier.value = positions
              .map((p) => PlayerPosition.fromJson(p as Map<String, dynamic>))
              .toList();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdventurePage(
              playerName: widget.playerName,
              role: widget.role,
              saveFilePath: _saveFilePath,
              character: _character,
            ),
          ),
        );
      } else if (type == 'host_setting_up') {
        if (mounted) setState(() => _hostSettingUp = true);
      } else if (type == 'host_save_changed') {
        _hostSaveName = data['fileName'] as String? ?? '';
        if (mounted) setState(() {});
      } else if (type == 'return_to_room') {
        if (mounted) Navigator.of(context).pop();
      } else if (type == 'host_disconnected') {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (_) {}
  }

  Future<void> _loadSaveData() async {
    if (_saveFilePath == null) return;
    try {
      final save = await SaveData.fromZip(_saveFilePath!);
      _loadedCharacters = save.characters;
    } catch (_) {
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
      _character = null;
      _isReady = false;
    });
    _loadSaveData();
  }

  void _selectCharacter(CharacterData c) {
    setState(() => _character = c);
  }

  Future<void> _navigateToAddCharacter() async {
    final result = await Navigator.push<CharacterData>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddCharacterPage(saveFilePath: _saveFilePath),
      ),
    );
    if (result != null && mounted) {
      await _appendCharacterToSave(result);
    }
  }

  Future<void> _navigateToEditCharacter(int index) async {
    final existing = _loadedCharacters[index];
    final result = await Navigator.push<CharacterData>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _AddCharacterPage(saveFilePath: _saveFilePath, existing: existing),
      ),
    );
    if (result != null && mounted) {
      await _updateCharacterInSave(index, result);
      if (_character != null && _character!.name == existing.name) {
        setState(() => _character = result);
      }
    }
  }

  Future<void> _appendCharacterToSave(CharacterData character) async {
    if (_saveFilePath == null) return;
    try {
      final save = await SaveData.fromZip(_saveFilePath!);
      final updated = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: [...save.characters, character],
        maps: save.maps,
        rules: save.rules,
      );
      await updated.packToZip(_saveFilePath!);
      await _loadSaveData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('角色「${character.name}」已添加到存档'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateCharacterInSave(int index, CharacterData updated) async {
    if (_saveFilePath == null) return;
    try {
      final save = await SaveData.fromZip(_saveFilePath!);
      final chars = [...save.characters];
      if (index >= 0 && index < chars.length) {
        chars[index] = updated;
      }
      final newSave = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: chars,
        maps: save.maps,
        rules: save.rules,
      );
      await newSave.packToZip(_saveFilePath!);
      await _loadSaveData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('角色「${updated.name}」已更新'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editSkill(CharacterData c, SkillData oldSkill) {
    final nameCtrl = TextEditingController(text: oldSkill.name);
    final descCtrl = TextEditingController(text: oldSkill.description ?? '');
    final diceCtrl = TextEditingController(text: oldSkill.diceType ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                  hintText: '如: 2d6+3, d20+力量',
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
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final idx = _loadedCharacters.indexOf(c);
              final updatedSkills = c.skills.toList();
              final oldIdx = updatedSkills.indexOf(oldSkill);
              if (oldIdx >= 0) {
                updatedSkills[oldIdx] = SkillData(
                  name: name,
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  diceType: diceCtrl.text.trim().isEmpty
                      ? null
                      : diceCtrl.text.trim(),
                );
              }
              final updated = c.copyWith(skills: updatedSkills);
              Navigator.pop(ctx);
              if (idx >= 0) {
                await _updateCharacterInSave(idx, updated);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _removeSkill(CharacterData c, SkillData skill) {
    final idx = _loadedCharacters.indexOf(c);
    final updatedSkills = c.skills.where((s) => s != skill).toList();
    final updated = c.copyWith(skills: updatedSkills);
    if (idx >= 0) {
      _updateCharacterInSave(idx, updated);
    }
  }

  void _markReady() {
    if (_character == null) return;
    setState(() => _isReady = true);
    RoomSession.instance.setPlayerReady(widget.playerName);
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  /// 根据已选角色切换显示角色详情或选择列表
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── 已选定角色 → 角色详情 ──
    if (_character != null) {
      return _buildCharacterView(theme);
    }

    // ── 角色选择页 ──
    return _buildCharacterSelection(theme);
  }

  /// 构建角色详情视图，显示属性、技能与准备按钮
  Widget _buildCharacterView(ThemeData theme) {
    final c = _character!;
    final idx = _loadedCharacters.indexOf(c);
    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _character = null),
        ),
        actions: [
          if (_saveFilePath != null && idx >= 0)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '编辑角色',
              onPressed: () => _navigateToEditCharacter(idx),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '欢迎，${c.name}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (c.portraitBase64.isNotEmpty)
                  ClipOval(
                    child: Image.memory(
                      base64Decode(c.portraitBase64),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                Text('职业: ${c.className}'),
                Text('种族: ${c.race} · Lv${c.level}'),
                if (c.skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '技能',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      children: c.skills
                          .map(
                            (s) => Card(
                              child: ListTile(
                                title: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (s.diceType != null)
                                      Text('骰子: ${s.diceType}'),
                                    if (s.description != null &&
                                        s.description!.isNotEmpty)
                                      Text(s.description!),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      tooltip: '编辑技能',
                                      onPressed: () => _editSkill(c, s),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      tooltip: '删除技能',
                                      onPressed: () => _removeSkill(c, s),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
                if (_hostSaveName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.save,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '房主备档: $_hostSaveName',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (!_isReady)
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: _markReady,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('准备', style: TextStyle(fontSize: 18)),
                    ),
                  )
                else if (_hostSettingUp)
                  Card(
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          SizedBox(height: 12),
                          Text('主持正在布置地图…'),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    color: Colors.green.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('已准备，等待主持开始…'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建角色选择列表、存档加载与新建角色入口
  Widget _buildCharacterSelection(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择角色')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你好，${widget.playerName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              if (_hostSettingUp)
                Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(height: 12),
                        Text('主持正在布置地图…'),
                      ],
                    ),
                  ),
                ),

              if (_hostSaveName.isNotEmpty)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(Icons.save, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '房主备档: $_hostSaveName',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── 存档选择 ──
              Text(
                '从存档中选择角色',
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

              // ── 已加载的角色列表 ──
              if (_loadedCharacters.isNotEmpty) ...[
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _loadedCharacters.length,
                    itemBuilder: (_, i) {
                      final c = _loadedCharacters[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: c.portraitBase64.isNotEmpty
                                ? MemoryImage(base64Decode(c.portraitBase64))
                                : null,
                            child: c.portraitBase64.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${c.className} · ${c.race} · Lv${c.level}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: '编辑角色',
                                onPressed: () => _navigateToEditCharacter(i),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () => _selectCharacter(c),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_saveFilePath != null) ...[
                const SizedBox(height: 12),
                Text('该存档中没有角色', style: TextStyle(color: Colors.grey.shade600)),
              ],

              const SizedBox(height: 24),

              // ── 创建新角色 ──
              if (_saveFilePath != null) ...[
                Text(
                  '或新建角色到当前存档',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _navigateToAddCharacter,
                    icon: const Icon(Icons.person_add),
                    label: const Text(
                      '在当前存档新建角色',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  在当前存档新建角色页面（复用 CharacterTab）
// ═══════════════════════════════════════════════════════

/// 在当前存档新建或编辑角色的页面，复用 CharacterTab 组件
class _AddCharacterPage extends StatefulWidget {
  const _AddCharacterPage({required this.saveFilePath, this.existing});

  final String? saveFilePath;
  final CharacterData? existing;

  @override
  State<_AddCharacterPage> createState() => _AddCharacterPageState();
}

class _AddCharacterPageState extends State<_AddCharacterPage> {
  late final CharEdit _char = _initChar();

  bool get _isEdit => widget.existing != null;

  CharEdit _initChar() {
    if (widget.existing case final e?) {
      final ce = CharEdit();
      ce.nameCtrl.text = e.name;
      ce.classes
        ..clear()
        ..add(ClassEdit(text: e.className));
      for (final ac in e.additionalClasses) {
        ce.classes.add(ClassEdit(text: ac));
      }
      ce.race = e.race;
      ce.level = e.level;
      ce.skills = e.skills.toList();
      ce.personalities = e.personalities
          .map(
            (p) => PersonalityEdit(
              trait: p.trait,
              description: p.description ?? '',
            ),
          )
          .toList();
      ce.backpack = e.backpack.toList();
      ce.baseStats['力量'] = e.strength;
      ce.baseStats['敏捷'] = e.dexterity;
      ce.baseStats['体质'] = e.constitution;
      ce.baseStats['智力'] = e.intelligence;
      ce.baseStats['感知'] = e.wisdom;
      ce.baseStats['魅力'] = e.charisma;
      ce.customStats.addAll(Map<String, int>.from(e.customStats));
      ce.hp = e.hp;
      ce.maxHp = e.maxHp;
      ce.portraitBase64 = e.portraitBase64;
      if (e.portraitBase64.isNotEmpty) {
        ce.portraitBytes = base64Decode(e.portraitBase64);
      }
      return ce;
    }
    return CharEdit();
  }

  int _getStat(String s) => _char.baseStats[s] ?? _char.customStats[s] ?? 0;
  void _setStat(String s, int v) {
    if (_char.baseStats.containsKey(s)) {
      _char.baseStats[s] = v;
    } else {
      _char.customStats[s] = v;
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

  Future<void> _pickPortrait() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择角色头像',
      type: FileType.image,
    );
    if (result == null || result.files.single.path == null) return;
    final bytes = await File(result.files.single.path!).readAsBytes();
    if (!mounted) return;
    setState(() {
      _char.portraitBytes = bytes;
      _char.portraitBase64 = base64Encode(bytes);
    });
  }

  void _submit() {
    final name = _char.nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先输入角色名称'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.pop(context, _char.toCharacterData());
  }

  /// 构建角色编辑表单与提交按钮
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑角色' : '新建角色到当前存档')),
      body: Column(
        children: [
          Expanded(
            child: CharacterTab(
              nameCtrl: _char.nameCtrl,
              classes: _char.classes,
              onAddClass: () => setState(() => _char.classes.add(ClassEdit())),
              onRemoveClass: (i) {
                if (_char.classes.length <= 1) return;
                setState(() {
                  _char.classes[i].dispose();
                  _char.classes.removeAt(i);
                });
              },
              race: _char.race,
              raceCustom: _char.raceCustom,
              raceCtrl: _char.raceCtrl,
              onRaceChanged: (v) {
                if (v == '__custom__') {
                  setState(() => _char.raceCustom = true);
                } else {
                  setState(() {
                    _char.raceCustom = false;
                    _char.race = v ?? '人类';
                  });
                }
              },
              level: _char.level,
              onLevelChanged: (v) => setState(() => _char.level = v),
              hp: _char.hp,
              maxHp: _char.maxHp,
              onHpChanged: (v) => setState(() => _char.hp = v),
              onMaxHpChanged: (v) => setState(() => _char.maxHp = v),
              skills: _char.skills,
              onAddSkill: () {
                // inline skill add
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
                              hintText: '如: 2d6+3, d20+力量',
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
                          setState(() {
                            _char.skills.add(
                              SkillData(
                                name: s,
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                diceType: diceCtrl.text.trim().isEmpty
                                    ? null
                                    : diceCtrl.text.trim(),
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                );
              },
              backpack: _char.backpack,
              onAddBackpackItem: () {
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
                          setState(() {
                            _char.backpack.add(
                              ItemData(
                                name: s,
                                type: '背包物品',
                                description: descCtrl.text.trim(),
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                );
              },
              onRemoveBackpackItem: (i) =>
                  setState(() => _char.backpack.removeAt(i)),
              personalities: _char.personalities,
              onAddPersonality: () =>
                  setState(() => _char.personalities.add(PersonalityEdit())),
              onRemovePersonality: (i) {
                setState(() {
                  _char.personalities[i].dispose();
                  _char.personalities.removeAt(i);
                });
              },
              baseStats: _char.baseStats,
              customStats: _char.customStats,
              onAddCustomStat: () {
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
                          final val = int.tryParse(valueCtrl.text.trim()) ?? 10;
                          setState(
                            () => _char.customStats[name] = val.clamp(0, 20),
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                );
              },
              onRemoveCustomStat: (name) =>
                  setState(() => _char.customStats.remove(name)),
              onRemoveBaseStat: (stat) =>
                  setState(() => _char.baseStats.remove(stat)),
              onAdjust: _adjustStat,
              onStatChanged: _setStatValue,
              portraitBase64: _char.portraitBase64,
              portraitBytes: _char.portraitBytes,
              onPickPortrait: _pickPortrait,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(_isEdit ? Icons.save : Icons.person_add),
                label: Text(
                  _isEdit ? '保存修改' : '添加到当前存档',
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
    );
  }
}

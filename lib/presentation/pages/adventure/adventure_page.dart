import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../../../data/services/socket_support.dart';
import '../../../data/services/voice_service.dart';
import '../create_save/create_save_page.dart';
import 'character_views.dart';
import 'map_display.dart';
import 'map_views.dart';
import 'chat_panel.dart';

/// 冒险主页面：骰子投掷、地图显示、聊天面板与角色管理
class AdventurePage extends StatefulWidget {
  const AdventurePage({
    required this.playerName,
    required this.role,
    this.saveFilePath,
    this.character,
    super.key,
  });

  final String playerName;
  final String role;
  final String? saveFilePath;
  final CharacterData? character;

  @override
  State<AdventurePage> createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  CharacterData? _character;
  MapData? _selectedMap;
  String? _saveFilePath;
  String _saveFileName = '未选择';
  List<CharacterData> _loadedCharacters = [];
  List<MapData> _loadedMaps = [];
  RuleData _loadedRules = const RuleData();

  bool _isReady = false;
  bool _adventureStarted = false;
  MapData? _displayedMap;

  // --- Chat floating ---
  bool _isChatOpen = false;

  // --- Dice rolling ---
  final TextEditingController _diceInputCtrl = TextEditingController();
  String _diceResult = '';

  // --- Chat ---
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();

  // --- Left panel: selected player detail ---
  String? _selectedPlayerName;

  // --- Deploy mode: right-click character → click map to place ---
  CharacterData? _deployCharacter;

  // --- Voice ---
  final VoiceService _voice = VoiceService.instance;

  StreamSubscription<String>? _msgSub;

  bool get _isGM => widget.role == '主持';

  @override
  void initState() {
    super.initState();
    _character = widget.character;
    _saveFilePath = widget.saveFilePath;
    if (_saveFilePath != null) {
      _saveFileName = _saveFilePath!.split('/').last.split('\\').last;
      _loadSaveData();
    }

    final session = RoomSession.instance;
    if (session.mapNotifier.value != null) {
      _adventureStarted = true;
      _displayedMap = session.mapNotifier.value;
    }
    final stream = _isGM
        ? session.serverHandle?.messages
        : session.clientHandle?.messages;
    _msgSub = stream?.listen(_handleMessage);
    session.readyMembersNotifier.addListener(_onReadyChanged);
    session.mapNotifier.addListener(_onMapChanged);
    session.playerPositionsNotifier.addListener(_onPositionsChanged);

    // 语音：录音数据通过 socket 发送
    _voice.onAudioCaptured = (pcm) {
      final b64 = base64Encode(pcm);
      final msg = {
        'type': 'voice_data',
        'from': widget.playerName,
        'data': b64,
      };
      if (_isGM) {
        RoomSession.instance.broadcast(msg);
      } else {
        RoomSession.instance.clientHandle?.send(socketEncode(msg));
      }
    };

    // 语音 UI 状态刷新
    _voice.isInChannel.addListener(_onVoiceStateChanged);
    _voice.isMuted.addListener(_onVoiceStateChanged);
    _voice.speakingMembers.addListener(_onVoiceStateChanged);
  }

  void _onVoiceStateChanged() {
    if (mounted) setState(() {});
  }

  void _onReadyChanged() {
    if (mounted) setState(() {});
  }

  void _onMapChanged() {
    if (mounted && RoomSession.instance.mapNotifier.value != null) {
      setState(() {
        _adventureStarted = true;
        _displayedMap = RoomSession.instance.mapNotifier.value;
      });
    }
  }

  void _onPositionsChanged() {
    if (mounted) setState(() {});
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message.trim()) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      if (type == 'chat_message') {
        _addChat(data['from'] as String? ?? '', data['text'] as String? ?? '');
        if (_isGM) RoomSession.instance.broadcast(data);
        return;
      }

      if (type == 'voice_data') {
        _voice.playVoiceData(
          data['from'] as String? ?? '',
          data['data'] as String? ?? '',
        );
        return;
      }

      if (type == 'voice_join') {
        if (mounted) setState(() {});
        return;
      }

      if (type == 'voice_leave') {
        if (mounted) setState(() {});
        return;
      }

      if (_isGM) {
        if (type == 'player_ready') {
          RoomSession.instance.onPlayerReady(data['name'] as String? ?? '');
          _checkAllReady();
        }
      } else {
        switch (type) {
          case 'adventure_started':
            if (data['map'] != null) {
              RoomSession.instance.mapNotifier.value = MapData.fromJson(
                data['map'] as Map<String, dynamic>,
              );
            }
            if (data['positions'] != null) {
              final list = (data['positions'] as List<dynamic>)
                  .map(
                    (p) => PlayerPosition.fromJson(p as Map<String, dynamic>),
                  )
                  .toList();
              RoomSession.instance.playerPositionsNotifier.value = list;
            }
            if (mounted) {
              setState(() {
                _adventureStarted = true;
                _displayedMap = RoomSession.instance.mapNotifier.value;
              });
            }
            break;
          case 'position_update':
            if (data['positions'] != null) {
              final list = (data['positions'] as List<dynamic>)
                  .map(
                    (p) => PlayerPosition.fromJson(p as Map<String, dynamic>),
                  )
                  .toList();
              RoomSession.instance.playerPositionsNotifier.value = list;
            }
            break;
          case 'character_update':
            if (data['characters'] != null) {
              _loadedCharacters = (data['characters'] as List<dynamic>)
                  .map((c) => CharacterData.fromJson(c as Map<String, dynamic>))
                  .toList();
              if (mounted) setState(() {});
            }
            break;
          case 'return_to_room':
          case 'host_disconnected':
            if (mounted) Navigator.of(context).pop();
            break;
        }
      }
    } catch (_) {}
  }

  void _addChat(String from, String text) {
    // 查找发送者的头像
    String? portrait;
    if (_character?.name == from) {
      portrait = _character?.portraitBase64;
    } else {
      portrait = _loadedCharacters
          .cast<CharacterData?>()
          .firstWhere((c) => c?.name == from, orElse: () => null)
          ?.portraitBase64;
    }
    setState(
      () => _chatMessages.add(
        ChatMessage(from: from, text: text, portraitBase64: portrait),
      ),
    );
    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();
    final msg = {
      'type': 'chat_message',
      'from': widget.playerName,
      'text': text,
    };
    if (_isGM) {
      RoomSession.instance.broadcast(msg);
    } else {
      RoomSession.instance.clientHandle?.send(socketEncode(msg));
    }
    final displayName = _character?.name ?? widget.playerName;
    setState(() {
      _chatMessages.add(
        ChatMessage(
          from: displayName,
          text: text,
          portraitBase64: _character?.portraitBase64,
        ),
      );
    });
    _scrollChatToBottom();
  }

  void _checkAllReady() {
    final s = RoomSession.instance;
    final nonHost = s.membersNotifier.value
        .where((m) => m != s.hostNameNotifier.value)
        .toList();
    if (nonHost.isEmpty) {
      // 仅房主一人，直接开始
      if (_selectedMap == null) return;
      s.mapNotifier.value = _selectedMap;
      s.broadcast({'type': 'adventure_started', 'map': _selectedMap!.toJson()});
      if (mounted) {
        setState(() {
          _adventureStarted = true;
          _displayedMap = _selectedMap;
        });
      }
      return;
    }
    if (!nonHost.every((m) => s.readyMembersNotifier.value.contains(m))) {
      return;
    }
    if (_selectedMap == null) return;
    s.mapNotifier.value = _selectedMap;
    s.broadcast({'type': 'adventure_started', 'map': _selectedMap!.toJson()});
    if (mounted) {
      setState(() {
        _adventureStarted = true;
        _displayedMap = _selectedMap;
      });
    }
  }

  Future<void> _loadSaveData() async {
    if (_saveFilePath == null) return;
    try {
      final save = await SaveData.fromZip(_saveFilePath!);
      _loadedCharacters = save.characters;
      _loadedMaps = save.maps;
      _loadedRules = save.rules;
    } catch (_) {
      _loadedCharacters = [];
      _loadedMaps = [];
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
      _selectedMap = null;
    });
    _loadSaveData();
  }

  void _selectCharacter(CharacterData c) => setState(() => _character = c);
  void _selectMap(MapData m) => setState(() => _selectedMap = m);

  Future<void> _navigateToCreateSave() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => CreateSavePage(allowMapEdit: _isGM)),
    );
    if (result != null && mounted) {
      setState(() {
        _saveFilePath = result;
        _saveFileName = result.split('/').last.split('\\').last;
        _character = null;
        _selectedMap = null;
      });
      _loadSaveData();
    }
  }

  void _startAdventure() {
    if (_isGM) {
      if (_selectedMap == null) return;
      setState(() => _isReady = true);
      _checkAllReady();
    } else {
      if (_character == null) return;
      setState(() => _isReady = true);
      RoomSession.instance.setPlayerReady(widget.playerName);
    }
  }

  void _onPlayerPositionChanged(int index, PlayerPosition newPos) {
    final session = RoomSession.instance;
    final list = List<PlayerPosition>.from(
      session.playerPositionsNotifier.value,
    );
    if (index >= 0 && index < list.length) {
      list[index] = newPos;
      session.playerPositionsNotifier.value = list;
      // 广播新位置给所有客户端
      session.broadcast({
        'type': 'position_update',
        'positions': list.map((p) => p.toJson()).toList(),
      });
    }
  }

  void _onEditCharacterHp(String name) {
    final idx = _loadedCharacters.indexWhere((c) => c.name == name);
    if (idx == -1) return;
    final c = _loadedCharacters[idx];
    final hpCtrl = TextEditingController(text: c.hp.toString());
    final maxHpCtrl = TextEditingController(text: c.maxHp.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑血量 · $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '当前 HP'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxHpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '最大 HP'),
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
              final hp = int.tryParse(hpCtrl.text) ?? c.hp;
              final maxHp = int.tryParse(maxHpCtrl.text) ?? c.maxHp;
              _loadedCharacters[idx] = c.copyWith(hp: hp, maxHp: maxHp);
              setState(() {});
              _saveCharacterChanges();
              Navigator.pop(ctx);
              // 广播 HP 更新
              RoomSession.instance.broadcast({
                'type': 'character_update',
                'characters': _loadedCharacters
                    .map((ch) => ch.toJson())
                    .toList(),
              });
              _addChat('系统', '$name HP: $hp/$maxHp');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _onAddCharacterNote(String name) {
    final idx = _loadedCharacters.indexWhere((c) => c.name == name);
    if (idx == -1) return;
    final c = _loadedCharacters[idx];
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('注释 · $name'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '新注释',
            hintText: '记录角色的状态变化、Buff、Debuff 等…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = noteCtrl.text.trim();
              if (text.isEmpty) {
                Navigator.pop(ctx);
                return;
              }
              _loadedCharacters[idx] = c.copyWith(notes: [...c.notes, text]);
              setState(() {});
              _saveCharacterChanges();
              Navigator.pop(ctx);
              _addChat('系统', '$name 新增注释');
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _onDeleteCharacterNote(String name, int noteIndex) {
    final idx = _loadedCharacters.indexWhere((c) => c.name == name);
    if (idx == -1) return;
    final c = _loadedCharacters[idx];
    if (noteIndex < 0 || noteIndex >= c.notes.length) return;
    final updated = [...c.notes]..removeAt(noteIndex);
    _loadedCharacters[idx] = c.copyWith(notes: updated);
    setState(() {});
    _saveCharacterChanges();
    _addChat('系统', '$name 注释已删除');
  }

  void _onPlayerTapped(String name) {
    setState(() => _selectedPlayerName = name);
  }

  void _onRemovePlayer(String name) {
    final session = RoomSession.instance;
    final list = List<PlayerPosition>.from(
      session.playerPositionsNotifier.value,
    );
    list.removeWhere((p) => p.name == name);
    session.playerPositionsNotifier.value = list;
    session.broadcast({
      'type': 'position_update',
      'positions': list.map((p) => p.toJson()).toList(),
    });
    if (_selectedPlayerName == name) {
      setState(() => _selectedPlayerName = null);
    }
    _addChat('系统', '$name 已下场');
  }

  void _onPlaceDeploy(CharacterData c, double x, double y) {
    setState(() => _deployCharacter = null);
    final session = RoomSession.instance;
    final list = List<PlayerPosition>.from(
      session.playerPositionsNotifier.value,
    );

    // 已在地图上则更新位置，否则添加
    final idx = list.indexWhere((p) => p.name == c.name);
    if (idx >= 0) {
      list[idx] = PlayerPosition(name: c.name, x: x, y: y);
    } else {
      list.add(PlayerPosition(name: c.name, x: x, y: y));
    }

    session.playerPositionsNotifier.value = list;
    session.broadcast({
      'type': 'position_update',
      'positions': list.map((p) => p.toJson()).toList(),
    });
    _addChat('系统', '${c.name} 已上场');
  }

  void _onAddEquipment(String characterName) {
    final idx = _loadedCharacters.indexWhere((c) => c.name == characterName);
    if (idx == -1) return;
    final c = _loadedCharacters[idx];
    final templates = _loadedRules.equipmentTemplates;
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchCtrl.text.toLowerCase();
          final filtered = templates
              .where(
                (t) =>
                    t.name.toLowerCase().contains(query) ||
                    t.slot.toLowerCase().contains(query) ||
                    t.effect.toLowerCase().contains(query),
              )
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
                        ? const Text(
                            '无匹配装备模板',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  t.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${t.slot}${t.ac > 0 ? ' · AC${t.ac}' : ''}${t.effect.isNotEmpty ? ' · ${t.effect}' : ''}',
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  final newEq =
                                      Map<String, EquipmentData?>.from(
                                        c.equipment,
                                      );
                                  newEq[t.slot] = t;
                                  _loadedCharacters[idx] = c.copyWith(
                                    equipment: newEq,
                                  );
                                  setState(() {});
                                  _saveCharacterChanges();
                                  Navigator.pop(ctx);
                                  _addChat(
                                    '系统',
                                    '$characterName 装备了 ${t.name}',
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onAddItem(String characterName) {
    final idx = _loadedCharacters.indexWhere((c) => c.name == characterName);
    if (idx == -1) return;
    final c = _loadedCharacters[idx];
    final templates = _loadedRules.itemTemplates;
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchCtrl.text.toLowerCase();
          final filtered = templates
              .where(
                (t) =>
                    t.name.toLowerCase().contains(query) ||
                    t.type.toLowerCase().contains(query) ||
                    t.effect.toLowerCase().contains(query),
              )
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
                        ? const Text(
                            '无匹配物品模板',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  t.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${t.type}${t.effect.isNotEmpty ? ' · ${t.effect}' : ''}${t.value > 0 ? ' · 💎${t.value}' : ''}',
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  _loadedCharacters[idx] = c.copyWith(
                                    backpack: [...c.backpack, t],
                                  );
                                  setState(() {});
                                  _saveCharacterChanges();
                                  Navigator.pop(ctx);
                                  _addChat(
                                    '系统',
                                    '$characterName 获得了 ${t.name}',
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveProgress() async {
    if (_saveFilePath == null) return;
    final ok = await _confirmOverwrite();
    if (ok != true) return;
    try {
      final save = await SaveData.fromZip(_saveFilePath!);
      final updated = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: _loadedCharacters,
        maps: save.maps,
        items: save.items,
        rules: save.rules,
        playerPositions: RoomSession.instance.playerPositionsNotifier.value,
      );
      await updated.packToZip(_saveFilePath!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('进度已保存'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存失败'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 弹出确认覆盖对话框，返回 true 表示用户确认
  Future<bool?> _confirmOverwrite() {
    return showDialog<bool>(
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
  }

  Future<void> _saveAsProgress() async {
    try {
      final result = await FilePicker.saveFile(
        dialogTitle: '另存为',
        fileName: _saveFileName,
        type: FileType.any,
      );
      if (result == null) return;
      final save = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: _loadedCharacters,
        maps: _saveFilePath != null
            ? (await SaveData.fromZip(_saveFilePath!)).maps
            : [],
        items: _saveFilePath != null
            ? (await SaveData.fromZip(_saveFilePath!)).items
            : [],
        rules: _saveFilePath != null
            ? (await SaveData.fromZip(_saveFilePath!)).rules
            : RuleData(),
        playerPositions: RoomSession.instance.playerPositionsNotifier.value,
      );
      await save.packToZip(result);
      if (mounted) {
        setState(() {
          _saveFilePath = result;
          _saveFileName = result.split('/').last.split('\\').last;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已另存为 $_saveFileName'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('另存失败'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveCharacterChanges() async {
    if (_saveFilePath == null) return;
    final ok = await _confirmOverwrite();
    if (ok != true) return;
    try {
      final save = await SaveData.fromZip(_saveFilePath!);
      final updated = SaveData(
        createdAt: DateTime.now().toIso8601String(),
        characters: _loadedCharacters,
        maps: save.maps,
        items: save.items,
        rules: save.rules,
        playerPositions: save.playerPositions,
      );
      await updated.packToZip(_saveFilePath!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已保存'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _rollDice(int sides) {
    final roll = (DateTime.now().millisecondsSinceEpoch % sides) + 1;
    final displayName = _character?.name ?? widget.playerName;
    final portrait = _character?.portraitBase64;
    setState(() {
      _diceResult = 'd$sides = $roll';
      _chatMessages.add(
        ChatMessage(
          from: displayName,
          text: '\u{1F3B2} d$sides = $roll',
          isSystem: true,
          isDice: true,
          portraitBase64: portrait,
        ),
      );
    });
    _scrollChatToBottom();
  }

  void _rollCustomDice() {
    final text = _diceInputCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      final result = DiceExpression.roll(text);
      final displayName = _character?.name ?? widget.playerName;
      final portrait = _character?.portraitBase64;
      setState(() {
        _diceResult = result.toString();
        _chatMessages.add(
          ChatMessage(
            from: displayName,
            text: '\u{1F3B2} ${result.toString()}',
            isSystem: true,
            isDice: true,
            portraitBase64: portrait,
          ),
        );
      });
      _scrollChatToBottom();
    } catch (_) {
      setState(() => _diceResult = '表达式无效');
    }
  }

  @override
  void dispose() {
    _voice.leaveChannel();
    _voice.onAudioCaptured = null;
    _voice.isInChannel.removeListener(_onVoiceStateChanged);
    _voice.isMuted.removeListener(_onVoiceStateChanged);
    _voice.speakingMembers.removeListener(_onVoiceStateChanged);
    _msgSub?.cancel();
    _diceInputCtrl.dispose();
    _chatCtrl.dispose();
    _chatScrollCtrl.dispose();
    RoomSession.instance.readyMembersNotifier.removeListener(_onReadyChanged);
    RoomSession.instance.mapNotifier.removeListener(_onMapChanged);
    RoomSession.instance.playerPositionsNotifier.removeListener(
      _onPositionsChanged,
    );
    super.dispose();
  }

  void _broadcastVoiceState(String type) {
    final msg = {'type': type, 'from': widget.playerName};
    if (_isGM) {
      RoomSession.instance.broadcast(msg);
    } else {
      RoomSession.instance.clientHandle?.send(socketEncode(msg));
    }
  }

  /// 根据冒险状态与角色切换显示冒险视图、角色详情或选择界面
  @override
  Widget build(BuildContext context) {
    if (_adventureStarted && _displayedMap != null) {
      return _buildAdventureView();
    }
    if (!_isGM && _character != null) return _buildCharacterView();
    if (_isGM && _selectedMap != null) return _buildMapPreviewView();
    return _isGM ? _buildMapSelection() : _buildCharacterSelection();
  }

  /// 构建冒险主界面 — 左侧角色详情 + 地图 + 聊天浮窗
  Widget _buildAdventureView() {
    final m = _displayedMap!;
    final positions = RoomSession.instance.playerPositionsNotifier.value;
    final theme = Theme.of(context);

    // 仅当地图 token 被点击选中时才显示详情面板
    final selectedChar = _loadedCharacters.cast<CharacterData?>().firstWhere(
      (c) => c?.name == _selectedPlayerName,
      orElse: () => null,
    );

    final mapDisplay = MapDisplay(
      mapData: m,
      positions: positions,
      enemies: m.enemies,
      isGM: _isGM,
      playerName: widget.playerName,
      character: _character,
      characters: _loadedCharacters,
      backpackItems: _character?.backpack ?? const [],
      backpackSlotMax: _loadedRules.backpackSlotMax,
      maxWeightExpression: _loadedRules.maxWeightExpression,
      onPositionChanged: _isGM ? _onPlayerPositionChanged : null,
      onEditHp: _isGM ? _onEditCharacterHp : null,
      onAddNote: _isGM ? _onAddCharacterNote : null,
      onDeleteNote: _isGM ? _onDeleteCharacterNote : null,
      onPlayerTap: _isGM ? _onPlayerTapped : null,
      onRemovePlayer: _isGM ? _onRemovePlayer : null,
    );
    final mainContent = SafeArea(child: mapDisplay);

    return Scaffold(
      appBar: AppBar(
        title: Text('冒险中 · ${m.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            RoomSession.instance.broadcast({'type': 'return_to_room'});
            RoomSession.instance.startAdventureNotifier.value = false;
            RoomSession.instance.mapNotifier.value = null;
            RoomSession.instance.playerPositionsNotifier.value = [];
            RoomSession.instance.readyMembersNotifier.value = {};
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // ── 发言者指示器（仅在频道内） ──
          ValueListenableBuilder<bool>(
            valueListenable: _voice.isInChannel,
            builder: (_, inChannel, _) {
              if (!inChannel) return const SizedBox.shrink();
              return ValueListenableBuilder<Set<String>>(
                valueListenable: _voice.speakingMembers,
                builder: (_, speakers, _) {
                  if (speakers.isEmpty) return const SizedBox.shrink();
                  final label = speakers.length == 1
                      ? speakers.first
                      : '${speakers.length} 人';
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      avatar: const Icon(
                        Icons.mic,
                        size: 14,
                        color: Colors.green,
                      ),
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                },
              );
            },
          ),
          // ── 麦克风静音（仅在频道内，带音量指示） ──
          ValueListenableBuilder<bool>(
            valueListenable: _voice.isInChannel,
            builder: (_, inChannel, _) {
              if (!inChannel) return const SizedBox.shrink();
              return ValueListenableBuilder<bool>(
                valueListenable: _voice.isMuted,
                builder: (_, muted, _) => ValueListenableBuilder<double>(
                  valueListenable: _voice.micVolume,
                  builder: (_, vol, _) => IconButton(
                    icon: muted
                        ? Icon(Icons.mic_off, color: Colors.red.shade400)
                        : _MicVolumeIcon(volume: vol),
                    tooltip: muted ? '打开麦克风' : '关闭麦克风',
                    onPressed: () async {
                      await _voice.toggleMute();
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
          // ── 麦克风选择（仅在频道内且多于1个设备时） ──
          ValueListenableBuilder<bool>(
            valueListenable: _voice.isInChannel,
            builder: (_, inChannel, _) {
              if (!inChannel) return const SizedBox.shrink();
              return ValueListenableBuilder<List<InputDevice>>(
                valueListenable: _voice.availableMics,
                builder: (_, mics, _) {
                  if (mics.length < 2) return const SizedBox.shrink();
                  return ValueListenableBuilder<String?>(
                    valueListenable: _voice.selectedMicId,
                    builder: (_, selId, _) => PopupMenuButton<String>(
                      tooltip: '选择麦克风',
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 36,
                      ),
                      onSelected: (id) {
                        _voice.selectedMicId.value = id;
                      },
                      itemBuilder: (_) => mics.map((m) {
                        final isSel = m.id == selId;
                        return PopupMenuItem<String>(
                          value: m.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSel
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: isSel ? Colors.green : null,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  m.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
          // ── 加入/退出语音频道 ──
          ValueListenableBuilder<bool>(
            valueListenable: _voice.isInChannel,
            builder: (_, inChannel, _) => IconButton(
              icon: Icon(
                inChannel ? Icons.phonelink_erase : Icons.mic_none,
                color: inChannel ? Colors.green : null,
              ),
              tooltip: inChannel ? '退出语音频道' : '加入语音频道',
              onPressed: () async {
                try {
                  if (inChannel) {
                    await _voice.leaveChannel();
                    _broadcastVoiceState('voice_leave');
                  } else {
                    await _voice.joinChannel();
                    _broadcastVoiceState('voice_join');
                  }
                  if (mounted) setState(() {});
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: '保存进度',
            onPressed: _saveProgress,
          ),
          IconButton(
            icon: const Icon(Icons.save_as_outlined),
            tooltip: '另存为',
            onPressed: _saveAsProgress,
          ),
          TextButton.icon(
            onPressed: () {
              RoomSession.instance.broadcast({'type': 'return_to_room'});
              RoomSession.instance.startAdventureNotifier.value = false;
              RoomSession.instance.mapNotifier.value = null;
              RoomSession.instance.playerPositionsNotifier.value = [];
              RoomSession.instance.readyMembersNotifier.value = {};
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.exit_to_app),
            label: const Text('返回房间'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                // ── 左侧面板 ──
                _AdventureLeftPanel(
                  selectedCharacter: selectedChar,
                  loadedCharacters: _loadedCharacters,
                  playerNames: _loadedCharacters.map((c) => c.name).toList(),
                  isGM: _isGM,
                  onSelectPlayer: (name) =>
                      setState(() => _selectedPlayerName = name),
                  onCloseDetail: () =>
                      setState(() => _selectedPlayerName = null),
                  onDeployCharacter: _isGM
                      ? (c) => setState(() => _deployCharacter = c)
                      : null,
                  onAddEquipment: _isGM ? _onAddEquipment : null,
                  onAddItem: _isGM ? _onAddItem : null,
                ),
                // ── 地图 ──
                Expanded(
                  child: _DeployOverlay(
                    deployCharacter: _deployCharacter,
                    imageAreaKey: mapDisplay.imageAreaKey,
                    onPlace: _onPlaceDeploy,
                    onCancel: () => setState(() => _deployCharacter = null),
                    child: mainContent,
                  ),
                ),
              ],
            ),
          ),
          // ── 聊天浮窗遮罩 ──
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isChatOpen,
              child: AnimatedOpacity(
                opacity: _isChatOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: GestureDetector(
                  onTap: () => setState(() => _isChatOpen = false),
                  child: Container(color: Colors.black38),
                ),
              ),
            ),
          ),
          _buildChatPanelSlide(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat_toggle',
        onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
        tooltip: _isChatOpen ? '关闭聊天' : '打开聊天',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isChatOpen ? Icons.close : Icons.chat,
            key: ValueKey(_isChatOpen),
          ),
        ),
      ),
    );
  }

  /// 构建玩家角色详情与准备冒险界面
  Widget _buildCharacterView() {
    return CharacterView(
      character: _character!,
      isReady: _isReady,
      onBack: () => setState(() => _character = null),
      onStart: _startAdventure,
      saveFileName: _saveFilePath != null ? _saveFileName : null,
    );
  }

  /// 构建主持地图预览与开始冒险界面
  Widget _buildMapPreviewView() {
    return MapPreviewView(
      mapData: _selectedMap!,
      isReady: _isReady,
      onBack: () => setState(() => _selectedMap = null),
      onStart: _startAdventure,
      saveFileName: _saveFilePath != null ? _saveFileName : null,
    );
  }

  /// 构建角色选择列表界面
  Widget _buildCharacterSelection() {
    return CharacterSelectionView(
      playerName: widget.playerName,
      saveFileName: _saveFileName,
      loadedCharacters: _loadedCharacters,
      onPickSaveFile: _pickSaveFile,
      onSelectCharacter: _selectCharacter,
      onCreateSave: _navigateToCreateSave,
    );
  }

  /// 构建主持地图选择界面
  Widget _buildMapSelection() {
    return MapSelectionView(
      playerName: widget.playerName,
      saveFileName: _saveFileName,
      loadedMaps: _loadedMaps,
      onPickSaveFile: _pickSaveFile,
      onSelectMap: _selectMap,
      onCreateSave: _navigateToCreateSave,
    );
  }

  /// 聊天面板侧滑卡片（直接返回 AnimatedPositioned 作为 Stack 子项）
  Widget _buildChatPanelSlide(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final panelWidth = isWide ? 300.0 : screenWidth * 0.85;
    const double cardMargin = 12.0;
    const double bottomSpace = 88.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: cardMargin,
      bottom: bottomSpace,
      right: _isChatOpen ? cardMargin : -(panelWidth + cardMargin * 2),
      width: panelWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(-4, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildChatHeader(theme),
              Expanded(
                child: ChatPanel(
                  chatMessages: _chatMessages,
                  chatCtrl: _chatCtrl,
                  chatScrollCtrl: _chatScrollCtrl,
                  playerName: widget.playerName,
                  onSend: _sendChat,
                  diceInputCtrl: _diceInputCtrl,
                  diceResult: _diceResult,
                  onRollDice: _rollDice,
                  onRollCustom: _rollCustomDice,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.chat_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '聊天',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_chatMessages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _isChatOpen = false),
            tooltip: '关闭',
            color: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// 带麦克风音量环的图标
class _MicVolumeIcon extends StatelessWidget {
  const _MicVolumeIcon({required this.volume});

  final double volume; // 0.0 ~ 1.0

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            value: volume,
            strokeWidth: 2.5,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.lerp(Colors.green, Colors.green.shade700, volume)!,
            ),
          ),
        ),
        Icon(Icons.mic, size: 18, color: Colors.green.shade600),
      ],
    );
  }
}

/// 冒险中左侧面板：角色网格 / 角色背包 / 角色详情
class _AdventureLeftPanel extends StatelessWidget {
  const _AdventureLeftPanel({
    required this.selectedCharacter,
    required this.loadedCharacters,
    required this.playerNames,
    required this.isGM,
    required this.onSelectPlayer,
    required this.onCloseDetail,
    this.onDeployCharacter,
    this.onAddEquipment,
    this.onAddItem,
  });

  final CharacterData? selectedCharacter;
  final List<CharacterData> loadedCharacters;
  final List<String> playerNames;
  final bool isGM;
  final ValueChanged<String> onSelectPlayer;
  final VoidCallback onCloseDetail;
  final void Function(CharacterData c)? onDeployCharacter;
  final void Function(String name)? onAddEquipment;
  final void Function(String name)? onAddItem;

  @override
  Widget build(BuildContext context) {
    // 选中角色 → 显示详情面板
    if (selectedCharacter != null) {
      return _PlayerDetailPanel(
        character: selectedCharacter,
        onClose: onCloseDetail,
        playerNames: playerNames,
        onSelectPlayer: onSelectPlayer,
        isGM: isGM,
        onAddEquipment: onAddEquipment,
        onAddItem: onAddItem,
      );
    }

    // 默认显示角色网格
    return _CharacterGridPanel(
      characters: loadedCharacters,
      isGM: isGM,
      onTapCharacter: (c) => onSelectPlayer(c.name),
      onDeployCharacter: onDeployCharacter,
    );
  }
}

/// 角色网格面板
class _CharacterGridPanel extends StatelessWidget {
  const _CharacterGridPanel({
    required this.characters,
    required this.isGM,
    required this.onTapCharacter,
    this.onDeployCharacter,
  });

  final List<CharacterData> characters;
  final bool isGM;
  final void Function(CharacterData c) onTapCharacter;
  final void Function(CharacterData c)? onDeployCharacter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 6),
                Text(
                  '角色列表',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isGM)
                  Text(
                    '右键头像上场',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: characters.isEmpty
                ? const Center(
                    child: Text(
                      '暂无角色',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: characters.length,
                    itemBuilder: (_, i) {
                      final c = characters[i];
                      final card = Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onTapCharacter(c),
                          onSecondaryTapDown: isGM && onDeployCharacter != null
                              ? (details) => _showDeployMenu(
                                  context,
                                  c,
                                  onDeployCharacter!,
                                  details.globalPosition,
                                )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: c.portraitBase64.isNotEmpty
                                      ? MemoryImage(
                                          base64Decode(c.portraitBase64),
                                        )
                                      : null,
                                  backgroundColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  child: c.portraitBase64.isEmpty
                                      ? Text(
                                          c.name.isNotEmpty
                                              ? c.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      return card;
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static void _showDeployMenu(
    BuildContext context,
    CharacterData c,
    void Function(CharacterData) onDeploy,
    Offset globalPosition,
  ) {
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox?;
    if (overlay == null) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'deploy',
          child: ListTile(
            leading: Icon(Icons.add_location, color: Colors.green),
            title: Text('上场'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value == 'deploy') onDeploy(c);
    });
  }
}

/// 部署模式覆盖层：当右键角色选择"上场"后，点击地图放置角色
class _DeployOverlay extends StatelessWidget {
  const _DeployOverlay({
    required this.deployCharacter,
    required this.imageAreaKey,
    required this.onPlace,
    required this.onCancel,
    required this.child,
  });

  final CharacterData? deployCharacter;
  final GlobalKey imageAreaKey;
  final void Function(CharacterData c, double x, double y) onPlace;
  final VoidCallback onCancel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (deployCharacter == null) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            onTapUp: (details) {
              // 将全局坐标转为图像区域本地坐标
              final imgBox =
                  imageAreaKey.currentContext?.findRenderObject() as RenderBox?;
              if (imgBox == null || !imgBox.hasSize) return;

              final localPos = imgBox.globalToLocal(details.globalPosition);
              final dx = (localPos.dx / imgBox.size.width).clamp(0.0, 1.0);
              final dy = (localPos.dy / imgBox.size.height).clamp(0.0, 1.0);
              onPlace(deployCharacter!, dx, dy);
            },
            child: Container(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '点击地图放置 ${deployCharacter!.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onCancel,
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 左侧角色详情面板 — 装备、物品、技能（法术表）
class _PlayerDetailPanel extends StatefulWidget {
  const _PlayerDetailPanel({
    required this.character,
    required this.onClose,
    required this.playerNames,
    required this.onSelectPlayer,
    this.isGM = false,
    this.onAddEquipment,
    this.onAddItem,
  });

  final CharacterData? character;
  final VoidCallback onClose;
  final List<String> playerNames;
  final ValueChanged<String> onSelectPlayer;
  final bool isGM;
  final void Function(String name)? onAddEquipment;
  final void Function(String name)? onAddItem;

  @override
  State<_PlayerDetailPanel> createState() => _PlayerDetailPanelState();
}

class _PlayerDetailPanelState extends State<_PlayerDetailPanel> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: c != null ? 260 : 0,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: c == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                // ── 头部：头像 + 名称 + HP + 切换 ──
                _PanelHeader(
                  character: c,
                  playerNames: widget.playerNames,
                  selectedName: widget.character!.name,
                  onSelectPlayer: widget.onSelectPlayer,
                  onClose: widget.onClose,
                ),
                const Divider(height: 1),
                // ── Tab 切换 ──
                _TabBarRow(
                  tabs: const ['装备', '物品', '技能'],
                  current: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
                const Divider(height: 1),
                // ── Tab 内容 ──
                Expanded(
                  child: IndexedStack(
                    index: _tabIndex,
                    children: [
                      _EquipmentTab(
                        character: c,
                        isGM: widget.isGM,
                        onAdd: widget.onAddEquipment,
                      ),
                      _BackpackTab(
                        character: c,
                        isGM: widget.isGM,
                        onAdd: widget.onAddItem,
                      ),
                      _SkillsTab(character: c),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// 面板头部：头像、名称、HP条、角色选择下拉
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.character,
    required this.playerNames,
    required this.selectedName,
    required this.onSelectPlayer,
    required this.onClose,
  });

  final CharacterData character;
  final List<String> playerNames;
  final String selectedName;
  final ValueChanged<String> onSelectPlayer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      child: Column(
        children: [
          Row(
            children: [
              // 头像
              if (character.portraitBase64.isNotEmpty)
                ClipOval(
                  child: Image.memory(
                    base64Decode(character.portraitBase64),
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                )
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    character.name.isNotEmpty
                        ? character.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // 名称 + HP
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 160,
                      child: playerNames.length > 1
                          ? DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedName,
                                isExpanded: true,
                                isDense: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                items: playerNames
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(
                                          n,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) onSelectPlayer(v);
                                },
                              ),
                            )
                          : Text(
                              character.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HP ${character.hp}/${character.maxHp}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lv${character.level}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onClose,
                tooltip: '关闭面板',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          // HP 进度条
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: character.maxHp > 0 ? character.hp / character.maxHp : 0,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                character.hp / (character.maxHp > 0 ? character.maxHp : 1) > 0.5
                    ? Colors.green
                    : character.hp /
                              (character.maxHp > 0 ? character.maxHp : 1) >
                          0.25
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 切换行
class _TabBarRow extends StatelessWidget {
  const _TabBarRow({
    required this.tabs,
    required this.current,
    required this.onChanged,
  });

  final List<String> tabs;
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? theme.colorScheme.primary
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 装备 Tab
class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab({required this.character, this.isGM = false, this.onAdd});
  final CharacterData character;
  final bool isGM;
  final void Function(String name)? onAdd;

  @override
  Widget build(BuildContext context) {
    final eq = character.equipment;
    return Stack(
      children: [
        if (eq.isEmpty)
          const Center(
            child: Text(
              '暂无装备',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          )
        else
          ListView(
            padding: const EdgeInsets.all(8),
            children: eq.entries
                .where((e) => e.value != null)
                .map((e) => _buildEqCard(e.key, e.value!, context))
                .toList(),
          ),
        if (isGM && onAdd != null)
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'add_eq_${character.name}',
              onPressed: () => onAdd!(character.name),
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildEqCard(String slot, EquipmentData eq, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (eq.imageBase64.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  base64Decode(eq.imageBase64),
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(
                Icons.shield_outlined,
                size: 28,
                color: Colors.deepPurple,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eq.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    slot,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  if (eq.effect.isNotEmpty)
                    Text(
                      eq.effect,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (eq.ac > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'AC${eq.ac}',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 物品（背包） Tab
class _BackpackTab extends StatelessWidget {
  const _BackpackTab({required this.character, this.isGM = false, this.onAdd});
  final CharacterData character;
  final bool isGM;
  final void Function(String name)? onAdd;

  @override
  Widget build(BuildContext context) {
    final items = character.backpack;
    return Stack(
      children: [
        if (items.isEmpty)
          const Center(
            child: Text(
              '暂无物品',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          )
        else
          ListView(
            padding: const EdgeInsets.all(8),
            children: items
                .map((item) => buildItemCard(item, context))
                .toList(),
          ),
        if (isGM && onAdd != null)
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'add_bp_${character.name}',
              onPressed: () => onAdd!(character.name),
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  static Widget buildItemCard(ItemData item, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (item.imageBase64.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  base64Decode(item.imageBase64),
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(
                Icons.category_outlined,
                size: 22,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.effect.isNotEmpty)
                    Text(
                      item.effect,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (item.value > 0)
              Text('💎${item.value}', style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/// 技能（法术表） Tab
class _SkillsTab extends StatelessWidget {
  const _SkillsTab({required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context) {
    final skills = character.skills;
    if (skills.isEmpty) {
      return const Center(
        child: Text('暂无技能', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: skills.map((s) => _buildSkillCard(s, context)).toList(),
    );
  }

  Widget _buildSkillCard(SkillData s, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_fix_high, size: 16, color: Colors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (s.description != null && s.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                s.description!,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
            if (s.damages.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...s.damages.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          d.expression ?? '',
                          style: const TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      if (d.damageType != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            d.damageType!,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

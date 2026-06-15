import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../../../data/services/socket_support.dart';
import '../create_save/create_save_page.dart';
import 'character_views.dart';
import 'dice_panel.dart';
import 'map_display.dart';
import 'map_views.dart';
import 'right_panel.dart';

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

  bool _isReady = false;
  bool _adventureStarted = false;
  MapData? _displayedMap;

  // --- Dice rolling ---
  final TextEditingController _diceInputCtrl = TextEditingController();
  String _diceResult = '';

  // --- Chat ---
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();

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

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message.trim()) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      if (type == 'chat_message') {
        _addChat(data['from'] as String? ?? '', data['text'] as String? ?? '');
        if (_isGM) RoomSession.instance.broadcast(data);
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
            if (mounted) {
              setState(() {
                _adventureStarted = true;
                _displayedMap = RoomSession.instance.mapNotifier.value;
              });
            }
          case 'return_to_room':
          case 'host_disconnected':
            if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (_) {}
  }

  void _addChat(String from, String text) {
    setState(() => _chatMessages.add(ChatMessage(from: from, text: text)));
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
    _addChat(widget.playerName, text);
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

  void _rollDice(int sides) {
    final roll = (DateTime.now().millisecondsSinceEpoch % sides) + 1;
    setState(() => _diceResult = 'd$sides = $roll');
    _chatMessages.add(
      ChatMessage(
        from: widget.playerName,
        text: '\u{1F3B2} d$sides = $roll',
        isSystem: true,
      ),
    );
    _scrollChatToBottom();
  }

  void _rollCustomDice() {
    final text = _diceInputCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      final result = DiceExpression.roll(text);
      setState(() => _diceResult = result.toString());
      _chatMessages.add(
        ChatMessage(
          from: widget.playerName,
          text: '\u{1F3B2} ${result.toString()}',
          isSystem: true,
        ),
      );
      _scrollChatToBottom();
    } catch (_) {
      setState(() => _diceResult = '表达式无效');
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _diceInputCtrl.dispose();
    _chatCtrl.dispose();
    _chatScrollCtrl.dispose();
    RoomSession.instance.readyMembersNotifier.removeListener(_onReadyChanged);
    RoomSession.instance.mapNotifier.removeListener(_onMapChanged);
    super.dispose();
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

  /// 构建冒险主界面，根据屏幕宽度切换横竖布局
  Widget _buildAdventureView() {
    final m = _displayedMap!;
    final positions = RoomSession.instance.playerPositionsNotifier.value;
    final members = RoomSession.instance.membersNotifier.value;
    final roles = RoomSession.instance.memberRolesNotifier.value;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('冒险中 · ${m.name}'),
        actions: [
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
      body: SafeArea(
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DicePanel(
                    diceInputCtrl: _diceInputCtrl,
                    diceResult: _diceResult,
                    onRollDice: _rollDice,
                    onRollCustom: _rollCustomDice,
                  ),
                  Expanded(
                    flex: 4,
                    child: MapDisplay(
                      mapData: m,
                      positions: positions,
                      enemies: m.enemies,
                      isGM: _isGM,
                      playerName: widget.playerName,
                      character: _character,
                      characters: _loadedCharacters,
                    ),
                  ),
                  RightPanel(
                    members: members,
                    roles: roles,
                    chatMessages: _chatMessages,
                    chatCtrl: _chatCtrl,
                    chatScrollCtrl: _chatScrollCtrl,
                    playerName: widget.playerName,
                    onSend: _sendChat,
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: MapDisplay(
                      mapData: m,
                      positions: positions,
                      enemies: m.enemies,
                      isGM: _isGM,
                      playerName: widget.playerName,
                      character: _character,
                      characters: _loadedCharacters,
                    ),
                  ),
                  DicePanel(
                    diceInputCtrl: _diceInputCtrl,
                    diceResult: _diceResult,
                    onRollDice: _rollDice,
                    onRollCustom: _rollCustomDice,
                  ),
                ],
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
}

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'create_save_page.dart';
import 'room_state.dart';
import 'save_data.dart';

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

  // ── Dice rolling ──
  final TextEditingController _diceInputCtrl = TextEditingController();
  String _diceResult = '';

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

    // If the map was already set before this page was created
    // (e.g. MapEditPage set it before pushing AdventurePage),
    // pick it up immediately — the listener won't fire for past values.
    if (session.mapNotifier.value != null) {
      _adventureStarted = true;
      _displayedMap = session.mapNotifier.value;
    }

    // Listen for messages
    final stream = _isGM
        ? session.serverHandle?.messages
        : session.clientHandle?.messages;
    if (stream != null) {
      _msgSub = stream.listen(_handleMessage);
    }

    // Listen for ready members changes
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

      if (_isGM) {
        // Host receives player_ready events
        if (type == 'player_ready') {
          final name = data['name'] as String? ?? '';
          RoomSession.instance.onPlayerReady(name);
          _checkAllReady();
        }
      } else {
        // Player receives adventure_started event
        if (type == 'adventure_started') {
          if (data['map'] != null) {
            final map = MapData.fromJson(data['map'] as Map<String, dynamic>);
            RoomSession.instance.mapNotifier.value = map;
          }
          if (mounted) {
            setState(() {
              _adventureStarted = true;
              _displayedMap = RoomSession.instance.mapNotifier.value;
            });
          }
        }
        // Player receives return_to_room event
        if (type == 'return_to_room') {
          if (mounted) Navigator.of(context).pop();
        }
        // Player receives host_disconnected event
        if (type == 'host_disconnected') {
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (_) {}
  }

  /// Host: check if all non-host members are ready.
  void _checkAllReady() {
    final session = RoomSession.instance;
    final allMembers = session.membersNotifier.value;
    final readyMembers = session.readyMembersNotifier.value;

    // All non-host members are ready
    final nonHost = allMembers
        .where((m) => m != session.hostNameNotifier.value)
        .toList();
    if (nonHost.isEmpty) return; // no players yet

    final allReady = nonHost.every((m) => readyMembers.contains(m));
    if (allReady && _selectedMap != null) {
      final mapJson = _selectedMap!.toJson();
      session.mapNotifier.value = _selectedMap;
      session.broadcast({'type': 'adventure_started', 'map': mapJson});
      if (mounted) {
        setState(() {
          _adventureStarted = true;
          _displayedMap = _selectedMap;
        });
      }
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
    final result = await FilePicker.platform.pickFiles(
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

  void _selectCharacter(CharacterData c) {
    setState(() => _character = c);
  }

  void _selectMap(MapData m) {
    setState(() => _selectedMap = m);
  }

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
      // Mark host as ready and check if all players are ready
      setState(() => _isReady = true);
      _checkAllReady();
    } else {
      if (_character == null) return;
      setState(() => _isReady = true);
      RoomSession.instance.setPlayerReady(widget.playerName);
    }
  }

  void _rollDice(int sides) {
    final rng = DateTime.now().millisecondsSinceEpoch;
    final roll = ((rng % sides) + 1);
    setState(() => _diceResult = 'd$sides = $roll');
  }

  void _rollCustomDice() {
    final text = _diceInputCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      final result = DiceExpression.roll(text);
      setState(() => _diceResult = result.toString());
    } catch (_) {
      setState(() => _diceResult = '表达式无效');
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _diceInputCtrl.dispose();
    RoomSession.instance.readyMembersNotifier.removeListener(_onReadyChanged);
    RoomSession.instance.mapNotifier.removeListener(_onMapChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Adventure started: show map ──
    if (_adventureStarted && _displayedMap != null) {
      return _buildAdventureView(theme);
    }

    // ── 玩家：已选定角色 → 角色详情 ──
    if (!_isGM && _character != null) {
      return _buildCharacterView(theme);
    }

    // ── 主持：已选定地图 → 地图详情 ──
    if (_isGM && _selectedMap != null) {
      return _buildMapView(theme);
    }

    // ── 选择页面 ──
    return _isGM ? _buildMapSelection(theme) : _buildCharacterSelection(theme);
  }

  // ═══════════════════════════════════════════
  //  冒险中：三栏布局（骰子 | 地图 | 玩家）
  // ═══════════════════════════════════════════
  Widget _buildAdventureView(ThemeData theme) {
    final m = _displayedMap!;
    final positions = RoomSession.instance.playerPositionsNotifier.value;
    final members = RoomSession.instance.membersNotifier.value;
    final roles = RoomSession.instance.memberRolesNotifier.value;
    final enemies = m.enemies;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('冒险中 · ${m.name}'),
        actions: [
          TextButton.icon(
            onPressed: () {
              RoomSession.instance.broadcast({'type': 'return_to_room'});
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
                  // ── 左：骰子面板 ──
                  _buildDicePanel(theme),
                  // ── 中：地图 ──
                  Expanded(
                    flex: 4,
                    child: _buildMapCenter(theme, m, positions, enemies),
                  ),
                  // ── 右：玩家/主持列表 ──
                  _buildMemberPanel(theme, members, roles),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: _buildMapCenter(theme, m, positions, enemies),
                  ),
                  _buildDicePanel(theme),
                ],
              ),
      ),
    );
  }

  // ── 骰子面板 ──
  Widget _buildDicePanel(ThemeData theme) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final dice = [4, 6, 8, 10, 12, 20];

    return Container(
      width: isWide ? 160 : null,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: isWide
            ? Border(right: BorderSide(color: theme.dividerColor))
            : Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            '骰子',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: dice.map((d) {
              return SizedBox(
                width: isWide ? 68 : 52,
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.deepPurple.shade100,
                    foregroundColor: Colors.deepPurple.shade900,
                  ),
                  onPressed: () => _rollDice(d),
                  child: Text(
                    'd$d',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: isWide ? 140 : double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
              ),
              onPressed: () => _rollDice(100),
              child: const Text(
                'd100',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (isWide) ...[
            TextField(
              controller: _diceInputCtrl,
              decoration: const InputDecoration(
                hintText: '2d6+3',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onSubmitted: (_) => _rollCustomDice(),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: _rollCustomDice,
                child: const Text('投掷', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
          if (_diceResult.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _diceResult,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 地图中心 ──
  Widget _buildMapCenter(
    ThemeData theme,
    MapData m,
    List<PlayerPosition> positions,
    List<EnemyData> enemies,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Role / character header
          Row(
            children: [
              if (_character != null) ...[
                if (_character!.portraitBase64.isNotEmpty)
                  ClipOval(
                    child: Image.memory(
                      base64Decode(_character!.portraitBase64),
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _character!.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    _isGM ? '主持模式' : widget.playerName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: m.imageBase64.isNotEmpty
                ? LayoutBuilder(
                    builder: (ctx, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.memory(
                                base64Decode(m.imageBase64),
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Player tokens
                            for (final pos in positions)
                              Positioned(
                                left: pos.x * constraints.maxWidth - 16,
                                top: pos.y * constraints.maxHeight - 16,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          pos.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        pos.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Enemy tokens
                            for (final e in enemies)
                              Positioned(
                                left: e.x * constraints.maxWidth - 16,
                                top: e.y * constraints.maxHeight - 16,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          e.name.isNotEmpty
                                              ? e.name[0].toUpperCase()
                                              : 'E',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        '${e.name} HP${e.hp}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      m.name,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 成员/角色面板 ──
  Widget _buildMemberPanel(
    ThemeData theme,
    List<String> members,
    Map<String, String> roles,
  ) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '房间成员',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: members.map((name) {
                final role = roles[name] ?? '';
                final isHost = role == '主持';
                return Card(
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isHost
                          ? Colors.orange
                          : Colors.deepPurple,
                      child: Icon(
                        isHost ? Icons.mic : Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontSize: 13)),
                    subtitle: role.isNotEmpty
                        ? Text(role, style: const TextStyle(fontSize: 11))
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  玩家：角色详情页
  // ═══════════════════════════════════════════
  Widget _buildCharacterView(ThemeData theme) {
    final c = _character!;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _character = null),
        ),
      ),
      body: SafeArea(
        child: Center(
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
                const SizedBox(height: 12),
                Text('技能: ${c.skills.map((s) => s.name).join(', ')}'),
              ],
              if (_saveFilePath != null) ...[
                const SizedBox(height: 16),
                Text(
                  '已加载存档: $_saveFileName',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 32),
              if (!_isReady)
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _startAdventure,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('准备', style: TextStyle(fontSize: 18)),
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
    );
  }

  // ═══════════════════════════════════════════
  //  主持：地图详情页
  // ═══════════════════════════════════════════
  Widget _buildMapView(ThemeData theme) {
    final m = _selectedMap!;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedMap = null),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (m.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  m.description,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 12),
              Text('尺寸: ${m.width} × ${m.height} · 单位: ${m.unit}'),
              if (m.imageBase64.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(m.imageBase64),
                    fit: BoxFit.contain,
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
              const SizedBox(height: 32),

              // ── 玩家准备状态 ──
              _buildReadyStatus(),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isReady ? null : _startAdventure,
                  icon: Icon(
                    _isReady
                        ? Icons.check_circle
                        : Icons.rocket_launch_outlined,
                  ),
                  label: Text(
                    _isReady ? '已准备，等待所有玩家…' : '开始冒险',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  玩家：角色选择页
  // ═══════════════════════════════════════════
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
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
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

              // ── 创建新角色 → 打开完整创建存档页 ──
              Text(
                '或自行创建角色',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _navigateToCreateSave,
                  icon: const Icon(Icons.person_add),
                  label: const Text(
                    '创建新角色 (完整创建)',
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
    );
  }

  // ═══════════════════════════════════════════
  //  主持：地图选择页
  // ═══════════════════════════════════════════
  Widget _buildMapSelection(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择地图')),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${m.width}×${m.height} · ${m.description.isNotEmpty ? m.description : "无描述"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _selectMap(m),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_saveFilePath != null) ...[
                const SizedBox(height: 12),
                Text('该存档中没有地图', style: TextStyle(color: Colors.grey.shade600)),
              ],

              const SizedBox(height: 24),

              // ── 创建 / 编辑地图 → 打开完整创建存档页 ──
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
    );
  }

  // ═══════════════════════════════════════════
  //  主持：玩家准备状态
  // ═══════════════════════════════════════════
  Widget _buildReadyStatus() {
    final session = RoomSession.instance;
    final allMembers = session.membersNotifier.value;
    final readyMembers = session.readyMembersNotifier.value;
    final hostName = session.hostNameNotifier.value;
    final players = allMembers.where((m) => m != hostName).toList();

    if (players.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              Text('暂无玩家加入', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '玩家准备状态',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...players.map((name) {
              final ready = readyMembers.contains(name);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      ready ? Icons.check_circle : Icons.hourglass_empty,
                      size: 18,
                      color: ready ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(name),
                    const SizedBox(width: 8),
                    Text(
                      ready ? '已准备' : '未准备',
                      style: TextStyle(
                        color: ready ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

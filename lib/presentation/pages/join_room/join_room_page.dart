import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../../../data/services/socket_support.dart';
import '../character_select/character_select_page.dart';

/// 加入房间页面：通过 IP/端口连接、切换身份并等待房主开始冒险
class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({required this.playerName, super.key});

  final String playerName;

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  // ── 连接表单 ──
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '33333',
  );
  bool _isJoining = false;
  bool get _isDO => PlatformSocketSupport.useDO;
  String _status = '请输入房间号';
  String _role = '玩家';

  // ── 已连接状态 ──
  bool _isConnected = false;
  String _connectedIp = '';
  int _connectedPort = 0;
  RoomClientHandle? _clientHandle;
  StreamSubscription<String>? _msgSub;
  String _hostSaveName = '';
  List<CharacterData>? _receivedCharacters;
  RuleData? _receivedRules;

  bool get _isReady =>
      RoomSession.instance.readyMembersNotifier.value.contains(_playerName);

  String get _playerName => widget.playerName;

  @override
  void initState() {
    super.initState();
    RoomSession.instance.membersNotifier.addListener(_handleMembersChanged);
    RoomSession.instance.memberRolesNotifier.addListener(_handleMembersChanged);
    RoomSession.instance.readyMembersNotifier.addListener(
      _handleMembersChanged,
    );
    RoomSession.instance.startAdventureNotifier.addListener(
      _onAdventureStarted,
    );
    RoomSession.instance.mapNotifier.addListener(_handleMembersChanged);
  }

  void _onAdventureStarted() {
    if (!RoomSession.instance.startAdventureNotifier.value) return;
    if (!mounted || !_isConnected) return;
    final saveName = _hostSaveName;
    final chars = _receivedCharacters;
    final rules = _receivedRules;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CharacterSelectPage(
            playerName: _playerName,
            role: _role,
            hostSaveName: saveName,
            characters: chars,
            rules: rules,
          ),
        ),
      );
    });
  }

  Future<void> _joinRoom() async {
    final ip = _ipController.text.trim();
    final portText = _portController.text.trim();

    if (ip.isEmpty) {
      setState(() => _status = _isDO ? '请输入房间号' : '请输入 IP');
      return;
    }

    if (!_isDO && (portText.isEmpty || int.tryParse(portText) == null)) {
      setState(() => _status = '请输入有效端口号');
      return;
    }

    final port = _isDO ? 0 : int.parse(portText);

    setState(() {
      _isJoining = true;
      _status = '正在连接...';
    });

    try {
      final clientHandle = await PlatformSocketSupport.connectToRoom(
        ip,
        port,
        playerName: _playerName,
        role: _role,
      );

      if (!mounted) return;

      RoomSession.instance.joinRoom(
        _playerName,
        roomAddress: '$ip:$port',
        role: _role,
      );
      RoomSession.instance.setClientHandle(clientHandle);

      // Start listening — wait for server confirmation (members_list / name_taken)
      _msgSub = clientHandle.messages.listen(_handleMessage);
      _clientHandle = clientHandle;

      if (!mounted) return;

      setState(() {
        _isJoining = false;
        _status = '等待房主确认...';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _status = '加入失败: $e';
      });
    }
  }

  void _leaveRoom() {
    _msgSub?.cancel();
    _msgSub = null;
    _clientHandle = null;
    RoomSession.instance.reset();
    setState(() {
      _isConnected = false;
      _connectedIp = '';
      _connectedPort = 0;
    });
  }

  void _markReady() {
    RoomSession.instance.setPlayerReady(_playerName);
  }

  void _cancelReady() {
    RoomSession.instance.setStateNotReady(_playerName);
    _clientHandle?.send(
      socketEncode({'type': 'player_cancel_ready', 'name': _playerName}),
    );
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      switch (type) {
        case 'player_ready':
          final name = data['name'] as String? ?? '';
          RoomSession.instance.setStateReady(name);
          break;

        case 'start_adventure':
          _hostSaveName = data['saveFileName'] as String? ?? '';
          // 解析房主发送的角色数据
          final charsJson = data['characters'] as List<dynamic>?;
          if (charsJson != null) {
            _receivedCharacters = charsJson
                .map((c) => CharacterData.fromJson(c as Map<String, dynamic>))
                .toList();
          }
          final rulesJson = data['rules'] as Map<String, dynamic>?;
          if (rulesJson != null) {
            _receivedRules = RuleData.fromJson(rulesJson);
          }
          RoomSession.instance.startAdventureNotifier.value = true;
          break;

        case 'member_joined':
          final name = data['name'] as String? ?? '';
          final role = data['role'] as String? ?? '玩家';
          RoomSession.instance.addMember(name, role: role);
          break;

        case 'members_list':
          final members = data['members'] as List<dynamic>? ?? [];
          var hostSave = '';
          for (final m in members) {
            final name = (m as Map<String, dynamic>)['name'] as String? ?? '';
            final role = m['role'] as String? ?? '玩家';
            RoomSession.instance.addMember(name, role: role);
            final saveName = m['hostSaveName'] as String?;
            if (saveName != null && saveName.isNotEmpty) {
              hostSave = saveName;
            }
            // Sync ready status from server
            final isReady = m['isReady'] as bool? ?? false;
            if (isReady) {
              RoomSession.instance.setStateReady(name);
            } else {
              RoomSession.instance.setStateNotReady(name);
            }
          }
          if (hostSave.isNotEmpty) {
            _hostSaveName = hostSave;
          }
          // Server confirmed join — mark as connected
          if (!_isConnected && mounted) {
            setState(() {
              _isConnected = true;
              _connectedIp = _ipController.text.trim();
              _connectedPort = int.tryParse(_portController.text.trim()) ?? 0;
              _status = '已成功加入房间';
            });
          }
          if (mounted) setState(() {});
          break;

        case 'name_taken':
          if (mounted) {
            setState(() {
              _status = data['message'] as String? ?? '名称已被使用，请更换名称后重试';
            });
            // Close connection and reset
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _leaveRoom();
            });
          }
          break;

        case 'host_save_changed':
          _hostSaveName = data['fileName'] as String? ?? '';
          if (mounted) setState(() {});
          break;

        case 'role_change':
          final name = data['name'] as String? ?? '';
          final role = data['role'] as String? ?? '玩家';
          RoomSession.instance.addMember(name, role: role);
          if (name == _playerName) {
            setState(() => _role = role);
          }
          break;

        case 'return_to_room':
          // Pop all adventure-level pages (CharacterSelectPage, AdventurePage)
          // so only JoinRoomPage is visible.
          if (mounted) {
            final myRoute = ModalRoute.of(context);
            if (myRoute != null) {
              Navigator.of(context).popUntil((route) => route == myRoute);
            }
          }
          break;

        case 'member_left':
          final name = data['name'] as String? ?? '';
          RoomSession.instance.removeMember(name);
          if (mounted) setState(() {});
          break;

        case 'kicked':
          if (mounted) {
            setState(() {
              _status = data['message'] as String? ?? '你已被踢出房间';
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _leaveRoom();
            });
          }
          break;

        case 'host_disconnected':
          // Host closed the room — go back to join form (deferred)
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _leaveRoom();
            });
          }
          break;
      }
    } catch (_) {}
  }

  void _handleMembersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _changeRole(String newRole) {
    setState(() => _role = newRole);
    RoomSession.instance.memberRolesNotifier.value = {
      ...RoomSession.instance.memberRolesNotifier.value,
      _playerName: newRole,
    };
    _clientHandle?.send(
      socketEncode({
        'type': 'role_change',
        'name': _playerName,
        'role': newRole,
      }),
    );
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    RoomSession.instance.membersNotifier.removeListener(_handleMembersChanged);
    RoomSession.instance.memberRolesNotifier.removeListener(
      _handleMembersChanged,
    );
    RoomSession.instance.readyMembersNotifier.removeListener(
      _handleMembersChanged,
    );
    RoomSession.instance.startAdventureNotifier.removeListener(
      _onAdventureStarted,
    );
    RoomSession.instance.mapNotifier.removeListener(_handleMembersChanged);
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  /// 根据连接状态切换显示加入表单或已连接房间视图
  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return _buildRoomView();
    }
    return _buildJoinForm();
  }

  /// 构建 IP/端口输入表单与身份选择界面
  Widget _buildJoinForm() {
    return Scaffold(
      appBar: AppBar(title: const Text('加入房间')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                _isDO ? '输入房间号' : '通过 IP 和端口加入房间',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_isDO)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('让房主把房间号发给你'),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: _isDO ? '房间号' : '房间 IP',
                  hintText: _isDO ? '例如: ABC123' : '例如: 127.0.0.1',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (!_isDO) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '房间端口',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                '选择身份',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: '玩家',
                    label: Text('玩家'),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: '主持',
                    label: Text('主持'),
                    icon: Icon(Icons.mic),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (v) => setState(() => _role = v.first),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isJoining ? null : _joinRoom,
                  icon: const Icon(Icons.login_rounded),
                  label: Text(
                    _isJoining ? '连接中...' : '加入房间',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建已加入房间视图，显示成员列表、身份切换与准备状态
  Widget _buildRoomView() {
    final roomMembers = RoomSession.instance.membersNotifier.value.isEmpty
        ? <String>[_playerName]
        : RoomSession.instance.membersNotifier.value;
    final adventureStarted =
        RoomSession.instance.startAdventureNotifier.value ||
        RoomSession.instance.mapNotifier.value != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('已加入房间'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新成员列表',
            onPressed: () {
              _clientHandle?.send(socketEncode({'type': 'request_members'}));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, size: 64),
              const SizedBox(height: 12),
              Text('已连接到房间', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (_isDO)
                Text('房间号: $_connectedIp')
              else ...[
                Text('IP: $_connectedIp'),
                Text('端口: $_connectedPort'),
              ],
              const SizedBox(height: 8),
              Text('你的名称: $_playerName'),
              Text('你的身份: $_role'),
              const SizedBox(height: 12),
              Text(
                '切换身份',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: '玩家',
                    label: Text('玩家'),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: '主持',
                    label: Text('主持'),
                    icon: Icon(Icons.mic),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (v) => _changeRole(v.first),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 20),
              if (adventureStarted)
                Card(
                  color: Colors.orange.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('冒险已开始'),
                      ],
                    ),
                  ),
                ),
              Text(
                '房间成员',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: roomMembers.map((name) {
                  final role =
                      RoomSession.instance.memberRolesNotifier.value[name] ??
                      '';
                  final roleIcon = role == '主持'
                      ? Icons.mic
                      : role == '玩家'
                      ? Icons.person
                      : Icons.account_circle;
                  final isReady = RoomSession
                      .instance
                      .readyMembersNotifier
                      .value
                      .contains(name);
                  return Card(
                    child: ListTile(
                      leading: Icon(roleIcon),
                      title: Text(name),
                      subtitle: role.isNotEmpty ? Text(role) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 准备状态（固定宽度对齐）
                          SizedBox(
                            width: 72,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isReady
                                      ? Icons.check_circle
                                      : Icons.hourglass_empty,
                                  size: 20,
                                  color: isReady ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isReady ? '已准备' : '未准备',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isReady
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 踢出按钮（固定宽度占位）
                          SizedBox(
                            width: 40,
                            child:
                                _isConnected &&
                                    _role == '主持' &&
                                    name != _playerName
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    tooltip: '踢出 $name',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('确认踢出'),
                                          content: Text('确定要将 $name 踢出房间吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                RoomSession.instance.kickMember(
                                                  name,
                                                );
                                                RoomSession.instance
                                                    .removeMember(name);
                                                RoomSession.instance.broadcast({
                                                  'type': 'member_left',
                                                  'name': name,
                                                });
                                              },
                                              child: const Text('踢出'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isReady ? _cancelReady : _markReady,
                  icon: Icon(
                    _isReady
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    _isReady ? '取消准备' : '准备就绪',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReady ? Colors.orange : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _leaveRoom,
                  child: const Text('离开房间', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

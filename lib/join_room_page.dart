import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'character_select_page.dart';
import 'room_state.dart';
import 'socket_support.dart';

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({required this.playerName, super.key});

  final String playerName;

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  // ── 连接表单 ──
  final TextEditingController _ipController = TextEditingController(
    text: '127.0.0.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '33333',
  );
  bool _isJoining = false;
  String _status = '请输入房间地址';
  String _role = '玩家';

  // ── 已连接状态 ──
  bool _isConnected = false;
  String _connectedIp = '';
  int _connectedPort = 0;
  RoomClientHandle? _clientHandle;
  StreamSubscription<String>? _msgSub;

  String get _playerName => widget.playerName;

  @override
  void initState() {
    super.initState();
    RoomSession.instance.membersNotifier.addListener(_handleMembersChanged);
    RoomSession.instance.memberRolesNotifier.addListener(_handleMembersChanged);
    RoomSession.instance.startAdventureNotifier.addListener(
      _handleMembersChanged,
    );
    RoomSession.instance.mapNotifier.addListener(_handleMembersChanged);
  }

  Future<void> _joinRoom() async {
    final ip = _ipController.text.trim();
    final portText = _portController.text.trim();

    if (ip.isEmpty || portText.isEmpty) {
      setState(() => _status = '请输入 IP 和端口');
      return;
    }

    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      setState(() => _status = '端口号必须是 1~65535 之间的整数');
      return;
    }

    if (!PlatformSocketSupport.isSupported) {
      setState(() => _status = PlatformSocketSupport.unsupportedMessage);
      return;
    }

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

      // Start listening
      _msgSub = clientHandle.messages.listen(_handleMessage);

      if (!mounted) return;

      setState(() {
        _isJoining = false;
        _isConnected = true;
        _connectedIp = ip;
        _connectedPort = port;
        _clientHandle = clientHandle;
        _status = '已成功加入房间';
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
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CharacterSelectPage(
                  playerName: _playerName,
                  role: _role,
                  saveFilePath:
                      (data['saveFilePath'] as String?)?.isEmpty == true
                      ? null
                      : data['saveFilePath'] as String?,
                ),
              ),
            );
          });
          break;

        case 'member_joined':
          final name = data['name'] as String? ?? '';
          final role = data['role'] as String? ?? '玩家';
          RoomSession.instance.addMember(name, role: role);
          break;

        case 'members_list':
          final members = data['members'] as List<dynamic>? ?? [];
          for (final m in members) {
            final name = (m as Map<String, dynamic>)['name'] as String? ?? '';
            final role = m['role'] as String? ?? '玩家';
            RoomSession.instance.addMember(name, role: role);
          }
          break;

        case 'return_to_room':
          // Host went back — pop all adventure pages
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
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

  @override
  void dispose() {
    _msgSub?.cancel();
    RoomSession.instance.membersNotifier.removeListener(_handleMembersChanged);
    RoomSession.instance.memberRolesNotifier.removeListener(
      _handleMembersChanged,
    );
    RoomSession.instance.startAdventureNotifier.removeListener(
      _handleMembersChanged,
    );
    RoomSession.instance.mapNotifier.removeListener(_handleMembersChanged);
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return _buildRoomView();
    }
    return _buildJoinForm();
  }

  Widget _buildJoinForm() {
    return Scaffold(
      appBar: AppBar(title: const Text('加入房间')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                '通过 IP 和端口加入房间',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: '房间 IP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '房间端口',
                  border: OutlineInputBorder(),
                ),
              ),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, size: 64),
              const SizedBox(height: 12),
              Text('已连接到房间', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('IP: $_connectedIp'),
              Text('端口: $_connectedPort'),
              const SizedBox(height: 8),
              Text('你的名称: $_playerName'),
              Text('你的身份: $_role'),
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
              Expanded(
                child: ListView(
                  children: roomMembers.map((name) {
                    final role =
                        RoomSession.instance.memberRolesNotifier.value[name] ??
                        '';
                    final roleIcon = role == '主持'
                        ? Icons.mic
                        : role == '玩家'
                        ? Icons.person
                        : Icons.account_circle;
                    return Card(
                      child: ListTile(
                        leading: Icon(roleIcon),
                        title: Text(name),
                        subtitle: role.isNotEmpty ? Text(role) : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
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

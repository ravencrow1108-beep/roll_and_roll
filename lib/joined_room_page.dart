import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'character_select_page.dart';
import 'room_state.dart';
import 'socket_support.dart';

class JoinedRoomPage extends StatefulWidget {
  const JoinedRoomPage({
    required this.ip,
    required this.port,
    required this.playerName,
    required this.members,
    required this.clientHandle,
    required this.role,
    super.key,
  });

  final String ip;
  final int port;
  final String playerName;
  final List<String> members;
  final RoomClientHandle clientHandle;
  final String role;

  @override
  State<JoinedRoomPage> createState() => _JoinedRoomPageState();
}

class _JoinedRoomPageState extends State<JoinedRoomPage> {
  StreamSubscription<String>? _msgSub;

  @override
  void initState() {
    super.initState();
    RoomSession.instance.membersNotifier.addListener(_handleMembersChanged);

    _msgSub = widget.clientHandle.messages.listen((msg) {
      _handleMessage(msg);
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CharacterSelectPage(
                playerName: widget.playerName,
                role: widget.role,
                saveFilePath: data['saveFilePath'] as String? ?? '',
              ),
            ),
          );
          break;

        case 'member_joined':
          final name = data['name'] as String? ?? '';
          final role = data['role'] as String? ?? '玩家';
          RoomSession.instance.addMember(name, role: role);
          break;
      }
    } catch (_) {
      // Ignore malformed messages
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomMembers = RoomSession.instance.membersNotifier.value.isEmpty
        ? <String>[widget.playerName]
        : RoomSession.instance.membersNotifier.value;

    return Scaffold(
      appBar: AppBar(title: const Text('已加入房间')),
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
              Text('IP: ${widget.ip}'),
              Text('端口: ${widget.port}'),
              const SizedBox(height: 8),
              Text('你的名称: ${widget.playerName}'),
              Text('你的身份: ${widget.role}'),
              const SizedBox(height: 20),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('返回', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

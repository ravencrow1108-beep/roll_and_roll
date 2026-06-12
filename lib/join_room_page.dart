import 'package:flutter/material.dart';

import 'joined_room_page.dart';
import 'room_state.dart';
import 'socket_support.dart';

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({required this.playerName, super.key});

  final String playerName;

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final TextEditingController _ipController = TextEditingController(
    text: '127.0.0.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '33333',
  );
  bool _isJoining = false;
  String _status = '请输入房间地址';
  String _role = '玩家';

  Future<void> _joinRoom(BuildContext context) async {
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
        playerName: widget.playerName,
        role: _role,
      );

      if (!mounted || !context.mounted) {
        return;
      }

      RoomSession.instance.joinRoom(
        widget.playerName,
        roomAddress: '$ip:$port',
        role: _role,
      );
      RoomSession.instance.setClientHandle(clientHandle);

      if (!mounted || !context.mounted) {
        return;
      }

      setState(() {
        _isJoining = false;
        _status = '已成功加入房间';
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JoinedRoomPage(
            ip: ip,
            port: port,
            playerName: widget.playerName,
            members: [widget.playerName, '房主'],
            clientHandle: clientHandle,
            role: _role,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isJoining = false;
        _status = '加入失败: $e';
      });
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _isJoining ? null : () => _joinRoom(context),
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
}

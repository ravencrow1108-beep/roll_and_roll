import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'map_edit_page.dart';
import 'room_state.dart';
import 'socket_support.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({required this.playerName, super.key});

  final String playerName;

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final TextEditingController _portController = TextEditingController(
    text: '33333',
  );
  RoomServerHandle? _server;
  bool _isHosting = false;
  String _status = '尚未开放端口';
  String _roomAddress = '等待开放端口';
  String? _saveFilePath;
  String _saveFileName = '未选择';
  String _role = '玩家';

  @override
  void initState() {
    super.initState();
    RoomSession.instance.initializeHost(
      widget.playerName,
      roomAddress: _roomAddress,
    );
    RoomSession.instance.membersNotifier.addListener(_onMembersChanged);
    RoomSession.instance.memberRolesNotifier.addListener(_onMembersChanged);
  }

  void _onMembersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectSaveFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择存档文件',
      type: FileType.any,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _saveFilePath = result.files.single.path!;
        _saveFileName = result.files.single.name;
      });
    }
  }

  Future<void> _startHosting() async {
    final portText = _portController.text.trim();
    if (portText.isEmpty) {
      setState(() => _status = '请输入端口号');
      return;
    }

    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      setState(() => _status = '端口号必须是 1~65535 之间的整数');
      return;
    }

    if (!PlatformSocketSupport.isSupported) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isHosting = false;
        _status = PlatformSocketSupport.unsupportedMessage;
        _roomAddress = '请在桌面端运行';
      });
      return;
    }

    try {
      if (_server != null) {
        await _server!.close();
      }

      final server = await PlatformSocketSupport.startServer(
        port,
        onClient: (remoteAddress, name, role) {
          if (!mounted) {
            return;
          }
          RoomSession.instance.addMember(name, role: role);
          // Tell all other clients about the new member
          RoomSession.instance.broadcast({
            'type': 'member_joined',
            'name': name,
            'role': role,
          });
        },
      );
      _server = server;
      RoomSession.instance.setServerHandle(server);

      if (!mounted) {
        return;
      }

      setState(() {
        _isHosting = true;
        _status = '已开放端口 $port';
        _roomAddress = '本机地址: 127.0.0.1:$port';
      });
      RoomSession.instance.initializeHost(
        widget.playerName,
        roomAddress: _roomAddress,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _status = '开放端口失败: $e');
    }
  }

  Future<void> _stopHosting() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close().timeout(const Duration(seconds: 2));
    }
    if (!mounted) return;
    RoomSession.instance.reset();
    setState(() {
      _isHosting = false;
      _status = '已关闭端口';
      _roomAddress = '等待开放端口';
    });
  }

  void _startAdventure(BuildContext context) {
    if (!mounted || !context.mounted) return;

    // Broadcast the start_adventure event to all players
    final msg = <String, dynamic>{
      'type': 'start_adventure',
      'from': widget.playerName,
      'role': _role,
    };
    if (_saveFilePath != null && _saveFilePath!.isNotEmpty) {
      msg['saveFilePath'] = _saveFilePath;
    }
    RoomSession.instance.broadcast(msg);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapEditPage(
          playerName: widget.playerName,
          role: _role,
          saveFilePath: _saveFilePath,
        ),
      ),
    );
  }

  @override
  void dispose() {
    RoomSession.instance.membersNotifier.removeListener(_onMembersChanged);
    RoomSession.instance.memberRolesNotifier.removeListener(_onMembersChanged);
    _server?.close();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建房间'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (_isHosting) {
              await _stopHosting();
            }
            if (mounted) {
              navigator.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                '开放本机端口',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '端口号',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isHosting ? _stopHosting : _startHosting,
                      icon: Icon(
                        _isHosting
                            ? Icons.stop_circle_outlined
                            : Icons.wifi_tethering,
                      ),
                      label: Text(
                        _isHosting ? '关闭端口' : '开放端口',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('状态: $_status'),
                      const SizedBox(height: 6),
                      Text('房间地址: $_roomAddress'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isHosting)
                ...() {
                  final members = RoomSession.instance.membersNotifier.value;
                  final roles = RoomSession.instance.memberRolesNotifier.value;
                  return [
                    Text(
                      '房间成员 (${members.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...members.map((name) {
                      final role = roles[name] ?? '';
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
                    }),
                    const SizedBox(height: 24),
                  ];
                }(),
              Text(
                '选择身份',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                onSelectionChanged: (v) {
                  setState(() => _role = v.first);
                  RoomSession.instance.setHostRole(v.first);
                },
              ),
              const SizedBox(height: 24),
              Text(
                '选择存档',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                              onPressed: _selectSaveFile,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startAdventure(context),
                  icon: const Icon(Icons.rocket_launch_outlined),
                  label: const Text('开始冒险', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

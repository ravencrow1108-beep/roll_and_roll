import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../providers/room_state.dart';
import '../../../data/models/save_data.dart';
import '../../../data/services/socket_support.dart';
import '../character_select/character_select_page.dart';
import '../create_save/create_save_page.dart';
import '../map_edit/map_edit_page.dart';

/// 创建房间页面：开放端口、管理成员身份、选档并开始冒险
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
  StreamSubscription<String>? _serverSub;
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
    RoomSession.instance.startAdventureNotifier.addListener(_onStateChanged);
    RoomSession.instance.mapNotifier.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
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
      if (_isHosting) {
        RoomSession.instance.hostSetSave(_saveFileName);
      }
    }
  }

  Future<void> _editSaveFile() async {
    if (_saveFilePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先选择存档文件')));
      }
      return;
    }

    try {
      final saveData = await SaveData.fromZip(_saveFilePath!);
      if (!mounted) return;

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => CreateSavePage.edit(
            filePath: _saveFilePath!,
            characters: saveData.characters,
            maps: saveData.maps,
            rules: saveData.rules,
            allowMapEdit: _role == '主持',
          ),
        ),
      );

      // If the user saved changes (result is the save path), broadcast update
      if (result != null && mounted) {
        if (_isHosting) {
          RoomSession.instance.hostSetSave(_saveFileName);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('打开存档失败: $e')));
      }
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

    if (!PlatformSocketSupport.canHost) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isHosting = false;
        _status = PlatformSocketSupport.unsupportedHostMessage;
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
        hostName: widget.playerName,
        hostRole: _role,
      );
      _server = server;
      RoomSession.instance.setServerHandle(server);

      // Listen to server messages (member_left, player_ready, etc.)
      _serverSub = server.messages.listen(_handleServerMessage);

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
        role: _role,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _status = '开放端口失败: $e');
    }
  }

  void _handleServerMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      switch (type) {
        case 'member_left':
          final name = data['name'] as String? ?? '';
          RoomSession.instance.removeMember(name);
          break;
        case 'player_ready':
          final name = data['name'] as String? ?? '';
          RoomSession.instance.onPlayerReady(name);
          break;
        case 'role_change':
          final name = data['name'] as String? ?? '';
          final role = data['role'] as String? ?? '玩家';
          RoomSession.instance.addMember(name, role: role);
          break;
      }
    } catch (_) {}
  }

  Future<void> _stopHosting() async {
    _serverSub?.cancel();
    _serverSub = null;
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
      _role = '玩家';
    });
  }

  Future<void> _startAdventure(BuildContext context) async {
    if (!mounted || !context.mounted) return;

    // Mark adventure as started
    RoomSession.instance.startAdventureNotifier.value = true;

    // Broadcast the start_adventure event to all players
    final msg = <String, dynamic>{
      'type': 'start_adventure',
      'from': widget.playerName,
      'role': _role,
    };
    if (_saveFileName != '未选择') {
      msg['saveFileName'] = _saveFileName;
    }
    RoomSession.instance.broadcast(msg);

    final page = _role == '主持'
        ? MapEditPage(
            playerName: widget.playerName,
            role: _role,
            saveFilePath: _saveFilePath,
          )
        : CharacterSelectPage(
            playerName: widget.playerName,
            role: _role,
            saveFilePath: _saveFilePath,
            hostSaveName: _saveFilePath != null ? _saveFileName : '',
          );

    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    // User came back without starting the adventure — reset state so they can try again
    if (mounted) {
      RoomSession.instance.startAdventureNotifier.value = false;
      RoomSession.instance.readyMembersNotifier.value = {};
      setState(() {});
    }
  }

  @override
  void dispose() {
    RoomSession.instance.membersNotifier.removeListener(_onMembersChanged);
    RoomSession.instance.memberRolesNotifier.removeListener(_onMembersChanged);
    RoomSession.instance.startAdventureNotifier.removeListener(_onStateChanged);
    RoomSession.instance.mapNotifier.removeListener(_onStateChanged);
    _serverSub?.cancel();
    _server?.close();
    _portController.dispose();
    super.dispose();
  }

  /// 构建房间创建界面，包含端口设置、成员列表、身份/存档选择与冒险控制
  @override
  Widget build(BuildContext context) {
    final adventureStarted =
        RoomSession.instance.startAdventureNotifier.value ||
        RoomSession.instance.mapNotifier.value != null;

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
        actions: [
          if (_isHosting)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新成员列表',
              onPressed: () => RoomSession.instance.sendFullMemberList(),
            ),
        ],
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
              if (_isHosting) ...[
                if (adventureStarted)
                  Card(
                    color: Colors.orange.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('冒险进行中'),
                        ],
                      ),
                    ),
                  ),
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
                      final isSelf = name == widget.playerName;
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
                          trailing: !isSelf
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  tooltip: '踢出 $name',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('确认踢出'),
                                        content: Text('确定要将 $name 踢出房间吗？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              RoomSession.instance.kickMember(
                                                name,
                                              );
                                              RoomSession.instance.removeMember(
                                                name,
                                              );
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
                      );
                    }),
                    const SizedBox(height: 24),
                  ];
                }(),
              ],
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
                            if (_saveFilePath != null)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: '编辑存档',
                                onPressed: _editSaveFile,
                              ),
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

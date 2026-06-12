import 'package:flutter/material.dart';

import 'room_state.dart';
import 'socket_support.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roll and Roll',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 101, 57, 175),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _playerNameController = TextEditingController(
    text: '玩家1',
  );

  bool get _webUnsupported => !PlatformSocketSupport.isSupported;

  @override
  void initState() {
    super.initState();
    RoomSession.instance.reset();
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _handleRoomAction(BuildContext context, Widget page) {
    if (_webUnsupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前 Web 端无法使用房间创建与加入功能，请在桌面端运行。'),
        ),
      );
      return;
    }
    _openPage(context, page);
  }

  String _getPlayerName() {
    final name = _playerNameController.text.trim();
    return name.isEmpty ? '玩家1' : name;
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Roll and Roll',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '选择你想要开始的方式',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_webUnsupported)
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Web 端当前无法创建或加入房间，请使用桌面版或者APP版运行。',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_webUnsupported) const SizedBox(height: 16),
                  TextField(
                    controller: _playerNameController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: '你的玩家名称',
                      hintText: '例如：阿宇',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ActionButton(
                    label: '新建房间',
                    icon: Icons.add_circle_outline,
                    onPressed: () => _handleRoomAction(
                      context,
                      CreateRoomPage(playerName: _getPlayerName()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: '加入房间',
                    icon: Icons.login_rounded,
                    onPressed: () => _handleRoomAction(
                      context,
                      JoinRoomPage(playerName: _getPlayerName()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: '直播模式',
                    icon: Icons.videocam_outlined,
                    onPressed: () => _openPage(context, const LiveModePage()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({required this.playerName, super.key});

  final String playerName;

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final TextEditingController _portController = TextEditingController(text: '33333');
  final TextEditingController _nameController = TextEditingController();
  RoomServerHandle? _server;
  bool _isHosting = false;
  String _status = '尚未开放端口';
  String _roomAddress = '等待开放端口';

  @override
  void initState() {
    super.initState();
    RoomSession.instance.initializeHost(widget.playerName, roomAddress: _roomAddress);
    _nameController.text = widget.playerName;
    RoomSession.instance.membersNotifier.addListener(_handleMembersChanged);
  }

  void _handleMembersChanged() {
    if (mounted) {
      setState(() {});
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
        onClient: (remoteAddress) {
          final playerName = '玩家 $remoteAddress';
          if (!mounted) {
            return;
          }
          RoomSession.instance.addMember(playerName);
        },
      );
      _server = server;

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
    await _server?.close();
    if (!mounted) {
      return;
    }
    setState(() {
      _server = null;
      _isHosting = false;
      _status = '已关闭端口';
      _roomAddress = '等待开放端口';
    });
    RoomSession.instance.initializeHost(
      widget.playerName,
      roomAddress: _roomAddress,
    );
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    RoomSession.instance.addMember(name);
    _nameController.clear();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  @override
  void dispose() {
    RoomSession.instance.membersNotifier.removeListener(_handleMembersChanged);
    _server?.close();
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建房间')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                '开放本机端口',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                      icon: Icon(_isHosting ? Icons.stop_circle_outlined : Icons.wifi_tethering),
                      label: Text(_isHosting ? '关闭端口' : '开放端口'),
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
              Text(
                '房间内玩家名称',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '输入玩家名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addPlayer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('添加玩家'),
              ),
              const SizedBox(height: 12),
              ...RoomSession.instance.membersNotifier.value.map(
                (name) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: Text(name),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({required this.playerName, super.key});

  final String playerName;

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final TextEditingController _ipController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portController = TextEditingController(text: '33333');
  bool _isJoining = false;
  String _status = '请输入房间地址';

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
      await PlatformSocketSupport.connectToRoom(ip, port);

      if (!mounted || !context.mounted) {
        return;
      }

      RoomSession.instance.joinRoom(
        widget.playerName,
        roomAddress: '$ip:$port',
      );

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '通过 IP 和端口加入房间',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isJoining ? null : () => _joinRoom(context),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(_isJoining ? '连接中...' : '加入房间'),
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

class JoinedRoomPage extends StatefulWidget {
  const JoinedRoomPage({
    required this.ip,
    required this.port,
    required this.playerName,
    required this.members,
    super.key,
  });

  final String ip;
  final int port;
  final String playerName;
  final List<String> members;

  @override
  State<JoinedRoomPage> createState() => _JoinedRoomPageState();
}

class _JoinedRoomPageState extends State<JoinedRoomPage> {
  @override
  void initState() {
    super.initState();
    RoomSession.instance.membersNotifier.addListener(_handleMembersChanged);
  }

  void _handleMembersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
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
              const SizedBox(height: 20),
              Text(
                '房间成员',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: roomMembers.map((name) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: Text(name),
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
                  child: const Text('返回'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LiveModePage extends StatelessWidget {
  const LiveModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('直播模式')),
      body: const Center(child: Text('这里将来可以用于直播模式')),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
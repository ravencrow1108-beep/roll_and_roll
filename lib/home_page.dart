import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'create_room_page.dart';
import 'create_save_page.dart';
import 'join_room_page.dart';
import 'live_mode_page.dart';
import 'room_state.dart';
import 'socket_support.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _playerNameController = TextEditingController();
  bool _nameLoaded = false;

  bool get _webUnsupported => !PlatformSocketSupport.isSupported;
  bool get _nameEmpty => _playerNameController.text.trim().isEmpty;

  static const _keyPlayerName = 'player_name';

  @override
  void initState() {
    super.initState();
    RoomSession.instance.reset();
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyPlayerName) ?? '';
    if (mounted) {
      _playerNameController.text = saved;
      setState(() => _nameLoaded = true);
    }
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayerName, name);
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _handleRoomAction(BuildContext context, Widget page) {
    if (_nameEmpty) return;
    _saveName(_playerNameController.text.trim());
    if (_webUnsupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前 Web 端无法使用房间创建与加入功能，请在桌面端运行。')),
      );
      return;
    }
    _openPage(context, page);
  }

  String _getPlayerName() => _playerNameController.text.trim();

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
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  if (_webUnsupported)
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
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
                  if (_nameLoaded)
                    TextField(
                      controller: _playerNameController,
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: '你的玩家名称',
                        hintText: '例如：阿宇',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  const SizedBox(height: 24),
                  _ActionButton(
                    label: '新建房间',
                    icon: Icons.add_circle_outline,
                    enabled: !_nameEmpty,
                    onPressed: () => _handleRoomAction(
                      context,
                      CreateRoomPage(playerName: _getPlayerName()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: '加入房间',
                    icon: Icons.login_rounded,
                    enabled: !_nameEmpty,
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
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: '创建存档',
                    icon: Icons.edit_note_rounded,
                    onPressed: () => _openPage(context, const CreateSavePage()),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
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

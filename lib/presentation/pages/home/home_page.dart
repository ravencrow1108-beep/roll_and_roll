import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/room_state.dart';
import '../../../data/models/models.dart';
import '../../../data/services/socket_support.dart';
import '../create_room/create_room_page.dart';
import '../create_save/create_save_page.dart';
import '../join_room/join_room_page.dart';
import '../live_mode/live_mode_page.dart';

/// 首页：玩家命名、房间创建/加入入口、直播模式与存档管理
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _playerNameController = TextEditingController();

  bool get _webCannotHost => !PlatformSocketSupport.canHost;
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
    _playerNameController.text = saved;
    if (mounted) setState(() {});
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayerName, name);
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _modifySaveFile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择要修改的存档文件 (.zip)',
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (!path.endsWith('.zip')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择 .zip 格式的存档文件'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      final save = await SaveData.fromZip(path);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateSavePage.edit(
            filePath: path,
            characters: save.characters,
            maps: save.maps,
            rules: save.rules,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('读取存档失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleRoomAction(
    BuildContext context,
    Widget page, {
    bool isHost = false,
  }) {
    if (_nameEmpty) return;
    _saveName(_playerNameController.text.trim());
    if (isHost && _webCannotHost) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Web 端不支持创建房间，请在桌面端运行。')));
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

  /// 构建首页布局，包含标题、玩家名称输入与各功能入口按钮
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
                  if (_webCannotHost)
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Web 端不支持创建房间。你可以加入桌面端创建的房间，或直接使用直播模式。',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_webCannotHost) const SizedBox(height: 16),
                  TextField(
                    controller: _playerNameController,
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
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
                    enabled: !_nameEmpty,
                    onPressed: () => _handleRoomAction(
                      context,
                      CreateRoomPage(playerName: _getPlayerName()),
                      isHost: true,
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
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: '修改存档',
                    icon: Icons.file_open_outlined,
                    onPressed: _modifySaveFile,
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

/// 统一样式的操作按钮组件，支持启用/禁用状态
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

  /// 构建带图标和标签的圆角全宽按钮
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

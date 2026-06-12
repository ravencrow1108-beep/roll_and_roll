import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'adventure_page.dart';
import 'create_save_page.dart';
import 'room_state.dart';
import 'save_data.dart';

class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({
    required this.playerName,
    required this.role,
    this.saveFilePath,
    super.key,
  });

  final String playerName;
  final String role;
  final String? saveFilePath;

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  CharacterData? _character;
  String? _saveFilePath;
  String _saveFileName = '未选择';
  List<CharacterData> _loadedCharacters = [];

  bool _isReady = false;

  StreamSubscription<String>? _msgSub;

  @override
  void initState() {
    super.initState();
    _saveFilePath = (widget.saveFilePath?.isEmpty ?? true)
        ? null
        : widget.saveFilePath;
    if (_saveFilePath != null) {
      _saveFileName = _saveFilePath!.split('/').last.split('\\').last;
      _loadSaveData();
    }

    // Listen for server messages (adventure_started)
    final client = RoomSession.instance.clientHandle;
    if (client != null) {
      _msgSub = client.messages.listen(_handleMessage);
    }
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message.trim()) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      if (type == 'adventure_started') {
        if (!mounted) return;
        // Set the map immediately so AdventurePage can pick it up on init
        if (data['map'] != null) {
          RoomSession.instance.mapNotifier.value = MapData.fromJson(
            data['map'] as Map<String, dynamic>,
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdventurePage(
              playerName: widget.playerName,
              role: widget.role,
              saveFilePath: _saveFilePath,
              character: _character,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  void _loadSaveData() {
    if (_saveFilePath == null) return;
    try {
      final json = jsonDecode(File(_saveFilePath!).readAsStringSync());
      final save = SaveData.fromJson(json as Map<String, dynamic>);
      _loadedCharacters = save.characters;
    } catch (_) {
      _loadedCharacters = [];
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
      _isReady = false;
    });
    _loadSaveData();
  }

  void _selectCharacter(CharacterData c) {
    setState(() => _character = c);
  }

  Future<void> _navigateToCreateSave() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CreateSavePage()),
    );
    if (result != null && mounted) {
      setState(() {
        _saveFilePath = result;
        _saveFileName = result.split('/').last.split('\\').last;
        _character = null;
        _isReady = false;
      });
      _loadSaveData();
    }
  }

  void _markReady() {
    if (_character == null) return;
    setState(() => _isReady = true);
    RoomSession.instance.setPlayerReady(widget.playerName);
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── 已选定角色 → 角色详情 ──
    if (_character != null) {
      return _buildCharacterView(theme);
    }

    // ── 角色选择页 ──
    return _buildCharacterSelection(theme);
  }

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
                    onPressed: _markReady,
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
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
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

              // ── 创建新角色 ──
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
}

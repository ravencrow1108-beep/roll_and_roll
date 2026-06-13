import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:roll_and_roll/save_data.dart';

/// 角色详情视图（准备冒险前查看角色信息）
class CharacterView extends StatelessWidget {
  const CharacterView({
    required this.character,
    required this.isReady,
    required this.onBack,
    required this.onStart,
    this.saveFileName,
    super.key,
  });

  final CharacterData character;
  final bool isReady;
  final VoidCallback onBack;
  final VoidCallback onStart;
  final String? saveFileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = character;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('欢迎，${c.name}',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (c.portraitBase64.isNotEmpty)
                ClipOval(
                  child: Image.memory(
                    base64Decode(c.portraitBase64),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text('职业: ${c.className}'),
              Text('种族: ${c.race} · Lv${c.level}'),
              if (c.skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                    '技能: ${c.skills.map((s) => s.name).join(", ")}'),
              ],
              if (saveFileName != null) ...[
                const SizedBox(height: 16),
                Text('已加载存档: $saveFileName',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12)),
              ],
              const SizedBox(height: 32),
              if (!isReady)
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(
                        Icons.check_circle_outline),
                    label: const Text('准备',
                        style: TextStyle(fontSize: 18)),
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
                        Icon(Icons.check_circle,
                            color: Colors.green),
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
}

/// 角色选择视图
class CharacterSelectionView extends StatelessWidget {
  const CharacterSelectionView({
    required this.playerName,
    required this.saveFileName,
    required this.loadedCharacters,
    required this.onPickSaveFile,
    required this.onSelectCharacter,
    required this.onCreateSave,
    super.key,
  });

  final String playerName;
  final String saveFileName;
  final List<CharacterData> loadedCharacters;
  final VoidCallback onPickSaveFile;
  final void Function(CharacterData c) onSelectCharacter;
  final VoidCallback onCreateSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('选择角色')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('你好，$playerName',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('从存档中选择角色',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.save_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(saveFileName)),
                            IconButton(
                              icon: const Icon(
                                  Icons.folder_open),
                              tooltip: '选择存档文件',
                              onPressed: onPickSaveFile,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (loadedCharacters.isNotEmpty) ...[
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: loadedCharacters.length,
                    itemBuilder: (_, i) {
                      final c = loadedCharacters[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                c.portraitBase64.isNotEmpty
                                    ? MemoryImage(base64Decode(
                                        c.portraitBase64))
                                    : null,
                            child: c.portraitBase64.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(c.name,
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold)),
                          subtitle: Text(
                              '${c.className} · ${c.race} · Lv${c.level}'),
                          trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16),
                          onTap: () => onSelectCharacter(c),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('或自行创建角色',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCreateSave,
                  icon: const Icon(Icons.person_add),
                  label: const Text('创建新角色 (完整创建)',
                      style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
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

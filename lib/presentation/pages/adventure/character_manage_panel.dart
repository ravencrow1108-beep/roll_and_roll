import 'package:flutter/material.dart';
import '../../../data/models/models.dart';

/// 冒险中左侧角色管理面板：添加角色 / 移除角色
class CharacterManagePanel extends StatelessWidget {
  const CharacterManagePanel({
    required this.characters,
    required this.isGM,
    required this.onAddCharacter,
    required this.onRemoveCharacter,
    super.key,
  });

  final List<CharacterData> characters;
  final bool isGM;
  final VoidCallback onAddCharacter;
  final void Function(int index) onRemoveCharacter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '角色管理',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // ── 添加角色按钮（仅 GM） ──
          if (isGM)
            SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                onPressed: onAddCharacter,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('添加角色', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            ),
          if (isGM) const SizedBox(height: 4),
          // ── 角色列表 ──
          if (characters.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: characters.length,
                itemBuilder: (_, i) {
                  final c = characters[i];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${c.className} · Lv${c.level}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: isGM
                        ? IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            tooltip: '移除角色',
                            onPressed: () => onRemoveCharacter(i),
                          )
                        : null,
                  );
                },
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '暂无角色',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

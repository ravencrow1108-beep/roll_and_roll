import 'package:flutter/material.dart';

/// 房间成员列表组件
class MemberList extends StatelessWidget {
  const MemberList({required this.members, required this.roles, super.key});

  final List<String> members;
  final Map<String, String> roles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Text(
            '房间 (${members.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: members.length < 3 ? members.length * 52.0 + 8 : 120,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: members.map((name) {
              final role = roles[name] ?? '';
              return Card(
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: role == '主持'
                        ? Colors.orange
                        : Colors.deepPurple,
                    child: Icon(
                      role == '主持' ? Icons.mic : Icons.person,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 13)),
                  subtitle: role.isNotEmpty
                      ? Text(role, style: const TextStyle(fontSize: 11))
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

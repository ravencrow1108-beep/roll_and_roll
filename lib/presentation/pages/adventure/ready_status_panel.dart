import 'package:flutter/material.dart';
import '../../providers/room_state.dart';

/// 玩家准备状态面板
class ReadyStatusPanel extends StatelessWidget {
  const ReadyStatusPanel({super.key});

  /// 构建各玩家的准备状态指示列表
  @override
  Widget build(BuildContext context) {
    final s = RoomSession.instance;
    final host = s.hostNameNotifier.value;
    final players = s.membersNotifier.value.where((m) => m != host).toList();

    if (players.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              Text('暂无玩家加入', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    final ready = s.readyMembersNotifier.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '玩家准备状态',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...players.map((name) {
              final r = ready.contains(name);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      r ? Icons.check_circle : Icons.hourglass_empty,
                      size: 18,
                      color: r ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(name),
                    const SizedBox(width: 8),
                    Text(
                      r ? '已准备' : '未准备',
                      style: TextStyle(
                        color: r ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

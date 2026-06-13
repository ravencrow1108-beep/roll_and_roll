import 'package:flutter/material.dart';
import 'package:roll_and_roll/models/chat_message.dart';

/// 聊天面板组件
class ChatPanel extends StatelessWidget {
  const ChatPanel({
    required this.chatMessages,
    required this.chatCtrl,
    required this.chatScrollCtrl,
    required this.playerName,
    required this.onSend,
    super.key,
  });

  final List<ChatMessage> chatMessages;
  final TextEditingController chatCtrl;
  final ScrollController chatScrollCtrl;
  final String playerName;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
          child: Text('聊天',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ListView.builder(
            controller: chatScrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: chatMessages.length,
            itemBuilder: (_, i) {
              final msg = chatMessages[i];
              final isMe = msg.from == playerName;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: msg.isSystem
                          ? Colors.grey.shade200
                          : isMe
                              ? Colors.deepPurple.shade100
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: msg.isSystem
                        ? Text(msg.text,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700))
                        : Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMe)
                                Text(
                                  msg.from,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors
                                        .deepPurple.shade700,
                                  ),
                                ),
                              Text(msg.text,
                                  style: const TextStyle(
                                      fontSize: 13)),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border:
                Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatCtrl,
                  decoration: const InputDecoration(
                    hintText: '输入消息…',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send, size: 20),
                color: Colors.deepPurple,
                tooltip: '发送',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

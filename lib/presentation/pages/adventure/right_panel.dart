import 'package:flutter/material.dart';
import '../../../data/models/chat_message.dart';
import 'chat_panel.dart';
import 'member_list.dart';

/// 冒险模式右侧面板：成员列表 + 聊天
class RightPanel extends StatelessWidget {
  const RightPanel({
    required this.members,
    required this.roles,
    required this.chatMessages,
    required this.chatCtrl,
    required this.chatScrollCtrl,
    required this.playerName,
    required this.onSend,
    super.key,
  });

  final List<String> members;
  final Map<String, String> roles;
  final List<ChatMessage> chatMessages;
  final TextEditingController chatCtrl;
  final ScrollController chatScrollCtrl;
  final String playerName;
  final VoidCallback onSend;

  /// 构建成员列表与聊天面板的组合布局
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          MemberList(members: members, roles: roles),
          Expanded(
            child: ChatPanel(
              chatMessages: chatMessages,
              chatCtrl: chatCtrl,
              chatScrollCtrl: chatScrollCtrl,
              playerName: playerName,
              onSend: onSend,
            ),
          ),
        ],
      ),
    );
  }
}

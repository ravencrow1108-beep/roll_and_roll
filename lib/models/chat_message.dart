/// 聊天消息数据模型
class ChatMessage {
  final String from;
  final String text;
  final bool isSystem;

  const ChatMessage({
    required this.from,
    required this.text,
    this.isSystem = false,
  });
}

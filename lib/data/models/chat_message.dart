/// 聊天消息数据模型
class ChatMessage {
  final String from;
  final String text;
  final bool isSystem;

  /// 发送者头像 base64（可选，用于聊天内显示头像）
  final String? portraitBase64;

  /// 是否为骰子消息（投掷结果）
  final bool isDice;

  const ChatMessage({
    required this.from,
    required this.text,
    this.isSystem = false,
    this.portraitBase64,
    this.isDice = false,
  });
}

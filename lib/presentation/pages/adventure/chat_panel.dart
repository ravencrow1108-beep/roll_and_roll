import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../data/models/chat_message.dart';

/// 聊天面板组件，底部输入栏上方有可折叠骰子栏。
class ChatPanel extends StatelessWidget {
  const ChatPanel({
    required this.chatMessages,
    required this.chatCtrl,
    required this.chatScrollCtrl,
    required this.playerName,
    required this.onSend,
    this.diceInputCtrl,
    this.diceResult = '',
    this.onRollDice,
    this.onRollCustom,
    super.key,
  });

  final List<ChatMessage> chatMessages;
  final TextEditingController chatCtrl;
  final ScrollController chatScrollCtrl;
  final String playerName;
  final VoidCallback onSend;

  // ── 骰子（可选） ──
  final TextEditingController? diceInputCtrl;
  final String diceResult;
  final void Function(int sides)? onRollDice;
  final VoidCallback? onRollCustom;

  @override
  Widget build(BuildContext context) {
    final hasDice = onRollDice != null;
    return _ChatPanelBody(
      chatMessages: chatMessages,
      chatCtrl: chatCtrl,
      chatScrollCtrl: chatScrollCtrl,
      playerName: playerName,
      onSend: onSend,
      hasDice: hasDice,
      diceInputCtrl: diceInputCtrl,
      diceResult: diceResult,
      onRollDice: onRollDice,
      onRollCustom: onRollCustom,
    );
  }
}

// ──────────────────────────────────────────────
// 聊天面板主体（含可折叠骰子栏）
// ──────────────────────────────────────────────

class _ChatPanelBody extends StatefulWidget {
  const _ChatPanelBody({
    required this.chatMessages,
    required this.chatCtrl,
    required this.chatScrollCtrl,
    required this.playerName,
    required this.onSend,
    required this.hasDice,
    this.diceInputCtrl,
    this.diceResult = '',
    this.onRollDice,
    this.onRollCustom,
  });

  final List<ChatMessage> chatMessages;
  final TextEditingController chatCtrl;
  final ScrollController chatScrollCtrl;
  final String playerName;
  final VoidCallback onSend;
  final bool hasDice;
  final TextEditingController? diceInputCtrl;
  final String diceResult;
  final void Function(int sides)? onRollDice;
  final VoidCallback? onRollCustom;

  @override
  State<_ChatPanelBody> createState() => _ChatPanelBodyState();
}

class _ChatPanelBodyState extends State<_ChatPanelBody> {
  bool _diceExpanded = false;
  final FocusNode _chatFocusNode = FocusNode();

  @override
  void dispose() {
    _chatFocusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    widget.onSend();
    _chatFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── 聊天消息列表 ──
        Expanded(
          child: ListView.builder(
            controller: widget.chatScrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: widget.chatMessages.length,
            itemBuilder: (_, i) {
              final msg = widget.chatMessages[i];
              final isMe = msg.from == widget.playerName;
              return _ChatMessageItem(message: msg, isMe: isMe);
            },
          ),
        ),
        // ── 可折叠骰子栏（输入框上方） ──
        if (widget.hasDice)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _diceExpanded
                ? _DiceBar(
                    diceInputCtrl: widget.diceInputCtrl!,
                    diceResult: widget.diceResult,
                    onRollDice: widget.onRollDice!,
                    onRollCustom: widget.onRollCustom!,
                  )
                : const SizedBox.shrink(),
          ),
        // ── 输入栏 ──
        Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── 骰子折叠按钮 ──
              if (widget.hasDice)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: IconButton(
                    onPressed: () =>
                        setState(() => _diceExpanded = !_diceExpanded),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _diceExpanded ? Icons.casino : Icons.casino_outlined,
                        key: ValueKey(_diceExpanded),
                        size: 22,
                      ),
                    ),
                    color: _diceExpanded
                        ? theme.colorScheme.primary
                        : Colors.grey.shade500,
                    tooltip: _diceExpanded ? '收起骰子' : '展开骰子',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              // ── 消息输入（圆角胶囊） ──
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: widget.chatCtrl,
                    focusNode: _chatFocusNode,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: '输入消息…',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                          width: 1.5,
                        ),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // ── 发送按钮 ──
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _handleSend,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  color: Colors.white,
                  tooltip: '发送',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 内嵌骰子快捷栏
// ──────────────────────────────────────────────

class _DiceBar extends StatelessWidget {
  const _DiceBar({
    required this.diceInputCtrl,
    required this.diceResult,
    required this.onRollDice,
    required this.onRollCustom,
  });

  final TextEditingController diceInputCtrl;
  final String diceResult;
  final void Function(int sides) onRollDice;
  final VoidCallback onRollCustom;

  static const _dice = [4, 6, 8, 10, 12, 20, 100];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快捷骰子按钮
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _dice
                .map(
                  (d) => SizedBox(
                    width: 46,
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        backgroundColor: d == 100
                            ? Colors.red.shade50
                            : theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.5,
                              ),
                        foregroundColor: d == 100
                            ? Colors.red.shade700
                            : theme.colorScheme.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => onRollDice(d),
                      child: Text(
                        'd$d',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          // 自定义表达式
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: diceInputCtrl,
                    decoration: InputDecoration(
                      hintText: '2d6+3',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => onRollCustom(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: onRollCustom,
                  child: const Text('投掷', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          // 结果展示
          if (diceResult.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                diceResult,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 聊天气泡项 — 头像 + 名字 + 消息内容
// ──────────────────────────────────────────────

class _ChatMessageItem extends StatelessWidget {
  const _ChatMessageItem({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  static const double _avatarSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 系统消息用居中轻量样式
    if (message.isSystem) {
      return _buildSystemMessage(theme);
    }

    final hasAvatar =
        message.portraitBase64 != null && message.portraitBase64!.isNotEmpty;

    // 骰子消息用特殊样式
    if (message.isDice) {
      return _buildDiceMessage(theme, hasAvatar);
    }

    return _buildNormalMessage(theme, hasAvatar);
  }

  Widget _buildSystemMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.6,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiceMessage(ThemeData theme, bool hasAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 小头像
              _MiniAvatar(portraitBase64: message.portraitBase64, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.from,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalMessage(ThemeData theme, bool hasAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 对方头像（左侧）
          if (!isMe) ...[
            _MiniAvatar(
              portraitBase64: message.portraitBase64,
              size: _avatarSize,
            ),
            const SizedBox(width: 6),
          ],
          // 消息气泡
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 名字标签
                Text(
                  message.from,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isMe
                        ? theme.colorScheme.primary
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          )
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isMe
                          ? const Radius.circular(12)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 自己头像（右侧）
          if (isMe) ...[
            const SizedBox(width: 6),
            _MiniAvatar(
              portraitBase64: message.portraitBase64,
              size: _avatarSize,
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 迷你圆形头像
// ──────────────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({this.portraitBase64, required this.size});

  final String? portraitBase64;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = portraitBase64 != null && portraitBase64!.isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: hasImage
          ? ClipOval(
              child: Image.memory(
                base64Decode(portraitBase64!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _fallback(theme),
              ),
            )
          : _fallback(theme),
    );
  }

  Widget _fallback(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: theme.colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}

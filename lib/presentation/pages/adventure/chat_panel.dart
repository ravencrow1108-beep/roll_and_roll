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
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isSystem
                          ? Colors.grey.shade200
                          : isMe
                              ? Colors.deepPurple.shade100
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: msg.isSystem
                        ? Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMe)
                                Text(
                                  msg.from,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                ),
                              Text(
                                msg.text,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                  ),
                ),
              );
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
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // ── 骰子折叠按钮 ──
                  if (widget.hasDice) ...[
                    IconButton(
                      onPressed: () =>
                          setState(() => _diceExpanded = !_diceExpanded),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _diceExpanded
                              ? Icons.casino
                              : Icons.casino_outlined,
                          key: ValueKey(_diceExpanded),
                          size: 20,
                        ),
                      ),
                      color: _diceExpanded
                          ? Colors.deepPurple
                          : Colors.grey.shade600,
                      tooltip: _diceExpanded ? '收起骰子' : '展开骰子',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                  // ── 消息输入 ──
                  Expanded(
                    child: TextField(
                      controller: widget.chatCtrl,
                      decoration: const InputDecoration(
                        hintText: '输入消息…',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (_) => widget.onSend(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: widget.onSend,
                    icon: const Icon(Icons.send, size: 20),
                    color: Colors.deepPurple,
                    tooltip: '发送',
                  ),
                ],
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
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快捷骰子按钮
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _dice
                .map((d) => SizedBox(
                      width: 50,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: d == 100
                              ? Colors.red.shade100
                              : Colors.deepPurple.shade100,
                          foregroundColor: d == 100
                              ? Colors.red.shade900
                              : Colors.deepPurple.shade900,
                        ),
                        onPressed: () => onRollDice(d),
                        child: Text('d$d',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // 自定义表达式
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: diceInputCtrl,
                  decoration: const InputDecoration(
                    hintText: '2d6+3',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => onRollCustom(),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: onRollCustom,
                  child: const Text('投掷', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          // 结果展示
          if (diceResult.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                diceResult,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

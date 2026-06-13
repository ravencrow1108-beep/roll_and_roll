import 'package:flutter/material.dart';

/// 骰子面板组件
class DicePanel extends StatelessWidget {
  const DicePanel({
    required this.diceInputCtrl,
    required this.diceResult,
    required this.onRollDice,
    required this.onRollCustom,
    super.key,
  });

  final TextEditingController diceInputCtrl;
  final String diceResult;
  final void Function(int sides) onRollDice;
  final VoidCallback onRollCustom;

  static const _dice = [4, 6, 8, 10, 12, 20];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    return Container(
      width: isWide ? 160 : null,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: isWide
            ? Border(right: BorderSide(color: theme.dividerColor))
            : Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text('骰子',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _dice
                .map((d) => SizedBox(
                      width: isWide ? 68 : 52,
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.deepPurple.shade100,
                          foregroundColor: Colors.deepPurple.shade900,
                        ),
                        onPressed: () => onRollDice(d),
                        child: Text('d$d',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: isWide ? 140 : double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
              ),
              onPressed: () => onRollDice(100),
              child: const Text('d100',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (isWide) ...[
            const SizedBox(height: 10),
            TextField(
              controller: diceInputCtrl,
              decoration: const InputDecoration(
                hintText: '2d6+3',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onSubmitted: (_) => onRollCustom(),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: onRollCustom,
                child: const Text('投掷', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
          if (diceResult.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  diceResult,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

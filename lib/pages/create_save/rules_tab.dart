import 'package:flutter/material.dart';

/// 规则 Tab
class RulesTab extends StatelessWidget {
  const RulesTab({
    super.key,
    required this.turnSettings,
    required this.phaseSettings,
    required this.onAddTurn,
    required this.onRemoveTurn,
    required this.onTurnChanged,
    required this.onAddPhase,
    required this.onRemovePhase,
    required this.onPhaseChanged,
  });

  final List<String> turnSettings;
  final List<String> phaseSettings;
  final VoidCallback onAddTurn;
  final void Function(int) onRemoveTurn;
  final void Function(int, String) onTurnChanged;
  final VoidCallback onAddPhase;
  final void Function(int) onRemovePhase;
  final void Function(int, String) onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '回合设置',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            turnSettings.isEmpty ? '暂未设置回合参数' : '已设置 ${turnSettings.length} 项',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddTurn,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加回合设置', style: TextStyle(fontSize: 16)),
            ),
          ),
          if (turnSettings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(turnSettings.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: turnSettings[i],
                        decoration: InputDecoration(
                          labelText: '回合设置 #${i + 1}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => onTurnChanged(i, v),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemoveTurn(i),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: '删除',
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 32),
          Text(
            '环节设置',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '已设置 ${phaseSettings.length} 个环节',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddPhase,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加环节', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(phaseSettings.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: phaseSettings[i],
                      decoration: InputDecoration(
                        labelText: '环节 #${i + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => onPhaseChanged(i, v),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemovePhase(i),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: '删除环节',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

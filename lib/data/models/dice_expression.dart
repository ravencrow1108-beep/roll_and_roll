import 'dart:math';

/// 骰子表达式解析结果
class DiceRollResult {
  final List<int> individualRolls;
  final int total;
  final String expression;

  const DiceRollResult({
    required this.individualRolls,
    required this.total,
    required this.expression,
  });

  @override
  String toString() =>
      '$expression => $total ${individualRolls.isNotEmpty ? individualRolls : ""}';
}

/// 骰子表达式解析器 — 支持如 "2d6+3", "1d8+1d4", "d20+力量", "2d6+敏捷+1d4" 等
class DiceExpression {
  static final _dicePattern = RegExp(r'(\d+)?d(\d+)', caseSensitive: false);
  static final _attrPattern = RegExp(r'[+\-]\s*(力量|敏捷|体质|智力|感知|魅力)');

  /// 解析并投掷骰子表达式
  /// [expression] 如 "2d6+3", "d20+力量"
  /// [statModifiers] 属性名到调整值的映射
  static DiceRollResult roll(
    String expression, {
    Map<String, int>? statModifiers,
  }) {
    final mods = statModifiers ?? {};
    final rolls = <int>[];
    int total = 0;
    String remaining = expression.trim();

    // 先提取所有骰子部分
    for (final match in _dicePattern.allMatches(remaining)) {
      final count = int.tryParse(match.group(1) ?? '1') ?? 1;
      final sides = int.tryParse(match.group(2) ?? '6') ?? 6;
      final rng = Random();
      for (int i = 0; i < count; i++) {
        final roll = rng.nextInt(sides) + 1;
        rolls.add(roll);
        total += roll;
      }
    }

    // 处理固定数值加成 (如 +3, -2)
    final fixedPattern = RegExp(r'([+\-])\s*(\d+)');
    for (final match in fixedPattern.allMatches(remaining)) {
      final sign = match.group(1) == '-' ? -1 : 1;
      final val = int.tryParse(match.group(2) ?? '0') ?? 0;
      total += sign * val;
    }

    // 处理属性加成 (如 +力量)
    for (final match in _attrPattern.allMatches(remaining)) {
      final sign = match.group(0)!.trimLeft().startsWith('-') ? -1 : 1;
      final attrName = match.group(1)!;
      final mod = mods[attrName] ?? 0;
      total += sign * mod;
    }

    return DiceRollResult(
      individualRolls: rolls,
      total: total,
      expression: expression,
    );
  }

  /// 校验表达式是否合法
  static bool isValid(String? expression) {
    if (expression == null || expression.trim().isEmpty) return false;
    final cleaned = expression.trim();
    return _dicePattern.hasMatch(cleaned) || _attrPattern.hasMatch(cleaned);
  }
}

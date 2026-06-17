import 'dart:math';

import '../../data/models/equipment_data.dart';

// ──────────────────────────────────────────────
// Token
// ──────────────────────────────────────────────

enum _TT { num_, dice, path, op, lparen, rparen }

class _Tok {
  final _TT type;
  final String val;
  const _Tok(this.type, this.val);

  bool get isOp => type == _TT.op;
  int get prec => val == '+' || val == '-' ? 1 : 2;
}

// ──────────────────────────────────────────────
// EvalContext
// ──────────────────────────────────────────────

class EvalContext {
  final Map<String, EquipmentData?> equipment;
  final Map<String, int> stats;
  final int baseAc;

  const EvalContext({
    this.equipment = const {},
    this.stats = const {},
    this.baseAc = 10,
  });
}

// ──────────────────────────────────────────────
// ExpressionEngine  —  infix → RPN → eval
// ──────────────────────────────────────────────

/// 语法示例：
///   装备/头盔/AC + 装备/手甲/AC + 10 + 1d4
///   装备.头盔.AC + 力量
///   (力量 + 敏捷) / 2
class ExpressionEngine {
  const ExpressionEngine();

  /// 求值，失败抛 [FormatException]
  int eval(String expr, EvalContext ctx) {
    final tokens = _lex(expr);
    if (tokens.isEmpty) return 0;
    final rpn = _toRpn(tokens);
    return _exec(rpn, ctx);
  }
}

// ══════════════════════════════════════════════
// 词法分析
// ══════════════════════════════════════════════

const _pathStarters = {
  '装备', '物品',
  '力量', '敏捷', '体质', '智力', '感知', '魅力',
};

bool _isPathStarter(String s) => _pathStarters.contains(s);

bool _isIdChar(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 0x4E00 && c <= 0x9FFF) ||
      (c >= 0x3400 && c <= 0x4DBF) ||
      (c >= 0x61 && c <= 0x7A) || // a-z
      (c >= 0x41 && c <= 0x5A) || // A-Z
      (c >= 0x30 && c <= 0x39) || // 0-9
      c == 0x5F; // _
}

bool _isDigit(String ch) {
  final c = ch.codeUnitAt(0);
  return c >= 0x30 && c <= 0x39;
}

List<_Tok> _lex(String s) {
  final tokens = <_Tok>[];
  int i = 0;
  final n = s.length;

  void addNumLike(String raw) {
    if (i < n && s[i] == 'd' && i + 1 < n && _isDigit(s[i + 1])) {
      i++;
      final dStart = i;
      while (i < n && _isDigit(s[i])) {
        i++;
      }
      tokens.add(_Tok(_TT.dice, '${raw}d${s.substring(dStart, i)}'));
    } else {
      tokens.add(_Tok(_TT.num_, raw));
    }
  }

  while (i < n) {
    final ch = s[i];

    if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
      i++;
      continue;
    }

    if (_isDigit(ch)) {
      final start = i;
      i++;
      while (i < n && _isDigit(s[i])) {
        i++;
      }
      addNumLike(s.substring(start, i));
      continue;
    }

    if (_isIdChar(ch) && !_isDigit(ch)) {
      final start = i;
      i++;
      while (i < n && _isIdChar(s[i])) {
        i++;
      }
      final ident = s.substring(start, i);

      if (_isPathStarter(ident)) {
        final buf = StringBuffer(ident);
        while (i < n && (s[i] == '/' || s[i] == '.')) {
          final sep = s[i];
          i++;
          while (i < n && (s[i] == ' ' || s[i] == '\t')) {
            i++;
          }
          final segStart = i;
          while (i < n && _isIdChar(s[i])) {
            i++;
          }
          if (segStart == i) break;
          buf.write(sep);
          buf.write(s.substring(segStart, i));
        }
        tokens.add(_Tok(_TT.path, buf.toString()));
        continue;
      }

      tokens.add(_Tok(_TT.path, ident));
      continue;
    }

    if (ch == '+' || ch == '-') { tokens.add(_Tok(_TT.op, ch)); i++; continue; }
    if (ch == '*' || ch == '/') { tokens.add(_Tok(_TT.op, ch)); i++; continue; }
    if (ch == '(') { tokens.add(_Tok(_TT.lparen, '(')); i++; continue; }
    if (ch == ')') { tokens.add(_Tok(_TT.rparen, ')')); i++; continue; }

    throw FormatException('表达式包含非法字符: "$ch" (位置 $i)');
  }

  return tokens;
}

// ══════════════════════════════════════════════
// 逆波兰转换（Shunting-yard）
// ══════════════════════════════════════════════

List<_Tok> _toRpn(List<_Tok> infix) {
  final output = <_Tok>[];
  final opStack = <_Tok>[];

  for (final tok in infix) {
    switch (tok.type) {
      case _TT.num_:
      case _TT.dice:
      case _TT.path:
        output.add(tok);

      case _TT.lparen:
        opStack.add(tok);

      case _TT.rparen:
        while (opStack.isNotEmpty && opStack.last.type != _TT.lparen) {
          output.add(opStack.removeLast());
        }
        if (opStack.isEmpty) throw const FormatException('括号不匹配');
        opStack.removeLast();

      case _TT.op:
        while (opStack.isNotEmpty &&
            opStack.last.isOp &&
            opStack.last.prec >= tok.prec) {
          output.add(opStack.removeLast());
        }
        opStack.add(tok);
    }
  }

  while (opStack.isNotEmpty) {
    final top = opStack.removeLast();
    if (top.type == _TT.lparen) throw const FormatException('括号不匹配');
    output.add(top);
  }

  return output;
}

// ══════════════════════════════════════════════
// RPN 求值
// ══════════════════════════════════════════════

final _rng = Random();

int _rollDice(int count, int sides) {
  int sum = 0;
  for (int i = 0; i < count; i++) {
    sum += _rng.nextInt(sides) + 1;
  }
  return sum;
}

int _exec(List<_Tok> rpn, EvalContext ctx) {
  final stack = <int>[];

  for (final tok in rpn) {
    switch (tok.type) {
      case _TT.num_:
        stack.add(int.parse(tok.val));

      case _TT.dice:
        final parts = tok.val.split('d');
        final count = int.parse(parts[0]);
        final sides = int.parse(parts[1]);
        if (count <= 0 || sides <= 0) throw FormatException('无效骰子: ${tok.val}');
        stack.add(_rollDice(count, sides));

      case _TT.path:
        stack.add(_resolvePath(tok.val, ctx));

      case _TT.op:
        if (stack.length < 2) throw const FormatException('表达式不完整');
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (tok.val) {
          case '+': stack.add(a + b);
          case '-': stack.add(a - b);
          case '*': stack.add(a * b);
          case '/':
            if (b == 0) throw const FormatException('除以零');
            stack.add(a ~/ b);
          default: throw FormatException('未知运算符: ${tok.val}');
        }

      case _TT.lparen:
      case _TT.rparen:
        throw const FormatException('表达式异常：残留括号');
    }
  }

  if (stack.length != 1) throw const FormatException('表达式不完整');
  return stack.first;
}

// ══════════════════════════════════════════════
// 路径解析
// ══════════════════════════════════════════════

int _resolvePath(String path, EvalContext ctx) {
  final segments = path
      .split(RegExp(r'[/.]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (segments.isEmpty) return 0;

  final root = segments.first;

  // ── 装备/槽位/属性 ──
  if (root == '装备' && segments.length >= 3) {
    final slot = segments[1];
    final prop = segments[2].toLowerCase();
    final eq = ctx.equipment[slot];
    if (eq == null) return 0;
    switch (prop) {
      case 'ac': return eq.ac;
      case 'value': case '价值': return eq.value;
      case 'weight': case '负重': return eq.weight;
      default: return 0;
    }
  }

  // ── 物品路径（预留） ──
  if (root == '物品' && segments.length >= 2) return 0;

  // ── 属性（单段） ──
  final stats = ctx.stats;
  if (stats.containsKey(root)) return stats[root]!;

  return 0;
}

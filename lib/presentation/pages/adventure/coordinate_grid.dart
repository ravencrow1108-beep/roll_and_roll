import 'package:flutter/material.dart';

/// 坐标系 + 网格 CustomPainter，左上角为原点 (0,0)，
/// x 向右递增，y 向下递增。
class CoordinateGridPainter extends CustomPainter {
  CoordinateGridPainter({
    required this.columns,
    required this.rows,
    this.unit = '',
    this.showLabels = true,
    this.showGrid = true,
    this.showMinorGrid = false,
    this.step = 1,
  });

  final int columns;
  final int rows;
  final String unit;
  final bool showLabels;
  final bool showGrid;
  final bool showMinorGrid;

  /// 网格步长：1 表示每格画线，2 表示隔一格画线，以此类推
  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns <= 0 || rows <= 0) return;

    final cellW = size.width / columns;
    final cellH = size.height / rows;

    if (showGrid) {
      _drawGrid(canvas, size, cellW, cellH);
    }

    if (showMinorGrid && columns > 1 && rows > 1) {
      _drawMinorGrid(canvas, size, cellW, cellH);
    }

    _drawAxes(canvas, size);

    if (showLabels) {
      _drawLabels(canvas, size, cellW, cellH);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double cellW, double cellH) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    // 竖线（按步长）
    for (int i = step; i <= columns; i += step) {
      final x = cellW * i.toDouble();
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // 横线（按步长）
    for (int i = step; i <= rows; i += step) {
      final y = cellH * i.toDouble();
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawMinorGrid(Canvas canvas, Size size, double cellW, double cellH) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.4;

    final int halfStep = (step ~/ 2).clamp(1, step);
    if (halfStep == step || halfStep == 0) return;

    for (int i = halfStep; i <= columns; i += halfStep) {
      if (i % step == 0) continue;
      final x = cellW * i.toDouble();
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int i = halfStep; i <= rows; i += halfStep) {
      if (i % step == 0) continue;
      final y = cellH * i.toDouble();
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// 绘制坐标轴（左上两条加粗边界）
  void _drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    // 左边 Y 轴
    canvas.drawLine(Offset.zero, Offset(0, size.height), axisPaint);
    // 顶部 X 轴
    canvas.drawLine(Offset.zero, Offset(size.width, 0), axisPaint);

    // 原点标记
    canvas.drawCircle(Offset.zero, 4, axisPaint);
  }

  void _drawLabels(Canvas canvas, Size size, double cellW, double cellH) {
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 9,
      fontWeight: FontWeight.w600,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
    );

    // X 轴标签（顶部）按步长
    for (int i = 0; i <= columns; i += step) {
      final double x = cellW * i.toDouble();
      final text = _labelText(i, unit);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cellW * step.toDouble() + 10);

      final double dx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      final double dy = 4.0;
      tp.paint(canvas, Offset(dx, dy));
    }

    // Y 轴标签（左侧）按步长
    for (int i = 0; i <= rows; i += step) {
      final double y = cellH * i.toDouble();
      final text = _labelText(i, unit);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cellW * step.toDouble() + 10);

      final dx = 4.0;
      final dy = y - tp.height / 2;
      final clippedDy = dy.clamp(0.0, size.height - tp.height);
      tp.paint(canvas, Offset(dx, clippedDy));
    }
  }

  String _labelText(int index, String unit) {
    if (unit.isNotEmpty) return '$index $unit';
    return '$index';
  }

  @override
  bool shouldRepaint(covariant CoordinateGridPainter oldDelegate) {
    return columns != oldDelegate.columns ||
        rows != oldDelegate.rows ||
        unit != oldDelegate.unit ||
        showLabels != oldDelegate.showLabels ||
        showGrid != oldDelegate.showGrid ||
        showMinorGrid != oldDelegate.showMinorGrid ||
        step != oldDelegate.step;
  }
}

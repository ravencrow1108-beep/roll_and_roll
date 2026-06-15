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
  });

  final int columns;
  final int rows;
  final String unit;
  final bool showLabels;
  final bool showGrid;
  final bool showMinorGrid;

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

    // 竖线
    for (int i = 1; i < columns; i++) {
      final x = cellW * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // 横线
    for (int i = 1; i < rows; i++) {
      final y = cellH * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawMinorGrid(Canvas canvas, Size size, double cellW, double cellH) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.4;

    final halfW = cellW / 2;
    final halfH = cellH / 2;

    for (int i = 0; i < columns; i++) {
      final x = cellW * i + halfW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int i = 0; i < rows; i++) {
      final y = cellH * i + halfH;
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

  void _drawLabels(
    Canvas canvas,
    Size size,
    double cellW,
    double cellH,
  ) {
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 9,
      fontWeight: FontWeight.w600,
      shadows: const [
        Shadow(color: Colors.black87, blurRadius: 2),
      ],
    );

    // X 轴标签（顶部）
    for (int i = 0; i <= columns; i++) {
      final x = cellW * i;
      final text = _labelText(i, unit);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cellW + 10);

      // 在格子顶部居中，略微偏移避免与轴重叠
      final dx = x - tp.width / 2;
      final dy = 4.0;
      // 处理边界裁剪
      final clippedDx = dx.clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(clippedDx, dy));
    }

    // Y 轴标签（左侧）
    for (int i = 0; i <= rows; i++) {
      final y = cellH * i;
      final text = _labelText(i, unit);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cellW + 10);

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
        showMinorGrid != oldDelegate.showMinorGrid;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Biểu đồ cột đơn giản (tự vẽ, không phụ thuộc thư viện ngoài).
class SimpleBarChart extends StatelessWidget {
  final List<double?> values;
  final List<String> labels;
  final double? goal;
  final String? goalLabel;
  final double? maxY;
  final double height;
  final Color? color;
  final String Function(double)? yFormat;

  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.goal,
    this.goalLabel,
    this.maxY,
    this.height = 170,
    this.color,
    this.yFormat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          values: values,
          labels: labels,
          goal: goal,
          goalLabel: goalLabel,
          maxY: maxY,
          barColor: color ?? cs.primary,
          gridColor: cs.outlineVariant.withOpacity(0.5),
          textColor: cs.onSurfaceVariant,
          goalColor: cs.tertiary,
          yFormat: yFormat ?? (v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double?> values;
  final List<String> labels;
  final double? goal;
  final String? goalLabel;
  final double? maxY;
  final Color barColor, gridColor, textColor, goalColor;
  final String Function(double) yFormat;

  _BarPainter({
    required this.values,
    required this.labels,
    required this.goal,
    required this.goalLabel,
    required this.maxY,
    required this.barColor,
    required this.gridColor,
    required this.textColor,
    required this.goalColor,
    required this.yFormat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, bottom = 20.0, top = 8.0;
    final w = size.width - left;
    final h = size.height - bottom - top;
    final dataMax = values.whereType<double>().fold<double>(0, (a, b) => math.max(a, b));
    double ymax = (maxY ?? math.max(dataMax, goal ?? 0.0) * 1.15).toDouble();
    if (ymax <= 0) ymax = 1;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + h - h * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      _text(canvas, yFormat(ymax * i / 3), Offset(0, y - 6), 10, width: left - 4, align: TextAlign.right);
    }

    final n = values.length;
    if (n == 0) return;
    final slot = w / n;
    final bw = math.max(2.0, math.min(28.0, slot * 0.6));
    final paint = Paint()..color = barColor;
    final labelEvery = (n / 10).ceil().clamp(1, 1000);
    for (var i = 0; i < n; i++) {
      final v = values[i];
      final cx = left + slot * i + slot / 2;
      if (v != null && v > 0) {
        final bh = h * (v / ymax).clamp(0.0, 1.0);
        final r = RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - bw / 2, top + h - bh, bw, bh),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(r, paint);
      }
      if (i % labelEvery == 0 && i < labels.length) {
        _text(canvas, labels[i], Offset(cx - 20, size.height - bottom + 4), 10, width: 40, align: TextAlign.center);
      }
    }

    if (goal != null && goal! > 0 && goal! <= ymax) {
      final y = top + h - h * goal! / ymax;
      final gp = Paint()
        ..color = goalColor
        ..strokeWidth = 1.5;
      for (double x = left; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), gp);
      }
      if (goalLabel != null) {
        _text(canvas, goalLabel!, Offset(size.width - 120, y - 14), 10, width: 120, align: TextAlign.right, color: goalColor);
      }
    }
  }

  void _text(Canvas c, String s, Offset o, double fs, {double width = 60, TextAlign align = TextAlign.left, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: fs, color: color ?? textColor)),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => true;
}

class ChartSeries {
  final String name;
  final Color color;
  final List<double?> values;
  const ChartSeries(this.name, this.color, this.values);
}

/// Biểu đồ đường nhiều chuỗi; giá trị null tạo khoảng trống.
class SimpleLineChart extends StatelessWidget {
  final List<ChartSeries> series;
  final List<String> labels;
  final double minY;
  final double maxY;
  final double height;

  const SimpleLineChart({
    super.key,
    required this.series,
    required this.labels,
    this.minY = 1,
    this.maxY = 5,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _LinePainter(
              series: series,
              labels: labels,
              minY: minY,
              maxY: maxY,
              gridColor: cs.outlineVariant.withOpacity(0.5),
              textColor: cs.onSurfaceVariant,
            ),
          ),
        ),
        if (series.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                for (final s in series)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(s.name, style: const TextStyle(fontSize: 12)),
                  ]),
              ],
            ),
          ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<ChartSeries> series;
  final List<String> labels;
  final double minY, maxY;
  final Color gridColor, textColor;

  _LinePainter({
    required this.series,
    required this.labels,
    required this.minY,
    required this.maxY,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 24.0, bottom = 20.0, top = 8.0, right = 8.0;
    final w = size.width - left - right;
    final h = size.height - bottom - top;
    final double range = (maxY - minY) == 0 ? 1.0 : (maxY - minY);
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final steps = (maxY - minY).round().clamp(1, 6);
    for (var i = 0; i <= steps; i++) {
      final v = minY + (maxY - minY) * i / steps;
      final y = top + h - h * (v - minY) / range;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      _text(canvas, v.toStringAsFixed(0), Offset(0, y - 6), width: left - 4, align: TextAlign.right);
    }
    final n = labels.length;
    if (n == 0) return;
    double xAt(int i) => n == 1 ? left + w / 2 : left + w * i / (n - 1);
    double yAt(double v) => top + h - h * ((v - minY) / range).clamp(0.0, 1.0);

    final labelEvery = (n / 8).ceil().clamp(1, 1000);
    for (var i = 0; i < n; i += labelEvery) {
      _text(canvas, labels[i], Offset(xAt(i) - 20, size.height - bottom + 4), width: 40, align: TextAlign.center);
    }

    for (final s in series) {
      final p = Paint()
        ..color = s.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dot = Paint()..color = s.color;
      Offset? prev;
      for (var i = 0; i < s.values.length && i < n; i++) {
        final v = s.values[i];
        if (v == null) {
          prev = null;
          continue;
        }
        final pt = Offset(xAt(i), yAt(v));
        if (prev != null) canvas.drawLine(prev, pt, p);
        canvas.drawCircle(pt, 2.6, dot);
        prev = pt;
      }
    }
  }

  void _text(Canvas c, String s, Offset o, {double width = 40, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 10, color: textColor)),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScoreRingPainter extends CustomPainter {
  final double percent;
  final Color  progressColor;
  final Color  trackColor;
  final double strokeWidth;

  const ScoreRingPainter({
    required this.percent,
    required this.progressColor,
    required this.trackColor,
    this.strokeWidth = 7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final base = Paint()
      ..color      = trackColor
      ..style      = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap  = StrokeCap.round;

    final arc = Paint()
      ..color      = progressColor
      ..style      = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap  = StrokeCap.round;

    canvas.drawCircle(center, radius, base);

    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * percent.clamp(0.0, 1.0),
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScoreRingPainter old) =>
      old.percent       != percent       ||
      old.progressColor != progressColor ||
      old.trackColor    != trackColor;
}
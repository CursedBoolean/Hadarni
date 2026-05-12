import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Small circular progress indicator drawn with a sweep arc.
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0–1.0
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 36,
    this.strokeWidth = 3.5,
    this.trackColor = const Color(0x33FFFFFF),
    this.progressColor = AppColors.warmOrange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          trackColor: trackColor,
          progressColor: progressColor,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // start at top
        sweepAngle,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor;
}

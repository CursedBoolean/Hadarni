import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Cloud shape with orange border and blue fill, used on letter learning screens.
class CloudShape extends StatelessWidget {
  final Widget? child;
  final double width;
  final double height;

  const CloudShape({
    super.key,
    this.child,
    this.width = 300,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _CloudPainter(),
          ),
          if (child != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: child!,
            ),
        ],
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Build cloud from overlapping ellipses using a combined path
    final rect1 = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.72), width: w * 0.82, height: h * 0.45);
    final rect2 = Rect.fromCenter(
        center: Offset(w * 0.28, h * 0.52), width: w * 0.38, height: h * 0.45);
    final rect3 = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.35), width: w * 0.48, height: h * 0.52);
    final rect4 = Rect.fromCenter(
        center: Offset(w * 0.72, h * 0.48), width: w * 0.38, height: h * 0.45);

    // Combine all ovals into one path for a clean outline
    Path combined = Path();
    combined.addOval(rect1);
    combined.addOval(rect2);
    combined.addOval(rect3);
    combined.addOval(rect4);

    // Fill
    canvas.drawPath(
      combined,
      Paint()
        ..color = AppColors.softBlue
        ..style = PaintingStyle.fill,
    );

    // Draw border on each oval individually for smooth look
    final borderPaint = Paint()
      ..color = AppColors.warmOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // Draw the outer contour only by clipping
    canvas.save();
    canvas.clipPath(
        Path()..addRect(Rect.fromLTWH(-10, -10, w + 20, h + 20)));

    // Re-fill to cover inner borders then draw outer border
    canvas.drawPath(combined, Paint()..color = AppColors.softBlue..style = PaintingStyle.fill);

    // Use a trick: draw each oval's border, then fill over the interior overlaps
    for (final rect in [rect1, rect2, rect3, rect4]) {
      canvas.drawOval(rect, borderPaint);
    }
    // Fill interior again to hide internal border lines
    // Shrink each oval slightly for interior fill
    for (final rect in [rect1, rect2, rect3, rect4]) {
      final inset = rect.deflate(3);
      canvas.drawOval(
        inset,
        Paint()
          ..color = AppColors.softBlue
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'dart:math';

class DirectionalMarker extends StatelessWidget {
  final double direction; // Angle in degrees

  const DirectionalMarker({super.key, required this.direction});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(30, 30), // Size of the icon
      painter: _DirectionalMarkerPainter(direction),
    );
  }
}

class _DirectionalMarkerPainter extends CustomPainter {
  final double direction;

  _DirectionalMarkerPainter(this.direction);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint circlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint arrowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7) // Adjusted for transparency
      ..style = PaintingStyle.fill;

    // Draw the blue circle
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, circlePaint);
    // Draw the white border
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, borderPaint);

    // Calculate the arrow position
    const double arrowLength = 20;
    const double arrowWidth = 20;

    final double adjustedDirection = (direction + 90) % 360; // Adjust direction to match Flutter's coordinate system
    final double arrowX = size.width / 2 + arrowLength * cos(adjustedDirection * pi / 180);
    final double arrowY = size.height / 2 + arrowLength * sin(adjustedDirection * pi / 180);

    // Draw the arrow
    final Path arrowPath = Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(arrowX, arrowY)
      ..lineTo(arrowX - arrowWidth * sin((direction - 90) * pi / 180), arrowY + arrowWidth * cos((direction - 90) * pi / 180))
      ..lineTo(arrowX, arrowY)
      ..lineTo(arrowX + arrowWidth * sin((direction - 90) * pi / 180), arrowY - arrowWidth * cos((direction - 90) * pi / 180))
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint when direction changes
  }
}
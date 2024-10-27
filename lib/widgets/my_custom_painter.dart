import 'dart:ui' as ui;

import 'package:doodle_deck/enum.dart';
import 'package:doodle_deck/widgets/touch_points.dart';
import 'package:flutter/material.dart';

class MyCustomPainter extends CustomPainter {
  List<TouchPoints> pointsList;
  List<Offset> offsetPoints = [];

  MyCustomPainter({required this.pointsList});

  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = Colors.white;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, background);
    canvas.clipRect(rect);

    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i].points != null && pointsList[i + 1].points != null) {
        Paint paint = pointsList[i].paint;

        // Draw eraser strokes
        if (pointsList[i].tool == Tool.eraser) {
          paint = Paint()
            ..color = Colors.white
            ..strokeCap = pointsList[i].paint.strokeCap
            ..strokeWidth = pointsList[i].paint.strokeWidth
            ..isAntiAlias = true;
        }

        // Draw pencil strokes
        canvas.drawLine(
            pointsList[i].points!, pointsList[i + 1].points!, paint);
      } else if (pointsList[i].points != null &&
          pointsList[i + 1].points == null) {
        offsetPoints.clear();
        offsetPoints.add(pointsList[i].points!);
        offsetPoints.add(Offset(
            pointsList[i].points!.dx + 0.1, pointsList[i].points!.dy + 0.1));
        canvas.drawPoints(
            ui.PointMode.points, offsetPoints, pointsList[i].paint);
      }

      // Check for paint bucket tool
      if (pointsList[i].tool == Tool.paintBucket) {
        _drawPaintBucket(
            canvas, pointsList[i].points!, pointsList[i].paint.color);
      }
    }
  }

  /// Fills the drawn area using the paint bucket logic.
  void _drawPaintBucket(Canvas canvas, Offset center, Color color) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double radius = 50.0; // Adjust radius as needed
    Rect rect = Rect.fromCircle(center: center, radius: radius);

    // Draw the paint bucket effect
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

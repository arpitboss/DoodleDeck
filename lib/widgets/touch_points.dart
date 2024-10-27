import 'dart:ui';

import 'package:doodle_deck/enum.dart';

class TouchPoints {
  Paint paint;
  Offset? points;
  Tool tool;

  TouchPoints({required this.points, required this.paint, required this.tool});

  Map<String, dynamic> toJson() {
    return {
      'point': {'dx': '${points?.dx}', 'dy': '${points?.dy}'},
      'tool': tool.toString().split('.').last,
    };
  }
}

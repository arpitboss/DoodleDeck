import 'package:doodle_deck/enum.dart';
import 'package:doodle_deck/widgets/touch_points.dart';

class Stroke {
  List<TouchPoints> points;
  Tool tool;

  Stroke({required this.points, required this.tool});
}

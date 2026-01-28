import 'route_point.dart';

enum ActivityType {
  walking,
  running,
  cycling,
}

class Workout {
  final String id;
  final ActivityType activityType;
  final DateTime startTime;
  final DateTime? endTime;
  final List<RoutePoint> route;
  final double distance; // в километрах
  final Duration duration;

  const Workout({
    required this.id,
    required this.activityType,
    required this.startTime,
    this.endTime,
    required this.route,
    required this.distance,
    required this.duration,
  });

  double get averageSpeed {
    if (duration.inSeconds == 0) return 0;
    return distance / (duration.inSeconds / 3600);
  }
}

import '../../domain/entities/route_point.dart';

enum WorkoutStatus { idle, running, paused, finished, error }

class WorkoutState {
  final WorkoutStatus status;
  final Duration elapsed;
  final double distanceMeters;
  final double avgSpeedMps;
  final List<RoutePoint> route;
  final String? message;

  const WorkoutState({
    required this.status,
    required this.elapsed,
    required this.distanceMeters,
    required this.avgSpeedMps,
    required this.route,
    this.message,
  });

  factory WorkoutState.initial() => const WorkoutState(
    status: WorkoutStatus.idle,
    elapsed: Duration.zero,
    distanceMeters: 0,
    avgSpeedMps: 0,
    route: [],
  );

  WorkoutState copyWith({
    WorkoutStatus? status,
    Duration? elapsed,
    double? distanceMeters,
    double? avgSpeedMps,
    List<RoutePoint>? route,
    String? message,
  }) {
    return WorkoutState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgSpeedMps: avgSpeedMps ?? this.avgSpeedMps,
      route: route ?? this.route,
      message: message,
    );
  }
}

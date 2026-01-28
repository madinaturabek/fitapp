import '../entities/workout.dart';
import '../entities/route_point.dart';

abstract class WorkoutRepository {
  Future<void> startWorkout(ActivityType type);

  Future<void> pauseWorkout();

  Future<Workout> stopWorkout();

  Stream<RoutePoint> getRouteStream();

  Future<List<Workout>> getWorkoutHistory();
}

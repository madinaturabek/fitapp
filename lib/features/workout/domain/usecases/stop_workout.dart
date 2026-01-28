import '../repositories/workout_repository.dart';
import '../entities/workout.dart';

class StopWorkout {
  final WorkoutRepository repository;

  StopWorkout(this.repository);

  Future<Workout> call() {
    return repository.stopWorkout();
  }
}

import '../repositories/workout_repository.dart';
import '../entities/workout.dart';

class StartWorkout {
  final WorkoutRepository repository;

  StartWorkout(this.repository);

  Future<void> call(ActivityType type) {
    return repository.startWorkout(type);
  }
}

import '../repositories/workout_repository.dart';
import '../entities/workout.dart';

class GetWorkoutHistory {
  final WorkoutRepository repository;

  GetWorkoutHistory(this.repository);

  Future<List<Workout>> call() {
    return repository.getWorkoutHistory();
  }
}

import '../repositories/workout_repository.dart';

class PauseWorkout {
  final WorkoutRepository repository;

  PauseWorkout(this.repository);

  Future<void> call() {
    return repository.pauseWorkout();
  }
}

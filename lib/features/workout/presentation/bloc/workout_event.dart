abstract class WorkoutEvent {}

class WorkoutStarted extends WorkoutEvent {
  final String activityType; // "running" | "walking" | "cycling"
  WorkoutStarted(this.activityType);
}

class WorkoutPaused extends WorkoutEvent {}

class WorkoutResumed extends WorkoutEvent {}

class WorkoutStopped extends WorkoutEvent {}

class WorkoutTicked extends WorkoutEvent {
  final Duration elapsed;
  WorkoutTicked(this.elapsed);
}

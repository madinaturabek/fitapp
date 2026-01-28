import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'workout_event.dart';
import 'workout_state.dart';

typedef StartWorkoutFn = Future<void> Function(String activityType);
typedef PauseWorkoutFn = Future<void> Function();
typedef StopWorkoutFn = Future<void> Function();

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final StartWorkoutFn startWorkout;
  final PauseWorkoutFn pauseWorkout;
  final StopWorkoutFn stopWorkout;

  Timer? _timer;
  Duration _elapsed = Duration.zero;

  WorkoutBloc({
    required this.startWorkout,
    required this.pauseWorkout,
    required this.stopWorkout,
  }) : super(WorkoutState.initial()) {
    on<WorkoutStarted>(_onStarted);
    on<WorkoutPaused>(_onPaused);
    on<WorkoutResumed>(_onResumed);
    on<WorkoutStopped>(_onStopped);
    on<WorkoutTicked>(_onTicked);
  }

  Future<void> _onStarted(WorkoutStarted event, Emitter<WorkoutState> emit) async {
    _elapsed = Duration.zero;

    await startWorkout(event.activityType);

    _startTimer();

    emit(state.copyWith(
      status: WorkoutStatus.running,
      elapsed: _elapsed,
    ));
  }

  Future<void> _onPaused(WorkoutPaused event, Emitter<WorkoutState> emit) async {
    _timer?.cancel();
    await pauseWorkout();
    emit(state.copyWith(status: WorkoutStatus.paused));
  }

  Future<void> _onResumed(WorkoutResumed event, Emitter<WorkoutState> emit) async {
    _startTimer();
    emit(state.copyWith(status: WorkoutStatus.running));
  }

  Future<void> _onStopped(WorkoutStopped event, Emitter<WorkoutState> emit) async {
    _timer?.cancel();
    await stopWorkout();
    emit(state.copyWith(status: WorkoutStatus.finished));
  }

  void _onTicked(WorkoutTicked event, Emitter<WorkoutState> emit) {
    _elapsed = event.elapsed;
    emit(state.copyWith(elapsed: _elapsed));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(WorkoutTicked(_elapsed + const Duration(seconds: 1)));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

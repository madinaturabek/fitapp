import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_model.dart';

class WorkoutStorageService {
  static const String _key = 'workouts_history';

  Future<List<WorkoutModel>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => WorkoutModel.fromJson(json)).toList();
  }

  Future<void> saveWorkout(WorkoutModel workout) async {
    final workouts = await getWorkouts();
    workouts.insert(0, workout); // Новые сверху

    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(workouts.map((w) => w.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  Future<void> deleteWorkout(String id) async {
    final workouts = await getWorkouts();
    workouts.removeWhere((w) => w.id == id);

    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(workouts.map((w) => w.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

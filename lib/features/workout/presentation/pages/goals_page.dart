import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_lang.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  double _weeklyDistance = 10.0;
  int _weeklyWorkouts = 3;
  int _dailyCalories = 500;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weeklyDistance = prefs.getDouble('weekly_distance_goal') ?? 10.0;
      _weeklyWorkouts = prefs.getInt('weekly_workouts_goal') ?? 3;
      _dailyCalories = prefs.getInt('daily_calories_goal') ?? 500;
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weekly_distance_goal', _weeklyDistance);
    await prefs.setInt('weekly_workouts_goal', _weeklyWorkouts);
    await prefs.setInt('daily_calories_goal', _dailyCalories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1419),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('Жаттығу мақсаттары', 'Цели тренировок'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildGoalCard(
              tr('Апталық қашықтық', 'Дистанция в неделю'),
              '${_weeklyDistance.toStringAsFixed(1)} км',
              Icons.route_rounded,
              const Color(0xFF00D9FF),
              Slider(
                value: _weeklyDistance,
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: const Color(0xFF00D9FF),
                onChanged: (value) {
                  setState(() => _weeklyDistance = value);
                  _saveGoals();
                  HapticFeedback.selectionClick();
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalCard(
              tr('Апталық жаттығулар', 'Тренировок в неделю'),
              '$_weeklyWorkouts',
              Icons.fitness_center_rounded,
              const Color(0xFF7C3AED),
              Slider(
                value: _weeklyWorkouts.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                activeColor: const Color(0xFF7C3AED),
                onChanged: (value) {
                  setState(() => _weeklyWorkouts = value.toInt());
                  _saveGoals();
                  HapticFeedback.selectionClick();
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalCard(
              tr('Күніне калория', 'Калорий в день'),
              '$_dailyCalories ${tr('ккал', 'ккал')}',
              Icons.local_fire_department_rounded,
              const Color(0xFFFF6B35),
              Slider(
                value: _dailyCalories.toDouble(),
                min: 100,
                max: 1000,
                divisions: 18,
                activeColor: const Color(0xFFFF6B35),
                onChanged: (value) {
                  setState(() => _dailyCalories = value.toInt());
                  _saveGoals();
                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(String title, String value, IconData icon, Color color, Widget slider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          slider,
        ],
      ),
    );
  }
}

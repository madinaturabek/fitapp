import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_details_page.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/localization/app_lang.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    if (email.isEmpty) return;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/workouts?email=$email'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      setState(() {
        _workouts = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  IconData _getWorkoutIcon(String type) {
    switch (type) {
      case 'running': return Icons.directions_run_rounded;
      case 'walking': return Icons.directions_walk_rounded;
      case 'cycling': return Icons.directions_bike_rounded;
      case 'hiit': return Icons.flash_on_rounded;
      case 'yoga': return Icons.self_improvement_rounded;
      case 'swimming': return Icons.pool_rounded;
      case 'strength': return Icons.fitness_center_rounded;
      default: return Icons.fitness_center_rounded;
    }
  }

  Color _getWorkoutColor(String type) {
    switch (type) {
      case 'running': return const Color(0xFF00D9FF);
      case 'walking': return const Color(0xFF10B981);
      case 'cycling': return const Color(0xFF7C3AED);
      case 'hiit': return const Color(0xFFFF6B35);
      case 'yoga': return const Color(0xFFEC4899);
      case 'swimming': return const Color(0xFF0EA5E9);
      case 'strength': return const Color(0xFFEAB308);
      default: return const Color(0xFF00D9FF);
    }
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return tr('Бүгін', 'Сегодня');
    if (difference.inDays == 1) return tr('Кеше', 'Вчера');
    if (difference.inDays < 7) {
      return appLang.value == 'ru'
          ? '${difference.inDays} дн. назад'
          : '${difference.inDays} күн бұрын';
    }

    return '${date.day}.${date.month}.${date.year}';
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
          tr('Жаттығу тарихы', 'История тренировок'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _workouts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_rounded, size: 80, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              tr('Жаттығулар жоқ', 'Нет тренировок'),
              style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _workouts.length,
        itemBuilder: (context, index) {
          final workout = _workouts[index];
          final color = _getWorkoutColor(workout['type']);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutDetailsPage(
                    workout: Map<String, dynamic>.from(workout),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2130),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getWorkoutIcon(workout['type']), color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(workout['date']),
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStat(Icons.timer_outlined, _formatTime(workout['durationSeconds'])),
                      const SizedBox(width: 16),
                      _buildStat(Icons.route_rounded, '${workout['distance'].toStringAsFixed(2)} км'),
                      const SizedBox(width: 16),
                      _buildStat(Icons.local_fire_department_rounded, '${workout['calories']} ккал'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }
}

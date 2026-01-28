import 'package:flutter/material.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final dynamic workout; // позже заменим на Workout entity

  const WorkoutDetailsPage({
    super.key,
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали тренировки'),
      ),
      body: const Center(
        child: Text(
          'Детальная информация о тренировке',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

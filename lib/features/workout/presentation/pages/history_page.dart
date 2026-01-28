import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
      ),
      body: const Center(
        child: Text(
          'Список тренировок',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

import '../../domain/entities/route_point.dart';
import '../widgets/map_widget.dart';
import '../../../../core/localization/app_lang.dart';

class WorkoutDetailsPage extends StatefulWidget {
  final Map<String, dynamic> workout;

  const WorkoutDetailsPage({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  Timer? _playTimer;
  int _currentIndex = 0;
  bool _isPlaying = false;
  late final List<RoutePoint> _route;

  @override
  void initState() {
    super.initState();
    _route = _parseRoute();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  List<RoutePoint> _parseRoute() {
    final List<dynamic> routeJson = widget.workout['route'] ?? [];
    return routeJson.map((p) {
      return RoutePoint(
        latitude: (p['latitude'] as num).toDouble(),
        longitude: (p['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(p['timestamp']),
      );
    }).toList();
  }

  void _toggleReplay() {
    if (_route.isEmpty) return;
    setState(() {
      _isPlaying = !_isPlaying;
    });

    _playTimer?.cancel();
    if (_isPlaying) {
      _playTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        if (!mounted) return;
        if (_currentIndex >= _route.length - 1) {
          setState(() => _isPlaying = false);
          _playTimer?.cancel();
          return;
        }
        setState(() {
          _currentIndex += 1;
        });
      });
    }
  }

  void _seekTo(double value) {
    if (_route.isEmpty) return;
    setState(() {
      _currentIndex = value.round().clamp(0, _route.length - 1);
    });
  }

  String _progressLabel() {
    if (_route.isEmpty) return '--/--';
    return '${_currentIndex + 1}/${_route.length}';
  }

  @override
  Widget build(BuildContext context) {
    final distance = (widget.workout['distance'] as num?)?.toDouble() ?? 0.0;
    final avgSpeed = (widget.workout['avgSpeed'] as num?)?.toDouble() ?? 0.0;
    final pace = (widget.workout['pace'] as num?)?.toDouble() ?? 0.0;
    final steps = (widget.workout['steps'] as num?)?.toInt() ?? 0;
    final duration = (widget.workout['durationSeconds'] as num?)?.toInt() ?? 0;
    final currentPoint = _route.isEmpty ? null : _route[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1419),
        title: Text(
          tr('Жаттығу мәліметтері', 'Детали тренировки'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SizedBox(
            height: 240,
            child: MapWidget(
              route: _route,
              followUser: false,
              currentPoint: currentPoint,
              headerText: tr('Тренировка көрінісі', 'Просмотр тренировки'),
            ),
          ),
          if (_route.length >= 2) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2130),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleReplay,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D9FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: const Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _currentIndex.toDouble(),
                          min: 0,
                          max: (_route.length - 1).toDouble(),
                          onChanged: (value) {
                            _playTimer?.cancel();
                            setState(() => _isPlaying = false);
                            _seekTo(value);
                          },
                          activeColor: const Color(0xFF00D9FF),
                          inactiveColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _progressLabel(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _StatRow(
            icon: Icons.timer_outlined,
            label: tr('Уақыт', 'Время'),
            value: _formatTime(duration),
          ),
          _StatRow(
            icon: Icons.route_rounded,
            label: tr('Қашықтық', 'Дистанция'),
            value: '${distance.toStringAsFixed(2)} км',
          ),
          _StatRow(
            icon: Icons.speed_rounded,
            label: tr('Орташа жылдамдық', 'Ср. скорость'),
            value: '${avgSpeed.toStringAsFixed(1)} км/ч',
          ),
          _StatRow(
            icon: Icons.timer_rounded,
            label: tr('Қарқын', 'Темп'),
            value: '${pace.toStringAsFixed(1)} мин/км',
          ),
          _StatRow(
            icon: Icons.directions_walk_rounded,
            label: tr('Қадамдар', 'Шаги'),
            value: '$steps',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> with TickerProviderStateMixin {
  bool _isActive = false;
  bool _isPaused = false;
  int _seconds = 0;
  Timer? _timer;

  double _distance = 0.0;
  int _calories = 0;
  int _heartRate = 0;
  int _steps = 0;
  double _avgSpeed = 0.0;
  double _pace = 0.0;
  double _elevation = 0.0;
  int _maxHeartRate = 0;

  String _workoutType = 'running';

  final List<int> _heartRateHistory = [];
  final List<double> _speedHistory = [];
  final List<double> _elevationHistory = [];
  int _totalHeartRate = 0;
  int _heartRateCount = 0;

  late AnimationController _pulseController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _workoutType = args;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _toggleWorkout() {
    setState(() {
      if (!_isActive) {
        _isActive = true;
        _isPaused = false;
        _startTimer();
      } else if (_isPaused) {
        _isPaused = false;
        _startTimer();
      } else {
        _isPaused = true;
        _timer?.cancel();
      }
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _stopWorkout() async {
    _timer?.cancel();

    if (_seconds > 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? jsonString = prefs.getString('workouts_history');
        List<Map<String, dynamic>> workouts = [];

        if (jsonString != null) {
          final List<dynamic> jsonList = json.decode(jsonString);
          workouts = jsonList.cast<Map<String, dynamic>>();
        }

        final workout = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': _workoutType,
          'name': _getWorkoutName(),
          'date': DateTime.now().toIso8601String(),
          'durationSeconds': _seconds,
          'distance': _distance,
          'calories': _calories,
          'steps': _steps,
          'avgHeartRate': _heartRateCount > 0 ? (_totalHeartRate / _heartRateCount).round() : 0,
          'maxHeartRate': _maxHeartRate,
          'avgSpeed': _avgSpeed,
          'pace': _pace,
          'elevation': _elevation,
        };

        workouts.insert(0, workout);
        await prefs.setString('workouts_history', json.encode(workouts));

        if (mounted) {
          _showWorkoutSummary();
        }
      } catch (e) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }

    setState(() {
      _isActive = false;
      _isPaused = false;
      _seconds = 0;
      _distance = 0.0;
      _calories = 0;
      _heartRate = 0;
      _steps = 0;
      _avgSpeed = 0.0;
      _pace = 0.0;
      _elevation = 0.0;
      _maxHeartRate = 0;
      _heartRateHistory.clear();
      _speedHistory.clear();
      _elevationHistory.clear();
      _totalHeartRate = 0;
      _heartRateCount = 0;
    });

    HapticFeedback.heavyImpact();
  }

  void _showWorkoutSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0F1419),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 16),

            const Text(
              'Отличная работа!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _getWorkoutName(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Время',
                            _formatTime(_seconds),
                            Icons.timer_outlined,
                            const Color(0xFF00D9FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Дистанция',
                            '${_distance.toStringAsFixed(2)} км',
                            Icons.route_rounded,
                            const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Калории',
                            '$_calories ккал',
                            Icons.local_fire_department_rounded,
                            const Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Ср. пульс',
                            '${_heartRateCount > 0 ? (_totalHeartRate / _heartRateCount).round() : 0}',
                            Icons.favorite_rounded,
                            const Color(0xFFEC4899),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2130),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Шаги', '$_steps шагов'),
                          const Divider(color: Colors.white12, height: 24),
                          _buildSummaryRow('Скорость', '${_avgSpeed.toStringAsFixed(1)} км/ч'),
                          const Divider(color: Colors.white12, height: 24),
                          _buildSummaryRow('Темп', '${_pace.toStringAsFixed(1)} мин/км'),
                          const Divider(color: Colors.white12, height: 24),
                          _buildSummaryRow('Макс. пульс', '$_maxHeartRate bpm'),
                          const Divider(color: Colors.white12, height: 24),
                          _buildSummaryRow('Набор высоты', '${_elevation.toStringAsFixed(0)} м'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Завершить',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;

        final random = math.Random();
        _distance += 0.004 + random.nextDouble() * 0.006;
        _calories += random.nextInt(3);
        _heartRate = 110 + random.nextInt(50);
        _steps += (2 + random.nextInt(3));
        _elevation += random.nextDouble() * 0.5 - 0.2;

        if (_heartRate > _maxHeartRate) {
          _maxHeartRate = _heartRate;
        }

        _totalHeartRate += _heartRate;
        _heartRateCount++;

        if (_distance > 0 && _seconds > 0) {
          _avgSpeed = (_distance / (_seconds / 3600)).clamp(0, 25);
          _pace = (_seconds / 60) / _distance;
        }

        _heartRateHistory.add(_heartRate);
        _speedHistory.add(_avgSpeed);
        _elevationHistory.add(_elevation);

        if (_heartRateHistory.length > 30) {
          _heartRateHistory.removeAt(0);
          _speedHistory.removeAt(0);
          _elevationHistory.removeAt(0);
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String _getWorkoutName() {
    switch (_workoutType) {
      case 'running': return 'Бег';
      case 'walking': return 'Ходьба';
      case 'cycling': return 'Велосипед';
      case 'hiit': return 'HIIT';
      case 'yoga': return 'Йога';
      case 'swimming': return 'Плавание';
      case 'strength': return 'Силовая';
      default: return 'Тренировка';
    }
  }

  IconData _getWorkoutIcon() {
    switch (_workoutType) {
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

  String _getHeartRateZone() {
    if (_heartRate < 100) return 'Разминка';
    if (_heartRate < 120) return 'Жиросжигание';
    if (_heartRate < 140) return 'Кардио';
    if (_heartRate < 160) return 'Пиковая';
    return 'Максимальная';
  }

  Color _getHeartRateZoneColor() {
    if (_heartRate < 100) return const Color(0xFF10B981);
    if (_heartRate < 120) return const Color(0xFFEAB308);
    if (_heartRate < 140) return const Color(0xFFFFA500);
    if (_heartRate < 160) return const Color(0xFFFF6B35);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_isActive) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1C2130),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text(
                              'Завершить тренировку?',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            content: const Text(
                              'Вы потеряете текущий прогресс',
                              style: TextStyle(color: Colors.white54),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Выйти',
                                  style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2130),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                    ),
                  ),

                  Column(
                    children: [
                      Text(
                        _getWorkoutName(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (_isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isPaused
                                ? Colors.orange.withOpacity(0.2)
                                : const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _isPaused ? Colors.orange : const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isPaused ? 'Пауза' : 'В процессе',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _isPaused ? Colors.orange : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2130),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isActive && !_isPaused)
                          AnimatedBuilder(
                            animation: _rippleController,
                            builder: (context, child) {
                              return Container(
                                width: 200 + (_rippleController.value * 40),
                                height: 200 + (_rippleController.value * 40),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00D9FF).withOpacity(0.3 - (_rippleController.value * 0.3)),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),

                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF00D9FF).withOpacity(0.2),
                                const Color(0xFF0EA5E9).withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00D9FF).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _isActive && !_isPaused ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                                    child: Icon(
                                      _getWorkoutIcon(),
                                      color: const Color(0xFF00D9FF),
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatTime(_seconds),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isActive
                                    ? (_isPaused ? 'ПАУЗА' : 'АКТИВНО')
                                    : 'ГОТОВ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _isActive
                                      ? (_isPaused ? Colors.orange : const Color(0xFF10B981))
                                      : Colors.white38,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: _buildLiveMetricCard(
                            '${_distance.toStringAsFixed(2)}',
                            'км',
                            'Дистанция',
                            Icons.route_rounded,
                            const Color(0xFF00D9FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildLiveMetricCard(
                            '$_calories',
                            'ккал',
                            'Калории',
                            Icons.local_fire_department_rounded,
                            const Color(0xFFFF6B35),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildLiveMetricCard(
                            _isActive ? '${_avgSpeed.toStringAsFixed(1)}' : '--',
                            'км/ч',
                            'Скорость',
                            Icons.speed_rounded,
                            const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildLiveMetricCard(
                            _isActive && _distance > 0 ? '${_pace.toStringAsFixed(1)}' : '--',
                            'мин/км',
                            'Темп',
                            Icons.timer_outlined,
                            const Color(0xFFEAB308),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (_isActive && _heartRateHistory.length > 3)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getHeartRateZoneColor().withOpacity(0.15),
                              _getHeartRateZoneColor().withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getHeartRateZoneColor().withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.favorite_rounded, color: _getHeartRateZoneColor(), size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Пульс',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getHeartRateZoneColor().withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getHeartRateZoneColor(),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getHeartRateZone(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _getHeartRateZoneColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$_heartRate',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8, left: 4),
                                  child: Text(
                                    'bpm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 80,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: HeartRateChartPainter(_heartRateHistory, _getHeartRateZoneColor()),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallMetricCard(
                            '$_steps',
                            'Шаги',
                            Icons.directions_walk_rounded,
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallMetricCard(
                            '${_elevation.toStringAsFixed(0)} м',
                            'Набор высоты',
                            Icons.terrain_rounded,
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1419),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    if (_isActive) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: _stopWorkout,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C2130),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFF6B35).withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stop_rounded, color: Color(0xFFFF6B35), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Завершить',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: _isActive ? 2 : 1,
                      child: GestureDetector(
                        onTap: _toggleWorkout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isActive && !_isPaused
                                  ? [const Color(0xFFFF6B35), const Color(0xFFFFA500)]
                                  : [const Color(0xFF00D9FF), const Color(0xFF0EA5E9)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (_isActive && !_isPaused
                                    ? const Color(0xFFFF6B35)
                                    : const Color(0xFF00D9FF)).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  !_isActive
                                      ? Icons.play_arrow_rounded
                                      : (_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  !_isActive
                                      ? 'Старт'
                                      : (_isPaused ? 'Продолжить' : 'Пауза'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetricCard(String value, String unit, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeartRateChartPainter extends CustomPainter {
  final List<int> data;
  final Color color;

  HeartRateChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final maxValue = data.reduce(math.max).toDouble();
    final minValue = data.reduce(math.min).toDouble();
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(HeartRateChartPainter oldDelegate) => true;
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../../../core/localization/app_lang.dart';

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

  final double _distance = 0.0;
  final int _calories = 0;
  final int _steps = 0;
  double _avgSpeed = 0.0;
  final double _elevation = 0.0;
  double _maxSpeed = 0.0;

  String _workoutType = 'running';

  final List<double> _speedHistory = [];
  final List<MapEntry<int, double>> _splitTimes = []; // время и дистанция каждого километра

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _statsController;

  bool _showDetailedStats = false;

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

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
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
    _statsController.dispose();
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

  void _stopWorkout() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    _showWorkoutSummary();
  }

  void _addLap() {
    if (_isActive && !_isPaused) {
      setState(() {
        _splitTimes.add(MapEntry(_seconds, _distance));
      });
      HapticFeedback.lightImpact();
      _showLapNotification();
    }
  }

  void _showLapNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${tr('Айналым', 'Круг')} ${_splitTimes.length} ${tr('жазылды', 'записан')}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00D9FF),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showWorkoutSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a1f3a),
                Color(0xFF0d111d),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00D9FF).withValues(alpha: 0.2),
                                const Color(0xFF4a90e2).withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFEAB308),
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('Керемет жұмыс!', 'Отличная работа!'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('Жаттығу аяқталды', 'Тренировка завершена'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Основные метрики
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                Icons.timer_rounded,
                                tr('Уақыт', 'Время'),
                                _formatTime(_seconds),
                                const Color(0xFF00D9FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                Icons.route_rounded,
                                tr('Қашықтық', 'Дистанция'),
                                '${_distance.toStringAsFixed(2)} км',
                                const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                Icons.local_fire_department_rounded,
                                tr('Калория', 'Калории'),
                                '$_calories ${tr('ккал', 'ккал')}',
                                const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                Icons.directions_walk_rounded,
                                tr('Қадамдар', 'Шаги'),
                                '$_steps ${tr('қадам', 'шагов')}',
                                const Color(0xFF00D9FF),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Детальная статистика
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Детальдар', 'Детали'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(tr('Макс. жылдамдық', 'Макс. скорость'), '${_maxSpeed.toStringAsFixed(1)} км/ч'),
                              _buildDetailRow(tr('Қарқын', 'Темп'), _distance > 0 ? '${(_seconds / 60 / _distance).toStringAsFixed(1)} мин/км' : '--'),
                              _buildDetailRow(tr('Қадамдар', 'Шаги'), _steps.toString()),
                              _buildDetailRow(tr('Биіктік өсімі', 'Набор высоты'), '${_elevation.toStringAsFixed(0)} м'),
                              if (_splitTimes.isNotEmpty)
                                _buildDetailRow(tr('Айналымдар', 'Кругов'), '${_splitTimes.length}'),
                            ],
                          ),
                        ),

                        // Круги
                        if (_splitTimes.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('Айналымдар', 'Круги'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._splitTimes.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final split = entry.value;
                                  final prevTime = index > 0 ? _splitTimes[index - 1].key : 0;
                                  final lapTime = split.key - prevTime;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${tr('Айналым', 'Круг')} ${index + 1}',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatTime(lapTime),
                                          style: const TextStyle(
                                            color: Color(0xFF00D9FF),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Кнопки действий
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      tr('Болдырмау', 'Отменить'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  // Здесь сохранение тренировки
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(tr('Жаттығу сақталды!', 'Тренировка сохранена!')),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00D9FF), Color(0xFF4a90e2)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      tr('Жаттығуды сақтау', 'Сохранить тренировку'),
                                      style: const TextStyle(
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        if (_distance > 0 && _seconds > 0) {
          final currentSpeed =
              (_distance / (_seconds / 3600)).clamp(0.0, 25.0).toDouble();
          _avgSpeed = currentSpeed;
          _speedHistory.add(currentSpeed);
          if (_speedHistory.length > 20) _speedHistory.removeAt(0);

          if (currentSpeed > _maxSpeed) _maxSpeed = currentSpeed;
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
      case 'running':
        return tr('Жүгіру', 'Бег');
      case 'walking':
        return tr('Жүру', 'Ходьба');
      case 'cycling':
        return tr('Велосипед', 'Велосипед');
      case 'hiit':
        return 'HIIT';
      case 'yoga':
        return tr('Йога', 'Йога');
      case 'swimming':
        return tr('Жүзу', 'Плавание');
      default:
        return tr('Жаттығу', 'Тренировка');
    }
  }

  IconData _getWorkoutIcon() {
    switch (_workoutType) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'hiit':
        return Icons.flash_on_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'swimming':
        return Icons.pool_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0d111d),
              Color(0xFF1a1f3a),
              Color(0xFF0d111d),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Верхняя панель
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_isActive) {
                          _showExitDialog();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _getWorkoutName(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (_isActive && !_isPaused)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: Color(0xFF10B981), size: 6),
                                const SizedBox(width: 4),
                                Text(
                                  tr('Жазба', 'Запись'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _showDetailedStats = !_showDetailedStats;
                        });
                        if (_showDetailedStats) {
                          _statsController.forward();
                        } else {
                          _statsController.reverse();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _showDetailedStats
                              ? const Color(0xFF00D9FF).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showDetailedStats
                                ? const Color(0xFF00D9FF)
                                : Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.analytics_rounded,
                          color: _showDetailedStats ? const Color(0xFF00D9FF) : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Главный таймер
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isActive && !_isPaused)
                              AnimatedBuilder(
                                animation: _rippleController,
                                builder: (context, child) {
                                  return Container(
                                    width: 300 + (_rippleController.value * 40),
                                    height: 300 + (_rippleController.value * 40),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFF00D9FF).withValues(alpha: 0.0),
                                          const Color(0xFF00D9FF).withValues(alpha: 0.1 * (1 - _rippleController.value)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF00D9FF).withValues(alpha: 0.15),
                                    const Color(0xFF4a90e2).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: _isActive && !_isPaused
                                    ? [
                                  BoxShadow(
                                    color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ]
                                    : [],
                              ),
                              child: Column(
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _isActive && !_isPaused
                                            ? 1.0 + (_pulseController.value * 0.1)
                                            : 1.0,
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF00D9FF), Color(0xFF4a90e2)],
                                            ),
                                            borderRadius: BorderRadius.circular(22),
                                            boxShadow: _isActive && !_isPaused
                                                ? [
                                              BoxShadow(
                                                color: const Color(0xFF00D9FF).withValues(alpha: 0.6),
                                                blurRadius: 25,
                                                spreadRadius: 3,
                                              ),
                                            ]
                                                : [],
                                          ),
                                          child: Icon(
                                            _getWorkoutIcon(),
                                            color: Colors.white,
                                            size: 48,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _formatTime(_seconds),
                                    style: const TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -2,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isActive
                                          ? (_isPaused
                                          ? Colors.orange.withValues(alpha: 0.2)
                                          : const Color(0xFF10B981).withValues(alpha: 0.2))
                                          : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isActive
                                            ? (_isPaused ? Colors.orange : const Color(0xFF10B981))
                                            : Colors.white24,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isActive
                                              ? (_isPaused ? Icons.pause_circle_filled : Icons.play_circle_filled)
                                              : Icons.radio_button_unchecked,
                                          color: _isActive
                                              ? (_isPaused ? Colors.orange : const Color(0xFF10B981))
                                              : Colors.white54,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isActive
                                              ? (_isPaused ? tr('Үзілісте', 'На паузе') : tr('Белсенді', 'Активно'))
                                              : tr('Бастауға дайын', 'Готов к старту'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: _isActive
                                                ? (_isPaused ? Colors.orange : const Color(0xFF10B981))
                                                : Colors.white54,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Основные метрики
                        Row(
                          children: [
                            Expanded(
                              child: _buildMainMetricCard(
                                tr('Қашықтық', 'Дистанция'),
                                _distance.toStringAsFixed(2),
                                'км',
                                Icons.route_rounded,
                                const Color(0xFF00D9FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMainMetricCard(
                                tr('Калория', 'Калории'),
                                _calories.toString(),
                                'ккал',
                                Icons.local_fire_department_rounded,
                                const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Статистика
                        Text(
                          tr('Статистика', 'Статистика'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                tr('Қашықтық', 'Дистанция'),
                                _isActive ? _distance.toStringAsFixed(2) : '--',
                                'км',
                                Icons.route_rounded,
                                const Color(0xFF00D9FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                tr('Қарқын', 'Темп'),
                                _isActive && _distance > 0
                                    ? '${(_seconds / 60 / _distance).toStringAsFixed(1)}'
                                    : '--',
                                'мин/км',
                                Icons.speed_rounded,
                                const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                tr('Қадамдар', 'Шаги'),
                                _isActive ? _steps.toString() : '--',
                                tr('қадам', 'шагов'),
                                Icons.directions_walk_rounded,
                                const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                tr('Жылдамдық', 'Скорость'),
                                _isActive ? _avgSpeed.toStringAsFixed(1) : '--',
                                'км/ч',
                                Icons.flash_on_rounded,
                                const Color(0xFFEAB308),
                              ),
                            ),
                          ],
                        ),

                        // Дополнительная статистика
                        if (_showDetailedStats) ...[
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _statsController,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        tr('Макс. жылдамдық', 'Макс. скорость'),
                                        _isActive ? '${_maxSpeed.toStringAsFixed(1)}' : '--',
                                        'км/ч',
                                        Icons.trending_up_rounded,
                                        const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        tr('Биіктік өсімі', 'Набор высоты'),
                                        _isActive ? _elevation.toStringAsFixed(0) : '--',
                                        'м',
                                        Icons.terrain_rounded,
                                        const Color(0xFF8B5CF6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        tr('Калория', 'Калории'),
                                        _isActive ? _calories.toString() : '--',
                                        'ккал',
                                        Icons.local_fire_department_rounded,
                                        const Color(0xFFEF4444),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        tr('Айналымдар', 'Кругов'),
                                        '${_splitTimes.length}',
                                        '',
                                        Icons.replay_rounded,
                                        const Color(0xFF06B6D4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),

              // Нижняя панель управления
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0d111d).withValues(alpha: 0.0),
                      const Color(0xFF0d111d),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    if (_isActive && !_isPaused)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: _addLap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flag_rounded, color: Color(0xFF00D9FF), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  tr('Айналым белгілеу', 'Отметить круг'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00D9FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        if (_isActive) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: _stopWorkout,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stop_rounded, color: Color(0xFFEF4444), size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        tr('Аяқтау', 'Завершить'),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFEF4444),
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
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isActive && !_isPaused
                                      ? [const Color(0xFFF97316), const Color(0xFFEF4444)]
                                      : [const Color(0xFF00D9FF), const Color(0xFF4a90e2)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isActive && !_isPaused
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF00D9FF)).withValues(alpha: 0.5),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
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
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      !_isActive
                                          ? tr('Бастау', 'Старт')
                                          : (_isPaused ? tr('Жалғастыру', 'Продолжить') : tr('Үзіліс', 'Пауза')),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f3a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr('Жаттығуды аяқтайсыз ба?', 'Завершить тренировку?'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          tr('Шығуға сенімдісіз бе? Барлық деректер жоғалады.', 'Вы уверены, что хотите выйти? Все данные будут потеряны.'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Бас тарту', 'Отмена'), style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(tr('Шығу', 'Выйти'), style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetricCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
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
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

}

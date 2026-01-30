import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/route_point.dart';
import '../widgets/map_widget.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/localization/app_lang.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  bool _isActive = false;
  bool _isPaused = false;
  int _seconds = 0;
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<StepCount>? _stepSub;

  double _distance = 0.0;
  int _calories = 0;
  int _steps = 0;
  double _avgSpeed = 0.0;
  double _currentSpeed = 0.0;
  double _pace = 0.0;
  double _elevation = 0.0;

  String _workoutType = 'running';

  final List<double> _speedHistory = [];
  final List<RoutePoint> _recentPoints = [];
  DateTime? _lastMovementAt;
  final List<double> _elevationHistory = [];

  final List<RoutePoint> _route = [];
  Position? _lastPosition;
  int _startSteps = 0;
  bool _hasStepBaseline = false;


  @override
  void initState() {
    super.initState();
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
    _positionSub?.cancel();
    _stepSub?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B35),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError(tr('Геолокацияны қосыңыз', 'Включите геолокацию'));
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      _showError(tr('Геолокацияға рұқсат беріңіз', 'Разрешите доступ к геолокации'));
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      _showError(tr('Геолокацияға қолжетімділік жабық. Баптауларды тексеріңіз.', 'Доступ к геолокации запрещен. Проверьте настройки.'));
      return false;
    }
    return true;
  }

  Future<void> _ensureActivityRecognitionPermission() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.activityRecognition.status;
      if (!status.isGranted) {
        await Permission.activityRecognition.request();
      }
    }
  }

  LocationSettings _buildLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Жаттығу белсенді',
          notificationText: 'Маршрут жазылып жатыр',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );
  }

  void _stopTrackingStreams() {
    _positionSub?.cancel();
    _positionSub = null;
    _stepSub?.cancel();
    _stepSub = null;
  }

  Future<void> _startPositionStream() async {
    _positionSub?.cancel();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _onPosition(position);
    } catch (_) {
      // Ignore initial read failures; stream may still work.
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(),
    ).listen(_onPosition, onError: (_) {
      if (mounted) {
      _showError(tr('GPS қатесі', 'Ошибка GPS'));
      }
    });
  }

  void _startStepStream() {
    _stepSub?.cancel();
    _stepSub = Pedometer.stepCountStream.listen((event) {
      if (!_hasStepBaseline) {
        _startSteps = event.steps;
        _hasStepBaseline = true;
      }
      final delta = event.steps - _startSteps;
      if (delta >= 0) {
        setState(() {
          _steps = delta;
        });
      }
    }, onError: (_) {});
  }

  void _onPosition(Position position) {
    if (!_isActive || _isPaused) return;

    final point = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );

    double deltaMeters = 0;
    if (_lastPosition != null) {
      deltaMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    final now = DateTime.now();
    _recentPoints.add(point);
    _recentPoints.removeWhere(
      (p) => now.difference(p.timestamp).inSeconds > 10,
    );

    double liveSpeed = 0.0;
    if (_recentPoints.length >= 2) {
      final first = _recentPoints.first;
      final last = _recentPoints.last;
      final durationSec = now.difference(first.timestamp).inMilliseconds / 1000.0;
      if (durationSec > 0) {
        final meters = Geolocator.distanceBetween(
          first.latitude,
          first.longitude,
          last.latitude,
          last.longitude,
        );
        liveSpeed = (meters / durationSec) * 3.6;
      }
    }

    if (deltaMeters > 1.0) {
      _lastMovementAt = now;
    }
    if (_lastMovementAt == null ||
        now.difference(_lastMovementAt!).inSeconds >= 3 ||
        deltaMeters < 0.3) {
      liveSpeed = 0.0;
    }

    setState(() {
      _route.add(point);
      if (deltaMeters > 0.5) {
        _distance += deltaMeters / 1000.0;
      }
      _lastPosition = position;
      _elevation = position.altitude;

      if (_distance > 0 && _seconds > 0) {
        _avgSpeed = (_distance / (_seconds / 3600)).clamp(0, 25);
        _pace = (_seconds / 60) / _distance;
      }

      _currentSpeed = liveSpeed.clamp(0, 25);
      _speedHistory.add(_currentSpeed);
      _elevationHistory.add(_elevation);
      if (_speedHistory.length > 30) _speedHistory.removeAt(0);
      if (_elevationHistory.length > 30) _elevationHistory.removeAt(0);

      _calories = _estimateCalories();
    });
  }

  int _estimateCalories() {
    final perKm = switch (_workoutType) {
      'running' => 60,
      'walking' => 45,
      'cycling' => 30,
      _ => 40,
    };
    return (_distance * perKm).round();
  }

  Future<void> _toggleWorkout() async {
    if (!_isActive) {
      final ok = await _ensureLocationPermission();
      if (!ok) return;

      setState(() {
        _isActive = true;
        _isPaused = false;
      });

      await _ensureActivityRecognitionPermission();
      _startTimer();
      _startPositionStream();
      _startStepStream();
    } else if (_isPaused) {
      setState(() {
        _isPaused = false;
      });
      _startTimer();
      _startPositionStream();
      _startStepStream();
    } else {
      setState(() {
        _isPaused = true;
      });
      _timer?.cancel();
      _stopTrackingStreams();
    }
    HapticFeedback.mediumImpact();
  }

  Future<void> _stopWorkout() async {
    _timer?.cancel();
    _stopTrackingStreams();

    var shouldPop = false;
    var showSummary = false;
    if (_seconds > 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email') ?? '';
        if (userEmail.isEmpty) {
          _showError(tr('Пайдаланушы email жоқ', 'Нет email пользователя'));
          shouldPop = true;
        } else {
          final workout = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'type': _workoutType,
            'name': _getWorkoutName(),
            'date': DateTime.now().toIso8601String(),
            'durationSeconds': _seconds,
            'distance': _distance,
            'calories': _calories,
            'steps': _steps,
            'avgSpeed': _avgSpeed,
            'pace': _pace,
            'elevation': _elevation,
            'route': _route
                .map((p) => {
              'latitude': p.latitude,
              'longitude': p.longitude,
              'timestamp': p.timestamp.toIso8601String(),
            })
                .toList(),
            'userEmail': userEmail,
          };

          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/workouts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(workout),
          );

          if (response.statusCode != 200) {
            _showError(tr('Жаттығуды сақтау мүмкін болмады', 'Не удалось сохранить тренировку'));
            shouldPop = true;
          } else {
            showSummary = true;
          }
        }
      } catch (e) {
        shouldPop = true;
      }
    } else {
      shouldPop = true;
    }

    if (showSummary && mounted) {
      await _showWorkoutSummary();
    }

    if (!mounted) return;
    setState(() {
      _isActive = false;
      _isPaused = false;
      _seconds = 0;
      _distance = 0.0;
      _calories = 0;
      _steps = 0;
      _avgSpeed = 0.0;
      _currentSpeed = 0.0;
      _pace = 0.0;
      _elevation = 0.0;
      _speedHistory.clear();
      _elevationHistory.clear();
      _route.clear();
      _lastPosition = null;
      _recentPoints.clear();
      _lastMovementAt = null;
      _hasStepBaseline = false;
      _startSteps = 0;
    });

    HapticFeedback.heavyImpact();

    if (shouldPop) {
      Navigator.pop(context);
    }
  }

  Future<void> _showWorkoutSummary() {
    return showModalBottomSheet(
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
                            tr('Уақыт', 'Время'),
                            _formatTime(_seconds),
                            Icons.timer_outlined,
                            const Color(0xFF00D9FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            tr('Қашықтық', 'Дистанция'),
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
                            tr('Калория', 'Калории'),
                            '$_calories ${tr('ккал', 'ккал')}',
                            Icons.local_fire_department_rounded,
                            const Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            tr('Қадамдар', 'Шаги'),
                            '$_steps ${tr('қадам', 'шагов')}',
                            Icons.directions_walk_rounded,
                            const Color(0xFF00D9FF),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (_route.isNotEmpty) ...[
                      SizedBox(
                        height: 220,
                        child: MapWidget(
                          route: _route,
                          followUser: false,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2130),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(tr('Қадамдар', 'Шаги'), '$_steps ${tr('қадам', 'шагов')}'),
                          const Divider(color: Colors.white12, height: 24),
                          _buildSummaryRow(tr('Жылдамдық', 'Скорость'), '${_avgSpeed.toStringAsFixed(1)} км/ч'),
                          const Divider(color: Colors.white12, height: 24),
                          _buildSummaryRow(tr('Қарқын', 'Темп'), '${_pace.toStringAsFixed(1)} мин/км'),
                          const Divider(color: Colors.white12, height: 24),
                          const Divider(color: Colors.white12, height: 24),
                          _buildSummaryRow(tr('Биіктік өсімі', 'Набор высоты'), '${_elevation.toStringAsFixed(0)} м'),
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
                        child: Center(
                          child: Text(
                            tr('Аяқтау', 'Завершить'),
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
      if (!_isActive || _isPaused) return;
      setState(() {
        _seconds++;
        if (_distance > 0 && _seconds > 0) {
          _avgSpeed = (_distance / (_seconds / 3600)).clamp(0, 25);
          _pace = (_seconds / 60) / _distance;
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
      case 'running': return tr('Жүгіру', 'Бег');
      case 'walking': return tr('Жүру', 'Ходьба');
      case 'cycling': return tr('Велосипед', 'Велосипед');
      case 'hiit': return 'HIIT';
      case 'yoga': return tr('Йога', 'Йога');
      case 'swimming': return tr('Жүзу', 'Плавание');
      case 'strength': return tr('Күш', 'Силовая');
      default: return tr('Жаттығу', 'Тренировка');
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
                            title: Text(
                              tr('Жаттығуды аяқтайсыз ба?', 'Завершить тренировку?'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            content: Text(
                              tr('Ағымдағы прогресс жоғалады', 'Вы потеряете текущий прогресс'),
                              style: const TextStyle(color: Colors.white54),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(tr('Бас тарту', 'Отмена'), style: const TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  tr('Шығу', 'Выйти'),
                                  style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w700),
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
                                _isPaused ? tr('Үзіліс', 'Пауза') : tr('Жүріп жатыр', 'В процессе'),
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
                          Icon(
                            _getWorkoutIcon(),
                            color: const Color(0xFF00D9FF),
                            size: 40,
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
                                ? (_isPaused ? tr('ҮЗІЛІС', 'ПАУЗА') : tr('БЕЛСЕНДІ', 'АКТИВНО'))
                                : tr('ДАЙЫН', 'ГОТОВ'),
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

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: _buildLiveMetricCard(
                            '${_distance.toStringAsFixed(2)}',
                            'км',
                            tr('Қашықтық', 'Дистанция'),
                            Icons.route_rounded,
                            const Color(0xFF00D9FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildLiveMetricCard(
                            '$_calories',
                            tr('ккал', 'ккал'),
                            tr('Калория', 'Калории'),
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
                            _isActive ? '${_currentSpeed.toStringAsFixed(1)}' : '--',
                            'км/ч',
                            tr('Жылдамдық', 'Скорость'),
                            Icons.speed_rounded,
                            const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildLiveMetricCard(
                            _isActive && _distance > 0 ? '${_pace.toStringAsFixed(1)}' : '--',
                            'мин/км',
                            tr('Қарқын', 'Темп'),
                            Icons.timer_outlined,
                            const Color(0xFFEAB308),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 220,
                      child: MapWidget(
                        route: _route,
                        followUser: true,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const SizedBox.shrink(),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallMetricCard(
                            '$_steps',
                            tr('Қадамдар', 'Шаги'),
                            Icons.directions_walk_rounded,
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallMetricCard(
                            '${_elevation.toStringAsFixed(0)} м',
                            tr('Биіктік өсімі', 'Набор высоты'),
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
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stop_rounded, color: Color(0xFFFF6B35), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('Аяқтау', 'Завершить'),
                                    style: const TextStyle(
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
                                      ? tr('Бастау', 'Старт')
                                      : (_isPaused ? tr('Жалғастыру', 'Продолжить') : tr('Үзіліс', 'Пауза')),
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

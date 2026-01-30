import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/localization/app_lang.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ActivitySummaryPage(),
    const WorkoutListPage(),
    const ProfilePage(), // ТЕПЕРЬ БЕРЁТСЯ ИЗ profile_page.dart
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C2130),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_rounded, 0),
                _buildNavItem(Icons.bar_chart_rounded, 1),
                _buildNavButton(),
                _buildNavItem(Icons.person_rounded, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D9FF).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF00D9FF)
              : Colors.white.withOpacity(0.4),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNavButton() {
    return GestureDetector(
      onTap: () {
        _showWorkoutTypePicker(context);
        HapticFeedback.mediumImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Icon(
          Icons.add_rounded,
          color: Colors.white.withOpacity(0.4),
          size: 24,
        ),
      ),
    );
  }
}

class _WorkoutTypeOption {
  const _WorkoutTypeOption({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final String key;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

void _showWorkoutTypePicker(BuildContext context) {
  final options = [
    _WorkoutTypeOption(
      key: 'running',
      icon: Icons.directions_run_rounded,
      color: const Color(0xFF00D9FF),
      title: tr('Жүгіру', 'Бег'),
      subtitle: tr('Сыртта/жолда', 'На улице/дорожке'),
    ),
    _WorkoutTypeOption(
      key: 'walking',
      icon: Icons.directions_walk_rounded,
      color: const Color(0xFF10B981),
      title: tr('Жүру', 'Ходьба'),
      subtitle: tr('Жеңіл қарқын', 'Легкий темп'),
    ),
    _WorkoutTypeOption(
      key: 'cycling',
      icon: Icons.directions_bike_rounded,
      color: const Color(0xFF7C3AED),
      title: tr('Велосипед', 'Велосипед'),
      subtitle: tr('Сыртта/тренажер', 'Улица/тренажер'),
    ),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1419),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.sports_mma_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  tr('Тренировка түрін таңдаңыз', 'Выберите тип тренировки'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final option = options[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/tracking', arguments: option.key);
                    HapticFeedback.mediumImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2130),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: option.color.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: option.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(option.icon, color: option.color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// ============ ACTIVITY SUMMARY PAGE ============

class ActivitySummaryPage extends StatefulWidget {
  const ActivitySummaryPage({super.key});

  @override
  State<ActivitySummaryPage> createState() => _ActivitySummaryPageState();
}

class _ActivitySummaryPageState extends State<ActivitySummaryPage> {
  bool _loading = true;
  String? _error;
  int _todaySteps = 0;
  int _todayMinutes = 0;
  int _todayCalories = 0;
  double _todayDistance = 0.0;
  double _progress = 0.0;
  final Map<int, double> _weekDistance = {for (var i = 1; i <= 7; i++) i: 0.0};
  final Map<int, int> _weekCalories = {for (var i = 1; i <= 7; i++) i: 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<String> _weekLabels() {
    return appLang.value == 'ru'
        ? ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС']
        : ['ДҮ', 'СЕ', 'СР', 'БЕ', 'ЖҰ', 'СН', 'ЖС'];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final email = prefs.getString('user_email') ?? '';
      if (email.isEmpty) {
        setState(() {
          _loading = false;
          _error = tr('Пайдаланушы жоқ', 'Пользователь не найден');
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/workouts?email=$email'),
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = tr('Деректер жүктелмеді', 'Не удалось загрузить данные');
        });
        return;
      }

      final List<dynamic> data = json.decode(response.body);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      int todaySteps = 0;
      int todayMinutes = 0;
      int todayCalories = 0;
      double todayDistance = 0.0;

      for (final item in data) {
        final date = DateTime.tryParse(item['date'] ?? '') ?? now;
        final day = DateTime(date.year, date.month, date.day);
        final weekday = day.weekday;

        if (!day.isBefore(weekStart) && !day.isAfter(weekEnd)) {
          _weekDistance[weekday] = (_weekDistance[weekday] ?? 0) + ((item['distance'] as num?)?.toDouble() ?? 0.0);
          _weekCalories[weekday] = (_weekCalories[weekday] ?? 0) + ((item['calories'] as num?)?.toInt() ?? 0);
        }

        if (_isSameDay(day, today)) {
          todaySteps += (item['steps'] as num?)?.toInt() ?? 0;
          todayMinutes += ((item['durationSeconds'] as num?)?.toInt() ?? 0) ~/ 60;
          todayCalories += (item['calories'] as num?)?.toInt() ?? 0;
          todayDistance += (item['distance'] as num?)?.toDouble() ?? 0.0;
        }
      }

      int maxCalories = 0;
      for (final v in _weekCalories.values) {
        if (v > maxCalories) maxCalories = v;
      }

      if (!mounted) return;
      setState(() {
        _todaySteps = todaySteps;
        _todayMinutes = todayMinutes;
        _todayCalories = todayCalories;
        _todayDistance = todayDistance;
        _progress = maxCalories > 0 ? (todayCalories / maxCalories).clamp(0, 1) : 0.0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = tr('Қате пайда болды', 'Произошла ошибка');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: const Color(0xFF0F1419),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
        ),
      );
    }
    if (_error != null) {
      return Container(
        color: const Color(0xFF0F1419),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadData,
                child: Text(
                  tr('Қайталау', 'Повторить'),
                  style: const TextStyle(color: Color(0xFF00D9FF)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxDistance = _weekDistance.values.fold<double>(0.0, (prev, e) => math.max(prev, e));
    final labels = _weekLabels();
    final todayWeekday = DateTime.now().weekday;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1419),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 44, height: 44),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('Белсенділік\nқысқаша', 'Сводка\nактивности'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2130),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tr('Бүгін', 'Сегодня'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            SliverToBoxAdapter(
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: CircularProgressPainter(_progress),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF6B35),
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_todayCalories',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -2,
                            ),
                          ),
                          Text(
                            tr('Жанған калория', 'Сожжено калорий'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                delegate: SliverChildListDelegate([
                  _buildStatCard(
                    '$_todaySteps',
                    tr('қадам', 'шагов'),
                    tr('Күндік қадам', 'Шаги за день'),
                    Icons.directions_walk_rounded,
                    const Color(0xFF00D9FF),
                  ),
                  _buildStatCard(
                    '$_todayMinutes',
                    tr('мин', 'мин'),
                    tr('Белсенді минут', 'Активные минуты'),
                    Icons.timer_outlined,
                    const Color(0xFFEC4899),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2130),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Бүгінгі қашықтық', 'Дистанция за сегодня'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_todayDistance.toStringAsFixed(2)} км',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2130),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('Апталық прогресс', 'Прогресс за неделю'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Icon(Icons.more_horiz_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (index) {
                            final weekday = index + 1;
                            final value = _weekDistance[weekday] ?? 0.0;
                            final height = maxDistance > 0 ? (value / maxDistance) : 0.0;
                            final highlight = weekday == todayWeekday;
                            return _buildWeekBar(labels[index], height, highlight: highlight);
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String unit, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBar(String day, double height, {bool highlight = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const labelHeight = 12.0;
        const gap = 6.0;
        final maxBarHeight = math.max(0.0, constraints.maxHeight - labelHeight - gap);
        final rawBarHeight = maxBarHeight * height;
        final barHeight = rawBarHeight.clamp(0.0, maxBarHeight);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: highlight
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
                      )
                    : null,
                color: highlight ? null : const Color(0xFF2A3142),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: gap),
            SizedBox(
              height: labelHeight,
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: highlight ? const Color(0xFF00D9FF) : Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


// ============ WORKOUTS PAGE ============

class WorkoutListPage extends StatefulWidget {
  const WorkoutListPage({super.key});

  @override
  State<WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends State<WorkoutListPage> {
  String _selectedCategory = 'all';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final email = prefs.getString('user_email') ?? '';
      if (email.isEmpty) {
        setState(() {
          _loading = false;
          _error = tr('Пайдаланушы жоқ', 'Пользователь не найден');
        });
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/workouts?email=$email'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        setState(() {
          _workouts = decoded.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = tr('Деректер жүктелмеді', 'Не удалось загрузить данные');
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = tr('Қате пайда болды', 'Произошла ошибка');
      });
    }
  }

  List<String> get _categories => [
        'all',
        'running',
        'walking',
        'cycling',
      ];

  String _categoryLabel(String key) {
    switch (key) {
      case 'all':
        return tr('Барлығы', 'Все');
      case 'running':
        return tr('Жүгіру', 'Бег');
      case 'walking':
        return tr('Жүру', 'Ходьба');
      case 'cycling':
        return tr('Велосипед', 'Велосипед');
      default:
        return key;
    }
  }

  IconData _getWorkoutIcon(String type) {
    switch (type) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  Color _getWorkoutColor(String type) {
    switch (type) {
      case 'running':
        return const Color(0xFF00D9FF);
      case 'walking':
        return const Color(0xFF10B981);
      case 'cycling':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF00D9FF);
    }
  }

  String _workoutTitle(Map<String, dynamic> workout) {
    if (workout['name'] != null) return workout['name'];
    return _categoryLabel(workout['type'] ?? '');
  }

  String _workoutSubtitle(Map<String, dynamic> workout) {
    final distance = (workout['distance'] as num?)?.toDouble() ?? 0.0;
    final minutes = ((workout['durationSeconds'] as num?)?.toInt() ?? 0) ~/ 60;
    return '${distance.toStringAsFixed(2)} км • $minutes ${tr('мин', 'мин')}';
  }

  List<Map<String, dynamic>> get _filteredWorkouts {
    if (_selectedCategory == 'all') return _workouts;
    return _workouts.where((w) => w['type'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1419),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('Жаттығулар', 'Тренировки'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2130),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    for (final cat in _categories) ...[
                      _buildCategoryChip(cat),
                      if (cat != _categories.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Жылдам бастау', 'Быстрый старт'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickStartCard(context),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('Соңғы жаттығулар', 'Последние тренировки'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      tr('Барлығын көру', 'Смотреть все'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: _loading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
                      ),
                    )
                  : _error != null
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _loadWorkouts,
                                  child: Text(
                                    tr('Қайталау', 'Повторить'),
                                    style: const TextStyle(color: Color(0xFF00D9FF)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filteredWorkouts.isEmpty
                          ? SliverToBoxAdapter(
                              child: Text(
                                tr('Жаттығулар жоқ', 'Нет тренировок'),
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final workout = _filteredWorkouts[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildWorkoutCard(context, workout),
                                  );
                                },
                                childCount: _filteredWorkouts.length,
                              ),
                            ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String key) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = key);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
                )
              : null,
          color: isSelected ? null : const Color(0xFF1C2130),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _categoryLabel(key),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStartCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_filled, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Жаттығуды бастау', 'Начать тренировку'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('GPS арқылы трекинг', 'Трекинг через GPS'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              _showWorkoutTypePicker(context);
              HapticFeedback.mediumImpact();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  tr('Бастау', 'Начать'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Map<String, dynamic> workout) {
    final type = workout['type'] ?? '';
    final title = _workoutTitle(workout);
    final subtitle = _workoutSubtitle(workout);
    final calories = (workout['calories'] as num?)?.toInt() ?? 0;
    final color = _getWorkoutColor(type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getWorkoutIcon(type), color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          Text(
            '$calories ${tr('ккал', 'ккал')}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ PAINTER ============

class CircularProgressPainter extends CustomPainter {
  final double progress;

  CircularProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFF2A3142)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 7, bgPaint);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFFA500)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/localization/app_lang.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Пайдаланушы';
  String _userEmail = 'user@example.com';
  int _totalWorkouts = 0;
  double _totalDistance = 0.0;
  int _totalCalories = 0;
  int _totalTime = 0;
  bool _isLoading = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00D9FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _validatePassword(String password) {
    if (password.length < 6) return tr('Кемінде 6 таңба', 'Минимум 6 символов');
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return tr('Бас әріп керек', 'Нужна заглавная буква');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return tr('Кіші әріп керек', 'Нужна строчная буква');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) return tr('Сан керек', 'Нужна цифра');
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return tr('Арнайы таңба керек', 'Нужен спец. символ');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _userName = prefs.getString('user_name') ?? tr('Пайдаланушы', 'Пользователь');
        _userEmail = prefs.getString('user_email') ?? 'user@example.com';
      });

      if (_userEmail.isNotEmpty && _userEmail != 'user@example.com') {
        final userResp = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/users?email=$_userEmail'),
        );
        if (userResp.statusCode == 200) {
          final data = json.decode(userResp.body);
          final name = data['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            await prefs.setString('user_name', name);
            if (mounted) {
              setState(() => _userName = name);
            }
          }
        }
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/workouts?email=$_userEmail'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> workouts = json.decode(response.body);

        int totalWorkouts = workouts.length;
        double totalDistance = 0.0;
        int totalCalories = 0;
        int totalTime = 0;

        for (var workout in workouts) {
          totalDistance += (workout['distance'] as num).toDouble();
          totalCalories += (workout['calories'] as num).toInt();
          totalTime += (workout['durationSeconds'] as num).toInt();
        }

        setState(() {
          _totalWorkouts = totalWorkouts;
          _totalDistance = totalDistance;
          _totalCalories = totalCalories;
          _totalTime = totalTime;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Ошибка загрузки: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return appLang.value == 'ru'
          ? '${hours}ч ${minutes}м'
          : '${hours}сағ ${minutes}мин';
    }
    return appLang.value == 'ru' ? '${minutes}м' : '${minutes}мин';
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr('Профильді өңдеу', 'Редактировать профиль'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: tr('Аты', 'Имя'),
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              tr('Бас тарту', 'Отмена'),
              style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', nameController.text);
              await prefs.setString('user_email', emailController.text);
              Navigator.pop(context, true);
            },
            child: Text(
              tr('Сақтау', 'Сохранить'),
              style: const TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _userName = nameController.text;
        _userEmail = emailController.text;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C2130),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              tr('Құпиясөзді өзгерту', 'Изменить пароль'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: tr('Қазіргі құпиясөз', 'Текущий пароль'),
                    labelStyle: const TextStyle(color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: tr('Жаңа құпиясөз', 'Новый пароль'),
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: tr('Құпиясөзді растаңыз', 'Подтвердите пароль'),
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('Бас тарту', 'Отмена'), style: const TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () async {
                  final current = currentController.text.trim();
                  final next = newController.text.trim();
                  final confirm = confirmController.text.trim();

                  if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                    _showMessage(tr('Барлық жолдарды толтырыңыз', 'Заполните все поля'));
                    return;
                  }
                  if (next != confirm) {
                    _showMessage(tr('Құпиясөздер сәйкес емес', 'Пароли не совпадают'));
                    return;
                  }
                  final passError = _validatePassword(next);
                  if (passError != null) {
                    _showMessage(passError);
                    return;
                  }

                  final prefs = await SharedPreferences.getInstance();
                  final email = prefs.getString('user_email') ?? _userEmail;
                  if (email.isEmpty || email == 'user@example.com') {
                    _showMessage(tr('Пайдаланушы жоқ', 'Пользователь не найден'));
                    return;
                  }

                  try {
                    final response = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/change_password'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'email': email,
                        'currentPassword': current,
                        'newPassword': next,
                      }),
                    );
                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      _showMessage(tr('Құпиясөз өзгертілді', 'Пароль изменён'));
                    } else {
                      _showMessage(response.body);
                    }
                  } catch (_) {
                    _showMessage(tr('Серверге қосылу қатесі', 'Ошибка подключения к серверу'));
                  }
                },
                child: Text(
                  tr('Сақтау', 'Сохранить'),
                  style: const TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF0F1419),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0F1419),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Парақша', 'Профиль'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _buildLangChip('kk', 'Қазақша'),
                  const SizedBox(width: 8),
                  _buildLangChip('ru', 'Русский'),
                  const Spacer(),
                  _buildLogoutButton(),
                ],
              ),

              const SizedBox(height: 32),

              // Карточка профиля
              GestureDetector(
                onTap: _editProfile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              tr('Өңдеу', 'Редактировать'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Статистика
              Text(
                tr('Жалпы статистика', 'Общая статистика'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _changePassword,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2130),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.35), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D9FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Color(0xFF00D9FF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('Құпиясөзді өзгерту', 'Изменить пароль'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      tr('Жаттығулар', 'Тренировок'),
                      '$_totalWorkouts',
                      Icons.fitness_center_rounded,
                      const Color(0xFF00D9FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      tr('Уақыт', 'Время'),
                      _formatTime(_totalTime),
                      Icons.timer_rounded,
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
                      tr('Қашықтық', 'Дистанция'),
                      '${_totalDistance.toStringAsFixed(1)} км',
                      Icons.route_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      tr('Калория', 'Калории'),
                      '$_totalCalories',
                      Icons.local_fire_department_rounded,
                      const Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Приколюхи
              Text(
                tr('Жетістіктер', 'Достижения'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              _buildAchievementCard(
                tr('🔥 От', '🔥 Огонёк'),
                tr('7 күн қатарынан жаттықты', 'Тренировался 7 дней подряд'),
                Colors.orange,
                isUnlocked: _totalWorkouts >= 7,
              ),
              const SizedBox(height: 12),
              _buildAchievementCard(
                tr('⚡ Найзағай', '⚡ Молния'),
                tr('10 км бір рет жүгірді', 'Пробежал 10 км за раз'),
                const Color(0xFFEAB308),
                isUnlocked: false,
              ),
              const SizedBox(height: 12),
              _buildAchievementCard(
                tr('💪 Күш', '💪 Качалка'),
                tr('1000 калория жақты', 'Сжёг 1000 калорий'),
                const Color(0xFF10B981),
                isUnlocked: _totalCalories >= 1000,
              ),
              const SizedBox(height: 12),
              _buildAchievementCard(
                tr('🏆 Чемпион', '🏆 Чемпион'),
                tr('50 жаттығу аяқтады', 'Завершил 50 тренировок'),
                const Color(0xFF7C3AED),
                isUnlocked: _totalWorkouts >= 50,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String lang, String label) {
    final isSelected = appLang.value == lang;
    return GestureDetector(
      onTap: () async {
        await setAppLang(lang);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D9FF) : const Color(0xFF1C2130),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('user_email');
        await prefs.remove('user_name');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2130),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          tr('Шығу', 'Выйти'),
          style: const TextStyle(
            color: Color(0xFFFF6B35),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(String title, String description, Color color, {bool isUnlocked = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(14),
        border: isUnlocked ? Border.all(color: color.withOpacity(0.5), width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? color.withOpacity(0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              title.split(' ')[0],
              style: TextStyle(
                fontSize: 24,
                color: isUnlocked ? color : Colors.white24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.substring(title.indexOf(' ') + 1),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked ? Colors.white : Colors.white38,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? Colors.white54 : Colors.white24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(Icons.check_circle_rounded, color: color, size: 24)
          else
            Icon(Icons.lock_rounded, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}

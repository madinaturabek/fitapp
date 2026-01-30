import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/localization/app_lang.dart';
import '../../../../../core/config/api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;

  static String get baseUrl => ApiConfig.baseUrl;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
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

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(tr('Барлық жолдарды толтырыңыз', 'Заполните все поля'));
      return;
    }

    if (!_isLogin && name.isEmpty) {
      _showError(tr('Атыңызды енгізіңіз', 'Введите имя'));
      return;
    }

    if (!_isLogin) {
      if (confirmPassword.isEmpty) {
        _showError(tr('Құпиясөзді растаңыз', 'Подтвердите пароль'));
        return;
      }
      if (password != confirmPassword) {
        _showError(tr('Құпиясөздер сәйкес емес', 'Пароли не совпадают'));
        return;
      }
      final passError = _validatePassword(password);
      if (passError != null) {
        _showError(passError);
        return;
      }
    }

    try {
      final response = await http.post(
        Uri.parse(_isLogin ? '$baseUrl/login' : '$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (!_isLogin) 'name': name,
        }),
      );

      if (response.statusCode == 200) {
        String? nameFromServer;
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['name'] is String) {
            nameFromServer = data['name'];
          }
        } catch (_) {}

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', email);
        if (nameFromServer != null && nameFromServer!.isNotEmpty) {
          await prefs.setString('user_name', nameFromServer!);
        } else if (!_isLogin && name.isNotEmpty) {
          await prefs.setString('user_name', name);
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showError(response.body);
      }
    } catch (e) {
      _showError(tr('Серверге қосылу қатесі', 'Ошибка подключения к серверу'));
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text.trim());
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C2130),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              tr('Құпиясөзді қалпына келтіру', 'Сброс пароля'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        _showError(tr('Email енгізіңіз', 'Введите email'));
                        return;
                      }
                      try {
                        final response = await http.post(
                          Uri.parse('$baseUrl/request_reset_code'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'email': email}),
                        );
                        if (response.statusCode == 200) {
                          _showError(tr('Код почтаға жіберілді', 'Код отправлен на почту'));
                        } else {
                          _showError(response.body);
                        }
                      } catch (_) {
                        _showError(tr('Серверге қосылу қатесі', 'Ошибка подключения к серверу'));
                      }
                    },
                    child: Text(
                      tr('Код жіберу', 'Отправить код'),
                      style: const TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                _buildTextField(
                  controller: codeController,
                  label: tr('Хаттағы код', 'Код из письма'),
                  icon: Icons.confirmation_number_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: newPasswordController,
                  label: tr('Жаңа құпиясөз', 'Новый пароль'),
                  icon: Icons.lock_rounded,
                  obscureText: obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        obscure = !obscure;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: confirmController,
                  label: tr('Құпиясөзді растаңыз', 'Подтвердите пароль'),
                  icon: Icons.lock_rounded,
                  obscureText: obscure,
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
                  final email = emailController.text.trim();
                  final code = codeController.text.trim();
                  final newPassword = newPasswordController.text.trim();
                  final confirm = confirmController.text.trim();

                  if (email.isEmpty || code.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
                    _showError(tr('Барлық жолдарды толтырыңыз', 'Заполните все поля'));
                    return;
                  }
                  if (newPassword != confirm) {
                    _showError(tr('Құпиясөздер сәйкес емес', 'Пароли не совпадают'));
                    return;
                  }
                  final passError = _validatePassword(newPassword);
                  if (passError != null) {
                    _showError(passError);
                    return;
                  }

                  try {
                    final response = await http.post(
                      Uri.parse('$baseUrl/reset_password'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'email': email,
                        'code': code,
                        'newPassword': newPassword,
                      }),
                    );
                    if (response.statusCode == 200) {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      _showError(tr('Құпиясөз жаңартылды', 'Пароль обновлен'));
                    } else {
                      _showError(response.body);
                    }
                  } catch (_) {
                    _showError(tr('Серверге қосылу қатесі', 'Ошибка подключения к серверу'));
                  }
                },
                child: Text(
                  tr('Қалпына келтіру', 'Сбросить'),
                  style: const TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                _isLogin ? tr('Кіру', 'Вход') : tr('Тіркелу', 'Регистрация'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? tr('Аккаунтыңызға кіріңіз', 'Войдите в свой аккаунт')
                    : tr('Жаңа аккаунт жасаңыз', 'Создайте новый аккаунт'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 40),

              if (!_isLogin) ...[
                _buildTextField(
                  controller: _nameController,
                  label: tr('Аты', 'Имя'),
                  icon: Icons.person_rounded,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),
              ],

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _passwordController,
                label: tr('Құпиясөз', 'Пароль'),
                icon: Icons.lock_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              if (!_isLogin) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: tr('Құпиясөзді растаңыз', 'Подтвердите пароль'),
                  icon: Icons.lock_rounded,
                  obscureText: _obscurePassword,
                ),
              ],

              const SizedBox(height: 32),

              if (_isLogin) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      tr('Құпиясөзді ұмыттыңыз ба?', 'Забыли пароль?'),
                      style: const TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _handleAuth();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                        const Color(0xFF00D9FF).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isLogin
                          ? tr('Кіру', 'Войти')
                          : tr('Тіркелу', 'Зарегистрироваться'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: RichText(
                    text: TextSpan(
                      text: _isLogin
                          ? tr('Аккаунт жоқ па? ', 'Нет аккаунта? ')
                          : tr('Аккаунтыңыз бар ма? ', 'Уже есть аккаунт? '),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                      children: [
                        TextSpan(
                          text:
                        _isLogin ? tr('Тіркелу', 'Регистрация') : tr('Кіру', 'Войти'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00D9FF),
                        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2130),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

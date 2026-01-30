import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/workout/presentation/pages/home_page.dart';
import 'features/workout/presentation/pages/tracking_page.dart';
import 'features/workout/presentation/pages/auth/login_page.dart';
import 'core/localization/app_lang.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAppLang();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, _, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fitness App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'SF Pro',
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => const MainScreen(),
            '/tracking': (context) => const TrackingPage(),
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: Center(
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
    );
  }
}

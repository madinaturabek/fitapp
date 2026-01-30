import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_lang.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/onboarding_1.jpg',
      titleKk: 'Денсаулық\nмақсатымен\nбастаңыз',
      titleRu: 'Начните путь\nк целям\nздоровья',
      descriptionKk: 'Жаттығу\nұзақтығы',
      descriptionRu: 'Длительность\nтренировки',
      heartRateKk: 'Орташа\nжүрек соғысы',
      heartRateRu: 'Средний\nпульс',
    ),
    OnboardingData(
      image: 'assets/onboarding_2.jpg',
      titleKk: 'Күн сайын\nпрогресті\nбақылаңыз',
      titleRu: 'Следите за\nпрогрессом\nежедневно',
      descriptionKk: 'Калория\nжанып жатыр',
      descriptionRu: 'Сожженные\nкалории',
      heartRateKk: 'Макс\nжүрек соғысы',
      heartRateRu: 'Макс\nпульс',
    ),
    OnboardingData(
      image: 'assets/onboarding_3.jpg',
      titleKk: 'Фитнес\nмақсатқа\nжетыңыз',
      titleRu: 'Достигайте\nфитнес\nцелей',
      descriptionKk: 'Күндік\nқадам',
      descriptionRu: 'Шаги\nза день',
      heartRateKk: 'Белсенді\nуақыт',
      heartRateRu: 'Активное\nвремя',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Gradient
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Skip Button
          Positioned(
            top: 60,
            right: 24,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  tr('Өткізу', 'Пропустить'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Get Started Button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                      HapticFeedback.mediumImpact();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? tr('Келесі', 'Далее')
                              : tr('Бастау', 'Начать'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
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
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background (заглушка вместо изображения)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1f3a),
                Color(0xFF0d111d),
              ],
            ),
          ),
        ),

        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 120),

              // Heart Rate Graph (Заглушка)
              Container(
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: CustomPaint(
                  painter: HeartRateGraphPainter(),
                ),
              ),

              const SizedBox(height: 24),

              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(data.descriptionKk, data.descriptionRu),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(data.heartRateKk, data.heartRateRu),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Title
              Text(
                tr(data.titleKk, data.titleRu),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String image;
  final String titleKk;
  final String titleRu;
  final String descriptionKk;
  final String descriptionRu;
  final String heartRateKk;
  final String heartRateRu;

  OnboardingData({
    required this.image,
    required this.titleKk,
    required this.titleRu,
    required this.descriptionKk,
    required this.descriptionRu,
    required this.heartRateKk,
    required this.heartRateRu,
  });
}

class HeartRateGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i += 20) {
      path.lineTo(i, size.height * 0.3);
      path.lineTo(i + 10, size.height * 0.7);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

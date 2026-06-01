import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Bienvenue',
      'subtitle':
          'Découvre le meilleur jeu de cartes à prendre pour tes soirées entre amis.',
    },
    {
      'title': 'Distribue',
      'subtitle':
          'Pose des questions, distribue des pénalités et maîtrise l\'art du bluff.',
    },
    {
      'title': 'Pouvoirs',
      'subtitle':
          'Utilise des super-pouvoirs uniques pour renverser la partie !',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.goNamed('auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF6B45CC), // Violet principal de la maquette
      body: Stack(
        children: [
          // 1. Background Pattern (Grid/Dots)
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),

          // 2. Floating floating elements (Background)
          _buildFloatingElement('🃏', top: 100, left: 40, rotation: -0.2),
          _buildFloatingElement('🍻', top: 250, right: 50, rotation: 0.15),
          _buildFloatingElement('🏆', bottom: 150, left: 60, rotation: -0.1),
          _buildFloatingElement('🎲', bottom: 300, right: 40, rotation: 0.3),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _pages[index]['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate(key: ValueKey(index))
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.3),
                            const SizedBox(height: 16),
                            Text(
                              _pages[index]['subtitle']!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate(key: ValueKey('sub_$index'))
                                .fadeIn(delay: 200.ms, duration: 400.ms)
                                .slideY(begin: 0.3),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 4. Page Indicators & Button
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 48, left: 24, right: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => _buildDot(index),
                        ),
                      ),
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentPage == _pages.length - 1
                            ? ElevatedButton(
                                onPressed: _completeOnboarding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6B45CC),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 48, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Commencer',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ).animate().scale(curve: Curves.elasticOut)
                            : TextButton(
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  'Suivant',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
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
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 8,
      width: _currentPage == index ? 8 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFloatingElement(String emoji,
      {double? top,
      double? bottom,
      double? left,
      double? right,
      double rotation = 0}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            emoji,
            style:
                TextStyle(fontSize: 40, color: Colors.white.withOpacity(0.9)),
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -10, end: 10, duration: const Duration(seconds: 3)),
    );
  }
}

/// Dessine une grille de petits points en fond
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _steps = const [
    _TutorialStep(
      emoji: '🏔️',
      title: 'Bienvenue dans La Pyramide !',
      description: 'Le jeu de cartes le plus fun entre amis.\nBluff, stratégie et éclats de rire garantis.',
      color: PyraTheme.primaryPurple,
    ),
    _TutorialStep(
      emoji: '🃏',
      title: 'Distribution',
      description: 'Chaque joueur reçoit des cartes secrètes.\nMémorise bien les tiennes !',
      color: PyraTheme.primaryCyan,
    ),
    _TutorialStep(
      emoji: '🎭',
      title: 'Bluff ou Vérité',
      description: 'Quand une carte est révélée sur la pyramide,\nassigne des pénalités — même si tu bluffes !',
      color: PyraTheme.primaryPink,
    ),
    _TutorialStep(
      emoji: '🚨',
      title: 'Anti-Bluff',
      description: 'Tu penses qu\'on te ment ? Appelle le bluff !\nSi tu as raison, les pénalités sont doublées pour le menteur.',
      color: PyraTheme.primaryOrange,
    ),
    _TutorialStep(
      emoji: '🎮',
      title: '3 façons de jouer',
      description: '🥤 Soirée — pénalités classiques\n⭐ Points — compétitif sans alcool\n💪 Gages — défis physiques et fun',
      color: PyraTheme.primaryYellow,
    ),
  ];

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    if (mounted) context.goNamed('home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _steps.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _completeTutorial,
                      child: const Text('Passer',
                          style: TextStyle(color: Colors.white38)),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _steps.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return _buildPage(step, index);
                    },
                  ),
                ),

                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    final isActive = i == _currentPage;
                    return AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _steps[_currentPage].color
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // Action button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: PulsarButton(
                    text: isLast ? 'C\'est parti !' : 'Suivant',
                    gradient: LinearGradient(colors: [
                      _steps[_currentPage].color,
                      _steps[_currentPage].color.withValues(alpha: 0.7),
                    ]),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (isLast) {
                        _completeTutorial();
                      } else {
                        _pageController.nextPage(
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_TutorialStep step, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated circle with emoji
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                step.color.withValues(alpha: 0.2),
                step.color.withValues(alpha: 0.05),
                Colors.transparent,
              ]),
              border: Border.all(
                  color: step.color.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(step.emoji, style: const TextStyle(fontSize: 64)),
            ),
          )
              .animate(key: ValueKey('emoji_$index'))
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(),

          const SizedBox(height: 40),

          Text(
            step.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ).animate(key: ValueKey('title_$index')).fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          Text(
            step.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate(key: ValueKey('desc_$index')).fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _TutorialStep {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _TutorialStep({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}

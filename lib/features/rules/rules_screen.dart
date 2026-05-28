import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _rules = [
    {
      'emoji': '🔺',
      'title': 'La Pyramide',
      'content': 'Les cartes sont disposées en pyramide face cachée. La base comporte le plus de cartes et vaut 1 gorgée. Le sommet comporte 1 carte et vaut autant de gorgées que de rangées.',
    },
    {
      'emoji': '🃏',
      'title': 'Distribution',
      'content': 'Chaque joueur reçoit 4 cartes face cachée. Ces cartes peuvent être utilisées pour envoyer des gorgées aux autres joueurs.',
    },
    {
      'emoji': '🔄',
      'title': 'Déroulement',
      'content': 'On retourne les cartes de la pyramide rangée par rangée. Quand une carte est retournée, tout joueur qui prétend avoir la même valeur en main peut l\'envoyer à quelqu\'un.',
    },
    {
      'emoji': '😈',
      'title': 'Le Bluff',
      'content': 'Tu peux poser une carte même si tu ne l\'as pas ! C\'est du bluff. La personne ciblée peut te "challenger". Si tu bluffais, tu bois le double. Sinon, elle boit le double.',
    },
    {
      'emoji': '🏆',
      'title': 'Fin de partie',
      'content': 'La partie se termine quand toutes les cartes ont été retournées. Le classement final affiche qui a bu le plus et qui est le meilleur bluffeur !',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _rules.length - 1) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeOutCubic);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => context.pop(),
                      ),
                      const Text('Tutoriel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 48), // Pour centrer le titre
                    ],
                  ),
                ),
                
                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _rules.length,
                    itemBuilder: (context, index) {
                      final rule = _rules[index];
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                            borderRadius: BorderRadius.circular(32),
                            innerGlow: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(rule['emoji']!, style: const TextStyle(fontSize: 80))
                                    .animate(target: _currentPage == index ? 1 : 0)
                                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 800.ms),
                                const SizedBox(height: 32),
                                Text(
                                  rule['title']!,
                                  style: const TextStyle(color: PyraTheme.primaryYellow, fontSize: 28, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ).animate(target: _currentPage == index ? 1 : 0).fadeIn(delay: 200.ms).slideY(begin: 0.2),
                                const SizedBox(height: 24),
                                Text(
                                  rule['content']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                                  textAlign: TextAlign.center,
                                ).animate(target: _currentPage == index ? 1 : 0).fadeIn(delay: 400.ms).slideY(begin: 0.2),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Indicators & Next Button
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _rules.length,
                          (index) => AnimatedContainer(
                            duration: 300.ms,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? PyraTheme.primaryCyan : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      PulsarButton(
                        text: _currentPage == _rules.length - 1 ? "C'est parti !" : "Suivant",
                        onPressed: _nextPage,
                        width: double.infinity,
                        icon: _currentPage == _rules.length - 1 ? Icons.check : Icons.arrow_forward_rounded,
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
}

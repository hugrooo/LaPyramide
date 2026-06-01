import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0F0817), // Couleur sombre comme sur la maquette
      body: SafeArea(
        child: Column(
          children: [
            // Header: Close | Title | Settings
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Icon(Icons.settings, color: Colors.white),
                ],
              ),
            ),

            // Earn badge
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: PyraTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'EN DÉVELOPPEMENT',
                style: TextStyle(
                  color: PyraTheme.primaryOrange,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Main Content Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF3F196B), // Purple clair
                      Color(0xFF1E0A3C), // Purple sombre
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // 3D Image
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/coming_soon_trophy.png',
                            fit: BoxFit.contain,
                          ).animate().scale(
                              delay: 200.ms,
                              duration: 600.ms,
                              curve: Curves.easeOutBack),
                        ],
                      ),
                    ),

                    // Texts
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const Text(
                            'QUELQUE CHOSE D\'INTÉRESSANT',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
                          const SizedBox(height: 8),
                          const Text(
                            'ARRIVE BIENTÔT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.5),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Notify Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48.0),
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Tu seras averti dès que ce sera prêt !')),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF986D8E), // Couleur mauve sourde
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'M\'avertir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 800.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

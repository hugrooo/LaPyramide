import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../auth/auth_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _submitProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      try {
        await FirebaseDatabase.instance.ref('users/${user.uid}').update({
          'name': name,
          'searchName': name.toLowerCase(),
        });

        if (mounted) {
          context.goNamed('home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
                decoration:
                    const BoxDecoration(gradient: PyraTheme.mainGradient)),
          ),
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlow(PyraTheme.primaryPink.withOpacity(0.3)),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _buildGlow(PyraTheme.primaryCyan.withOpacity(0.3)),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSlide(
                        icon: Icons.celebration_rounded,
                        color: PyraTheme.primaryPink,
                        title: 'Bienvenue !',
                        description:
                            'Prépare-toi à passer des soirées mémorables avec tes amis sur La Pyramide.',
                      ),
                      _buildSlide(
                        icon: Icons.trending_up_rounded,
                        color: PyraTheme.primaryCyan,
                        title: 'Progression',
                        description:
                            'Joue des parties, gagne de l\'XP et des pièces pour débloquer des récompenses dans la Boutique.',
                      ),
                      _buildProfileSetupSlide(),
                    ],
                  ),
                ),

                // Dots indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? PyraTheme.primaryPink
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                      color: PyraTheme.primaryPink
                                          .withOpacity(0.5),
                                      blurRadius: 8)
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                // Bottom Button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: _currentPage < 2
                        ? PulsarButton(
                            text: 'Suivant',
                            gradient: PyraTheme.cyanGradient,
                            onPressed: _nextPage,
                          )
                        : _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: PyraTheme.primaryPink))
                            : PulsarButton(
                                text: 'C\'est parti !',
                                gradient: PyraTheme.festiveGradient,
                                onPressed: _submitProfile,
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.3), blurRadius: 30)
                      ],
                    ),
                    child: Icon(icon, size: 80, color: color),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 48),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildProfileSetupSlide() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PyraTheme.primaryYellow.withOpacity(0.1),
                      border: Border.all(
                          color: PyraTheme.primaryYellow.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: PyraTheme.primaryYellow.withOpacity(0.3),
                            blurRadius: 30)
                      ],
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        size: 80, color: PyraTheme.primaryYellow),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 48),
                  const Text(
                    'Choisis ton pseudo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  Text(
                    'Ce sera ton nom dans les classements et lors de tes parties.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 32),
                  GlassContainer(
                    blur: 10,
                    opacity: 0.1,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '@Pseudo',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submitProfile(),
                    ),
                  ).animate().fadeIn(delay: 600.ms).scale(),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

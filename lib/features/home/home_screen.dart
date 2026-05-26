import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/neo_badge.dart';
import '../profile/user_profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;
    
    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;
    final coins = profile?.coins ?? 0;
    final diamonds = profile?.diamonds ?? 0;

    final numberFormat = NumberFormat('#,###', 'fr_FR');
    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          // ── Fond : gradient très profond ──────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: PyraTheme.mainGradient,
              ),
            ),
          ),

          // ── Bokeh et effets de lumière (Neon Glows) ───────────
          Positioned(
            top: -50,
            left: -100,
            child: _GlowOrb(color: PyraTheme.primaryCyan.withOpacity(0.15), size: 400),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 4.seconds, begin: const Offset(1,1), end: const Offset(1.1,1.1)),
          
          Positioned(
            bottom: 50,
            right: -100,
            child: _GlowOrb(color: PyraTheme.primaryPurple.withOpacity(0.15), size: 500),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(duration: 5.seconds, begin: 0, end: -0.1),

          // ── Contenu principal ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top Bar (HUD : Avatar, Level, Monnaies) ─────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil & Level (Style Image 2)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.pushNamed('level');
                        },
                        child: GlassContainer(
                          innerGlow: true,
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: PyraTheme.bgSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Center(child: Text('😎', style: TextStyle(fontSize: 28))),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Niv. $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                      const SizedBox(width: 8),
                                      NeoBadge(text: '$xp XP', gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]), fontSize: 10, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _miniDot(active: xp >= 10),
                                      _miniDot(active: xp >= 25),
                                      _miniDot(active: xp >= 50),
                                      _miniDot(active: xp >= 75),
                                      _miniDot(active: xp >= 100),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

                      // Currencies & Icons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              children: [
                                Text(numberFormat.format(diamonds), style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 16)),
                                const SizedBox(width: 8),
                                const Icon(Icons.diamond_rounded, color: PyraTheme.primaryPurple, size: 20),
                              ],
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: 0.2),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.pushNamed('store');
                            },
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                children: [
                                  Text(numberFormat.format(coins), style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 16)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.monetization_on_rounded, color: PyraTheme.primaryYellow, size: 20),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: 0.2),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Bannières d'action & Play Button ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Quests Banner
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: PyraTheme.bgCard,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Row(
                                children: [
                                  Icon(Icons.hourglass_empty, color: PyraTheme.primaryPurple),
                                  SizedBox(width: 8),
                                  Text('Bientôt disponible', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                              content: Text(
                                "Le système de quêtes quotidiennes sera ajouté dans une prochaine mise à jour ! Reviens plus tard pour gagner plus de diamants.",
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('Fermer', style: TextStyle(color: PyraTheme.primaryCyan)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: GlassContainer(
                          innerGlow: true,
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: PyraTheme.cyanGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: PyraTheme.glowCyan,
                                ),
                                child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Quêtes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                        const SizedBox(width: 8),
                                        const NeoBadge(text: 'NOUVEAU', fontSize: 9, padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Participe aux tirages !', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 20),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.2),

                      const SizedBox(height: 24),

                      // Bouton Jouer
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          context.pushNamed('onlineLobby');
                        },
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: PyraTheme.festiveGradient,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: PyraTheme.glowPink,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'JOUER EN LIGNE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1,1), end: const Offset(1.03, 1.03), duration: 1.5.seconds, curve: Curves.easeInOut)
                        .shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.3), angle: 45),
                      ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: 120),
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

  Widget _miniDot({required bool active}) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 14,
      height: 4,
      decoration: BoxDecoration(
        gradient: active ? PyraTheme.purplePinkGradient : null,
        color: active ? null : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(2),
        boxShadow: active ? PyraTheme.glowPurple.map((s) => BoxShadow(color: s.color, blurRadius: 4)).toList() : [],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size / 1.5,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

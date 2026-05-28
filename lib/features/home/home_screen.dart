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
import 'widgets/play_card_3d.dart';
import 'widgets/particle_background.dart';

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
    
    final streak = profile?.streak ?? 0;

    final numberFormat = NumberFormat('#,###', 'fr_FR');
    
    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          // ── Fond : gradient profond ──────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: PyraTheme.mainGradient,
              ),
            ),
          ),

          // ── Particules Dynamiques ──────────────────────
          const Positioned.fill(
            child: ParticleBackground(),
          ),

          // ── Bokeh (Neon Glows avec Parallax léger simulé) ───────────
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
                // ── Nouveau HUD : Barre Fine Unifiée ─────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Avatar + Streak
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.pushNamed('level');
                              },
                              child: Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(child: Text(profile?.emoji ?? '😎', style: const TextStyle(fontSize: 20))),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: -2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: PyraTheme.primaryCyan,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('Lvl $level', style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Streak (Flamme)
                                  Row(
                                    children: [
                                      const Text('🔥', style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 4),
                                      Text('$streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Currencies
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.pushNamed('store');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(numberFormat.format(coins), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.monetization_on_rounded, color: PyraTheme.primaryYellow, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(numberFormat.format(diamonds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.diamond_rounded, color: PyraTheme.primaryPurple, size: 18),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Barre de progression XP Linéaire
                        Row(
                          children: [
                            const Text('XP', style: TextStyle(color: PyraTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (xp % 100) / 100, // Exemple de progression
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(PyraTheme.primaryCyan),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${xp % 100} / 100', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

                // ── Carrousel d'événements (News/Quests) ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pushNamed('quests');
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PyraTheme.primaryPink.withOpacity(0.3)),
                      innerGlow: true,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PyraTheme.primaryPink.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.card_giftcard_rounded, color: PyraTheme.primaryPink, size: 20),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 1.seconds),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Coffre Quotidien Disponible', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    SizedBox(width: 8),
                                    NeoBadge(text: 'RÉCUPÉRER', fontSize: 8, gradient: PyraTheme.festiveGradient, padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text('Ouvre-le avant minuit !', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2),

                const Spacer(),

                // ── Carte 3D Centrale (Bouton Jouer) ──────────────────────
                PlayCard3D(
                  onTap: () {
                    context.pushNamed('onlineLobby');
                  },
                ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOutBack).scale(begin: const Offset(0.8, 0.8)),

                const Spacer(),
                const SizedBox(height: 100), // Espace pour la barre de navigation
              ],
            ),
          ),
        ],
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/card_3d_showcase.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/neo_badge.dart';
import '../../shared/widgets/avatar_with_border.dart';
import 'user_profile_provider.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String uid;

  const PublicProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(uid));

    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          const AnimatedBackground(),

          // ── Néon glow coins ──────────────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(
                    color: PyraTheme.primaryCyan.withOpacity(0.12),
                    blurRadius: 200,
                    spreadRadius: 40)
              ]),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(
                    color: PyraTheme.primaryPink.withOpacity(0.10),
                    blurRadius: 150,
                    spreadRadius: 30)
              ]),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ─────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Expanded(
                        child: Text('Profil Public',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 40), // Pour balancer la flèche de retour
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // ── Corps scrollable ─────────────────────────────────────
                Expanded(
                  child: profileAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: PyraTheme.primaryCyan),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Erreur: $error', style: const TextStyle(color: Colors.redAccent)),
                    ),
                    data: (profile) {
                      if (profile == null) {
                        return const Center(
                          child: Text('Utilisateur introuvable', style: TextStyle(color: Colors.white54)),
                        );
                      }

                      final level = profile.level;
                      final xp = profile.xp;
                      final xpNeededForNext = level * 100;
                      final progress = (xp / xpNeededForNext).clamp(0.0, 1.0);
                      final numberFormat = NumberFormat('#,###', 'fr_FR');
                      final displayTitle = profile.activeTitle.isNotEmpty ? profile.activeTitle : 'Novice 🐣';

                      final backDisplayName = switch (profile.activeCardBack) {
                        'neon' => 'Néon Cyberpunk ⚡',
                        'pirate' => 'Pirate Doré ☠️',
                        'retro' => 'Rétro Pixel 👾',
                        'girl' => 'Girly Rose 🎀',
                        'beta' => 'Testeur Bêta 🚀',
                        'pharaoh' => 'Pharaon 👁️',
                        'casino' => 'Casino Royal 🎲',
                        'toxic' => 'Toxique 🧪',
                        'clubbing' => 'Clubbing 🪩',
                        'demon' => 'Démoniaque 😈',
                        'galaxy' => 'Galaxy 🌌',
                        'vip' => 'VIP Diamant 💎',
                        _ => 'Classique Rouge 🟥',
                      };

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // ── Avatar + Halo ──────────────────────────────────
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Halo externe pulsant
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: PyraTheme.primaryCyan
                                              .withOpacity(0.25),
                                          blurRadius: 50,
                                          spreadRadius: 15),
                                      BoxShadow(
                                          color: PyraTheme.primaryPink
                                              .withOpacity(0.15),
                                          blurRadius: 70,
                                          spreadRadius: 25),
                                    ],
                                  ),
                                )
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .scale(
                                        duration: 2500.ms,
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.08, 1.08),
                                        curve: Curves.easeInOut),

                                // Anneau XP
                                SizedBox(
                                  width: 164,
                                  height: 164,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 7,
                                    backgroundColor: Colors.white.withOpacity(0.05),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                        PyraTheme.primaryCyan),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ).animate().custom(
                                      duration: 1200.ms,
                                      curve: Curves.easeOutCubic,
                                      builder: (_, v, child) =>
                                          child!, // Juste pour le trigger
                                    ),

                                // Avatar (non-cliquable)
                                Container(
                                  width: 136,
                                  height: 136,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: PyraTheme.bgSurface,
                                    border: Border.all(
                                      color:
                                          PyraTheme.primaryCyan.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: AvatarWithBorder(
                                      emoji: profile.emoji,
                                      size: 56,
                                      borderType: profile.selectedBorder,
                                    ),
                                  ),
                                ),

                                // Badge niveau
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      gradient: PyraTheme.cyanGradient,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: PyraTheme.glowCyan,
                                    ),
                                    child: Text(
                                      'Niv. $level',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .scale(duration: 700.ms, curve: Curves.easeOutBack),

                          const SizedBox(height: 20),

                          // ── Nom + Titre ────────────────────────────────────
                          Column(
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: PyraTheme.purplePinkGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  displayTitle.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                          const SizedBox(height: 32),

                          // ── Statistiques ───────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Parties',
                                  value: numberFormat.format(profile.gamesPlayed),
                                  icon: Icons.casino_rounded,
                                  color: PyraTheme.primaryPink,
                                  delay: 300,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Pénalités',
                                  value: numberFormat.format(profile.drinksGiven),
                                  icon: Icons.sports_score_rounded,
                                  color: PyraTheme.primaryCyan,
                                  delay: 400,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Coups de\nBluff',
                                  value: numberFormat.format(profile.bluffWins),
                                  icon: Icons.visibility_off_rounded,
                                  color: PyraTheme.primaryPurple,
                                  delay: 500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // ── Équipements ────────────────────────────────────
                          const Text(
                            'ÉQUIPEMENT ACTIF',
                            style: TextStyle(
                                color: PyraTheme.primaryCyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 2),
                          ).animate().fadeIn(delay: 600.ms),
                          const SizedBox(height: 12),

                          // Carte Card Back
                          GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Card3DShowcase(
                                  skinId: profile.activeCardBack,
                                  width: 48,
                                  height: 68,
                                  showControls: false,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dos de carte',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        backDisplayName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),
                        ],
                      );
                    },
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

// ── Widget Statistique ────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.2),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).scale(curve: Curves.easeOutBack);
  }
}

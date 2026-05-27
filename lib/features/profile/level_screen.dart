import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/neo_badge.dart';
import '../auth/auth_service.dart';
import 'user_profile_provider.dart';

class LevelScreen extends ConsumerWidget {
  const LevelScreen({super.key});

  // Logique pour obtenir un titre selon le niveau
  String _getTitleForLevel(int level) {
    if (level < 5) return 'Novice du Bluff';
    if (level < 10) return 'Initié de la Pyramide';
    if (level < 20) return 'Maître Distributeur';
    if (level < 50) return 'Seigneur des Cartes';
    return 'Le Pharaon';
  }

  // Icône associée au titre
  String _getIconForLevel(int level) {
    if (level < 5) return '🥚';
    if (level < 10) return '🎭';
    if (level < 20) return '🎴';
    if (level < 50) return '👑';
    return '👁️';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;

    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;
    
    final xpNeededForNext = level * 100;
    final progress = (xp / xpNeededForNext).clamp(0.0, 1.0);
    final numberFormat = NumberFormat('#,###', 'fr_FR');

    final title = _getTitleForLevel(level);
    final rankIcon = _getIconForLevel(level);

    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          const AnimatedBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ─────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Mon Profil',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Pour équilibrer le titre
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      // ── Entête Profil (Badge + Avatar) ─────────────────────
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Halo brillant derrière l'avatar
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: PyraTheme.primaryCyan.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                                  BoxShadow(color: PyraTheme.primaryPink.withOpacity(0.2), blurRadius: 60, spreadRadius: 20),
                                ],
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 2.seconds, begin: const Offset(1,1), end: const Offset(1.1,1.1)),

                            // Avatar et Anneau de Niveau
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                valueColor: const AlwaysStoppedAnimation<Color>(PyraTheme.primaryCyan),
                                strokeCap: StrokeCap.round,
                              ),
                            ),

                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: PyraTheme.bgSurface,
                                border: Border.all(color: Colors.white12, width: 2),
                              ),
                              child: Center(
                                child: Text(profile?.emoji ?? '😎', style: const TextStyle(fontSize: 64)),
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 24),

                      // ── Titre et Nom ─────────────────────
                      Column(
                        children: [
                          Text(
                            ref.watch(authStateChangesProvider).value?.displayName ?? 'Joueur Inconnu',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: PyraTheme.purplePinkGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: PyraTheme.glowPurple,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(rankIcon, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  title.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                      const SizedBox(height: 32),

                      // ── Détails XP ─────────────────────
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Progression (Niveau Actuel)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                NeoBadge(text: 'Niv. $level', gradient: PyraTheme.cyanGradient),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${numberFormat.format(xp)} XP', style: const TextStyle(color: PyraTheme.primaryCyan, fontSize: 20, fontWeight: FontWeight.w900)),
                                Text('/ ${numberFormat.format(xpNeededForNext)} XP', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation<Color>(PyraTheme.primaryCyan),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                      const SizedBox(height: 16),

                      // ── Statistiques de Jeu (Simulées) ─────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: GlassContainer(
                              padding: const EdgeInsets.all(20),
                              borderRadius: BorderRadius.circular(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.water_drop_rounded, color: PyraTheme.primaryCyan, size: 32),
                                  const SizedBox(height: 12),
                                  const Text('Gorgées Données', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                                  const SizedBox(height: 4),
                                  Text(numberFormat.format((level * 15) + 42), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GlassContainer(
                              padding: const EdgeInsets.all(20),
                              borderRadius: BorderRadius.circular(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: PyraTheme.primaryOrange, size: 32),
                                  const SizedBox(height: 12),
                                  const Text('Victoires au Bluff', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                                  const SizedBox(height: 4),
                                  Text(numberFormat.format(level * 3), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Récompense Prochain Niveau ─────────────────────
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: PyraTheme.primaryYellow.withOpacity(0.3)),
                        innerGlow: true,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PyraTheme.primaryYellow.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.card_giftcard_rounded, color: PyraTheme.primaryYellow, size: 28),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 1.seconds),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Récompense du Niv. ${level + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '+200 Pièces & +10 Diamants',
                                    style: TextStyle(color: PyraTheme.primaryYellow, fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: 40),
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

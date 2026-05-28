import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/neo_badge.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../auth/auth_service.dart';
import 'user_profile_provider.dart';

class LevelScreen extends ConsumerWidget {
  const LevelScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;

    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;
    final lastClaimedLevel = profile?.lastClaimedLevel ?? 1;
    final hasRewardToClaim = level > lastClaimedLevel;
    final rewardLevel = lastClaimedLevel + 1;
    
    final xpNeededForNext = level * 100;
    final progress = (xp / xpNeededForNext).clamp(0.0, 1.0);
    final numberFormat = NumberFormat('#,###', 'fr_FR');

    final String displayTitle = profile?.activeTitle ?? 'Novice 🐣';
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
                                Text(
                                  displayTitle.toUpperCase(),
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
                                  Text(numberFormat.format(profile?.drinksGiven ?? 0), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
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
                                  Text(numberFormat.format(profile?.bluffWins ?? 0), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Récompense Prochain Niveau ─────────────────────
                      if (hasRewardToClaim)
                        GestureDetector(
                          onTap: () async {
                            final user = ref.read(authServiceProvider).currentUser;
                            if (user == null) return;

                            HapticFeedback.mediumImpact();

                            await UserProfile.claimLevelReward(user.uid);

                            if (context.mounted) {
                              _showRewardSuccessDialog(context, 200, 10, rewardLevel);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFB8500).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
                                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                                     .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 800.ms),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Récompense du Niv. $rewardLevel DISPONIBLE !',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            '+200 Pièces & +10 Diamants',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black26,
                                                  offset: Offset(0, 2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                '🎁 RÉCUPÉRER MAINTENANT',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0,
                                                ),
                                              ).animate(onPlay: (c) => c.repeat(reverse: true))
                                               .fadeIn(duration: 1.seconds)
                                               .fadeOut(duration: 1.seconds),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                             .shimmer(
                               duration: 3.seconds,
                               color: Colors.white.withOpacity(0.4),
                               angle: 45,
                               blendMode: BlendMode.srcATop,
                             ),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                         .scale(
                           begin: const Offset(1, 1),
                           end: const Offset(1.03, 1.03),
                           duration: 2.seconds,
                           curve: Curves.easeInOut,
                         )
                      else
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          innerGlow: true,
                          child: Opacity(
                            opacity: 0.6,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_rounded, color: Colors.white54, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Récompense du Niv. ${level + 1}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '+200 Pièces & +10 Diamants',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Atteignez le niveau ${level + 1} pour débloquer',
                                        style: const TextStyle(color: PyraTheme.primaryYellow, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  void _showRewardSuccessDialog(BuildContext context, int coinsReward, int diamondsReward, int rewardLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PyraTheme.primaryYellow.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PyraTheme.primaryYellow.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: PyraTheme.primaryYellow,
                size: 48,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              'Niveau $rewardLevel Atteint !',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Félicitations ! Vous avez débloqué votre récompense de passage de niveau :',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: PyraTheme.primaryYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PyraTheme.primaryYellow.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '+$coinsReward',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.monetization_on_rounded, color: PyraTheme.primaryYellow, size: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: PyraTheme.primaryCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PyraTheme.primaryCyan.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '+$diamondsReward',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.diamond_rounded, color: PyraTheme.primaryCyan, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          PulsarButton(
            text: 'Génial !',
            paddingHorizontal: 24,
            width: 160,
            gradient: PyraTheme.festiveGradient,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
    );
  }
}

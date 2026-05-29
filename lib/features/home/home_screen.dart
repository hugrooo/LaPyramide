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
import '../notifications/push_notification_service.dart';
import 'widgets/play_card_3d.dart';
import 'widgets/particle_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Demande la permission pour les notifications (au premier lancement) et initialise l'écoute
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;
    
    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;
    final coins = profile?.coins ?? 0;
    final diamonds = profile?.diamonds ?? 0;
    final gamesPlayed = profile?.gamesPlayed ?? 0;

    final numberFormat = NumberFormat('#,###', 'fr_FR');

    // ── Calcul de l'état des quêtes ──────────────────────────────────────────
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int nextClaim = (profile?.lastDailyChestClaimed ?? 0) + 24 * 60 * 60 * 1000;
    final bool isChestAvailable = now >= nextClaim;

    // Vérifier si une quête est complète et non réclamée
    final quests = profile?.quests ?? {};
    const questTargets = {'bluff': 3, 'games': 1, 'shop': 1};
    bool hasQuestToCollect = false;
    bool hasAnyNewQuest = false;

    for (final entry in questTargets.entries) {
      final data = quests[entry.key];
      final progress = data?['progress'] as int? ?? 0;
      final claimed = data?['claimed'] as bool? ?? false;
      if (!claimed && progress >= entry.value) {
        hasQuestToCollect = true;
      }
      if (data == null) {
        hasAnyNewQuest = true;
      }
    }

    // Texte et badge dynamiques pour le panneau quêtes
    String questTitle;
    String? questSubtitle;
    Widget? questBadge;

    if (isChestAvailable || hasQuestToCollect) {
      questTitle = isChestAvailable ? 'Coffre Quotidien Disponible 🎁' : 'Récompense à récupérer !';
      questSubtitle = isChestAvailable ? 'Ouvre-le avant minuit !' : 'Une quête est terminée, réclame ta mise.';
      questBadge = const NeoBadge(
        text: 'RÉCUPÉRER',
        fontSize: 8,
        gradient: PyraTheme.festiveGradient,
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      );
    } else if (hasAnyNewQuest) {
      questTitle = 'Nouvelles Quêtes Disponibles';
      questSubtitle = 'De nouveaux défis t\'attendent !';
      questBadge = const NeoBadge(
        text: 'NOUVEAU',
        fontSize: 8,
        gradient: PyraTheme.purplePinkGradient,
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      );
    } else {
      questTitle = 'Défis & Quêtes';
      questSubtitle = 'Suis ta progression quotidienne';
      questBadge = null;
    }
    
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

          // ── Bokeh (Neon Glows) ─────────────────────────
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
                // ── HUD : Barre Unifiée CLIQUABLE → Profil ───────────────
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed('level');
                  },
                  child: Padding(
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
                              // Avatar + Parties jouées
                              Row(
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
                                  Row(
                                    children: [
                                      const Text('🎮', style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 4),
                                      Text('$gamesPlayed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ],
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
                          // Barre XP
                          Row(
                            children: [
                              const Text('XP', style: TextStyle(color: PyraTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (xp % 100) / 100,
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
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

                // ── Panneau Quêtes Dynamique ──────────────────────────────
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
                      border: Border.all(
                        color: (isChestAvailable || hasQuestToCollect)
                            ? PyraTheme.primaryPink.withOpacity(0.5)
                            : Colors.white.withOpacity(0.15),
                      ),
                      innerGlow: isChestAvailable || hasQuestToCollect,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isChestAvailable || hasQuestToCollect)
                                  ? PyraTheme.primaryPink.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isChestAvailable ? Icons.card_giftcard_rounded : Icons.checklist_rounded,
                              color: (isChestAvailable || hasQuestToCollect) ? PyraTheme.primaryPink : Colors.white54,
                              size: 20,
                            ),
                          ).animate(
                            onPlay: (c) {
                              if (isChestAvailable || hasQuestToCollect) c.repeat(reverse: true);
                            },
                          ).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 1.seconds),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        questTitle,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (questBadge != null) ...[
                                      const SizedBox(width: 8),
                                      questBadge,
                                    ],
                                  ],
                                ),
                                if (questSubtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    questSubtitle,
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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

                // ── Carte 3D Centrale (Bouton Jouer) ─────────────────────
                PlayCard3D(
                  onTap: () {
                    context.pushNamed('onlineLobby');
                  },
                ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOutBack).scale(begin: const Offset(0.8, 0.8)),

                const Spacer(),
                const SizedBox(height: 100),
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

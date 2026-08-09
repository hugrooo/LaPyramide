import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/neo_badge.dart';
import '../../shared/widgets/avatar_with_border.dart';
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
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
      _checkTutorial();
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('tutorial_completed') ?? false;
    if (!done && mounted) {
      context.pushNamed('tutorial');
    }
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
    final int nextClaim =
        (profile?.lastDailyChestClaimed ?? 0) + 24 * 60 * 60 * 1000;
    final bool isChestAvailable = now >= nextClaim;
    final hasClaimedBetaCard = profile?.cardBacks.contains('beta') ?? false;
    final hasClaimedBetaTitle = profile?.titles.contains('Pionnier de la Bêta 🚀') ?? false;
    final hasClaimedAllBetaGifts = hasClaimedBetaCard && hasClaimedBetaTitle;
    final int claimedBetaGiftsCount = (hasClaimedBetaCard ? 1 : 0) + (hasClaimedBetaTitle ? 1 : 0);

    // Texte et badge dynamiques pour le panneau de coffre
    String questTitle;
    String? questSubtitle;
    Widget? questBadge;

    if (isChestAvailable) {
      questTitle = 'Coffre Quotidien Disponible 🎁';
      questSubtitle = 'Ouvre-le avant minuit !';
      questBadge = const NeoBadge(
        text: 'RÉCUPÉRER',
        fontSize: 8,
        gradient: PyraTheme.festiveGradient,
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      );
    } else {
      questTitle = 'Coffre Quotidien';
      questSubtitle = 'Reviens demain pour ton prochain cadeau';
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
            child: _GlowOrb(
                color: PyraTheme.primaryCyan.withOpacity(0.15), size: 400),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              duration: 4.seconds,
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1)),

          Positioned(
            bottom: 50,
            right: -100,
            child: _GlowOrb(
                color: PyraTheme.primaryPurple.withOpacity(0.15), size: 500),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideY(duration: 5.seconds, begin: 0, end: -0.1),

          // ── Contenu principal ─────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 100,
              ),
              child: Column(
                children: [
                // ── HUD : Barre Unifiée CLIQUABLE → Profil ───────────────
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed('level');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                                  AvatarWithBorder(
                                    emoji: profile?.emoji ?? '😎',
                                    size: 40,
                                    borderType:
                                        profile?.selectedBorder ?? 'classic',
                                    showLevel: true,
                                    level: level,
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    children: [
                                      const Text('🎮',
                                          style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 4),
                                      Text('$gamesPlayed',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(numberFormat.format(coins),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14)),
                                          const SizedBox(width: 6),
                                          const Text('🪙', style: TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(numberFormat.format(diamonds),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14)),
                                        const SizedBox(width: 6),
                                        const Text('💎', style: TextStyle(fontSize: 16)),
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
                              const Text('XP',
                                  style: TextStyle(
                                      color: PyraTheme.primaryCyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (xp % 100) / 100,
                                    minHeight: 8,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            PyraTheme.primaryCyan),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${xp % 100} / 100',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

                // ── Panneau Quêtes Dynamique ──────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pushNamed('quests');
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isChestAvailable
                            ? PyraTheme.primaryPink.withOpacity(0.5)
                            : Colors.white.withOpacity(0.15),
                      ),
                      innerGlow: isChestAvailable,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isChestAvailable
                                  ? PyraTheme.primaryPink.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.card_giftcard_rounded,
                              color: isChestAvailable
                                  ? PyraTheme.primaryPink
                                  : Colors.white54,
                              size: 20,
                            ),
                          ).animate(
                            onPlay: (c) {
                              if (isChestAvailable) c.repeat(reverse: true);
                            },
                          ).scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 1.seconds),
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
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white30, size: 14),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2),

                // ── Annonce Cadeau Bêta ──────────────────────────────
                if (!hasClaimedAllBetaGifts)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.pushNamed('store', extra: {
                          'tab': 'cosmetics',
                          'scrollToBetaGifts': true,
                          'scrollToTitle': hasClaimedBetaCard && !hasClaimedBetaTitle,
                        });
                      },
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: PyraTheme.primaryYellow.withOpacity(0.5)),
                        innerGlow: true,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PyraTheme.primaryYellow.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded,
                                  color: PyraTheme.primaryYellow, size: 20),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.1, 1.1),
                                    duration: 1.seconds),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cadeaux de Bêta Testeur ($claimedBetaGiftsCount/2) 🎁',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Récupère tes récompenses gratuites !',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white30, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 700.ms).slideX(begin: -0.2),

                const SizedBox(height: 16),

                // ── PageView Cartes 3D ─────────────────────
                SizedBox(
                  height: 380,
                  child: PageView(
                    onPageChanged: (index) {
                      setState(() {
                        _currentCardIndex = index;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: PlayCard3D(
                            onTap: () {
                              context.pushNamed('onlineLobby');
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: PlayCard3D(
                            title: 'JEUX DE TABLE',
                            modeLabel: 'COMPAGNON',
                            statusText: 'Outils de jeu physique',
                            icon: Icons.casino_rounded,
                            statusIcon: Icons.casino_outlined,
                            statusIconColor: PyraTheme.primaryPurple,
                            buttonGradient: PyraTheme.purplePinkGradient,
                            glowBackColors: const [
                              PyraTheme.primaryPurple,
                              PyraTheme.primaryPink,
                            ],
                            onTap: () {
                              context.pushNamed('boardGames');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOutBack)
                    .scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (index) {
                    final isSelected = _currentCardIndex == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isSelected ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isSelected
                            ? PyraTheme.primaryCyan
                            : Colors.white.withOpacity(0.3),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _QuickAction(
                            icon: Icons.people_alt_rounded,
                            label: 'Amis',
                            color: PyraTheme.primaryCyan,
                            onTap: () => context.pushNamed('friends'),
                          ),
                          _QuickAction(
                            icon: Icons.extension_rounded,
                            label: 'Mini-Jeux',
                            color: PyraTheme.primaryPink,
                            onTap: () => context.pushNamed('minigames'),
                          ),
                          _QuickAction(
                            icon: Icons.groups_rounded,
                            label: 'Crews',
                            color: PyraTheme.primaryPurple,
                            onTap: () => context.pushNamed('crews'),
                          ),
                          _QuickAction(
                            icon: Icons.style_rounded,
                            label: 'Decks',
                            color: PyraTheme.primaryOrange,
                            onTap: () => context.pushNamed('customDecks'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _QuickAction(
                            icon: Icons.leaderboard_rounded,
                            label: 'Classement',
                            color: PyraTheme.primaryYellow,
                            onTap: () => context.pushNamed('leaderboard'),
                          ),
                          _QuickAction(
                            icon: Icons.bar_chart_rounded,
                            label: 'Stats',
                            color: PyraTheme.primaryGreen,
                            onTap: () => context.pushNamed('stats'),
                          ),
                          _QuickAction(
                            icon: Icons.military_tech_rounded,
                            label: 'Pass',
                            color: PyraTheme.primaryPink,
                            onTap: () => context.pushNamed('battlePass'),
                          ),
                          _QuickAction(
                            icon: Icons.visibility_rounded,
                            label: 'Regarder',
                            color: PyraTheme.primaryBlue,
                            onTap: () => _showSpectateDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 900.ms).slideY(begin: 0.2),
                const SizedBox(height: 24),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showSpectateDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: PyraTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Regarder une partie',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Entre le code de la room pour regarder en direct',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'CODE',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PyraTheme.primaryCyan),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Annuler',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        TextButton(
          onPressed: () {
            final code = controller.text.trim();
            if (code.isNotEmpty) {
              Navigator.pop(ctx);
              GoRouter.of(context).pushNamed('spectate', extra: code);
            }
          },
          child: const Text('Regarder',
              style: TextStyle(color: PyraTheme.primaryCyan, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

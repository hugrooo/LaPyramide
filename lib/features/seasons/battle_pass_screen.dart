import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../profile/user_profile_provider.dart';
import 'season_service.dart';

class BattlePassTier {
  final int tier;
  final String reward;
  final String emoji;
  final bool isPremium;
  final Color accentColor;

  const BattlePassTier({
    required this.tier,
    required this.reward,
    required this.emoji,
    this.isPremium = false,
    this.accentColor = PyraTheme.primaryCyan,
  });
}

const _tiers = [
  BattlePassTier(tier: 1, reward: '50 Coins', emoji: '🪙', accentColor: PyraTheme.primaryGreen),
  BattlePassTier(tier: 2, reward: 'Titre "Débutant"', emoji: '🏷️', accentColor: PyraTheme.primaryCyan),
  BattlePassTier(tier: 3, reward: '100 Coins', emoji: '🪙', accentColor: PyraTheme.primaryGreen),
  BattlePassTier(tier: 4, reward: 'Joker Bouclier', emoji: '🛡️', accentColor: PyraTheme.primaryBlue),
  BattlePassTier(tier: 5, reward: '200 Coins', emoji: '💰', accentColor: PyraTheme.primaryGreen),
  BattlePassTier(tier: 6, reward: 'Dos "Néon"', emoji: '🃏', isPremium: true, accentColor: PyraTheme.primaryPurple),
  BattlePassTier(tier: 7, reward: '500 Coins', emoji: '🪙', isPremium: true, accentColor: PyraTheme.primaryYellow),
  BattlePassTier(tier: 8, reward: 'Titre "Vétéran"', emoji: '⭐', isPremium: true, accentColor: PyraTheme.primaryOrange),
  BattlePassTier(tier: 9, reward: 'Bordure "Flamme"', emoji: '🔥', isPremium: true, accentColor: PyraTheme.primaryOrange),
  BattlePassTier(tier: 10, reward: '1 000 Coins', emoji: '🪙', isPremium: true, accentColor: PyraTheme.primaryYellow),
  BattlePassTier(tier: 11, reward: 'Dos "Galaxy"', emoji: '🌌', isPremium: true, accentColor: PyraTheme.primaryPurple),
  BattlePassTier(tier: 12, reward: 'Titre "Champion"', emoji: '🏆', isPremium: true, accentColor: PyraTheme.primaryYellow),
  BattlePassTier(tier: 13, reward: 'Anim "Confetti"', emoji: '🎊', isPremium: true, accentColor: PyraTheme.primaryPink),
  BattlePassTier(tier: 14, reward: '2 000 Coins', emoji: '💰', isPremium: true, accentColor: PyraTheme.primaryYellow),
  BattlePassTier(tier: 15, reward: 'Bordure "Diamant"', emoji: '💎', isPremium: true, accentColor: PyraTheme.primaryCyan),
];

class BattlePassScreen extends ConsumerStatefulWidget {
  const BattlePassScreen({super.key});

  @override
  ConsumerState<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends ConsumerState<BattlePassScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).value;
      final xp = profile?.xp ?? 0;
      final currentTier = (xp ~/ 100).clamp(0, 15);
      if (currentTier > 2) {
        _scrollController.animateTo(
          (currentTier - 1) * 142.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(currentSeasonProvider);
    final profile = ref.watch(userProfileProvider).value;
    final xp = profile?.xp ?? 0;
    final currentTier = (xp ~/ 100).clamp(0, 15);
    final xpInTier = xp % 100;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PyraTheme.primaryPurple.withValues(alpha: 0.15),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PyraTheme.primaryCyan.withValues(alpha: 0.1),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(season),
                const SizedBox(height: 16),
                _buildXPSection(currentTier, xpInTier),
                const SizedBox(height: 20),
                _buildSeasonRewardPreview(currentTier),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildHorizontalTrack(currentTier),
                ),
                _buildPremiumCTA(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SeasonData season) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(season.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          PyraTheme.festiveGradient.createShader(bounds),
                      child: Text(
                        'PASS ${season.name.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: PyraTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PyraTheme.primaryGreen.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${season.daysRemaining} jours restants',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildXPSection(int currentTier, int xpInTier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PyraTheme.primaryCyan.withValues(alpha: 0.2)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: PyraTheme.cyanGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: PyraTheme.primaryCyan.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        'LVL $currentTier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$currentTier / 15',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$xpInTier / 100 XP',
                    style: const TextStyle(
                      color: PyraTheme.primaryCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      widthFactor: xpInTier / 100,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              PyraTheme.primaryCyan,
                              PyraTheme.primaryPurple,
                              PyraTheme.primaryCyan,
                            ],
                            stops: [
                              0.0,
                              _shimmerController.value,
                              1.0,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  PyraTheme.primaryCyan.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildSeasonRewardPreview(int currentTier) {
    if (currentTier >= 15) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PyraTheme.primaryYellow.withValues(alpha: 0.4)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Text(
                'Pass complété !',
                style: TextStyle(
                  color: PyraTheme.primaryYellow,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nextTier = _tiers[currentTier];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nextTier.accentColor.withValues(alpha: 0.3)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: nextTier.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: nextTier.accentColor.withValues(alpha: 0.3)),
              ),
              child: Text(nextTier.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prochaine récompense',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextTier.reward,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (nextTier.isPremium)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: PyraTheme.purplePinkGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1);
  }

  Widget _buildHorizontalTrack(int currentTier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: PyraTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RÉCOMPENSES',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tiers.length,
            itemBuilder: (context, index) {
              final tier = _tiers[index];
              final isUnlocked = index < currentTier;
              final isCurrent = index == currentTier;

              return _buildTierNode(tier, isUnlocked, isCurrent, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTierNode(
      BattlePassTier tier, bool isUnlocked, bool isCurrent, int index) {
    final color = tier.accentColor;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          // Connection line
          Row(
            children: [
              if (index > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnlocked
                            ? [
                                PyraTheme.primaryGreen.withValues(alpha: 0.8),
                                PyraTheme.primaryGreen
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.05)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? PyraTheme.primaryGreen
                      : isCurrent
                          ? color
                          : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isCurrent
                        ? color
                        : Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isUnlocked
                    ? const Icon(Icons.check, color: Colors.white, size: 10)
                    : null,
              ),
              if (index < _tiers.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? PyraTheme.primaryGreen.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 12),
          // Tier card
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: isCurrent
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                color: isCurrent ? null : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCurrent
                      ? color.withValues(alpha: 0.6)
                      : isUnlocked
                          ? PyraTheme.primaryGreen.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06),
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? PyraTheme.primaryGreen.withValues(alpha: 0.2)
                          : color.withValues(alpha: 0.15),
                      border: Border.all(
                        color: isUnlocked
                            ? PyraTheme.primaryGreen.withValues(alpha: 0.5)
                            : color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: isUnlocked
                          ? const Icon(Icons.check_rounded,
                              color: PyraTheme.primaryGreen, size: 14)
                          : Text(
                              '${tier.tier}',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tier.emoji,
                    style: TextStyle(
                      fontSize: isCurrent ? 36 : 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tier.reward,
                    style: TextStyle(
                      color: isUnlocked
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      decoration:
                          isUnlocked ? TextDecoration.lineThrough : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (tier.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: PyraTheme.purplePinkGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PyraTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                PyraTheme.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'GRATUIT',
                        style: TextStyle(
                          color: PyraTheme.primaryGreen,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 40 * tier.tier))
        .slideY(begin: 0.15);
  }

  Widget _buildPremiumCTA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PyraTheme.primaryPurple.withValues(alpha: 0.4)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: PyraTheme.purplePinkGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: PyraTheme.primaryPurple.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pass Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Débloque les 10 récompenses exclusives',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => HapticFeedback.mediumImpact(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: PyraTheme.purplePinkGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: PyraTheme.primaryPink.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Text(
                  'OBTENIR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}

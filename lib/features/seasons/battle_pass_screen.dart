import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../auth/auth_service.dart';
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
  BattlePassTier(tier: 13, reward: '500 Coins', emoji: '💰', isPremium: true, accentColor: PyraTheme.primaryPink),
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
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = ref.read(userProfileProvider).value;
      final level = profile?.level ?? 1;
      final rawLastClaimed = profile?.lastClaimedLevel ?? 0;

      // Auto-correction : si lastClaimedLevel > level, c'est une valeur
      // corrompue par l'ancien code — on la remet à 0 dans Firebase
      if (rawLastClaimed > level) {
        final uid = ref.read(authStateChangesProvider).value?.uid;
        if (uid != null) {
          await FirebaseDatabase.instance
              .ref('users/$uid/lastClaimedLevel')
              .set(0);
        }
      }

      // Scroll pour centrer le tier courant
      final tierIndex = (level - 1).clamp(0, _tiers.length - 1);
      if (tierIndex > 1) {
        _scrollController.animateTo(
          (tierIndex - 1) * 142.0,
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

  Future<void> _claimReward(int tierIndex, String uid) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    HapticFeedback.mediumImpact();

    try {
      final tier = _tiers[tierIndex];
      final reward = await UserProfile.claimLevelReward(uid, tierIndex: tierIndex);

      if (reward == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de récupérer cette récompense.'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(tier.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tier.reward} récupéré !',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: PyraTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(currentSeasonProvider);
    final profile = ref.watch(userProfileProvider).value;
    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;
    // Tier actuel = level (niveau 2 → tier 2 débloqué)
    final currentTier = level.clamp(0, _tiers.length);
    // XP pour passer au niveau suivant = level * 100
    final xpForNext = level * 100;
    // lastClaimed ne peut jamais dépasser le niveau actuel (corrige les valeurs corrompues)
    final rawLastClaimed = profile?.lastClaimedLevel ?? 0;
    final lastClaimed = rawLastClaimed.clamp(0, currentTier);
    final uid = ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: PyraTheme.primaryPurple.withValues(alpha: 0.15),
                  blurRadius: 150, spreadRadius: 50,
                )],
              ),
            ),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: PyraTheme.primaryCyan.withValues(alpha: 0.1),
                  blurRadius: 120, spreadRadius: 40,
                )],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(season),
                const SizedBox(height: 16),
                _buildXPSection(currentTier, xp, xpForNext, level),
                const SizedBox(height: 12),
                _buildNextRewardBanner(currentTier, lastClaimed, level),
                const SizedBox(height: 16),
                Expanded(child: _buildHorizontalTrack(currentTier, lastClaimed, uid)),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
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
                      shaderCallback: (bounds) => PyraTheme.festiveGradient.createShader(bounds),
                      child: Text(
                        'PASS ${season.name.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w900, letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: PyraTheme.primaryGreen, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: PyraTheme.primaryGreen.withValues(alpha: 0.6), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${season.daysRemaining} jours restants',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500),
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

  Widget _buildXPSection(int currentTier, int xp, int xpForNext, int level) {
    final progress = (xp / xpForNext).clamp(0.0, 1.0);

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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: PyraTheme.cyanGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: PyraTheme.primaryCyan.withValues(alpha: 0.3), blurRadius: 8)],
                      ),
                      child: Text(
                        'LVL $level',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tier $currentTier/${_tiers.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$xp / $xpForNext XP',
                    style: const TextStyle(color: PyraTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.w700),
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
                      widthFactor: progress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [PyraTheme.primaryCyan, PyraTheme.primaryPurple, PyraTheme.primaryCyan],
                            stops: [0.0, _shimmerController.value, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [BoxShadow(color: PyraTheme.primaryCyan.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)],
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

  Widget _buildNextRewardBanner(int currentTier, int lastClaimed, int level) {
    // Y a-t-il des récompenses à réclamer ?
    final pendingCount = currentTier - lastClaimed;

    if (pendingCount > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PyraTheme.primaryYellow.withValues(alpha: 0.6)),
          innerGlow: true,
          child: Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$pendingCount récompense${pendingCount > 1 ? 's' : ''} à récupérer !',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PyraTheme.primaryYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PyraTheme.primaryYellow.withValues(alpha: 0.5)),
                ),
                child: const Text('↓', style: TextStyle(color: PyraTheme.primaryYellow, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 300.ms).shake(hz: 2, rotation: 0.02);
    }

    if (currentTier >= _tiers.length) {
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
              Text('Pass complété !', style: TextStyle(color: PyraTheme.primaryYellow, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
    }

    // nextTier = premier tier pas encore débloqué (index = currentTier = level)
    final nextTier = _tiers[currentTier];
    final nextLevel = currentTier + 1; // niveau requis pour débloquer ce tier
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
                border: Border.all(color: nextTier.accentColor.withValues(alpha: 0.3)),
              ),
              child: Text(nextTier.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Niveau $nextLevel — prochaine récompense',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(nextTier.reward,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (nextTier.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(gradient: PyraTheme.purplePinkGradient, borderRadius: BorderRadius.circular(8)),
                child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1);
  }

  Widget _buildHorizontalTrack(int currentTier, int lastClaimed, String? uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12),
          child: Row(
            children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: PyraTheme.primaryPurple, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('RÉCOMPENSES', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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
              final isClaimed = index < lastClaimed;
              final canClaim = isUnlocked && !isClaimed && uid != null;
              return _buildTierNode(tier, isUnlocked, isCurrent, isClaimed, canClaim, index, uid);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTierNode(BattlePassTier tier, bool isUnlocked, bool isCurrent, bool isClaimed, bool canClaim, int index, String? uid) {
    final color = tier.accentColor;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          // Ligne de connexion + point
          Row(
            children: [
              if (index > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isClaimed
                            ? [PyraTheme.primaryGreen.withValues(alpha: 0.8), PyraTheme.primaryGreen]
                            : isUnlocked
                                ? [color.withValues(alpha: 0.5), color.withValues(alpha: 0.3)]
                                : [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isClaimed
                      ? PyraTheme.primaryGreen
                      : isCurrent
                          ? color
                          : isUnlocked
                              ? color.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isCurrent ? color : Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: isCurrent || canClaim
                      ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)]
                      : null,
                ),
                child: isClaimed
                    ? const Icon(Icons.check, color: Colors.white, size: 10)
                    : null,
              ),
              if (index < _tiers.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isClaimed
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
          // Carte du tier
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: canClaim
                    ? LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.1)],
                      )
                    : isCurrent
                        ? LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                          )
                        : null,
                color: (canClaim || isCurrent) ? null : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: canClaim
                      ? color
                      : isCurrent
                          ? color.withValues(alpha: 0.6)
                          : isClaimed
                              ? PyraTheme.primaryGreen.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                  width: (canClaim || isCurrent) ? 2 : 1,
                ),
                boxShadow: canClaim
                    ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)]
                    : isCurrent
                        ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2)]
                        : null,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Numéro du tier
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isClaimed
                          ? PyraTheme.primaryGreen.withValues(alpha: 0.2)
                          : color.withValues(alpha: 0.15),
                      border: Border.all(
                        color: isClaimed
                            ? PyraTheme.primaryGreen.withValues(alpha: 0.5)
                            : color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: isClaimed
                          ? const Icon(Icons.check_rounded, color: PyraTheme.primaryGreen, size: 14)
                          : Text('${tier.tier}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(tier.emoji, style: TextStyle(fontSize: (isCurrent || canClaim) ? 36 : 30)),
                  const SizedBox(height: 6),
                  Text(
                    tier.reward,
                    style: TextStyle(
                      color: isClaimed ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      decoration: isClaimed ? TextDecoration.lineThrough : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Bouton réclamer ou badge
                  if (canClaim)
                    GestureDetector(
                      onTap: () => _claimReward(index, uid!),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
                        ),
                        child: _claiming
                            ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('RÉCLAMER', textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                      ),
                    )
                  else if (isClaimed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PyraTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PyraTheme.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: const Text('RÉCLAMÉ ✓', style: TextStyle(color: PyraTheme.primaryGreen, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    )
                  else if (tier.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(gradient: PyraTheme.purplePinkGradient, borderRadius: BorderRadius.circular(6)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PyraTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PyraTheme.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: const Text('GRATUIT', style: TextStyle(color: PyraTheme.primaryGreen, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 40 * tier.tier)).slideY(begin: 0.15);
  }

  Widget _buildPremiumCTA() {
    final profile = ref.watch(userProfileProvider).value;
    final hasPass = profile?.battlePassActive ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPass
              ? PyraTheme.primaryGreen.withValues(alpha: 0.5)
              : PyraTheme.primaryPurple.withValues(alpha: 0.4),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: hasPass
                    ? const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)])
                    : PyraTheme.purplePinkGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (hasPass ? PyraTheme.primaryGreen : PyraTheme.primaryPurple)
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                  )
                ],
              ),
              child: Icon(
                hasPass ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPass ? 'Pass Premium Actif' : 'Pass Premium',
                    style: TextStyle(
                      color: hasPass ? PyraTheme.primaryGreen : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPass
                        ? 'Toutes les récompenses premium débloquées ✓'
                        : 'Débloque les 10 récompenses exclusives',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasPass)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.go('/store');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: PyraTheme.purplePinkGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: PyraTheme.primaryPink.withValues(alpha: 0.3),
                          blurRadius: 8)
                    ],
                  ),
                  child: const Text('OBTENIR',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}

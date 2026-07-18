import 'package:firebase_database/firebase_database.dart';
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
import '../../shared/widgets/pulsar_button.dart';
import '../../shared/widgets/avatar_with_border.dart';
import '../auth/auth_service.dart';
import 'user_profile_provider.dart';

// ─── Page Profil Premium ──────────────────────────────────────────────────────

class LevelScreen extends ConsumerWidget {
  const LevelScreen({super.key});

  // ── Firebase profile updater ────────────────────────────────────────────────
  Future<void> _updateProfileField(
      String field, dynamic value, String uid) async {
    await FirebaseDatabase.instance.ref('users/$uid').update({field: value});
  }

  // ── Édition de pseudo ───────────────────────────────────────────────────────
  void _showEditNameDialog(
      BuildContext context, String uid, String currentName) {
    HapticFeedback.mediumImpact();
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          innerGlow: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_rounded,
                  color: PyraTheme.primaryPink, size: 48),
              const SizedBox(height: 16),
              const Text('Modifier le pseudo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GlassContainer(
                blur: 8,
                opacity: 0.1,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nouveau pseudo',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PulsarButton(
                      text: 'Valider',
                      gradient: PyraTheme.purplePinkGradient,
                      onPressed: () {
                        final newName = controller.text.trim();
                        if (newName.isNotEmpty) {
                          FirebaseDatabase.instance.ref('users/$uid').update({
                            'name': newName,
                            'searchName': newName.toLowerCase(),
                          });
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  // ── Sélecteur d'avatar ──────────────────────────────────────────────────────
  void _showEmojiPicker(BuildContext context, String uid, String currentEmoji) {
    const emojis = [
      '😎',
      '👑',
      '🦁',
      '🐱',
      '🐶',
      '🦊',
      '🐼',
      '🐸',
      '🦄',
      '🥤',
      '🃏',
      '🔥',
      '⚡',
      '🎭',
      '💀',
      '🌙',
      '🐲',
      '🤖',
      '👻',
      '🎯',
      '🎯',
      '🎰',
      '🦅',
      '🐯',
    ];
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AppearanceSheet(
        title: 'Choisir ton Avatar',
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: emojis.length,
          itemBuilder: (_, i) {
            final emoji = emojis[i];
            final isSelected = emoji == currentEmoji;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _updateProfileField('emoji', emoji, uid);
                Navigator.pop(ctx);
              },
              child: AnimatedContainer(
                duration: 200.ms,
                decoration: BoxDecoration(
                  color: isSelected
                      ? PyraTheme.primaryCyan.withOpacity(0.25)
                      : Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? PyraTheme.primaryCyan : Colors.white12,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: PyraTheme.primaryCyan.withOpacity(0.5),
                              blurRadius: 12)
                        ]
                      : null,
                ),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26))),
              ).animate().scale(
                  delay: (i * 15).ms,
                  duration: 200.ms,
                  curve: Curves.easeOutBack),
            );
          },
        ),
      ),
    );
  }

  // ── Sélecteur de titre ──────────────────────────────────────────────────────
  void _showTitlePicker(BuildContext context, String uid, String currentTitle,
      List<String> ownedTitles) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AppearanceSheet(
        title: 'Choisir ton Titre',
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: ownedTitles.length,
          itemBuilder: (_, i) {
            final title = ownedTitles[i];
            final isSelected = title == currentTitle;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _updateProfileField('activeTitle', title, uid);
                Navigator.pop(ctx);
              },
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PyraTheme.primaryPink.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? PyraTheme.primaryPink : Colors.white12,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.military_tech_rounded,
                      color:
                          isSelected ? PyraTheme.primaryPink : Colors.white30,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: PyraTheme.primaryPink, size: 22),
                  ],
                ),
              )
                  .animate()
                  .slideX(begin: -0.2, delay: (i * 30).ms, duration: 300.ms),
            );
          },
        ),
      ),
    );
  }

  // ── Sélecteur de dos de carte ───────────────────────────────────────────────
  void _showCardBackPicker(BuildContext context, String uid, String currentBack,
      List<String> ownedBacks) {
    const backData = {
      'classic': {
        'name': 'Classique Rouge',
        'emoji': '🟥',
        'color': Color(0xFFD72638)
      },
      'neon': {
        'name': 'Néon Cyberpunk',
        'emoji': '⚡',
        'color': Color(0xFF00F5FF)
      },
      'pirate': {
        'name': 'Pirate Doré',
        'emoji': '☠️',
        'color': Color(0xFFFFB703)
      },
      'retro': {
        'name': 'Rétro Pixel',
        'emoji': '👾',
        'color': Color(0xFF8338EC)
      },
      'girl': {'name': 'Girly Rose', 'emoji': '🎀', 'color': Color(0xFFFF1493)},
      'beta': {
        'name': 'Testeur Bêta',
        'emoji': '🚀',
        'color': Color(0xFFE040FB)
      },
      'pharaoh': {
        'name': 'Pharaon',
        'emoji': '👁️',
        'color': Color(0xFFD4AF37)
      },
      'casino': {
        'name': 'Casino Royal',
        'emoji': '🎲',
        'color': Color(0xFF006400)
      },
      'toxic': {'name': 'Toxique', 'emoji': '🧪', 'color': Color(0xFF39FF14)},
      'clubbing': {
        'name': 'Clubbing',
        'emoji': '🪩',
        'color': Color(0xFFFF00FF)
      },
      'demon': {
        'name': 'Démoniaque',
        'emoji': '😈',
        'color': Color(0xFFFF4500)
      },
      'vip': {'name': 'VIP Diamant', 'emoji': '💎', 'color': Color(0xFF80DEEA)},
    };
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AppearanceSheet(
        title: 'Choisir le Dos de Carte',
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ownedBacks.length,
          itemBuilder: (_, i) {
            final backId = ownedBacks[i];
            final data = backData[backId];
            final name = data?['name'] as String? ?? backId;
            final emoji = data?['emoji'] as String? ?? '🃏';
            final color = data?['color'] as Color? ?? PyraTheme.primaryCyan;
            final isSelected = backId == currentBack;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _updateProfileField('activeCardBack', backId, uid);
                Navigator.pop(ctx);
              },
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : Colors.white12,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Card3DShowcase(
                      skinId: backId,
                      width: 40,
                      height: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: color, size: 22),
                  ],
                ),
              )
                  .animate()
                  .slideX(begin: -0.2, delay: (i * 40).ms, duration: 300.ms),
            );
          },
        ),
      ),
    );
  }

  // ── Sélecteur de Cadre ──────────────────────────────────────────────────────
  void _showBorderPicker(BuildContext context, String uid, String currentBorder,
      List<String> ownedBorders) {
    const borderData = {
      'classic': {'name': 'Sans Cadre', 'color': Colors.grey},
      'neon': {'name': 'Néon Fluo ⚡', 'color': Color(0xFF00F5FF)},
      'fire': {'name': 'Feu Ardent 🔥', 'color': Colors.orange},
      'gold': {'name': 'Or Massif 👑', 'color': Color(0xFFFFD700)},
    };
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AppearanceSheet(
        title: 'Choisir le Cadre',
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ownedBorders.length,
          itemBuilder: (_, i) {
            final borderId = ownedBorders[i];
            final data = borderData[borderId];
            final name = data?['name'] as String? ?? borderId;
            final color = data?['color'] as Color? ?? PyraTheme.primaryCyan;
            final isSelected = borderId == currentBorder;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _updateProfileField('selectedBorder', borderId, uid);
                Navigator.pop(ctx);
              },
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : Colors.white12,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AvatarWithBorder(
                        emoji: '😎', size: 30, borderType: borderId),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: color, size: 22),
                  ],
                ),
              )
                  .animate()
                  .slideX(begin: -0.2, delay: (i * 30).ms, duration: 300.ms),
            );
          },
        ),
      ),
    );
  }

  // ── Sélecteur de Thème Musical ──────────────────────────────────────────────
  void _showThemePicker(BuildContext context, String uid, String currentTheme,
      List<String> ownedThemes) {
    const themeData = {
      'classic': {
        'name': 'Musique Classique Pyramide',
        'icon': Icons.music_note_rounded,
        'color': Colors.grey
      },
      'casino': {
        'name': 'Casino Royal 🎰',
        'icon': Icons.casino_rounded,
        'color': Color(0xFFFFB703)
      },
      'clubbing': {
        'name': 'Clubbing 🪩',
        'icon': Icons.speaker_group_rounded,
        'color': Color(0xFFFF00FF)
      },
      'horror': {
        'name': 'Tension Horrifique 🔪',
        'icon': Icons.piano_rounded,
        'color': Colors.redAccent
      },
    };
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AppearanceSheet(
        title: 'Choisir le Thème Musical',
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ownedThemes.length,
          itemBuilder: (_, i) {
            final themeId = ownedThemes[i];
            final data = themeData[themeId];
            final name = data?['name'] as String? ?? themeId;
            final icon = data?['icon'] as IconData? ?? Icons.music_note_rounded;
            final color = data?['color'] as Color? ?? PyraTheme.primaryCyan;
            final isSelected = themeId == currentTheme;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _updateProfileField('selectedTheme', themeId, uid);
                Navigator.pop(ctx);
              },
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : Colors.white12,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        color: isSelected ? color : Colors.white30, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: color, size: 22),
                  ],
                ),
              )
                  .animate()
                  .slideX(begin: -0.2, delay: (i * 30).ms, duration: 300.ms),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;
    final user = ref.watch(authStateChangesProvider).value;

    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;
    final lastClaimedLevel = profile?.lastClaimedLevel ?? 1;
    final hasRewardToClaim = level > lastClaimedLevel;
    final rewardLevel = lastClaimedLevel + 1;
    final xpNeededForNext = level * 100;
    final progress = (xp / xpNeededForNext).clamp(0.0, 1.0);
    final numberFormat = NumberFormat('#,###', 'fr_FR');
    final displayTitle = profile?.activeTitle ?? 'Novice 🐣';

    final backDisplayName = switch (profile?.activeCardBack ?? 'classic') {
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
      'vip' => 'VIP Diamant 💎',
      _ => 'Classique Rouge 🟥',
    };

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
                        child: Text('Mon Profil',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center),
                      ),
                      // Raccourci vers Paramètres
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.goNamed('settings');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.settings_outlined,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // ── Corps scrollable ─────────────────────────────────────
                Expanded(
                  child: ListView(
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

                            // Avatar
                            GestureDetector(
                              onTap: user != null && profile != null
                                  ? () => _showEmojiPicker(
                                      context, user.uid, profile.emoji)
                                  : null,
                              child: Container(
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AvatarWithBorder(
                                        emoji: profile?.emoji ?? '😎',
                                        size: 56,
                                        borderType: profile?.selectedBorder ??
                                            'classic'),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Modifier',
                                      style: TextStyle(
                                          color: PyraTheme.primaryCyan,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                profile?.name ??
                                    user?.displayName ??
                                    'Joueur Inconnu',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showEditNameDialog(
                                    context,
                                    user!.uid,
                                    profile?.name ?? user?.displayName ?? ''),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      color: Colors.white70, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: PyraTheme.purplePinkGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: PyraTheme.glowPurple,
                            ),
                            child: Text(
                              displayTitle.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.8),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                      const SizedBox(height: 24),

                      // ── Barre XP ───────────────────────────────────────
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Progression',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                NeoBadge(
                                    text: 'Niv. $level → ${level + 1}',
                                    gradient: PyraTheme.cyanGradient),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${numberFormat.format(xp)} XP',
                                    style: const TextStyle(
                                        color: PyraTheme.primaryCyan,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900)),
                                Text(
                                    '/ ${numberFormat.format(xpNeededForNext)} XP',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: 1200.ms,
                              curve: Curves.easeOutCubic,
                              builder: (_, val, __) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: val,
                                  minHeight: 10,
                                  backgroundColor: Colors.white10,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          PyraTheme.primaryCyan),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),

                      const SizedBox(height: 16),

                      // ── Grille Stats ───────────────────────────────────
                      Row(
                        children: [
                          _StatCard(
                            icon: '🎮',
                            label: 'Parties',
                            value:
                                numberFormat.format(profile?.gamesPlayed ?? 0),
                            color: PyraTheme.primaryCyan,
                            delay: 400,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: '😈',
                            label: 'Bluffs',
                            value: numberFormat.format(profile?.bluffWins ?? 0),
                            color: PyraTheme.primaryPink,
                            delay: 470,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: '🎯',
                            label: 'Pénalités',
                            value:
                                numberFormat.format(profile?.drinksGiven ?? 0),
                            color: PyraTheme.primaryOrange,
                            delay: 540,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: '💰',
                            label: 'Pièces',
                            value: numberFormat.format(profile?.coins ?? 0),
                            color: PyraTheme.primaryYellow,
                            delay: 610,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Section Mon Apparence ──────────────────────────
                      _SectionHeader(
                          label: 'MON APPARENCE',
                          color: PyraTheme.primaryPurple),

                      const SizedBox(height: 12),

                      if (user != null && profile != null) ...[
                        // Ligne 1 : Avatar + Titre
                        Row(
                          children: [
                            // Avatar
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _showEmojiPicker(
                                      context, user.uid, profile.emoji);
                                },
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: PyraTheme.primaryCyan
                                          .withOpacity(0.35)),
                                  child: Column(
                                    children: [
                                      Text(profile.emoji,
                                          style: const TextStyle(fontSize: 38)),
                                      const SizedBox(height: 8),
                                      const Text('Avatar',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11)),
                                      const SizedBox(height: 3),
                                      const Text('Changer →',
                                          style: TextStyle(
                                              color: PyraTheme.primaryCyan,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: 650.ms).scale(
                                  begin: const Offset(0.9, 0.9),
                                  curve: Curves.easeOutBack),
                            ),

                            const SizedBox(width: 10),

                            // Titre
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _showTitlePicker(context, user.uid,
                                      profile.activeTitle, profile.titles);
                                },
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: PyraTheme.primaryPink
                                          .withOpacity(0.35)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.military_tech_rounded,
                                          color: PyraTheme.primaryPink,
                                          size: 28),
                                      const SizedBox(height: 8),
                                      const Text('Titre actif',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile.activeTitle,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Changer →',
                                          style: TextStyle(
                                              color: PyraTheme.primaryPink,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: 700.ms).scale(
                                  begin: const Offset(0.9, 0.9),
                                  curve: Curves.easeOutBack),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Dos de carte (pleine largeur)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showCardBackPicker(context, user.uid,
                                profile.activeCardBack, profile.cardBacks);
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    PyraTheme.primaryYellow.withOpacity(0.35)),
                            child: Row(
                              children: [
                                Card3DShowcase(
                                  skinId: profile.activeCardBack,
                                  width: 44,
                                  height: 62,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Dos de Carte',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)),
                                      const SizedBox(height: 3),
                                      Text(
                                        backDisplayName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white30, size: 14),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.1),
                        const SizedBox(height: 10),

                        // Cadre (pleine largeur)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showBorderPicker(context, user.uid,
                                profile.selectedBorder, profile.bordersOwned);
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: PyraTheme.primaryCyan.withOpacity(0.35)),
                            child: Row(
                              children: [
                                AvatarWithBorder(
                                    emoji: '😎',
                                    size: 44,
                                    borderType: profile.selectedBorder),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Cadre d\'Avatar',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)),
                                      const SizedBox(height: 3),
                                      Text(
                                        profile.selectedBorder == 'classic'
                                            ? 'Sans Cadre'
                                            : 'Spécial',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white30, size: 14),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 775.ms).slideY(begin: 0.1),


                      ],

                      const SizedBox(height: 24),

                      // ── Récompense de niveau ───────────────────────────
                      _SectionHeader(
                          label: 'RÉCOMPENSE', color: PyraTheme.primaryYellow),
                      const SizedBox(height: 12),

                      if (hasRewardToClaim)
                        _RewardCard(
                          rewardLevel: rewardLevel,
                          onClaim: () async {
                            HapticFeedback.heavyImpact();
                            final u = ref.read(authServiceProvider).currentUser;
                            if (u == null) return;
                            await UserProfile.claimLevelReward(u.uid);
                            if (context.mounted) {
                              _showRewardDialog(context, 200, 10, rewardLevel);
                            }
                          },
                        )
                      else
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_rounded,
                                    color: Colors.white30, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Récompense Niv. ${level + 1}',
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    const Text('+200 Pièces & +10 Diamants',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Atteins le niveau ${level + 1} pour débloquer',
                                        style: const TextStyle(
                                            color: PyraTheme.primaryYellow,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 800.ms),
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

  void _showRewardDialog(
      BuildContext context, int coins, int diamonds, int lvl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_rounded,
                    color: PyraTheme.primaryYellow, size: 52)
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 12),
            Text('Niveau $lvl Atteint !',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22),
                textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Récompense débloquée :',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardChip(
                    amount: '+$coins',
                    icon: Icons.monetization_on_rounded,
                    color: PyraTheme.primaryYellow),
                const SizedBox(width: 12),
                _RewardChip(
                    amount: '+$diamonds',
                    icon: Icons.diamond_rounded,
                    color: PyraTheme.primaryCyan),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          PulsarButton(
            text: 'Génial !',
            paddingHorizontal: 32,
            width: 160,
            gradient: PyraTheme.festiveGradient,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      )
          .animate()
          .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
    );
  }
}

// ─── Widgets utilitaires ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5)),
      );
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final int delay;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.delay});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                  textAlign: TextAlign.center),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: delay))
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
      );
}

class _RewardCard extends StatelessWidget {
  final int rewardLevel;
  final VoidCallback onClaim;
  const _RewardCard({required this.rewardLevel, required this.onClaim});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onClaim,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFB8500).withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              )
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white, size: 40)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.12, 1.12),
                      duration: 800.ms),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Niv. $rewardLevel Disponible !',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('+200 Pièces & +10 Diamants',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('🎁 TOUCHER POUR RÉCUPÉRER',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(
                duration: 3.seconds,
                color: Colors.white.withOpacity(0.3),
                angle: 45,
                blendMode: BlendMode.srcATop)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.02, 1.02),
                duration: 2.seconds,
                curve: Curves.easeInOut),
      );
}

class _RewardChip extends StatelessWidget {
  final String amount;
  final IconData icon;
  final Color color;
  const _RewardChip(
      {required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Text(amount,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(width: 6),
            Icon(icon, color: color, size: 20),
          ],
        ),
      );
}

// ── Bottom Sheet générique pour les pickers ─────────────────────────────────
class _AppearanceSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _AppearanceSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: PyraTheme.bgCard.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

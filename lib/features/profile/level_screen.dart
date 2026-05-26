import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'user_profile_provider.dart';
import 'dart:math' as math;

class LevelScreen extends ConsumerWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;

    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;
    
    // Formule simple d'XP nécessaire : 100 * niveau
    final xpNeededForNext = level * 100;
    final progress = (xp / xpNeededForNext).clamp(0.0, 1.0);
    
    final numberFormat = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Top Bar
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
                          'Progression',
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
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Circular Progress
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 16,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(PyraTheme.primaryCyan),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Niveau', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                Text('$level', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // XP details
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          children: [
                            const Text(
                              'Expérience (XP)',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${numberFormat.format(xp)} XP', style: const TextStyle(color: PyraTheme.primaryCyan, fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('/ ${numberFormat.format(xpNeededForNext)} XP', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.black26,
                                valueColor: const AlwaysStoppedAnimation<Color>(PyraTheme.primaryCyan),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gagne de l\'XP en jouant des parties. Plus tu joues, plus ton niveau augmente !',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Prochaines récompenses
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Récompense du Niv. ${level + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: PyraTheme.primaryYellow.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.monetization_on_rounded, color: PyraTheme.primaryYellow, size: 32),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('200 Pièces', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text('Pour acheter des Jokers en partie !', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

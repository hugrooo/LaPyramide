import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';

class MinigamesHubScreen extends StatelessWidget {
  const MinigamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => context.pop(),
                  ),
                  title: const Text('Mini-Jeux'),
                  centerTitle: true,
                  floating: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: PyraTheme.primaryPink.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '4 jeux disponibles',
                              style: TextStyle(
                                color: PyraTheme.primaryPink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Des jeux rapides à jouer entre amis, sans prise de tête !',
                        style: TextStyle(
                          color: PyraTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildGameCard(
                        context,
                        title: 'Menteur',
                        description:
                            'Bluff tes amis sur tes cartes ! Le premier à se faire prendre perd.',
                        icon: '🃏',
                        color: PyraTheme.primaryPurple,
                        players: '3-8 joueurs',
                        isPlayable: true,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed('minigameLiar');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGameCard(
                        context,
                        title: 'Quiz Rapidité',
                        description:
                            'Réponds le plus vite possible aux questions. Le dernier est éliminé !',
                        icon: '⚡',
                        color: PyraTheme.primaryCyan,
                        players: '2-10 joueurs',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed('comingSoon',
                              extra: 'Quiz Rapidité');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGameCard(
                        context,
                        title: 'Mime Party',
                        description:
                            'Mime un mot et fais deviner ton équipe avant le temps imparti !',
                        icon: '🎭',
                        color: PyraTheme.primaryPink,
                        players: '4-12 joueurs',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed('comingSoon', extra: 'Mime Party');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGameCard(
                        context,
                        title: 'Culture Clash',
                        description:
                            'Trouve le mot qui relie deux indices. Le plus rapide marque !',
                        icon: '🧠',
                        color: PyraTheme.primaryOrange,
                        players: '2-6 joueurs',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed('comingSoon',
                              extra: 'Culture Clash');
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required String icon,
    required Color color,
    required String players,
    required VoidCallback onTap,
    bool isPlayable = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isPlayable
                ? color.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.2)),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPlayable
                              ? Colors.greenAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPlayable ? 'JOUABLE' : 'BIENTÔT',
                          style: TextStyle(
                            color: isPlayable
                                ? Colors.greenAccent
                                : Colors.white38,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isPlayable
                          ? PyraTheme.textMuted
                          : PyraTheme.textMuted.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    players,
                    style: TextStyle(
                      color: color.withValues(alpha: isPlayable ? 1.0 : 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 14),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.05);
  }
}

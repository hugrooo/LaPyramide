import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'stats_service.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Stack(
          children: [
            const AnimatedBackground(),
            const Center(
              child: Text('Connecte-toi pour voir tes stats',
                  style: TextStyle(color: PyraTheme.textSecondary)),
            ),
          ],
        ),
      );
    }

    final historyAsync = ref.watch(gameHistoryProvider(user.uid));

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          'Statistiques',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: PyraTheme.primaryYellow),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // Content
                Expanded(
                  child: historyAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: PyraTheme.primaryCyan),
                    ),
                    error: (e, _) => Center(
                      child: Text('Erreur: $e',
                          style: const TextStyle(
                              color: PyraTheme.textSecondary)),
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Aucune partie enregistrée',
                                      style: TextStyle(
                                          color: PyraTheme.textSecondary,
                                          fontSize: 16))
                                  .animate()
                                  .fadeIn(),
                              const SizedBox(height: 8),
                              const Text('Joue une partie pour commencer !',
                                      style: TextStyle(
                                          color: PyraTheme.textMuted,
                                          fontSize: 14))
                                  .animate()
                                  .fadeIn(delay: 200.ms),
                            ],
                          ),
                        );
                      }

                      final stats = PlayerStats.fromEntries(entries);
                      return _StatsContent(
                          stats: stats, recentGames: entries);
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

class _StatsContent extends StatelessWidget {
  final PlayerStats stats;
  final List<GameHistoryEntry> recentGames;

  const _StatsContent({required this.stats, required this.recentGames});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          _buildOverviewCards(context),
          const SizedBox(height: 24),

          // Streak
          _buildStreakCard(),
          const SizedBox(height: 24),

          // Penalties by mode chart
          if (stats.penaltiesByMode.isNotEmpty) ...[
            _buildPenaltyChart(),
            const SizedBox(height: 24),
          ],

          // Recent games
          const Text(
            'Parties récentes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 12),
          ...recentGames.take(10).toList().asMap().entries.map((entry) {
            return _buildGameRow(entry.value, entry.key);
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Parties',
            value: '${stats.totalGames}',
            icon: Icons.sports_esports_rounded,
            color: PyraTheme.primaryCyan,
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Victoires',
            value: '${(stats.winRate * 100).toInt()}%',
            icon: Icons.emoji_events_rounded,
            color: PyraTheme.primaryYellow,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Mode favori',
            value: _modeLabel(stats.favoriteMode),
            icon: Icons.favorite_rounded,
            color: PyraTheme.primaryPink,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      color: PyraTheme.primaryOrange,
      opacity: 0.12,
      border: Border.all(color: PyraTheme.primaryOrange.withOpacity(0.4)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: PyraTheme.orangeYellowGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Série en cours',
                  style: TextStyle(
                      color: PyraTheme.textSecondary, fontSize: 13),
                ),
                Text(
                  '${stats.currentStreak} jour${stats.currentStreak > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Bluffs réussis',
                  style:
                      TextStyle(color: PyraTheme.textMuted, fontSize: 11)),
              Text(
                '${(stats.bluffSuccessRate * 100).toInt()}%',
                style: const TextStyle(
                  color: PyraTheme.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPenaltyChart() {
    final maxPenalties = stats.penaltiesByMode.values.isEmpty
        ? 1
        : stats.penaltiesByMode.values
            .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pénalités par mode',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: stats.penaltiesByMode.entries.map((entry) {
              final ratio = entry.value / maxPenalties;
              final color = _modeColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        _modeLabel(entry.key),
                        style: const TextStyle(
                            color: PyraTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio.clamp(0.05, 1.0),
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [color, color.withOpacity(0.6)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${entry.value}',
                        style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildGameRow(GameHistoryEntry game, int index) {
    final isWin = game.result == 'win';
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  (isWin ? PyraTheme.primaryGreen : PyraTheme.primaryPink)
                      .withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isWin ? Icons.emoji_events_rounded : Icons.close_rounded,
              color:
                  isWin ? PyraTheme.primaryGreen : PyraTheme.primaryPink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _modeLabel(game.mode),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  '${game.players.length} joueurs',
                  style: const TextStyle(
                      color: PyraTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${game.penalties} pen.',
                style: const TextStyle(
                    color: PyraTheme.primaryOrange, fontSize: 13),
              ),
              Text(
                _formatDate(game.date),
                style: const TextStyle(
                    color: PyraTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 550 + index * 60))
        .slideX(begin: 0.1);
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'classic':
        return 'Classique';
      case 'powers':
        return 'Pouvoirs';
      case 'secretMissions':
        return 'Missions';
      case 'miniGames':
        return 'Mini-jeux';
      case 'truthOrSip':
        return 'Action/Vérité';
      case 'speedRun':
        return 'Speed';
      default:
        return mode;
    }
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case 'classic':
        return PyraTheme.primaryCyan;
      case 'powers':
        return PyraTheme.primaryPurple;
      case 'secretMissions':
        return PyraTheme.primaryOrange;
      case 'miniGames':
        return PyraTheme.primaryGreen;
      case 'truthOrSip':
        return PyraTheme.primaryPink;
      case 'speedRun':
        return PyraTheme.primaryYellow;
      default:
        return PyraTheme.primaryCyan;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      color: color,
      opacity: 0.1,
      border: Border.all(color: color.withOpacity(0.3)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style:
                const TextStyle(color: PyraTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

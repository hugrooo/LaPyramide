import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/animated_background.dart';
import '../game/models/player_model.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../../shared/widgets/glass_container.dart';

class ScoreboardScreen extends StatelessWidget {
  final List<Player> players;

  const ScoreboardScreen({super.key, required this.players});

  Player get _mostDrunk =>
      players.reduce((a, b) => a.totalSips >= b.totalSips ? a : b);

  Player get _bestBluffer =>
      players.reduce((a, b) => a.bluffsWon >= b.bluffsWon ? a : b);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...players]..sort((a, b) => b.totalSips.compareTo(a.totalSips));

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Titre
                  Text(
                    '🏆 ${l10n.scoreboard_title}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: PyraTheme.primaryYellow,
                        ),
                  ).animate().fadeIn().scale(),

                  const SizedBox(height: 24),

                  // Podium des statistiques
                  _buildStatBadges(context, l10n),

                  const SizedBox(height: 24),

                  // Classement complet
                  Expanded(
                    child: ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, i) =>
                          _buildPlayerRow(context, i, sorted[i]),
                    ),
                  ),

                  // Révélation des missions secrètes
                  if (players.any((p) => p.secretMission != null)) ...[
                    const SizedBox(height: 16),
                    const Text('🕵️ Missions Secrètes', style: TextStyle(color: PyraTheme.primaryOrange, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        itemCount: players.where((p) => p.secretMission != null).length,
                        itemBuilder: (context, i) {
                          final p = players.where((p) => p.secretMission != null).toList()[i];
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Text(p.emoji, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(p.secretMission!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Boutons
                  const SizedBox(height: 16),
                  PulsarButton(
                    text: '🎲 ${l10n.scoreboard_play_again}',
                    gradient: PyraTheme.purplePinkGradient,
                    onPressed: () => context.goNamed('localLobby'), // Or something depending if online/local
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.goNamed('home'),
                    child: Text(
                      l10n.scoreboard_home,
                      style: const TextStyle(color: PyraTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadges(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _StatBadge(
            emoji: '🍺',
            label: l10n.scoreboard_most_drunk,
            player: _mostDrunk,
            value: '${_mostDrunk.totalSips} gorgées',
            color: PyraTheme.primaryOrange,
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBadge(
            emoji: '😈',
            label: l10n.scoreboard_best_bluffer,
            player: _bestBluffer,
            value: '${_bestBluffer.bluffsWon} bluffs',
            color: PyraTheme.primaryPink,
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(BuildContext context, int rank, Player player) {
    final rankEmoji = rank == 0
        ? '🥇'
        : rank == 1
            ? '🥈'
            : rank == 2
                ? '🥉'
                : '${rank + 1}.';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: rank == 0 ? PyraTheme.primaryYellow : PyraTheme.bgCard,
      opacity: rank == 0 ? 0.2 : 0.6,
      border: rank == 0
          ? Border.all(color: PyraTheme.primaryYellow.withOpacity(0.5), width: 1.5)
          : Border.all(color: Colors.white.withOpacity(0.1)),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Text(rankEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Text(player.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '🍺 ${player.totalSips}',
                style: const TextStyle(
                    color: PyraTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Text(
                '😈 ${player.bluffsWon}w / ${player.bluffsLost}l',
                style: const TextStyle(
                    color: PyraTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 400 + rank * 80)).slideX();
  }
}

class _StatBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final Player player;
  final String value;
  final Color color;

  const _StatBadge({
    required this.emoji,
    required this.label,
    required this.player,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: color,
      opacity: 0.15,
      border: Border.all(color: color.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: PyraTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            '${player.emoji} ${player.name}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(value, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

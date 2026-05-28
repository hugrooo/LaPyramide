import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';
import '../models/player_model.dart';
import '../../../shared/widgets/glass_container.dart';

class SipScoreboardWidget extends StatelessWidget {
  final List<Player> players;

  const SipScoreboardWidget({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    // Trier par gorgées reçues, puis bluffs réussis
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) {
        int cmp = b.totalSips.compareTo(a.totalSips);
        if (cmp == 0) return b.bluffsWon.compareTo(a.bluffsWon);
        return cmp;
      });

    return GlassContainer(
      innerGlow: true,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: PyraTheme.primaryPink.withOpacity(0.5), width: 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🏆 Tableau des Scores',
            style: TextStyle(
              color: PyraTheme.primaryYellow,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          // En-têtes
          const Row(
            children: [
              Expanded(flex: 3, child: Text('Joueur', style: TextStyle(color: PyraTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Reçues 🍺', textAlign: TextAlign.center, style: TextStyle(color: PyraTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Données 🎯', textAlign: TextAlign.center, style: TextStyle(color: PyraTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Bluffs 🎭', textAlign: TextAlign.center, style: TextStyle(color: PyraTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          // Liste des joueurs
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: sortedPlayers.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final p = sortedPlayers[i];
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${p.totalSips}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: PyraTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${p.drinksGiven}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: PyraTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${p.bluffsWon}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: PyraTheme.primaryPink, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideX(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

void showScoreboard(BuildContext context, List<Player> players) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(ctx).padding.bottom + 16,
        top: 64,
      ),
      child: SipScoreboardWidget(players: players),
    ),
  );
}

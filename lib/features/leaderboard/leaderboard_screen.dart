import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'leaderboard_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _service = LeaderboardService();
  List<Map<String, dynamic>> _topDrinkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service.getLeaderboard().listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final list = data.entries.map((e) {
          final val = e.value as Map<dynamic, dynamic>;
          return {
            'id': e.key.toString(),
            'name': val['name']?.toString() ?? 'Inconnu',
            'totalSips': (val['totalSips'] as int?) ?? 0,
            'totalBluffs': (val['totalBluffs'] as int?) ?? 0,
          };
        }).toList();

        // Firebase limitToLast(50) retourne dans un ordre non garanti en Map, on trie localement
        list.sort((a, b) => (b['totalSips'] as int).compareTo(a['totalSips'] as int));

        setState(() {
          _topDrinkers = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          '🌍 Hall of Fame',
                          style: TextStyle(
                            color: PyraTheme.primaryYellow,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for centering
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPink))
                      : _topDrinkers.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun score pour le moment.\nJoue une partie en ligne pour apparaître ici !',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _topDrinkers.length,
                              itemBuilder: (context, index) {
                                final player = _topDrinkers[index];
                                final rank = index + 1;
                                return _buildRankCard(player, rank)
                                    .animate()
                                    .fadeIn(delay: (index * 100).ms)
                                    .slideX(begin: 0.2, end: 0);
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

  Widget _buildRankCard(Map<String, dynamic> player, int rank) {
    final rankEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
    final isTop3 = rank <= 3;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      color: isTop3 ? PyraTheme.primaryYellow : PyraTheme.bgCard,
      opacity: isTop3 ? 0.2 : 0.6,
      border: isTop3
          ? Border.all(color: PyraTheme.primaryYellow.withOpacity(0.5), width: 1.5)
          : Border.all(color: Colors.white.withOpacity(0.1)),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              rankEmoji,
              style: TextStyle(
                  fontSize: isTop3 ? 28 : 20,
                  fontWeight: FontWeight.bold,
                  color: isTop3 ? Colors.white : Colors.white54),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${player['totalBluffs']} bluffs réussis 😈',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player['totalSips']}',
                style: const TextStyle(
                  color: PyraTheme.primaryOrange,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'gorgées',
                style: TextStyle(color: PyraTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

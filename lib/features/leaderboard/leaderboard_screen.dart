import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/avatar_with_border.dart';
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
  StreamSubscription? _leaderboardSub;

  @override
  void initState() {
    super.initState();
    _leaderboardSub = _service.getGlobalLeaderboard().listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final list = data.entries.map((e) {
          final val = e.value as Map<dynamic, dynamic>;
          return {
            'id': e.key.toString(),
            'name': val['name']?.toString() ??
                val['pseudo']?.toString() ??
                'Inconnu',
            'emoji': val['emoji']?.toString() ?? '😎',
            'photoUrl': val['photoUrl']?.toString(),
            'selectedBorder': val['selectedBorder']?.toString() ?? 'classic',
            'xp': (val['xp'] as int?) ?? 0,
            'level': (val['level'] as int?) ?? 1,
            'totalSips': (val['totalSips'] as int?) ?? 0,
            'totalBluffs': (val['totalBluffs'] as int?) ?? 0,
          };
        }).toList();

        // Firebase limitToLast(100) retourne dans un ordre non garanti en Map, on trie localement
        list.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));

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
  void dispose() {
    _leaderboardSub?.cancel();
    super.dispose();
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: PyraTheme.primaryPink))
                      : _topDrinkers.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun score pour le moment.\nJoue une partie en ligne pour apparaître ici !',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : Column(
                              children: [
                                if (_topDrinkers.length >= 3)
                                  _buildPodium(_topDrinkers.take(3).toList()),
                                if (_topDrinkers.length < 3 &&
                                    _topDrinkers.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 24.0),
                                    child: _buildPodium(
                                      _topDrinkers,
                                      // On complète avec des vide s'il n'y en a pas 3
                                    ),
                                  ),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(
                                        left: 16, right: 16, bottom: 100),
                                    itemCount: _topDrinkers.length > 3
                                        ? _topDrinkers.length - 3
                                        : 0,
                                    itemBuilder: (context, index) {
                                      final player = _topDrinkers[index + 3];
                                      final rank = index + 4;
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
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    if (top3.isEmpty) return const SizedBox();

    final player1 = top3.isNotEmpty ? top3[0] : null;
    final player2 = top3.length > 1 ? top3[1] : null;
    final player3 = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (player2 != null)
            Expanded(
              child: _buildPodiumStep(player2, 2, 120, PyraTheme.primaryCyan),
            ),
          if (player2 == null) const Expanded(child: SizedBox()),
          if (player1 != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child:
                    _buildPodiumStep(player1, 1, 160, PyraTheme.primaryYellow),
              ),
            ),
          if (player3 != null)
            Expanded(
              child: _buildPodiumStep(player3, 3, 100, PyraTheme.primaryPink),
            ),
          if (player3 == null) const Expanded(child: SizedBox()),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutBack);
  }

  Widget _buildPodiumStep(
      Map<String, dynamic> player, int rank, double height, Color color) {
    final String name = player['name'] ?? 'Inconnu';
    final String emoji = player['emoji'] ?? '😎';
    final String? photoUrl = player['photoUrl'];
    final String selectedBorder = player['selectedBorder'] ?? 'classic';
    final int xp = player['xp'] ?? 0;
    final int level = player['level'] ?? 1;
    final int totalSips = player['totalSips'] ?? 0;
    final int totalBluffs = player['totalBluffs'] ?? 0;

    final isFirst = rank == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isFirst)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.star_rounded,
                  color: PyraTheme.primaryYellow, size: 32),
            ),
          AvatarWithBorder(
            emoji: emoji,
            photoUrl: photoUrl,
            size: isFirst ? 60 : 48,
            borderType: selectedBorder,
            showLevel: true,
            level: level,
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rank',
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '$xp XP',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Niv. $level',
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                if (totalSips > 0 || totalBluffs > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🥤 $totalSips  🃏 $totalBluffs',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(Map<String, dynamic> player, int rank) {
    final String name = player['name'] ?? 'Inconnu';
    final String emoji = player['emoji'] ?? '😎';
    final String? photoUrl = player['photoUrl'];
    final String selectedBorder = player['selectedBorder'] ?? 'classic';
    final int xp = player['xp'] ?? 0;
    final int level = player['level'] ?? 1;
    final int totalSips = player['totalSips'] ?? 0;
    final int totalBluffs = player['totalBluffs'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AvatarWithBorder(
              emoji: emoji,
              photoUrl: photoUrl,
              size: 40,
              borderType: selectedBorder,
              showLevel: false,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Niv. $level',
                    style: const TextStyle(
                        color: PyraTheme.primaryCyan, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (totalSips > 0 || totalBluffs > 0)
                  Text(
                    '🥤 $totalSips  🃏 $totalBluffs',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/animated_background.dart';
import '../game/models/player_model.dart';
import '../game/models/game_state.dart';

import '../../shared/widgets/pulsar_button.dart';
import '../../shared/widgets/glass_container.dart';
import '../game/online/online_game_service.dart';

// ─── Particule de confetti légère ──────────────────────
class _ConfettiParticle {
  final double x;
  final double startY;
  final double size;
  final Color color;
  final double rotation;
  final double speed;
  final bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.speed,
    required this.isCircle,
  });
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;

  static const _colors = [
    PyraTheme.primaryYellow,
    PyraTheme.primaryPink,
    PyraTheme.primaryCyan,
    PyraTheme.primaryPurple,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Génère seulement 25 particules (léger et élégant)
    final rnd = Random();
    _particles = List.generate(25, (i) {
      return _ConfettiParticle(
        x: rnd.nextDouble(),
        startY: -0.05 - rnd.nextDouble() * 0.3,
        size: 6 + rnd.nextDouble() * 8,
        color: _colors[rnd.nextInt(_colors.length)],
        rotation: rnd.nextDouble() * 2 * pi,
        speed: 0.4 + rnd.nextDouble() * 0.6,
        isCircle: rnd.nextBool(),
      );
    });

    // Lance l'animation et ne la répète pas
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Fondu des confettis après 3.5 secondes
        final opacity = _controller.value < 0.7
            ? 1.0
            : (1.0 - (_controller.value - 0.7) / 0.3).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: CustomPaint(
            painter: _ConfettiPainter(_particles, _controller.value),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final x = p.x * size.width + sin(t * pi * 3 + p.rotation) * 30;
      final y = (p.startY + t * 1.5) * size.height;

      if (y > size.height) continue;

      final paint = Paint()..color = p.color.withOpacity(0.85);
      final angle = p.rotation + t * pi * 4;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size / 2),
            const Radius.circular(2),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ─── Écran Scoreboard ──────────────────────────────────
class ScoreboardScreen extends ConsumerWidget {
  final List<Player> players;
  final bool isOnline;
  final String? roomCode;

  const ScoreboardScreen({
    super.key,
    required this.players,
    this.isOnline = false,
    this.roomCode,
  });

  Player get _mostDrunk =>
      players.reduce((a, b) => a.totalSips >= b.totalSips ? a : b);

  Player get _bestBluffer =>
      players.reduce((a, b) => a.bluffsWon >= b.bluffsWon ? a : b);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...players]..sort((a, b) => b.totalSips.compareTo(a.totalSips));
    final service = ref.read(onlineGameServiceProvider);

    if (isOnline && roomCode != null) {
      ref.listen(onlineGameStateProvider, (previous, next) {
        if (next.value != null && next.value!.phase == GamePhase.setup) {
          if (context.mounted) {
            context.goNamed('onlineLobby');
          }
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),

          // Confettis élégants (25 particules max)
          const _ConfettiOverlay(),

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
                  ).animate().fadeIn(duration: 400.ms).scale(curve: Curves.easeOutBack),

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

                  if (isOnline && roomCode != null) ...[
                    // Mode En Ligne : bouton Rejouer (remet le salon en lobby)
                    SizedBox(
                      width: double.infinity,
                      child: PulsarButton(
                        text: '🔄 Rejouer avec le même groupe',
                        gradient: PyraTheme.purplePinkGradient,
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          try {
                            await service.restartRoom(roomCode!);
                            if (context.mounted) {
                              context.goNamed('onlineLobby');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        // Nettoyer le code salon avant de rentrer à l'accueil
                        ref.read(currentRoomCodeProvider.notifier).state = null;
                        await service.leaveRoom(roomCode!);
                        if (context.mounted) context.goNamed('home');
                      },
                      child: const Text(
                        '🏠 Retour à l\'accueil',
                        style: TextStyle(color: PyraTheme.textSecondary),
                      ),
                    ),
                  ] else ...[
                    // Mode Local
                    PulsarButton(
                      text: '🎲 ${l10n.scoreboard_play_again}',
                      gradient: PyraTheme.purplePinkGradient,
                      onPressed: () => context.goNamed('localLobby'),
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
            value: '${_mostDrunk.totalSips} pénalités',
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

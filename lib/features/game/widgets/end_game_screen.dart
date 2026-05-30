import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../online/online_game_service.dart';
import '../../../shared/widgets/playing_card_widget.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pulsar_button.dart';
import '../../../core/audio/audio_manager.dart';

// ─── Confettis légers (25 particules, animation 5s puis fondu) ─────────────
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

    final rnd = Random();
    _particles = List.generate(25, (i) => _ConfettiParticle(
      x: rnd.nextDouble(),
      startY: -0.05 - rnd.nextDouble() * 0.3,
      size: 6 + rnd.nextDouble() * 8,
      color: _colors[rnd.nextInt(_colors.length)],
      rotation: rnd.nextDouble() * 2 * pi,
      speed: 0.4 + rnd.nextDouble() * 0.6,
      isCircle: rnd.nextBool(),
    ));

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
        final opacity = _controller.value < 0.7
            ? 1.0
            : (1.0 - (_controller.value - 0.7) / 0.3).clamp(0.0, 1.0);
        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              painter: _ConfettiPainter(_particles, _controller.value),
              child: const SizedBox.expand(),
            ),
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

// ─── Écran Fin de Partie ────────────────────────────────────────────────────
class EndGameScreen extends ConsumerStatefulWidget {
  final GameState state;
  final String currentUserId;

  const EndGameScreen({
    super.key,
    required this.state,
    required this.currentUserId,
  });

  @override
  ConsumerState<EndGameScreen> createState() => _EndGameScreenState();
}

class _EndGameScreenState extends ConsumerState<EndGameScreen> {
  final Set<int> _revealedCards = {};
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    if (widget.state.endGamePlayerIndex >= widget.state.players.length) {
      _showConfetti = true;
      AudioManager().playVictory();
    }
  }

  @override
  void didUpdateWidget(covariant EndGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.endGamePlayerIndex != widget.state.endGamePlayerIndex) {
      _revealedCards.clear();
    }

    if (oldWidget.state.endGamePlayerIndex < oldWidget.state.players.length &&
        widget.state.endGamePlayerIndex >= widget.state.players.length) {
      setState(() => _showConfetti = true);
      AudioManager().playVictory();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.endGamePlayerIndex >= widget.state.players.length) {
      return _buildScoreboard(context);
    }

    final activePlayer = widget.state.players[widget.state.endGamePlayerIndex];
    final isMyTurn = activePlayer.id == widget.currentUserId;

    return Column(
      children: [
        const SizedBox(height: 32),
        const Text(
          'FIN DE PARTIE',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: PyraTheme.primaryOrange,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isMyTurn ? 'C\'est à toi de réciter tes cartes !' : 'Au tour de ${activePlayer.name} ${activePlayer.emoji} !',
          style: TextStyle(
            fontSize: 22,
            color: isMyTurn ? Colors.white : PyraTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),

        // Affichage de la main
        Wrap(
          spacing: 12,
          children: List.generate(activePlayer.hand.length, (index) {
            final card = activePlayer.hand[index];
            final isRevealed = _revealedCards.contains(index);
            return GestureDetector(
              onTap: isMyTurn && !isRevealed
                  ? () => setState(() => _revealedCards.add(index))
                  : null,
              child: SizedBox(
                width: 70, height: 100,
                child: PlayingCardWidget(card: card, faceUp: isRevealed),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        if (isMyTurn) ...[
          const Text('As-tu bien deviné la carte ?', style: TextStyle(color: PyraTheme.textMuted)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {},
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Bon', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryPink),
                onPressed: () {
                  final roomCode = widget.state.gameId;
                  ref.read(onlineGameServiceProvider).addPenalty(roomCode, widget.currentUserId);
                },
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text('Faux (+2 pénalités)', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PyraTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            onPressed: () {
              final roomCode = widget.state.gameId;
              ref.read(onlineGameServiceProvider).nextEndGamePlayer(roomCode);
            },
            child: const Text('J\'ai fini ! Au suivant', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ] else ...[
          const CircularProgressIndicator(color: PyraTheme.primaryPurple),
          const SizedBox(height: 16),
          Text('${activePlayer.name} révèle ses cartes...', style: const TextStyle(color: PyraTheme.textMuted)),
        ],

        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildScoreboard(BuildContext context) {
    final sortedPlayers = List.of(widget.state.players)..sort((a, b) => b.totalSips.compareTo(a.totalSips));
    final roomCode = widget.state.gameId;
    final service = ref.read(onlineGameServiceProvider);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              '🏆 RÉSULTATS FINAUX 🏆',
              style: TextStyle(fontSize: 26, color: PyraTheme.primaryYellow, fontWeight: FontWeight.w900),
            ).animate().fadeIn(duration: 400.ms).scale(curve: Curves.easeOutBack),
            const SizedBox(height: 20),

            // Classement
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedPlayers.length,
                itemBuilder: (context, index) {
                  final player = sortedPlayers[index];
                  final rankEmoji = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '${index + 1}.';
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: index == 0 ? PyraTheme.primaryYellow : PyraTheme.bgCard,
                    opacity: index == 0 ? 0.2 : 0.6,
                    border: index == 0
                        ? Border.all(color: PyraTheme.primaryYellow.withOpacity(0.5), width: 1.5)
                        : Border.all(color: Colors.white.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Text(rankEmoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Text(player.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Text('${player.totalSips} 🍺', style: const TextStyle(color: PyraTheme.primaryOrange, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 300 + index * 80)).slideX();
                },
              ),
            ),

            // Bouton Rejouer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: PulsarButton(
                  text: '🔄 Rejouer avec le même groupe',
                  gradient: PyraTheme.purplePinkGradient,
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    try {
                      await service.restartRoom(roomCode);
                      if (context.mounted) {
                        // Rester sur la route onlineGame — Firebase va pusher le nouvel état setup
                        // Le lobby est géré par OnlineLobbyScreen
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
            ),

            // Bouton Quitter
            Padding(
              padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
              child: TextButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  // Nettoyer le code salon AVANT de naviguer → évite le bug "salon fermé"
                  ref.read(currentRoomCodeProvider.notifier).state = null;
                  await service.leaveRoom(roomCode);
                  if (context.mounted) context.goNamed('home');
                },
                child: const Text(
                  '🏠 Retour à l\'accueil',
                  style: TextStyle(color: PyraTheme.textSecondary, fontSize: 16),
                ),
              ),
            ),
          ],
        ),

        // Confettis légers
        if (_showConfetti) const _ConfettiOverlay(),
      ],
    );
  }
}

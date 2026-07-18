import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../widgets/pyramid_widget.dart';
import 'online_game_service.dart';

/// Spectator screen: read-only view of an ongoing online game.
class SpectatorScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const SpectatorScreen({super.key, required this.roomCode});

  @override
  ConsumerState<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends ConsumerState<SpectatorScreen> {
  final List<_ReactionBubble> _reactions = [];

  @override
  void initState() {
    super.initState();
    // Set the room code so the stream provider picks it up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentRoomCodeProvider.notifier).state = widget.roomCode;
    });
  }

  void _sendReaction(String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      _reactions.add(_ReactionBubble(
        emoji: emoji,
        key: UniqueKey(),
      ));
    });
    // Remove after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _reactions.removeWhere((r) => r.key == _reactions.firstOrNull?.key);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameStateAsync = ref.watch(onlineGameStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Top bar with SPECTATEUR badge
                _buildTopBar(context),
                // Game content
                Expanded(
                  child: gameStateAsync.when(
                    data: (state) {
                      if (state == null) {
                        return _buildNoGame();
                      }
                      return _buildGameView(state);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: PyraTheme.primaryPurple),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Erreur: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
                // Reactions bar at bottom
                _buildReactionsBar(),
              ],
            ),
          ),
          // Floating reaction bubbles
          ..._reactions.map((r) => Positioned(
                bottom: 100,
                left: MediaQuery.of(context).size.width / 2 - 20,
                child: Text(r.emoji, style: const TextStyle(fontSize: 40))
                    .animate()
                    .slideY(begin: 0, end: -3, duration: 1500.ms)
                    .fadeOut(delay: 1000.ms, duration: 500.ms),
              )),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(currentRoomCodeProvider.notifier).state = null;
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: PyraTheme.purplePinkGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: PyraTheme.primaryPurple.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'SPECTATEUR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
          const Spacer(),
          // Room code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.roomCode,
              style: const TextStyle(
                color: PyraTheme.primaryOrange,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGame() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_rounded,
              color: PyraTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          const Text(
            'La partie n\'existe plus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le salon a ete supprime ou la partie est terminee.',
            style: TextStyle(color: PyraTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameView(GameState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Phase indicator
          _buildPhaseIndicator(state),
          const SizedBox(height: 16),
          // Pyramid view (read-only)
          if (state.phase != GamePhase.setup &&
              state.phase != GamePhase.distribution)
            _buildPyramidSection(state),
          // Current event
          if (state.lastEventMessage != null &&
              state.lastEventMessage!.isNotEmpty)
            _buildEventBanner(state.lastEventMessage!),
          const SizedBox(height: 16),
          // Players scoreboard
          _buildPlayersSection(state),
          const SizedBox(height: 16),
          // Pending drinks
          if (state.pendingDrinks.isNotEmpty) _buildPendingDrinks(state),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(GameState state) {
    final phaseText = _phaseToText(state.phase);
    final phaseColor = _phaseToColor(state.phase);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: phaseColor.withValues(alpha: 0.4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: phaseColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: phaseColor.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            phaseText,
            style: TextStyle(
              color: phaseColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPyramidSection(GameState state) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      child: Column(
        children: [
          const Text(
            'LA PYRAMIDE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          PyramidWidget(
            pyramid: state.pyramid,
            currentRow: state.currentRow,
            currentCardIndex: state.currentCardIndex,
            phase: state.phase,
            onRevealCard: null,
          ),
        ],
      ),
    );
  }

  Widget _buildEventBanner(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PyraTheme.primaryYellow.withValues(alpha: 0.3)),
        child: Row(
          children: [
            const Text('📢', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1);
  }

  Widget _buildPlayersSection(GameState state) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JOUEURS',
            style: TextStyle(
              color: PyraTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...state.players.map((player) => _buildPlayerRow(player)),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Player player) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(player.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (player.activeTitle.isNotEmpty)
                  Text(
                    player.activeTitle,
                    style: const TextStyle(
                      color: PyraTheme.primaryCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PyraTheme.primaryOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${player.totalSips} pen.',
              style: const TextStyle(
                color: PyraTheme.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDrinks(GameState state) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PyraTheme.primaryPink.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PENALITES EN COURS',
            style: TextStyle(
              color: PyraTheme.primaryPink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...state.pendingDrinks.map((drink) {
            final from = state.players
                .where((p) => p.id == drink.fromPlayerId)
                .firstOrNull;
            final to = state.players
                .where((p) => p.id == drink.toPlayerId)
                .firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${from?.name ?? "?"} -> ${to?.name ?? "?"} (${drink.sips} pen.)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReactionsBar() {
    const reactions = ['😂', '🔥', '😱', '👏'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: PyraTheme.bgCard.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((emoji) {
          return GestureDetector(
            onTap: () => _sendReaction(emoji),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _phaseToText(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup:
        return 'En attente';
      case GamePhase.distribution:
        return 'Le Bus';
      case GamePhase.revealing:
        return 'Revelation';
      case GamePhase.assigning:
        return 'Attribution';
      case GamePhase.bluffing:
        return 'Bluff en cours';
      case GamePhase.transition:
        return 'Transition';
      case GamePhase.miniGame:
        return 'Mini-Jeu';
      case GamePhase.finished:
        return 'Partie terminee';
    }
  }

  Color _phaseToColor(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup:
        return PyraTheme.textMuted;
      case GamePhase.distribution:
        return PyraTheme.primaryCyan;
      case GamePhase.revealing:
        return PyraTheme.primaryGreen;
      case GamePhase.assigning:
        return PyraTheme.primaryOrange;
      case GamePhase.bluffing:
        return PyraTheme.primaryPink;
      case GamePhase.transition:
        return PyraTheme.primaryPurple;
      case GamePhase.miniGame:
        return PyraTheme.primaryYellow;
      case GamePhase.finished:
        return PyraTheme.primaryYellow;
    }
  }
}

class _ReactionBubble {
  final String emoji;
  final Key key;

  _ReactionBubble({required this.emoji, required this.key});
}

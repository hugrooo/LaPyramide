import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/animated_background.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../models/card_model.dart';
import '../game_logic.dart';
import '../widgets/pyramid_widget.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/drink_and_bluff_widgets.dart';

/// Provider de l'état du jeu local
final localGameProvider =
    StateNotifierProvider.autoDispose<LocalGameNotifier, GameState?>(
  (ref) => LocalGameNotifier(),
);

class LocalGameNotifier extends StateNotifier<GameState?> {
  LocalGameNotifier() : super(null);

  void initGame(List<Player> players, GameSettings settings) {
    state = GameLogic.initGame(players: players, settings: settings);
  }

  void revealCard() {
    if (state == null) return;
    state = GameLogic.revealCurrentCard(state!);
  }

  void assignDrink(String fromId, String toId, PyraCard? card) {
    if (state == null) return;
    state = GameLogic.assignDrink(
      state: state!,
      fromPlayerId: fromId,
      toPlayerId: toId,
    );
  }

  void callBluff() {
    if (state == null) return;
    state = GameLogic.callBluff(state!);
  }

  void resolveBluff(String fromId, String? cardId) {
    if (state == null) return;
    state = GameLogic.resolveBluff(state: state!, fromPlayerId: fromId, cardId: cardId);
  }

  void acceptDrink() {
    if (state == null) return;
    state = GameLogic.acceptDrink(state!);
  }

  void usePower(String playerId, String cardId) {
    if (state == null) return;
    state = GameLogic.usePower(state: state!, playerId: playerId, cardId: cardId);
  }

  void nextCard() {
    if (state == null) return;
    state = GameLogic.nextCard(state!);
  }
}

class LocalGameScreen extends ConsumerStatefulWidget {
  final List<Player> players;
  final GameSettings settings;

  const LocalGameScreen({
    super.key,
    required this.players,
    required this.settings,
  });

  @override
  ConsumerState<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends ConsumerState<LocalGameScreen> {
  int _currentPlayerIndex = 0;
  PyraCard? _selectedCard;
  String? _assignToPlayerId;
  bool _showPassPhone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localGameProvider.notifier).initGame(widget.players, widget.settings);
    });
  }

  Player get currentPlayer =>
      ref.read(localGameProvider)!.players[_currentPlayerIndex];

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(localGameProvider);
    if (gameState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Redirection vers le scoreboard si partie terminée
    if (gameState.phase == GamePhase.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.goNamed('scoreboard', extra: {'players': gameState.players});
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: _buildGameContent(context, gameState),
          ),

          // Overlay boire
          if (gameState.phase == GamePhase.transition &&
              gameState.players.isNotEmpty)
            _buildDrinkOverlay(gameState),

          // Dialog bluff
          if (gameState.phase == GamePhase.bluffing &&
              gameState.pendingDrinks.isNotEmpty)
            _buildBluffDialog(gameState),

          // Écran de passage de téléphone
          if (_showPassPhone)
            _buildPassPhoneScreen(gameState),
        ],
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, GameState gameState) {
    return Column(
      children: [
        // Header : scores joueurs
        _buildPlayersHeader(gameState),

        const SizedBox(height: 8),

        // Pyramide
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: PyramidWidget(
                pyramid: gameState.pyramid,
                currentRow: gameState.currentRow,
                currentCardIndex: gameState.currentCardIndex,
                phase: gameState.phase,
                onRevealCard: () {
                  HapticFeedback.mediumImpact();
                  ref.read(localGameProvider.notifier).revealCard();
                },
              ),
            ),
          ),
        ),

        const Divider(color: Colors.white12),

        // Zone du joueur actif
        _buildCurrentPlayerZone(context, gameState),
      ],
    );
  }

  Widget _buildPlayersHeader(GameState gameState) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gameState.players.length,
        itemBuilder: (context, i) {
          final player = gameState.players[i];
          final isActive = i == _currentPlayerIndex;
          return _PlayerChip(
            player: player,
            isActive: isActive,
            onTap: () => setState(() => _assignToPlayerId = player.id),
            isTargeted: _assignToPlayerId == player.id,
          );
        },
      ),
    );
  }

  Widget _buildCurrentPlayerZone(BuildContext context, GameState gameState) {
    final player = currentPlayer;
    final isAssigning = gameState.phase == GamePhase.assigning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PyraTheme.bgCard.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nom du joueur actif
          Text(
            '${player.emoji} ${player.name}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),

          // Main du joueur
          PlayerHandWidget(
            player: player,
            isInteractive: isAssigning,
            selectedCard: _selectedCard,
            onCardSelected: (card) => setState(() => _selectedCard = card),
          ),

          if (isAssigning && _assignToPlayerId != null) ...[
            const SizedBox(height: 16),
            _buildAssignButton(gameState),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignButton(GameState gameState) {
    final target = gameState.players
        .firstWhere((p) => p.id == _assignToPlayerId);

    return GestureDetector(
      onTap: () {
        ref.read(localGameProvider.notifier).assignDrink(
              currentPlayer.id,
              _assignToPlayerId!,
              null,
            );
        setState(() {
          _selectedCard = null;
          _assignToPlayerId = null;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: PyraTheme.orangeYellowGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: PyraTheme.glowOrange,
        ),
        child: Text(
          'Envoyer ${gameState.currentSips} 🍺 à ${target.emoji} ${target.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkOverlay(GameState gameState) {
    // Trouver le joueur qui doit boire (le dernier qui a reçu des gorgées)
    final player = gameState.players.reduce(
        (a, b) => a.totalSips > b.totalSips ? a : b);

    return DrinkOverlay(
      player: player,
      sips: gameState.currentSips,
      onDismiss: () {
        // Passer au joueur suivant
        setState(() {
          _currentPlayerIndex =
              (_currentPlayerIndex + 1) % gameState.players.length;
          _showPassPhone = true;
        });
        ref.read(localGameProvider.notifier).nextCard();
      },
    );
  }

  Widget _buildBluffDialog(GameState gameState) {
    final assignment = gameState.pendingDrinks.last;
    final accuser = gameState.players.firstWhere(
        (p) => p.id == assignment.fromPlayerId);
    final accused = gameState.players.firstWhere(
        (p) => p.id == assignment.toPlayerId);
        
    // Récupérer les pouvoirs du joueur ciblé
    final availablePowers = accused.hand.where((c) => c.powerType != PowerType.none).toList();

    return Material(
      color: Colors.transparent,
      child: BluffDialog(
        accuser: accuser,
        accused: accused,
        sips: assignment.sips,
        availablePowers: availablePowers,
        onChallenge: () => ref.read(localGameProvider.notifier).callBluff(),
        onAccept: () => ref.read(localGameProvider.notifier).acceptDrink(),
        onUsePower: (cardId) => ref.read(localGameProvider.notifier).usePower(accused.id, cardId),
      ),
    );
  }

  Widget _buildPassPhoneScreen(GameState gameState) {
    final nextPlayer = gameState.players[_currentPlayerIndex];
    return GestureDetector(
      onTap: () => setState(() => _showPassPhone = false),
      child: Container(
        color: PyraTheme.bgDark.withOpacity(0.95),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📱', style: TextStyle(fontSize: 60))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shake(),
              const SizedBox(height: 24),
              Text(
                'Passe le téléphone à',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: PyraTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${nextPlayer.emoji} ${nextPlayer.name}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: PyraTheme.primaryPurple,
                    ),
              ).animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 48),
              Text(
                'Appuie pour continuer',
                style: Theme.of(context).textTheme.bodyMedium,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn()
                  .then()
                  .fadeOut(duration: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final Player player;
  final bool isActive;
  final bool isTargeted;
  final VoidCallback onTap;

  const _PlayerChip({
    required this.player,
    required this.isActive,
    required this.isTargeted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? PyraTheme.purplePinkGradient
              : isTargeted
                  ? PyraTheme.orangeYellowGradient
                  : null,
          color: isActive || isTargeted ? null : PyraTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? PyraTheme.glowPurple : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(player.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '🍺 ${player.totalSips}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

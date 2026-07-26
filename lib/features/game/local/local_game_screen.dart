import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../auth/auth_service.dart';
import '../../../app/theme.dart';
import '../../../core/security/screen_protection.dart';
import '../../../shared/widgets/animated_background.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../models/card_model.dart';
import '../game_logic.dart';
import '../widgets/pyramid_widget.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/drink_and_bluff_widgets.dart';
import '../../profile/user_profile_provider.dart';
import '../../../shared/widgets/pulsar_button.dart';

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

  void assignDrinkSplit(String fromId, List<String> toIds, int totalSips) {
    if (state == null) return;
    state = GameLogic.assignDrinkSplit(
      state: state!,
      fromPlayerId: fromId,
      toPlayerIds: toIds,
      totalSips: totalSips,
    );
  }

  void callBluff() {
    if (state == null) return;
    state = GameLogic.callBluff(state!);
  }

  void resolveBluff(String fromId, String? cardId) {
    if (state == null) return;
    state = GameLogic.resolveBluff(
        state: state!, fromPlayerId: fromId, cardId: cardId);
  }

  void acceptDrink() {
    if (state == null) return;
    state = GameLogic.acceptDrink(state!);
  }

  void usePower(String playerId, String cardId) {
    if (state == null) return;
    state =
        GameLogic.usePower(state: state!, playerId: playerId, cardId: cardId);
  }

  void useJoker(String jokerId, String playerId) {
    if (state == null) return;
    state =
        GameLogic.useJoker(state: state!, playerId: playerId, jokerId: jokerId);
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
  final Set<String> _assignToPlayerIds = {};
  bool _splitMode = false;
  bool _showPassPhone = false;
  bool _navigatedToScoreboard = false;

  @override
  void initState() {
    super.initState();
    ScreenProtection.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(localGameProvider.notifier)
          .initGame(widget.players, widget.settings);
    });
  }

  @override
  void dispose() {
    ScreenProtection.disable();
    super.dispose();
  }

  Player get currentPlayer =>
      ref.read(localGameProvider)!.players[_currentPlayerIndex];

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(localGameProvider);
    if (gameState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Écouter le changement d'état pour incrémenter le nombre de parties jouées à la fin de la partie locale
    ref.listen<GameState?>(localGameProvider, (previous, next) {
      if (next != null &&
          next.phase == GamePhase.finished &&
          (previous == null || previous.phase != GamePhase.finished)) {
        final user = ref.read(authServiceProvider).currentUser;
        if (user != null) {
          // XP : 30 base + 5 par penalité distribuée + 10 par bluff gagné
          final me = next.players.isNotEmpty ? next.players.first : null;
          final xpDrinks = (me?.drinksGiven ?? 0) * 5;
          final xpBluffs = (me?.bluffsWon ?? 0) * 10;
          // Coins: 10 base + 2 per penalty given + 3 per bluff won
          final coinsDrinks = (me?.drinksGiven ?? 0) * 2;
          final coinsBluffs = (me?.bluffsWon ?? 0) * 3;
          final totalCoins = 10 + coinsDrinks + coinsBluffs;
          UserProfile.addGameRewards(user.uid, 30 + xpDrinks + xpBluffs, me?.drinksGiven ?? 0, me?.bluffsWon ?? 0,
              addedCoins: totalCoins);
        }
      }
    });

    // Redirection vers le scoreboard si partie terminée
    if (gameState.phase == GamePhase.finished && !_navigatedToScoreboard) {
      _navigatedToScoreboard = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.goNamed('scoreboard', extra: {
            'players': gameState.players,
            'settings': gameState.settings,
          });
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: _buildGameContent(context, gameState),
          ),

          // Overlay prendre
          if (gameState.phase == GamePhase.transition &&
              gameState.players.isNotEmpty)
            _buildDrinkOverlay(gameState),

          // Dialog bluff
          if (gameState.phase == GamePhase.bluffing &&
              gameState.pendingDrinks.isNotEmpty)
            _buildBluffDialog(gameState),

          // Écran de passage de téléphone
          if (_showPassPhone) _buildPassPhoneScreen(gameState),
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
          final isTargeted = _splitMode
              ? _assignToPlayerIds.contains(player.id)
              : _assignToPlayerId == player.id;
          return _PlayerChip(
            player: player,
            isActive: isActive,
            onTap: () {
              if (player.id == currentPlayer.id) return;
              setState(() {
                if (_splitMode) {
                  if (_assignToPlayerIds.contains(player.id)) {
                    _assignToPlayerIds.remove(player.id);
                  } else {
                    _assignToPlayerIds.add(player.id);
                  }
                } else {
                  _assignToPlayerId = player.id;
                }
              });
            },
            isTargeted: isTargeted,
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

          if (isAssigning) ...[
            const SizedBox(height: 12),
            // Toggle split mode
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _splitMode = !_splitMode;
                      if (_splitMode) {
                        if (_assignToPlayerId != null) {
                          _assignToPlayerIds.add(_assignToPlayerId!);
                          _assignToPlayerId = null;
                        }
                      } else {
                        _assignToPlayerIds.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _splitMode
                          ? PyraTheme.primaryCyan.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _splitMode
                            ? PyraTheme.primaryCyan
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.call_split_rounded,
                          color: _splitMode ? PyraTheme.primaryCyan : Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Diviser',
                          style: TextStyle(
                            color: _splitMode ? PyraTheme.primaryCyan : Colors.white54,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if ((_splitMode && _assignToPlayerIds.isNotEmpty) ||
                (!_splitMode && _assignToPlayerId != null)) ...[
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, child) {
                  final profileAsync = ref.watch(userProfileProvider);
                  final profile = profileAsync.value;
                  if (profile == null) return const SizedBox();

                  final int doubleDoseCount = profile.jokers['double_dose'] ?? 0;
                  if (doubleDoseCount == 0) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PulsarButton(
                      text: '🧪 Activer Joker Double Dose (x$doubleDoseCount)',
                      fontSize: 12,
                      gradient: PyraTheme.purplePinkGradient,
                      onPressed: () async {
                        HapticFeedback.mediumImpact();

                        final user = ref.read(authStateChangesProvider).value;
                        if (user != null) {
                          await FirebaseDatabase.instance
                              .ref('users/${user.uid}/jokers/double_dose')
                              .set(doubleDoseCount - 1);
                        }

                        if (mounted) {
                          ref
                              .read(localGameProvider.notifier)
                              .useJoker('double_dose', currentPlayer.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Double Dose activé ! Pénalités doublées !'),
                                backgroundColor: Colors.purpleAccent),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              _buildAssignButton(gameState),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAssignButton(GameState gameState) {
    if (_splitMode) {
      final targets = gameState.players
          .where((p) => _assignToPlayerIds.contains(p.id))
          .toList();
      final totalSips = gameState.currentSips;
      final perPlayer = (totalSips / targets.length).ceil();
      final targetNames = targets.map((t) => t.emoji).join(' ');

      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          ref.read(localGameProvider.notifier).assignDrinkSplit(
                currentPlayer.id,
                _assignToPlayerIds.toList(),
                totalSips,
              );
          setState(() {
            _selectedCard = null;
            _assignToPlayerIds.clear();
            _splitMode = false;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: PyraTheme.cyanGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: PyraTheme.glowCyan,
          ),
          child: Text(
            'Diviser $totalSips 🎯 → $perPlayer chacun à $targetNames',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final target =
        gameState.players.firstWhere((p) => p.id == _assignToPlayerId);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
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
          'Envoyer ${gameState.currentSips} 🎯 à ${target.emoji} ${target.name}',
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
    // Trouver le joueur qui doit prendre (le dernier qui a reçu des pénalités)
    final player =
        gameState.players.reduce((a, b) => a.totalSips > b.totalSips ? a : b);

    return DrinkOverlay(
      player: player,
      sips: gameState.currentSips,
      message: gameState.lastEventMessage,
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
    final accuser =
        gameState.players.firstWhere((p) => p.id == assignment.fromPlayerId);
    final accused =
        gameState.players.firstWhere((p) => p.id == assignment.toPlayerId);

    // Récupérer les pouvoirs du joueur ciblé
    final availablePowers =
        accused.hand.where((c) => c.powerType != PowerType.none).toList();

    return Material(
      color: Colors.transparent,
      child: BluffDialog(
        accuser: accuser,
        accused: accused,
        sips: assignment.sips,
        availablePowers: availablePowers,
        onChallenge: () => ref.read(localGameProvider.notifier).callBluff(),
        onAccept: () => ref.read(localGameProvider.notifier).acceptDrink(),
        onUsePower: (cardId) =>
            ref.read(localGameProvider.notifier).usePower(accused.id, cardId),
        onUseJoker: (jokerId) {
          ref.read(localGameProvider.notifier).useJoker(jokerId, accused.id);
        },
        isBluffCalled: assignment.isBluffCalled,
        cardsToProve: accuser.hand,
        onResolveBluff: (cardId) {
          ref
              .read(localGameProvider.notifier)
              .resolveBluff(assignment.fromPlayerId, cardId);
        },
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
                  '🎯 ${player.totalSips}',
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

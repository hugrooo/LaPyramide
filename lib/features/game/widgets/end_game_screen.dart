import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../models/game_state.dart';
import '../online/online_game_service.dart';
import '../../../shared/widgets/playing_card_widget.dart';

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

  @override
  void didUpdateWidget(covariant EndGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.endGamePlayerIndex != widget.state.endGamePlayerIndex) {
      _revealedCards.clear(); // Reset revealed cards when player changes
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
                onPressed: () {}, // Ne fait rien, c'est juste visuel
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
                label: const Text('Faux (+2 gorgées)', style: TextStyle(color: Colors.white)),
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
    
    return Column(
      children: [
        const SizedBox(height: 32),
        const Text('🏆 RÉSULTATS FINAUX 🏆', style: TextStyle(fontSize: 28, color: PyraTheme.primaryYellow)),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.builder(
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: PyraTheme.primaryPurple,
                  child: Text(player.emoji),
                ),
                title: Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 20)),
                trailing: Text('${player.totalSips} 🍺', style: const TextStyle(color: PyraTheme.primaryPink, fontSize: 20, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: PyraTheme.primaryOrange,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          onPressed: () {
            ref.read(onlineGameServiceProvider).leaveRoom(widget.state.gameId);
            context.goNamed('home');
          },
          child: const Text('Quitter le salon', style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

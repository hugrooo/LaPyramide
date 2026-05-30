import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../online/online_game_service.dart';
import '../distribution_logic.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/playing_card_widget.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pulsar_button.dart';

class DistributionScreen extends ConsumerWidget {
  final GameState state;
  final String currentUserId;

  const DistributionScreen({
    super.key,
    required this.state,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerIndex = state.currentDistributionPlayerIndex;
    final cardIndex = state.currentDistributionCardIndex;
    final activePlayer = state.players[playerIndex];
    final isMyTurn = activePlayer.id == currentUserId;

    return Column(
      children: [
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => PyraTheme.festiveGradient.createShader(bounds),
          child: Text(
            'LE BUS - CARTE ${cardIndex + 1}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ).animate().slideY(begin: -0.3, duration: 400.ms).fadeIn(),
        const SizedBox(height: 8),
        Text(
          isMyTurn ? 'C\'est à toi de jouer !' : 'Au tour de ${activePlayer.name} ${activePlayer.emoji}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
            color: isMyTurn ? Colors.white : PyraTheme.textSecondary,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),

        // Affichage de la main actuelle du joueur actif
        Wrap(
          spacing: 8,
          children: activePlayer.hand.asMap().entries.map((e) => SizedBox(
            width: 65, height: 95, 
            child: PlayingCardWidget(card: e.value, faceUp: e.value.isFaceUp)
          ).animate()
           .fadeIn(delay: Duration(milliseconds: e.key * 150))
           .slideX(begin: 0.2, curve: Curves.easeOutBack)).toList(),
        ),

        const Spacer(),

        // Question
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          border: Border.all(color: PyraTheme.primaryOrange.withOpacity(0.5), width: 2),
          child: Text(
            _getQuestion(cardIndex),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 32),

        // Choix ou Distribution
        if (state.pendingDrinks.isNotEmpty && state.pendingDrinks.first.toPlayerId.isEmpty)
          if (isMyTurn)
            _buildPlayerSelection(context, ref, activePlayer)
          else
            Center(
              child: Text(
                '${activePlayer.name} choisit à qui donner ${state.pendingDrinks.first.sips} pénalité(s)...',
                style: const TextStyle(color: PyraTheme.primaryPink, fontSize: 18),
              ),
            )
        else if (isMyTurn)
          _buildChoices(context, ref, cardIndex).animate().slideY(begin: 0.3, delay: 400.ms).fadeIn()
        else
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircularProgressIndicator(color: PyraTheme.primaryPurple),
                const SizedBox(height: 16),
                Text(
                  'En attente de ${activePlayer.name}...',
                  style: const TextStyle(color: PyraTheme.textSecondary, fontSize: 18),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

        const Spacer(flex: 2),
        
        // Tes cartes (Miniatures pour mémoriser)
        _buildMyHand(state, currentUserId),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMyHand(GameState state, String currentUserId) {
    final me = state.players.firstWhere((p) => p.id == currentUserId, orElse: () => state.players.first);
    if (me.hand.isEmpty) return const SizedBox();

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.black,
      opacity: 0.2,
      child: Column(
        children: [
          const Text('Tes cartes (mémorise-les !) :', style: TextStyle(color: PyraTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: me.hand.asMap().entries.map((e) => SizedBox(
              width: 50, height: 75, 
              child: PlayingCardWidget(card: e.value, faceUp: e.value.isFaceUp)
            ).animate()
             .fadeIn(delay: Duration(milliseconds: 500 + e.key * 100))
             .scale(curve: Curves.easeOutBack)).toList(),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.5, duration: 400.ms);
  }

  Widget _buildPlayerSelection(BuildContext context, WidgetRef ref, Player activePlayer) {
    final assignment = state.pendingDrinks.first;
    final service = ref.read(onlineGameServiceProvider);

    return Column(
      children: [
        Text(
          'À qui donner ${assignment.sips} pénalité(s) ?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: PyraTheme.primaryPink),
        ).animate().shake(duration: 400.ms),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: state.players.where((p) => p.id != activePlayer.id).map((p) {
            return GestureDetector(
              onTap: () {
                service.distributeBusDrinks(state.gameId, p.id);
              },
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: PyraTheme.primaryPurple,
                opacity: 0.3,
                border: Border.all(color: PyraTheme.primaryPink.withOpacity(0.5)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ).animate().scale(curve: Curves.easeOutBack, duration: 300.ms);
          }).toList(),
        ),
      ],
    );
  }

  String _getQuestion(int cardIndex) {
    switch (cardIndex) {
      case 0: return 'Rouge ou Noir ?';
      case 1: return 'Plus grand, Plus petit ou Égal ?';
      case 2: return 'Intérieur ou Extérieur ?';
      case 3: return 'Quel signe ?';
      default: return '?';
    }
  }

  Widget _buildChoices(BuildContext context, WidgetRef ref, int cardIndex) {
    final service = ref.read(onlineGameServiceProvider);

    void onChoice(dynamic choice) {
      final newState = DistributionLogic.processChoice(state: state, choice: choice);
      service.updateGameState(newState);
    }

    switch (cardIndex) {
      case 0:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChoiceButton(label: '🔴 Rouge', color: Colors.red, onPressed: () => onChoice('rouge')),
            const SizedBox(width: 16),
            _ChoiceButton(label: '⚫ Noir', color: Colors.black, onPressed: () => onChoice('noir')),
          ],
        );
      case 1:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _ChoiceButton(label: '⬆️ Plus', color: PyraTheme.primaryOrange, onPressed: () => onChoice('plus')),
            _ChoiceButton(label: '⏸️ Égal', color: Colors.grey, onPressed: () => onChoice('egal')),
            _ChoiceButton(label: '⬇️ Moins', color: PyraTheme.primaryPurple, onPressed: () => onChoice('moins')),
          ],
        );
      case 2:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChoiceButton(label: '↔️ Intérieur', color: PyraTheme.primaryPink, onPressed: () => onChoice('interieur')),
            const SizedBox(width: 16),
            _ChoiceButton(label: '↕️ Extérieur', color: PyraTheme.primaryPurple, onPressed: () => onChoice('exterieur')),
          ],
        );
      case 3:
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _ChoiceButton(label: '♠️ Pique', color: Colors.black, onPressed: () => onChoice(CardSuit.spades)),
            _ChoiceButton(label: '♥️ Cœur', color: Colors.red, onPressed: () => onChoice(CardSuit.hearts)),
            _ChoiceButton(label: '♦️ Carreau', color: Colors.red, onPressed: () => onChoice(CardSuit.diamonds)),
            _ChoiceButton(label: '♣️ Trèfle', color: Colors.black, onPressed: () => onChoice(CardSuit.clubs)),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ChoiceButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        color: color,
        opacity: 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        border: Border.all(color: color.withOpacity(0.8), width: 2),
        child: Text(label, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

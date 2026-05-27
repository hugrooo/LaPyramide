import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../../../shared/widgets/playing_card_widget.dart';

/// Widget de la pyramide de cartes
class PyramidWidget extends StatelessWidget {
  final List<List<PyraCard>> pyramid;
  final int currentRow;
  final int currentCardIndex;
  final GamePhase phase;
  final VoidCallback? onRevealCard;

  const PyramidWidget({
    super.key,
    required this.pyramid,
    required this.currentRow,
    required this.currentCardIndex,
    required this.phase,
    this.onRevealCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int rowIdx = 0; rowIdx < pyramid.length; rowIdx++)
          _buildRow(context, rowIdx),
      ],
    );
  }

  Widget _buildRow(BuildContext context, int rowIdx) {
    final row = pyramid[rowIdx];
    final isCurrentRow = rowIdx == currentRow && phase != GamePhase.finished;
    final sips = pyramid.length - rowIdx; // sommet = plus de gorgées
    final rowColor = PyraTheme.pyramidRowColors[
        (rowIdx % PyraTheme.pyramidRowColors.length)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          // Indicateur de gorgées
          if (isCurrentRow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: rowColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rowColor.withOpacity(0.5)),
              ),
              child: Text(
                '🍺 $sips gorgée${sips > 1 ? 's' : ''}',
                style: TextStyle(
                  color: rowColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 4),

          // Rangée de cartes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int cardIdx = 0; cardIdx < row.length; cardIdx++)
                _buildCardWithGesture(context, rowIdx, cardIdx, row[cardIdx], rowColor),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit la carte avec son animation d'entrée ET le GestureDetector
  /// TOUT EN DEHORS de toutes les couches d'animation.
  Widget _buildCardWithGesture(
    BuildContext context,
    int rowIdx,
    int cardIdx,
    PyraCard card,
    Color rowColor,
  ) {
    final isActive = rowIdx == currentRow &&
        cardIdx == currentCardIndex &&
        phase == GamePhase.revealing;

    // GestureDetector TOUJOURS présent dans l'arbre pour que Flutter
    // puisse mettre à jour onTap sans reconstruire toute la sous-arborescence.
    // Sans ça, quand isActive change, l'arbre de widgets change de type
    // (GestureDetector ↔ Animate) et Flutter perd le callback.
    return Padding(
      key: ValueKey('card_${rowIdx}_$cardIdx'),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: (isActive && onRevealCard != null) ? onRevealCard : null,
        behavior: HitTestBehavior.opaque,
        child: FlippableCardWidget(
          card: card,
          isRevealed: card.isRevealed,
          isActive: isActive,
          width: 52,
          height: 72,
          glowColor: rowColor,
          onTap: null,
        )
            .animate(target: isActive ? 1 : 0)
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              duration: 800.ms,
              curve: Curves.easeInOut,
            )
            .shimmer(
              duration: 1500.ms,
              color: rowColor.withOpacity(0.6),
              angle: 0.5,
            )
            .animate(onPlay: isActive ? (ctrl) => ctrl.repeat(reverse: true) : null)
            .animate()
            .fadeIn(
                delay: (rowIdx * 100 + cardIdx * 50).ms,
                duration: 400.ms)
            .slideY(
                begin: 0.8,
                delay: (rowIdx * 100 + cardIdx * 50).ms,
                duration: 500.ms,
                curve: Curves.easeOutBack),
      ),
    );
  }
}

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildCard(context, rowIdx, cardIdx, row[cardIdx], rowColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    int rowIdx,
    int cardIdx,
    PyraCard card,
    Color rowColor,
  ) {
    final isActive = rowIdx == currentRow &&
        cardIdx == currentCardIndex &&
        phase == GamePhase.revealing;

    return FlippableCardWidget(
      card: card,
      isRevealed: card.isRevealed,
      isActive: isActive,
      width: 52,
      height: 72,
      glowColor: rowColor,
      onTap: isActive ? onRevealCard : null,
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
        .animate(onPlay: isActive ? (ctrl) => ctrl.repeat(reverse: true) : null);
  }
}

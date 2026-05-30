import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../../../shared/widgets/playing_card_widget.dart';

/// Main de joueur — affiché en éventail
class PlayerHandWidget extends StatefulWidget {
  final Player player;
  final bool isInteractive;
  final bool allowPeeking;
  final PyraCard? selectedCard;
  final ValueChanged<PyraCard?>? onCardSelected;
  final ValueChanged<int>? onPeekCard;

  const PlayerHandWidget({
    super.key,
    required this.player,
    this.isInteractive = false,
    this.allowPeeking = false,
    this.selectedCard,
    this.onCardSelected,
    this.onPeekCard,
  });

  @override
  State<PlayerHandWidget> createState() => _PlayerHandWidgetState();
}

class _PlayerHandWidgetState extends State<PlayerHandWidget> {
  PyraCard? _hoveredCard;
  int? _peekedCardIndex;

  void _handlePeek(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1A2A), // PyraTheme.bgCard fallback
        title: const Text('Regarder la carte ?', style: TextStyle(color: Colors.white)),
        content: const Text('Oublié ta carte ? Ça te coûtera 1 pénalité !', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A5F)),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Prendre 1 pénalité', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onPeekCard?.call(index);
      setState(() => _peekedCardIndex = index);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _peekedCardIndex == index) {
          setState(() => _peekedCardIndex = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hand = widget.player.hand;
    if (hand.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < hand.length; i++)
            _buildCard(context, i, hand[i], hand.length),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index, PyraCard card, int total) {
    final isSelected = widget.selectedCard?.id == card.id;
    final isHovered = _hoveredCard?.id == card.id;
    final offset = _cardOffset(index, total);
    final angle = _cardAngle(index, total);

    return Positioned(
      left: offset,
      bottom: isSelected || isHovered ? 20 : 0,
      child: GestureDetector(
        onTap: () {
          if (widget.allowPeeking && _peekedCardIndex != index) {
            _handlePeek(index);
          } else if (widget.isInteractive) {
            HapticFeedback.selectionClick();
            widget.onCardSelected?.call(isSelected ? null : card);
          }
        },
        child: Transform.rotate(
          angle: angle,
          child: AnimatedContainer(
            duration: 200.ms,
            child: PlayingCardWidget(
              card: card,
              faceUp: _peekedCardIndex == index,
              isSelected: isSelected,
              overrideSkin: widget.player.activeCardBack,
              width: 62,
              height: 86,
            ),
          ),
        ),
      ).animate().fadeIn(
            delay: Duration(milliseconds: index * 80),
            duration: 400.ms,
          ),
    );
  }

  double _cardOffset(int index, int total) {
    const cardWidth = 62.0;
    const overlap = 0.65;
    final totalWidth = cardWidth + (total - 1) * cardWidth * overlap;
    final startX = (MediaQuery.of(context).size.width - totalWidth) / 2 - 30;
    return startX + index * cardWidth * overlap;
  }

  double _cardAngle(int index, int total) {
    if (total <= 1) return 0;
    final spread = 0.15;
    return (index - (total - 1) / 2) * spread / (total - 1) * 2;
  }
}

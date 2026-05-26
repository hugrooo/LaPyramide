import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../features/game/models/card_model.dart';

/// Widget d'affichage d'une carte individuelle (face recto ou verso)
class PlayingCardWidget extends StatelessWidget {
  final PyraCard? card;
  final bool faceUp;
  final bool isHighlighted;
  final bool isSelected;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.faceUp = false,
    this.isHighlighted = false,
    this.isSelected = false,
    this.width = 60,
    this.height = 84,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: PyraTheme.primaryYellow.withOpacity(0.8),
                blurRadius: 16,
                spreadRadius: 3,
              ),
            if (isSelected)
              BoxShadow(
                color: PyraTheme.primaryPurple.withOpacity(0.8),
                blurRadius: 16,
                spreadRadius: 3,
              ),
            PyraTheme.cardShadow,
          ],
          border: Border.all(
            color: isHighlighted
                ? PyraTheme.primaryYellow
                : isSelected
                    ? PyraTheme.primaryPurple
                    : Colors.white.withOpacity(0.1),
            width: isHighlighted || isSelected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: faceUp && card != null ? _buildFront(card!) : _buildBack(),
        ),
      ),
    );
  }

  Widget _buildFront(PyraCard c) {
    final color = c.suit.isRed ? const Color(0xFFEF4444) : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade200],
        ),
      ),
      child: Stack(
        children: [
          // Filigrane géant au centre (watermark)
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Text(
                c.suit.emoji,
                style: TextStyle(
                  fontSize: width * 0.9,
                  height: 1,
                ),
              ),
            ),
          ),
          // Valeur haut-gauche
          Positioned(
            top: 4,
            left: 6,
            child: Column(
              children: [
                Text(c.displayValue,
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1)),
                Text(c.suit.emoji,
                    style: const TextStyle(fontSize: 10, height: 1)),
              ],
            ),
          ),
          // Symbole central
          Center(
            child: Text(
              c.suit.emoji,
              style: TextStyle(
                fontSize: width * 0.4,
              ),
            ),
          ),
          // Valeur bas-droite (retournée)
          Positioned(
            bottom: 4,
            right: 6,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                children: [
                  Text(c.displayValue,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1)),
                  Text(c.suit.emoji,
                      style: const TextStyle(fontSize: 10, height: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1B4B), Color(0xFF1E103B)],
        ),
      ),
      child: Stack(
        children: [
          // Motif en fond
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Text(
                '🔺\n🔻',
                style: TextStyle(fontSize: width * 0.6, height: 0.8),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Cadre central
          Center(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: PyraTheme.primaryPink.withOpacity(0.5),
                  width: 1.5,
                ),
                gradient: RadialGradient(
                  colors: [
                    PyraTheme.primaryPink.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
              child: const Center(
                child: Text('🔺', style: TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de la pyramide avec animation de flip
class FlippableCardWidget extends StatefulWidget {
  final PyraCard card;
  final bool isRevealed;
  final bool isActive;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final Color? glowColor;

  const FlippableCardWidget({
    super.key,
    required this.card,
    required this.isRevealed,
    this.isActive = false,
    this.width = 56,
    this.height = 78,
    this.onTap,
    this.glowColor,
  });

  @override
  State<FlippableCardWidget> createState() => _FlippableCardWidgetState();
}

class _FlippableCardWidgetState extends State<FlippableCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    if (widget.isRevealed) _flipController.value = 1.0;
  }

  @override
  void didUpdateWidget(FlippableCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _flipController.forward();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * 3.14159;
        final isFrontVisible = angle > 1.5708;
        // Pop up effect: scale increases in the middle of the flip
        final scale = 1.0 + (0.5 - (_flipAnimation.value - 0.5).abs()) * 0.4;

        return Transform.scale(
          scale: scale,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // Stronger perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontVisible
                ? Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: PlayingCardWidget(
                      card: widget.card,
                      faceUp: true,
                      isHighlighted: widget.isActive,
                      width: widget.width,
                      height: widget.height,
                      onTap: widget.onTap,
                    ),
                  )
                : PlayingCardWidget(
                    card: widget.card,
                    faceUp: false,
                    isHighlighted: widget.isActive,
                    width: widget.width,
                    height: widget.height,
                    onTap: widget.isActive ? widget.onTap : null,
                  ),
          ),
        );
      },
    );
  }
}

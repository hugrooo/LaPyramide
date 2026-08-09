import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../features/game/models/card_model.dart';
import '../../features/profile/user_profile_provider.dart';

/// Widget d'affichage d'une carte individuelle (face recto ou verso) avec animations 3D
class PlayingCardWidget extends ConsumerStatefulWidget {
  final PyraCard? card;
  final bool faceUp;
  final bool isHighlighted;
  final bool isSelected;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final String? overrideSkin;
  final bool animateFlip;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.faceUp = false,
    this.isHighlighted = false,
    this.isSelected = false,
    this.width = 60,
    this.height = 84,
    this.onTap,
    this.overrideSkin,
    this.animateFlip = true,
  });

  @override
  ConsumerState<PlayingCardWidget> createState() => _PlayingCardWidgetState();
}

class _PlayingCardWidgetState extends ConsumerState<PlayingCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    _scaleController.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final activeCardBack = widget.overrideSkin ??
        ref.watch(userProfileProvider).value?.activeCardBack ??
        'classic';

    final glowColor = widget.isHighlighted
        ? PyraTheme.primaryYellow
        : widget.isSelected
            ? PyraTheme.primaryPurple
            : null;

    final cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.8),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          PyraTheme.cardShadow,
        ],
        border: Border.all(
          color: glowColor ?? Colors.white.withValues(alpha: 0.1),
          width: glowColor != null ? 2.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: widget.faceUp && widget.card != null
            ? _buildFront(widget.card!)
            : _buildBack(activeCardBack),
      ),
    );

    if (!widget.animateFlip) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: cardBody,
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          tween: Tween<double>(begin: 0, end: widget.faceUp ? 1.0 : 0.0),
          builder: (context, val, child) {
            final angle = val * math.pi;
            final isFront = val >= 0.5;
            final transformMatrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle);

            return Transform(
              transform: transformMatrix,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (glowColor != null)
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.8),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                    PyraTheme.cardShadow,
                  ],
                  border: Border.all(
                    color: glowColor ?? Colors.white.withValues(alpha: 0.1),
                    width: glowColor != null ? 2.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Transform(
                    transform: isFront ? (Matrix4.identity()..rotateY(math.pi)) : Matrix4.identity(),
                    alignment: Alignment.center,
                    child: isFront && widget.card != null
                        ? _buildFront(widget.card!)
                        : _buildBack(activeCardBack),
                  ),
                ),
              ),
            );
          },
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
                  fontSize: widget.width * 0.9,
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
                fontSize: widget.width * 0.4,
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

  Widget _buildBack(String style) {
    // Différents styles de cartes
    Gradient bgGradient;
    Color borderColor;
    Color centerGlowColor;
    String centerSymbol;
    String bgPattern;

    switch (style) {
      case 'neon':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        );
        borderColor = PyraTheme.primaryCyan;
        centerGlowColor = PyraTheme.primaryCyan;
        centerSymbol = '⚡';
        bgPattern = '///';
        break;
      case 'pirate':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E2723), Color(0xFF1B0000)],
        );
        borderColor = PyraTheme.primaryYellow;
        centerGlowColor = PyraTheme.primaryYellow;
        centerSymbol = '☠️';
        bgPattern = 'X X\nX X';
        break;
      case 'retro':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF000051)],
        );
        borderColor = const Color(0xFF00E676); // Retro green
        centerGlowColor = const Color(0xFF00E676);
        centerSymbol = '👾';
        bgPattern = '0 1\n1 0';
        break;
      case 'girl':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB6C1),
            Color(0xFFFF1493)
          ], // Light pink to Deep pink
        );
        borderColor = Colors.white;
        centerGlowColor = Colors.white;
        centerSymbol = '🎀';
        bgPattern = '✨\n💖';
        break;
      case 'beta':
        bgGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9C27B0).withOpacity(0.7), // Transparent purple
            const Color(0xFF4A148C).withOpacity(0.9),
          ],
        );
        borderColor = const Color(0xFFE040FB); // Bright purple
        centerGlowColor = const Color(0xFFE040FB);
        centerSymbol = '🚀\nBÊTA';
        bgPattern = '🚀\n⭐';
        break;
      case 'pharaoh':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4AF37), Color(0xFF8B6508)],
        );
        borderColor = const Color(0xFFFFF8DC);
        centerGlowColor = const Color(0xFFFFF8DC);
        centerSymbol = '👁️';
        bgPattern = '🐪\n🐫';
        break;
      case 'casino':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006400), Color(0xFF003300)],
        );
        borderColor = const Color(0xFFFFD700);
        centerGlowColor = const Color(0xFFFFD700);
        centerSymbol = '🎲';
        bgPattern = '♠️\n♣️';
        break;
      case 'toxic':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
        );
        borderColor = const Color(0xFF39FF14);
        centerGlowColor = const Color(0xFF39FF14);
        centerSymbol = '🧪';
        bgPattern = '☣️\n💀';
        break;
      case 'vip':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
        );
        borderColor = Colors.white;
        centerGlowColor = Colors.white;
        centerSymbol = '💎';
        bgPattern = '✨\n💎';
        break;
      case 'clubbing':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF000000), Color(0xFF120024)],
        );
        borderColor = const Color(0xFFFF00FF);
        centerGlowColor = const Color(0xFF00FFFF);
        centerSymbol = '🪩';
        bgPattern = '🎵\n⭐';
        break;
      case 'demon':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B0000), Color(0xFF3A0000)],
        );
        borderColor = const Color(0xFFFF4500);
        centerGlowColor = const Color(0xFFFF4500);
        centerSymbol = '😈';
        bgPattern = '🔥\n👹';
        break;
      case 'galaxy':
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0221), Color(0xFF1B0A3C), Color(0xFF0D0221)],
        );
        borderColor = const Color(0xFF7C4DFF);
        centerGlowColor = const Color(0xFFB388FF);
        centerSymbol = '🌌';
        bgPattern = '✨\n🌠';
        break;
      case 'classic':
      default:
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1B4B), Color(0xFF1E103B)],
        );
        borderColor = PyraTheme.primaryPink;
        centerGlowColor = PyraTheme.primaryPink;
        centerSymbol = '🔺';
        bgPattern = '🔺\n🔻';
        break;
    }

    Widget cardBack = Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: Stack(
        children: [
          // Motif en fond
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Text(
                bgPattern,
                style: TextStyle(
                  fontSize: style == 'retro' ? widget.width * 0.4 : widget.width * 0.6,
                  height: 0.8,
                  fontFamily: style == 'retro' ? 'Courier' : null,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Cadre central
          Center(
            child: Container(
              margin: EdgeInsets.all(widget.width * 0.1),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(style == 'retro' ? 0 : widget.width * 0.1),
                border: Border.all(
                  color: borderColor.withOpacity(0.5),
                  width: widget.width * 0.025 > 1.0 ? widget.width * 0.025 : 1.0,
                ),
                gradient: RadialGradient(
                  colors: [
                    centerGlowColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
              child: Center(
                child: Text(centerSymbol,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: style == 'beta' ? widget.width * 0.23 : widget.width * 0.36,
                      fontWeight:
                          style == 'beta' ? FontWeight.bold : FontWeight.normal,
                      color: style == 'beta' ? const Color(0xFFE040FB) : null,
                    )),
              ),
            ),
          ),
        ],
      ),
    );

    if (style == 'vip') {
      cardBack = cardBack
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
              duration: 2500.ms,
              color: Colors.white.withOpacity(0.6),
              angle: 0.8)
          .elevation(
              end: 10,
              duration: 1250.ms,
              color: Colors.cyanAccent.withOpacity(0.3));
    }

    return cardBack;
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

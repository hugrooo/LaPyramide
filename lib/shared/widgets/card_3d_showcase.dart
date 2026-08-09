import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../features/game/models/card_model.dart';
import 'playing_card_widget.dart';

class Card3DShowcase extends StatefulWidget {
  final String skinId;
  final double width;
  final double height;
  final bool showControls;

  const Card3DShowcase({
    super.key,
    required this.skinId,
    this.width = 120,
    this.height = 168,
    this.showControls = true,
  });

  @override
  State<Card3DShowcase> createState() => _Card3DShowcaseState();
}

class _Card3DShowcaseState extends State<Card3DShowcase>
    with TickerProviderStateMixin {
  late AnimationController _autoController;
  late AnimationController _inertiaController;

  final ValueNotifier<double> _angleY = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _angleX = ValueNotifier<double>(0.0);

  bool _isAutoSpinning = true;
  double _lastAutoVal = 0.0;
  double _velocityDx = 0.0;

  @override
  void initState() {
    super.initState();
    _autoController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _inertiaController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _autoController.addListener(_onAutoTick);
    _inertiaController.addListener(_onInertiaTick);

    _autoController.repeat();
  }

  void _onAutoTick() {
    if (!_isAutoSpinning) return;
    final delta = _autoController.value - _lastAutoVal;
    _lastAutoVal = _autoController.value;
    final stepY = (delta < 0 ? (delta + 1.0) : delta) * math.pi * 2;
    _angleY.value = (_angleY.value + stepY) % (math.pi * 2);
    _angleX.value = math.sin(_angleY.value) * 0.12;
  }

  void _onInertiaTick() {
    final t = 1.0 - _inertiaController.value;
    _angleY.value = (_angleY.value + _velocityDx * t * 0.016) % (math.pi * 2);
  }

  @override
  void dispose() {
    _autoController.removeListener(_onAutoTick);
    _inertiaController.removeListener(_onInertiaTick);
    _autoController.dispose();
    _inertiaController.dispose();
    _angleY.dispose();
    _angleX.dispose();
    super.dispose();
  }

  void _toggleAutoSpin() {
    HapticFeedback.lightImpact();
    setState(() {
      _isAutoSpinning = !_isAutoSpinning;
      if (_isAutoSpinning) {
        _inertiaController.stop();
        _lastAutoVal = _autoController.value;
        _autoController.repeat();
      } else {
        _autoController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.skinId == 'neon'
        ? const Color(0xFF00F2FE)
        : widget.skinId == 'galaxy'
            ? const Color(0xFFE040FB)
            : widget.skinId == 'pirate'
                ? const Color(0xFFFFD700)
                : Colors.cyan;

    final touchWidth = math.max(widget.width, widget.height) + 12.0;
    final touchHeight = widget.height;

    final card3DWidget = AnimatedBuilder(
      animation: Listenable.merge([_angleY, _angleX]),
      builder: (context, child) {
        final y = _angleY.value;
        final x = _angleX.value;

        // Angle normalisé entre 0 et 2*pi
        final normY = (y % (math.pi * 2) + math.pi * 2) % (math.pi * 2);

        // Vérifier si la face verso est visible (le cosinus régit le franchissement)
        final bool isBackVisible = math.cos(normY) >= 0;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateX(x)
          ..rotateY(normY);

        return Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isBackVisible
                ? PlayingCardWidget(
                    faceUp: false,
                    overrideSkin: widget.skinId,
                    width: widget.width,
                    height: widget.height,
                    animateFlip: false,
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: PlayingCardWidget(
                      faceUp: true,
                      overrideSkin: widget.skinId,
                      width: widget.width,
                      height: widget.height,
                      animateFlip: false,
                      card: PyraCard(
                        id: 'dummy',
                        suit: CardSuit.spades,
                        value: 1,
                        powerType: PowerType.none,
                      ),
                    ),
                  ),
          ),
        );
      },
    );

    if (!widget.showControls) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          if (_isAutoSpinning) {
            setState(() {
              _isAutoSpinning = false;
            });
            _autoController.stop();
          }
          _inertiaController.stop();
        },
        onPanUpdate: (details) {
          _angleY.value = (_angleY.value + details.delta.dx * 0.012) % (math.pi * 2);
          _angleX.value = (_angleX.value - details.delta.dy * 0.012).clamp(-0.6, 0.6);
        },
        onPanEnd: (details) {
          _velocityDx = details.velocity.pixelsPerSecond.dx * 0.003;
          if (_velocityDx.abs() > 0.1) {
            _inertiaController.forward(from: 0.0);
          }
        },
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(child: card3DWidget),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            if (_isAutoSpinning) {
              setState(() {
                _isAutoSpinning = false;
              });
              _autoController.stop();
            }
            _inertiaController.stop();
          },
          onPanUpdate: (details) {
            _angleY.value = (_angleY.value + details.delta.dx * 0.012) % (math.pi * 2);
            _angleX.value = (_angleX.value - details.delta.dy * 0.012).clamp(-0.6, 0.6);
          },
          onPanEnd: (details) {
            _velocityDx = details.velocity.pixelsPerSecond.dx * 0.003;
            if (_velocityDx.abs() > 0.1) {
              _inertiaController.forward(from: 0.0);
            }
          },
          child: Container(
            width: touchWidth,
            height: touchHeight,
            alignment: Alignment.center,
            color: Colors.transparent, // Zone tactile invisible et réactive
            child: card3DWidget,
          ),
        ),

        const SizedBox(height: 12),
        GestureDetector(
          onTap: _toggleAutoSpin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _isAutoSpinning
                  ? glowColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isAutoSpinning
                    ? glowColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAutoSpinning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: _isAutoSpinning ? glowColor : Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _isAutoSpinning ? 'Stopper la rotation' : 'Reprendre la rotation',
                  style: TextStyle(
                    color: _isAutoSpinning ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '👈 Faites glisser pour pivoter en 3D libre 👉',
          style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../features/game/models/card_model.dart';
import 'playing_card_widget.dart';

class Card3DShowcase extends StatefulWidget {
  final String skinId;
  final double width;
  final double height;

  const Card3DShowcase({
    super.key,
    required this.skinId,
    this.width = 120,
    this.height = 168,
  });

  @override
  State<Card3DShowcase> createState() => _Card3DShowcaseState();
}

class _Card3DShowcaseState extends State<Card3DShowcase>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Rotation autour de Y en continu, et une légère oscillation sur X
        final rotateY = _controller.value * math.pi * 2;
        final rotateX = math.sin(_controller.value * math.pi * 2) *
            0.15; // légère oscillation

        // Déterminer si on voit le dos ou la face de la carte
        final bool isBackVisible =
            rotateY <= math.pi / 2 || rotateY >= math.pi * 1.5;

        // Effet de perspective
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.002) // Perspective plus forte
          ..rotateX(rotateX)
          ..rotateY(isBackVisible
              ? rotateY
              : (rotateY +
                  math.pi)); // On tourne de 180° supplémentaire si on voit la face pour ne pas l'avoir en miroir

        return Transform(
          transform: matrix,
          alignment: FractionalOffset.center,
          child: PlayingCardWidget(
            faceUp: !isBackVisible,
            overrideSkin: widget.skinId,
            width: widget.width,
            height: widget.height,
            card: PyraCard(
                id: 'dummy',
                suit: CardSuit.spades,
                value: 1,
                powerType: PowerType.none), // Dummy card pour la face
          ),
        );
      },
    );
  }
}

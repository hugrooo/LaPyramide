import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class PulsarButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Gradient? gradient;
  final double paddingVertical;
  final double paddingHorizontal;

  const PulsarButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.gradient,
    this.paddingVertical = 16.0,
    this.paddingHorizontal = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final activeGradient = gradient ?? PyraTheme.purplePinkGradient;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: activeGradient,
          boxShadow: [
            BoxShadow(
              color: activeGradient.colors.last.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 1.seconds)
          .shimmer(duration: 2.seconds, color: Colors.white24),
    );
  }
}

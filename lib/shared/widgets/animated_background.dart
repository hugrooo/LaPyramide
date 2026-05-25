import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Fond animé avec des bulles/particules festives flottantes
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<_Particle> _particles;
  late AnimationController _controller;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(18, (_) => _Particle(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
      builder: (context, _) {
        return CustomPaint(
          painter: _BackgroundPainter(_particles, _controller.value),
          child: Container(
            decoration: const BoxDecoration(gradient: PyraTheme.mainGradient),
          ),
        );
      },
    );
  }
}

class _Particle {
  double x, y, size, speed, opacity;
  Color color;

  _Particle(Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = random.nextDouble() * 8 + 4,
        speed = random.nextDouble() * 0.3 + 0.1,
        opacity = random.nextDouble() * 0.3 + 0.05,
        color = _festiveColors[random.nextInt(_festiveColors.length)];

  static const List<Color> _festiveColors = [
    PyraTheme.primaryPurple,
    PyraTheme.primaryPink,
    PyraTheme.primaryOrange,
    PyraTheme.primaryYellow,
    PyraTheme.primaryGreen,
  ];
}

class _BackgroundPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _BackgroundPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = (p.y - p.speed * progress) % 1.0;
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width, currentY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}

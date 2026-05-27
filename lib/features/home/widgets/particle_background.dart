import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        _updateParticles();
      })..repeat();

    // Init particles
    for (int i = 0; i < 40; i++) {
      _particles.add(_generateParticle(initial: true));
    }
  }

  _Particle _generateParticle({bool initial = false}) {
    return _Particle(
      x: _rnd.nextDouble(),
      y: initial ? _rnd.nextDouble() : 1.1, // Si initial, réparti partout, sinon commence en bas
      size: _rnd.nextDouble() * 3 + 1,
      speed: _rnd.nextDouble() * 0.002 + 0.001,
      opacity: _rnd.nextDouble() * 0.5 + 0.1,
      color: _rnd.nextBool() ? PyraTheme.primaryYellow : PyraTheme.primaryPink,
      wobbleSpeed: _rnd.nextDouble() * 0.05,
      wobbleAmount: _rnd.nextDouble() * 0.02,
    );
  }

  void _updateParticles() {
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.y -= p.speed;
      // Wobble horizontal
      p.x += sin(DateTime.now().millisecondsSinceEpoch * p.wobbleSpeed) * p.wobbleAmount * 0.1;

      // Si la particule sort de l'écran par le haut, on la recycle en bas
      if (p.y < -0.1) {
        _particles[i] = _generateParticle();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(_particles),
      size: Size.infinite,
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  Color color;
  double wobbleSpeed;
  double wobbleAmount;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.wobbleSpeed,
    required this.wobbleAmount,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

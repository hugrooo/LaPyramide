import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';

class PlayCard3D extends StatefulWidget {
  final VoidCallback onTap;

  const PlayCard3D({super.key, required this.onTap});

  @override
  State<PlayCard3D> createState() => _PlayCard3DState();
}

class _PlayCard3DState extends State<PlayCard3D> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isPressed = false;
  Offset _tilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _tilt += Offset(details.delta.dx * 0.01, details.delta.dy * 0.01);
      // Limiter le tilt
      _tilt = Offset(
        _tilt.dx.clamp(-0.5, 0.5),
        _tilt.dy.clamp(-0.5, 0.5),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _tilt = Offset.zero; // Reset doux par défaut (on pourrait l'animer via un Tween, mais setState suffit pour un snap rapide)
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          // Animation de lévitation et rotation continue
          final floatY = sin(_floatController.value * 2 * pi) * 10;
          final rotateX = sin(_floatController.value * 2 * pi) * 0.05 + _tilt.dy;
          final rotateY = cos(_floatController.value * 2 * pi) * 0.05 - _tilt.dx;
          
          // L'enfoncement 3D au clic
          final scale = _isPressed ? 0.92 : 1.0;
          final pressZ = _isPressed ? -20.0 : 0.0;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective matricielle
              ..translate(0.0, floatY, pressZ)
              ..rotateX(rotateX)
              ..rotateY(rotateY)
              ..scale(scale),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    return Container(
      width: 240,
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PyraTheme.bgCard,
            PyraTheme.bgSurface,
            PyraTheme.bgDark,
          ],
        ),
        boxShadow: [
          // Ombre colorée (Glow arrière)
          BoxShadow(color: PyraTheme.primaryPink.withOpacity(0.4), blurRadius: 40, spreadRadius: -5, offset: const Offset(-20, 20)),
          BoxShadow(color: PyraTheme.primaryCyan.withOpacity(0.4), blurRadius: 40, spreadRadius: -5, offset: const Offset(20, -20)),
          // Ombre de portée 3D
          BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 30, offset: const Offset(0, 30)),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Effet holographique interne (dégradé qui bouge avec shimmer)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).slideX(begin: -1, end: 1, duration: 3.seconds, curve: Curves.linear),
            ),
            
            // Halo lumineux au centre
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: PyraTheme.primaryYellow.withOpacity(0.3), blurRadius: 80, spreadRadius: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Contenu (Logo, Texte, Play)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top (Saison, ou icône)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text('MODE LIGNE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                      const Icon(Icons.wifi_rounded, color: PyraTheme.primaryCyan, size: 20),
                    ],
                  ),
                  
                  // Center
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: PyraTheme.orangeYellowGradient,
                          boxShadow: PyraTheme.glowOrange,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
                      const SizedBox(height: 16),
                      const Text(
                        'JOUER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                        ),
                      ),
                    ],
                  ),

                  // Bottom (Joueurs en ligne etc)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 8)]),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
                      const SizedBox(width: 8),
                      const Text('Prêt pour la Pyramide', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

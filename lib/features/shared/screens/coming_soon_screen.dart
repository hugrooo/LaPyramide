import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pulsar_button.dart';

class ComingSoonScreen extends StatefulWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _shimmerController;
  bool _notifyTapped = false;

  String get _prefsKey => 'coming_soon_notify_${widget.title}';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadNotifyState();
  }

  Future<void> _loadNotifyState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _notifyTapped = prefs.getBool(_prefsKey) ?? false);
    }
  }

  Future<void> _onNotifyTap() async {
    HapticFeedback.mediumImpact();
    setState(() => _notifyTapped = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Animated orbital system
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating ring
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateController.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(200, 200),
                              painter: _OrbitPainter(
                                color: PyraTheme.primaryPurple
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                          );
                        },
                      ),
                      // Second ring (opposite direction, slower)
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: -_rotateController.value * 1.5 * math.pi,
                            child: CustomPaint(
                              size: const Size(160, 160),
                              painter: _OrbitPainter(
                                color:
                                    PyraTheme.primaryCyan.withValues(alpha: 0.2),
                                dashed: true,
                              ),
                            ),
                          );
                        },
                      ),
                      // Orbital dots
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateController.value * 2 * math.pi,
                            child: SizedBox(
                              width: 200,
                              height: 200,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 95,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: PyraTheme.primaryCyan,
                                        boxShadow: [
                                          BoxShadow(
                                            color: PyraTheme.primaryCyan
                                                .withValues(alpha: 0.6),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 15,
                                    right: 20,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: PyraTheme.primaryPink,
                                        boxShadow: [
                                          BoxShadow(
                                            color: PyraTheme.primaryPink
                                                .withValues(alpha: 0.6),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 40,
                                    left: 10,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: PyraTheme.primaryYellow,
                                        boxShadow: [
                                          BoxShadow(
                                            color: PyraTheme.primaryYellow
                                                .withValues(alpha: 0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Inner pulsing glow
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + _pulseController.value * 0.08;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    PyraTheme.primaryPurple
                                        .withValues(alpha: 0.25),
                                    PyraTheme.primaryPink
                                        .withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Center emoji
                      const Text('🚀', style: TextStyle(fontSize: 52))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .slideY(
                              begin: 0,
                              end: -0.06,
                              duration: 2.seconds,
                              curve: Curves.easeInOut),
                    ],
                  ),
                ).animate().scale(
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.4, 0.4)),

                const SizedBox(height: 36),

                // Title
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

                const SizedBox(height: 12),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Ce mode de jeu est en cours de développement.\nIl sera disponible très bientôt !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 16),

                // Badge
                GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: PyraTheme.primaryYellow.withValues(alpha: 0.3)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.construction_rounded,
                          color: PyraTheme.primaryYellow, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'EN DÉVELOPPEMENT',
                        style: TextStyle(
                          color: PyraTheme.primaryYellow,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).scale(
                    begin: const Offset(0.8, 0.8)),

                const Spacer(flex: 3),

                // Notify button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _notifyTapped
                      ? GlassContainer(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_active_rounded,
                                  color: Colors.greenAccent, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Tu seras notifié !',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ).animate().scale(
                            duration: 400.ms, curve: Curves.easeOutBack)
                      : PulsarButton(
                          text: 'Me prévenir à la sortie',
                          icon: Icons.notifications_none_rounded,
                          gradient: PyraTheme.purplePinkGradient,
                          onPressed: _onNotifyTap,
                        ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Retour',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15)),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final Color color;
  final bool dashed;

  _OrbitPainter({required this.color, this.dashed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (dashed) {
      const dashLength = 8.0;
      const gapLength = 6.0;
      final circumference = 2 * math.pi * radius;
      final dashCount = (circumference / (dashLength + gapLength)).floor();

      for (int i = 0; i < dashCount; i++) {
        final startAngle =
            (i * (dashLength + gapLength) / circumference) * 2 * math.pi;
        final sweepAngle = (dashLength / circumference) * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
    } else {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

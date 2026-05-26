import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class PulsarButton extends StatefulWidget {
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
  State<PulsarButton> createState() => _PulsarButtonState();
}

class _PulsarButtonState extends State<PulsarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    _pressController.reverse();
    setState(() => _isPressed = false);
  }

  void _onTap() {
    if (widget.onPressed == null) return;
    HapticFeedback.mediumImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final activeGradient = widget.gradient ?? PyraTheme.purplePinkGradient;
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: widget.paddingVertical,
              horizontal: widget.paddingHorizontal,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isDisabled
                  ? const LinearGradient(colors: [Color(0xFF444444), Color(0xFF555555)])
                  : activeGradient,
              boxShadow: isDisabled
                  ? []
                  : [
                      BoxShadow(
                        color: activeGradient.colors.last.withOpacity(_isPressed ? 0.7 : 0.45),
                        blurRadius: _isPressed ? 25 : 18,
                        spreadRadius: _isPressed ? 3 : 2,
                      ),
                    ],
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.025, 1.025),
                duration: 1800.ms,
                curve: Curves.easeInOut,
              )
              .shimmer(
                duration: 3.seconds,
                color: Colors.white.withOpacity(0.15),
                angle: 45,
              ),
        ),
      ),
    );
  }
}

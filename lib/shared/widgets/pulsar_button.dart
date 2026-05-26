import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class PulsarButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final Gradient? gradient;
  final double paddingVertical;
  final double paddingHorizontal;
  final double? fontSize;
  final double? iconSize;

  const PulsarButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.gradient,
    this.paddingVertical = 18.0,
    this.paddingHorizontal = 32.0,
    this.fontSize,
    this.iconSize,
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutBack),
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
    final activeGradient = widget.gradient ?? PyraTheme.cyanGradient;
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
              borderRadius: BorderRadius.circular(32),
              gradient: isDisabled
                  ? const LinearGradient(colors: [Color(0xFF2A2D43), Color(0xFF1E2138)])
                  : activeGradient,
              boxShadow: isDisabled
                  ? []
                  : [
                      // Glow effect
                      BoxShadow(
                        color: activeGradient.colors.last.withOpacity(_isPressed ? 0.8 : 0.5),
                        blurRadius: _isPressed ? 30 : 20,
                        spreadRadius: _isPressed ? 4 : 2,
                        offset: const Offset(0, 8),
                      ),
                      // Inner highlight simulated with border
                    ],
              border: Border.all(
                color: Colors.white.withOpacity(isDisabled ? 0.05 : 0.4),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Text and Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: widget.iconSize ?? 24),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.fontSize ?? 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.02, 1.02),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              )
              .shimmer(
                duration: 3.seconds,
                color: Colors.white.withOpacity(0.25),
                angle: 45,
                blendMode: BlendMode.overlay,
              ),
        ),
      ),
    );
  }
}

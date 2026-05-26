import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color color;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final bool innerGlow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.color = Colors.white,
    this.opacity = 0.05,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.innerGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(24);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              borderRadius: effectiveBorderRadius,
              // Light border on top-left, dark on bottom-right for 3D glass effect
              border: border ?? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              gradient: innerGlow
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

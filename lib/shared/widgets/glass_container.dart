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

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.color = Colors.white,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);

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
              border: border ?? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

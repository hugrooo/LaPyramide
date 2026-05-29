import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class AvatarWithBorder extends StatelessWidget {
  final String emoji;
  final double size;
  final String borderType;
  final bool showLevel;
  final int? level;
  final String? photoUrl;

  const AvatarWithBorder({
    super.key,
    required this.emoji,
    this.size = 40,
    this.borderType = 'classic',
    this.showLevel = false,
    this.level,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.5))),
              )
            : Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.5))),
      ),
    );

    // Appliquer le cadre selon le type
    if (borderType == 'neon') {
      avatarChild = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: PyraTheme.primaryCyan.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: PyraTheme.primaryPink.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: PyraTheme.primaryCyan, width: 2),
          ),
          child: avatarChild,
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white);
    } 
    else if (borderType == 'fire') {
      avatarChild = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.4),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: avatarChild,
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 800.ms, begin: const Offset(1,1), end: const Offset(1.05, 1.05));
    }
    else if (borderType == 'gold') {
      avatarChild = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.yellowAccent.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: avatarChild,
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: Colors.white, angle: 1.0);
    }

    if (showLevel && level != null) {
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          avatarChild,
          Positioned(
            bottom: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: PyraTheme.primaryCyan,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text(
                'Lvl $level',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatarChild;
  }
}

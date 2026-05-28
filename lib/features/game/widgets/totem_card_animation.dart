import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/playing_card_widget.dart';
import '../models/card_model.dart';

/// Overlay affichant une carte avec l'animation style "Totem d'Immortalité" de Minecraft
class TotemCardAnimation extends StatefulWidget {
  final PyraCard card;
  final bool isTruth;
  final VoidCallback onAnimationComplete;

  const TotemCardAnimation({
    super.key,
    required this.card,
    required this.isTruth,
    required this.onAnimationComplete,
  });

  @override
  State<TotemCardAnimation> createState() => _TotemCardAnimationState();
}

class _TotemCardAnimationState extends State<TotemCardAnimation> {
  bool _showFront = false;

  @override
  void initState() {
    super.initState();

    // SÉQUENCE DE VIBRATIONS HAPTIQUES ET ANIMATIONS RYTHMÉES :
    // 0ms : Jaillissement initial de loin
    HapticFeedback.lightImpact();

    // 300ms : Début du retournement 3D
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) HapticFeedback.selectionClick();
    });

    // 600ms : Révélation du recto sur la tranche
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        HapticFeedback.selectionClick();
        setState(() {
          _showFront = true;
        });
      }
    });

    // 900ms : Pop final de l'impact & scintillement
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) HapticFeedback.heavyImpact();
    });

    // 1200ms - 1500ms : Tremblements saccadés (séquence séisme)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) HapticFeedback.lightImpact();
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) HapticFeedback.lightImpact();
    });

    // 4500ms : Disparition de la carte
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) HapticFeedback.lightImpact();
    });

    // 5500ms : Fermeture de l'overlay
    Future.delayed(const Duration(milliseconds: 5500), () {
      if (mounted) widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Texte de résultat (placé élégamment au-dessus de la carte)
                Text(
                  widget.isTruth ? 'VÉRITÉ !' : 'MENTEUR !',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: widget.isTruth ? Colors.greenAccent : Colors.redAccent,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), delay: 900.ms, duration: 300.ms, curve: Curves.elasticOut)
                    .fadeOut(delay: 4500.ms, duration: 300.ms),

                const SizedBox(height: 32),

                // Stack contenant les rayons lumineux et la carte du joueur
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Rayons lumineux en fond
                    const Icon(
                      Icons.sunny,
                      size: 320,
                      color: Colors.white10,
                    )
                        .animate(onPlay: (ctrl) => ctrl.repeat())
                        .rotate(duration: 6.seconds)
                        .fadeIn(duration: 400.ms, delay: 600.ms)
                        .fadeOut(delay: 4500.ms, duration: 400.ms),

                    // La carte animée
                    SizedBox(
                      width: 180,
                      height: 250,
                      child: PlayingCardWidget(
                        card: widget.card,
                        faceUp: _showFront,
                        width: 180,
                        height: 250,
                      ),
                    )
                        .animate()
                        // 1. Arrive par le bas, de très loin, en tourbillonnant
                        .slideY(begin: 3.5, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
                        .scale(begin: const Offset(0.01, 0.01), end: const Offset(1.0, 1.0), duration: 500.ms, curve: Curves.easeOutCubic)
                        .rotate(begin: -0.5, end: 0.0, duration: 600.ms, curve: Curves.easeOutBack)
                        // 2. Se retourne 3D (le recto s'active exactement à 600ms au milieu de la rotation)
                        .flipH(begin: -1, end: 0, duration: 600.ms, delay: 300.ms, curve: Curves.easeInOut)
                        // 3. Grossit (le pop élastique du totem)
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.3, 1.3), delay: 900.ms, duration: 300.ms, curve: Curves.elasticOut)
                        // 4. Scintillement de type Shimmer
                        .shimmer(delay: 900.ms, duration: 500.ms, color: widget.isTruth ? Colors.greenAccent : Colors.redAccent)
                        // 5. Tremblement physique d'impact
                        .shake(delay: 1200.ms, duration: 300.ms, hz: 4)
                        // 6. Redescend et disparaît après une longue phase stationnaire
                        .scale(end: const Offset(0.0, 0.0), delay: 4500.ms, duration: 400.ms, curve: Curves.easeInBack)
                        .fadeOut(delay: 4500.ms, duration: 400.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper pour afficher l'animation facilement depuis un State
void showTotemAnimation(BuildContext context, PyraCard card, bool isTruth) {
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => TotemCardAnimation(
      card: card,
      isTruth: isTruth,
      onAnimationComplete: () {
        overlayEntry.remove();
      },
    ),
  );
  
  Overlay.of(context).insert(overlayEntry);
}

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
  final String? overrideSkin;

  const TotemCardAnimation({
    super.key,
    required this.card,
    required this.isTruth,
    required this.onAnimationComplete,
    this.overrideSkin,
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
        setState(() => _showFront = true);
        HapticFeedback.heavyImpact();
      }
    });

    // 900ms : Pop de satisfaction (comme le totem qui s'active)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        if (widget.isTruth) {
          HapticFeedback.lightImpact(); // Double tap léger
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) HapticFeedback.lightImpact();
          });
        } else {
          HapticFeedback.vibrate(); // Vibreur long et lourd
        }
      }
    });

    // 4000ms : Fin de l'animation, on la retire
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Voile noir de fond qui clignote et s'estompe
              Container(
                color: Colors.black.withOpacity(0.7),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .fadeOut(delay: 3500.ms, duration: 500.ms),

              // Rayons dorés/rouges en arrière-plan (tournent)
              if (_showFront)
                Positioned(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.isTruth ? Colors.greenAccent.withOpacity(0.4) : Colors.redAccent.withOpacity(0.4),
                          blurRadius: 100,
                          spreadRadius: 20,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.sunny,
                      size: 320,
                      color: Colors.white10,
                    )
                        .animate(onPlay: (ctrl) => ctrl.repeat())
                        .rotate(duration: 6.seconds)
                        .fadeIn(duration: 400.ms, delay: 600.ms)
                        .fadeOut(delay: 4500.ms, duration: 400.ms),
                  ),
                ),

              // La carte animée
              SizedBox(
                width: 180,
                height: 250,
                child: PlayingCardWidget(
                  card: widget.card,
                  faceUp: _showFront,
                  width: 180,
                  height: 250,
                  overrideSkin: widget.overrideSkin,
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
                  .shimmer(delay: 1200.ms, duration: 1500.ms, color: Colors.white30)
                  // 5. Tremblement si ce n'est pas la vérité (carte rouge/choc)
                  .shake(delay: 1000.ms, duration: 500.ms, hz: widget.isTruth ? 0 : 8, curve: Curves.easeInOutCubic)
                  // 6. S'envole vers le haut et disparaît
                  .slideY(begin: 0, end: -2.0, delay: 3500.ms, duration: 500.ms, curve: Curves.easeInBack)
                  .scale(begin: const Offset(1.3, 1.3), end: const Offset(0.5, 0.5), delay: 3500.ms, duration: 500.ms)
                  .fadeOut(delay: 3700.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper pour afficher l'animation facilement depuis un State
void showTotemAnimation(BuildContext context, PyraCard card, bool isTruth, {String? overrideSkin}) {
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => TotemCardAnimation(
      card: card,
      isTruth: isTruth,
      overrideSkin: overrideSkin,
      onAnimationComplete: () {
        overlayEntry.remove();
      },
    ),
  );
  
  Overlay.of(context).insert(overlayEntry);
}

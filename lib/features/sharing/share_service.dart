import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../game/models/game_state.dart';
import 'moment_card.dart';

/// Service for showing shareable moment cards.
/// Displays a full-screen overlay with the moment card that users can screenshot.
class ShareService {
  /// Shows a moment card overlay for a key game event.
  /// The user can screenshot the moment or simply close it.
  static void showMomentOverlay(BuildContext context, MomentData moment) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Moment',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _MomentOverlay(moment: moment);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack));
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Creates a MomentData for a bluff caught event.
  static MomentData createBluffCaughtMoment({
    required String blufferName,
    required String catcherName,
    required int penalties,
    required GameMode gameMode,
  }) {
    return MomentData(
      type: MomentType.bluffCaught,
      eventText: '$blufferName a bluffe et s\'est fait attraper !',
      playerNames: [blufferName, catcherName],
      gameMode: gameMode,
      penaltyCount: penalties,
    );
  }

  /// Creates a MomentData for a successful bluff.
  static MomentData createBluffSuccessMoment({
    required String blufferName,
    required String targetName,
    required int penalties,
    required GameMode gameMode,
  }) {
    return MomentData(
      type: MomentType.bluffSuccess,
      eventText: '$blufferName a bluffe avec succes !',
      playerNames: [blufferName, targetName],
      gameMode: gameMode,
      penaltyCount: penalties,
    );
  }

  /// Creates a MomentData for a big penalty event.
  static MomentData createBigPenaltyMoment({
    required String playerName,
    required int penalties,
    required GameMode gameMode,
  }) {
    return MomentData(
      type: MomentType.bigPenalty,
      eventText: '$playerName prend une grosse penalite !',
      playerNames: [playerName],
      gameMode: gameMode,
      penaltyCount: penalties,
    );
  }

  /// Creates a MomentData for game finished.
  static MomentData createGameFinishedMoment({
    required String winnerName,
    required List<String> playerNames,
    required GameMode gameMode,
  }) {
    return MomentData(
      type: MomentType.gameFinished,
      eventText: '$winnerName remporte la partie !',
      playerNames: playerNames,
      gameMode: gameMode,
    );
  }
}

class _MomentOverlay extends StatelessWidget {
  final MomentData moment;

  const _MomentOverlay({required this.moment});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hint text
            Text(
              'Capture ce moment !',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            // The moment card itself
            Center(
              child: MomentCard(moment: moment),
            ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 32),
            // Close button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'Fermer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

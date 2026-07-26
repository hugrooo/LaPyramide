import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme.dart';
import '../game/models/game_state.dart';
import 'moment_card.dart';

/// Service for showing shareable moment cards.
/// Displays a full-screen overlay with the moment card and a share button
/// that opens the native share sheet with a screenshot of the card.
class ShareService {
  /// Shows a moment card overlay for a key game event.
  /// The user can share the moment via the native share sheet or close it.
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

  /// Captures the widget bound to [repaintKey] as a PNG and opens the native
  /// share sheet with the image and a short text.
  static Future<void> shareCardImage(GlobalKey repaintKey, String text) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pyramide_moment.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
      );
    } catch (e) {
      // Fallback to text-only share if image capture fails
      await Share.share(text);
    }
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

class _MomentOverlay extends StatefulWidget {
  final MomentData moment;

  const _MomentOverlay({required this.moment});

  @override
  State<_MomentOverlay> createState() => _MomentOverlayState();
}

class _MomentOverlayState extends State<_MomentOverlay> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();

    final text =
        '${widget.moment.eventText} - Pyramide Party\nhttps://pyramideparty.fr';
    await ShareService.shareCardImage(_repaintKey, text);

    if (mounted) setState(() => _isSharing = false);
  }

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
              'Partage ce moment !',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            // The moment card itself wrapped in RepaintBoundary for capture
            RepaintBoundary(
              key: _repaintKey,
              child: Center(
                child: MomentCard(moment: widget.moment),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 32),
            // Share button
            GestureDetector(
              onTap: _handleShare,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [PyraTheme.primaryCyan, PyraTheme.primaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSharing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.share_rounded,
                          color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    const Text(
                      'Partager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
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
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../game/models/game_state.dart';

/// Types of shareable moments
enum MomentType {
  bluffCaught,
  bluffSuccess,
  bigPenalty,
  gameFinished,
  epicPlay,
}

/// Data for a shareable moment
class MomentData {
  final MomentType type;
  final String eventText;
  final List<String> playerNames;
  final GameMode gameMode;
  final int? penaltyCount;

  const MomentData({
    required this.type,
    required this.eventText,
    required this.playerNames,
    required this.gameMode,
    this.penaltyCount,
  });
}

/// A beautifully designed moment card for sharing key game events.
class MomentCard extends StatelessWidget {
  final MomentData moment;

  const MomentCard({super.key, required this.moment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _backgroundGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Branding header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _gameModeIcon,
                    const SizedBox(width: 6),
                    const Text(
                      'PYRAMIDE PARTY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Moment type emoji
          Text(
            _momentEmoji,
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 16),
          // Event text
          Text(
            moment.eventText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Players involved
          if (moment.playerNames.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: moment.playerNames.map((name) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          if (moment.penaltyCount != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: PyraTheme.primaryOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PyraTheme.primaryOrange.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '+${moment.penaltyCount} penalites',
                style: const TextStyle(
                  color: PyraTheme.primaryOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Footer
          Text(
            'pyramideparty.fr',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient get _backgroundGradient {
    switch (moment.type) {
      case MomentType.bluffCaught:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a0533), Color(0xFF330a1a), Color(0xFF1a0533)],
        );
      case MomentType.bluffSuccess:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0a1a33), Color(0xFF0a3320), Color(0xFF0a1a33)],
        );
      case MomentType.bigPenalty:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF331a0a), Color(0xFF33290a), Color(0xFF1a0a0a)],
        );
      case MomentType.gameFinished:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0a0a33), Color(0xFF1a0a33), Color(0xFF0a1a33)],
        );
      case MomentType.epicPlay:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001a33), Color(0xFF003333), Color(0xFF001a33)],
        );
    }
  }

  Color get _accentColor {
    switch (moment.type) {
      case MomentType.bluffCaught:
        return PyraTheme.primaryPink;
      case MomentType.bluffSuccess:
        return PyraTheme.primaryGreen;
      case MomentType.bigPenalty:
        return PyraTheme.primaryOrange;
      case MomentType.gameFinished:
        return PyraTheme.primaryYellow;
      case MomentType.epicPlay:
        return PyraTheme.primaryCyan;
    }
  }

  String get _momentEmoji {
    switch (moment.type) {
      case MomentType.bluffCaught:
        return '🎭';
      case MomentType.bluffSuccess:
        return '😈';
      case MomentType.bigPenalty:
        return '💥';
      case MomentType.gameFinished:
        return '🏆';
      case MomentType.epicPlay:
        return '⚡';
    }
  }

  Widget get _gameModeIcon {
    IconData icon;
    switch (moment.gameMode) {
      case GameMode.classic:
        icon = Icons.style_rounded;
        break;
      case GameMode.powers:
        icon = Icons.bolt_rounded;
        break;
      case GameMode.secretMissions:
        icon = Icons.lock_rounded;
        break;
      case GameMode.miniGames:
        icon = Icons.games_rounded;
        break;
      case GameMode.truthOrSip:
        icon = Icons.question_mark_rounded;
        break;
      case GameMode.speedRun:
        icon = Icons.timer_rounded;
        break;
    }
    return Icon(icon, color: Colors.white70, size: 14);
  }
}

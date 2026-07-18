import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../../shared/widgets/pulsar_button.dart';

/// Pass-the-phone screen shown between players in local mode.
/// Displays a prompt to hand the phone to the next player before
/// revealing their cards.
class PassPhoneScreen extends StatelessWidget {
  final String playerName;
  final String playerEmoji;
  final VoidCallback onReady;

  const PassPhoneScreen({
    super.key,
    required this.playerName,
    required this.playerEmoji,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(playerEmoji, style: const TextStyle(fontSize: 80))
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  Text(
                    'Passe le telephone a',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    playerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: PulsarButton(
                      text: 'Je suis $playerName',
                      gradient: PyraTheme.purplePinkGradient,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onReady();
                      },
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                  const SizedBox(height: 16),
                  Text(
                    'Ne regarde pas avant !',
                    style: TextStyle(
                      color: PyraTheme.primaryYellow.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';
import 'dart:math' as math;

import '../models/player_model.dart';
import '../models/card_model.dart';

import 'package:confetti/confetti.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pulsar_button.dart';
import '../../profile/user_profile_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../auth/auth_service.dart';

/// Overlay animé affiché quand un joueur doit boire
class DrinkOverlay extends ConsumerStatefulWidget {
  final Player player;
  final int sips;
  final VoidCallback onDismiss;
  final String? message;

  const DrinkOverlay({
    super.key,
    required this.player,
    required this.sips,
    required this.onDismiss,
    this.message,
  });

  @override
  ConsumerState<DrinkOverlay> createState() => _DrinkOverlayState();
}

class _DrinkOverlayState extends ConsumerState<DrinkOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    HapticFeedback.heavyImpact();

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji bière animé
                const Text('🍺', style: TextStyle(fontSize: 80))
                    .animate(onPlay: (ctrl) => ctrl.repeat())
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.2, 1.2),
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                    ),

                const SizedBox(height: 24),

                // Avatar et nom
                Text(
                  '${widget.player.emoji} ${widget.player.name}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                // Message de pouvoir éventuel
                if (widget.message != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PyraTheme.primaryPink.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PyraTheme.primaryPink.withOpacity(0.5)),
                      boxShadow: PyraTheme.glowPurple,
                    ),
                    child: Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms).scale(curve: Curves.elasticOut),

                if (widget.message == null)
                  const SizedBox(height: 12),

                // Texte "doit boire"
                if (widget.message == null)
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        PyraTheme.orangeYellowGradient.createShader(bounds),
                    child: Text(
                      'doit boire',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                // Compteur de gorgées
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: PyraTheme.orangeYellowGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: PyraTheme.glowOrange,
                  ),
                  child: Text(
                    '${widget.sips} gorgée${widget.sips > 1 ? 's' : ''} !',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      delay: 400.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 32),

                // Bouton Joker (si le joueur actuel est celui qui boit et a assez de pièces)
                Consumer(
                  builder: (context, ref, child) {
                    final currentUser = ref.watch(authStateChangesProvider).value;
                    // Vérifier si c'est le joueur actuel (on suppose que le pseudo ou l'ID correspond)
                    if (currentUser != null && currentUser.displayName == widget.player.name) {
                      final profile = ref.watch(userProfileProvider).value;
                      final coins = profile?.coins ?? 0;
                      
                      return Column(
                        children: [
                          if (coins >= 50)
                            PulsarButton(
                              text: 'Utiliser un Joker (50 pièces)',
                              gradient: PyraTheme.cyanGradient,
                              paddingHorizontal: 24,
                              onPressed: () async {
                                // Déduire 50 pièces
                                final dbRef = FirebaseDatabase.instance.ref('users/${currentUser.uid}/coins');
                                await dbRef.set(coins - 50);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Joker utilisé !')),
                                );
                                widget.onDismiss();
                              },
                            )
                          else
                            const Text('Pas assez de pièces pour un Joker (50)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Instruction
                Text(
                  'Appuie n\'importe où pour continuer',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PyraTheme.textMuted,
                      ),
                )
                    .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                    .fadeIn(delay: 1000.ms)
                    .then()
                    .fadeOut(duration: 1000.ms),
              ],
            ),
            // Confetti effect
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  PyraTheme.primaryOrange,
                  PyraTheme.primaryPink,
                  PyraTheme.primaryCyan,
                  PyraTheme.primaryYellow,
                ],
                createParticlePath: drawStar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A custom Path to paint stars for confetti.
  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
          halfWidth + externalRadius * math.cos(step),
          halfWidth + externalRadius * math.sin(step));
      path.lineTo(
          halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * math.sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}

/// Dialog de bluff — Challenge ou Accepter
class BluffDialog extends StatefulWidget {
  final Player accuser;  // Celui qui a posé la carte
  final Player accused;  // Celui qui doit boire ou challenger
  final int sips;
  final List<PyraCard> availablePowers;
  final VoidCallback onChallenge;
  final VoidCallback onAccept;
  final void Function(String cardId)? onUsePower;

  const BluffDialog({
    super.key,
    required this.accuser,
    required this.accused,
    required this.sips,
    this.availablePowers = const [],
    required this.onChallenge,
    required this.onAccept,
    this.onUsePower,
  });

  @override
  State<BluffDialog> createState() => _BluffDialogState();
}

class _BluffDialogState extends State<BluffDialog> {
  int _countdown = 10;
  late final _timer = Stream.periodic(const Duration(seconds: 1), (i) => 9 - i)
      .take(10)
      .listen((v) {
    if (mounted) setState(() => _countdown = v);
    if (v == 0) widget.onAccept(); // Auto-accept si pas de réponse
  });

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        innerGlow: true,
        padding: const EdgeInsets.all(28),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: PyraTheme.primaryOrange.withOpacity(0.5), width: 2),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
            Text(
              '😈 Bluff ?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: PyraTheme.primaryPink,
                  ),
            ).animate().fadeIn().scale(),

            const SizedBox(height: 16),

            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                children: [
                  TextSpan(
                    text: '${widget.accuser.emoji} ${widget.accuser.name} ',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: 'envoie '),
                  TextSpan(
                    text: '${widget.sips} gorgée${widget.sips > 1 ? 's' : ''} ',
                    style: TextStyle(
                        color: PyraTheme.primaryOrange,
                        fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: 'à '),
                  TextSpan(
                    text: '${widget.accused.emoji} ${widget.accused.name}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '\n\nEst-ce un bluff ?'),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Compte à rebours
            Text(
              '$_countdown',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _countdown <= 3
                    ? PyraTheme.primaryPink
                    : PyraTheme.textMuted,
              ),
            ).animate(target: _countdown <= 3 ? 1 : 0).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.2, 1.2),
                  duration: 300.ms,
                ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: PulsarButton(
                    paddingHorizontal: 8,
                    paddingVertical: 14,
                    text: '⚡ Challenge !',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _timer.cancel();
                      widget.onChallenge();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PulsarButton(
                    paddingHorizontal: 8,
                    paddingVertical: 14,
                    text: '✅ J\'accepte',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _timer.cancel();
                      widget.onAccept();
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

            if (widget.availablePowers.isNotEmpty && widget.onUsePower != null) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              const Text(
                'Ou utiliser un pouvoir :',
                style: TextStyle(color: PyraTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: widget.availablePowers.map((power) {
                  return PulsarButton(
                    paddingHorizontal: 16,
                    paddingVertical: 12,
                    text: '${power.powerType.emoji} ${power.powerType.name}',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _timer.cancel();
                      widget.onUsePower!(power.id);
                    },
                  );
                }).toList(),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

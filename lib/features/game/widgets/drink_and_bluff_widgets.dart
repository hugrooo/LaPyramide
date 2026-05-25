import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';
import '../models/player_model.dart';
import '../models/card_model.dart';

/// Overlay animé affiché quand un joueur doit boire
class DrinkOverlay extends StatelessWidget {
  final Player player;
  final int sips;
  final VoidCallback onDismiss;

  const DrinkOverlay({
    super.key,
    required this.player,
    required this.sips,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    HapticFeedback.heavyImpact();

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Column(
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
                '${player.emoji} ${player.name}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                    ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

              const SizedBox(height: 12),

              // Texte "doit boire"
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
                  '$sips gorgée${sips > 1 ? 's' : ''} !',
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

              const SizedBox(height: 48),

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
        ),
      ),
    );
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
      backgroundColor: PyraTheme.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
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
                  child: _DialogButton(
                    label: '⚡ Je Challenge !',
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
                  child: _DialogButton(
                    label: '✅ J\'accepte',
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
                  return _DialogButton(
                    label: '${power.powerType.emoji} ${power.powerType.name}',
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

class _DialogButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onPressed;

  const _DialogButton({
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

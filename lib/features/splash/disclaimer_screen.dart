import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _accepted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAlreadyAccepted();
  }

  Future<void> _checkAlreadyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAccepted = prefs.getBool('disclaimer_accepted') ?? false;
    if (alreadyAccepted && mounted) {
      context.goNamed('home');
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndContinue() async {
    if (!_accepted) return;
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);
    if (mounted) context.goNamed('home');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PyraTheme.mainGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône animée
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                    ),
                    boxShadow: PyraTheme.glowOrange,
                  ),
                  child: const Center(
                    child: Text('⚠️', style: TextStyle(fontSize: 48)),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.5, 0.5)),

                const SizedBox(height: 32),

                // Titre
                Text(
                  l10n.disclaimer_title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: PyraTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.3),

                const SizedBox(height: 24),

                // Corps du message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: PyraTheme.bgCard.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: PyraTheme.primaryOrange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    l10n.disclaimer_body,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: PyraTheme.textSecondary,
                          height: 1.6,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 28),

                // Checkbox
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _accepted = !_accepted);
                  },
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: 300.ms,
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _accepted
                                ? PyraTheme.primaryPurple
                                : PyraTheme.textMuted,
                            width: 2,
                          ),
                          gradient: _accepted
                              ? PyraTheme.purplePinkGradient
                              : null,
                        ),
                        child: _accepted
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.disclaimer_checkbox,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _accepted
                                    ? PyraTheme.textPrimary
                                    : PyraTheme.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 600.ms),

                const SizedBox(height: 32),

                // Bouton confirmer
                AnimatedOpacity(
                  opacity: _accepted ? 1.0 : 0.4,
                  duration: 300.ms,
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _accepted
                            ? PyraTheme.purplePinkGradient
                            : null,
                        color: _accepted ? null : PyraTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _accepted ? PyraTheme.glowPurple : null,
                      ),
                      child: ElevatedButton(
                        onPressed: _accepted ? _confirmAndContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.disclaimer_confirm,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms, duration: 600.ms).slideY(begin: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

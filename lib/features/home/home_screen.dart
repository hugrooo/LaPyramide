import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/animated_background.dart';
import '../../core/audio/audio_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _savedRoomCode;
  String _savedAvatar = '😎';
  bool _isMuted = false;
  static const List<String> _avatars = ['😎', '🤠', '👻', '👽', '🤖', '💩', '🤡', '🦄', '🦁', '🦊'];

  @override
  void initState() {
    super.initState();
    _loadSavedRoom();
  }

  Future<void> _loadSavedRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('currentRoomCode');
    final avatar = prefs.getString('userAvatar');
    final isMuted = prefs.getBool('isMuted') ?? false;
    
    if (mounted) {
      setState(() {
        if (code != null && code.isNotEmpty) _savedRoomCode = code;
        if (avatar != null) _savedAvatar = avatar;
        _isMuted = isMuted;
      });
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PyraTheme.bgDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisis ton Avatar', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _avatars.map((emoji) {
                  return GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('userAvatar', emoji);
                      if (mounted) setState(() => _savedAvatar = emoji);
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _savedAvatar == emoji ? PyraTheme.primaryOrange.withOpacity(0.3) : PyraTheme.bgCard,
                        shape: BoxShape.circle,
                        border: _savedAvatar == emoji ? Border.all(color: PyraTheme.primaryOrange, width: 2) : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Fond animé avec particules
          const AnimatedBackground(),

          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 28),
                    onPressed: () async {
                      setState(() => _isMuted = !_isMuted);
                      AudioManager().setMuted(_isMuted);
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _showAvatarPicker,
                    child: CircleAvatar(
                      backgroundColor: PyraTheme.bgCard.withOpacity(0.6),
                      radius: 26,
                      child: Text(_savedAvatar, style: const TextStyle(fontSize: 28)),
                    ),
                  ).animate().scale(delay: 500.ms),
                ),
                // Colonne principale centrée prenant tout l'espace disponible
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),

                        // Logo / Titre
                        _buildLogo(context, l10n),

                        const Spacer(flex: 1),

                        // Boutons principaux
                        _buildButtons(context, l10n),

                        if (_savedRoomCode != null) ...[
                          const SizedBox(height: 24),
                          const Text('Partie en cours détectée', style: TextStyle(color: PyraTheme.textSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          PulsarButton(
                            text: 'Rejoindre $_savedRoomCode',
                            gradient: PyraTheme.festiveGradient,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.pushNamed('onlineGame', pathParameters: {'roomId': _savedRoomCode!});
                            },
                          ).animate().fadeIn().slideY(),
                        ],

                        const Spacer(flex: 1),

                        // Boutons secondaires
                        _buildSecondaryButtons(context, l10n),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // Pyramide emoji animée
        ShaderMask(
          shaderCallback: (bounds) => PyraTheme.festiveGradient.createShader(bounds),
          child: const Text(
            '🔺',
            style: TextStyle(fontSize: 80),
          ),
        )
            .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.08, 1.08),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            ),

        const SizedBox(height: 16),

        // Titre principal avec shader gradient
        ShaderMask(
          shaderCallback: (bounds) => PyraTheme.festiveGradient.createShader(bounds),
          child: Text(
            l10n.appName,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .slideY(begin: -0.3, curve: Curves.easeOut),

        const SizedBox(height: 8),

        Text(
          l10n.home_subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: PyraTheme.textSecondary,
                letterSpacing: 1,
              ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // Jouer en local
        PulsarButton(
          text: l10n.home_play_local,
          gradient: PyraTheme.purplePinkGradient,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pushNamed('localLobby');
          },
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideX(begin: -0.3),

        const SizedBox(height: 16),

        // Jouer en ligne
        PulsarButton(
          text: l10n.home_play_online,
          gradient: PyraTheme.orangeYellowGradient,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pushNamed('auth');
          },
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 600.ms)
            .slideX(begin: 0.3),
      ],
    );
  }

  Widget _buildSecondaryButtons(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: _SecondaryButton(
            label: l10n.home_rules,
            onPressed: () => context.pushNamed('rules'),
          ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: _SecondaryButton(
            label: 'Classement',
            onPressed: () => context.pushNamed('leaderboard'),
          ).animate().fadeIn(delay: 750.ms, duration: 600.ms),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: _SecondaryButton(
            label: l10n.home_settings,
            onPressed: () => context.pushNamed('settings'),
          ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: Border.all(
          color: PyraTheme.primaryPurple.withOpacity(0.4),
          width: 1.5,
        ),
        color: PyraTheme.bgCard,
        opacity: 0.3,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: PyraTheme.textSecondary,
                fontSize: 13,
              ),
        ),
      ),
    );
  }
}

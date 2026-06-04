import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../auth/auth_service.dart';
import '../profile/user_profile_provider.dart';
import 'settings_provider.dart';
import '../../shared/widgets/pulsar_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final profile = ref.watch(userProfileProvider).value;
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: const Text(
                      '⚙️ Paramètres',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Carte Profil (raccourci) ─────────────────────
                      if (profile != null && user != null)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.pushNamed('level');
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: PyraTheme.primaryCyan.withOpacity(0.25)),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: PyraTheme.bgSurface,
                                    border: Border.all(
                                        color: PyraTheme.primaryCyan
                                            .withOpacity(0.4),
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: PyraTheme.primaryCyan
                                              .withOpacity(0.2),
                                          blurRadius: 12)
                                    ],
                                  ),
                                  child: Center(
                                      child: Text(profile.emoji,
                                          style:
                                              const TextStyle(fontSize: 26))),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name ?? user.displayName ?? 'Mon Profil',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  PyraTheme.purplePinkGradient,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              profile.activeTitle.toUpperCase(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Niv. ${profile.level}',
                                              style: const TextStyle(
                                                  color: PyraTheme.primaryCyan,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 6,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: (profile.xp / (profile.level * 100)).clamp(0.0, 1.0),
                                            child: Container(
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: PyraTheme.primaryCyan,
                                                borderRadius: BorderRadius.circular(3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: PyraTheme.primaryCyan.withOpacity(0.5),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${profile.xp} / ${profile.level * 100} XP',
                                          style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                // Flèche + label
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Voir le profil',
                                        style: TextStyle(
                                            color: PyraTheme.primaryCyan,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: PyraTheme.primaryCyan, size: 13),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      _SettingsGroup(
                        title: 'AUDIO & HAPTIQUE',
                        children: [
                          _VolumeSliderTile(
                            icon: Icons.volume_up_rounded,
                            label: 'Bruitages (SFX)',
                            value: settings.sfxVolume,
                            onChanged: (v) =>
                                settingsNotifier.updateSfxVolume(v),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SettingTile(
                            icon: Icons.vibration_rounded,
                            label: 'Vibrations',
                            value: settings.vibrationEnabled,
                            onChanged: (v) =>
                                settingsNotifier.toggleVibration(v),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),



                      _SettingsGroup(
                        title: 'SUPPORT & INFOS',
                        children: [
                          ListTile(
                            leading: const Icon(Icons.help_outline_rounded,
                                color: PyraTheme.primaryYellow),
                            title: const Text('Revoir le tutoriel',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white30,
                                size: 16),
                            onTap: () {
                              settingsNotifier.resetTutorial();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Le tutoriel sera relancé à votre prochaine partie !')),
                              );
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.bug_report_rounded,
                                color: PyraTheme.primaryPink),
                            title: const Text('Signaler un bug / Support',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded,
                                color: Colors.white30, size: 16),
                            onTap: () => _launchUrl(
                                'mailto:contact@pyramideparty.fr?subject=Support%20Pyramide%20Party'),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_rounded,
                                color: PyraTheme.primaryCyan),
                            title: const Text('Politique de confidentialité',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded,
                                color: Colors.white30, size: 16),
                            onTap: () =>
                                _launchUrl('https://pyramideparty.fr/privacy'),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.description_rounded,
                                color: Colors.white70),
                            title: const Text('Conditions d\'utilisation',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded,
                                color: Colors.white30, size: 16),
                            onTap: () =>
                                _launchUrl('https://pyramideparty.fr/terms'),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),

                      _SettingsGroup(
                        title: 'GESTION DU COMPTE',
                        borderColor: Colors.redAccent.withOpacity(0.3),
                        children: [
                          Consumer(builder: (context, ref, child) {
                            return ListTile(
                              leading: const Icon(Icons.logout_rounded, color: Colors.white70),
                              title: const Text('Se déconnecter',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onTap: () async {
                                await ref.read(authServiceProvider).signOut();
                                if (context.mounted) {
                                  context.goNamed('auth');
                                }
                              },
                            );
                          }),
                          const Divider(color: Colors.white10, height: 1),
                          Consumer(builder: (context, ref, child) {
                            return ListTile(
                              leading: const Icon(Icons.warning_rounded, color: Colors.redAccent),
                              title: const Text('Supprimer mon compte',
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: PyraTheme.bgCard,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    title: const Text('⚠️ Attention',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    content: const Text(
                                      'Cette action est irréversible. Toutes vos statistiques, XP, jokers et cosmétiques seront définitivement perdus. Êtes-vous sûr de vouloir continuer ?',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Annuler',
                                            style: TextStyle(color: Colors.white)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await ref.read(authServiceProvider).signOut();
                                          if (context.mounted) {
                                            context.goNamed('auth');
                                          }
                                        },
                                        child: const Text('Supprimer',
                                            style: TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Pyramide Party v1.0.2\nApp Store Review Build',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: PyraTheme.textMuted, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? borderColor;

  const _SettingsGroup({required this.title, required this.children, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
                color: PyraTheme.primaryPurple,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 2),
          ),
        ),
        GlassContainer(
          borderRadius: BorderRadius.circular(24),
          padding: EdgeInsets.zero,
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          child: Material(
            color: Colors.transparent,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: PyraTheme.primaryPurple,
            activeTrackColor: PyraTheme.primaryPurple.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

class _VolumeSliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${(value * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: PyraTheme.primaryCyan,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: PyraTheme.primaryCyan.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}



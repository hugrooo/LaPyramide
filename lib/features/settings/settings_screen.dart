import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
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

  Future<void> _updateProfileField(String field, dynamic value, String uid) async {
    final dbRef = FirebaseDatabase.instance.ref('users/$uid');
    await dbRef.update({field: value});
  }

  void _showEmojiPicker(BuildContext context, String uid, String currentEmoji) {
    final List<String> emojis = ['😎', '👤', '🐱', '🐶', '🦊', '🦁', '🐼', '🐸', '🦄', '🍹', '🃏', '👑'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text('Sélectionner un Avatar', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                final emoji = emojis[index];
                final isSelected = emoji == currentEmoji;
                return GestureDetector(
                  onTap: () {
                    _updateProfileField('emoji', emoji, uid);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? PyraTheme.primaryCyan.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? PyraTheme.primaryCyan : Colors.white12, width: 2),
                      boxShadow: isSelected ? [BoxShadow(color: PyraTheme.primaryCyan.withOpacity(0.5), blurRadius: 10)] : null,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                ).animate().scale(delay: (index * 20).ms, duration: 200.ms);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTitlePicker(BuildContext context, String uid, String currentTitle, List<String> ownedTitles) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text('Choisir un Titre', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: ownedTitles.length,
              itemBuilder: (context, index) {
                final title = ownedTitles[index];
                final isSelected = title == currentTitle;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      _updateProfileField('activeTitle', title, uid);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? PyraTheme.primaryPink.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? PyraTheme.primaryPink : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: PyraTheme.primaryPink, size: 24),
                        ],
                      ),
                    ),
                  ).animate().slideX(delay: (index * 30).ms, duration: 300.ms),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCardBackPicker(BuildContext context, String uid, String currentBack, List<String> ownedBacks) {
    final Map<String, String> backNames = {
      'classic': 'Classique Rouge 🟥',
      'neon': 'Néon Cyberpunk ⚡',
      'pirate': 'Pirate Doré ☠️',
      'retro': 'Rétro Pixel 👾',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text('Sélectionner un Dos de Cartes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: ownedBacks.length,
              itemBuilder: (context, index) {
                final backId = ownedBacks[index];
                final backName = backNames[backId] ?? backId;
                final isSelected = backId == currentBack;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      _updateProfileField('activeCardBack', backId, uid);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? PyraTheme.primaryCyan.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? PyraTheme.primaryCyan : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(backName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: PyraTheme.primaryCyan, size: 24),
                        ],
                      ),
                    ),
                  ).animate().slideX(delay: (index * 30).ms, duration: 300.ms),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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
    
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '⚙️ Paramètres',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Profil Customization Group
                      if (profile != null && user != null) ...[
                        _SettingsGroup(
                          title: 'MON APPARENCE',
                          children: [
                            ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Center(child: Text(profile.emoji, style: const TextStyle(fontSize: 24))),
                              ),
                              title: const Text('Avatar de Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Modifier votre émoticône', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                              onTap: () => _showEmojiPicker(context, user.uid, profile.emoji),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            ListTile(
                              leading: const Icon(Icons.military_tech_rounded, color: PyraTheme.primaryPink),
                              title: const Text('Titre Affiché', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(profile.activeTitle, style: const TextStyle(color: PyraTheme.primaryPink, fontSize: 13, fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                              onTap: () => _showTitlePicker(context, user.uid, profile.activeTitle, profile.titles),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            ListTile(
                              leading: const Icon(Icons.style_rounded, color: PyraTheme.primaryCyan),
                              title: const Text('Dos de Cartes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                profile.activeCardBack == 'classic' ? 'Classique Rouge' : 
                                profile.activeCardBack == 'neon' ? 'Néon Cyberpunk' : 
                                profile.activeCardBack == 'pirate' ? 'Pirate Doré' : 'Rétro Pixel',
                                style: const TextStyle(color: PyraTheme.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                              onTap: () => _showCardBackPicker(context, user.uid, profile.activeCardBack, profile.cardBacks),
                            ),
                          ],
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                      ],

                      _SettingsGroup(
                        title: 'AUDIO & HAPTIQUE',
                        children: [
                          _VolumeSliderTile(
                            icon: Icons.music_note_rounded,
                            label: 'Musique',
                            value: settings.musicVolume,
                            onChanged: (v) => settingsNotifier.updateMusicVolume(v),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _VolumeSliderTile(
                            icon: Icons.volume_up_rounded,
                            label: 'Bruitages (SFX)',
                            value: settings.sfxVolume,
                            onChanged: (v) => settingsNotifier.updateSfxVolume(v),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SettingTile(
                            icon: Icons.vibration_rounded,
                            label: 'Vibrations',
                            value: settings.vibrationEnabled,
                            onChanged: (v) => settingsNotifier.toggleVibration(v),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      _SettingsGroup(
                        title: 'ACCESSIBILITÉ & LANGUE',
                        children: [
                          _SettingTile(
                            icon: Icons.visibility_rounded,
                            label: 'Mode daltonien',
                            value: settings.colorBlindMode,
                            onChanged: (v) => settingsNotifier.toggleColorBlindMode(v),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _LanguageTile(
                            selected: settings.language,
                            onChanged: (lang) => settingsNotifier.setLanguage(lang),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      _SettingsGroup(
                        title: 'SUPPORT & INFOS',
                        children: [
                          ListTile(
                            leading: const Icon(Icons.help_outline_rounded, color: PyraTheme.primaryYellow),
                            title: const Text('Revoir le tutoriel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                            onTap: () {
                              settingsNotifier.resetTutorial();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Le tutoriel sera relancé à votre prochaine partie !')),
                              );
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.bug_report_rounded, color: PyraTheme.primaryPink),
                            title: const Text('Signaler un bug / Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () => _launchUrl('mailto:support@lapyramide.app?subject=Support%20Pyramide%20Party'),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_rounded, color: PyraTheme.primaryCyan),
                            title: const Text('Politique de confidentialité', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () => _launchUrl('https://lapyramide.app/privacy'),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.description_rounded, color: Colors.white70),
                            title: const Text('Conditions d\'utilisation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () => _launchUrl('https://lapyramide.app/terms'),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),

                      Consumer(
                        builder: (context, ref, child) {
                          return Center(
                            child: PulsarButton(
                              text: 'Se déconnecter',
                              paddingHorizontal: 32,
                              gradient: const LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
                              onPressed: () async {
                                await ref.read(authServiceProvider).signOut();
                                if (context.mounted) {
                                  context.goNamed('auth');
                                }
                              },
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          return Center(
                            child: TextButton.icon(
                              icon: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 16),
                              label: const Text('Supprimer mon compte', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: PyraTheme.bgCard,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Text('⚠️ Attention', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    content: const Text(
                                      'Cette action est irréversible. Toutes vos statistiques, XP, jokers et cosmétiques seront définitivement perdus. Êtes-vous sûr de vouloir continuer ?',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Annuler', style: TextStyle(color: Colors.white)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await ref.read(authServiceProvider).signOut();
                                          if (context.mounted) {
                                            context.goNamed('auth');
                                          }
                                        },
                                        child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Pyramide Party v1.0.2\nApp Store Review Build',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: PyraTheme.textMuted, fontSize: 12),
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

  const _SettingsGroup({required this.title, required this.children});

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
          child: Column(children: children),
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
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
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
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.white54, fontSize: 14)),
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

class _LanguageTile extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _LanguageTile({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          for (final lang in [
            ('fr', '🇫🇷 Français'),
            ('en', '🇬🇧 English')
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(lang.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: lang.$1 == 'fr' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: selected == lang.$1 ? PyraTheme.purplePinkGradient : null,
                    color: selected == lang.$1 ? null : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected == lang.$1 ? Colors.transparent : Colors.white12),
                  ),
                  child: Text(
                    lang.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected == lang.$1 ? Colors.white : Colors.white54, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

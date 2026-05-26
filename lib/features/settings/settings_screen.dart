import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../auth/auth_service.dart';
import 'settings_provider.dart';
import '../../shared/widgets/pulsar_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => context.pop(),
                  ),
                  title: const Text('⚙️ Paramètres'),
                  centerTitle: true,
                  floating: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SettingsGroup(
                        title: 'Audio & Haptique',
                        children: [
                          _SettingTile(
                            emoji: '🔊',
                            label: 'Sons',
                            value: settings.soundEnabled,
                            onChanged: (v) => settingsNotifier.toggleSound(v),
                          ),
                          _SettingTile(
                            emoji: '📳',
                            label: 'Vibrations',
                            value: settings.vibrationEnabled,
                            onChanged: (v) => settingsNotifier.toggleVibration(v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SettingsGroup(
                        title: 'Accessibilité',
                        children: [
                          _SettingTile(
                            emoji: '👁️',
                            label: 'Mode daltonien',
                            value: settings.colorBlindMode,
                            onChanged: (v) => settingsNotifier.toggleColorBlindMode(v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SettingsGroup(
                        title: 'Langue / Language',
                        children: [
                          _LanguageTile(
                            selected: 'fr',
                            onChanged: (lang) {}, // Pas encore géré globalement
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: PulsarButton(
                          text: '🏆 Classement des Joueurs',
                          paddingHorizontal: 24,
                          gradient: PyraTheme.orangeYellowGradient,
                          onPressed: () {
                            context.pushNamed('leaderboard');
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Consumer(
                        builder: (context, ref, child) {
                          return Center(
                            child: PulsarButton(
                              text: 'Se déconnecter',
                              paddingHorizontal: 32,
                              gradient: const LinearGradient(colors: [Colors.redAccent, Colors.pink]),
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
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Pyramide Party v1.0.1',
                          style: TextStyle(
                              color: PyraTheme.textMuted, fontSize: 12),
                        ),
                      ),
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
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
                color: PyraTheme.primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: PyraTheme.bgCard.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: PyraTheme.primaryPurple,
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
      padding: const EdgeInsets.all(16),
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
                    gradient: selected == lang.$1
                        ? PyraTheme.purplePinkGradient
                        : null,
                    color: selected == lang.$1 ? null : PyraTheme.bgDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lang.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _colorBlindMode = false;
  String _language = 'fr';

  @override
  Widget build(BuildContext context) {
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
                            value: _soundEnabled,
                            onChanged: (v) => setState(() => _soundEnabled = v),
                          ),
                          _SettingTile(
                            emoji: '📳',
                            label: 'Vibrations',
                            value: _vibrationEnabled,
                            onChanged: (v) => setState(() => _vibrationEnabled = v),
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
                            value: _colorBlindMode,
                            onChanged: (v) => setState(() => _colorBlindMode = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SettingsGroup(
                        title: 'Langue / Language',
                        children: [
                          _LanguageTile(
                            selected: _language,
                            onChanged: (lang) => setState(() => _language = lang),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'La Pyramide v1.0.0',
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

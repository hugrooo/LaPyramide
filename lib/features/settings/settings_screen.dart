import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sélectionner un Avatar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
                    color: isSelected ? PyraTheme.primaryCyan.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? PyraTheme.primaryCyan : Colors.white12, width: 2),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTitlePicker(BuildContext context, String uid, String currentTitle, List<String> ownedTitles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Choisir un Titre de Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ownedTitles.length,
            itemBuilder: (context, index) {
              final title = ownedTitles[index];
              final isSelected = title == currentTitle;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    _updateProfileField('activeTitle', title, uid);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? PyraTheme.primaryPink.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? PyraTheme.primaryPink : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: PyraTheme.primaryPink, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sélectionner un Dos de Cartes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ownedBacks.length,
            itemBuilder: (context, index) {
              final backId = ownedBacks[index];
              final backName = backNames[backId] ?? backId;
              final isSelected = backId == currentBack;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    _updateProfileField('activeCardBack', backId, uid);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? PyraTheme.primaryCyan.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? PyraTheme.primaryCyan : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(backName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: PyraTheme.primaryCyan, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
                      // Profil Customization Group
                      if (profile != null && user != null) ...[
                        _SettingsGroup(
                          title: 'Mon Apparence & Profil',
                          children: [
                            // Emoji Avatar Picker
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
                              subtitle: const Text('Modifier votre émoticône de jeu', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                              onTap: () => _showEmojiPicker(context, user.uid, profile.emoji),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            // Profile Title Picker
                            ListTile(
                              leading: const Icon(Icons.military_tech_rounded, color: PyraTheme.primaryPink),
                              title: const Text('Titre Affiché', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(profile.activeTitle, style: const TextStyle(color: PyraTheme.primaryPink, fontSize: 13, fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                              onTap: () => _showTitlePicker(context, user.uid, profile.activeTitle, profile.titles),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            // Card Back Picker
                            ListTile(
                              leading: const Icon(Icons.style_rounded, color: PyraTheme.primaryCyan),
                              title: const Text('Dos de Cartes actif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        ),
                        const SizedBox(height: 16),
                      ],

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

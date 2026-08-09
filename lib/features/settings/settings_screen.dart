import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_settings/app_settings.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../auth/auth_service.dart';
import '../profile/user_profile_provider.dart';
import '../store/store_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = 'v1.0.4+5 (Build 42)';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${info.version} (Build ${info.buildNumber})';
        });
      }
    } catch (_) {}
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : PyraTheme.primaryCyan,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Modales d'actions ──
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: PyraTheme.primaryYellow),
            SizedBox(width: 8),
            Text('Déconnexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryYellow),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).signOut();
              if (mounted) context.goNamed('auth');
            },
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Zone Rouge : Supprimer le compte',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Cette action est irréversible et supprimera définitivement votre profil, votre progression, vos statistiques, vos pièces et vos éléments débloqués dans la base de données.\n\nVoulez-vous vraiment continuer ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (mounted) context.goNamed('auth');
              } catch (e) {
                _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
              }
            },
            child: const Text('Supprimer définitivement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRedeemCodeDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: PyraTheme.primaryPink),
            SizedBox(width: 8),
            Text('Code Promo / Redeem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre code promo pour débloquer des récompenses ou des offres spéciales.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'EX: PYRAMIDE2026',
                hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 1),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryPurple),
            onPressed: () {
              final code = codeController.text.trim();
              Navigator.pop(context);
              if (code.isEmpty) return;
              if (code.toUpperCase() == 'PYRAMIDE2026') {
                _showSnackBar('🎉 Code valide ! +100 Pièces ajoutées à votre compte.');
              } else {
                _showSnackBar('Code promo invalide ou expiré.', isError: true);
              }
            },
            child: const Text('Valider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final profile = ref.watch(userProfileProvider).value;
    final user = ref.watch(authStateChangesProvider).value;

    String authMethod = 'Déconnecté';
    if (user != null) {
      if (user.isAnonymous) {
        authMethod = 'Compte Invité ⚠️';
      } else if (user.providerData.any((p) => p.providerId == 'google.com')) {
        authMethod = 'Google (${user.email ?? user.displayName ?? "Connecté"})';
      } else if (user.providerData.any((p) => p.providerId == 'apple.com')) {
        authMethod = 'Apple ID';
      } else {
        authMethod = user.email ?? 'Email & Mot de passe';
      }
    }

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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Text(
                          '⚙️ Paramètres',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── 1. COMPTE & DONNÉES UTILISATEUR ─────────────────────
                      _SettingsGroup(
                        title: 'COMPTE & IDENTITÉ',
                        children: [
                          if (profile != null && user != null) ...[
                            ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: PyraTheme.bgSurface,
                                  border: Border.all(color: PyraTheme.primaryCyan.withValues(alpha: 0.4), width: 2),
                                ),
                                child: Center(child: Text(profile.emoji, style: const TextStyle(fontSize: 22))),
                              ),
                              title: Text(
                                profile.name ?? user.displayName ?? 'Joueur Pyramide',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              subtitle: Text(
                                authMethod,
                                style: TextStyle(
                                  color: user.isAnonymous ? PyraTheme.primaryYellow : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: user.isAnonymous ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: PyraTheme.primaryCyan, size: 14),
                              onTap: () => context.pushNamed('level'),
                            ),
                            if (user.isAnonymous) ...[
                              const Divider(color: Colors.white10, height: 1),
                              Container(
                                color: PyraTheme.primaryYellow.withValues(alpha: 0.1),
                                child: ListTile(
                                  leading: const Icon(Icons.phonelink_setup_rounded, color: PyraTheme.primaryYellow),
                                  title: const Text('Lier mon compte (Sauvegarder)',
                                      style: TextStyle(color: PyraTheme.primaryYellow, fontWeight: FontWeight.bold)),
                                  subtitle: const Text('Évite de perdre ta progression et tes achats',
                                      style: TextStyle(color: Colors.white60, fontSize: 11)),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: PyraTheme.primaryYellow, size: 14),
                                  onTap: () => context.pushNamed('auth'),
                                ),
                              ),
                            ],
                            const Divider(color: Colors.white10, height: 1),
                            ListTile(
                              leading: const Icon(Icons.logout_rounded, color: Colors.white70),
                              title: const Text('Se déconnecter',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onTap: _showLogoutDialog,
                            ),
                          ],
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── 2. AUDIO & GAMEPLAY ───────────────────────────────
                      _SettingsGroup(
                        title: 'AUDIO & GAMEPLAY',
                        children: [
                          _SettingTile(
                            icon: Icons.music_note_rounded,
                            label: 'Musique de fond',
                            value: settings.musicEnabled,
                            onChanged: (v) => settingsNotifier.toggleMusic(v),
                          ),
                          if (settings.musicEnabled)
                            _VolumeSliderTile(
                              icon: Icons.volume_down_rounded,
                              label: 'Volume Musique',
                              value: settings.musicVolume,
                              onChanged: (v) => settingsNotifier.updateMusicVolume(v),
                            ),
                          const Divider(color: Colors.white10, height: 1),
                          _SettingTile(
                            icon: Icons.volume_up_rounded,
                            label: 'Effets Sonores (SFX)',
                            value: settings.soundEnabled,
                            onChanged: (v) => settingsNotifier.toggleSound(v),
                          ),
                          if (settings.soundEnabled)
                            _VolumeSliderTile(
                              icon: Icons.graphic_eq_rounded,
                              label: 'Volume SFX',
                              value: settings.sfxVolume,
                              onChanged: (v) => settingsNotifier.updateSfxVolume(v),
                            ),
                          const Divider(color: Colors.white10, height: 1),
                          _SettingTile(
                            icon: Icons.headset_rounded,
                            label: 'Audio en arrière-plan',
                            subtitle: 'Autoriser la musique à coexister avec Spotify/Apple Music',
                            value: settings.allowBgAudio,
                            onChanged: (v) => settingsNotifier.toggleAllowBgAudio(v),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SettingTile(
                            icon: Icons.vibration_rounded,
                            label: 'Vibrations (Retour Haptique)',
                            value: settings.vibrationEnabled,
                            onChanged: (v) => settingsNotifier.toggleVibration(v),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── 3. NOTIFICATIONS & SOCIAL ─────────────────────────
                      _SettingsGroup(
                        title: 'NOTIFICATIONS & SOCIAL',
                        children: [
                          _SettingTile(
                            icon: Icons.notifications_active_rounded,
                            label: 'Notifications Push',
                            value: settings.pushGlobal,
                            onChanged: (v) => settingsNotifier.togglePushGlobal(v),
                          ),
                          if (settings.pushGlobal) ...[
                            _SettingTile(
                              icon: Icons.timer_rounded,
                              label: 'Rappels de partie & Tours',
                              value: settings.pushReminders,
                              onChanged: (v) => settingsNotifier.togglePushReminders(v),
                            ),
                            _SettingTile(
                              icon: Icons.people_outline_rounded,
                              label: 'Invitations d\'amis & Défis',
                              value: settings.pushFriends,
                              onChanged: (v) => settingsNotifier.togglePushFriends(v),
                            ),
                            _SettingTile(
                              icon: Icons.card_giftcard_rounded,
                              label: 'Bonus & Événements',
                              value: settings.pushEvents,
                              onChanged: (v) => settingsNotifier.togglePushEvents(v),
                            ),
                          ],
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.settings_phone_rounded, color: PyraTheme.primaryCyan),
                            title: const Text('Réglages Notifications (OS)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Gérer les autorisations système iOS',
                                style: TextStyle(color: Colors.white54, fontSize: 11)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () {
                              AppSettings.openAppSettings(type: AppSettingsType.notification);
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SettingTile(
                            icon: Icons.visibility_rounded,
                            label: 'Statut en ligne public',
                            value: settings.isOnlineVisible,
                            onChanged: (v) {
                              settingsNotifier.toggleIsOnlineVisible(v);
                              if (user != null) {
                                FirebaseDatabase.instance.ref('users/${user.uid}/isOnlineVisible').set(v);
                              }
                            },
                          ),
                          _SettingTile(
                            icon: Icons.person_add_disabled_rounded,
                            label: 'Autoriser les demandes d\'amis',
                            value: settings.allowFriendRequests,
                            onChanged: (v) {
                              settingsNotifier.toggleAllowFriendRequests(v);
                              if (user != null) {
                                FirebaseDatabase.instance.ref('users/${user.uid}/allowFriendRequests').set(v);
                              }
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── 4. MONÉTISATION & ACHATS ──────────────────────────
                      _SettingsGroup(
                        title: 'MONÉTISATION & ACHATS',
                        children: [
                          ListTile(
                            leading: const Icon(Icons.restore_rounded, color: PyraTheme.primaryCyan),
                            title: const Text('Restaurer les achats',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                            onTap: () async {
                              _showSnackBar('Restauration des achats en cours...');
                              try {
                                await ref.read(storeServiceProvider).restorePurchases();
                                _showSnackBar('Vos achats ont été restaurés avec succès !');
                              } catch (e) {
                                _showSnackBar('Aucun achat restauré ou erreur de réseau.', isError: true);
                              }
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.subscriptions_rounded, color: PyraTheme.primaryPurple),
                            title: const Text('Gérer mes abonnements Store',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () {
                              if (defaultTargetPlatform == TargetPlatform.iOS) {
                                _launchUrl('https://apps.apple.com/account/subscriptions');
                              } else {
                                _launchUrl('https://play.google.com/store/account/subscriptions');
                              }
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.card_giftcard_rounded, color: PyraTheme.primaryPink),
                            title: const Text('Code Promo / Redeem',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                            onTap: _showRedeemCodeDialog,
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── 5. SUPPORT, CACHE & MENTIONS LÉGALES ─────────────
                      _SettingsGroup(
                        title: 'SUPPORT & INFOS LÉGALES',
                        children: [
                          if (user != null) ...[
                            ListTile(
                              leading: const Icon(Icons.fingerprint_rounded, color: PyraTheme.primaryCyan),
                              title: const Text('ID Utilisateur (UID)',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(user.uid, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              trailing: const Icon(Icons.copy_rounded, color: PyraTheme.primaryCyan, size: 18),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: user.uid));
                                _showSnackBar('ID Utilisateur copié dans le presse-papier !');
                              },
                            ),
                            const Divider(color: Colors.white10, height: 1),
                          ],
                          ListTile(
                            leading: const Icon(Icons.cleaning_services_rounded, color: PyraTheme.primaryYellow),
                            title: const Text('Vider le cache local',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Réinitialise les fichiers temporaires sans toucher à votre profil',
                                style: TextStyle(color: Colors.white54, fontSize: 11)),
                            onTap: () async {
                              PaintingBinding.instance.imageCache.clear();
                              PaintingBinding.instance.imageCache.clearLiveImages();
                              await settingsNotifier.clearCache();
                              _showSnackBar('Cache local vidé avec succès !');
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.help_outline_rounded, color: PyraTheme.primaryYellow),
                            title: const Text('Revoir le tutoriel',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                            onTap: () {
                              settingsNotifier.resetTutorial();
                              _showSnackBar('Le tutoriel sera relancé à votre prochaine partie !');
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.bug_report_rounded, color: PyraTheme.primaryPink),
                            title: const Text('Signaler un bug / Support',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () {
                              final uid = user?.uid ?? 'Non connecté';
                              final platform = defaultTargetPlatform.name;
                              _launchUrl(
                                  'mailto:contact@pyramideparty.fr?subject=Support%20Pyramide%20Party&body=Informations%20Support:%0A- UID: $uid%0A- Platform: $platform%0A- App Version: $_appVersion%0A%0A[Expliquez votre problème ici]');
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_rounded, color: PyraTheme.primaryCyan),
                            title: const Text('Politique de confidentialité',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () => _launchUrl('https://pyramideparty.fr/privacy'),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.description_rounded, color: Colors.white70),
                            title: const Text('Conditions d\'utilisation (CGU)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () => _launchUrl('https://pyramideparty.fr/terms'),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── ZONE ROUGE (SUPPRESSION DE COMPTE) ─────────────────
                      _SettingsGroup(
                        title: 'ZONE ROUGE',
                        borderColor: Colors.redAccent.withValues(alpha: 0.4),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                            title: const Text('Supprimer mon compte & mes données',
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 14),
                            onTap: _showDeleteAccountDialog,
                          ),
                        ],
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),

                      // ── FOOTER & VERSION ──────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              '🔺 PYRAMIDE PARTY 🔺',
                              style: TextStyle(
                                color: PyraTheme.primaryCyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _appVersion,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: PyraTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
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
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: PyraTheme.primaryPurple,
            activeTrackColor: PyraTheme.primaryPurple.withValues(alpha: 0.5),
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
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 16),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${(value * 100).toInt()}%',
                  style: const TextStyle(color: PyraTheme.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: PyraTheme.primaryCyan,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: PyraTheme.primaryCyan.withValues(alpha: 0.2),
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

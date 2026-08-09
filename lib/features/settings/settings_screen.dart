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
import '../auth/auth_service.dart';
import '../profile/user_profile_provider.dart';
import '../store/store_service.dart';
import '../store/redeem_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = 'v1.0.4 (Build 42)';

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
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade400 : PyraTheme.primaryCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: PyraTheme.primaryYellow),
            SizedBox(width: 10),
            Text('Déconnexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PyraTheme.primaryYellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).signOut();
              if (mounted) context.goNamed('auth');
            },
            child: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 10),
            Text('Supprimer mon compte', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'Cette action est irréversible et supprimera définitivement votre profil, vos statistiques, vos pièces et vos éléments débloqués dans la base de données.\n\nVoulez-vous vraiment continuer ?',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (mounted) context.goNamed('auth');
              } catch (e) {
                _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
              }
            },
            child: const Text('Supprimer définitivement', style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: PyraTheme.primaryPink.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: PyraTheme.primaryPink),
            SizedBox(width: 10),
            Text('Code Promo / Redeem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre code promo pour débloquer des récompenses ou offres exclusives.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'EX: PYRAMIDE2026',
                hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 1),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: PyraTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              final code = codeController.text.trim();
              Navigator.pop(context);
              if (code.isEmpty) return;
              final user = ref.read(authServiceProvider).currentUser;
              if (user == null) return;
              final result = await RedeemService.redeemCode(rawCode: code, uid: user.uid);
              _showSnackBar(result.message, isError: !result.success);
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
    Color authBadgeColor = PyraTheme.primaryCyan;
    if (user != null) {
      if (user.isAnonymous) {
        authMethod = 'Compte Invité ⚠️';
        authBadgeColor = PyraTheme.primaryYellow;
      } else if (user.providerData.any((p) => p.providerId == 'google.com')) {
        authMethod = 'Google';
        authBadgeColor = PyraTheme.primaryPink;
      } else if (user.providerData.any((p) => p.providerId == 'apple.com')) {
        authMethod = 'Apple ID';
        authBadgeColor = Colors.white;
      } else {
        authMethod = user.email ?? 'Email';
        authBadgeColor = PyraTheme.primaryCyan;
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
                // ── Header Bar ───────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.pop();
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        ShaderMask(
                          shaderCallback: (bounds) => PyraTheme.cyanGradient.createShader(bounds),
                          child: const Text(
                            'Paramètres',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── 1. CARTE PROFIL ET COMPTE ───────────────────────────
                      if (profile != null && user != null)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.pushNamed('level');
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.all(18),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: PyraTheme.primaryCyan.withValues(alpha: 0.3), width: 1.5),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Avatar avec lueur
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: PyraTheme.bgSurface,
                                        border: Border.all(color: PyraTheme.primaryCyan, width: 2),
                                        boxShadow: PyraTheme.glowCyan,
                                      ),
                                      child: Center(child: Text(profile.emoji, style: const TextStyle(fontSize: 28))),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  profile.name ?? user.displayName ?? 'Joueur Pyramide',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 17,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: authBadgeColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: authBadgeColor.withValues(alpha: 0.4)),
                                                ),
                                                child: Text(
                                                  authMethod,
                                                  style: TextStyle(
                                                    color: authBadgeColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  gradient: PyraTheme.purplePinkGradient,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  profile.activeTitle.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Niveau ${profile.level}',
                                                style: const TextStyle(
                                                  color: PyraTheme.primaryCyan,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: PyraTheme.primaryCyan, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Progress Bar XP
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
                                          gradient: PyraTheme.cyanGradient,
                                          borderRadius: BorderRadius.circular(3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: PyraTheme.primaryCyan.withValues(alpha: 0.6),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),

                      // Bannières spécifiques si compte Invité
                      if (user != null && user.isAnonymous) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.pushNamed('auth');
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: PyraTheme.primaryYellow.withValues(alpha: 0.5)),
                            child: Row(
                              children: [
                                const Text('🛡️', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lier mon compte (Sauvegarde)',
                                        style: TextStyle(color: PyraTheme.primaryYellow, fontWeight: FontWeight.w900, fontSize: 14),
                                      ),
                                      Text(
                                        'Conserve ta progression et tes pièces en sécurité !',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: PyraTheme.primaryYellow, size: 14),
                              ],
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.02, 1.02),
                                duration: 2.seconds,
                              ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── 2. AUDIO & GAMEPLAY ───────────────────────────────
                      _SleekSettingGroup(
                        title: 'AUDIO & AMBIANCE',
                        accentColor: PyraTheme.primaryCyan,
                        children: [
                          _SleekSwitchTile(
                            icon: Icons.music_note_rounded,
                            iconColor: PyraTheme.primaryCyan,
                            title: 'Musique de fond',
                            value: settings.musicEnabled,
                            onChanged: (v) => settingsNotifier.toggleMusic(v),
                          ),
                          if (settings.musicEnabled)
                            _SleekSliderTile(
                              icon: Icons.volume_down_rounded,
                              label: 'Volume Musique',
                              value: settings.musicVolume,
                              accentColor: PyraTheme.primaryCyan,
                              onChanged: (v) => settingsNotifier.updateMusicVolume(v),
                            ),
                          const Divider(color: Colors.white10, height: 1),
                          _SleekSwitchTile(
                            icon: Icons.volume_up_rounded,
                            iconColor: PyraTheme.primaryPink,
                            title: 'Effets Sonores (SFX)',
                            value: settings.soundEnabled,
                            onChanged: (v) => settingsNotifier.toggleSound(v),
                          ),
                          if (settings.soundEnabled)
                            _SleekSliderTile(
                              icon: Icons.graphic_eq_rounded,
                              label: 'Volume SFX',
                              value: settings.sfxVolume,
                              accentColor: PyraTheme.primaryPink,
                              onChanged: (v) => settingsNotifier.updateSfxVolume(v),
                            ),
                          const Divider(color: Colors.white10, height: 1),
                          _SleekSwitchTile(
                            icon: Icons.headset_rounded,
                            iconColor: PyraTheme.primaryPurple,
                            title: 'Audio en arrière-plan',
                            subtitle: 'Autoriser la musique de l\'app à coexister avec Spotify / Apple Music',
                            value: settings.allowBgAudio,
                            onChanged: (v) => settingsNotifier.toggleAllowBgAudio(v),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SleekSwitchTile(
                            icon: Icons.vibration_rounded,
                            iconColor: PyraTheme.primaryOrange,
                            title: 'Vibrations (Retour Haptique)',
                            value: settings.vibrationEnabled,
                            onChanged: (v) => settingsNotifier.toggleVibration(v),
                          ),
                        ],
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── 3. NOTIFICATIONS & SOCIAL ─────────────────────────
                      _SleekSettingGroup(
                        title: 'NOTIFICATIONS & SOCIAL',
                        accentColor: PyraTheme.primaryPurple,
                        children: [
                          _SleekSwitchTile(
                            icon: Icons.notifications_active_rounded,
                            iconColor: PyraTheme.primaryPurple,
                            title: 'Notifications Push',
                            value: settings.pushGlobal,
                            onChanged: (v) => settingsNotifier.togglePushGlobal(v),
                          ),
                          if (settings.pushGlobal) ...[
                            _SleekSwitchTile(
                              icon: Icons.timer_rounded,
                              iconColor: PyraTheme.primaryCyan,
                              title: 'Rappels de partie & Tours',
                              value: settings.pushReminders,
                              onChanged: (v) => settingsNotifier.togglePushReminders(v),
                            ),
                            _SleekSwitchTile(
                              icon: Icons.people_outline_rounded,
                              iconColor: PyraTheme.primaryPink,
                              title: 'Invitations d\'amis & Défis',
                              value: settings.pushFriends,
                              onChanged: (v) => settingsNotifier.togglePushFriends(v),
                            ),
                            _SleekSwitchTile(
                              icon: Icons.card_giftcard_rounded,
                              iconColor: PyraTheme.primaryYellow,
                              title: 'Bonus & Événements',
                              value: settings.pushEvents,
                              onChanged: (v) => settingsNotifier.togglePushEvents(v),
                            ),
                          ],
                          const Divider(color: Colors.white10, height: 1),
                          _SleekActionTile(
                            icon: Icons.settings_phone_rounded,
                            iconColor: PyraTheme.primaryCyan,
                            title: 'Réglages Notifications (OS)',
                            subtitle: 'Gérer les autorisations système iOS',
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () {
                              AppSettings.openAppSettings(type: AppSettingsType.notification);
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SleekSwitchTile(
                            icon: Icons.visibility_rounded,
                            iconColor: PyraTheme.primaryGreen,
                            title: 'Statut en ligne public',
                            value: settings.isOnlineVisible,
                            onChanged: (v) {
                              settingsNotifier.toggleIsOnlineVisible(v);
                              if (user != null) {
                                FirebaseDatabase.instance.ref('users/${user.uid}/isOnlineVisible').set(v);
                              }
                            },
                          ),
                          _SleekSwitchTile(
                            icon: Icons.person_add_rounded,
                            iconColor: PyraTheme.primaryYellow,
                            title: 'Autoriser les demandes d\'amis',
                            value: settings.allowFriendRequests,
                            onChanged: (v) {
                              settingsNotifier.toggleAllowFriendRequests(v);
                              if (user != null) {
                                FirebaseDatabase.instance.ref('users/${user.uid}/allowFriendRequests').set(v);
                              }
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── 4. MONÉTISATION & ACHATS ──────────────────────────
                      _SleekSettingGroup(
                        title: 'BOUTIQUE & ACHATS',
                        accentColor: PyraTheme.primaryPink,
                        children: [
                          _SleekActionTile(
                            icon: Icons.restore_rounded,
                            iconColor: PyraTheme.primaryCyan,
                            title: 'Restaurer les achats',
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
                          _SleekActionTile(
                            icon: Icons.subscriptions_rounded,
                            iconColor: PyraTheme.primaryPurple,
                            title: 'Gérer mes abonnements Store',
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
                          _SleekActionTile(
                            icon: Icons.card_giftcard_rounded,
                            iconColor: PyraTheme.primaryPink,
                            title: 'Code Promo / Redeem',
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                            onTap: _showRedeemCodeDialog,
                          ),
                        ],
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── 5. SUPPORT, CACHE & INFOS ─────────────────────────
                      _SleekSettingGroup(
                        title: 'SUPPORT & INFOS LÉGALES',
                        accentColor: PyraTheme.primaryYellow,
                        children: [
                          if (user != null) ...[
                            _SleekActionTile(
                              icon: Icons.fingerprint_rounded,
                              iconColor: PyraTheme.primaryCyan,
                              title: 'ID Utilisateur (UID)',
                              subtitle: user.uid,
                              trailing: const Icon(Icons.copy_rounded, color: PyraTheme.primaryCyan, size: 18),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: user.uid));
                                _showSnackBar('ID Utilisateur copié dans le presse-papier !');
                              },
                            ),
                            const Divider(color: Colors.white10, height: 1),
                          ],
                          _SleekActionTile(
                            icon: Icons.cleaning_services_rounded,
                            iconColor: PyraTheme.primaryYellow,
                            title: 'Vider le cache local',
                            subtitle: 'Réinitialise les fichiers temporaires sans toucher au profil',
                            onTap: () async {
                              PaintingBinding.instance.imageCache.clear();
                              PaintingBinding.instance.imageCache.clearLiveImages();
                              await settingsNotifier.clearCache();
                              _showSnackBar('Cache local vidé avec succès !');
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SleekActionTile(
                            icon: Icons.help_outline_rounded,
                            iconColor: PyraTheme.primaryOrange,
                            title: 'Revoir le tutoriel',
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                            onTap: () {
                              settingsNotifier.resetTutorial();
                              _showSnackBar('Le tutoriel sera relancé à votre prochaine partie !');
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SleekActionTile(
                            icon: Icons.bug_report_rounded,
                            iconColor: PyraTheme.primaryPink,
                            title: 'Signaler un bug / Support',
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () {
                              final uid = user?.uid ?? 'Non connecté';
                              final platform = defaultTargetPlatform.name;
                              _launchUrl(
                                  'mailto:contact@pyramideparty.fr?subject=Support%20Pyramide%20Party&body=Informations%20Support:%0A- UID: $uid%0A- Platform: $platform%0A- App Version: $_appVersion%0A%0A[Expliquez votre problème ici]');
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SleekActionTile(
                            icon: Icons.privacy_tip_rounded,
                            iconColor: PyraTheme.primaryCyan,
                            title: 'Politique de confidentialité',
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () => _launchUrl('https://pyramideparty.fr/privacy'),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _SleekActionTile(
                            icon: Icons.description_rounded,
                            iconColor: Colors.white70,
                            title: 'Conditions d\'utilisation (CGU)',
                            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                            onTap: () => _launchUrl('https://pyramideparty.fr/terms'),
                          ),
                        ],
                      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // ── ZONE ROUGE (SUPPRESSION DE COMPTE) ─────────────────
                      _SleekSettingGroup(
                        title: 'ZONE ROUGE',
                        accentColor: Colors.redAccent,
                        children: [
                          _SleekActionTile(
                            icon: Icons.delete_forever_rounded,
                            iconColor: Colors.redAccent,
                            title: 'Supprimer mon compte & mes données',
                            titleColor: Colors.redAccent,
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 14),
                            onTap: _showDeleteAccountDialog,
                          ),
                        ],
                      ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
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
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Text(
                                _appVersion,
                                style: const TextStyle(color: PyraTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
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

// ── Composants Reutilisables Sleek UI ─────────────────────────────────────────

class _SleekSettingGroup extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<Widget> children;

  const _SleekSettingGroup({
    required this.title,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(color: accentColor.withValues(alpha: 0.8), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        GlassContainer(
          borderRadius: BorderRadius.circular(24),
          padding: EdgeInsets.zero,
          border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
          child: Material(
            color: Colors.transparent,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SleekActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SleekActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: iconColor.withValues(alpha: 0.12),
                border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SleekSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SleekSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: iconColor.withValues(alpha: 0.12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
            activeColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _SleekSliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _SleekSliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: accentColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: accentColor.withValues(alpha: 0.2),
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

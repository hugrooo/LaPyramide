import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pulsar_button.dart';
import '../../../shared/widgets/neo_badge.dart';
import '../../profile/user_profile_provider.dart';
import '../../auth/auth_service.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  bool _isChestOpening = false;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final profile = ref.read(userProfileProvider).value;
      if (profile == null) return;

      final int nextClaimAvailable = profile.lastDailyChestClaimed + 24 * 60 * 60 * 1000;
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int diff = nextClaimAvailable - now;

      if (diff > 0) {
        if (mounted) {
          setState(() {
            _timeLeft = Duration(milliseconds: diff);
          });
        }
      } else {
        if (mounted && _timeLeft != Duration.zero) {
          setState(() {
            _timeLeft = Duration.zero;
          });
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<void> _claimDailyChest(UserProfile profile) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() {
      _isChestOpening = true;
    });

    HapticFeedback.vibrate();

    // Simuler l'animation d'ouverture de 1.5 seconde
    await Future.delayed(const Duration(milliseconds: 1500));

    final random = Random();
    final coinsReward = 50 + random.nextInt(101); // 50 à 150 pièces
    final diamondsReward = 5;

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    await dbRef.update({
      'coins': profile.coins + coinsReward,
      'diamonds': profile.diamonds + diamondsReward,
      'lastDailyChestClaimed': DateTime.now().millisecondsSinceEpoch,
    });

    if (mounted) {
      setState(() {
        _isChestOpening = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PyraTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard_rounded, color: PyraTheme.primaryPink, size: 28),
              SizedBox(width: 8),
              Text('Récompense !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Félicitations, vous avez ouvert le coffre mystère et gagné :',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: PyraTheme.primaryYellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PyraTheme.primaryYellow.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Text('+$coinsReward', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 6),
                        const Icon(Icons.monetization_on_rounded, color: PyraTheme.primaryYellow, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: PyraTheme.primaryPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PyraTheme.primaryPurple.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Text('+$diamondsReward', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 6),
                        const Icon(Icons.diamond_rounded, color: PyraTheme.primaryPurple, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            PulsarButton(
              text: 'Génial !',
              paddingHorizontal: 24,
              width: null,
              gradient: PyraTheme.festiveGradient,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _simulateQuestCompletion(String questPath, int currentProgress, int target, int coinsReward, int currentCoins) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    if (currentProgress < target) {
      // Simuler l'avancement
      await dbRef.update({
        'quests/$questPath/progress': target,
      });
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Défi complété ! Cliquez sur Récupérer pour obtenir vos pièces.'), backgroundColor: Colors.orangeAccent),
      );
    } else {
      // Réclamer la récompense
      await dbRef.update({
        'coins': currentCoins + coinsReward,
        'quests/$questPath/claimed': true,
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$coinsReward pièces réclamées avec succès !'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildQuestCard({
    required String path,
    required String title,
    required String desc,
    required int progress,
    required int target,
    required int reward,
    required bool claimed,
    required int userCoins,
  }) {
    final bool isCompleted = progress >= target;
    final double percent = (progress / target).clamp(0.0, 1.0);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.greenAccent : PyraTheme.primaryCyan),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$progress / $target', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (claimed)
            const SizedBox(
              width: 105,
              height: 40,
              child: Center(
                child: Icon(Icons.check_circle_outline_rounded, color: Colors.white30, size: 28),
              ),
            )
          else if (isCompleted)
            SizedBox(
              width: 105,
              height: 40,
              child: PulsarButton(
                text: 'Récupérer',
                fontSize: 12,
                paddingHorizontal: 8,
                paddingVertical: 8,
                maxLines: 1,
                gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                onPressed: () => _simulateQuestCompletion(path, progress, target, reward, userCoins),
              ),
            )
          else
            SizedBox(
              width: 105,
              height: 40,
              child: PulsarButton(
                text: '+$reward 🪙',
                fontSize: 12,
                paddingHorizontal: 8,
                paddingVertical: 8,
                maxLines: 1,
                gradient: PyraTheme.festiveGradient,
                onPressed: () => _simulateQuestCompletion(path, progress, target, reward, userCoins),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;
    final currentCoins = profile?.coins ?? 0;
    final currentDiamonds = profile?.diamonds ?? 0;

    // Détermination de l'état du coffre
    final int nextClaimAvailable = (profile?.lastDailyChestClaimed ?? 0) + 24 * 60 * 60 * 1000;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final bool isChestAvailable = now >= nextClaimAvailable;

    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Quêtes & Coffre',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Row(
                        children: [
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                Text('$currentCoins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 4),
                                const Icon(Icons.monetization_on_rounded, color: PyraTheme.primaryYellow, size: 14),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                Text('$currentDiamonds', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 4),
                                const Icon(Icons.diamond_rounded, color: PyraTheme.primaryPurple, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Coffre Mystère Quotidien
                      Center(
                        child: Text(
                          'COFFRE MYSTÈRE QUOTIDIEN',
                          style: TextStyle(color: PyraTheme.primaryCyan, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (isChestAvailable && !_isChestOpening && profile != null) {
                              _claimDailyChest(profile);
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isChestAvailable ? PyraTheme.primaryPink : Colors.grey).withOpacity(0.08),
                                  boxShadow: isChestAvailable
                                      ? [BoxShadow(color: PyraTheme.primaryPink.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)]
                                      : null,
                                ),
                              ),
                              // Icône ou Texte Animé du Coffre
                              _isChestOpening
                                  ? const Text('🎁', style: TextStyle(fontSize: 90))
                                      .animate(onPlay: (c) => c.repeat())
                                      .shake(duration: 300.ms, hz: 6)
                                      .scale(end: const Offset(1.3, 1.3), duration: 1500.ms, curve: Curves.easeIn)
                                  : (isChestAvailable
                                      ? const Text('🎁', style: TextStyle(fontSize: 85))
                                          .animate(onPlay: (c) => c.repeat(reverse: true))
                                          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: 1200.ms, curve: Curves.easeInOut)
                                          .shake(delay: 2000.ms, duration: 400.ms, hz: 3)
                                      : const Text('📦', style: TextStyle(fontSize: 80, color: Colors.grey))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: isChestAvailable
                            ? const Text(
                                'CLIQUEZ SUR LE CADEAU POUR L\'OUVRIR !',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w900),
                              )
                            : Column(
                                children: [
                                  Text(
                                    'Prochain coffre disponible dans :',
                                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _timeLeft != Duration.zero ? _formatDuration(_timeLeft) : '24:00:00',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 36),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),

                      // Défis Quotidiens
                      const Text(
                        'Défis du Jour',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // Défi 1
                      _buildQuestCard(
                        path: 'bluff',
                        title: 'Légende du Bluff 🎭',
                        desc: 'Réussir 3 bluffs en partie en ligne ou locale.',
                        progress: 0, // Dans un vrai jeu, ceci viendrait d'un noeud Firebase dynamic
                        target: 3,
                        reward: 80,
                        claimed: false,
                        userCoins: currentCoins,
                      ),
                      const SizedBox(height: 16),

                      // Défi 2
                      _buildQuestCard(
                        path: 'games',
                        title: 'Soirée Active 🍻',
                        desc: 'Jouer 1 partie de Pyramide complète.',
                        progress: 1, // Simulé complété pour test facile
                        target: 1,
                        reward: 50,
                        claimed: false,
                        userCoins: currentCoins,
                      ),
                      const SizedBox(height: 16),

                      // Défi 3
                      _buildQuestCard(
                        path: 'shop',
                        title: 'Acheteur Averti 🛒',
                        desc: 'Acheter 1 Joker consommable dans la Boutique.',
                        progress: 0,
                        target: 1,
                        reward: 60,
                        claimed: false,
                        userCoins: currentCoins,
                      ),
                    ],
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

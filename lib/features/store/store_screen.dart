import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../../shared/widgets/neo_badge.dart';
import '../profile/user_profile_provider.dart';
import 'store_service.dart';

enum StoreTab { coins, jokers, cosmetics }

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  StoreTab _activeTab = StoreTab.coins;

  @override
  void initState() {
    super.initState();
    ref.read(storeServiceProvider).init();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ref.read(storeServiceProvider).fetchProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    ref.read(storeServiceProvider).dispose();
    super.dispose();
  }

  Widget _buildFallbackPacks() {
    return Column(
      children: [
        _buildPackCard('Récompense Quotidienne', 'Reviens tous les jours !', 'Ouvrir 🎁', 100)
            .animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
        const SizedBox(height: 16),
        _buildPackCard('Visionner une Pub', 'Soutenez-nous', 'Regarder 📺', 500, isPopular: true)
            .animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2),
        const SizedBox(height: 16),
        _buildPackCard('Défi de la Pyramide', 'Gagne 3 parties de suite', 'Réclamer 🏆', 1200)
            .animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildPackCard(String title, String desc, String buttonText, int coins, {bool isPopular = false}) {
    return GlassContainer(
      innerGlow: isPopular,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      border: isPopular ? Border.all(color: PyraTheme.primaryPink.withOpacity(0.5), width: 2) : null,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: isPopular ? PyraTheme.purplePinkGradient : const LinearGradient(colors: [PyraTheme.bgSurface, PyraTheme.bgCard]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isPopular ? PyraTheme.glowPink : null,
              border: Border.all(color: Colors.white24),
            ),
            child: const Center(
              child: Icon(Icons.monetization_on_rounded, color: PyraTheme.primaryYellow, size: 36),
            ),
          ).animate(onPlay: (c) => isPopular ? c.repeat(reverse: true) : null).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 2.seconds),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PyraTheme.primaryCyan,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: PyraTheme.glowCyan,
                    ),
                    child: const Text('BONUS', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                  ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
          PulsarButton(
            text: buttonText,
            paddingHorizontal: 12,
            paddingVertical: 12,
            fontSize: 12,
            gradient: isPopular ? const LinearGradient(colors: [PyraTheme.primaryPink, Colors.pinkAccent]) : PyraTheme.festiveGradient,
            onPressed: () async {
              await ref.read(storeServiceProvider).addCoinsFictitiously(coins);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 Félicitations ! +$coins pièces ajoutées !'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJokersTab(UserProfile? profile) {
    final Map<String, int> jokersOwned = profile?.jokers ?? {};

    return Column(
      children: [
        _buildItemPurchaseCard(
          id: 'miroir',
          title: 'Joker Miroir 🪞',
          desc: 'Renvoie instantanément les gorgées reçues vers l\'envoyeur en partie.',
          cost: 150,
          currency: 'coins',
          icon: Icons.repeat_on_rounded,
          iconColor: PyraTheme.primaryCyan,
          ownedCount: jokersOwned['miroir'] ?? 0,
          type: 'joker',
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'bouclier',
          title: 'Joker Bouclier 🛡️',
          desc: 'Réduit de moitié les gorgées que vous devez boire sur un tour.',
          cost: 100,
          currency: 'coins',
          icon: Icons.shield_rounded,
          iconColor: PyraTheme.primaryYellow,
          ownedCount: jokersOwned['bouclier'] ?? 0,
          type: 'joker',
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'detecteur',
          title: 'Joker Détecteur 🔍',
          desc: 'Indique la probabilité exacte qu\'un joueur soit en train de bluffer.',
          cost: 200,
          currency: 'coins',
          icon: Icons.radar_rounded,
          iconColor: PyraTheme.primaryPink,
          ownedCount: jokersOwned['detecteur'] ?? 0,
          type: 'joker',
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'double_dose',
          title: 'Joker Double Dose 🧪',
          desc: 'Multiplie par deux le nombre de gorgées que vous distribuez à vos cibles.',
          cost: 120,
          currency: 'coins',
          icon: Icons.science_rounded,
          iconColor: PyraTheme.primaryPurple,
          ownedCount: jokersOwned['double_dose'] ?? 0,
          type: 'joker',
        ),
      ],
    );
  }

  Widget _buildCosmeticsTab(UserProfile? profile) {
    final List<String> cardBacksOwned = profile?.cardBacks ?? ['classic'];
    final List<String> titlesOwned = profile?.titles ?? ['Novice 🐣'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dos de Cartes Premium',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildItemPurchaseCard(
          id: 'neon',
          title: 'Dos Néon Cyberpunk ⚡',
          desc: 'Un dos de carte brillant aux couleurs cyan et violet futuristes.',
          cost: 50,
          currency: 'diamonds',
          icon: Icons.electric_bolt_rounded,
          iconColor: PyraTheme.primaryCyan,
          ownedCount: cardBacksOwned.contains('neon') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('neon'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'pirate',
          title: 'Dos Pirate Doré ☠️',
          desc: 'Le dos de carte des légendes de la flibuste et de la fortune.',
          cost: 100,
          currency: 'diamonds',
          icon: Icons.sailing_rounded,
          iconColor: PyraTheme.primaryYellow,
          ownedCount: cardBacksOwned.contains('pirate') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('pirate'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'retro',
          title: 'Dos Rétro Pixel 👾',
          desc: 'Pour les nostalgiques de l\'ère 8-bit et du retrogaming.',
          cost: 75,
          currency: 'diamonds',
          icon: Icons.videogame_asset_rounded,
          iconColor: PyraTheme.primaryPink,
          ownedCount: cardBacksOwned.contains('retro') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('retro'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Titres de Profil délirants',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildItemPurchaseCard(
          id: 'Légende du Bluff 🎭',
          title: 'Légende du Bluff 🎭',
          desc: 'Affichez ce titre sur votre profil pour intimider vos adversaires.',
          cost: 300,
          currency: 'coins',
          icon: Icons.military_tech_rounded,
          iconColor: PyraTheme.primaryCyan,
          ownedCount: titlesOwned.contains('Légende du Bluff 🎭') ? 1 : 0,
          type: 'title',
          isOwned: titlesOwned.contains('Légende du Bluff 🎭'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'Pilier de Bar 🍻',
          title: 'Pilier de Bar 🍻',
          desc: 'Un titre idéal pour ceux qui ne reculent devant aucune gorgée.',
          cost: 150,
          currency: 'coins',
          icon: Icons.sports_bar_rounded,
          iconColor: PyraTheme.primaryYellow,
          ownedCount: titlesOwned.contains('Pilier de Bar 🍻') ? 1 : 0,
          type: 'title',
          isOwned: titlesOwned.contains('Pilier de Bar 🍻'),
        ),
      ],
    );
  }

  Widget _buildItemPurchaseCard({
    required String id,
    required String title,
    required String desc,
    required int cost,
    required String currency,
    required IconData icon,
    required Color iconColor,
    required int ownedCount,
    required String type,
    bool isOwned = false,
  }) {
    final bool isCoins = currency == 'coins';
    final String currencySuffix = isCoins ? ' pièces' : ' diamants';
    final IconData currencyIcon = isCoins ? Icons.monetization_on_rounded : Icons.diamond_rounded;
    final Color currencyColor = isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 28),
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
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ownedCount > 0 && type == 'joker')
                      NeoBadge(text: 'x$ownedCount', fontSize: 10, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2))
                    else if (isOwned)
                      const NeoBadge(text: 'ACQUIS', gradient: LinearGradient(colors: [Colors.greenAccent, Colors.green]), fontSize: 8, padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isOwned)
            const SizedBox(
              width: 80,
              height: 40,
              child: Center(
                child: Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
              ),
            )
          else
            SizedBox(
              width: 80,
              height: 40,
              child: PulsarButton(
                text: '$cost',
                paddingHorizontal: 8,
                fontSize: 12,
                icon: currencyIcon,
                iconSize: 12,
                gradient: isCoins ? PyraTheme.cyanGradient : PyraTheme.purplePinkGradient,
                onPressed: () async {
                  bool success = false;
                  if (type == 'joker') {
                    success = await ref.read(storeServiceProvider).buyJoker(id, cost);
                  } else {
                    success = await ref.read(storeServiceProvider).buyCosmetic(type, id, cost, currency);
                  }

                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Achat réussi : $title !'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Monnaie insuffisante pour acheter : $title !'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, IconData icon, StoreTab tab) {
    final bool isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tab;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: Colors.white12) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? PyraTheme.primaryCyan : Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white60,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.value;
    final currentCoins = profile?.coins ?? 0;
    final currentDiamonds = profile?.diamonds ?? 0;

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
                      const Expanded(
                        child: Text(
                          'Boutique',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
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

                // Tabs Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(4),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        _buildTabButton('Pièces', Icons.monetization_on_rounded, StoreTab.coins),
                        _buildTabButton('Jokers', Icons.stars_rounded, StoreTab.jokers),
                        _buildTabButton('Apparence', Icons.palette_rounded, StoreTab.cosmetics),
                      ],
                    ),
                  ),
                ),

                // Content Area
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (_activeTab == StoreTab.coins) ...[
                        const Text(
                          'Achète des pièces pour débloquer des Jokers et dominer vos soirées !',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        else
                          _buildFallbackPacks(),
                      ] else if (_activeTab == StoreTab.jokers) ...[
                        const Text(
                          'Utilise tes pièces pour acheter des Jokers dévastateurs utilisables en pleine partie !',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildJokersTab(profile),
                      ] else if (_activeTab == StoreTab.cosmetics) ...[
                        const Text(
                          'Dépense tes diamants et pièces pour obtenir des dos de cartes et titres légendaires !',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildCosmeticsTab(profile),
                      ],
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

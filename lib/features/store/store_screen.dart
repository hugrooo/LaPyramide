import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../../shared/widgets/neo_badge.dart';
import '../../shared/widgets/avatar_with_border.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../profile/user_profile_provider.dart';
import 'store_service.dart';
import '../../shared/widgets/card_3d_showcase.dart';
import '../auth/auth_service.dart';

enum StoreTab { coins, jokers, cosmetics }

class StoreScreen extends ConsumerStatefulWidget {
  final StoreTab? initialTab;
  final bool scrollToBetaGifts;
  final bool scrollToTitle;

  const StoreScreen({
    super.key,
    this.initialTab,
    this.scrollToBetaGifts = false,
    this.scrollToTitle = false,
  });

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  StoreTab _activeTab = StoreTab.coins;

  final GlobalKey _betaGiftKey = GlobalKey();
  final GlobalKey _betaTitleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab ?? StoreTab.coins;
    ref.read(storeServiceProvider).init();
    _loadProducts();

    if (widget.scrollToBetaGifts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final contextToScroll = widget.scrollToTitle 
              ? _betaTitleKey.currentContext 
              : _betaGiftKey.currentContext;
          if (contextToScroll != null) {
            Scrollable.ensureVisible(
              contextToScroll,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              alignment: 0.3,
            );
          }
        });
      });
    }
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

  Widget _buildJokersTab(UserProfile? profile) {
    final Map<String, int> jokersOwned = profile?.jokers ?? {};

    return Column(
      children: [
        _buildItemPurchaseCard(
          id: 'miroir',
          title: 'Joker Miroir 🪞',
          desc:
              'Renvoie instantanément les pénalités reçues vers l\'envoyeur en partie.',
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
          desc:
              'Réduit de moitié les pénalités que vous devez prendre sur un tour.',
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
          desc:
              'Indique la probabilité exacte qu\'un joueur soit en train de bluffer.',
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
          desc:
              'Multiplie par deux le nombre de pénalités que vous distribuez à vos cibles.',
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
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildItemPurchaseCard(
          id: 'neon',
          title: 'Dos Néon Cyberpunk ⚡',
          desc:
              'Un dos de carte brillant aux couleurs cyan et violet futuristes.',
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
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'girl',
          title: 'Dos Girly Rose 🎀',
          desc: 'Un design rose éclatant pour briller avec classe.',
          cost: 50,
          currency: 'diamonds',
          icon: Icons.favorite_rounded,
          iconColor: Colors.pinkAccent,
          ownedCount: cardBacksOwned.contains('girl') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('girl'),
        ),
        const SizedBox(height: 16),
        Container(
          key: _betaGiftKey,
          child: _buildItemPurchaseCard(
            id: 'beta',
            title: 'Dos Testeur Bêta 🚀',
            desc: 'Édition spéciale réservée aux pionniers de Pyramide Party.',
            cost: 0,
            currency: 'diamonds',
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFE040FB),
            ownedCount: cardBacksOwned.contains('beta') ? 1 : 0,
            type: 'cardBack',
            isOwned: cardBacksOwned.contains('beta'),
          ),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'pharaoh',
          title: 'Dos Pharaon 👁️',
          desc: 'Le dos des rois du désert. Régnez sur la partie.',
          cost: 150,
          currency: 'diamonds',
          icon: Icons.visibility_rounded,
          iconColor: const Color(0xFFD4AF37),
          ownedCount: cardBacksOwned.contains('pharaoh') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('pharaoh'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'casino',
          title: 'Dos Casino Royal 🎲',
          desc: 'Faites tapis avec ce dos vert digne des plus grands casinos.',
          cost: 200,
          currency: 'diamonds',
          icon: Icons.casino_rounded,
          iconColor: const Color(0xFF006400),
          ownedCount: cardBacksOwned.contains('casino') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('casino'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'toxic',
          title: 'Dos Toxique 🧪',
          desc: 'Distribuez les pénalités empoisonnées à vos amis.',
          cost: 250,
          currency: 'diamonds',
          icon: Icons.science_rounded,
          iconColor: const Color(0xFF39FF14),
          ownedCount: cardBacksOwned.contains('toxic') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('toxic'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'clubbing',
          title: 'Dos Clubbing 🪩',
          desc: 'Ambiance néon, musique et cocktails.',
          cost: 300,
          currency: 'diamonds',
          icon: Icons.nightlife_rounded,
          iconColor: const Color(0xFFFF00FF),
          ownedCount: cardBacksOwned.contains('clubbing') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('clubbing'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'demon',
          title: 'Dos Démoniaque 😈',
          desc: 'Pour les menteurs impitoyables qui brûlent le jeu.',
          cost: 400,
          currency: 'diamonds',
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFFF4500),
          ownedCount: cardBacksOwned.contains('demon') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('demon'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'vip',
          title: 'Dos VIP Diamant 💎',
          desc: 'L\'ultime dos de carte. Brillez de mille feux.',
          cost: 1000,
          currency: 'diamonds',
          icon: Icons.diamond_rounded,
          iconColor: const Color(0xFF80DEEA),
          ownedCount: cardBacksOwned.contains('vip') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('vip'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Titres de Profil délirants',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildItemPurchaseCard(
          id: 'Légende du Bluff 🎭',
          title: 'Légende du Bluff 🎭',
          desc:
              'Affichez ce titre sur votre profil pour intimider vos adversaires.',
          cost: 300,
          currency: 'coins',
          icon: Icons.military_tech_rounded,
          iconColor: PyraTheme.primaryCyan,
          ownedCount: titlesOwned.contains('Légende du Bluff 🎭') ? 1 : 0,
          type: 'title',
          isOwned: titlesOwned.contains('Légende du Bluff 🎭'),
        ),
        const SizedBox(height: 16),
        Container(
          key: _betaTitleKey,
          child: _buildItemPurchaseCard(
            id: 'Pionnier de la Bêta 🚀',
            title: 'Pionnier de la Bêta 🚀',
            desc:
                'Titre exclusif gratuit réservé aux tout premiers joueurs de la Bêta !',
            cost: 0,
            currency: 'coins',
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFE040FB), // Purple
            ownedCount: titlesOwned.contains('Pionnier de la Bêta 🚀') ? 1 : 0,
            type: 'title',
            isOwned: titlesOwned.contains('Pionnier de la Bêta 🚀'),
          ),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'Maître du Jeu 🃏',
          title: 'Maître du Jeu 🃏',
          desc:
              'Un titre idéal pour ceux qui ne reculent devant aucune pénalité.',
          cost: 150,
          currency: 'coins',
          icon: Icons.psychology_rounded,
          iconColor: PyraTheme.primaryYellow,
          ownedCount: titlesOwned.contains('Maître du Jeu 🃏') ? 1 : 0,
          type: 'title',
          isOwned: titlesOwned.contains('Maître du Jeu 🃏'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'Roi de la Partie 👑',
          title: 'Roi de la Partie 👑',
          desc: 'Pour celui ou celle qui met toujours l\'ambiance.',
          cost: 200,
          currency: 'coins',
          icon: Icons.celebration_rounded,
          iconColor: const Color(0xFFFFD700), // Gold
          ownedCount: titlesOwned.contains('Roi de la Partie 👑') ? 1 : 0,
          type: 'title',
          isOwned: titlesOwned.contains('Roi de la Partie 👑'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'Escroc Professionnel 🦊',
          title: 'Escroc Professionnel 🦊',
          desc: 'Vous mentez tellement bien que c\'en est devenu un art.',
          cost: 400,
          currency: 'coins',
          icon: Icons.masks_rounded, // Better fit for a scammer/thief
          iconColor: const Color(0xFFFF8C00), // Dark Orange
          ownedCount: titlesOwned.contains('Escroc Professionnel 🦊') ? 1 : 0,
          type: 'title',
          isOwned: titlesOwned.contains('Escroc Professionnel 🦊'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'Menteur Pathologique 🤥',
          title: 'Menteur Pathologique 🤥',
          desc: 'Plus personne ne croit un traître mot de ce que vous dites.',
          cost: 500,
          currency: 'coins',
          icon: Icons.psychology_alt_rounded,
          iconColor: PyraTheme.primaryPink,
          ownedCount: titlesOwned.contains('Menteur Pathologique 🤥') ? 1 : 0,
          type: 'title',
          isOwned: titlesOwned.contains('Menteur Pathologique 🤥'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'Dieu de la Pyramide 👁️',
          title: 'Dieu de la Pyramide 👁️',
          desc: 'Le titre honorifique suprême. Vous dominez le jeu.',
          cost: 1000,
          currency: 'coins',
          icon: Icons.visibility_rounded,
          iconColor: PyraTheme.primaryCyan,
          ownedCount: titlesOwned.contains('Dieu de la Pyramide 👁️') ? 1 : 0,
          type: 'title',
          isOwned: titlesOwned.contains('Dieu de la Pyramide 👁️'),
        ),
        const SizedBox(height: 32),
        _buildBordersSection(profile?.bordersOwned ?? ['classic']),
      ],
    );
  }

  Widget _buildBordersSection(List<String> bordersOwned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cadres d\'Avatar animés',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildItemPurchaseCard(
          id: 'neon',
          title: 'Cadre Néon Fluo ⚡',
          desc: 'Un cercle néon stylisé qui brille autour de ton avatar.',
          cost: 300,
          currency: 'coins',
          icon: Icons.lens_blur_rounded,
          iconColor: PyraTheme.primaryCyan,
          ownedCount: bordersOwned.contains('neon') ? 1 : 0,
          type: 'border',
          isOwned: bordersOwned.contains('neon'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'fire',
          title: 'Cadre en Feu 🔥',
          desc: 'Ton profil s\'enflamme et impressionne la galerie.',
          cost: 500,
          currency: 'coins',
          icon: Icons.local_fire_department_rounded,
          iconColor: Colors.orange,
          ownedCount: bordersOwned.contains('fire') ? 1 : 0,
          type: 'border',
          isOwned: bordersOwned.contains('fire'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'gold',
          title: 'Cadre Or Massif 👑',
          desc: 'L\'ultime cadre doré scintillant réservé aux gros gagnants.',
          cost: 200,
          currency: 'diamonds',
          icon: Icons.stars_rounded,
          iconColor: const Color(0xFFFFD700),
          ownedCount: bordersOwned.contains('gold') ? 1 : 0,
          type: 'border',
          isOwned: bordersOwned.contains('gold'),
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
    final IconData currencyIcon =
        isCoins ? Icons.monetization_on_rounded : Icons.diamond_rounded;
    final Color currencyColor =
        isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple;

    return GestureDetector(
        onTap: () {
          if (type == 'cardBack' ||
              type == 'title' ||
              type == 'border' ||
              type == 'theme') {
            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.transparent,
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (type == 'cardBack')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Card3DShowcase(
                              skinId: id, width: 140, height: 196),
                        )
                      else if (type == 'border')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: AvatarWithBorder(
                              emoji: '😎', size: 80, borderType: id),
                        )
                      else
                        Icon(icon, color: iconColor, size: 80),
                      const SizedBox(height: 16),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Text(desc,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: PyraTheme.primaryPurple),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
        child: GlassContainer(
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
                child: type == 'cardBack'
                    ? Center(
                        child: Card3DShowcase(
                          skinId: id,
                          width: 32,
                          height: 44,
                        ),
                      )
                    : type == 'border'
                        ? Center(
                            child: AvatarWithBorder(
                                emoji: '😎', size: 30, borderType: id),
                          )
                        : Icon(icon, color: iconColor, size: 28),
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
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ownedCount > 0 && type == 'joker')
                          NeoBadge(
                              text: 'x$ownedCount',
                              fontSize: 10,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2))
                        else if (isOwned)
                          const NeoBadge(
                              text: 'ACQUIS',
                              gradient: LinearGradient(
                                  colors: [Colors.greenAccent, Colors.green]),
                              fontSize: 8,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(desc,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isOwned)
                const SizedBox(
                  width: 80,
                  height: 40,
                  child: Center(
                    child: Icon(Icons.check_circle_rounded,
                        color: Colors.greenAccent, size: 28),
                  ),
                )
              else
                PulsarButton(
                  width: null,
                  text: cost == 0 ? 'GRATUIT' : '$cost',
                  paddingHorizontal: 12,
                  paddingVertical: 8,
                  fontSize: 14,
                  icon: cost == 0 
                      ? Icons.redeem_rounded 
                      : currencyIcon,
                  iconSize: 14,
                  gradient: cost == 0
                      ? const LinearGradient(colors: [Colors.greenAccent, Colors.green])
                      : (isCoins
                          ? PyraTheme.cyanGradient
                          : PyraTheme.purplePinkGradient),
                  onPressed: () async {
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user == null || user.isAnonymous) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Veuillez vous connecter avec un compte pour effectuer cet achat.'),
                            backgroundColor: Colors.redAccent));
                      }
                      return;
                    }
                    bool success = false;
                    if (type == 'joker') {
                      success = await ref
                          .read(storeServiceProvider)
                          .buyJoker(id, cost);
                    } else {
                      success = await ref
                          .read(storeServiceProvider)
                          .buyCosmetic(type, id, cost, currency);
                    }

                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Achat réussi : $title !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        if (id == 'beta') {
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            if (mounted && _betaTitleKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                _betaTitleKey.currentContext!,
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOutCubic,
                                alignment: 0.3,
                              );
                            }
                          });
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Monnaie insuffisante pour acheter : $title !'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ));
  }

  Widget _buildRealProductCard(ProductDetails product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: PyraTheme.primaryYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: PyraTheme.primaryYellow.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.monetization_on_rounded,
                  color: PyraTheme.primaryYellow, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PulsarButton(
              width: null,
              text: product.price,
              paddingHorizontal: 12,
              paddingVertical: 8,
              fontSize: 14,
              gradient: PyraTheme.cyanGradient,
              onPressed: () {
                ref.read(storeServiceProvider).buyProduct(product);
              },
            ),
          ],
        ),
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
            color:
                isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: Colors.white12) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isActive ? PyraTheme.primaryCyan : Colors.white54,
                  size: 16),
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

    final titlesOwned = profile?.titles ?? ['Novice 🐣'];
    final cardBacksOwned = profile?.cardBacks ?? ['classic'];
    final bordersOwned = profile?.bordersOwned ?? ['classic'];
    final themesOwned = profile?.themesOwned ?? ['classic'];

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Boutique',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2),
                        ),
                      ),
                      Row(
                        children: [
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                Text('$currentCoins',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                const SizedBox(width: 4),
                                const Icon(Icons.monetization_on_rounded,
                                    color: PyraTheme.primaryYellow, size: 14),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                Text('$currentDiamonds',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                const SizedBox(width: 4),
                                const Icon(Icons.diamond_rounded,
                                    color: PyraTheme.primaryPurple, size: 14),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(4),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        _buildTabButton('Pièces', Icons.monetization_on_rounded,
                            StoreTab.coins),
                        _buildTabButton(
                            'Jokers', Icons.stars_rounded, StoreTab.jokers),
                        _buildTabButton('Apparence', Icons.palette_rounded,
                            StoreTab.cosmetics),
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
                          'Achète des pièces pour débloquer des Jokers et dominer vos parties !',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Center(
                              child: CircularProgressIndicator(
                                  color: PyraTheme.primaryYellow))
                        else if (_products.isEmpty)
                          const Text(
                            'Aucun produit disponible actuellement.',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          )
                        else
                          ..._products.map((p) => _buildRealProductCard(p)),
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

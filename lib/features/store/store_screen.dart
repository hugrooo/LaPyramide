import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
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
import 'package:firebase_database/firebase_database.dart';

enum StoreTab { coins, jokers, cosmetics, vip }

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
  Offerings? _offerings;
  bool _isLoading = true;
  StoreTab _activeTab = StoreTab.coins;

  final GlobalKey _betaGiftKey = GlobalKey();
  final GlobalKey _betaTitleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab ?? StoreTab.coins;
    ref.read(storeServiceProvider).init();
    _loadOfferings();

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

  Future<void> _loadOfferings() async {
    if (kIsWeb) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final offerings = await ref.read(storeServiceProvider).fetchOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
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

  Widget _buildRealPackageCard(Package package) {
    final bool isCoins = package.storeProduct.identifier.contains('pack') || package.storeProduct.identifier.contains('coin');
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
                color: (isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple).withValues(alpha: 0.3)),
              ),
              child: Icon(
                isCoins ? Icons.monetization_on_rounded : Icons.diamond_rounded,
                color: isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.storeProduct.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.storeProduct.description,
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
              text: package.storeProduct.priceString,
              paddingHorizontal: 12,
              paddingVertical: 8,
              fontSize: 14,
              gradient: isCoins ? PyraTheme.cyanGradient : PyraTheme.purplePinkGradient,
              onPressed: () {
                ref.read(storeServiceProvider).buyPackage(package);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulatePurchase(String title, int coins, int diamonds, String price) async {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                coins > 0 ? Icons.monetization_on_rounded : Icons.diamond_rounded,
                color: coins > 0 ? PyraTheme.primaryYellow : PyraTheme.primaryPurple,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Simulation d\'achat',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Voulez-vous simuler l\'achat du pack de ${coins > 0 ? "$coins pièces" : "$diamonds diamants"} pour $price ?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryPurple),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final user = ref.read(authServiceProvider).currentUser;
                      if (user == null || user.isAnonymous) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Veuillez vous connecter pour simuler cet achat.'),
                            backgroundColor: Colors.redAccent));
                        return;
                      }
                      
                      if (coins > 0) {
                        final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/coins');
                        final snap = await dbRef.get();
                        final val = (snap.value as int?) ?? 0;
                        await dbRef.set(val + coins);
                      } else if (diamonds > 0) {
                        final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/diamonds');
                        final snap = await dbRef.get();
                        final val = (snap.value as int?) ?? 0;
                        await dbRef.set(val + diamonds);
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Achat simulé réussi : +${coins > 0 ? "$coins pièces" : "$diamonds diamants"} !'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Acheter', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simulateVipPurchase(String price) async {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFD700), // Gold
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Simulation d\'abonnement',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Voulez-vous simuler la souscription à Pyra VIP pour $price ?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryPurple),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final user = ref.read(authServiceProvider).currentUser;
                      if (user == null || user.isAnonymous) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Veuillez vous connecter pour simuler cet achat.'),
                            backgroundColor: Colors.redAccent));
                        return;
                      }
                      
                      final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
                      final snapshot = await dbRef.get();
                      if (snapshot.exists && snapshot.value is Map) {
                        final data = snapshot.value as Map;
                        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
                        final currentDiamonds = (data['diamonds'] as num?)?.toInt() ?? 0;
                        
                        List<dynamic> titles = data['titles'] is List ? List<dynamic>.from(data['titles']) : ['Novice 🐣'];
                        List<dynamic> borders = data['bordersOwned'] is List ? List<dynamic>.from(data['bordersOwned']) : ['classic'];
                        
                        if (!titles.contains('Dieu de la Pyramide 👁️')) titles.add('Dieu de la Pyramide 👁️');
                        if (!borders.contains('gold')) borders.add('gold');

                        await dbRef.update({
                          'isVip': true,
                          'vipExpireDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
                          'coins': currentCoins + 500,
                          'diamonds': currentDiamonds + 100,
                          'titles': titles,
                          'bordersOwned': borders,
                        });
                      } else {
                        await dbRef.update({
                          'isVip': true,
                          'vipExpireDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
                          'coins': 500,
                          'diamonds': 100,
                          'titles': ['Novice 🐣', 'Dieu de la Pyramide 👁️'],
                          'bordersOwned': ['classic', 'gold'],
                        });
                      }
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abonnement VIP simulé avec succès ! +500 Pièces & +100 Diamants.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('S\'abonner', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockProductCard({
    required String title,
    required String description,
    required String price,
    required int coins,
    required int diamonds,
  }) {
    final bool isCoins = coins > 0;
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
                color: (isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple).withOpacity(0.3)),
              ),
              child: Icon(
                isCoins ? Icons.monetization_on_rounded : Icons.diamond_rounded,
                color: isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple,
                size: 28,
              ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PulsarButton(
              width: null,
              text: price,
              paddingHorizontal: 12,
              paddingVertical: 8,
              fontSize: 14,
              gradient: isCoins ? PyraTheme.cyanGradient : PyraTheme.purplePinkGradient,
              onPressed: () {
                _simulatePurchase(title, coins, diamonds, price);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinsProducts() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: PyraTheme.primaryYellow));
    }
    
    final packages = _offerings?.current?.availablePackages ?? [];
    final coinPackages = packages.where((p) => p.storeProduct.identifier.contains('pack') || p.storeProduct.identifier.contains('coin')).toList();

    if (kIsWeb || coinPackages.isEmpty) {
      return Column(
        children: [
          _buildMockProductCard(
            title: 'Pack de 100 Pièces',
            description: 'Idéal pour s\'offrir son premier Joker Miroir.',
            price: '0,99 €',
            coins: 100,
            diamonds: 0,
          ),
          _buildMockProductCard(
            title: 'Pack de 500 Pièces',
            description: 'Contient de quoi débloquer plusieurs Jokers de valeur.',
            price: '3,99 €',
            coins: 500,
            diamonds: 0,
          ),
          _buildMockProductCard(
            title: 'Pack de 1200 Pièces',
            description: 'Le meilleur rapport qualité/prix pour régner sur le jeu.',
            price: '7,99 €',
            coins: 1200,
            diamonds: 0,
          ),
        ],
      );
    }
    
    return Column(
      children: coinPackages.map((p) => _buildRealPackageCard(p)).toList(),
    );
  }

  Widget _buildDiamondsProducts() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPurple));
    }
    
    final packages = _offerings?.current?.availablePackages ?? [];
    final diamondPackages = packages.where((p) => p.storeProduct.identifier.contains('diamond')).toList();

    if (kIsWeb || diamondPackages.isEmpty) {
      return Column(
        children: [
          _buildMockProductCard(
            title: 'Poignée de 50 Diamants',
            description: 'Permet de s\'acheter un dos de carte classique premium.',
            price: '1,99 €',
            coins: 0,
            diamonds: 50,
          ),
          _buildMockProductCard(
            title: 'Coffre de 250 Diamants',
            description: 'Contient de quoi s\'offrir des dos de cartes animés stylés.',
            price: '7,99 €',
            coins: 0,
            diamonds: 250,
          ),
          _buildMockProductCard(
            title: 'Trésor de 600 Diamants',
            description: 'Pour s\'acheter les plus beaux dos Cyberpunk et Pirate.',
            price: '14,99 €',
            coins: 0,
            diamonds: 600,
          ),
        ],
      );
    }
    
    return Column(
      children: diamondPackages.map((p) => _buildRealPackageCard(p)).toList(),
    );
  }

  Widget _buildVipTab(UserProfile? profile) {
    final bool isVip = profile?.isVip ?? false;
    final String vipExpireDate = profile?.vipExpireDate ?? '';

    String formattedDate = '';
    if (vipExpireDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(vipExpireDate);
        formattedDate = "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
      } catch (_) {
        formattedDate = vipExpireDate;
      }
    }

    return Column(
      children: [
        // Main Premium Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700), // Gold
                Color(0xFF8A2BE2), // Purple
                Color(0xFFFF1493), // Deep Pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(28),
            color: Colors.black.withOpacity(0.2),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 36),
                    const SizedBox(width: 8),
                    Text(
                      isVip ? 'MEMBRE VIP ACTIF 👑' : 'PYRA CLUB VIP 👑',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isVip
                      ? 'Merci pour votre soutien ! Votre abonnement est actif.'
                      : 'Devenez membre d\'élite et financez le développement de Pyramide Party.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (isVip && formattedDate.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Valable jusqu\'au : $formattedDate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  const Text(
                    '4,99 € / mois',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Annulable à tout moment sur les stores',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        
        // Benefits Section
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Avantages Exclusifs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildBenefitRow(
          Icons.diamond_rounded,
          const Color(0xFF80DEEA),
          'Monnaie mensuelle gratuite',
          '+500 Pièces et +100 Diamants crédités immédiatement chaque mois.',
        ),
        const SizedBox(height: 16),
        _buildBenefitRow(
          Icons.palette_rounded,
          const Color(0xFFFFD700),
          'Cosmétiques Légendaires Offerts',
          'Débloque automatiquement le cadre doré "Or Massif" et le titre "Dieu de la Pyramide".',
        ),
        const SizedBox(height: 16),
        _buildBenefitRow(
          Icons.bolt_rounded,
          const Color(0xFFFF8C00),
          '+50% de Gains',
          'Augmentez vos récompenses de pièces à la fin de chaque partie en ligne.',
        ),
        const SizedBox(height: 16),
        _buildBenefitRow(
          Icons.block_rounded,
          const Color(0xFFEF5350),
          'Expérience 100% Sans Pub',
          'Aucune publicité intrusive ne viendra couper le rythme de vos soirées.',
        ),
        const SizedBox(height: 32),

        // Action Button
        if (!isVip)
          PulsarButton(
            width: double.infinity,
            text: 'S\'ABONNER AU CLUB VIP',
            paddingHorizontal: 24,
            paddingVertical: 16,
            fontSize: 16,
            icon: Icons.workspace_premium_rounded,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFF007F),
              ],
            ),
            onPressed: () {
              if (kIsWeb) {
                _simulateVipPurchase('4,99 €');
                return;
              }
              final packages = _offerings?.current?.availablePackages ?? [];
              Package? vipPackage;
              for (var p in packages) {
                if (p.storeProduct.identifier == StoreService.subVipMonthlyId) {
                  vipPackage = p;
                  break;
                }
              }
              
              if (vipPackage != null) {
                ref.read(storeServiceProvider).buyPackage(vipPackage);
              } else {
                _simulateVipPurchase('4,99 €');
              }
            },
          ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, Color color, String title, String desc) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
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
                        _buildTabButton('Pièces & Diamants', Icons.monetization_on_rounded,
                            StoreTab.coins),
                        _buildTabButton(
                            'Jokers', Icons.stars_rounded, StoreTab.jokers),
                        _buildTabButton('Apparence', Icons.palette_rounded,
                            StoreTab.cosmetics),
                        _buildTabButton('Club VIP 👑', Icons.workspace_premium_rounded,
                            StoreTab.vip),
                      ],
                    ),
                  ),
                ),

                // Content Area
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                    children: [
                      if (_activeTab == StoreTab.coins) ...[
                        const Text(
                          'Achetez des pièces et des diamants avec de la vraie monnaie pour débloquer des objets uniques !',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pièces',
                            style: TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCoinsProducts(),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Diamants',
                            style: TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDiamondsProducts(),
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
                      ] else if (_activeTab == StoreTab.vip) ...[
                        _buildVipTab(profile),
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

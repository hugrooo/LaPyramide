import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
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
import 'redeem_service.dart';
import '../../shared/widgets/card_3d_showcase.dart';
import '../auth/auth_service.dart';

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
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? PyraTheme.primaryCyan : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                );
              }
            },
            child: const Text('Valider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemBanner() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showRedeemCodeDialog();
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PyraTheme.primaryPink.withValues(alpha: 0.4)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PyraTheme.primaryPink.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: PyraTheme.primaryPink, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code Promo / Redeem 🎁',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Entrer un code privilège pour obtenir des bonus gratuits',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: PyraTheme.primaryPink, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildJokersTab(UserProfile? profile) {
    final Map<String, int> jokersOwned = profile?.jokers ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: PyraTheme.primaryCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PyraTheme.primaryCyan.withOpacity(0.25)),
          ),
          child: const Row(
            children: [
              Text('⭐', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jokers achetables avec tes Pièces 🪙',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
          id: 'galaxy',
          title: 'Dos Galaxy 🌌',
          desc: 'Un dos de carte aux couleurs de la galaxie. Exclusif Pass de Combat.',
          cost: 500,
          currency: 'diamonds',
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF7C4DFF),
          ownedCount: cardBacksOwned.contains('galaxy') ? 1 : 0,
          type: 'cardBack',
          isOwned: cardBacksOwned.contains('galaxy'),
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
            iconColor: const Color(0xFFE040FB),
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
          iconColor: const Color(0xFFFFD700),
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
          icon: Icons.masks_rounded,
          iconColor: const Color(0xFFFF8C00),
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
          id: 'flamme',
          title: 'Cadre Flamme 🔥',
          desc: 'Un cadre ardent aux couleurs du feu. Exclusif Pass de Combat.',
          cost: 400,
          currency: 'coins',
          icon: Icons.whatshot_rounded,
          iconColor: const Color(0xFFFF6D00),
          ownedCount: bordersOwned.contains('flamme') ? 1 : 0,
          type: 'border',
          isOwned: bordersOwned.contains('flamme'),
        ),
        const SizedBox(height: 16),
        _buildItemPurchaseCard(
          id: 'diamant',
          title: 'Cadre Diamant 💎',
          desc: 'Le cadre ultime en cristal pur. Exclusif Pass de Combat.',
          cost: 300,
          currency: 'diamonds',
          icon: Icons.diamond_rounded,
          iconColor: const Color(0xFF80DEEA),
          ownedCount: bordersOwned.contains('diamant') ? 1 : 0,
          type: 'border',
          isOwned: bordersOwned.contains('diamant'),
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
    final IconData currencyIcon =
        isCoins ? Icons.monetization_on_rounded : Icons.diamond_rounded;

    return GestureDetector(
      onTap: () {
        if ({'cardBack', 'title', 'border', 'theme'}.contains(type)) {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type == 'cardBack')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Card3DShowcase(skinId: id, width: 140, height: 196),
                      )
                    else if (type == 'border')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: AvatarWithBorder(emoji: '😎', size: 80, borderType: id),
                      )
                    else
                      Icon(icon, color: iconColor, size: 80),
                    const SizedBox(height: 16),
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(desc,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryPurple),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
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
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: type == 'cardBack'
                  ? Center(child: Card3DShowcase(skinId: id, width: 32, height: 44, showControls: false))
                  : type == 'border'
                      ? Center(child: AvatarWithBorder(emoji: '😎', size: 30, borderType: id))
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
                        child: Text(title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (ownedCount > 0 && type == 'joker')
                        NeoBadge(
                            text: 'x$ownedCount', fontSize: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2))
                      else if (isOwned)
                        const NeoBadge(
                            text: 'ACQUIS',
                            gradient: LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                            fontSize: 8,
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isOwned)
              const SizedBox(
                  width: 80, height: 40,
                  child: Center(
                      child: Icon(Icons.check_circle_rounded,
                          color: Colors.greenAccent, size: 28)))
            else
              PulsarButton(
                width: null,
                text: cost == 0 ? 'GRATUIT' : '$cost',
                paddingHorizontal: 12, paddingVertical: 8, fontSize: 14,
                icon: cost == 0 ? Icons.redeem_rounded : currencyIcon,
                iconSize: 14,
                gradient: cost == 0
                    ? const LinearGradient(colors: [Colors.greenAccent, Colors.green])
                    : (isCoins ? PyraTheme.cyanGradient : PyraTheme.purplePinkGradient),
                onPressed: () async {
                  final user = ref.read(authServiceProvider).currentUser;
                  if (user == null || user.isAnonymous) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Veuillez vous connecter avec un compte pour effectuer cet achat.'),
                          backgroundColor: Colors.redAccent));
                    }
                    return;
                  }
                  final success = type == 'joker'
                      ? await ref.read(storeServiceProvider).buyJoker(id, cost)
                      : await ref.read(storeServiceProvider).buyCosmetic(type, id, cost, currency);

                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Achat réussi : $title !'),
                              backgroundColor: Colors.green));
                      if (id == 'beta') {
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (mounted && _betaTitleKey.currentContext != null) {
                            Scrollable.ensureVisible(_betaTitleKey.currentContext!,
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOutCubic, alignment: 0.3);
                          }
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Monnaie insuffisante pour acheter : $title !'),
                          backgroundColor: Colors.redAccent));
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealPackageCard(Package package) {
    final bool isCoins = package.storeProduct.identifier.contains('pack') ||
        package.storeProduct.identifier.contains('coin');
    final Color accent = isCoins ? PyraTheme.primaryYellow : PyraTheme.primaryPurple;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(isCoins ? Icons.monetization_on_rounded : Icons.diamond_rounded,
                  color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(package.storeProduct.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(package.storeProduct.description,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PulsarButton(
              width: null, text: package.storeProduct.priceString,
              paddingHorizontal: 12, paddingVertical: 8, fontSize: 14,
              gradient: isCoins ? PyraTheme.cyanGradient : PyraTheme.purplePinkGradient,
              onPressed: () => ref.read(storeServiceProvider).buyPackage(package),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerVipPurchase() {
    if (kIsWeb) {
      _showStoreUnavailable();
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
      _showStoreUnavailable();
    }
  }

  void _showStoreUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Boutique indisponible — veuillez réessayer plus tard.'),
      backgroundColor: Colors.redAccent,
    ));
  }

  Widget _buildStoreUnavailableMessage() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded,
              color: Colors.white.withOpacity(0.5), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Boutique indisponible — vérifiez votre connexion',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buyFallbackCoins(int amount, String title) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/coins');
    final snapshot = await dbRef.get();
    final val = snapshot.value;
    final currentCoins = (val is num) ? val.toInt() : 0;
    await dbRef.set(currentCoins + amount);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Achat réussi ! +$amount Pièces ajoutées.'),
          backgroundColor: PyraTheme.primaryCyan,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _buyFallbackDiamonds(int amount, String title) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/diamonds');
    final snapshot = await dbRef.get();
    final val = snapshot.value;
    final currentDiamonds = (val is num) ? val.toInt() : 0;
    await dbRef.set(currentDiamonds + amount);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Achat réussi ! +$amount Diamants ajoutés.'),
          backgroundColor: PyraTheme.primaryPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Widget _buildDemoPackCard({
    required String title,
    required String amountText,
    required String priceText,
    required String badgeText,
    required Color badgeColor,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor.withValues(alpha: 0.15),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
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
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  amountText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: badgeColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Text(
              priceText,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCoinsPacks() {
    return Column(
      children: [
        _buildDemoPackCard(
          title: 'Bourse de Pièces 🪙',
          amountText: '+500 Pièces',
          priceText: '0,99 €',
          badgeText: 'STARTER',
          badgeColor: PyraTheme.primaryGreen,
          icon: '🪙',
          onTap: () => _buyFallbackCoins(500, 'Bourse de Pièces'),
        ),
        const SizedBox(height: 12),
        _buildDemoPackCard(
          title: 'Sac de Pièces 💰',
          amountText: '+1 500 Pièces',
          priceText: '2,49 €',
          badgeText: '+20% GRATUIT',
          badgeColor: PyraTheme.primaryCyan,
          icon: '💰',
          onTap: () => _buyFallbackCoins(1500, 'Sac de Pièces'),
        ),
        const SizedBox(height: 12),
        _buildDemoPackCard(
          title: 'Coffre-Fort 🏦',
          amountText: '+5 000 Pièces',
          priceText: '6,99 €',
          badgeText: '+50% GRATUIT',
          badgeColor: PyraTheme.primaryPurple,
          icon: '🏦',
          onTap: () => _buyFallbackCoins(5000, 'Coffre-Fort'),
        ),
        const SizedBox(height: 12),
        _buildDemoPackCard(
          title: 'Trésor Pyramide 👑',
          amountText: '+15 000 Pièces',
          priceText: '14,99 €',
          badgeText: 'BEST OFFER 🔥',
          badgeColor: PyraTheme.primaryYellow,
          icon: '👑',
          onTap: () => _buyFallbackCoins(15000, 'Trésor Pyramide'),
        ),
      ],
    );
  }

  Widget _buildFallbackDiamondsPacks() {
    return Column(
      children: [
        _buildDemoPackCard(
          title: 'Poignée de Diamants 💎',
          amountText: '+50 Diamants',
          priceText: '1,49 €',
          badgeText: 'STARTER',
          badgeColor: PyraTheme.primaryCyan,
          icon: '💎',
          onTap: () => _buyFallbackDiamonds(50, 'Poignée de Diamants'),
        ),
        const SizedBox(height: 12),
        _buildDemoPackCard(
          title: 'Sac de Diamants 💎✨',
          amountText: '+150 Diamants',
          priceText: '3,99 €',
          badgeText: '+15% BONUS',
          badgeColor: PyraTheme.primaryPink,
          icon: '💎',
          onTap: () => _buyFallbackDiamonds(150, 'Sac de Diamants'),
        ),
        const SizedBox(height: 12),
        _buildDemoPackCard(
          title: 'Coffre Diamants 🏛️💎',
          amountText: '+500 Diamants',
          priceText: '9,99 €',
          badgeText: 'SUPER OFFRE 🔥',
          badgeColor: PyraTheme.primaryYellow,
          icon: '🏛️',
          onTap: () => _buyFallbackDiamonds(500, 'Coffre Diamants'),
        ),
      ],
    );
  }

  Widget _buildCoinsProducts() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: PyraTheme.primaryYellow));
    }

    final packages = _offerings?.current?.availablePackages ?? [];
    final coinPackages = packages
        .where((p) =>
            p.storeProduct.identifier.contains('pack') ||
            p.storeProduct.identifier.contains('coin'))
        .toList();

    if (coinPackages.isNotEmpty) {
      return Column(
        children: coinPackages.map((p) => _buildRealPackageCard(p)).toList(),
      );
    }

    return _buildFallbackCoinsPacks();
  }

  Widget _buildDiamondsProducts() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: PyraTheme.primaryPurple));
    }

    final packages = _offerings?.current?.availablePackages ?? [];
    final diamondPackages = packages
        .where((p) => p.storeProduct.identifier.contains('diamond'))
        .toList();

    if (diamondPackages.isNotEmpty) {
      return Column(
        children: diamondPackages.map((p) => _buildRealPackageCard(p)).toList(),
      );
    }

    return _buildFallbackDiamondsPacks();
  }

  Widget _buildVipTab(UserProfile? profile) {
    final bool isVip = profile?.isVip ?? false;
    final String vipExpireDate = profile?.vipExpireDate ?? '';

    String formattedDate = '';
    if (vipExpireDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(vipExpireDate);
        formattedDate =
            "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
      } catch (_) {
        formattedDate = vipExpireDate;
      }
    }

    const vipBenefits = [
      (Icons.monetization_on_rounded, Color(0xFFFFD700), '+500 Pièces & +100 Diamants / mois',
          'Crédités automatiquement chaque mois dès le renouvellement.'),
      (Icons.palette_rounded, Color(0xFF80DEEA), 'Cosmétiques Légendaires',
          'Cadre "Or Massif" + titre "Dieu de la Pyramide" offerts immédiatement.'),
      (Icons.bolt_rounded, Color(0xFFFF8C00), '+50% de Gains en partie',
          'Multipliez vos récompenses XP et pièces à chaque partie en ligne.'),
      (Icons.block_rounded, Color(0xFFEF5350), '100% Sans Pub',
          'Aucune publicité pendant vos soirées.'),
    ];

    const bundleBenefits = [
      (Icons.workspace_premium_rounded, Color(0xFFFFD700), 'Tout le Club VIP',
          '+500 Pièces/mois, cosmétiques légendaires, +50% gains, sans pub.'),
      (Icons.military_tech_rounded, Color(0xFFE040FB), 'Pass de Combat inclus',
          'Toutes les 15 récompenses du pass débloquées — tiers gratuits ET premium.'),
      (Icons.savings_rounded, Color(0xFF69F0AE), 'Économisez 2,98 €/mois',
          'VIP (4,99€) + Pass (2,99€) séparément = 7,98€. Offre groupée : 4,99€.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── OFFRE GROUPÉE (mise en avant) ────────────────────────────
        Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE040FB), Color(0xFF8A2BE2), Color(0xFFFFD700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE040FB).withOpacity(0.4),
                      blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 8)),
                ],
              ),
              child: GlassContainer(
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(24),
                color: Colors.black.withOpacity(0.15),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⚡', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 8),
                        Text('VIP + PASS COMBAT',
                            style: TextStyle(color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('L\'offre complète — VIP et toutes les récompenses du Pass',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('4,99 €',
                            style: TextStyle(color: Colors.white, fontSize: 38,
                                fontWeight: FontWeight.w900, height: 1.0)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('7,98 €',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.white54)),
                              const Text('par mois',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final b in bundleBenefits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(b.$1, color: b.$2, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(b.$3,
                                  style: const TextStyle(color: Colors.white, fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (!isVip)
                      PulsarButton(
                        width: double.infinity,
                        text: 'S\'ABONNER — VIP + PASS',
                        paddingHorizontal: 20,
                        paddingVertical: 14,
                        fontSize: 15,
                        icon: Icons.workspace_premium_rounded,
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFE040FB)]),
                        onPressed: _triggerVipPurchase,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          formattedDate.isNotEmpty
                              ? 'Actif jusqu\'au $formattedDate ✓'
                              : 'Abonnement actif ✓',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Badge "MEILLEURE OFFRE"
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF69F0AE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('MEILLEURE OFFRE',
                    style: TextStyle(color: Colors.black,
                        fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── VIP SEUL ─────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
            color: Colors.white.withOpacity(0.03),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD700), size: 22),
                  const SizedBox(width: 8),
                  const Text('Club VIP uniquement',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  const Text('4,99 €/mois',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 16,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 12),
              for (final b in vipBenefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(b.$1, color: b.$2, size: 15),
                      const SizedBox(width: 8),
                      Expanded(child: Text(b.$3,
                          style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (!isVip)
                GestureDetector(
                  onTap: _triggerVipPurchase,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFFFD700).withOpacity(0.08),
                    ),
                    child: const Text('S\'abonner au VIP seulement',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── PASS COMBAT SEUL ─────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PyraTheme.primaryPurple.withOpacity(0.4)),
            color: Colors.white.withOpacity(0.03),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded,
                      color: PyraTheme.primaryPurple, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pass de Combat uniquement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '2,99 €/mois',
                    style: TextStyle(
                      color: PyraTheme.primaryPurple,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Débloque les 10 récompenses premium du Pass de Combat chaque saison.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (kIsWeb) {
                    _showStoreUnavailable();
                    return;
                  }
                  final user = ref.read(authServiceProvider).currentUser;
                  if (user == null || user.isAnonymous) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Connectez-vous pour acheter le Pass.'),
                        backgroundColor: Colors.redAccent));
                    return;
                  }
                  final packages = _offerings?.current?.availablePackages ?? [];
                  Package? battlePassPackage;
                  for (var p in packages) {
                    if (p.storeProduct.identifier.contains('battle_pass') ||
                        p.storeProduct.identifier.contains('pass_combat')) {
                      battlePassPackage = p;
                      break;
                    }
                  }
                  if (battlePassPackage != null) {
                    ref.read(storeServiceProvider).buyPackage(battlePassPackage);
                  } else {
                    _showStoreUnavailable();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: PyraTheme.primaryPurple.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(12),
                    color: PyraTheme.primaryPurple.withOpacity(0.08),
                  ),
                  child: const Text('S\'abonner au Pass seulement',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: PyraTheme.primaryPurple,
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text('Annulable à tout moment depuis les Stores',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
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
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBanner(int coins, int diamonds) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCurrencyStat('🪙', '$coins', 'Pièces', PyraTheme.primaryYellow),
              Container(width: 1, height: 40, color: Colors.white12),
              _buildCurrencyStat('💎', '$diamonds', 'Diamants', PyraTheme.primaryPurple),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text('Gagnes des Pièces en jouant !',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyStat(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text(value,
                style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      ],
    );
  }

  Widget _buildTabButton(String text, IconData icon, StoreTab tab) {
    final bool isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? PyraTheme.primaryCyan.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: PyraTheme.primaryCyan.withValues(alpha: 0.4)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isActive ? PyraTheme.primaryCyan : Colors.white38,
                  size: 18),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white38,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showRedeemCodeDialog();
                            },
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: PyraTheme.primaryPink.withValues(alpha: 0.5)),
                              child: const Row(
                                children: [
                                  Icon(Icons.card_giftcard_rounded, color: PyraTheme.primaryPink, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Code',
                                    style: TextStyle(color: PyraTheme.primaryPink, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                const Text('🪙', style: TextStyle(fontSize: 13)),
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
                                const Text('💎', style: TextStyle(fontSize: 13)),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton('Monnaie', Icons.monetization_on_rounded, StoreTab.coins),
                        _buildTabButton('Jokers', Icons.stars_rounded, StoreTab.jokers),
                        _buildTabButton('Apparence', Icons.palette_rounded, StoreTab.cosmetics),
                        _buildTabButton('VIP 👑', Icons.workspace_premium_rounded, StoreTab.vip),
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
                        _buildBalanceBanner(currentCoins, currentDiamonds),
                        const SizedBox(height: 16),
                        _buildRedeemBanner(),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pièces',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
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
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDiamondsProducts(),
                      ] else if (_activeTab == StoreTab.jokers) ...[
                        const Text(
                          'Utilise tes pièces pour acheter des Jokers dévastateurs utilisables en pleine partie !',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildJokersTab(profile),
                      ] else if (_activeTab == StoreTab.cosmetics) ...[
                        const Text(
                          'Dépense tes diamants et pièces pour obtenir des dos de cartes et titres légendaires !',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14),
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

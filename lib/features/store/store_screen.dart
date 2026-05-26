import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../profile/user_profile_provider.dart';
import 'store_service.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  List<ProductDetails> _products = [];
  bool _isLoading = true;

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
    // Si les produits ne chargent pas (ex: simulateur non configuré), afficher des packs fictifs
    return Column(
      children: [
        _buildPackCard('Petit Pack', '100 Pièces', '0,99 €', 100),
        const SizedBox(height: 16),
        _buildPackCard('Moyen Pack', '500 Pièces', '3,99 €', 500, isPopular: true),
        const SizedBox(height: 16),
        _buildPackCard('Grand Pack', '1200 Pièces', '8,99 €', 1200),
      ],
    );
  }

  Widget _buildPackCard(String title, String desc, String price, int coins, {bool isPopular = false, ProductDetails? product}) {
    return GlassContainer(
      innerGlow: isPopular,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
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
          ),
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
                    ),
                    child: const Text('POPULAIRE', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              ],
            ),
          ),
          PulsarButton(
            text: price,
            paddingHorizontal: 16,
            gradient: isPopular ? const LinearGradient(colors: [PyraTheme.primaryPink, Colors.pinkAccent]) : PyraTheme.festiveGradient,
            onPressed: () async {
              if (product != null) {
                ref.read(storeServiceProvider).buyProduct(product);
              } else {
                // Achat fictif pour le mode de développement/simulateur
                await ref.read(storeServiceProvider).addCoinsFictitiously(coins);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Achat fictif de $coins pièces réussi (Simulateur / Dev mode) !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final currentCoins = userProfileAsync.value?.coins ?? 0;

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
                          'Boutique',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            Text('$currentCoins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.monetization_on_rounded, color: PyraTheme.primaryYellow, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text(
                        'Achète des pièces pour débloquer des Jokers et passer tes gorgées pendant la partie !',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPink))
                      else if (_products.isNotEmpty)
                        Column(
                          children: _products.map((p) {
                            int coins = 100;
                            if (p.id == StoreService.pack500Id) coins = 500;
                            if (p.id == StoreService.pack1200Id) coins = 1200;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildPackCard(
                                p.title,
                                '$coins Pièces',
                                p.price,
                                coins,
                                isPopular: coins == 500,
                                product: p,
                              ),
                            );
                          }).toList(),
                        )
                      else
                        _buildFallbackPacks(), // Si on est sur simulateur ou pas configuré
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

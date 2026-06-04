import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_database/firebase_database.dart';
import '../auth/auth_service.dart';

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(ref);
});

class StoreService {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Example Product IDs (You need to create these exactly in App Store Connect)
  static const String pack100Id = 'com.lapyramide.pack100';
  static const String pack500Id = 'com.lapyramide.pack500';
  static const String pack1200Id = 'com.lapyramide.pack1200';

  StoreService(this._ref);

  void init() {
    try {
      final purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen((purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      }, onDone: () {
        _subscription?.cancel();
      }, onError: (error) {
        print("Erreur d'achat: $error");
      });
    } catch (e) {
      print("Erreur d'initialisation du store (simulateur ou autre): $e");
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<List<ProductDetails>> fetchProducts() async {
    try {
      final bool available =
          await _iap.isAvailable().timeout(const Duration(seconds: 3));
      if (!available) {
        print("Store indisponible");
        return [];
      }

      const Set<String> kIds = <String>{pack100Id, pack500Id, pack1200Id};
      final ProductDetailsResponse response = await _iap
          .queryProductDetails(kIds)
          .timeout(const Duration(seconds: 5));

      if (response.notFoundIDs.isNotEmpty) {
        print("Produits non trouvés: ${response.notFoundIDs}");
      }

      return response.productDetails;
    } catch (e) {
      print("Erreur de récupération des produits (timeout ou autre): $e");
      return [];
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // En attente
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print("Erreur d'achat: ${purchaseDetails.error}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // L'achat a réussi, donner la récompense
          await _deliverProduct(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    int coinsToAdd = 0;
    if (purchaseDetails.productID == pack100Id) coinsToAdd = 100;
    if (purchaseDetails.productID == pack500Id) coinsToAdd = 500;
    if (purchaseDetails.productID == pack1200Id) coinsToAdd = 1200;

    if (coinsToAdd > 0) {
      final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/coins');
      // Pour éviter les écritures concurrentes, on lit puis on écrit.
      // Dans une application en production, utilisez un Transaction Firebase
      final snapshot = await dbRef.get();
      final currentCoins = (snapshot.value as int?) ?? 0;
      await dbRef.set(currentCoins + coinsToAdd);
      print("Ajout de $coinsToAdd pièces au compte ${user.uid}");
    }
  }

  Future<bool> buyJoker(String jokerId, int cost) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return false;

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    final snapshot = await dbRef.get();
    if (!snapshot.exists || snapshot.value is! Map) return false;

    final data = snapshot.value as Map;
    final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;

    if (currentCoins < cost) return false;

    final rawJokers = data['jokers'];
    int currentJokerCount = 0;
    if (rawJokers is Map) {
      currentJokerCount = (rawJokers[jokerId] as num?)?.toInt() ?? 0;
    }

    // Déduire pièces et ajouter le joker
    await dbRef.update({
      'coins': currentCoins - cost,
      'jokers/$jokerId': currentJokerCount + 1,
    });
    return true;
  }

  Future<bool> buyCosmetic(
      String type, String itemId, int cost, String currency) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return false;

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    final snapshot = await dbRef.get();
    if (!snapshot.exists || snapshot.value is! Map) return false;

    final data = snapshot.value as Map;

    // Vérifier monnaie
    if (currency == 'coins') {
      final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
      if (currentCoins < cost) return false;
      await dbRef.child('coins').set(currentCoins - cost);
    } else {
      final currentDiamonds = (data['diamonds'] as num?)?.toInt() ?? 0;
      if (currentDiamonds < cost) return false;
      await dbRef.child('diamonds').set(currentDiamonds - cost);
    }

    // Ajouter le cosmétique à l'inventaire
    String listPath;
    String defaultItem = 'classic';
    
    if (type == 'cardBack') {
      listPath = 'cardBacks';
    } else if (type == 'title') {
      listPath = 'titles';
      defaultItem = 'Novice 🐣';
    } else if (type == 'border') {
      listPath = 'bordersOwned';
    } else {
      listPath = '${type}s';
    }

    List<dynamic> currentList = [];
    if (data[listPath] is List) {
      currentList = List<dynamic>.from(data[listPath]);
    } else if (data[listPath] is Map) {
      currentList = List<dynamic>.from((data[listPath] as Map).values);
    } else {
      currentList = [defaultItem];
    }

    if (!currentList.contains(itemId)) {
      currentList.add(itemId);
      await dbRef.child(listPath).set(currentList);
    }
    return true;
  }
}

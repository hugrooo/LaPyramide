import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../auth/auth_service.dart';

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(ref);
});

class StoreService {
  final Ref _ref;
  bool _isInitialized = false;

  static const String _apiKeyAndroid = 'goog_placeholder_api_key';
  static const String _apiKeyIOS = 'appl_UhDMyaJAFJPCYfnzxwkqBzwNhWo';

  static const String vipEntitlementId = 'premium';

  static const String pack100Id = 'com.lapyramide.pack100';
  static const String pack500Id = 'com.lapyramide.pack500';
  static const String pack1200Id = 'com.lapyramide.pack1200';
  static const String diamonds50Id = 'com.lapyramide.diamonds50';
  static const String diamonds250Id = 'com.lapyramide.diamonds250';
  static const String diamonds600Id = 'com.lapyramide.diamonds600';
  static const String subVipMonthlyId = 'com.lapyramide.sub_vip_monthly';

  StoreService(this._ref);

  Future<void> init() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      PurchasesConfiguration configuration;
      if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_apiKeyAndroid);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        configuration = PurchasesConfiguration(_apiKeyIOS);
      } else {
        return;
      }

      await Purchases.configure(configuration);
      _isInitialized = true;

      _ref.listen(authServiceProvider, (previous, next) {
        final user = next.currentUser;
        if (user != null && !user.isAnonymous) {
          Purchases.logIn(user.uid);
        } else {
          Purchases.logOut();
        }
      }, fireImmediately: true);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateVipStatusFromCustomerInfo(customerInfo);
      });
    } catch (e) {
      print("Erreur d'initialisation de RevenueCat: $e");
    }
  }

  void dispose() {}

  Future<Offerings?> fetchOfferings() async {
    if (kIsWeb) return null;
    try {
      await init();
      return await Purchases.getOfferings();
    } catch (e) {
      print("Erreur de récupération des Offerings RevenueCat: $e");
      return null;
    }
  }

  Future<void> buyPackage(Package package) async {
    if (kIsWeb) return;
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      await _updateVipStatusFromCustomerInfo(customerInfo);
      await _deliverNonSubscriptionProductIfNeeded(package.storeProduct.identifier);
    } catch (e) {
      print("Erreur d'achat de package: $e");
    }
  }

  Future<void> _updateVipStatusFromCustomerInfo(CustomerInfo customerInfo) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null || user.isAnonymous) return;

    final userDbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    
    final bool isVipActive = customerInfo.entitlements.all[vipEntitlementId]?.isActive ?? false;
    final String? expirationDate = customerInfo.entitlements.all[vipEntitlementId]?.expirationDate;

    if (isVipActive) {
      final snapshot = await userDbRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        List<dynamic> titles = data['titles'] is List ? List<dynamic>.from(data['titles']) : ['Novice 🐣'];
        List<dynamic> borders = data['bordersOwned'] is List ? List<dynamic>.from(data['bordersOwned']) : ['classic'];
        
        if (!titles.contains('Dieu de la Pyramide 👁️')) titles.add('Dieu de la Pyramide 👁️');
        if (!borders.contains('gold')) borders.add('gold');

        await userDbRef.update({
          'isVip': true,
          'vipExpireDate': expirationDate ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'titles': titles,
          'bordersOwned': borders,
        });
      } else {
        await userDbRef.update({
          'isVip': true,
          'vipExpireDate': expirationDate ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'titles': ['Novice 🐣', 'Dieu de la Pyramide 👁️'],
          'bordersOwned': ['classic', 'gold'],
        });
      }
    } else {
      await userDbRef.update({
        'isVip': false,
      });
    }
  }

  Future<void> _deliverNonSubscriptionProductIfNeeded(String productID) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    int coinsToAdd = 0;
    int diamondsToAdd = 0;

    if (productID.contains('pack100') || productID.contains('coin100') || productID == pack100Id) coinsToAdd = 100;
    if (productID.contains('pack500') || productID.contains('coin500') || productID == pack500Id) coinsToAdd = 500;
    if (productID.contains('pack1200') || productID.contains('coin1200') || productID == pack1200Id) coinsToAdd = 1200;

    if (productID.contains('diamonds50') || productID == diamonds50Id) diamondsToAdd = 50;
    if (productID.contains('diamonds250') || productID == diamonds250Id) diamondsToAdd = 250;
    if (productID.contains('diamonds600') || productID == diamonds600Id) diamondsToAdd = 600;

    final userDbRef = FirebaseDatabase.instance.ref('users/${user.uid}');

    if (coinsToAdd > 0) {
      final dbRef = userDbRef.child('coins');
      final snapshot = await dbRef.get();
      final currentCoins = (snapshot.value as int?) ?? 0;
      await dbRef.set(currentCoins + coinsToAdd);
      print("RevenueCat: Ajout de $coinsToAdd pièces");
    }

    if (diamondsToAdd > 0) {
      final dbRef = userDbRef.child('diamonds');
      final snapshot = await dbRef.get();
      final currentDiamonds = (snapshot.value as int?) ?? 0;
      await dbRef.set(currentDiamonds + diamondsToAdd);
      print("RevenueCat: Ajout de $diamondsToAdd diamants");
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

    if (currency == 'coins') {
      final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
      if (currentCoins < cost) return false;
      await dbRef.child('coins').set(currentCoins - cost);
    } else {
      final currentDiamonds = (data['diamonds'] as num?)?.toInt() ?? 0;
      if (currentDiamonds < cost) return false;
      await dbRef.child('diamonds').set(currentDiamonds - cost);
    }

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

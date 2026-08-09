import 'package:firebase_database/firebase_database.dart';

class RedeemResult {
  final bool success;
  final String message;
  final String? rewardText;

  const RedeemResult({
    required this.success,
    required this.message,
    this.rewardText,
  });
}

class RedeemService {
  static Future<RedeemResult> redeemCode({
    required String rawCode,
    required String uid,
  }) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return const RedeemResult(success: false, message: 'Veuillez saisir un code promo.');
    }

    try {
      final userRef = FirebaseDatabase.instance.ref('users/$uid');

      // 1. Vérifier si l'utilisateur a déjà utilisé ce code
      final claimedSnap = await userRef.child('claimedPromoCodes/$code').get();
      if (claimedSnap.exists && claimedSnap.value == true) {
        return const RedeemResult(
          success: false,
          message: 'Vous avez déjà utilisé ce code promo.',
        );
      }

      // 2. Chercher le code dans le nœud Firebase promoCodes/{code}
      final codeRef = FirebaseDatabase.instance.ref('promoCodes/$code');
      final codeSnap = await codeRef.get();

      if (!codeSnap.exists || codeSnap.value is! Map) {
        // Fallback spécial pour le code fondateur PYRAMIDE2026 si non encore initialisé en DB
        if (code == 'PYRAMIDE2026') {
          await userRef.child('claimedPromoCodes/$code').set(true);
          final coinsSnap = await userRef.child('coins').get();
          final currentCoins = (coinsSnap.value as int?) ?? 0;
          await userRef.child('coins').set(currentCoins + 100);

          return const RedeemResult(
            success: true,
            message: '🎉 Code Fondateur validé ! +100 Pièces ajoutées.',
            rewardText: '+100 🪙',
          );
        }

        return const RedeemResult(
          success: false,
          message: 'Code promo invalide ou inconnu.',
        );
      }

      final data = Map<String, dynamic>.from(codeSnap.value as Map);
      final bool isActive = data['active'] ?? true;
      final int maxUses = (data['maxUses'] as num?)?.toInt() ?? 999999;
      final int currentUses = (data['currentUses'] as num?)?.toInt() ?? 0;
      final String? expirationDateStr = data['expirationDate'] as String?;

      if (!isActive) {
        return const RedeemResult(
          success: false,
          message: 'Ce code promo est actuellement désactivé.',
        );
      }

      if (currentUses >= maxUses) {
        return const RedeemResult(
          success: false,
          message: 'Le nombre maximum d\'utilisations de ce code a été atteint.',
        );
      }

      if (expirationDateStr != null && expirationDateStr.isNotEmpty) {
        final expDate = DateTime.tryParse(expirationDateStr);
        if (expDate != null && DateTime.now().isAfter(expDate)) {
          return const RedeemResult(
            success: false,
            message: 'Ce code promo a expiré.',
          );
        }
      }

      // 3. Appliquer la récompense
      final String rewardType = data['rewardType'] ?? 'coins';
      final dynamic rewardValue = data['rewardValue'] ?? 100;
      String rewardSummary = '';

      if (rewardType == 'coins') {
        final int amount = (rewardValue as num?)?.toInt() ?? 100;
        final coinsSnap = await userRef.child('coins').get();
        final currentCoins = (coinsSnap.value as int?) ?? 0;
        await userRef.child('coins').set(currentCoins + amount);
        rewardSummary = '+$amount 🪙';
      } else if (rewardType == 'diamonds') {
        final int amount = (rewardValue as num?)?.toInt() ?? 20;
        final diamondsSnap = await userRef.child('diamonds').get();
        final currentDiamonds = (diamondsSnap.value as int?) ?? 0;
        await userRef.child('diamonds').set(currentDiamonds + amount);
        rewardSummary = '+$amount 💎';
      } else if (rewardType == 'title') {
        final String titleName = rewardValue.toString();
        final titlesSnap = await userRef.child('titles').get();
        List<dynamic> titles = titlesSnap.exists && titlesSnap.value is List
            ? List<dynamic>.from(titlesSnap.value as List)
            : ['Novice 🐣'];
        if (!titles.contains(titleName)) titles.add(titleName);
        await userRef.child('titles').set(titles);
        rewardSummary = 'Titre "$titleName"';
      } else if (rewardType == 'cardBack') {
        final String backId = rewardValue.toString();
        final backsSnap = await userRef.child('cardBacks').get();
        List<dynamic> cardBacks = backsSnap.exists && backsSnap.value is List
            ? List<dynamic>.from(backsSnap.value as List)
            : ['classic'];
        if (!cardBacks.contains(backId)) cardBacks.add(backId);
        await userRef.child('cardBacks').set(cardBacks);
        rewardSummary = 'Dos de carte "$backId"';
      }

      // 4. Marquer comme utilisé
      await userRef.child('claimedPromoCodes/$code').set(true);
      await codeRef.child('currentUses').set(currentUses + 1);

      return RedeemResult(
        success: true,
        message: '🎉 Code promo validé avec succès ! ($rewardSummary)',
        rewardText: rewardSummary,
      );
    } catch (e) {
      return RedeemResult(
        success: false,
        message: 'Erreur lors de la validation du code: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }
}

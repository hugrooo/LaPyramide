import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../auth/auth_service.dart';

class UserProfile {
  final String name;
  final String searchName;
  final int level;
  final int xp;
  final int coins;
  final int diamonds;
  final String emoji;
  final String activeCardBack;
  final String activeTitle;
  final int lastDailyChestClaimed;
  final int drinksGiven;
  final int bluffWins;
  final int streak;
  final int gamesPlayed;
  final int lastClaimedLevel;
  final Map<String, int> jokers;
  final List<String> cardBacks;
  final List<String> titles;
  final List<String> bordersOwned;
  final String selectedBorder;
  final List<String> themesOwned;
  final String selectedTheme;
  // Quêtes : clé = path de la quête, valeur = {progress, claimed}
  final Map<String, Map<String, dynamic>> quests;
  final bool isVip;
  final String vipExpireDate;
  final bool battlePassActive;

  UserProfile({
    this.name = 'Utilisateur',
    this.searchName = 'utilisateur',
    required this.level,
    required this.xp,
    required this.coins,
    required this.diamonds,
    required this.emoji,
    required this.activeCardBack,
    required this.activeTitle,
    required this.lastDailyChestClaimed,
    required this.drinksGiven,
    required this.bluffWins,
    required this.streak,
    required this.gamesPlayed,
    required this.lastClaimedLevel,
    required this.jokers,
    required this.cardBacks,
    required this.titles,
    required this.bordersOwned,
    required this.selectedBorder,
    required this.themesOwned,
    required this.selectedTheme,
    this.quests = const {},
    this.isVip = false,
    this.vipExpireDate = '',
    this.battlePassActive = false,
  });

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    final isVip = map['isVip'] == true;
    final vipExpireDate = map['vipExpireDate']?.toString() ?? '';

    // Parse jokers safely
    final rawJokers = map['jokers'];
    final Map<String, int> jokersMap = {};
    if (rawJokers is Map) {
      rawJokers.forEach((key, val) {
        jokersMap[key.toString()] = (val as num?)?.toInt() ?? 0;
      });
    } else {
      jokersMap['miroir'] = 0;
      jokersMap['bouclier'] = 0;
      jokersMap['detecteur'] = 0;
      jokersMap['double_dose'] = 0;
    }

    // Parse list of card backs safely
    final List<String> cardBacksList = [];
    if (map['cardBacks'] is List) {
      cardBacksList.addAll((map['cardBacks'] as List).map((e) => e.toString()));
    } else if (map['cardBacks'] is Map) {
      cardBacksList
          .addAll((map['cardBacks'] as Map).values.map((e) => e.toString()));
    }
    if (cardBacksList.isEmpty) {
      cardBacksList.add('classic');
    }

    // Parse list of titles safely
    final List<String> titlesList = [];
    if (map['titles'] is List) {
      titlesList.addAll((map['titles'] as List).map((e) => e.toString()));
    } else if (map['titles'] is Map) {
      titlesList.addAll((map['titles'] as Map).values.map((e) => e.toString()));
    }
    if (titlesList.isEmpty) {
      titlesList.add('Novice 🐣');
    }

    // Parse list of borders safely
    final List<String> bordersList = [];
    if (map['bordersOwned'] is List) {
      bordersList
          .addAll((map['bordersOwned'] as List).map((e) => e.toString()));
    } else if (map['bordersOwned'] is Map) {
      bordersList
          .addAll((map['bordersOwned'] as Map).values.map((e) => e.toString()));
    }
    if (bordersList.isEmpty) {
      bordersList.add('classic'); // classic border (none)
    }

    // Parse list of themes safely
    final List<String> themesList = [];
    if (map['themesOwned'] is List) {
      themesList.addAll((map['themesOwned'] as List).map((e) => e.toString()));
    } else if (map['themesOwned'] is Map) {
      themesList
          .addAll((map['themesOwned'] as Map).values.map((e) => e.toString()));
    }
    if (themesList.isEmpty) {
      themesList.add('classic'); // classic theme
    }

    // Parser les quêtes depuis Firebase
    final Map<String, Map<String, dynamic>> questsMap = {};
    final rawQuests = map['quests'];
    if (rawQuests is Map) {
      rawQuests.forEach((key, val) {
        if (val is Map) {
          questsMap[key.toString()] = {
            'progress': (val['progress'] as num? ?? 0).toInt(),
            'claimed': val['claimed'] == true,
          };
        }
      });
    }

    return UserProfile(
      name: map['name']?.toString() ?? 'Utilisateur',
      searchName: map['searchName']?.toString() ?? 'utilisateur',
      level: (map['level'] as num? ?? 1).toInt(),
      xp: (map['xp'] as num? ?? 0).toInt(),
      coins: (map['coins'] as num? ?? 0).toInt(),
      diamonds: (map['diamonds'] as num? ?? 0).toInt(),
      emoji: map['emoji'] ?? '😎',
      activeCardBack: map['activeCardBack'] ?? 'classic',
      activeTitle: map['activeTitle'] ?? 'Novice 🐣',
      lastDailyChestClaimed:
          (map['lastDailyChestClaimed'] as num? ?? 0).toInt(),
      drinksGiven: (map['drinksGiven'] as num? ?? 0).toInt(),
      bluffWins: (map['bluffWins'] as num? ?? 0).toInt(),
      streak: (map['streak'] as num? ?? 0).toInt(),
      gamesPlayed: (map['gamesPlayed'] as num? ?? 0).toInt(),
      lastClaimedLevel: (map['lastClaimedLevel'] as num? ?? 0).toInt(),
      jokers: jokersMap,
      cardBacks: cardBacksList,
      titles: titlesList,
      bordersOwned: bordersList,
      selectedBorder: map['selectedBorder'] ?? 'classic',
      themesOwned: themesList,
      selectedTheme: map['selectedTheme'] ?? 'classic',
      quests: questsMap,
      isVip: isVip,
      vipExpireDate: vipExpireDate,
      // Le pass est actif si VIP (inclus) ou acheté séparément
      battlePassActive: isVip || map['battlePassActive'] == true,
    );
  }

  static Future<void> addGameRewards(
      String uid, int addedXp, int addedDrinks, int addedBluffs,
      {int addedCoins = 0}) async {
    final dbRef = FirebaseDatabase.instance.ref('users/$uid');
    final snapshot = await dbRef.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final bool isVip = data['isVip'] == true;

      // VIP bonus: +50% XP and coins
      int effectiveXp = addedXp;
      int effectiveCoins = addedCoins;
      if (isVip) {
        effectiveXp = (addedXp * 1.5).round();
        effectiveCoins = (addedCoins * 1.5).round();
      }

      int currentXp = (data['xp'] as num? ?? 0).toInt();
      int currentLevel = (data['level'] as num? ?? 1).toInt();
      int currentDrinks = (data['drinksGiven'] as num? ?? 0).toInt();
      int currentBluffs = (data['bluffWins'] as num? ?? 0).toInt();
      int currentGamesPlayed = (data['gamesPlayed'] as num? ?? 0).toInt();
      int currentCoins = (data['coins'] as num? ?? 0).toInt();

      currentXp += effectiveXp;

      // Level up logic
      while (currentXp >= currentLevel * 100) {
        currentXp -= currentLevel * 100;
        currentLevel++;
      }

      await dbRef.update({
        'xp': currentXp,
        'level': currentLevel,
        'drinksGiven': currentDrinks + addedDrinks,
        'bluffWins': currentBluffs + addedBluffs,
        'gamesPlayed': currentGamesPlayed + 1,
        'coins': currentCoins + effectiveCoins,
      });
    }
  }

  // Récompenses par tier (index 0 = tier 1, index 14 = tier 15)
  static const List<Map<String, dynamic>> _tierRewards = [
    {'type': 'coins', 'amount': 50},                          // Tier 1
    {'type': 'title', 'value': 'Débutant 🏷️'},              // Tier 2
    {'type': 'coins', 'amount': 100},                         // Tier 3
    {'type': 'joker', 'key': 'bouclier'},                    // Tier 4
    {'type': 'coins', 'amount': 200},                         // Tier 5
    {'type': 'cardBack', 'value': 'neon'},                   // Tier 6
    {'type': 'coins', 'amount': 500},                         // Tier 7
    {'type': 'title', 'value': 'Vétéran ⭐'},                // Tier 8
    {'type': 'border', 'value': 'flamme'},                   // Tier 9
    {'type': 'coins', 'amount': 1000},                        // Tier 10
    {'type': 'cardBack', 'value': 'galaxy'},                 // Tier 11
    {'type': 'title', 'value': 'Champion 🏆'},               // Tier 12
    {'type': 'coins', 'amount': 500},                         // Tier 13
    {'type': 'coins', 'amount': 2000},                        // Tier 14
    {'type': 'border', 'value': 'diamant'},                  // Tier 15
  ];

  /// Réclame la récompense du prochain tier non réclamé.
  /// tierIndex : 0-based index du tier à réclamer (0 = tier 1).
  /// Si null, réclame le prochain tier disponible automatiquement.
  static Future<Map<String, dynamic>?> claimLevelReward(String uid, {int? tierIndex}) async {
    final dbRef = FirebaseDatabase.instance.ref('users/$uid');
    final snapshot = await dbRef.get();
    if (!snapshot.exists || snapshot.value is! Map) return null;

    final data = snapshot.value as Map<dynamic, dynamic>;
    final int currentLevel = (data['level'] as num? ?? 1).toInt();
    final int lastClaimed = (data['lastClaimedLevel'] as num? ?? 0).toInt();

    // Détermine quel tier réclamer
    final int claimIndex = tierIndex ?? lastClaimed; // 0-based
    // Niveau N débloque les tiers 0..N-1 (tier index = level - 1 max)
    // claimIndex 0 → se débloque au level 1, claimIndex 1 → level 2, etc.
    if (currentLevel < claimIndex + 1) return null;       // pas encore débloqué
    if (lastClaimed > claimIndex) return null;             // déjà réclamé
    if (claimIndex >= _tierRewards.length) return null;   // hors limites
    // Sécurité : ne jamais écrire lastClaimedLevel > currentLevel
    final newLastClaimed = (claimIndex + 1).clamp(0, currentLevel);

    final reward = _tierRewards[claimIndex];
    final updates = <String, dynamic>{
      'lastClaimedLevel': newLastClaimed,
    };

    // Applique la récompense
    switch (reward['type']) {
      case 'coins':
        final int current = (data['coins'] as num? ?? 0).toInt();
        updates['coins'] = current + (reward['amount'] as int);
        break;
      case 'title':
        final titles = _parseList(data['titles']) ?? ['Novice 🐣'];
        final v = reward['value'] as String;
        if (!titles.contains(v)) titles.add(v);
        updates['titles'] = titles;
        break;
      case 'joker':
        final rawJokers = data['jokers'];
        final Map<String, dynamic> jokers = rawJokers is Map
            ? Map<String, dynamic>.from(rawJokers)
            : {};
        final key = reward['key'] as String;
        jokers[key] = ((jokers[key] as num? ?? 0).toInt()) + 1;
        updates['jokers'] = jokers;
        break;
      case 'cardBack':
        final backs = _parseList(data['cardBacks']) ?? ['classic'];
        final v = reward['value'] as String;
        if (!backs.contains(v)) backs.add(v);
        updates['cardBacks'] = backs;
        break;
      case 'border':
        final borders = _parseList(data['bordersOwned']) ?? ['classic'];
        final v = reward['value'] as String;
        if (!borders.contains(v)) borders.add(v);
        updates['bordersOwned'] = borders;
        break;
    }

    await dbRef.update(updates);
    return reward;
  }

  static List<String>? _parseList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is Map) return raw.values.map((e) => e.toString()).toList();
    return null;
  }
}

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseDatabase.instance.ref('users/${user.uid}').onValue.map((event) {
    final data = event.snapshot.value;
    if (data == null) return null;
    return UserProfile.fromMap(data as Map<dynamic, dynamic>);
  });
});

final publicProfileProvider = FutureProvider.family<UserProfile?, String>((ref, uid) async {
  final snapshot = await FirebaseDatabase.instance.ref('users/$uid').get();
  if (snapshot.exists && snapshot.value != null) {
    return UserProfile.fromMap(snapshot.value as Map<dynamic, dynamic>);
  }
  return null;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../auth/auth_service.dart';

class UserProfile {
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

  UserProfile({
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
  });

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
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
      cardBacksList.addAll((map['cardBacks'] as Map).values.map((e) => e.toString()));
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
      bordersList.addAll((map['bordersOwned'] as List).map((e) => e.toString()));
    } else if (map['bordersOwned'] is Map) {
      bordersList.addAll((map['bordersOwned'] as Map).values.map((e) => e.toString()));
    }
    if (bordersList.isEmpty) {
      bordersList.add('classic'); // classic border (none)
    }

    // Parse list of themes safely
    final List<String> themesList = [];
    if (map['themesOwned'] is List) {
      themesList.addAll((map['themesOwned'] as List).map((e) => e.toString()));
    } else if (map['themesOwned'] is Map) {
      themesList.addAll((map['themesOwned'] as Map).values.map((e) => e.toString()));
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
      level: (map['level'] as num? ?? 1).toInt(),
      xp: (map['xp'] as num? ?? 0).toInt(),
      coins: (map['coins'] as num? ?? 0).toInt(),
      diamonds: (map['diamonds'] as num? ?? 0).toInt(),
      emoji: map['emoji'] ?? '😎',
      activeCardBack: map['activeCardBack'] ?? 'classic',
      activeTitle: map['activeTitle'] ?? 'Novice 🐣',
      lastDailyChestClaimed: (map['lastDailyChestClaimed'] as num? ?? 0).toInt(),
      drinksGiven: (map['drinksGiven'] as num? ?? 0).toInt(),
      bluffWins: (map['bluffWins'] as num? ?? 0).toInt(),
      streak: (map['streak'] as num? ?? 0).toInt(),
      gamesPlayed: (map['gamesPlayed'] as num? ?? 0).toInt(),
      lastClaimedLevel: (map['lastClaimedLevel'] as num? ?? 1).toInt(),
      jokers: jokersMap,
      cardBacks: cardBacksList,
      titles: titlesList,
      bordersOwned: bordersList,
      selectedBorder: map['selectedBorder'] ?? 'classic',
      themesOwned: themesList,
      selectedTheme: map['selectedTheme'] ?? 'classic',
      quests: questsMap,
    );
  }

  static Future<void> addGameRewards(String uid, int addedXp, int addedDrinks, int addedBluffs) async {
    final dbRef = FirebaseDatabase.instance.ref('users/$uid');
    final snapshot = await dbRef.get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      int currentXp = (data['xp'] as num? ?? 0).toInt();
      int currentLevel = (data['level'] as num? ?? 1).toInt();
      int currentDrinks = (data['drinksGiven'] as num? ?? 0).toInt();
      int currentBluffs = (data['bluffWins'] as num? ?? 0).toInt();
      int currentGamesPlayed = (data['gamesPlayed'] as num? ?? 0).toInt();

      currentXp += addedXp;
      
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
      });
    }
  }

  static Future<void> claimLevelReward(String uid) async {
    final dbRef = FirebaseDatabase.instance.ref('users/$uid');
    final snapshot = await dbRef.get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final int currentLevel = (data['level'] as num? ?? 1).toInt();
      final int currentCoins = (data['coins'] as num? ?? 0).toInt();
      final int currentDiamonds = (data['diamonds'] as num? ?? 0).toInt();
      final int lastClaimed = (data['lastClaimedLevel'] as num? ?? 1).toInt();

      if (currentLevel > lastClaimed) {
        final nextClaimable = lastClaimed + 1;
        await dbRef.update({
          'coins': currentCoins + 200,
          'diamonds': currentDiamonds + 10,
          'lastClaimedLevel': nextClaimable,
        });
      }
    }
  }
}

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value(null);
  }

  final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
  return dbRef.onValue.map((event) {
    final value = event.snapshot.value;
    if (value != null && value is Map<dynamic, dynamic>) {
      return UserProfile.fromMap(value);
    }
    return null;
  });
});

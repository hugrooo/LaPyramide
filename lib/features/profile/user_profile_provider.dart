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
  final Map<String, int> jokers;
  final List<String> cardBacks;
  final List<String> titles;

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
    required this.jokers,
    required this.cardBacks,
    required this.titles,
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

    return UserProfile(
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      coins: map['coins'] ?? 0,
      diamonds: map['diamonds'] ?? 0,
      emoji: map['emoji'] ?? '😎',
      activeCardBack: map['activeCardBack'] ?? 'classic',
      activeTitle: map['activeTitle'] ?? 'Novice 🐣',
      lastDailyChestClaimed: map['lastDailyChestClaimed'] ?? 0,
      drinksGiven: map['drinksGiven'] ?? 0,
      bluffWins: map['bluffWins'] ?? 0,
      jokers: jokersMap,
      cardBacks: cardBacksList,
      titles: titlesList,
    );
  }

  static Future<void> addGameRewards(String uid, int addedXp, int addedDrinks, int addedBluffs) async {
    final dbRef = FirebaseDatabase.instance.ref('users/$uid');
    final snapshot = await dbRef.get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      int currentXp = (data['xp'] ?? 0) as int;
      int currentLevel = (data['level'] ?? 1) as int;
      int currentDrinks = (data['drinksGiven'] ?? 0) as int;
      int currentBluffs = (data['bluffWins'] ?? 0) as int;

      currentXp += addedXp;
      
      // Level up logic
      while (currentXp >= currentLevel * 100) {
        currentXp -= currentLevel * 100;
        currentLevel++;
        // On pourrait distribuer des pièces/diamants ici pour le passage de niveau
      }

      await dbRef.update({
        'xp': currentXp,
        'level': currentLevel,
        'drinksGiven': currentDrinks + addedDrinks,
        'bluffWins': currentBluffs + addedBluffs,
      });
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

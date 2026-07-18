import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameHistoryEntry {
  final String id;
  final String mode;
  final String penaltyMode;
  final List<String> players;
  final String result;
  final int penalties;
  final int bluffsSucceeded;
  final int bluffsCaught;
  final DateTime date;

  GameHistoryEntry({
    required this.id,
    required this.mode,
    required this.penaltyMode,
    required this.players,
    required this.result,
    required this.penalties,
    required this.bluffsSucceeded,
    required this.bluffsCaught,
    required this.date,
  });

  factory GameHistoryEntry.fromJson(String id, Map<String, dynamic> json) =>
      GameHistoryEntry(
        id: id,
        mode: json['mode'] ?? 'classic',
        penaltyMode: json['penaltyMode'] ?? 'sips',
        players: List<String>.from(json['players'] ?? []),
        result: json['result'] ?? 'loss',
        penalties: json['penalties'] ?? 0,
        bluffsSucceeded: json['bluffsSucceeded'] ?? 0,
        bluffsCaught: json['bluffsCaught'] ?? 0,
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'penaltyMode': penaltyMode,
        'players': players,
        'result': result,
        'penalties': penalties,
        'bluffsSucceeded': bluffsSucceeded,
        'bluffsCaught': bluffsCaught,
        'date': date.millisecondsSinceEpoch,
      };
}

class PlayerStats {
  final int totalGames;
  final int wins;
  final int losses;
  final int totalPenalties;
  final int totalBluffsSucceeded;
  final int totalBluffsCaught;
  final String favoriteMode;
  final int currentStreak;
  final Map<String, int> penaltiesByMode;

  PlayerStats({
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.totalPenalties,
    required this.totalBluffsSucceeded,
    required this.totalBluffsCaught,
    required this.favoriteMode,
    required this.currentStreak,
    required this.penaltiesByMode,
  });

  double get winRate => totalGames > 0 ? wins / totalGames : 0;
  double get bluffSuccessRate =>
      (totalBluffsSucceeded + totalBluffsCaught) > 0
          ? totalBluffsSucceeded / (totalBluffsSucceeded + totalBluffsCaught)
          : 0;

  factory PlayerStats.empty() => PlayerStats(
        totalGames: 0,
        wins: 0,
        losses: 0,
        totalPenalties: 0,
        totalBluffsSucceeded: 0,
        totalBluffsCaught: 0,
        favoriteMode: 'classic',
        currentStreak: 0,
        penaltiesByMode: {},
      );

  factory PlayerStats.fromEntries(List<GameHistoryEntry> entries) {
    if (entries.isEmpty) return PlayerStats.empty();

    int wins = 0;
    int losses = 0;
    int totalPenalties = 0;
    int totalBluffsSucceeded = 0;
    int totalBluffsCaught = 0;
    final Map<String, int> modeCount = {};
    final Map<String, int> penaltiesByMode = {};

    for (final entry in entries) {
      if (entry.result == 'win') {
        wins++;
      } else {
        losses++;
      }
      totalPenalties += entry.penalties;
      totalBluffsSucceeded += entry.bluffsSucceeded;
      totalBluffsCaught += entry.bluffsCaught;
      modeCount[entry.mode] = (modeCount[entry.mode] ?? 0) + 1;
      penaltiesByMode[entry.mode] =
          (penaltiesByMode[entry.mode] ?? 0) + entry.penalties;
    }

    // Find favorite mode
    String favoriteMode = 'classic';
    int maxCount = 0;
    for (final entry in modeCount.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        favoriteMode = entry.key;
      }
    }

    // Calculate streak (consecutive days played)
    final sortedDates = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    if (sortedDates.isNotEmpty) {
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final daysDiff = today.difference(sortedDates.first).inDays;
      if (daysDiff <= 1) {
        streak = 1;
        for (int i = 1; i < sortedDates.length; i++) {
          final diff = sortedDates[i - 1].difference(sortedDates[i]).inDays;
          if (diff == 1) {
            streak++;
          } else {
            break;
          }
        }
      }
    }

    return PlayerStats(
      totalGames: entries.length,
      wins: wins,
      losses: losses,
      totalPenalties: totalPenalties,
      totalBluffsSucceeded: totalBluffsSucceeded,
      totalBluffsCaught: totalBluffsCaught,
      favoriteMode: favoriteMode,
      currentStreak: streak,
      penaltiesByMode: penaltiesByMode,
    );
  }
}

class StatsService {
  final _db = FirebaseDatabase.instance;

  Future<void> recordGame({
    required String userId,
    required String mode,
    required String penaltyMode,
    required List<String> players,
    required String result,
    required int penalties,
    required int bluffsSucceeded,
    required int bluffsCaught,
  }) async {
    await _db.ref('users/$userId/game_history').push().set({
      'mode': mode,
      'penaltyMode': penaltyMode,
      'players': players,
      'result': result,
      'penalties': penalties,
      'bluffsSucceeded': bluffsSucceeded,
      'bluffsCaught': bluffsCaught,
      'date': ServerValue.timestamp,
    });
  }
}

final statsServiceProvider = Provider((ref) => StatsService());

final gameHistoryProvider =
    StreamProvider.family<List<GameHistoryEntry>, String>((ref, userId) {
  final db = FirebaseDatabase.instance.ref('users/$userId/game_history');
  return db.orderByChild('date').limitToLast(50).onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
    return data.entries
        .map((e) => GameHistoryEntry.fromJson(
            e.key, Map<String, dynamic>.from(e.value)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  });
});

final playerStatsProvider =
    Provider.family<PlayerStats, List<GameHistoryEntry>>((ref, entries) {
  return PlayerStats.fromEntries(entries);
});

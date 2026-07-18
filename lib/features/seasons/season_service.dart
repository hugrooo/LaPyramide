import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Season { summer, halloween, christmas, newYear, spring }

class SeasonData {
  final Season season;
  final String name;
  final String emoji;
  final DateTime startDate;
  final DateTime endDate;

  const SeasonData({
    required this.season,
    required this.name,
    required this.emoji,
    required this.startDate,
    required this.endDate,
  });

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}

final currentSeasonProvider = Provider<SeasonData>((ref) {
  final now = DateTime.now();
  final month = now.month;

  if (month >= 6 && month <= 8) {
    return SeasonData(
      season: Season.summer,
      name: 'Été Tropical',
      emoji: '☀️',
      startDate: DateTime(now.year, 6, 1),
      endDate: DateTime(now.year, 8, 31),
    );
  } else if (month == 10) {
    return SeasonData(
      season: Season.halloween,
      name: 'Halloween',
      emoji: '🎃',
      startDate: DateTime(now.year, 10, 1),
      endDate: DateTime(now.year, 10, 31),
    );
  } else if (month == 12) {
    return SeasonData(
      season: Season.christmas,
      name: 'Noël Festif',
      emoji: '🎄',
      startDate: DateTime(now.year, 12, 1),
      endDate: DateTime(now.year, 12, 31),
    );
  } else if (month >= 3 && month <= 5) {
    return SeasonData(
      season: Season.spring,
      name: 'Printemps Frais',
      emoji: '🌸',
      startDate: DateTime(now.year, 3, 1),
      endDate: DateTime(now.year, 5, 31),
    );
  }

  return SeasonData(
    season: Season.summer,
    name: 'Saison Standard',
    emoji: '🎯',
    startDate: DateTime(now.year, 1, 1),
    endDate: DateTime(now.year, 12, 31),
  );
});

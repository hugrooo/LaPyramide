import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomDeck {
  final String id;
  final String name;
  final String emoji;
  final String creatorId;
  final String creatorName;
  final List<String> truths;
  final List<String> dares;
  final List<String> challenges;
  final int downloads;
  final double rating;
  final DateTime createdAt;

  CustomDeck({
    required this.id,
    required this.name,
    required this.emoji,
    required this.creatorId,
    required this.creatorName,
    required this.truths,
    required this.dares,
    required this.challenges,
    this.downloads = 0,
    this.rating = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'emoji': emoji,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'truths': truths,
        'dares': dares,
        'challenges': challenges,
        'downloads': downloads,
        'rating': rating,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory CustomDeck.fromJson(String id, Map<String, dynamic> json) =>
      CustomDeck(
        id: id,
        name: json['name'] ?? '',
        emoji: json['emoji'] ?? '',
        creatorId: json['creatorId'] ?? '',
        creatorName: json['creatorName'] ?? 'Anonyme',
        truths: List<String>.from(json['truths'] ?? []),
        dares: List<String>.from(json['dares'] ?? []),
        challenges: List<String>.from(json['challenges'] ?? []),
        downloads: json['downloads'] ?? 0,
        rating: (json['rating'] ?? 0).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      );
}

final communityDecksProvider = StreamProvider<List<CustomDeck>>((ref) {
  final db = FirebaseDatabase.instance.ref('community_decks');
  return db.orderByChild('downloads').limitToLast(20).onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
    return data.entries
        .map((e) =>
            CustomDeck.fromJson(e.key, Map<String, dynamic>.from(e.value)))
        .toList()
      ..sort((a, b) => b.downloads.compareTo(a.downloads));
  });
});

final myDecksProvider =
    StreamProvider.family<List<CustomDeck>, String>((ref, userId) {
  final db = FirebaseDatabase.instance.ref('community_decks');
  return db.orderByChild('creatorId').equalTo(userId).onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
    return data.entries
        .map((e) =>
            CustomDeck.fromJson(e.key, Map<String, dynamic>.from(e.value)))
        .toList();
  });
});

class CustomDeckService {
  final _db = FirebaseDatabase.instance.ref('community_decks');

  Future<void> createDeck(CustomDeck deck) async {
    await _db.push().set(deck.toJson());
  }

  Future<void> downloadDeck(String deckId) async {
    await _db.child(deckId).child('downloads').set(ServerValue.increment(1));
  }

  Future<void> rateDeck(String deckId, String userId, double rating) async {
    await FirebaseDatabase.instance
        .ref('deck_ratings/$deckId/$userId')
        .set(rating);
    // Recalculate average
    final snapshot = await FirebaseDatabase.instance
        .ref('deck_ratings/$deckId')
        .get();
    if (snapshot.exists) {
      final ratings = Map<String, dynamic>.from(snapshot.value as Map);
      final avg = ratings.values
              .fold<double>(0, (sum, v) => sum + (v as num).toDouble()) /
          ratings.length;
      await _db.child(deckId).child('rating').set(avg);
    }
  }

  Future<void> deleteDeck(String deckId) async {
    await _db.child(deckId).remove();
  }
}

final customDeckServiceProvider = Provider((ref) => CustomDeckService());

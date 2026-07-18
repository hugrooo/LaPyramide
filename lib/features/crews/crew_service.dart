import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CrewData {
  final String id;
  final String name;
  final String emoji;
  final String createdBy;
  final int memberCount;
  final int gamesPlayed;

  CrewData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdBy,
    required this.memberCount,
    this.gamesPlayed = 0,
  });

  factory CrewData.fromJson(String id, Map<dynamic, dynamic> json) {
    final members = json['members'] as Map<dynamic, dynamic>? ?? {};
    return CrewData(
      id: id,
      name: json['name'] ?? 'Crew',
      emoji: json['emoji'] ?? '🔥',
      createdBy: json['createdBy'] ?? '',
      memberCount: members.length,
      gamesPlayed: json['stats']?['gamesPlayed'] ?? 0,
    );
  }
}

final crewsProvider = StreamProvider.family<List<CrewData>, String>((ref, uid) {
  final db = FirebaseDatabase.instance.ref('crews');
  return db.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
    return data.entries
        .where((e) {
          final members =
              (e.value as Map<dynamic, dynamic>)['members'] as Map? ?? {};
          return members.containsKey(uid);
        })
        .map((e) => CrewData.fromJson(
            e.key as String, e.value as Map<dynamic, dynamic>))
        .toList();
  });
});

class CrewService {
  final _db = FirebaseDatabase.instance.ref('crews');

  Future<String> createCrew({
    required String name,
    required String emoji,
    required String creatorId,
  }) async {
    final ref = _db.push();
    await ref.set({
      'name': name,
      'emoji': emoji,
      'createdBy': creatorId,
      'createdAt': ServerValue.timestamp,
      'members': {creatorId: true},
      'stats': {'gamesPlayed': 0, 'totalPenalties': 0},
    });
    return ref.key!;
  }

  Future<void> joinCrew(String crewId, String uid) async {
    await _db.child(crewId).child('members').child(uid).set(true);
  }

  Future<void> leaveCrew(String crewId, String uid) async {
    await _db.child(crewId).child('members').child(uid).remove();
  }
}

final crewServiceProvider = Provider((ref) => CrewService());

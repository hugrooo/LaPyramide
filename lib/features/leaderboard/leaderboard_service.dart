import 'package:firebase_database/firebase_database.dart';

class LeaderboardService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> savePlayerStats(String userId, String name, int sips, int bluffsWon) async {
    final ref = _db.ref('leaderboard/$userId');
    final snapshot = await ref.get();
    
    int totalSips = sips;
    int totalBluffs = bluffsWon;
    
    if (snapshot.exists) {
      try {
        final data = snapshot.value as Map<dynamic, dynamic>;
        totalSips += (data['totalSips'] as int?) ?? 0;
        totalBluffs += (data['totalBluffs'] as int?) ?? 0;
      } catch (e) {
        // Ignorer si le format est invalide
      }
    }

    await ref.set({
      'name': name,
      'totalSips': totalSips,
      'totalBluffs': totalBluffs,
      'lastUpdated': ServerValue.timestamp,
    });
  }

  Stream<DatabaseEvent> getLeaderboard() {
    // Note: Firebase realtime db orderByChild('totalSips') triera par ordre croissant.
    return _db.ref('leaderboard').orderByChild('totalSips').limitToLast(50).onValue;
  }
}

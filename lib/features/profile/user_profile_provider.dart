import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../auth/auth_service.dart';

class UserProfile {
  final int level;
  final int xp;
  final int coins;
  final int diamonds;

  UserProfile({
    required this.level,
    required this.xp,
    required this.coins,
    required this.diamonds,
  });

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      coins: map['coins'] ?? 0,
      diamonds: map['diamonds'] ?? 0,
    );
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

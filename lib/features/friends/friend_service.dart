import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';

final friendServiceProvider = Provider<FriendService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return FriendService(FirebaseDatabase.instance, auth);
});

class FriendProfile {
  final String id;
  final String name;
  final String? emoji;
  final String? photoUrl;
  final String selectedBorder;

  FriendProfile({
    required this.id,
    required this.name,
    this.emoji,
    this.photoUrl,
    this.selectedBorder = 'classic',
  });

  factory FriendProfile.fromJson(String id, Map<dynamic, dynamic> json) {
    return FriendProfile(
      id: id,
      name: json['name'] ?? 'Inconnu',
      emoji: json['emoji'],
      photoUrl: json['photoUrl'],
      selectedBorder: json['selectedBorder'] ?? 'classic',
    );
  }
}

class FriendService {
  final FirebaseDatabase _db;
  final AuthService _auth;

  FriendService(this._db, this._auth);

  /// Mettre à jour le profil public de l'utilisateur
  Future<void> saveUserProfile(String name, String emoji) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.ref('users/${user.uid}').update({
      'name': name,
      'emoji': emoji,
      'searchName': name.toLowerCase(),
    });
  }

  /// Rechercher des utilisateurs par nom (rudimentaire avec Realtime Database)
  Future<List<FriendProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final user = _auth.currentUser;
    final q = query.toLowerCase();

    final snapshot = await _db
        .ref('users')
        .orderByChild('searchName')
        .startAt(q)
        .endAt('$q\uf8ff')
        .limitToFirst(20)
        .get();

    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final List<FriendProfile> results = [];

    data.forEach((key, value) {
      if (user != null && key == user.uid) return; // Ignorer soi-même
      results.add(FriendProfile.fromJson(key, value as Map<dynamic, dynamic>));
    });

    return results;
  }

  /// Envoyer une demande d'ami
  Future<void> sendFriendRequest(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Enregistrer chez la cible
    await _db.ref('friend_requests/$targetUid/${user.uid}').set({
      'timestamp': ServerValue.timestamp,
      'status': 'pending',
    });
    // Enregistrer localement pour savoir qu'on a envoyé
    await _db.ref('sent_requests/${user.uid}/$targetUid').set({
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Accepter une demande d'ami
  Future<void> acceptFriendRequest(String fromUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Ajouter dans les deux listes d'amis
    await _db.ref('friends/${user.uid}/$fromUid').set(true);
    await _db.ref('friends/$fromUid/${user.uid}').set(true);

    // Supprimer la requête
    await _db.ref('friend_requests/${user.uid}/$fromUid').remove();
    await _db.ref('sent_requests/$fromUid/${user.uid}').remove();
  }

  /// Refuser une demande
  Future<void> declineFriendRequest(String fromUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.ref('friend_requests/${user.uid}/$fromUid').remove();
    await _db.ref('sent_requests/$fromUid/${user.uid}').remove();
  }

  /// Récupérer les amis
  Stream<List<FriendProfile>> getFriends() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db.ref('friends/${user.uid}').onValue.asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];

      final Map<dynamic, dynamic> friendsMap =
          event.snapshot.value as Map<dynamic, dynamic>;
      final friendIds = friendsMap.keys.cast<String>().toList();

      final List<FriendProfile> friendsList = [];
      for (final fid in friendIds) {
        final profileSnap = await _db.ref('users/$fid').get();
        if (profileSnap.exists && profileSnap.value != null) {
          friendsList.add(FriendProfile.fromJson(
              fid, profileSnap.value as Map<dynamic, dynamic>));
        }
      }
      return friendsList;
    });
  }

  /// Récupérer les requêtes reçues
  Stream<List<FriendProfile>> getPendingRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .ref('friend_requests/${user.uid}')
        .onValue
        .asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];

      final Map<dynamic, dynamic> reqMap =
          event.snapshot.value as Map<dynamic, dynamic>;
      final reqIds = reqMap.keys.cast<String>().toList();

      final List<FriendProfile> reqList = [];
      for (final rid in reqIds) {
        final profileSnap = await _db.ref('users/$rid').get();
        if (profileSnap.exists && profileSnap.value != null) {
          reqList.add(FriendProfile.fromJson(
              rid, profileSnap.value as Map<dynamic, dynamic>));
        }
      }
      return reqList;
    });
  }

  /// Envoyer une invitation de jeu
  Future<void> inviteToGame(
      String friendUid, String roomCode, String hostName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // On écrit dans /users/{friendUid}/invites avec un ID unique
    final inviteRef = _db.ref('users/$friendUid/invites').push();
    await inviteRef.set({
      'inviterId': user.uid,
      'inviterName': hostName,
      'roomCode': roomCode,
      'timestamp': ServerValue.timestamp,
    });
  }
}

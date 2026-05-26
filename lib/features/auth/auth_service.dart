import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Utile pour iOS natif

import 'package:firebase_database/firebase_database.dart';

/// Fournisseur global pour l'instance de FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Fournisseur du flux d'état d'authentification (connecté / déconnecté)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Fournisseur du service d'authentification
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  AuthService(this._auth);

  /// Inscription avec Email et Mot de passe
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String pseudo,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (cred.user != null) {
      await cred.user!.updateDisplayName(pseudo);
      await cred.user!.reload();
      
      await _db.ref('users/${cred.user!.uid}').update({
        'name': pseudo,
        'searchName': pseudo.toLowerCase(),
        'lastLogin': ServerValue.timestamp,
        'level': 1,
        'xp': 0,
        'coins': 0,
        'diamonds': 0,
      });
    }
    return cred;
  }

  /// Connexion avec Email et Mot de passe
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (cred.user != null) {
      await _db.ref('users/${cred.user!.uid}').update({
        'lastLogin': ServerValue.timestamp,
      });
    }
    return cred;
  }

  /// Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // Sur le Web, utiliser la popup Firebase (beaucoup plus simple, gère automatiquement les clés)
      final googleProvider = GoogleAuthProvider();
      return await _auth.signInWithPopup(googleProvider);
    } else {
      // Sur Mobile, utiliser le flux natif
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // L'utilisateur a annulé

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        // Initialize fields if they don't exist (using a transaction or just update for now)
        // Note: update will overwrite if we send hardcoded 0, but if we just want lastLogin:
        await _db.ref('users/${cred.user!.uid}').update({
          'name': cred.user!.displayName ?? 'Utilisateur',
          'searchName': (cred.user!.displayName ?? 'Utilisateur').toLowerCase(),
          'lastLogin': ServerValue.timestamp,
        });
        
        // Ensure default economy values exist
        final snapshot = await _db.ref('users/${cred.user!.uid}/level').get();
        if (!snapshot.exists) {
          await _db.ref('users/${cred.user!.uid}').update({
            'level': 1,
            'xp': 0,
            'coins': 0,
            'diamonds': 0,
          });
        }
      }
      return cred;
    }
  }

  /// Connexion avec Apple (Simplifiée pour l'instant)
  Future<UserCredential?> signInWithApple() async {
    // Note: L'implémentation complète nécessite de configurer les identifiants Apple dans Firebase
    // Pour l'instant, on utilise le provider Firebase natif si supporté (Web/iOS 13+)
    final appleProvider = AppleAuthProvider();
    // appleProvider.addScope('email');
    // appleProvider.addScope('name');
    final cred = await _auth.signInWithProvider(appleProvider);
    
    if (cred.user != null) {
      await _db.ref('users/${cred.user!.uid}').update({
        'lastLogin': ServerValue.timestamp,
      });
      
      final snapshot = await _db.ref('users/${cred.user!.uid}/level').get();
      if (!snapshot.exists) {
        await _db.ref('users/${cred.user!.uid}').update({
          'name': cred.user!.displayName ?? 'Utilisateur',
          'searchName': (cred.user!.displayName ?? 'Utilisateur').toLowerCase(),
          'level': 1,
          'xp': 0,
          'coins': 0,
          'diamonds': 0,
        });
      }
    }
    return cred;
  }

  /// Déconnexion
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// Récupérer l'utilisateur courant
  User? get currentUser => _auth.currentUser;
}

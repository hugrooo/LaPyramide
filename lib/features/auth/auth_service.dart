import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Utile pour iOS natif

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

  AuthService(this._auth);

  /// Connexion Anonyme (Invité)
  Future<UserCredential> signInAnonymously({String? pseudo}) async {
    final cred = await _auth.signInAnonymously();
    if (pseudo != null && pseudo.isNotEmpty && cred.user != null) {
      await cred.user!.updateDisplayName(pseudo);
      await cred.user!.reload();
    }
    return cred;
  }

  /// Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
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

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Échec de la connexion Google: $e');
    }
  }

  /// Connexion avec Apple (Simplifiée pour l'instant)
  Future<UserCredential?> signInWithApple() async {
    // Note: L'implémentation complète nécessite de configurer les identifiants Apple dans Firebase
    // Pour l'instant, on utilise le provider Firebase natif si supporté (Web/iOS 13+)
    try {
      final appleProvider = AppleAuthProvider();
      // appleProvider.addScope('email');
      // appleProvider.addScope('name');
      return await _auth.signInWithProvider(appleProvider);
    } catch (e) {
      throw Exception('Échec de la connexion Apple: $e');
    }
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

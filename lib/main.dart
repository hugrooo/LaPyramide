import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/audio/audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app/router.dart';
import 'app/app.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

// Gestion des notifications en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // On ne fait rien de spécial ici car flutter_local_notifications gèrera l'affichage
  // mais la fonction doit exister pour que Firebase ne plante pas en arrière-plan.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style de la barre système
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await AudioManager().init();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final currentUser = FirebaseAuth.instance.currentUser;
  
  final initialRoute = !hasSeenOnboarding 
      ? '/onboarding' 
      : (currentUser == null ? '/auth' : '/home');

  runApp(
    ProviderScope(
      overrides: [
        initialRouteProvider.overrideWithValue(initialRoute),
      ],
      child: const PyraApp(),
    ),
  );
}

// Placeholder — sera généré par FlutterFire CLI après configuration Firebase
// Commande : flutterfire configure --project=<votre-projet-firebase>
// Ce fichier sera remplacé automatiquement par la commande ci-dessus

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ⚠️ REMPLACE CES VALEURS par celles de ta console Firebase

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtpyczBVkbTsGqbNuZyyFEGZ-b3dOFLvI',
    appId: '1:545021164365:android:fbf3f4d308ff5df7271504',
    messagingSenderId: '545021164365',
    projectId: 'la-pyramide-54588',
    databaseURL: 'https://la-pyramide-54588-default-rtdb.firebaseio.com',
    storageBucket: 'la-pyramide-54588.firebasestorage.app',
  );

  // Elles seront générées automatiquement avec : flutterfire configure

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCJEqGQ7BUn8p1fvBf7yp_-5epR89TX5S4',
    appId: '1:545021164365:ios:c6bc2670797aa9cf271504',
    messagingSenderId: '545021164365',
    projectId: 'la-pyramide-54588',
    databaseURL: 'https://la-pyramide-54588-default-rtdb.firebaseio.com',
    storageBucket: 'la-pyramide-54588.firebasestorage.app',
    iosClientId:
        '545021164365-9sa39eol5505p56d7p4a1vlphjobpcti.apps.googleusercontent.com',
    iosBundleId: 'com.lapyramide.laPyramide',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC8aI4RMydKHe0BEW5wNcgYpTmfrskF9Ws',
    appId: '1:545021164365:web:03588e2ea44bb42b271504',
    messagingSenderId: '545021164365',
    projectId: 'la-pyramide-54588',
    authDomain: 'la-pyramide-54588.firebaseapp.com',
    databaseURL: 'https://la-pyramide-54588-default-rtdb.firebaseio.com',
    storageBucket: 'la-pyramide-54588.firebasestorage.app',
    measurementId: 'G-GHTY9KMSRY',
  );
}

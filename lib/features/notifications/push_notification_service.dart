import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// Fournisseur global pour le service de notifications
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return; // Les notifications push web nécessitent une configuration VAPID
    _isInitialized = true;

    // Initialiser les fuseaux horaires
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (e) {
      debugPrint('Erreur timezone: $e');
    }

    // 1. Demander la permission (surtout pour iOS et Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Initialiser les notifications locales (pour afficher en mode Foreground)
      await _initLocalNotifications();

      // 3. Récupérer le token FCM et le sauvegarder
      String? token = await _fcm.getToken();
      if (token != null) {
        _saveTokenToDatabase(token);
      }

      // Écouter les changements de token
      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

      // 4. Configurer les écouteurs de messages
      
      // Message reçu quand l'app est au premier plan (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // Message ouvert depuis une notification (Background/Terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Optionnel: Gérer la navigation ici
      });
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false);

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Créer la chaîne de notification pour Android 8.0+
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'Notifications Importantes', // name
        description: 'Ce canal est utilisé pour les notifications importantes comme les récompenses.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null && !kIsWeb) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notifications Importantes',
            channelDescription: 'Ce canal est utilisé pour les notifications importantes comme les récompenses.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  void _saveTokenToDatabase(String token) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseDatabase.instance.ref('users/${user.uid}/fcmToken').set(token);
    }
  }

  // Permet de programmer une notification locale (Ex: Récompense dispo demain)
  Future<void> scheduleRewardNotification(String title, String body, Duration delay) async {
    if (kIsWeb) return;
    
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    await _localNotifications.zonedSchedule(
      1001, // ID unique pour la récompense
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications Importantes',
          channelDescription: 'Récompenses et événements du jeu',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  // Permet d'annuler une notification programmée
  Future<void> cancelRewardNotification() async {
    await _localNotifications.cancel(1001);
  }
}

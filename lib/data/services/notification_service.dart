// lib/data/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

@singleton
class NotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._messaging);

  Future<void> initialize() async {
    // Configuration iOS
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Configuration locale
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Token FCM
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Écoute des messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      payload: message.data['type'],
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Navigation selon le type
    final type = message.data['type'];
    switch (type) {
      case 'new_match':
        // TODO: Naviguer vers matches
        break;
      case 'new_message':
        // TODO: Naviguer vers conversation
        break;
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    // Gérer le tap sur notification
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'hivmeet_channel',
      'HIVMeet Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
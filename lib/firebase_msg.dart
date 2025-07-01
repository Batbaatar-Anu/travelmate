import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  // Singleton
  static final FirebaseMessagingService instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Init FCM service
Future<void> initFCM() async {
  await _requestPermission();
  await _initializeLocalNotifications();

  // final token = await _messaging.getToken();
  // debugPrint("🔐 FCM Token: $token");

  // ✅ Бүх хэрэглэгчийг 'all' topic-д бүртгүүлнэ
  await _messaging.subscribeToTopic('all');
  debugPrint("✅ Subscribed to topic: all");

  // ✅ Foreground болон notification click listener
  FirebaseMessaging.onMessage.listen(_handleForegroundNotification);
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
}


  /// Request permissions for iOS
  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initialize local notification plugin (foreground display)
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);
  }

  /// Show local notification when app is in foreground
  Future<void> _handleForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default',
        channelDescription: 'Default channel',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    }
  }

  /// Handle when user taps notification
  void _handleNotificationClick(RemoteMessage message) {
    debugPrint("📬 Notification clicked: ${message.data}");
    // TODO: navigate or handle click
  }

  /// Static method to handle background messages
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    debugPrint("📩 Background message: ${message.notification?.title}");
    // You can show a local notification here too (if needed)
  }
}

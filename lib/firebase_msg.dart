import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:travelmate/presentation/push_notification_settings/notificationStorage.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Callback function for received notification
  Function(String title, String body)? onNotificationReceived;

  // Initialize Firebase messaging service
  Future<void> initFCM() async {
    await _requestPermission();
    await _initializeLocalNotifications();

    // Subscribe to a topic (all users in this case)
    await _messaging.subscribeToTopic('all');

    // Handle message when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(notification);
        // Store the notification data
        NotificationStorage.save(
          notification.title ?? 'No title', 
          notification.body ?? 'No message',
        );
        // Call the onNotificationReceived callback
        if (onNotificationReceived != null) {
          onNotificationReceived!(notification.title ?? 'No title', notification.body ?? 'No message');
        }
      }
    });

    // Handle notification click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📬 Notification clicked: ${message.data}");
      // Perform any action when the user clicks the notification, like navigation
    });

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  // Request permission for notifications on iOS
  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings);
  }

  // Show local notification when a message is received
  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Default',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  // Firebase background message handler to store the notifications
  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    // Store the notification in the local storage
    NotificationStorage.save(
      message.notification?.title ?? 'No Title', 
      message.notification?.body ?? 'No Body',
    );
  }
}

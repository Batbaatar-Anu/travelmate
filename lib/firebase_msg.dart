import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:travelmate/presentation/push_notification_settings/notificationStorage.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final user = FirebaseAuth.instance.currentUser;
  // Callback function for received notification
  Function(String title, String body)? onNotificationReceived;

  // Initialize Firebase messaging service
  Future<void> initFCM() async {
    await _requestPermission();
    await _initializeLocalNotifications();

    // Subscribe to a topic (all users in this case)
    await _messaging.subscribeToTopic('all');

    // Handle message when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final user = FirebaseAuth.instance.currentUser;

      if (notification != null) {
        // Show local notification
        _showLocalNotification(notification);

        // 🔴 Store to local storage (optional)
        NotificationStorage.save(
          notification.title ?? 'No title',
          notification.body ?? 'No message',
        );

        // 🔵 🔥 Store to Firestore: user_profiles/{uid}/notifications
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('user_profiles')
              .doc(user.uid)
              .collection('notifications')
              .add({
            'title': notification.title ?? '',
            'message': notification.body ?? '',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }

        // Call custom callback
        if (onNotificationReceived != null) {
          onNotificationReceived!(notification.title ?? 'No title',
              notification.body ?? 'No message');
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

    // Store locally
    NotificationStorage.save(
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
    );

    // Get uid from custom data payload (NOT from FirebaseAuth)
    final userId = message.data['userId'];
    if (userId != null && message.notification != null) {
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': message.notification!.title ?? '',
        'message': message.notification!.body ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }
}

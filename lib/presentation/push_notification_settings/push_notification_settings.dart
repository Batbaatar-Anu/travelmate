import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/presentation/push_notification_settings/notificationStorage.dart';
import 'package:travelmate/firebase_msg.dart'; // 👈 FCM service import

class ReceivedNotification {
  final String title;
  final String body;
  final DateTime timestamp;

  ReceivedNotification({
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<ReceivedNotification> receivedNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // ✅ Listen to foreground notifications
 FirebaseMessagingService.instance.onNotificationReceived = (title, body) {
  if (!mounted) return;
  setState(() {
    receivedNotifications.insert(
      0,
      ReceivedNotification(
        title: title,
        body: body,
        timestamp: DateTime.now(),
      ),
    );
  });
};

  }

  // Load notifications from local storage
void _loadNotifications() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('user_profiles') // 🛠️ энэ мөрийг users → user_profiles болго
      .doc(user.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .get();

  final notifications = snapshot.docs.map((doc) {
    final data = doc.data();
    return ReceivedNotification(
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }).toList();

  setState(() {
    receivedNotifications = notifications;
  });
}


  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return "Just now";
    if (difference.inHours < 1) return "${difference.inMinutes}m ago";
    if (difference.inDays < 1) return "${difference.inHours}h ago";
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: receivedNotifications.isEmpty
            ? Center(
                child: Text(
                  'No notifications yet',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: receivedNotifications.length,
                itemBuilder: (context, index) {
                  final notif = receivedNotifications[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 1.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              AssetImage('assets/images/avatar.png'),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: notif.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontSize: 13.sp,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          "  • ${formatTime(notif.timestamp)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey,
                                        fontSize: 11.sp,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                notif.body,
                                style: TextStyle(fontSize: 11.5.sp),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.image, size: 24, color: Colors.grey.shade400)
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

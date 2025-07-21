import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'package:travelmate/config_loader.dart';
import 'package:travelmate/firebase_msg.dart';
import 'package:travelmate/firebase_options.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';

Future<void> saveDeviceToken(String uid) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(uid)
          .update({'fcm_token': token});
      debugPrint("✅ FCM token saved for user: $uid");
    }
  } catch (e) {
    debugPrint("❌ Error saving FCM token: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessagingService.instance.initFCM();
  await Config.load();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  User? currentUser = FirebaseAuth.instance.currentUser;

  try {
    if (currentUser != null) {
      await currentUser.reload();
      currentUser = FirebaseAuth.instance.currentUser;
    }
  } catch (e) {
    debugPrint('User reload failed: $e');
    currentUser = null;
  }

  String initialRoute;

  if (!hasSeenOnboarding) {
    initialRoute = AppRoutes.onboardingFlow;
  } else if (currentUser != null && currentUser.emailVerified) {
    await saveDeviceToken(currentUser.uid); // ✅ Save token
    initialRoute = AppRoutes.homeDashboard;
  } else {
    initialRoute = AppRoutes.userLogin;
  }

  // 🔁 Refresh token listener
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(uid)
          .update({'fcm_token': newToken});
      debugPrint("🔄 Token refreshed and updated for $uid");
    }
  });

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(errorDetails: details);
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'travelmate',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        routes: AppRoutes.routes,
        initialRoute: initialRoute,
      );
    });
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'package:travelmate/config_loader.dart';
import 'package:travelmate/firebase_msg.dart';
import 'package:travelmate/firebase_options.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';

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

  // ✅ Алдаанаас хамгаалж currentUser.reload хийх
  try {
    if (currentUser != null) {
      await currentUser.reload();
      currentUser = FirebaseAuth.instance.currentUser;
    }
  } catch (e) {
    debugPrint('User reload failed: $e');
    currentUser = null; // 👈 устгагдсан хэрэглэгч байж болно
  }

  String initialRoute;

  if (!hasSeenOnboarding) {
    initialRoute = AppRoutes.onboardingFlow;
  } else if (currentUser != null && currentUser.emailVerified) {
    initialRoute = AppRoutes.homeDashboard;
  } else {
    initialRoute = AppRoutes.userLogin;
  }

  // 🔧 UI алдаа catcher
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

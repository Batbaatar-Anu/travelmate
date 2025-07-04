import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🆕
import 'package:sizer/sizer.dart';

import 'package:travelmate/config_loader.dart';
import 'package:travelmate/firebase_msg.dart';
import 'package:travelmate/firebase_options.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'routes/app_routes.dart'; // Та routes файлаа ингэж импортолж байгаарай

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase инициализаци
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Firebase Cloud Messaging инициализаци
  await FirebaseMessagingService.instance.initFCM();

  // ✅ App config ачаалалт
  await Config.load();

  // ✅ Onboarding flag шалгах
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  // ✅ Алдаа гарсан үед UI дээр харуулах өөрчлөлт
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(errorDetails: details);
  };

  // ✅ Portrait горимд ажиллах
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(MyApp(initialRoute: hasSeenOnboarding
      ? AppRoutes.homeDashboard
      : AppRoutes.onboardingFlow));
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

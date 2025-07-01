import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sizer/sizer.dart';
import 'package:dio/dio.dart';
import 'package:travelmate/config_loader.dart';
import 'package:travelmate/firebase_msg.dart';
import 'package:travelmate/firebase_options.dart';
import 'package:travelmate/services/supabase_service.dart'; // ✅ Supabase service import

import 'core/app_export.dart';
import '../widgets/custom_error_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase initialize
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ FCM init — ЭНЭ ХЭСГИЙГ НЭМЭХ ХЭРЭГТЭЙ
  await FirebaseMessagingService.instance.initFCM();

  // ✅ Config load
  await Config.load();

  // ✅ Supabase client init
  try {
    await SupabaseService().client;
  } catch (e) {
    debugPrint('❌ Supabase initialization error: $e');
  }

  // ✅ Error UI override
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(errorDetails: details);
  };

  // ✅ Portrait lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        initialRoute: AppRoutes.initial,
      );
    });
  }
}

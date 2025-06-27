import 'package:flutter/material.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/user_login/user_login.dart';
import '../presentation/push_notification_settings/push_notification_settings.dart';
import '../presentation/user_registration/user_registration.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/home_detail/home_detail.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String onboardingFlow = '/onboarding-flow';
  static const String userLogin = '/user-login';
  static const String pushNotificationSettings = '/push-notification-settings';
  static const String userRegistration = '/user-registration';
  static const String homeDashboard = '/home-dashboard';
  static const String homeDetail = '/home-detail';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const OnboardingFlow(),
    onboardingFlow: (context) => const OnboardingFlow(),
    userLogin: (context) => const UserLogin(),
    pushNotificationSettings: (context) => const PushNotificationSettings(),
    userRegistration: (context) => const UserRegistration(),
    homeDashboard: (context) => const HomeDashboard(),
    homeDetail: (context) => const HomeDetail(),
    // TODO: Add your other routes here
  };
}

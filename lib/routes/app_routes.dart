import 'package:flutter/material.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/SearchResultScreen.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/TripDetailScreen.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/all_destinations.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/newtrip.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/user_login/user_login.dart';
import '../presentation/push_notification_settings/push_notification_settings.dart';
import '../presentation/user_registration/user_registration.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/home_detail/home_detail.dart';

class AppRoutes {
  static const String initial = '/';
  static const String onboardingFlow = '/onboarding-flow';
  static const String userLogin = '/user-login';
  static const String pushNotificationSettings = '/push-notification-settings';
  static const String userRegistration = '/user-registration';
  static const String homeDashboard = '/home-dashboard';
  static const String homeDetail = '/home-detail';
  static const String newTrip = '/new-trip';
  static const String allDestinations = '/all-destinations';
  static const String tripDetail = '/trip-detail';
  static const String searchResult = '/search-result'; 

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const OnboardingFlow(),
    onboardingFlow: (context) => const OnboardingFlow(),
    userLogin: (context) => const UserLogin(),
    pushNotificationSettings: (context) => const NotificationScreen(),
    userRegistration: (context) => const UserRegistration(),
    homeDashboard: (context) => const HomeDashboard(),
    homeDetail: (context) => const HomeDetail(),
    newTrip: (context) => const NewTripScreen(),
    allDestinations: (context) => const AllDestinationsScreen(),
    tripDetail: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('Trip мэдээлэл олдсонгүй.')),
        );
      }
      return TripDetailScreen(trip: args);
    },
    searchResult: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final query = args is String && args.trim().isNotEmpty ? args : null;

      return SearchResultScreen(query: query ?? '');
    },
  };
}

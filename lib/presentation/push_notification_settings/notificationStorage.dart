import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelmate/presentation/push_notification_settings/push_notification_settings.dart';


class NotificationStorage {
  static const String _key = 'notifications';

  // Save notification to local storage (SharedPreferences)
  static Future<void> save(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final existing = prefs.getStringList(_key) ?? [];
    existing.insert(0, '$now|$title|$body'); // Insert at the top of the list
    await prefs.setStringList(_key, existing.take(50).toList()); // Keep only the latest 50 notifications
  }

  // Load saved notifications
  static Future<List<ReceivedNotification>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    return saved.map((e) {
      final parts = e.split('|');
      return ReceivedNotification(
        timestamp: DateTime.parse(parts[0]),
        title: parts[1],
        body: parts[2],
      );
    }).toList();
  }
}

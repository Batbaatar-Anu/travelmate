import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Config {
  static late String supabaseUrl;
  static late String supabaseAnonKey;

  static Future<void> load() async {
    final String configString = await rootBundle.loadString('assets/images/env.json');
    final Map<String, dynamic> jsonMap = json.decode(configString);

    supabaseUrl = jsonMap['SUPABASE_URL'];
    supabaseAnonKey = jsonMap['SUPABASE_ANON_KEY'];
  }
}

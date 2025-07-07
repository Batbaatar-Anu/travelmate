import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/app_export.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String? temperature;
  String? condition;
  String? location;
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    try {
      final initialPosition = await _getCurrentLocation();
      _loadWeatherAt(initialPosition);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, // 100 метрт өөрчлөгдвөл дахин дуудна
        ),
      );

      _positionStream!.listen((position) {
        _loadWeatherAt(position);
      });
    } catch (e) {
      print('Location init error: $e');
    }
  }

  Future<void> _loadWeatherAt(Position position) async {
    try {
      final weatherData =
          await _fetchWeather(position.latitude, position.longitude);
      print("✅ Weather data: $weatherData"); // ← check in debug console

      setState(() {
        temperature = "${weatherData['main']['temp'].round()}°C";
        condition = weatherData['weather'][0]['description'];
        location = weatherData['name'];
      });
    } catch (e) {
      print("❌ Error loading weather: $e");
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) return lastPosition;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchWeather(double lat, double lon) async {
    const apiKey = '99fb4dd1334df80a3acd277f2c44345d';
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey&lang=mn',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'wb_sunny',
            color: Colors.amber,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                temperature ?? '...',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                condition ?? 'Loading...',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (location != null)
                Text(
                  location!,
                  style: AppTheme.lightTheme.textTheme.labelSmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

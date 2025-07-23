import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final List<LatLng> _loggedLocations = [];
  final List<Map<String, dynamic>> _logJson = [];

  Timer? _timer;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _initializeAndStartLogging();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeAndStartLogging() async {
    final isAllowed = await _checkPermissions();
    if (isAllowed) {
      await _loadStoredLocations();
      await _logCurrentPosition();
    }
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }
    return true;
  }

  Future<void> _logCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      final timestamp = DateTime.now().toIso8601String();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final locationData = {
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
        'timestamp': timestamp,
        'accuracy': position.accuracy,
        'speed': position.speed,
      };

      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('gps_logs')
          .add(locationData);

      setState(() {
        _currentPosition = latLng;
        _loggedLocations.add(latLng);
        _logJson.add(locationData);
        _totalPoints = _loggedLocations.length;
        _calculateTotalDistance();
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadStoredLocations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(user.uid)
        .collection('gps_logs')
        .orderBy('timestamp')
        .get();

    final docs = snapshot.docs;
    if (docs.isEmpty) return;

    setState(() {
      _loggedLocations.clear();
      _logJson.clear();
      for (var doc in docs) {
        final data = doc.data();
        final latLng = LatLng(data['latitude'], data['longitude']);
        _loggedLocations.add(latLng);
        _logJson.add(data);
      }
      _totalPoints = _loggedLocations.length;
      _calculateTotalDistance();
    });
  }

  void _calculateTotalDistance() {
    if (_loggedLocations.length < 2) {
      _totalDistance = 0.0;
      return;
    }
    double distance = 0.0;
    for (int i = 1; i < _loggedLocations.length; i++) {
      distance += Geolocator.distanceBetween(
        _loggedLocations[i - 1].latitude,
        _loggedLocations[i - 1].longitude,
        _loggedLocations[i].latitude,
        _loggedLocations[i].longitude,
      );
    }
    _totalDistance = distance;
  }

  void _startPeriodicLogging() {
    if (_timer != null) return;
    setState(() => _isTracking = true);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _logCurrentPosition());
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isTracking = false);
  }

  Set<Marker> _buildMarkers() {
    return _loggedLocations.asMap().entries.map((entry) {
      final index = entry.key;
      final latLng = entry.value;
      return Marker(
        markerId: MarkerId('point_$index'),
        position: latLng,
        infoWindow: InfoWindow(
          title: 'Цэг ${index + 1}',
          snippet: _logJson.isNotEmpty && index < _logJson.length
              ? 'Цаг: ${_formatTimestamp(_logJson[index]['timestamp'])}'
              : null,
        ),
      );
    }).toSet();
  }

  Set<Polyline> _buildPolyline() {
    if (_loggedLocations.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.red,
        width: 4,
        points: _loggedLocations,
      ),
    };
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [Text("Цэг"), Text("$_totalPoints")]),
                Column(children: [Text("Зай (км)"), Text((_totalDistance / 1000).toStringAsFixed(2))]),
                Column(children: [Text("Статус"), Text(_isTracking ? "Ажиллаж байна" : "Зогссон")]),
              ],
            ),
          ),
          Expanded(
            child: _currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 16),
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    markers: _buildMarkers(),
                    polylines: _buildPolyline(),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "track",
            onPressed: _isTracking ? _stopTracking : _startPeriodicLogging,
            child: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "locate",
            onPressed: _logCurrentPosition,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

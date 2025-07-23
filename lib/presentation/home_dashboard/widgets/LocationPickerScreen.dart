import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];
  Timer? _timer;
  bool _isTracking = false;
  String? _currentSessionId;
  int _recordedPoints = 0;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadRouteFromFirestore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // GPS зөвшөөрөл шалгах
  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location service-ийг идэвхжүүлнэ үү')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS зөвшөөрөл шаардлагатай')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS зөвшөөрлийг тохиргооноос идэвхжүүлнэ үү')),
      );
      return false;
    }

    return true;
  }

  // Анхны байрлал авах
  Future<void> _initLocation() async {
    try {
      final permissionGranted = await _checkPermissions();
      if (!permissionGranted) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
      });

      print('Анхны байрлал: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Байрлал авахад алдаа: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Байрлал авахад алдаа гарлаа')),
      );
    }
  }

  // Tracking эхлүүлэх
  void _startTracking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Нэвтэрч орно уу')),
        );
        return;
      }

      final permissionGranted = await _checkPermissions();
      if (!permissionGranted) return;

      // Шинэ tracking session үүсгэх
      final sessionRef = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('tracking_sessions')
          .add({
        'start_time': FieldValue.serverTimestamp(),
        'created_at': DateTime.now().toIso8601String(),
        'status': 'active',
      });

      _currentSessionId = sessionRef.id;
      _routePoints.clear();
      _recordedPoints = 0;

      // Анхны байрлалыг бүртгэх
      await _recordLocation();

      // 1 минут тутамд байрлал бүртгэх
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _recordLocation());
      
      setState(() => _isTracking = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS tracking эхэллээ')),
      );
    } catch (e) {
      print('Tracking эхлүүлэхэд алдаа: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tracking эхлүүлэхэд алдаа гарлаа')),
      );
    }
  }

  // Tracking зогсоох
  void _stopTracking() async {
  try {
    _timer?.cancel();
    setState(() => _isTracking = false);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentSessionId != null) {
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('tracking_sessions')
          .doc(_currentSessionId)
          .update({
        'end_time': FieldValue.serverTimestamp(),
        'ended_at': DateTime.now().toIso8601String(),
        'status': 'completed',
        'total_points': _recordedPoints,
      });
    }

    setState(() {
      _currentSessionId = null;
      _routePoints.clear();      // 🟢 Цэгүүдийг цэвэрлэнэ
      _recordedPoints = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('GPS tracking зогслоо. Нийт $_recordedPoints цэг бүртгэгдлээ')),
    );
  } catch (e) {
    print('Tracking зогсоохоход алдаа: $e');
  }
}


  // GPS координат бүртгэх
  Future<void> _recordLocation() async {
    if (_currentSessionId == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final latLng = LatLng(position.latitude, position.longitude);
      final now = DateTime.now();

      // Firestore-д хадгалах
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('tracking_sessions')
          .doc(_currentSessionId)
          .collection('points')
          .add({
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'recorded_at': now.toIso8601String(),
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
      });

      setState(() {
        _routePoints.add(latLng);
        _currentPosition = latLng;
        _recordedPoints++;
      });

      // Камерыг шинэ байрлал руу чиглүүлэх
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(latLng),
        );
      }

      print('GPS координат бүртгэгдлээ: ${latLng.latitude}, ${latLng.longitude}');
    } catch (e) {
      print('GPS координат бүртгэхэд алдаа: $e');
    }
  }

  // Хамгийн сүүлийн tracking session-ийг ачаалах
  Future<void> _loadRouteFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final sessionSnap = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('tracking_sessions')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (sessionSnap.docs.isEmpty) return;

      final sessionId = sessionSnap.docs.first.id;
      final sessionData = sessionSnap.docs.first.data();

      // Хэрэв идэвхтэй session бол үргэлжлүүлэх
      if (sessionData['status'] == 'active') {
        _currentSessionId = sessionId;
        setState(() => _isTracking = true);
        _timer = Timer.periodic(const Duration(minutes: 1), (_) => _recordLocation());
      }

      final pointsSnap = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('tracking_sessions')
          .doc(sessionId)
          .collection('points')
          .orderBy('recorded_at')
          .get();

      List<LatLng> loadedPoints = pointsSnap.docs.map((doc) {
        final data = doc.data();
        return LatLng(data['latitude'], data['longitude']);
      }).toList();

      setState(() {
        _routePoints = loadedPoints;
        _recordedPoints = loadedPoints.length;
        if (loadedPoints.isNotEmpty) {
          _currentPosition = loadedPoints.last;
        }
      });

      print('Ачаалагдсан цэгүүд: ${loadedPoints.length}');
    } catch (e) {
      print('Route ачаалахад алдаа: $e');
    }
  }

  // Marker-үүд үүсгэх
  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    if (_routePoints.isNotEmpty) {
      // Эхлэлийн цэг
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: _routePoints.first,
        infoWindow: const InfoWindow(title: 'Эхлэл'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));

      // Төгсгөлийн цэг
      if (_routePoints.length > 1) {
        markers.add(Marker(
          markerId: const MarkerId('end'),
          position: _routePoints.last,
          infoWindow: InfoWindow(
            title: 'Одоогийн байрлал',
            snippet: 'Нийт цэг: $_recordedPoints',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }
    }

    return markers;
  }

  // Route-ийн шугам үүсгэх
  Set<Polyline> _buildPolyline() {
    if (_routePoints.length < 2) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 4,
        points: _routePoints,
        patterns: _isTracking ? [] : [PatternItem.dash(10), PatternItem.gap(5)],
      ),
    };
  }

  // Бүх route-ийг харуулах
  void _showFullRoute() {
    if (_routePoints.isEmpty || _mapController == null) return;

    LatLngBounds bounds = _calculateBounds(_routePoints);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  // Bounds тооцоолох
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Tracker'),
        backgroundColor: Colors.blue,
        actions: [
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: Icon(Icons.zoom_out_map),
              onPressed: _showFullRoute,
              tooltip: 'Бүх route харуулах',
            ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('GPS байрлал авч байна...'),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  polylines: _buildPolyline(),
                  markers: _buildMarkers(),
                  mapType: MapType.normal,
                ),
                
                // Статус мэдээлэл
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isTracking ? Icons.location_on : Icons.location_off,
                                color: _isTracking ? Colors.green : Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _isTracking ? 'Tracking идэвхтэй' : 'Tracking зогссон',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (_recordedPoints > 0)
                            Text('Бүртгэгдсэн цэг: $_recordedPoints'),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tracking товч
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton.extended(
                    heroTag: 'trackBtn',
                    onPressed: _isTracking ? _stopTracking : _startTracking,
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                    label: Text(_isTracking ? 'Зогсоох' : 'Эхлүүлэх'),
                  ),
                ),
              ],
            ),
    );
  }
}
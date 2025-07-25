import 'dart:async';
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
  final List<LatLng> _smoothedLocations = []; // For smoothed polyline
  final List<Map<String, dynamic>> _logJson = [];
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  Timer? _timer;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  int _totalPoints = 0;
  String? _currentSessionId;
  String _selectedRouteTitle = '';
  bool _isViewingHistory = false;
  bool _useSmoothPolyline = true; // Toggle for smooth polyline

  // Enhanced route naming
  final TextEditingController _routeNameController = TextEditingController();
  String _customRouteName = '';

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    _routeNameController.dispose();
    super.dispose();
  }

  // Smooth polyline methods
  List<LatLng> _applySmoothingFilter(List<LatLng> points) {
    if (points.length < 3) return points;

    List<LatLng> smoothed = [];
    smoothed.add(points.first); // Keep first point

    // Apply simple moving average smoothing
    for (int i = 1; i < points.length - 1; i++) {
      double avgLat = (points[i - 1].latitude +
              points[i].latitude +
              points[i + 1].latitude) /
          3;
      double avgLng = (points[i - 1].longitude +
              points[i].longitude +
              points[i + 1].longitude) /
          3;
      smoothed.add(LatLng(avgLat, avgLng));
    }

    smoothed.add(points.last); // Keep last point
    return smoothed;
  }

  List<LatLng> _interpolatePoints(List<LatLng> points,
      {int segmentPoints = 5}) {
    if (points.length < 2) return points;

    List<LatLng> interpolated = [];

    for (int i = 0; i < points.length - 1; i++) {
      LatLng start = points[i];
      LatLng end = points[i + 1];

      interpolated.add(start);

      // Add intermediate points between start and end
      for (int j = 1; j < segmentPoints; j++) {
        double ratio = j / segmentPoints;
        double lat = start.latitude + (end.latitude - start.latitude) * ratio;
        double lng =
            start.longitude + (end.longitude - start.longitude) * ratio;
        interpolated.add(LatLng(lat, lng));
      }
    }

    interpolated.add(points.last);
    return interpolated;
  }

  List<LatLng> _removeNoisyPoints(List<LatLng> points,
      {double threshold = 10.0}) {
    if (points.length < 3) return points;

    List<LatLng> filtered = [points.first];

    for (int i = 1; i < points.length - 1; i++) {
      LatLng prev = filtered.last;
      LatLng current = points[i];
      LatLng next = points[i + 1];

      // Calculate distance from current point to line between prev and next
      double distance = _pointToLineDistance(current, prev, next);

      // Only add point if it's significantly different from the straight line
      if (distance > threshold) {
        filtered.add(current);
      }
    }

    filtered.add(points.last);
    return filtered;
  }

  double _pointToLineDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    double A = point.latitude - lineStart.latitude;
    double B = point.longitude - lineStart.longitude;
    double C = lineEnd.latitude - lineStart.latitude;
    double D = lineEnd.longitude - lineStart.longitude;

    double dot = A * C + B * D;
    double lenSq = C * C + D * D;

    if (lenSq == 0) {
      return Geolocator.distanceBetween(point.latitude, point.longitude,
          lineStart.latitude, lineStart.longitude);
    }

    double param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      xx = lineStart.latitude;
      yy = lineStart.longitude;
    } else if (param > 1) {
      xx = lineEnd.latitude;
      yy = lineEnd.longitude;
    } else {
      xx = lineStart.latitude + param * C;
      yy = lineStart.longitude + param * D;
    }

    return Geolocator.distanceBetween(point.latitude, point.longitude, xx, yy);
  }

  void _updateSmoothedPolyline() {
    if (_loggedLocations.length < 2) {
      _smoothedLocations.clear();
      return;
    }

    List<LatLng> processed = List.from(_loggedLocations);

    // Step 1: Remove noisy points
    processed = _removeNoisyPoints(processed, threshold: 5.0);

    // Step 2: Apply smoothing filter
    processed = _applySmoothingFilter(processed);

    // Step 3: Interpolate points for smoother curves
    processed = _interpolatePoints(processed, segmentPoints: 3);

    // Step 4: Optional: Apply Bezier curves for very smooth appearance
    // processed = _createBezierCurve(processed);

    setState(() {
      _smoothedLocations.clear();
      _smoothedLocations.addAll(processed);
    });
  }

  // Your existing methods remain the same...
  Future<void> _initializeAndLoad() async {
    final isAllowed = await _checkPermissions();
    if (isAllowed) {
      await _getInitialPositionOnly();
    }
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showDialog('GPS Service', 'GPS службийг идэвхжүүлнэ үү');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _showDialog('Зөвшөөрөл', 'GPS зөвшөөрлийг тохиргооноос идэвхжүүлнэ үү');
      return false;
    }

    if (permission == LocationPermission.denied) {
      _showDialog('Зөвшөөрөл', 'GPS зөвшөөрөл шаардлагатай');
      return false;
    }

    return true;
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ойлголоо'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRouteNameDialog() async {
    final now = DateTime.now();
    final defaultName =
        'Маршрут ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    _routeNameController.text = defaultName;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Маршрутын нэр'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Маршрутын нэрийг оруулна уу:'),
            const SizedBox(height: 16),
            TextField(
              controller: _routeNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Жишээ: Гэр - Ажлын газар',
              ),
              maxLength: 50,
            ),
            // Add smooth polyline toggle
            Row(
              children: [
                Checkbox(
                  value: _useSmoothPolyline,
                  onChanged: (value) {
                    setState(() {
                      _useSmoothPolyline = value ?? true;
                    });
                  },
                ),
                const Text('Гөлгөр зураас ашиглах'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Цуцлах'),
          ),
          ElevatedButton(
            onPressed: () {
              _customRouteName = _routeNameController.text.trim();
              if (_customRouteName.isEmpty) {
                _customRouteName = defaultName;
              }
              Navigator.pop(context);
              _startTrackingWithName();
            },
            child: const Text('Эхлүүлэх'),
          ),
        ],
      ),
    );
  }

//GPS анхны цэг авах
  Future<void> _getInitialPositionOnly() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
      });
      await _animateToPosition(latLng);
    } catch (e) {
      debugPrint('Error getting initial position: $e');
      _showDialog('Алдаа', 'Одоогийн байршлыг олж чадсангүй');
    }
  }

  Future<void> _animateToPosition(LatLng latLng, {double zoom = 16}) async {
    final controller = _mapController ?? await _controllerCompleter.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: zoom)));
  }

  Future<void> _loadSessionLocations(
      String sessionId, String routeTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('gps_sessions')
          .doc(sessionId)
          .collection('locations')
          .orderBy('timestamp')
          .get();

      final points = <LatLng>[];
      final jsonData = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'];
        final lng = data['longitude'];
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
          jsonData.add(data);
        }
      }

      setState(() {
        _selectedRouteTitle = routeTitle;
        _isViewingHistory = true;
        _loggedLocations.clear();
        _logJson.clear();
        _loggedLocations.addAll(points);
        _logJson.addAll(jsonData);
        _totalPoints = points.length;
        _calculateTotalDistance();
      });

      // Update smoothed polyline for history
      _updateSmoothedPolyline();

      if (points.isNotEmpty) {
        await _animateToPosition(points.first, zoom: 15);
        _showSnackBar('$routeTitle ачаалагдлаа (${points.length} цэг)');
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
      _showDialog('Алдаа', 'Маршрут ачааллахад алдаа гарлаа');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _recordCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15));
      final latLng = LatLng(position.latitude, position.longitude);
      final timestamp = DateTime.now().toIso8601String();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _currentSessionId == null) return;

      final locationData = {
        'latitude': double.parse(latLng.latitude.toStringAsFixed(8)),
        'longitude': double.parse(latLng.longitude.toStringAsFixed(8)),
        'timestamp': timestamp,
        'serverTimestamp': FieldValue.serverTimestamp(),
        'accuracy': position.accuracy,
        'speed': position.speed,
        'altitude': position.altitude,
      };

      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('gps_sessions')
          .doc(_currentSessionId)
          .collection('locations')
          .add(locationData);

      setState(() {
        _currentPosition = latLng;
        _loggedLocations.add(latLng);
        _logJson.add(locationData);
        _totalPoints = _loggedLocations.length;
        _calculateTotalDistance();
      });

      // Update smoothed polyline after adding new point
      _updateSmoothedPolyline();

      await _animateToPosition(latLng);
    } catch (e) {
      debugPrint('Error recording position: $e');
    }
  }

  Future<void> _startTrackingWithName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showDialog('Алдаа', 'Нэвтэрч орно уу');
      return;
    }

    final now = DateTime.now();
    final sessionId = 'session_${now.millisecondsSinceEpoch}';

    try {
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('gps_sessions')
          .doc(sessionId)
          .set({
        'started_at': FieldValue.serverTimestamp(),
        'status': 'active',
        'device': 'mobile',
        'created_date': FieldValue.serverTimestamp(),
        'route_name': _customRouteName,
      });

      setState(() {
        _isTracking = true;
        _currentSessionId = sessionId;
        _isViewingHistory = false;
        _loggedLocations.clear();
        _smoothedLocations.clear();
        _logJson.clear();
        _totalPoints = 0;
        _totalDistance = 0.0;
      });

      await _recordCurrentPosition();
      _timer = Timer.periodic(
          const Duration(minutes: 1), (_) => _recordCurrentPosition());

      _showSnackBar('GPS tracking эхэллээ: $_customRouteName');
    } catch (e) {
      debugPrint('Error starting tracking: $e');
      _showDialog('Алдаа', 'Tracking эхлүүлж чадсангүй');
    }
  }

  void _stopTracking() async {
    _timer?.cancel();
    _timer = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentSessionId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('user_profiles')
            .doc(user.uid)
            .collection('gps_sessions')
            .doc(_currentSessionId)
            .update({
          'status': 'finished',
          'ended_at': FieldValue.serverTimestamp(),
          'total_points': _totalPoints,
          'total_distance': _totalDistance,
        });

        _showSnackBar('GPS tracking зогслоо (${_totalPoints} цэг бүртгэгдлээ)');
      } catch (e) {
        debugPrint('Error stopping tracking: $e');
      }
    }

    setState(() {
      _isTracking = false;
      _currentSessionId = null;
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

  void _deleteSession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Delete the specific session from Firestore
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('gps_sessions')
          .doc(sessionId)
          .delete();

      _showSnackBar('Маршрут устгагдлаа');
    } catch (e) {
      debugPrint('Error deleting session: $e');
      _showSnackBar('Маршрут устгах үед алдаа гарлаа');
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (int i = 0; i < _loggedLocations.length; i++) {
      final latLng = _loggedLocations[i];
      Color markerColor = Colors.blue;
      String title = 'Цэг ${i + 1}';

      if (i == 0) {
        markerColor = Colors.green;
        title = 'Эхлэл';
      } else if (i == _loggedLocations.length - 1) {
        markerColor = _isTracking ? Colors.red : Colors.orange;
        title = _isTracking ? 'Одоогийн байршил' : 'Төгсгөл';
      }

      markers.add(Marker(
        markerId: MarkerId('point_$i'),
        position: latLng,
        infoWindow: InfoWindow(
          title: title,
          snippet: _logJson.isNotEmpty && i < _logJson.length
              ? 'Цаг: ${_formatTimestamp(_logJson[i]['timestamp'])}'
              : null,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor == Colors.green
            ? BitmapDescriptor.hueGreen
            : markerColor == Colors.red
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueOrange),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolyline() {
    if (_loggedLocations.length < 2) return {};

    Color routeColor = _isViewingHistory ? Colors.purple : Colors.blue;
    if (_isTracking) routeColor = Colors.red;

    // Use smoothed locations if enabled and available
    List<LatLng> polylinePoints =
        _useSmoothPolyline && _smoothedLocations.isNotEmpty
            ? _smoothedLocations
            : _loggedLocations;

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: routeColor,
        width: 5,
        points: polylinePoints,
        patterns: _isViewingHistory
            ? [PatternItem.dash(15), PatternItem.gap(10)]
            : [],
        // Add these properties for smoother appearance
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }


  Widget _buildTopInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isTracking
                    ? Icons.gps_fixed
                    : _isViewingHistory
                        ? Icons.history
                        : Icons.gps_off,
                color: _isTracking
                    ? Colors.red
                    : _isViewingHistory
                        ? Colors.purple
                        : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isTracking
                      ? 'Идэвхтэй tracking: $_customRouteName'
                      : _isViewingHistory
                          ? _selectedRouteTitle
                          : 'GPS Tracking зогссон',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isTracking
                        ? Colors.red
                        : _isViewingHistory
                            ? Colors.purple
                            : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Add toggle for smooth polyline
              IconButton(
                icon: Icon(
                  _useSmoothPolyline ? Icons.timeline : Icons.show_chart,
                  color: _useSmoothPolyline ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _useSmoothPolyline = !_useSmoothPolyline;
                  });
                  if (_useSmoothPolyline) {
                    _updateSmoothedPolyline();
                  }
                  _showSnackBar(_useSmoothPolyline
                      ? 'Гөлгөр зураас идэвхжлээ'
                      : 'Энгийн зураас идэвхжлээ');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Цэгүүд', '$_totalPoints', Icons.place),
              _buildStatItem(
                  'Зай',
                  '${(_totalDistance / 1000).toStringAsFixed(2)} км',
                  Icons.straighten),
              _buildStatItem(
                  'Төлөв',
                  _isTracking
                      ? 'Идэвхтэй'
                      : _isViewingHistory
                          ? 'Түүх'
                          : 'Зогссон',
                  Icons.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('GPS байршил хайж байна...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 🌍 Google Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(47.9182, 106.9171),
                zoom: 0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (!_controllerCompleter.isCompleted) {
                  _controllerCompleter.complete(controller);
                }
              },
              myLocationEnabled: true,
              markers: _buildMarkers(),
              polylines: _buildPolyline(),
              padding: EdgeInsets.zero,
            ),
          ),

          // 📋 Top Info Card (distance, points, status, etc.)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildTopInfoCard(),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.1,
            maxChildSize: 0.4,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // ⬍ Drag Handle
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Маршрутын түүх",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Divider(height: 1)),

                    // 📍 Route List
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('user_profiles')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('gps_sessions')
                          .orderBy('created_date', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final sessions = snapshot.data!.docs;
                        if (sessions.isEmpty) {
                          return const SliverFillRemaining(
                            child: Center(child: Text('Түүх алга байна')),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = sessions[index];
                              final sessionId = doc.id;
                              final routeName =
                                  doc['route_name'] ?? 'Нэргүй маршрут';
                              final createdDate = doc['created_date'];
                              final formattedDate = createdDate != null
                                  ? (createdDate as Timestamp)
                                      .toDate()
                                      .toString()
                                      .substring(0, 19)
                                  : 'Огноо алга';

                              return ListTile(
                                leading: const Icon(Icons.pin),
                                title: Text(routeName),
                                subtitle: Text('Огноо: $formattedDate'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    // Implement your delete logic here
                                    _deleteSession(sessionId);
                                  },
                                ),
                                onTap: () {
                                  _loadSessionLocations(sessionId, routeName);
                                },
                              );
                            },
                            childCount: sessions.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // ▶️ Floating Action Button (Start/Stop Tracking)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: "track",
        onPressed: _isTracking ? _stopTracking : _showRouteNameDialog,
        backgroundColor: _isTracking ? Colors.red : Colors.green,
        child: Icon(
          _isTracking ? Icons.stop : Icons.play_arrow,
          size: 32,
        ),
      ),
    );
  }
}

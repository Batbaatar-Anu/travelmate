import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const GoogleMapScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController _controller;
  late CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 14.0,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip Location')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _initialPosition,
        markers: {
          Marker(
            markerId: MarkerId('trip_location'),
            position: LatLng(widget.latitude, widget.longitude),
          ),
        },
      ),
    );
  }
}

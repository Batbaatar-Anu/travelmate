import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/LocationPickerScreen.dart';

class NewTripScreen extends StatefulWidget {
  const NewTripScreen({super.key});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;
  LatLng? _selectedLatLng;

  /// Сонгосон координатаас газрын нарийвчилсан нэрийг авч 'Очих газар'-т оруулна
  Future<void> _updateLocationName(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final name = [
          place.name,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(", ");

        _destinationController.text = name;
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLatLng == null) {
      _showSnackBar('Байршил сонгоно уу', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Нэвтэрсэн хэрэглэгч олдсонгүй', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final tripData = {
      'user_id': user.uid,
      'title': _tripNameController.text.trim(),
      'destination': _destinationController.text.trim(),
      'image': _imageUrlController.text.trim(),
      'description': _descriptionController.text.trim(),
      'rating': 0.0,
      'location': {
        'latitude': _selectedLatLng!.latitude,
        'longitude': _selectedLatLng!.longitude,
      },
      'date': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('trips').add(tripData);
      _showSnackBar('Аялал амжилттай хадгалагдлаа!', isError: false);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Хадгалах үед алдаа гарлаа: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Шинэ аялал', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput("Аяллын нэр", _tripNameController,
                  hint: "Жишээ: Говийн аялал", requiredField: true),
              SizedBox(height: 2.h),
              _buildInput("Тайлбар", _descriptionController,
                  hint: "Тайлбар бичнэ үү", maxLines: 4),
              SizedBox(height: 2.h),
              _buildInput("Зургийн URL", _imageUrlController,
                  hint: "https://...", keyboardType: TextInputType.url),
              SizedBox(height: 2.h),
              _buildInput("Очих газар", _destinationController,
                  hint: "Жишээ: Улаанбаатар, Монгол", requiredField: true),
              SizedBox(height: 3.h),
              Text(
                _selectedLatLng != null
                    ? "Сонгосон байршил: ${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)}"
                    : "Байршил сонгоогүй байна",
                style: TextStyle(fontSize: 13.sp),
              ),
              SizedBox(height: 1.h),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LocationPickerScreen()),
                  );
                  if (result != null && result is LatLng) {
                    setState(() => _selectedLatLng = result);
                    await _updateLocationName(result);
                  }
                },
                icon: Icon(Icons.location_on),
                label: Text("Байршил сонгох"),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text("Хадгалах"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String title,
    TextEditingController controller, {
    required String hint,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        SizedBox(height: 0.5.h),
        TextFormField(
          controller: controller,
          validator: requiredField
              ? (val) => val == null || val.isEmpty ? '$title шаардлагатай' : null
              : null,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

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
  final _highlightsController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  File? _selectedMedia;
  bool _isLoading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedMedia = File(picked.path);
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Нэвтэрсэн хэрэглэгч олдсонгүй', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String? imageUrl;
    if (_selectedMedia != null) {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';
        final ref =
            FirebaseStorage.instance.ref().child('trip_media/$fileName');

        final uploadTaskSnapshot = await ref.putFile(_selectedMedia!);

        if (uploadTaskSnapshot.state == TaskState.success) {
          imageUrl = await ref.getDownloadURL();
          print("✅ Зураг амжилттай хадгалагдлаа. URL: $imageUrl");
        } else {
          throw FirebaseException(
            plugin: 'firebase_storage',
            message:
                'Upload task failed with state: ${uploadTaskSnapshot.state}',
          );
        }
      } catch (e) {
        print("🔥 Firebase upload error: $e");
        _showSnackBar('Зураг оруулахад алдаа гарлаа: $e', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    final tripData = {
      'user_id': user.uid,
      'title': _tripNameController.text.trim(),
      'subtitle': _destinationController.text.trim(),
      'heroImage': imageUrl,
      'description': _descriptionController.text.trim(),
      'rating': 0.0,
      'reviewCount': 0,
      'coordinates': {
        'latitude': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
      },
      'highlights': _highlightsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'photos': [imageUrl],
      'created_at': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('trips').add(tripData);
      _showSnackBar('Аялал амжилттай нийтлэгдлээ!', isError: false);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Аялал хадгалахад алдаа гарлаа', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _highlightsController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Шинэ аялал нийтлэх',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.teal.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            NetworkImage("https://i.pravatar.cc/150"),
                        radius: 28,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Шинэ аялал",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Аяллын мэдээллийг бөглөнө үү",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 3.h),

                // Trip Name Section
                _buildSectionCard(
                  title: "Аяллын нэр",
                  icon: Icons.title,
                  color: Colors.blue,
                  child: _buildInputField(
                    controller: _tripNameController,
                    hint: "Аяллын нэр оруулна уу",
                    validator: (val) => val == null || val.isEmpty
                        ? 'Аяллын нэр оруулна уу'
                        : null,
                  ),
                ),

                SizedBox(height: 2.h),

                // Description Section
                _buildSectionCard(
                  title: "Тайлбар",
                  icon: Icons.description,
                  color: Colors.purple,
                  child: _buildInputField(
                    controller: _descriptionController,
                    hint: "Аяллын талаар дэлгэрэнгүй...",
                    maxLines: 4,
                  ),
                ),

                SizedBox(height: 2.h),

                // Image Section
                _buildSectionCard(
                  title: "Зураг",
                  icon: Icons.image,
                  color: Colors.orange,
                  child: _buildImagePicker(),
                ),

                SizedBox(height: 2.h),

                // Destination Section
                _buildSectionCard(
                  title: "Очих газар",
                  icon: Icons.location_on,
                  color: Colors.red,
                  child: _buildInputField(
                    controller: _destinationController,
                    hint: "Хот, улс",
                    validator: (val) => val == null || val.isEmpty
                        ? 'Очих газрын нэр оруулна уу'
                        : null,
                  ),
                ),

                SizedBox(height: 2.h),

                // Highlights Section
                _buildSectionCard(
                  title: "Гол онцлох зүйлс",
                  icon: Icons.star,
                  color: Colors.amber,
                  child: _buildInputField(
                    controller: _highlightsController,
                    hint: "Таслалаар тусгаарлан бичнэ үү",
                  ),
                ),

                SizedBox(height: 2.h),

                // Coordinates Section
                _buildSectionCard(
                  title: "Координат",
                  icon: Icons.gps_fixed,
                  color: Colors.teal,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: _latitudeController,
                          hint: "Өргөрөг",
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: _buildInputField(
                          controller: _longitudeController,
                          hint: "Уртраг",
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 4.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.green.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Нийтэлж байна...",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Нийтлэх",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildImagePicker() {
    return _selectedMedia != null
        ? Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(_selectedMedia!),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMedia = null),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : GestureDetector(
            onTap: _pickMedia,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Зураг нэмэх",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Дарж зураг сонгоно уу",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

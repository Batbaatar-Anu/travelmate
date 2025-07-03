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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нэвтэрсэн хэрэглэгч олдсонгүй')),
      );
      return;
    }

    String? imageUrl;
    if (_selectedMedia != null) {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';
        final ref =
            FirebaseStorage.instance.ref().child('trip_media/$fileName');

        // ✨ Upload хийж, snapshot авч байна
        final uploadTaskSnapshot = await ref.putFile(_selectedMedia!);

        // ✨ Upload амжилттай болсон эсэхийг шалгаж байна
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Зураг оруулахад алдаа гарлаа: $e')),
        );
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

    await FirebaseFirestore.instance.collection('trips').add(tripData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Аялал амжилттай нийтлэгдлээ!')),
    );
    Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Шинэ аялал нийтлэх')),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
                    radius: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: TextFormField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(
                        hintText: "Аяллын нэр",
                        border: InputBorder.none,
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Аяллын нэр оруулна уу'
                          : null,
                    ),
                  ),
                ],
              ),
              const Divider(),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Аяллын талаар дэлгэрэнгүй...",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              _selectedMedia != null
                  ? Stack(
                      children: [
                        Image.file(_selectedMedia!),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: InkWell(
                            onTap: () => setState(() => _selectedMedia = null),
                            child: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.image),
                      label: const Text("Зураг нэмэх"),
                    ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Очих газар (хот, улс)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Очих газрын нэр оруулна уу'
                    : null,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _highlightsController,
                decoration: const InputDecoration(
                  labelText: 'Гол онцлох зүйлс (таслалаар тусгаарлан)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Өргөрөг',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Уртраг',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: _saveTrip,
                icon: const Icon(Icons.send),
                label: const Text('Нийтлэх'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

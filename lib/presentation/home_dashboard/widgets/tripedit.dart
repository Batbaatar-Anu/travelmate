import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

class TripEditScreen extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;

  const TripEditScreen({super.key, required this.tripId, required this.trip});

  @override
  State<TripEditScreen> createState() => _TripEditScreenState();
}

class _TripEditScreenState extends State<TripEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _destinationController;
  late TextEditingController _descriptionController;
  late TextEditingController _highlightsController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  File? _selectedMedia;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip['title']);
    _destinationController = TextEditingController(text: widget.trip['destination']);
    _descriptionController = TextEditingController(text: widget.trip['description'] ?? '');
    _highlightsController = TextEditingController(text: (widget.trip['highlights'] as List?)?.join(", ") ?? '');
    _latitudeController = TextEditingController(text: widget.trip['coordinates']?['latitude']?.toString() ?? '');
    _longitudeController = TextEditingController(text: widget.trip['coordinates']?['longitude']?.toString() ?? '');
    _existingImageUrl = widget.trip['heroImage'];
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedMedia = File(picked.path));
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    String? imageUrl = _existingImageUrl;
    if (_selectedMedia != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user?.uid}.jpg';
        final ref = FirebaseStorage.instance.ref().child('trip_media/$fileName');
        final snapshot = await ref.putFile(_selectedMedia!);
        if (snapshot.state == TaskState.success) {
          imageUrl = await ref.getDownloadURL();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
        return;
      }
    }

    final updateData = {
      'title': _titleController.text.trim(),
      'destination': _destinationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'heroImage': imageUrl,
      'coordinates': {
        'latitude': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
      },
      'highlights': _highlightsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update(updateData);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Аялал шинэчлэгдлээ')));
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Аялал засах')),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Аяллын нэр'),
                validator: (val) => val == null || val.isEmpty ? 'Нэр оруулна уу' : null,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'Тайлбар'),
              ),
              SizedBox(height: 2.h),
              _selectedMedia != null
                  ? Stack(
                      children: [
                        Image.file(_selectedMedia!),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.white, size: 16),
                              onPressed: () => setState(() => _selectedMedia = null),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _existingImageUrl != null
                      ? Image.network(_existingImageUrl!, height: 150)
                      : ElevatedButton.icon(
                          onPressed: _pickMedia,
                          icon: Icon(Icons.image),
                          label: Text("Зураг нэмэх"),
                        ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(labelText: 'Очих газар'),
                validator: (val) => val == null || val.isEmpty ? 'Газрын нэр оруулна уу' : null,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _highlightsController,
                decoration: InputDecoration(labelText: 'Онцлох зүйлс (таслалаар тусгаарлана)'),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: InputDecoration(labelText: 'Өргөрөг'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: InputDecoration(labelText: 'Уртраг'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: Icon(Icons.save),
                label: Text("Хадгалах"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

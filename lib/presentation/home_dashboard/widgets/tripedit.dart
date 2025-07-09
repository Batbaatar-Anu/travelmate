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
  late TextEditingController _imageUrlController;

  File? _selectedMedia;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip['title']);
    _destinationController =
        TextEditingController(text: widget.trip['destination']);
    _descriptionController =
        TextEditingController(text: widget.trip['description'] ?? '');
    _imageUrlController =
        TextEditingController(text: widget.trip['heroImage'] ?? '');
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
    setState(() => _isLoading = true);

    String? imageUrl = _imageUrlController.text.trim();

    if (_selectedMedia != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${user?.uid}.jpg';
        final ref =
            FirebaseStorage.instance.ref().child('trip_media/$fileName');
        final snapshot = await ref.putFile(_selectedMedia!);
        if (snapshot.state == TaskState.success) {
          imageUrl = await ref.getDownloadURL();
        }
      } catch (e) {
        _showSnackBar('Зураг байршуулахад алдаа гарлаа: $e', isError: true);
        setState(() => _isLoading = false);
        return;
      }
    }

    final updateData = {
      'title': _titleController.text.trim(),
      'destination': _destinationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'heroImage': imageUrl,
      'updated_at': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update(updateData);
      _showSnackBar('Аялал амжилттай шинэчлэгдлээ!', isError: false);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Шинэчлэх үед алдаа гарлаа: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle,
                color: Colors.white),
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
              ? (val) =>
                  val == null || val.isEmpty ? '$title шаардлагатай' : null
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Аялал засах', style: TextStyle(color: Colors.black)),
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
              _buildInput("Аяллын нэр", _titleController,
                  hint: "Жишээ: Хөвсгөл", requiredField: true),
              SizedBox(height: 2.h),
              _buildInput("Тайлбар", _descriptionController,
                  hint: "Тайлбар бичнэ үү", maxLines: 4),
              SizedBox(height: 2.h),
              _buildInput("Зургийн URL", _imageUrlController,
                  hint: "https://...", keyboardType: TextInputType.url),
              SizedBox(height: 2.h),
              _selectedMedia != null
                  ? Stack(
                      children: [
                        Image.file(_selectedMedia!, height: 150),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                              onPressed: () =>
                                  setState(() => _selectedMedia = null),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _imageUrlController.text.isNotEmpty
                      ? Image.network(_imageUrlController.text, height: 150)
                      : ElevatedButton.icon(
                          onPressed: _pickMedia,
                          icon: const Icon(Icons.image),
                          label: const Text("Зураг нэмэх"),
                        ),
              SizedBox(height: 2.h),
              _buildInput("Очих газар", _destinationController,
                  hint: "Жишээ: Улаанбаатар", requiredField: true),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
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

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}

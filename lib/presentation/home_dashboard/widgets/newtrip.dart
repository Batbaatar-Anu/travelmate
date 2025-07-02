import 'dart:io';
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
  DateTime? _startDate;
  DateTime? _endDate;
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

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() {
        if (isStart) {
          _startDate = selected;
        } else {
          _endDate = selected;
        }
      });
    }
  }

  void _saveTrip() {
    if (_formKey.currentState!.validate()) {
      final trip = {
        'name': _tripNameController.text,
        'destination': _destinationController.text,
        'description': _descriptionController.text,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'media_path': _selectedMedia?.path,
      };

      print('Trip posted: $trip');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your trip has been posted!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a New Trip')),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile avatar and input
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
                        hintText: "What's your trip name?",
                        border: InputBorder.none,
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Trip name required' : null,
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Tell something about your trip...",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),

              // Media preview
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
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.image),
                      label: const Text("Add Image/Video"),
                    ),

              SizedBox(height: 2.h),

              // Destination
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Destination required' : null,
              ),
              SizedBox(height: 2.h),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(_startDate == null
                          ? 'Start Date'
                          : 'Start: ${_startDate!.toLocal().toString().split(" ")[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(_endDate == null
                          ? 'End Date'
                          : 'End: ${_endDate!.toLocal().toString().split(" ")[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),

              // Post button
              ElevatedButton.icon(
                onPressed: _saveTrip,
                icon: const Icon(Icons.send),
                label: const Text('Post Trip'),
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

import 'package:flutter/material.dart';
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
  DateTime? _startDate;
  DateTime? _endDate;

  void _saveTrip() {
    if (_formKey.currentState!.validate()) {
      final trip = {
        'name': _tripNameController.text,
        'destination': _destinationController.text,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
      };

      print('Trip saved: $trip');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New trip saved successfully!')),
      );

      Navigator.pop(context);
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

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Trip')),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tripNameController,
                decoration: const InputDecoration(labelText: 'Trip Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter trip name' : null,
              ),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter destination' : null,
              ),
              SizedBox(height: 2.h),
              ListTile(
                title: Text(_startDate == null
                    ? 'Pick Start Date'
                    : 'Start: ${_startDate!.toLocal().toString().split(" ")[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isStart: true),
              ),
              ListTile(
                title: Text(_endDate == null
                    ? 'Pick End Date'
                    : 'End: ${_endDate!.toLocal().toString().split(" ")[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isStart: false),
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: _saveTrip,
                child: const Text('Save Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

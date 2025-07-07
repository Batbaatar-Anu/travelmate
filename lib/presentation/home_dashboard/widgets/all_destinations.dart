import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/recommended_destination_widget.dart';

import '../../../core/app_export.dart';

class AllDestinationsScreen extends StatelessWidget {
  const AllDestinationsScreen({super.key});

  Stream<List<Map<String, dynamic>>> fetchAllDestinations() {
    return FirebaseFirestore.instance
        .collection('destinations')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Destinations"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchAllDestinations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading destinations"));
          }

          final destinations = snapshot.data ?? [];

          if (destinations.isEmpty) {
            return const Center(child: Text("No destinations found"));
          }

          return Padding(
            padding: EdgeInsets.all(4.w),
            child: GridView.builder(
              itemCount: destinations.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return RecommendedDestinationWidget(
                  name: destination["name"] ?? '',
                  imageUrl: destination["image"] ?? '',
                  price: destination["price"] ?? '',
                  rating: destination["rating"] ?? 0.0,
                  duration: destination["duration"] ?? '',
                  category: destination["category"] ?? '',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/home-detail',
                    arguments: destination['id'],
                  ),
                  isSaved: false, // optional: manage saved logic
                  onFavoriteToggle: () {}, // optional
                );
              },
            ),
          );
        },
      ),
    );
  }
}

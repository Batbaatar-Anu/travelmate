import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/recommended_destination_widget.dart';

class AllDestinationsScreen extends StatelessWidget {
  const AllDestinationsScreen({super.key});
Future<void> updateDestinationRating(String destinationId) async {
  final reviewsSnap = await FirebaseFirestore.instance
      .collection('destinations')
      .doc(destinationId)
      .collection('reviews')
      .get();

  if (reviewsSnap.docs.isEmpty) return;

  final totalReviews = reviewsSnap.docs.length;
  final totalRating = reviewsSnap.docs.fold<double>(
    0,
    (sum, doc) => sum + (doc['rating'] as num).toDouble(),
  );

  final avgRating = totalRating / totalReviews;

  await FirebaseFirestore.instance
      .collection('destinations')
      .doc(destinationId)
      .update({
    'rating': avgRating,
    'reviewCount': totalReviews,
  });
}


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
            return _buildShimmerGrid();
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
                  isSaved: false,
                  onFavoriteToggle: () {},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: GridView.builder(
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 2.h,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    height: 10,
                    width: 40.w,
                    color: Colors.white,
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    height: 10,
                    width: 30.w,
                    color: Colors.white,
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    height: 10,
                    width: 25.w,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

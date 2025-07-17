// search_result_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/recommended_destination_widget.dart';
import '../widgets/recent_trip_card_widget.dart';

class SearchResultScreen extends StatelessWidget {
  final String query;
  const SearchResultScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final lowerQuery = query.toLowerCase();

    return Scaffold(
      appBar: AppBar(title: Text('Search Results: "$query"')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Trips",
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('trips').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final results = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title =
                        (data['title'] ?? '').toString().toLowerCase();
                    final dest =
                        (data['destination'] ?? '').toString().toLowerCase();
                    return title.contains(lowerQuery) ||
                        dest.contains(lowerQuery);
                  }).toList();

                  if (results.isEmpty)
                    return const Text("No matching trips found");

                  return ListView.builder(
                    itemCount: results.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final trip =
                          results[index].data() as Map<String, dynamic>;
                      trip['id'] = results[index].id;
                      return RecentTripCardWidget(
                        title: trip['title'] ?? '',
                        destination: trip['destination'] ?? '',
                        imageUrl: trip['image'] ?? '',
                        date: trip['date']?.toString() ?? '',
                        rating: trip['rating'] is num
                            ? (trip['rating'] as num).toDouble()
                            : 0.0,
                        highlights: trip['highlights'] is List
                            ? List<String>.from(trip['highlights'])
                            : [],
                        onTap: () => Navigator.pushNamed(
                            context, '/trip-detail',
                            arguments: trip),
                        onShare: () {},
                        onEdit: () {},
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 4.h),
              Text("Destinations",
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('destinations')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final results = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final subtitle =
                        (data['subtitle'] ?? '').toString().toLowerCase();
                    return name.contains(lowerQuery) ||
                        subtitle.contains(lowerQuery);
                  }).toList();

                  if (results.isEmpty)
                    return const Text("No matching destinations found");

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: results.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final data =
                          results[index].data() as Map<String, dynamic>;
                      return RecommendedDestinationWidget(
                        name: data['name'] ?? '',
                        imageUrl: data['image'] ?? '',
                        price: data['price'] ?? '',
                        rating: data['rating'] is num
                            ? (data['rating'] as num).toDouble()
                            : 0.0,
                        duration: data['duration'] ?? '',
                        category: data['category'] ?? '',
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/home-detail',
                          arguments: results[index].id,
                        ),
                        isSaved: false,
                        onFavoriteToggle: () {},
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/recommended_destination_widget.dart';
import '../widgets/recent_trip_card_widget.dart';

class SearchResultScreen extends StatefulWidget {
  final String query;
  const SearchResultScreen({super.key, required this.query});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  Stream<List<String>> fetchSavedDestinationIds(String userId) {
    return FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(userId)
        .collection('saved_destinations')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<void> _toggleFavorite(
      String userId, String destinationId, bool isSaved) async {
    final ref = FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(userId)
        .collection('saved_destinations')
        .doc(destinationId);

    if (isSaved) {
      await ref.delete();
    } else {
      await ref.set({'saved_at': FieldValue.serverTimestamp()});
    }

    // 🔁 Force rebuild after toggle
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lowerQuery = widget.query.toLowerCase();
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Search Results: "${widget.query}"')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Trips", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('trips').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final results = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    final dest = (data['destination'] ?? '').toString().toLowerCase();
                    return title.contains(lowerQuery) || dest.contains(lowerQuery);
                  }).toList();

                  if (results.isEmpty) return const Text("No matching trips found");

                  return ListView.builder(
                    itemCount: results.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final trip = results[index].data() as Map<String, dynamic>;
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
                          context,
                          '/trip-detail',
                          arguments: trip,
                        ),
                        onShare: () {},
                        onEdit: () {},
                      );
                    },
                  );
                },
              ),

              SizedBox(height: 4.h),

              Text("Destinations", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),

              if (userId == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text("Login required to save destinations."),
                )
              else
                StreamBuilder<List<String>>(
                  stream: fetchSavedDestinationIds(userId),
                  builder: (context, savedSnapshot) {
                    final savedIds = savedSnapshot.data ?? [];

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('destinations')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();

                        final results = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? '').toString().toLowerCase();
                          final subtitle = (data['subtitle'] ?? '').toString().toLowerCase();
                          return name.contains(lowerQuery) || subtitle.contains(lowerQuery);
                        }).toList();

                        if (results.isEmpty) return const Text("No matching destinations found");

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
                            final doc = results[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final destinationId = doc.id;
                            final isSaved = savedIds.contains(destinationId);

                            return RecommendedDestinationWidget(
                              key: ValueKey(destinationId),
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
                                arguments: destinationId,
                              ),
                              isSaved: isSaved,
                              onFavoriteToggle: () =>
                                  _toggleFavorite(userId, destinationId, isSaved),
                            );
                          },
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

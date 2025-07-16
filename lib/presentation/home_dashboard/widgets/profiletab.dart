import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/TripDetailScreen.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/tripedit.dart';
import 'package:travelmate/routes/app_routes.dart';
import 'package:travelmate/theme/app_theme.dart';
import 'package:travelmate/services/firebase_auth_service.dart';

class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final String userDisplayName;
  final String? userPhotoURL;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.userDisplayName,
    this.userPhotoURL,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userDisplayName: data['userDisplayName'] ?? '',
      userPhotoURL: data['userPhotoURL'],
    );
  }
}

Future<int> fetchTripCount(User? user) async {
  if (user == null) return 0;

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('trips')
        .where('user_id', isEqualTo: user.uid)
        .get();

    return snapshot.docs.length;
  } catch (e) {
    debugPrint('🔥 Error fetching trip count: $e');
    return 0;
  }
}


Stream<List<Map<String, dynamic>>> fetchUserTrips(User? user) {
  if (user == null) {
    return Stream.value([]);
  }

  final tripsRef = FirebaseFirestore.instance
      .collection('trips')
      .where('user_id', isEqualTo: user.uid)
      .orderBy('date', descending: true);

  return tripsRef.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final createdAt = data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now();

      final formattedDate =
          "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";

      final image = (data['media_url']?.toString().isNotEmpty ?? false)
          ? data['media_url']
          : (data['heroImage']?.toString().isNotEmpty ?? false)
              ? data['heroImage']
              : (data['image']?.toString().isNotEmpty ?? false)
                  ? data['image']
                  : null;

      // highlights-г шалгаж баталгаажуулж байна
      List<String> highlights = [];
      if (data['highlights'] is List) {
        highlights = List<String>.from(
          (data['highlights'] as List).whereType<String>(),
        );
      }

      return {
        'id': doc.id,
        'title': data['title'] ?? 'Untitled',
        'destination': data['destination'] ?? 'Unknown',
        'image': image,
        'date': formattedDate,
        'status': data['status'] ?? 'Upcoming',
        'rating': (data['rating'] is num) ? data['rating'].toDouble() : 0.0,
        'highlights': highlights,
        'user_id': data['user_id'] ?? '',
      };
    }).toList();
  }).handleError((e, stackTrace) {
    debugPrint("🔥 [Trips Stream Error]: $e");
    return [];
  });
}

Widget buildProfileTab(BuildContext context, User? currentUser) {
  if (currentUser == null) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            "No user logged in",
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  return SliverToBoxAdapter(
    child: Column(
      children: [
        // 🔷 Profile Header
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 255, 255),
                Color.fromARGB(255, 190, 190, 190),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 178, 178, 178).withOpacity(0.2),
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Column(
              children: [
                // 👤 Avatar
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: currentUser.photoURL != null
                      ? NetworkImage(currentUser.photoURL!)
                      : null,
                  child: currentUser.photoURL == null
                      ? Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                SizedBox(height: 1.h),

                // 👑 Name
                Text(
                  currentUser.displayName ?? 'Guest User',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  currentUser.email ?? 'No email',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                ),

                SizedBox(height: 3.h),

                // 📊 Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTripStat(currentUser),
                    _buildStat("Saved", "0"),
                    _buildLogoutStat(context),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 🔸 My Trips Title
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Trips",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
            ],
          ),
        ),

        // 🔹 Trip List Section
        _buildUserTripsSection(currentUser),
      ],
    ),
  );
}


Widget _buildTripStat(User? user) {
  return FutureBuilder<int>(
    future: fetchTripCount(user),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildStat("Trips", "...");
      }

      if (snapshot.hasError) {
        debugPrint("🔥 Error in FutureBuilder: ${snapshot.error}");
        return _buildStat("Trips", "0");
      }

      final count = snapshot.data ?? 0;
      return _buildStat("Trips", count.toString());
    },
  );
}



Widget _buildLogoutStat(BuildContext context) {
  return GestureDetector(
    onTap: () async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Log Out"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Log Out"),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final auth = FirebaseAuthService();
        await auth.signOut();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/user-login', (route) => false);
        }
      }
    },
    child: Column(
      children: [
        Icon(Icons.logout, color: Colors.red, size: 24),
        SizedBox(height: 0.5.h),
        Text("Log Out", style: TextStyle(color: Colors.red, fontSize: 10.sp)),
      ],
    ),
  );
}

Widget _buildStat(String label, String count) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        count.isNotEmpty ? count : '0',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16.sp,
          color: Colors.black,
        ),
      ),
      SizedBox(height: 0.5.h),
      Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: Colors.grey[600] ?? Colors.grey,
        ),
      ),
    ],
  );
}

Widget _buildUserTripsSection(User? user) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 1.h),

      StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchUserTrips(user),
        builder: (context, snapshot) {
          // 🔄 Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 2.h),
                    Text("Аяллуудыг ачааллаж байна...", style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
              ),
            );
          }

          // ❌ Error state
          if (snapshot.hasError) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 12.w, color: Colors.red),
                    SizedBox(height: 2.h),
                    Text("Алдаа гарлаа. Сүлжээг шалгана уу.",
                        style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
              ),
            );
          }

          // 📭 No data state
          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.travel_explore, size: 12.w, color: Colors.grey),
                    SizedBox(height: 2.h),
                    Text(
                      "Одоогоор нэмсэн аялал алга байна.",
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      "Доорх ➕ товчоор аялал нэмээрэй.",
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // ✅ Data exists → display trips
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: trip['image'] != null && trip['image'].toString().isNotEmpty
                        ? Image.network(
                            trip['image'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/no-image.jpg',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/no-image.jpg',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                  ),
                  title: Text(trip['title']),
                  subtitle: Text("${trip['destination']} • ${trip['date']}"),
                  trailing: trip['user_id'] == FirebaseAuth.instance.currentUser?.uid
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TripEditScreen(
                                      trip: trip,
                                      tripId: trip['id'],
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Trip"),
                                    content: const Text("Are you sure you want to delete this trip?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('trips')
                                      .doc(trip['id'])
                                      .delete();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Trip deleted successfully"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        )
                      : null,
                  onTap: () {
                    final tripId = trip['id']?.toString();
                    if (tripId != null && tripId.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.tripDetail,
                        arguments: trip,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('empty.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    ],
  );
}


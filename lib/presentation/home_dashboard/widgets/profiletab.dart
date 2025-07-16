import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/TripDetailScreen.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/profiletrips.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/tripedit.dart';
import 'package:travelmate/routes/app_routes.dart';
import 'package:travelmate/theme/app_theme.dart';
import 'package:travelmate/services/firebase_auth_service.dart';
import 'package:shimmer/shimmer.dart';

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
bool _initialLoadDone = false;
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
  if (user == null || user.uid.isEmpty) {
    debugPrint("⚠️ fetchUserTrips: хэрэглэгч алга.");
    return Stream.value([]);
  }

  try {
    // Remove orderBy to avoid filtering out documents without 'date' field
    final tripsRef = FirebaseFirestore.instance
        .collection('trips')
        .where('user_id', isEqualTo: user.uid);

    return tripsRef.snapshots().map((snapshot) {
      debugPrint("📥 Realtime trips received: ${snapshot.docs.length}");
      
      final tripsList = snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Handle different date field possibilities
        DateTime createdAt;
        if (data['date'] is Timestamp) {
          createdAt = (data['date'] as Timestamp).toDate();
        } else if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['created_at'] is Timestamp) {
          createdAt = (data['created_at'] as Timestamp).toDate();
        } else {
          createdAt = DateTime.now();
        }

        final formattedDate = 
            "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";

        // Image handling with multiple fallbacks
        final image = data['media_url']?.toString().isNotEmpty == true
            ? data['media_url']
            : data['heroImage']?.toString().isNotEmpty == true
                ? data['heroImage']
                : data['image']?.toString().isNotEmpty == true
                    ? data['image']
                    : null;

        // Highlights handling
        final highlights = (data['highlights'] is List)
            ? List<String>.from(
                (data['highlights'] as List).whereType<String>(),
              )
            : <String>[];

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
          'createdAt': createdAt, // Keep original DateTime for sorting
        };
      }).toList();

      // Sort by date in Dart instead of Firestore to avoid filtering issues
      tripsList.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      
      // Remove the createdAt field from final result to match your original structure
      return tripsList.map((trip) {
        final Map<String, dynamic> result = Map.from(trip);
        result.remove('createdAt');
        return result;
      }).toList();

    }).handleError((e, stackTrace) {
      debugPrint("🔥 [fetchUserTrips Stream алдаа]: $e");
      debugPrint("Stack trace: $stackTrace");
      return <Map<String, dynamic>>[];
    });

  } catch (e, stackTrace) {
    debugPrint("❌ [fetchUserTrips try-catch алдаа]: $e");
    debugPrint("Stack trace: $stackTrace");
    return Stream.value([]);
  }
}

Widget buildProfileTab(BuildContext context, User? currentUser) {
  if (currentUser == null || currentUser.uid.isEmpty) {
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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
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

        // 🔸 My Trips Section (only if user exists)
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
        ProfileTripsSection(user: currentUser),
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


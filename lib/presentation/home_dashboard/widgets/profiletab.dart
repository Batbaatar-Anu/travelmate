import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/profiletrips.dart';
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

Future<int> fetchSavedCount(User? user) async {
  if (user == null) return 0;

  try {
    final savedSnap = await FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(user.uid)
        .collection('saved_destinations')
        .get();

    return savedSnap.size;
  } catch (e) {
    debugPrint('🔥 Error fetching saved count: $e');
    return 0;
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
  if (user == null || user.uid.isEmpty) {
    debugPrint("⚠️ fetchUserTrips: хэрэглэгч алга.");
    return Stream.value([]);
  }

  try {
    final tripsRef = FirebaseFirestore.instance
        .collection('trips')
        .where('user_id', isEqualTo: user.uid);

    return tripsRef.snapshots().map((snapshot) {
      final tripsList = snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime createdAt = DateTime.now();

        if (data['date'] is Timestamp) {
          createdAt = (data['date'] as Timestamp).toDate();
        } else if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['created_at'] is Timestamp) {
          createdAt = (data['created_at'] as Timestamp).toDate();
        }

        final formattedDate =
            "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";

        final image = data['media_url']?.toString().isNotEmpty == true
            ? data['media_url']
            : data['heroImage']?.toString().isNotEmpty == true
                ? data['heroImage']
                : data['image']?.toString().isNotEmpty == true
                    ? data['image']
                    : null;

        final highlights = (data['highlights'] is List)
            ? List<String>.from(
                (data['highlights'] as List).whereType<String>())
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
          'createdAt': createdAt,
        };
      }).toList();

      tripsList.sort((a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

      return tripsList.map((trip) {
        final result = Map<String, dynamic>.from(trip);
        result.remove('createdAt');
        return result;
      }).toList();
    }).handleError((e, stackTrace) {
      debugPrint("🔥 [fetchUserTrips Stream алдаа]: $e");
      return <Map<String, dynamic>>[];
    });
  } catch (e) {
    debugPrint("❌ [fetchUserTrips try-catch алдаа]: $e");
    return Stream.value([]);
  }
}

Widget buildProfileTab(BuildContext context, User? currentUser) {
  if (currentUser == null || currentUser.uid.isEmpty) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text("No user logged in",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
        ),
      ),
    );
  }

  return SliverToBoxAdapter(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFBEBEBE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFB2B2B2).withOpacity(0.2),
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Column(
              children: [
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
                Text(currentUser.displayName ?? 'Guest User',
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text(currentUser.email ?? 'No email',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[700])),
                SizedBox(height: 3.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTripStat(currentUser),
                    _buildSavedStat(currentUser),
                    _buildLogoutStat(context),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Trips",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
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
        return _buildStat("Trips", "0");
      }
      return _buildStat("Trips", snapshot.data?.toString() ?? "0");
    },
  );
}

Widget _buildSavedStat(User? user) {
  return FutureBuilder<int>(
    future: fetchSavedCount(user),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildStat("Saved", "...");
      }
      if (snapshot.hasError) {
        return _buildStat("Saved", "0");
      }
      return _buildStat("Saved", snapshot.data?.toString() ?? "0");
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
                child: Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text("Log Out")),
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
      Text(count,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.black)),
      SizedBox(height: 0.5.h),
      Text(label,
          style: TextStyle(
              fontSize: 10.sp, color: Colors.grey[600] ?? Colors.grey)),
    ],
  );
}

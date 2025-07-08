import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/tripedit.dart';
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

// Future<List<Map<String, dynamic>>> fetchUserTrips(User? user) async {
//   if (user == null) return [];

//   try {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('trips')
//         .where('user_id', isEqualTo: user.uid)
//         .orderBy('created_at', descending: true)
//         .get();

//     return snapshot.docs.map((doc) {
//       final data = doc.data();
//       final Timestamp createdAt = data['created_at'] ?? Timestamp.now();
//       final createdDate = createdAt.toDate();
//       final formattedDate =
//           "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";

//       final image = (data['media_url']?.toString().isNotEmpty ?? false)
//           ? data['media_url']
//           : (data['heroImage']?.toString().isNotEmpty ?? false)
//               ? data['heroImage']
//               : null;

//       return {
//         'id': doc.id,
//         'title': data['title'] ?? 'Untitled',
//         'destination': data['destination'] ?? 'Unknown',
//         'image': image,
//         'date': formattedDate,
//         'status': data['status'] ?? 'Upcoming',
//         'rating': data['rating']?.toDouble() ?? 0.0,
//         'highlights': List<String>.from(data['highlights'] ?? []),
//       };
//     }).toList();
//   } catch (e) {
//     debugPrint('🔥 Error fetching user trips: $e');
//     return [];
//   }
// }
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
    return Stream.value(
        []); // Return an empty list as a stream if no user is found
  }

  try {
    // Listen to the 'trips' collection where 'user_id' equals to the current user's UID
    return FirebaseFirestore.instance
        .collection('trips')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at',
            descending: true) // Order by creation date in descending order
        .snapshots() // Use snapshots() to listen to real-time updates
        .map((snapshot) {
      // Map each document to a Map<String, dynamic>
      return snapshot.docs.map((doc) {
        final data = doc.data(); // Get document data

        // Extract and format the 'created_at' timestamp
        final Timestamp createdAt = data['created_at'] ??
            Timestamp.now(); // Default to current time if missing
        final createdDate = createdAt.toDate(); // Convert to DateTime
        final formattedDate =
            "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}"; // Format the date

        // Determine the image URL
        final image = (data['media_url']?.toString().isNotEmpty ?? false)
            ? data['media_url']
            : (data['heroImage']?.toString().isNotEmpty ?? false)
                ? data['heroImage']
                : null; // Use media_url first, otherwise fallback to heroImage

        // Return the data as a map
        return {
          'id': doc.id, // Document ID
          'title':
              data['title'] ?? 'Untitled', // Title or default to 'Untitled'
          'destination': data['destination'] ??
              'Unknown', // Destination or default to 'Unknown'
          'image': image, // Image URL
          'date': formattedDate, // Formatted date
          'status':
              data['status'] ?? 'Upcoming', // Status or default to 'Upcoming'
          'rating': data['rating']?.toDouble() ?? 0.0, // Rating, default to 0.0
          'highlights': List<String>.from(
              data['highlights'] ?? []), // Highlights as a list of strings
        };
      }).toList(); // Convert the documents to a list of maps
    });
  } catch (e) {
    debugPrint('🔥 Error fetching user trips: $e'); // Error handling
    return Stream.value([]); // Return an empty list in case of error
  }
}

Widget buildProfileTab(BuildContext context, User? currentUser) {
  return SliverToBoxAdapter(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 255, 255), // цайвар мөнгөлөг
                Color.fromARGB(255, 190, 190, 190), // бараан мөнгөлөг
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
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
                  backgroundImage: currentUser?.photoURL != null
                      ? NetworkImage(currentUser!.photoURL!)
                      : null,
                  child: currentUser?.photoURL == null
                      ? Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                SizedBox(height: 1.h),

                // 👑 Name
                Text(
                  currentUser?.displayName ?? 'Guest User',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  currentUser?.email ?? 'No email',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                ),

                SizedBox(height: 3.h),
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
        SizedBox(height: 2.h),

        // 🧳 My Trips Title
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

        // 🧳 Trip Grid
        _buildUserTripsSection(currentUser),
      ],
    ),
  );
}

Widget _buildTripStat(User? user) {
  return FutureBuilder<int>(
    future: fetchTripCount(user),
    builder: (context, snapshot) {
      final count = snapshot.data?.toString() ?? '0';
      return _buildStat("Trips", count);
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
    children: [
      Text(count,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10.sp)),
    ],
  );
}

// Widget _buildUserInfoSection(User? currentUser) {
//   return Card(
//     elevation: 2,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     child: ListTile(
//       contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
//       leading: CircleAvatar(
//         radius: 24,
//         backgroundColor: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
//         backgroundImage: currentUser?.photoURL != null
//             ? NetworkImage(currentUser!.photoURL!)
//             : null,
//         child: currentUser?.photoURL == null
//             ? Icon(Icons.person,
//                 size: 24, color: AppTheme.lightTheme.primaryColor)
//             : null,
//       ),
//       title: Text(
//         currentUser?.displayName ?? 'Guest User',
//         style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       subtitle: Text(
//         currentUser?.email ?? 'No email',
//         style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
//           color: Colors.grey[600],
//         ),
//       ),
//     ),
//   );
// }

Widget _buildUserTripsSection(User? user) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 1.h),

      // StreamBuilder to fetch and display user trips
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchUserTrips(user), // Pass in the currentUser
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text("Error loading trips"));
          }

          // Handle empty trips list
          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(4.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.travel_explore, size: 12.w, color: Colors.grey),
                    SizedBox(height: 2.h),
                    Text("No trips yet"),
                  ],
                ),
              ),
            );
          }

          // Display the trips
          return ListView.builder(
            shrinkWrap: true, // Makes the list take the required space
            physics: NeverScrollableScrollPhysics(), // Prevent scrolling
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: trip['image'] != null &&
                            trip['image'].toString().isNotEmpty
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
                  onTap: () {
                    // Navigate to Trip Detail screen when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailScreen(trip: trip),
                      ),
                    );
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

// Widget _buildLogoutSection(BuildContext context) {
//   return Card(
//     elevation: 2,
//     child: ListTile(
//       leading: Icon(Icons.logout, color: Colors.red),
//       title: Text("Log Out", style: TextStyle(color: Colors.red)),
//       onTap: () async {
//         final confirm = await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text("Log Out"),
//             content: Text("Are you sure you want to log out?"),
//             actions: [
//               TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: Text("Cancel")),
//               ElevatedButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   child: Text("Log Out")),
//             ],
//           ),
//         );

//         if (confirm == true) {
//           final auth = FirebaseAuthService();
//           await auth.signOut();
//           if (context.mounted) {
//             Navigator.pushNamedAndRemoveUntil(
//                 context, '/user-login', (route) => false);
//           }
//         }
//       },
//     ),
//   );
// }

class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Image Background
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Trip Image
                  trip['image'] != null
                      ? Image.network(
                          trip['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/no-image.jpg',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/no-image.jpg',
                          fit: BoxFit.cover,
                        ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Title Overlay
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 80,
                    child: Text(
                      trip['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Edit Button
              Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.black87),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripEditScreen(
                          tripId: trip['id'],
                          trip: trip,
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              // Delete Button
              Container(
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete Trip"),
                          ],
                        ),
                        content: Text(
                          "Are you sure you want to delete this trip? This action cannot be undone.",
                          style: TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text("Delete"),
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
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          // Trip Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.location_on,
                          label: "Destination",
                          value: trip['destination'],
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.calendar_today,
                          label: "Date",
                          value: trip['date'],
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Status Card
                  _buildStatusCard(),
                  SizedBox(height: 3.h),
                  if (trip['description'] != null &&
                      trip['description'].toString().trim().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          trip['description'] ??
                              'No description available', // Default text if empty
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],
                    ),

                  // Highlights Section
                  _buildHighlightsSection(),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    switch (trip['status'].toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'ongoing':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'upcoming':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status",
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                trip['status'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.purple, size: 24),
                SizedBox(width: 12),
                Text(
                  "Trip Highlights",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: trip['highlights']
                  .map<Widget>((highlight) => Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                highlight,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

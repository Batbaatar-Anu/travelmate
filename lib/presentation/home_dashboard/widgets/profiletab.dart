import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
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

Future<List<Map<String, dynamic>>> fetchUserTrips(User? user) async {
  if (user == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('trips')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final Timestamp createdAt = data['created_at'] ?? Timestamp.now();
      final createdDate = createdAt.toDate();
      final formattedDate =
          "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";

      final image = (data['media_url']?.toString().isNotEmpty ?? false)
          ? data['media_url']
          : (data['heroImage']?.toString().isNotEmpty ?? false)
              ? data['heroImage']
              : null;

      return {
        'id': doc.id,
        'title': data['title'] ?? 'Untitled',
        'destination': data['destination'] ?? 'Unknown',
        'image': image,
        'date': formattedDate,
        'status': data['status'] ?? 'Upcoming',
        'rating': data['rating']?.toDouble() ?? 0.0,
        'highlights': List<String>.from(data['highlights'] ?? []),
      };
    }).toList();
  } catch (e) {
    debugPrint('🔥 Error fetching user trips: $e');
    return [];
  }
}

Widget buildProfileTab(BuildContext context, User? currentUser) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Profile",
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildUserInfoSection(currentUser),
          SizedBox(height: 3.h),
          _buildUserTripsSection(currentUser),
          SizedBox(height: 3.h),
          _buildLogoutSection(context),
        ],
      ),
    ),
  );
}

Widget _buildUserInfoSection(User? currentUser) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
        backgroundImage: currentUser?.photoURL != null
            ? NetworkImage(currentUser!.photoURL!)
            : null,
        child: currentUser?.photoURL == null
            ? Icon(Icons.person,
                size: 24, color: AppTheme.lightTheme.primaryColor)
            : null,
      ),
      title: Text(
        currentUser?.displayName ?? 'Guest User',
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        currentUser?.email ?? 'No email',
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
        ),
      ),
    ),
  );
}

Widget _buildUserTripsSection(User? user) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "My Trips",
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 1.h),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUserTrips(user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text("Error loading trips");
          }

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

Widget _buildLogoutSection(BuildContext context) {
  return Card(
    elevation: 2,
    child: ListTile(
      leading: Icon(Icons.logout, color: Colors.red),
      title: Text("Log Out", style: TextStyle(color: Colors.red)),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Log Out"),
            content: Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
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
    ),
  );
}

Future<int> _getUserPostsCount(User? user) async {
  if (user == null) return 0;
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: user.uid)
        .get();
    return snapshot.docs.length;
  } catch (e) {
    return 0;
  }
}

Stream<List<Post>> _getUserPostsStream(User? user) {
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('posts')
      .where('userId', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Post.fromFirestore(doc)).toList());
}

class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(trip['title']),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
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

              // Хэрвээ амжилттай хадгалагдсан бол profile таб руу буцна
              if (result == true && context.mounted) {
                Navigator.pop(context); // Back to previous screen
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text("Delete Trip"),
                  content: Text("Are you sure you want to delete this trip?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
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
                  Navigator.pop(context); // Back after delete
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            trip['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      trip['image'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/no-image.jpg',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/no-image.jpg',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
            SizedBox(height: 2.h),
            Text(
              trip['title'],
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Destination: ${trip['destination']}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text("Date: ${trip['date']}"),
            Text("Status: ${trip['status']}"),
            SizedBox(height: 1.h),
            Text(
              "Highlights:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...trip['highlights'].map<Widget>((h) => Text("- $h")).toList(),
          ],
        ),
      ),
    );
  }
}

class TripEditScreen extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;

  const TripEditScreen({super.key, required this.tripId, required this.trip});

  @override
  State<TripEditScreen> createState() => _TripEditScreenState();
}

class _TripEditScreenState extends State<TripEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _destinationController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip['title']);
    _destinationController =
        TextEditingController(text: widget.trip['destination']);
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'title': _titleController.text.trim(),
        'destination': _destinationController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (context.mounted)
        Navigator.pop(context, true); // return true on success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Trip")),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Trip Title"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter a title" : null,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: "Destination"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter a destination" : null,
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

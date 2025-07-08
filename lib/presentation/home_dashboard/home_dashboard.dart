import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/profiletab.dart';
import 'package:travelmate/services/firebase_auth_service.dart';
import '../../core/app_export.dart';
import './widgets/recent_trip_card_widget.dart';
import './widgets/recommended_destination_widget.dart';
// import './widgets/travel_tip_card_widget.dart';
import './widgets/trip_countdown_widget.dart';
// import './widgets/upcoming_reminder_widget.dart';
import './widgets/weather_widget.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  bool _isRefreshing = false;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  User? _currentUser;
  Map<String, dynamic>? _currentUserProfile;
  Set<String> savedDestinationIds = {};

  // Mock data for travel dashboard
  List<Map<String, dynamic>> postedTrips = [];
  // final List<Map<String, dynamic>> recentTrips = [
  //   {
  //     "id": 1,
  //     "destination": "Paris, France",
  //     "image":
  //         "https://images.pexels.com/photos/338515/pexels-photo-338515.jpeg",
  //     "date": "Dec 15-22, 2023",
  //     "status": "Completed",
  //     "rating": 4.8,
  //     "highlights": ["Eiffel Tower", "Louvre Museum", "Seine River Cruise"]
  //   },
  //   {
  //     "id": 2,
  //     "destination": "Tokyo, Japan",
  //     "image":
  //         "https://images.pexels.com/photos/2506923/pexels-photo-2506923.jpeg",
  //     "date": "Jan 10-18, 2024",
  //     "status": "Completed",
  //     "rating": 4.9,
  //     "highlights": ["Shibuya Crossing", "Mount Fuji", "Cherry Blossoms"]
  //   },
  //   {
  //     "id": 3,
  //     "destination": "Bali, Indonesia",
  //     "image":
  //         "https://images.pexels.com/photos/2474690/pexels-photo-2474690.jpeg",
  //     "date": "Mar 5-12, 2024",
  //     "status": "Upcoming",
  //     "rating": 0.0,
  //     "highlights": ["Beach Resorts", "Temple Tours", "Rice Terraces"]
  //   }
  // ];

  // final List<Map<String, dynamic>> recommendedDestinations = [
  //   {
  //     "id": 1,
  //     "name": "Santorini, Greece",
  //     "image":
  //         "https://images.pexels.com/photos/1285625/pexels-photo-1285625.jpeg",
  //     "price": "\$1,299",
  //     "rating": 4.7,
  //     "duration": "7 days",
  //     "category": "Beach & Culture"
  //   },
  //   {
  //     "id": 2,
  //     "name": "Swiss Alps",
  //     "image":
  //         "https://images.pexels.com/photos/417074/pexels-photo-417074.jpeg",
  //     "price": "\$1,899",
  //     "rating": 4.9,
  //     "duration": "10 days",
  //     "category": "Adventure"
  //   },
  //   {
  //     "id": 3,
  //     "name": "Dubai, UAE",
  //     "image":
  //         "https://images.pexels.com/photos/1470405/pexels-photo-1470405.jpeg",
  //     "price": "\$999",
  //     "rating": 4.6,
  //     "duration": "5 days",
  //     "category": "Luxury"
  //   },
  //   {
  //     "id": 4,
  //     "name": "Iceland",
  //     "image":
  //         "https://images.pexels.com/photos/1433052/pexels-photo-1433052.jpeg",
  //     "price": "\$1,599",
  //     "rating": 4.8,
  //     "duration": "8 days",
  //     "category": "Nature"
  //   }
  // ];

  // final List<Map<String, dynamic>> travelTips = [
  //   {
  //     "id": 1,
  //     "title": "10 Essential Packing Tips for International Travel",
  //     "image":
  //         "https://images.pexels.com/photos/1008155/pexels-photo-1008155.jpeg",
  //     "readTime": "5 min read",
  //     "category": "Packing",
  //     "excerpt": "Master the art of efficient packing with these expert tips..."
  //   },
  //   {
  //     "id": 2,
  //     "title": "Budget Travel: How to See the World for Less",
  //     "image":
  //         "https://images.pexels.com/photos/1010657/pexels-photo-1010657.jpeg",
  //     "readTime": "8 min read",
  //     "category": "Budget",
  //     "excerpt":
  //         "Discover proven strategies to travel more while spending less..."
  //   },
  //   {
  //     "id": 3,
  //     "title": "Solo Female Travel Safety Guide",
  //     "image":
  //         "https://images.pexels.com/photos/1371360/pexels-photo-1371360.jpeg",
  //     "readTime": "6 min read",
  //     "category": "Safety",
  //     "excerpt": "Essential safety tips for confident solo female travelers..."
  //   }
  // ];

  // final List<Map<String, dynamic>> upcomingReminders = [
  //   {
  //     "id": 1,
  //     "title": "Flight Check-in",
  //     "subtitle": "Bali Trip - Check in opens in 2 hours",
  //     "time": "2 hours",
  //     "type": "flight",
  //     "priority": "high"
  //   },
  //   {
  //     "id": 2,
  //     "title": "Passport Renewal",
  //     "subtitle": "Expires in 6 months - Renew now",
  //     "time": "6 months",
  //     "type": "document",
  //     "priority": "medium"
  //   },
  //   {
  //     "id": 3,
  //     "title": "Travel Insurance",
  //     "subtitle": "Purchase for upcoming Bali trip",
  //     "time": "3 days",
  //     "type": "insurance",
  //     "priority": "high"
  //   }
  // ];

  List<Map<String, dynamic>> recommendedDestinations = [];
  Future<void> markAllNotificationsAsRead(String userId) async {
    final userNotificationsRef = FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(userId)
        .collection('notifications');

    final unreadSnapshot =
        await userNotificationsRef.where('isRead', isEqualTo: false).get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> fetchRecommendedDestinations() {
    return FirebaseFirestore.instance
        .collection('destinations')
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'image':
              (data['image'] != null && data['image'].toString().isNotEmpty)
                  ? data['image']
                  : 'https://via.placeholder.com/300',
          'price': data['price'] ?? '',
          'rating': (data['rating'] ?? 0.0).toDouble(),
          'duration': data['duration'] ?? '',
          'category': data['category'] ?? '',
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> fetchDestinationsByCategory(
      String category) {
    return FirebaseFirestore.instance
        .collection('destinations')
        .where('category', isEqualTo: category)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'image':
              (data['image'] != null && data['image'].toString().isNotEmpty)
                  ? data['image']
                  : 'https://via.placeholder.com/300',
          'price': data['price'] ?? '',
          'rating': (data['rating'] ?? 0.0).toDouble(),
          'duration': data['duration'] ?? '',
          'category': data['category'] ?? '',
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> fetchSavedDestinations(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_destinations')
        .snapshots()
        .asyncMap((snapshot) async {
      final destinationIds = snapshot.docs.map((doc) => doc.id).toList();

      if (destinationIds.isEmpty) return [];

      final futures = destinationIds.map(
        (id) =>
            FirebaseFirestore.instance.collection('destinations').doc(id).get(),
      );

      final docs = await Future.wait(futures);

      return docs.where((doc) => doc.exists).map((doc) {
        final data = doc.data()!;
        return {
          'id': doc.id, // ✅ зөв: зөвхөн doc.id-г ашиглаж байна
          'name': data['name'],
          'image': data['image'],
          'price': data['price'],
          'rating': data['rating'],
          'duration': data['duration'],
          'category': data['category'],
          'subtitle': data['subtitle'],
          'description': data['description'],
          'photos': data['photos'],
          // ⚠️ Хэрвээ data['id'] байсан ч, энд оруулахгүй
        };
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getUserProfile();
    _fetchPostedTrips();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });

      // 👇 Listen to saved destinations
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_destinations')
          .snapshots()
          .listen((snapshot) {
        setState(() {
          savedDestinationIds = snapshot.docs.map((doc) => doc.id).toSet();
        });
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Future<void> _xAfetchPostedTrips() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     // 🛠️ get() үр дүнгээ хадгалж байна
  //     final snapshot = await FirebaseFirestore.instance
  //         .collection('trips')
  //         .where('user_id', isEqualTo: user.uid)
  //         .orderBy('created_at', descending: true)
  //         .get();

  //     setState(() {
  //       postedTrips = snapshot.docs.map((doc) {
  //         final data = doc.data();
  //         return {
  //           'id': doc.id,
  //           'destination': data['destination'] ?? '',
  //           'image': data['media_url'] ?? '',
  //           'date': _formatDateRange(data['start_date'], data['end_date']),
  //           'status': 'Upcoming',
  //           'rating': 0.0,
  //           'highlights': [],
  //         };
  //       }).toList();
  //     });
  //   }
  // }
  // Future<void> _fetchUserOwnTrips() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;

  //   try {
  //     final snapshot = await FirebaseFirestore.instance
  //         .collection('trips')
  //         .where('user_id', isEqualTo: user.uid)
  //         .orderBy('created_at', descending: true)
  //         .get();

  //     setState(() {
  //       postedTrips = snapshot.docs.map((doc) {
  //         final data = doc.data();
  //         final Timestamp createdAt = data['created_at'] ?? Timestamp.now();
  //         final createdDate = createdAt.toDate();

  //         final formattedDate =
  //             "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";

  //         return {
  //           'id': doc.id,
  //           'title': data['title'] ?? 'Untitled',
  //           'destination': data['destination'] ?? '',
  //           'image': (data['media_url'] ?? '').toString().isNotEmpty
  //               ? data['media_url']
  //               : 'https://via.placeholder.com/300',
  //           'date': formattedDate,
  //           'status': 'Upcoming',
  //           'rating': data['rating'] ?? 0.0,
  //           'highlights': List<String>.from(data['highlights'] ?? []),
  //         };
  //       }).toList();
  //     });
  //   } catch (e) {
  //     debugPrint('Error fetching user trips: $e');
  //   }
  // }

  Future<void> _fetchPostedTrips() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('trips')
        .orderBy('created_at', descending: true)
        .limit(10)
        .get();

    setState(() {
      postedTrips = snapshot.docs.map((doc) {
        final data = doc.data();
        final Timestamp createdAt = data['created_at'] ?? Timestamp.now();
        final createdDate = createdAt.toDate();

        final formattedDate =
            "${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}";

        return {
          'id': doc.id,
          'destination': data['destination'] ?? '',
          'title': data['title'] ?? 'Untitled Trip',
          'image': (data['media_url'] != null &&
                  data['media_url'].toString().isNotEmpty)
              ? data['media_url']
              : 'https://via.placeholder.com/300',
          'date': formattedDate,
          'status': 'Upcoming',
          'rating': data['rating'] ?? 0.0,
          'highlights': List<String>.from(data['highlights'] ?? []),
        };
      }).toList();
    });
  }

  void _toggleSaveDestination(String destinationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_destinations')
        .doc(destinationId);

    if (savedDestinationIds.contains(destinationId)) {
      await docRef.delete();
    } else {
      await docRef.set({
        'destination_id': destinationId,
        'saved_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> sendNotificationToAllUsers(String title, String message) async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('user_profiles').get();

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;

      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    // // Remove navigation from case 3
    // switch (index) {
    //   case 0:
    //     break;
    //   case 1:
    //     Navigator.pushNamed(context, '/home-detail');
    //     break;
    //   // case 2:
    //   //   Navigator.pushNamed(context, '/push-notification-settings');
    //   //   break;
    // }
  }

  Future<void> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user; // ✅ Make sure this is always set
      });

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _currentUserProfile = doc.data();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.lightTheme.primaryColor,
          child: CustomScrollView(
  controller: _scrollController,
  slivers: [
    if (_currentTabIndex != 2) _buildStickyHeader(),

    if (_currentTabIndex == 0) ...[
      _buildHeroSection(),
      _buildFilteredDestinationsSection(),
      _buildRecommendedDestinationsSection(),
      _buildRecentTripsSection(),
    ],
    if (_currentTabIndex == 1)
      _buildSavedDestinationsSection(_currentUser?.uid),
    if (_currentTabIndex == 2)
      buildProfileTab(context, _currentUser),

    SliverToBoxAdapter(child: SizedBox(height: 10.h)),
  ],
),

        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSavedDestinationsSection(String? userId) {
    if (userId == null) {
      return SliverToBoxAdapter(
        child: Center(child: Text('Please log in to see saved destinations')),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Saved Destinations",
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 2.h),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fetchSavedDestinations(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error loading saved destinations');
                }

                final savedDestinations = snapshot.data ?? [];

                if (savedDestinations.isEmpty) {
                  return Text('No saved destinations yet.');
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: savedDestinations.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 2.h,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final destination = savedDestinations[index];
                    return RecommendedDestinationWidget(
                      name: destination["name"] as String,
                      imageUrl: destination["image"] as String,
                      price: destination["price"] as String,
                      rating: destination["rating"] as double,
                      duration: destination["duration"] as String,
                      category: destination["category"] as String,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/home-detail',
                        arguments: destination['id'],
                      ),
                      isSaved:
                          savedDestinationIds.contains(destination['id']), // ✅
                      onFavoriteToggle: () =>
                          _toggleSaveDestination(destination['id']), // ✅
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// 🔁 StreamBuilder хэвээр байлгана
Widget _buildNotificationIcon() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const SizedBox.shrink();

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('user_profiles') // ✅ Зөв collection path
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildNotificationBaseIcon(); // loading үед badge байхгүй icon
      }

      final unreadCount = snapshot.data?.docs.length ?? 0;

      return GestureDetector(
        onTap: () async {
          // ✅ Mark all as read
          await markAllNotificationsAsRead(user.uid);

          // ✅ Navigate to notification detail screen
          if (context.mounted) {
            Navigator.pushNamed(context, '/push-notification-settings');
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildNotificationBaseIcon(),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  child: Center(
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

Widget _buildNotificationBaseIcon() {
  return Container(
    padding: EdgeInsets.all(2.w),
    decoration: BoxDecoration(
      color: AppTheme.lightTheme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: CustomIconWidget(
      iconName: 'notifications',
      color: AppTheme.lightTheme.primaryColor,
      size: 24,
    ),
  );
}


  Widget _buildStickyHeader() {
    final currentUser = FirebaseAuthService().currentUser;
    final displayName = currentUser?.displayName ?? 'Traveler';

    return SliverAppBar(
      automaticallyImplyLeading: false,
      floating: true,
      pinned: true,
      snap: false,
      elevation: 0,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      expandedHeight: 20.h,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello ${displayName} ",
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          "Дараагийн адал явдалдаа бэлэн үү?",
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Row(
                  //   children: [
                  //     WeatherWidget(),
                  //     SizedBox(width: 2.w),
                  //     GestureDetector(
                  //       onTap: () => Navigator.pushNamed(
                  //           context, '/push-notification-settings'),
                  //       child: Container(
                  //         padding: EdgeInsets.all(2.w),
                  //         decoration: BoxDecoration(
                  //           color: AppTheme.lightTheme.colorScheme.surface,
                  //           borderRadius: BorderRadius.circular(12),
                  //           boxShadow: [
                  //             BoxShadow(
                  //               color: Colors.black.withValues(alpha: 0.05),
                  //               blurRadius: 8,
                  //               offset: const Offset(0, 2),
                  //             ),
                  //           ],
                  //         ),
                  //         child: CustomIconWidget(
                  //           iconName: 'notifications',
                  //           color: AppTheme.lightTheme.primaryColor,
                  //           size: 24,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  Row(
                    children: [
                      WeatherWidget(),
                      SizedBox(width: 2.w),
                      _buildNotificationIcon(), // → badge бүхий icon энд
                    ],
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search destinations...",
          prefixIcon: CustomIconWidget(
            iconName: 'search',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        ),
        onTap: () => Navigator.pushNamed(context, ''),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: TripCountdownWidget(
          destination: "Bali, Indonesia",
          daysLeft: 15,
          imageUrl:
              "https://images.pexels.com/photos/2474690/pexels-photo-2474690.jpeg",
          onTap: () => Navigator.pushNamed(context, ''),
        ),
      ),
    );
  }

  Widget _buildRecentTripsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Trips",
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 2.h),

            // ✅ Auto height list (shrinkWrap)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: postedTrips.length,
              itemBuilder: (context, index) {
                final trip = postedTrips[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: RecentTripCardWidget(
                    title: trip['title'] ?? 'Untitled',
                    destination: trip['destination'] ?? '',
                    imageUrl: trip['image'] ?? '',
                    date: trip['date'] ?? '',
                    status: trip['status'] ?? 'Upcoming',
                    rating: trip['rating'] ?? 0.0,
                    highlights: trip['highlights'] ?? [],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '',
                        arguments: trip['id'],
                      );
                    },
                    onShare: () {},
                    onEdit: () {},
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredDestinationsSection() {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchDestinationsByCategory('tr'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final destinations = snapshot.data;

          if (destinations == null || destinations.isEmpty) {
            return const Center(child: Text('No destinations found.'));
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: destinations.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return RecommendedDestinationWidget(
                name: destination["name"] as String,
                imageUrl: destination["image"] as String,
                price: destination["price"] as String,
                rating: destination["rating"] as double,
                duration: destination["duration"] as String,
                category: destination["category"] as String,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/home-detail',
                  arguments: destination['id'],
                ),
                isSaved: savedDestinationIds.contains(destination['id']), // ✅
                onFavoriteToggle: () =>
                    _toggleSaveDestination(destination['id']), // ✅
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecommendedDestinationsSection() {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchRecommendedDestinations(), // 👈 stream ашиглаж байна
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading destinations"));
          }

          final destinations = snapshot.data ?? [];

          if (destinations.isEmpty) {
            return Center(child: Text("No destinations found"));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "Recommended Destinations",
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/all-destinations'),
                      child: Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 2.h,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    return RecommendedDestinationWidget(
                      name: destination["name"] as String,
                      imageUrl: destination["image"] as String,
                      price: destination["price"] as String,
                      rating: destination["rating"] as double,
                      duration: destination["duration"] as String,
                      category: destination["category"] as String,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/home-detail',
                        arguments: destination['id'],
                      ),
                      isSaved:
                          savedDestinationIds.contains(destination['id']), // ✅
                      onFavoriteToggle: () =>
                          _toggleSaveDestination(destination['id']), // ✅
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget _buildTravelTipsSection() {
  //   return SliverToBoxAdapter(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(height: 3.h),
  //         Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 4.w),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 "Travel Tips",
  //                 style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               TextButton(
  //                 onPressed: () => Navigator.pushNamed(context, '/home-detail'),
  //                 child: Text("View All"),
  //               ),
  //             ],
  //           ),
  //         ),
  //         SizedBox(height: 1.h),
  //         ListView.builder(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           padding: EdgeInsets.symmetric(horizontal: 4.w),
  //           itemCount: travelTips.length,
  //           itemBuilder: (context, index) {
  //             final tip = travelTips[index];
  //             return Container(
  //               margin: EdgeInsets.only(bottom: 2.h),
  //               child: TravelTipCardWidget(
  //                 title: tip["title"] as String,
  //                 imageUrl: tip["image"] as String,
  //                 readTime: tip["readTime"] as String,
  //                 category: tip["category"] as String,
  //                 excerpt: tip["excerpt"] as String,
  //                 onTap: () => Navigator.pushNamed(context, '/home-detail'),
  //               ),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildUpcomingRemindersSection() {
  //   return SliverToBoxAdapter(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(height: 3.h),
  //         Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 4.w),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 "Upcoming Reminders",
  //                 style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               TextButton(
  //                 onPressed: () => Navigator.pushNamed(
  //                     context, '/push-notification-settings'),
  //                 child: Text("View All"),
  //               ),
  //             ],
  //           ),
  //         ),
  //         SizedBox(height: 1.h),
  //         ListView.builder(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           padding: EdgeInsets.symmetric(horizontal: 4.w),
  //           itemCount:
  //               upcomingReminders.length > 2 ? 2 : upcomingReminders.length,
  //           itemBuilder: (context, index) {
  //             final reminder = upcomingReminders[index];
  //             return Container(
  //               margin: EdgeInsets.only(bottom: 1.h),
  //               child: UpcomingReminderWidget(
  //                 title: reminder["title"] as String,
  //                 subtitle: reminder["subtitle"] as String,
  //                 time: reminder["time"] as String,
  //                 type: reminder["type"] as String,
  //                 priority: reminder["priority"] as String,
  //                 onTap: () => Navigator.pushNamed(
  //                     context, '/push-notification-settings'),
  //               ),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8.0,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: _currentTabIndex == 0
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'explore',
            color: _currentTabIndex == 1
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Plan',
        ),
        // BottomNavigationBarItem(
        //   icon: CustomIconWidget(
        //     iconName: 'notifications',
        //     color: _currentTabIndex == 2
        //         ? AppTheme.lightTheme.primaryColor
        //         : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        //     size: 24,
        //   ),
        //   label: 'Notifications',
        // ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _currentTabIndex == 2
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/new-trip'),
      backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      foregroundColor: Colors.white,
      icon: CustomIconWidget(
        iconName: 'add',
        color: Colors.white,
        size: 24,
      ),
      label: Text(
        "New Trip",
        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // void _showShareDialog(String destination) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Share Trip"),
  //         content:
  //             Text("Share your amazing trip to $destination with friends!"),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text("Share"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _showEditDialog(String destination) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Edit Trip"),
  //         content: Text("Edit your trip details for $destination."),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               Navigator.pushNamed(context, '/home-detail');
  //             },
  //             child: Text("Edit"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}

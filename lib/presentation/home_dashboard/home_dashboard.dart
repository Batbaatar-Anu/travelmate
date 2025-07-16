import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
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
  String _currentCategory = 'All';
  // Mock data for travel dashboard
  List<Map<String, dynamic>> postedTrips = [];
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
          'image': data['image'] ?? 'https://via.placeholder.com/300',
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
          'id': doc.id,
          'name': data['name'],
          'image': data['image'],
          'price': data['price'],
          'rating': data['rating'],
          'duration': data['duration'],
          'category': data['category'],
          'subtitle': data['subtitle'],
          'description': data['description'],
          'photos': data['photos'],
        };
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getUserProfile();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });

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

  Stream<List<String>> fetchCategories() async* {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('destinations').get();

      final allCategories = snapshot.docs
          .map((doc) => doc['category'] as String)
          .toSet()
          .toList();

      allCategories.sort(); // Sort categories A-Z
      allCategories.insert(0, 'All'); // Insert 'All' category at the start

      yield allCategories;
    } catch (e) {
      print('Error fetching categories: $e');
      yield ['All']; // Return 'All' category if error occurs
    }
  }

  Stream<List<Map<String, dynamic>>> streamPostedTrips() {
    return FirebaseFirestore.instance
        .collection('trips')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
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
        'body': message,
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
        _currentUser = user;
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
                _buildRecommendedDestinationsSection(),
                _buildRecentTripsSection(),
              ],
              if (_currentTabIndex == 1)
                _buildSavedDestinationsSection(_currentUser?.uid),
              if (_currentTabIndex == 2) buildProfileTab(context, _currentUser),
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

  Widget _buildNotificationIcon() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildNotificationBaseIcon();
        }

        final unreadCount = snapshot.data?.docs.length ?? 0;

        return GestureDetector(
          onTap: () async {
            await markAllNotificationsAsRead(user.uid);
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
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 22),
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
                  Row(
                    children: [
                      WeatherWidget(),
                      SizedBox(width: 2.w),
                      _buildNotificationIcon(), 
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
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: streamPostedTrips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerRecentTrips();
              }

              if (snapshot.hasError) {
                return const Center(
                    child: Text("Аяллуудыг ачааллаж чадсангүй."));
              }

              final trips = snapshot.data ?? [];
              if (trips.isEmpty) {
                return const Center(child: Text("Сүүлийн аялал алга байна."));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trips.length,
                separatorBuilder: (_, __) => SizedBox(height: 2.h),
                itemBuilder: (context, index) {
                  final trip = trips[index];

                  final imageUrl = trip['image']?.toString() ??
                      trip['heroImage']?.toString() ??
                      ((trip['photos'] is List &&
                              trip['photos'].isNotEmpty)
                          ? trip['photos'][0].toString()
                          : 'https://via.placeholder.com/300');

                  String formattedDate = '';
                  final dateField = trip['date'];
                  if (dateField is Timestamp) {
                    formattedDate = DateFormat('yyyy-MM-dd').format(dateField.toDate());
                  } else if (dateField is String) {
                    formattedDate = dateField;
                  }

                  return RecentTripCardWidget(
                    title: trip['title']?.toString() ?? 'No title',
                    destination: trip['destination']?.toString() ??
                        trip['subtitle']?.toString() ??
                        '',
                    imageUrl: imageUrl,
                    date: formattedDate,
                    rating: trip['rating'] is num
                        ? (trip['rating'] as num).toDouble()
                        : 0.0,
                    highlights: trip['highlights'] is List
                        ? List<String>.from(trip['highlights'])
                        : [],
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
                            content: Text('Аяллын ID олдсонгүй.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    onShare: () {
                      // TODO: Share logic
                    },
                    onEdit: () {
                      // TODO: Edit logic
                    },
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

  Widget _buildCategoryFilter(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentCategory = category;
        });
        print('Category tapped: $category');
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.secondary
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(70),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        child: Text(
          category,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? Colors.white
                : AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

 Widget _buildRecommendedDestinationsSection() {
  return SliverToBoxAdapter(
    child: Column(
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
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
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

        // 🔹 Category chips
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: StreamBuilder<List<String>>(
            stream: fetchCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 5.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: 18.w,
                            height: 5.h,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text('Error loading categories');
              }

              final categories = snapshot.data ?? [];

              return SizedBox(
                height: 5.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _currentCategory == category;
                    return _buildCategoryFilter(category, isSelected);
                  },
                ),
              );
            },
          ),
        ),

        SizedBox(height: 1.h),

        // 🔹 Destination cards
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _currentCategory == 'All'
                ? fetchRecommendedDestinations()
                : fetchDestinationsByCategory(_currentCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerDestinationGrid();
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error loading destinations"));
              }

              final destinations = snapshot.data ?? [];

              if (destinations.isEmpty) {
                return Center(child: Text("No destinations found"));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                        savedDestinationIds.contains(destination['id']),
                    onFavoriteToggle: () =>
                        _toggleSaveDestination(destination['id']),
                  );
                },
              );
            },
          ),
        ),
      ],
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
  Widget _buildShimmerDestinationGrid() {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 6,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 3.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 0.8,
    ),
    itemBuilder: (context, index) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
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
              Container(height: 10, width: 40.w, color: Colors.white),
              SizedBox(height: 0.5.h),
              Container(height: 10, width: 30.w, color: Colors.white),
              SizedBox(height: 0.5.h),
              Container(height: 10, width: 25.w, color: Colors.white),
            ],
          ),
        ),
      );
    },
  );
}
Widget _buildShimmerRecentTrips() {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 3,
    separatorBuilder: (_, __) => SizedBox(height: 2.h),
    itemBuilder: (context, index) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 50.w, color: Colors.white),
                    SizedBox(height: 1.h),
                    Container(height: 10, width: 30.w, color: Colors.white),
                    SizedBox(height: 1.h),
                    Container(height: 10, width: 20.w, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

}

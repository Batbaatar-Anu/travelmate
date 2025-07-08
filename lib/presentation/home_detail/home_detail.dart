import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/activities_section_widget.dart';
import './widgets/destination_info_widget.dart';
import './widgets/hero_image_widget.dart';
import './widgets/interactive_map_widget.dart';
import './widgets/photo_gallery_widget.dart';
import './widgets/reviews_section_widget.dart';
import './widgets/weather_section_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeDetail extends StatefulWidget {
  const HomeDetail({super.key});

  @override
  State<HomeDetail> createState() => _HomeDetailState();
}

class _HomeDetailState extends State<HomeDetail> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  bool _isLoading = true;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  String? _destinationId;
  Map<String, dynamic>? destinationData;
  bool _isSaved = false;
  String selectedCategory = "All";

  // Mock destination data
  // final Map<String, dynamic> destinationData = {
  //   "id": 1,
  //   "title": "Santorini, Greece",
  //   "subtitle": "Cyclades Islands",
  //   "heroImage":
  //       "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
  //   "rating": 4.8,
  //   "reviewCount": 2847,
  //   "description":
  //       """Discover the magic of Santorini, where whitewashed buildings cascade down dramatic cliffs overlooking the deep blue Aegean Sea. This volcanic island paradise offers breathtaking sunsets, world-class wineries, and ancient archaeological sites that tell stories of civilizations past.""",
  //   "highlights": [
  //     "Iconic blue-domed churches",
  //     "Spectacular sunset views from Oia",
  //     "Volcanic beaches with unique colors",
  //     "Traditional Cycladic architecture",
  //     "Award-winning local wines"
  //   ],
  //   "photos": [
  //     "https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
  //     "https://images.unsplash.com/photo-1516483638261-f4dbaf036963?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
  //     "https://images.unsplash.com/photo-1533105079780-92b9be482077?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
  //     "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
  //     "https://images.unsplash.com/photo-1539650116574-75c0c6d73f6e?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3"
  //   ],
  //   "activities": [
  //     {
  //       "title": "Sunset Watching in Oia",
  //       "description":
  //           "Experience the world's most famous sunset from the charming village of Oia",
  //       "duration": "2-3 hours",
  //       "price": "Free",
  //       "difficulty": "Easy"
  //     },
  //     {
  //       "title": "Wine Tasting Tour",
  //       "description": "Explore local wineries and taste unique volcanic wines",
  //       "duration": "4-5 hours",
  //       "price": "\$85 per person",
  //       "difficulty": "Easy"
  //     },
  //     {
  //       "title": "Volcano Hiking",
  //       "description": "Hike to the active volcano crater and hot springs",
  //       "duration": "6-7 hours",
  //       "price": "\$45 per person",
  //       "difficulty": "Moderate"
  //     },
  //     {
  //       "title": "Catamaran Cruise",
  //       "description":
  //           "Sail around the caldera with swimming and snorkeling stops",
  //       "duration": "5-6 hours",
  //       "price": "\$120 per person",
  //       "difficulty": "Easy"
  //     }
  //   ],
  //   "weather": [
  //     {
  //       "day": "Today",
  //       "high": 28,
  //       "low": 22,
  //       "condition": "Sunny",
  //       "icon": "sunny"
  //     },
  //     {
  //       "day": "Tomorrow",
  //       "high": 26,
  //       "low": 20,
  //       "condition": "Partly Cloudy",
  //       "icon": "partly_cloudy_day"
  //     },
  //     {
  //       "day": "Wednesday",
  //       "high": 29,
  //       "low": 23,
  //       "condition": "Sunny",
  //       "icon": "sunny"
  //     },
  //     {
  //       "day": "Thursday",
  //       "high": 27,
  //       "low": 21,
  //       "condition": "Cloudy",
  //       "icon": "cloud"
  //     },
  //     {
  //       "day": "Friday",
  //       "high": 25,
  //       "low": 19,
  //       "condition": "Light Rain",
  //       "icon": "light_mode"
  //     },
  //     {
  //       "day": "Saturday",
  //       "high": 24,
  //       "low": 18,
  //       "condition": "Rainy",
  //       "icon": "water_drop"
  //     },
  //     {
  //       "day": "Sunday",
  //       "high": 26,
  //       "low": 20,
  //       "condition": "Partly Cloudy",
  //       "icon": "partly_cloudy_day"
  //     }
  //   ],
  //   "reviews": [
  //     {
  //       "userName": "Sarah Johnson",
  //       "userAvatar":
  //           "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
  //       "rating": 5,
  //       "date": "2 weeks ago",
  //       "comment":
  //           "Absolutely breathtaking! The sunset views from Oia are beyond words. The local wine tasting was an amazing experience too."
  //     },
  //     {
  //       "userName": "Michael Chen",
  //       "userAvatar":
  //           "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
  //       "rating": 5,
  //       "date": "1 month ago",
  //       "comment":
  //           "Perfect honeymoon destination. The volcanic beaches are unique and the hospitality is incredible. Highly recommend the catamaran cruise!"
  //     },
  //     {
  //       "userName": "Emma Rodriguez",
  //       "userAvatar":
  //           "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
  //       "rating": 4,
  //       "date": "3 weeks ago",
  //       "comment":
  //           "Beautiful island with stunning architecture. Can get quite crowded during peak season, but still worth every moment."
  //     }
  //   ],
  //   "coordinates": {"latitude": 36.3932, "longitude": 25.4615},
  //   "lastUpdated": "2 hours ago"
  // };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _destinationId = args;
      _fetchDestinationFromFirestore();
      _checkIfSaved(); // 👈 ЭНЭХҮҮ мөрийг нэм
    }
  }
  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScroll);
    _simulateLoading();
  }

  void _simulateLoading() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 400 && !_showBackToTop) {
      setState(() {
        _showBackToTop = true;
      });
      _fabAnimationController.forward();
    } else if (_scrollController.offset <= 400 && _showBackToTop) {
      setState(() {
        _showBackToTop = false;
      });
      _fabAnimationController.reverse();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchDestinationFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('destinations')
          .doc(_destinationId)
          .get();

      if (doc.exists) {
        if (mounted) {
          // Check if widget is still mounted
          setState(() {
            destinationData = doc.data();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destination not found')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching destination: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content updated successfully'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _handleSaveDestination() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _destinationId == null) return;

    try {
      final savedRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_destinations')
          .doc(_destinationId);

      if (_isSaved) {
        await savedRef.delete(); // Unsave if already saved
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from bookmarks')),
        );
      } else {
        await savedRef.set({
          'destination_id': _destinationId,
          'saved_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to bookmarks')),
        );
      }

      setState(() {
        _isSaved = !_isSaved;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _destinationId == null) return;

    final savedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_destinations')
        .doc(_destinationId)
        .get();

    setState(() {
      _isSaved = savedDoc.exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: _isLoading
          ? _buildLoadingSkeleton()
          : destinationData == null
              ? Center(child: Text("Destination not found"))
              : _buildContent(),
      floatingActionButton: _showBackToTop
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                child: CustomIconWidget(
                  iconName: 'keyboard_arrow_up',
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        // Hero image skeleton
        Container(
          height: 35.h,
          width: double.infinity,
          color: Colors.grey[300],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(4.w),
            children: [
              // Title skeleton
              Container(
                height: 3.h,
                width: 70.w,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: 2.h),
              // Description skeleton
              ...List.generate(
                  3,
                  (index) => Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Container(
                          height: 2.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 35.h,
            pinned: true,
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            leading: Container(
              margin: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _handleSaveDestination, // ✅ Save logic
                  icon: CustomIconWidget(
                    iconName: _isSaved
                        ? 'bookmark'
                        : 'bookmark_border', // ✅ Toggle icon
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 4.w, top: 2.w, bottom: 2.w),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing destination...')),
                    );
                  },
                  icon: CustomIconWidget(
                    iconName: 'share',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: HeroImageWidget(
                imageUrl: destinationData!["image"] as String, // ← зассан
                title: destinationData!["title"] as String,
                subtitle: destinationData!["subtitle"] as String? ?? '',
              ),
            ),
          ),

          // Content sections
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destination Info
                DestinationInfoWidget(
                  title: destinationData!["title"] as String,
                  subtitle: destinationData!["subtitle"] as String,
                  rating: destinationData!["rating"] as double,
                  reviewCount: destinationData!["reviewCount"] as int,
                  description: destinationData!["description"] as String,
                  // highlights:
                  //     (destinationData!["highlights"] as List).cast<String>(),
                ),

                SizedBox(height: 3.h),

                // Photo Gallery
                PhotoGalleryWidget(
                  photos: (destinationData!["photos"] as List).cast<String>(),
                ),

                SizedBox(height: 3.h),

                // Activities Section (optional)
                if (destinationData!.containsKey("activities"))
                  ActivitiesSectionWidget(
                    activities: (destinationData!["activities"] as List)
                        .cast<Map<String, dynamic>>(),
                  ),

                // Reviews Section
                ReviewsSectionWidget(destinationId: _destinationId!),

                SizedBox(height: 12.h), // Space for sticky action bar
              ],
            ),
          ),
        ],
      ),
    );
  }
}

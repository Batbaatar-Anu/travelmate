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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _destinationId = args;
      _fetchDestinationFromFirestore();
      _checkIfSaved();
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
      // ✅ Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _onScroll() {
    // ✅ Check if widget is still mounted before calling setState
    if (!mounted) return;

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

      // ✅ Check if widget is still mounted before calling setState
      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          destinationData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Destination not found')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching destination: $e');

      // ✅ Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));

    // ✅ Check if widget is still mounted before showing SnackBar
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
          .collection('user_profiles')
          .doc(user.uid)
          .collection('saved_destinations')
          .doc(_destinationId);

      if (_isSaved) {
        await savedRef.delete();

        // ✅ Check if widget is still mounted before showing SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from bookmarks')),
          );
        }
      } else {
        await savedRef.set({
          'destination_id': _destinationId,
          'saved_at': FieldValue.serverTimestamp(),
        });

        // ✅ Check if widget is still mounted before showing SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to bookmarks')),
          );
        }
      }

      // ✅ Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
      }
    } catch (e) {
      // ✅ Check if widget is still mounted before showing SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _destinationId == null) return;

    try {
      final savedDoc = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .collection('saved_destinations')
          .doc(_destinationId)
          .get();

      // ✅ Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isSaved = savedDoc.exists;
        });
      }
    } catch (e) {
      debugPrint('Error checking saved status: $e');
      // Handle error silently or show error message if needed
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll); // ✅ Remove listener
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
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
                  onPressed: _handleSaveDestination,
                  icon: CustomIconWidget(
                    iconName: _isSaved ? 'bookmark' : 'bookmark_border',
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
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing destination...')),
                      );
                    }
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
                imageUrl: destinationData!["image"] as String,
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

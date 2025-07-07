import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class RecommendedDestinationWidget extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String price;
  final double rating;
  final String duration;
  final String category;
  final VoidCallback onTap;
  final bool isSaved; // 🔁 Whether it's saved or not
  final VoidCallback onFavoriteToggle; // 🔁 Tap action for heart icon

  const RecommendedDestinationWidget({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.duration,
    required this.category,
    required this.onTap,
    required this.isSaved,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      height: 10.h,
      width: double.infinity,
      child: Stack(
        children: [
          // 🔳 Destination image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: CustomImageWidget(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 10.h,
              fit: BoxFit.cover,
            ),
          ),

          // 🏷 Category label
          Positioned(
            top: 1.h,
            left: 2.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // ❤️ Favorite icon
          Positioned(
            top: 1.h,
            right: 2.w,
            child: GestureDetector(
              onTap: onFavoriteToggle,
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomIconWidget(
                  iconName: isSaved ? 'favorite_border' : 'favorite_border',
                  color: isSaved
                      ? Colors.red
                      : AppTheme.lightTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(3.w),
      child: SizedBox(
        height: 10.h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 📍 Destination Name
            Text(
              name,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // ⭐ Rating & duration
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'star',
                  color: Colors.amber,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  "• $duration",
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // 💰 Price + Book button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Book Now",
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

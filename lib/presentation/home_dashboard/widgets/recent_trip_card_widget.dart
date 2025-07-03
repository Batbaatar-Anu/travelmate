import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentTripCardWidget extends StatelessWidget {
  final String title; // 🆕
  final String destination;
  final String imageUrl;
  final String date;
  final String status;
  final double rating;
  final List<String> highlights;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onEdit;

  const RecentTripCardWidget({
    super.key,
    required this.title, // 🆕
    required this.destination,
    required this.imageUrl,
    required this.date,
    required this.status,
    required this.rating,
    required this.highlights,
    required this.onTap,
    required this.onShare,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        width: 70.w,
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
      height: 12.h,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: CustomImageWidget(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 12.h,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 1.h,
            right: 2.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: status == "Completed"
                    ? AppTheme.lightTheme.colorScheme.tertiary
                    : AppTheme.lightTheme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🆕 Title харагдах хэсэг
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),

            // ✅ Destination
            Text(
              destination,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 0.5.h),

            // ✅ Date
            Text(
              date,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),

            // ✅ Rating
            if (rating > 0) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'star',
                    color: Colors.amber,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    rating.toString(),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // ✅ Highlights
            SizedBox(height: 1.h),
            Expanded(
              child: Text(
                highlights.take(2).join(" • "),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 3.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'visibility',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                title: Text("View Details"),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'share',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                title: Text("Share"),
                onTap: () {
                  Navigator.pop(context);
                  onShare();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'edit',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                title: Text("Edit"),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }
}

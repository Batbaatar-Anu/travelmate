import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UpcomingReminderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String type;
  final String priority;
  final VoidCallback onTap;

  const UpcomingReminderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.priority,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getPriorityColor().withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconSection(),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildContentSection(),
            ),
            _buildTimeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: _getPriorityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomIconWidget(
        iconName: _getIconName(),
        color: _getPriorityColor(),
        size: 24,
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 0.5.h),
        Text(
          subtitle,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: _getPriorityColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: _getPriorityColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Container(
          width: 2.w,
          height: 2.w,
          decoration: BoxDecoration(
            color: _getPriorityColor(),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.lightTheme.colorScheme.error;
      case 'medium':
        return Colors.amber;
      case 'low':
        return AppTheme.lightTheme.colorScheme.tertiary;
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }

  String _getIconName() {
    switch (type.toLowerCase()) {
      case 'flight':
        return 'flight';
      case 'document':
        return 'description';
      case 'insurance':
        return 'security';
      case 'hotel':
        return 'hotel';
      case 'car':
        return 'directions_car';
      default:
        return 'notifications';
    }
  }
}

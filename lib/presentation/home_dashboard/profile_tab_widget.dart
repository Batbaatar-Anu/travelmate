import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class ProfileTabWidget extends StatelessWidget {
  final String userName;
  final String email;
  final Function() onLogout;
  final List<Map<String, String>> trips; // {title, destination, imageUrl}

  const ProfileTabWidget({
    super.key,
    required this.userName,
    required this.email,
    required this.onLogout,
    required this.trips,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.lightTheme.primaryColor,
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  SizedBox(width: 4.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        email,
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Profile Options
          _buildOption(context, Icons.edit, "Edit Profile", '/edit-profile'),
          _buildOption(context, Icons.settings, "Settings", '/settings'),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Log Out", style: TextStyle(color: Colors.red)),
            onTap: onLogout,
          ),

          SizedBox(height: 3.h),

          // Your Trips Section
          Text(
            "Your Trips",
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),

          if (trips.isEmpty)
            Center(child: Text("No trips added yet.", style: TextStyle(color: Colors.grey))),
          ...trips.map((trip) => _buildTripCard(context, trip)).toList(),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.lightTheme.primaryColor),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, String> trip) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(2.w),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            trip['imageUrl'] ?? '',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported),
          ),
        ),
        title: Text(trip['title'] ?? 'Untitled'),
        subtitle: Text(trip['destination'] ?? ''),
        onTap: () {
          Navigator.pushNamed(context, '/trip-detail', arguments: trip);
        },
      ),
    );
  }
}

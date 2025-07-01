import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class ProfileTabWidget extends StatelessWidget {
  final String userName;
  final String email;
  final Function() onLogout;

  const ProfileTabWidget({
    super.key,
    required this.userName,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Row(
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
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  Text(
                    email,
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ListTile(
            leading: Icon(Icons.edit, color: AppTheme.lightTheme.primaryColor),
            title: Text("Edit Profile"),
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: AppTheme.lightTheme.primaryColor),
            title: Text("Settings"),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Log Out", style: TextStyle(color: Colors.red)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

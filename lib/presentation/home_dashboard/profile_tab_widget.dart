// import 'package:flutter/material.dart';
// import 'package:sizer/sizer.dart';
// import '../../../core/app_export.dart';

// class ProfileTabWidget extends StatelessWidget {
//   final String userName;
//   final String email;
//   final Function() onLogout;
//   final List<Map<String, String>> trips;

//   const ProfileTabWidget({
//     super.key,
//     required this.userName,
//     required this.email,
//     required this.onLogout,
//     required this.trips,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         SingleChildScrollView(
//           padding: EdgeInsets.only(bottom: 8.h),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // --- Profile Header ---
//               Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.purple.shade100, Colors.pink.shade50],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                   borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
//                 ),
//                 padding: EdgeInsets.symmetric(vertical: 4.h),
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 40,
//                       backgroundImage: AssetImage("assets/images/default_profile.png"),
//                       backgroundColor: Colors.white,
//                     ),
//                     SizedBox(height: 1.h),
//                     Text(
//                       userName,
//                       style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       email,
//                       style: TextStyle(color: Colors.grey, fontSize: 11.sp),
//                     ),
//                     SizedBox(height: 1.h),
//                     TextButton.icon(
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/edit-profile');
//                       },
//                       icon: Icon(Icons.edit, size: 18),
//                       label: Text("Edit Profile"),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 2.h),

//               // --- Your Trips Section ---
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 4.w),
//                 child: Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Your Trips",
//                     style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 1.5.h),

//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 4.w),
//                 child: trips.isEmpty
//                     ? Center(
//                         child: Padding(
//                           padding: EdgeInsets.only(top: 5.h),
//                           child: Text("No trips added yet.", style: TextStyle(color: Colors.grey)),
//                         ),
//                       )
//                     : GridView.builder(
//                         shrinkWrap: true,
//                         physics: NeverScrollableScrollPhysics(),
//                         itemCount: trips.length,
//                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 3,
//                           crossAxisSpacing: 2.w,
//                           mainAxisSpacing: 2.w,
//                           childAspectRatio: 0.75,
//                         ),
//                         itemBuilder: (context, index) {
//                           final trip = trips[index];
//                           return GestureDetector(
//                             onTap: () {
//                               Navigator.pushNamed(context, '/trip-detail', arguments: trip);
//                             },
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.network(
//                                 trip['imageUrl'] ?? '',
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (_, __, ___) => Container(
//                                   color: Colors.grey.shade300,
//                                   child: Icon(Icons.image, size: 24),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         ),

//         // --- Logout button (Top right) ---
//         Positioned(
//           top: 2.h,
//           right: 2.w,
//           child: IconButton(
//             icon: Icon(Icons.logout, color: Colors.red),
//             onPressed: onLogout,
//           ),
//         ),
//       ],
//     );
//   }
// }

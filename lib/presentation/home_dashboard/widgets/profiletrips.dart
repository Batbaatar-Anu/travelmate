import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/profiletab.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/tripedit.dart';
import 'package:travelmate/routes/app_routes.dart';

class ProfileTripsSection extends StatelessWidget {
  final User? user;
  const ProfileTripsSection({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null || user!.uid.isEmpty) {
      return _buildErrorWidget("Хэрэглэгчийн мэдээлэл олдсонгүй.");
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: user != null
          ? fetchUserTrips(user)
          : Stream.value([]), 
      builder: (context, snapshot) {
        debugPrint("🔄 StreamBuilder state: ${snapshot.connectionState}");

        if (user == null) {
          return _buildErrorWidget("Хэрэглэгчийн мэдээлэл алга байна.");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          debugPrint("❌ StreamBuilder error: ${snapshot.error}");
          return _buildErrorWidget("Алдаа гарлаа: ${snapshot.error}");
        }

        final trips = snapshot.data ?? [];
        debugPrint("📋 Displaying ${trips.length} trips");

        if (trips.isEmpty) {
          return _buildEmptyWidget();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force refresh by delaying rebuild
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 2.w),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildTripImage(trip),
                  ),
                  title: Text(
                    trip['title'] ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${trip['destination'] ?? 'Unknown'} • ${trip['date'] ?? 'No date'}",
                        style:
                            TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: _buildActions(context, trip),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.tripDetail,
                      arguments: trip,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTripImage(Map<String, dynamic> trip) {
    final imageUrl = trip['image'];
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: imageUrl != null && imageUrl.toString().isNotEmpty
          ? Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported,
                size: 30,
                color: Colors.grey[400],
              ),
            )
          : Icon(
              Icons.travel_explore,
              size: 30,
              color: Colors.grey[400],
            ),
    );
  }

  Widget? _buildActions(BuildContext context, Map<String, dynamic> trip) {
    final isOwner = trip['user_id'] == FirebaseAuth.instance.currentUser?.uid;
    if (!isOwner) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, size: 25),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripEditScreen(
                  trip: trip,
                  tripId: trip['id'],
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.delete, size: 25),
          onPressed: () => _showDeleteDialog(context, trip),
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context, Map<String, dynamic> trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Аяллыг устгах уу?"),
        content:
            Text("Та '${trip['title']}' аяллыг бүр мөсөн устгах гэж байна."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Болих"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Устгах", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('trips')
            .doc(trip['id'])
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'${trip['title']}' аялал амжилттай устгагдлаа."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("❌ Delete error: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Аялал устгахад алдаа гарлаа: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildLoading() => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) => Card(
            margin: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 2.w),
            child: ListTile(
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              title: Container(
                height: 16,
                width: 60.w,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                width: 40.w,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );

  Widget _buildErrorWidget(String message) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 12.w, color: Colors.red),
              SizedBox(height: 2.h),
              Text(
                message,
                style: TextStyle(fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () {
                  // Trigger rebuild
                },
                child: const Text("Дахин оролдох"),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyWidget() => Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.travel_explore, size: 12.w, color: Colors.grey),
              SizedBox(height: 2.h),
              Text(
                "Одоогоор нэмсэн аялал алга байна.",
                style: TextStyle(fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                "Доорх ➕ товчоор аялал нэмээрэй.",
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

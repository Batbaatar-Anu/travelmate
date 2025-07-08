import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';

class ReviewsSectionWidget extends StatefulWidget {
  final String destinationId;

  const ReviewsSectionWidget({super.key, required this.destinationId});

  @override
  State<ReviewsSectionWidget> createState() => _ReviewsSectionWidgetState();
}

class _ReviewsSectionWidgetState extends State<ReviewsSectionWidget> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5;

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(user.uid)
        .get();

    final userData = userDoc.data() ?? {};

    await FirebaseFirestore.instance
        .collection('destinations')
        .doc(widget.destinationId)
        .collection('reviews')
        .add({
      'userId': user.uid,
      'userName': userData['full_name'],
      'userAvatar': userData['photoUrl'] ?? '',
      'rating': _rating,
      'comment': _commentController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    setState(() => _rating = 5);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Сэтгэгдэл илгээгдлээ!')));
  }

  String _formatTimestamp(dynamic timestamp) {
  // Check if the timestamp is null or not a valid Timestamp object
  if (timestamp == null || timestamp is! Timestamp) {
    return 'wait';
  }

  final date = timestamp.toDate();  // Convert to DateTime
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays >= 7) {
    return '${(difference.inDays / 7).floor()} долоо хоногийн өмнө';
  } else if (difference.inDays >= 1) {
    return '${difference.inDays} хоногийн өмнө';
  } else if (difference.inHours >= 1) {
    return '${difference.inHours} цагийн өмнө';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes} минутын өмнө';
  } else {
    return 'Саяхан';
  }
}


  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Устгах уу?"),
        content: Text("Та энэ сэтгэгдлийг устгахдаа итгэлтэй байна уу?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Үгүй")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Тийм")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('destinations')
          .doc(widget.destinationId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Сэтгэгдэл устгагдлаа")));
    }
  }

  Widget _buildStarBar(int star, int count, int total) {
    final percent = total > 0 ? count / total : 0;
    return Row(
      children: [
        SizedBox(width: 18, child: Text('$star')),
        Icon(Icons.star, size: 16, color: Colors.amber),
        SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percent.toDouble(),
            color: Colors.amber,
            backgroundColor: Colors.grey[300],
          ),
        ),
        SizedBox(width: 8),
        Text('${(percent * 100).toStringAsFixed(0)}%'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('destinations')
          .doc(widget.destinationId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final reviews = snapshot.data?.docs ?? [];

        double avgRating = 0;
        Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

        for (var review in reviews) {
          int star = review['rating'].round();
          starCounts[star] = (starCounts[star] ?? 0) + 1;
          avgRating += review['rating'];
        }

        final totalReviews = reviews.length;
        avgRating = totalReviews > 0 ? avgRating / totalReviews : 0;

        return Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⭐ Overall Rating
              Text("Сэтгэгдэл ба Үнэлгээ",
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 2.h),

              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(avgRating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < avgRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                      Text('$totalReviews сэтгэгдэл'),
                    ],
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      children: List.generate(5, (i) {
                        int star = 5 - i;
                        return _buildStarBar(
                            star, starCounts[star] ?? 0, totalReviews);
                      }),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),
              Divider(),

              // ✍️ Submit Review
              Text("Сэтгэгдэл үлдээх",
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 1.h),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() => _rating = (index + 1).toDouble());
                    },
                  );
                }),
              ),
              Row(
                children: [
                  // 💬 Сэтгэгдэл бичих талбар
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: "Таны сэтгэгдэл...",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),

                  // 📤 Илгээх товч
                  ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      minimumSize: Size(0, 48), // өндөр тэнцүүлэх
                    ),
                    child: Text("Илгээх"),
                  ),
                ],
              ),

              SizedBox(height: 2.h),
              Divider(),

              // 📄 Review List
              Text("Сүүлийн сэтгэгдлүүд",
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 1.h),
              // 📄 Review List (доторх map loop хэсгийн нэг review item-ийн код)
              ...reviews.map((review) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 4.w),
    padding: EdgeInsets.all(3.5.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.15),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE0E0E0),
          backgroundImage: (review['userAvatar'] != null &&
                  review['userAvatar'].toString().isNotEmpty)
              ? NetworkImage(review['userAvatar'])
              : null,
          child: (review['userAvatar'] == null ||
                  review['userAvatar'].toString().isEmpty)
              ? Icon(Icons.person, size: 26, color: Colors.grey)
              : null,
        ),
        SizedBox(width: 3.5.w),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name & Timestamp & Delete
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      review['userName'] ?? 'Хэрэглэгч',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (review['userId'] ==
                      FirebaseAuth.instance.currentUser?.uid)
                    GestureDetector(
                      onTap: () => _deleteReview(review.id),
                      child: Icon(Icons.delete, color: Colors.red, size: 18),
                    ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatTimestamp(review['createdAt']),
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 0.6.h),

              // Rating
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review['rating']
                        ? Icons.star
                        : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ), 
              ),
              SizedBox(height: 0.6.h),

              // Comment
              Text(
                review['comment'] ?? '',
                style: TextStyle(fontSize: 10.sp, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}).toList()


            ],
          ),
        );
      },
    );
  }
}

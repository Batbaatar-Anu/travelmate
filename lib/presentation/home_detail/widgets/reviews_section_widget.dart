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

    final userData = await FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(user.uid)
        .get();

    await FirebaseFirestore.instance
        .collection('destinations')
        .doc(widget.destinationId)
        .collection('reviews')
        .add({
      'userId': user.uid,
      'userName': userData['name'],
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

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()} долоо хоногийн өмнө';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} хоногийн өмнө';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} цагийн өмнө';
    } else {
      return 'Саяхан';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ Review input
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Сэтгэгдэл үлдээх", style: Theme.of(context).textTheme.titleMedium),
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
              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Таны сэтгэгдэл...",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 1.h),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submitReview,
                  child: Text("Илгээх"),
                ),
              )
            ],
          ),
        ),

        Divider(),

        // 📄 Review List
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text("Сэтгэгдлүүд", style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(height: 1.h),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('destinations')
              .doc(widget.destinationId)
              .collection('reviews')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(4.w),
                child: Text('Одоогоор сэтгэгдэл алга байна.'),
              );
            }

            final reviews = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(review['userAvatar']),
                  ),
                  title: Text(review['userName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${review['rating']} ★"),
                      Text(review['comment']),
                      Text(
                        _formatTimestamp(review['createdAt']),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

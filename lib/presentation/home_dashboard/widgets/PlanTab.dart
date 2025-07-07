// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class PlanTab extends StatelessWidget {
//   const PlanTab({super.key});

//   // ✅ Real-time stream ашиглан хадгалсан аяллуудыг авна
//   Stream<List<Map<String, dynamic>>> fetchSavedDestinations(String userId) {
//     return FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .collection('saved_destinations')
//         .snapshots()
//         .asyncMap((snapshot) async {
//       final destinationIds = snapshot.docs.map((doc) => doc.id).toList();

//       if (destinationIds.isEmpty) return [];

//       final futures = destinationIds.map((id) =>
//           FirebaseFirestore.instance.collection('destinations').doc(id).get());

//       final docs = await Future.wait(futures);

//       return docs
//           .where((doc) => doc.exists)
//           .map((doc) => {
//                 'id': doc.id,
//                 ...doc.data()!,
//               })
//           .toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

//     if (currentUser == null) {
//       return const Center(
//         child: Text('Please log in to view saved trips.'),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Saved Trips'),
//         centerTitle: true,
//       ),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: fetchSavedDestinations(currentUser.uid),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No saved trips yet.',
//                 style: TextStyle(fontSize: 16),
//               ),
//             );
//           }

//           final savedTrips = snapshot.data!;
//           return ListView.builder(
//             itemCount: savedTrips.length,
//             itemBuilder: (context, index) {
//               final trip = savedTrips[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: ListTile(
//                   leading: trip['image'] != null
//                       ? Image.network(
//                           trip['image'],
//                           width: 60,
//                           height: 60,
//                           fit: BoxFit.cover,
//                         )
//                       : const Icon(Icons.image_not_supported),
//                   title: Text(trip['title'] ?? 'No title'),
//                   subtitle: Text(trip['subtitle'] ?? ''),
//                   onTap: () {
//                     Navigator.pushNamed(
//                       context,
//                       '/home_detail',
//                       arguments: trip['id'],
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travelmate/presentation/home_dashboard/widgets/tripedit.dart'; // For Timestamp

class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final imageUrl = trip['heroImage']?.toString() ??
        trip['image']?.toString() ??
        ((trip['photos'] is List && trip['photos'].isNotEmpty)
            ? trip['photos'][0].toString()
            : 'https://via.placeholder.com/300');

    final String formattedDate = _formatTripDate(trip['date']);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[300]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Show buttons only if current user owns this trip
              if (trip['user_id'] ==
                  FirebaseAuth.instance.currentUser?.uid) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    // Navigate to edit screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripEditScreen(
                          trip: trip,
                          tripId: trip['id'],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Delete Trip"),
                        content: const Text(
                            "Are you sure you want to delete this trip?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('trips')
                          .doc(trip['id'])
                          .delete();

                      if (context.mounted) {
                        Navigator.pop(
                            context); // Back to previous screen after delete
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Trip deleted successfully"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
              ]
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title, location, rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip['title']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip['subtitle']?.toString() ??
                                  trip['destination']?.toString() ??
                                  '',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            if (formattedDate.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trip['description']?.toString() ??
                        'No description available.',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 24),
                  _buildHighlightsSection(trip),
                  const SizedBox(height: 24),
                  _buildPhotoGallerySection(trip),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Format Timestamp or String to readable date
  String _formatTripDate(dynamic date) {
    try {
      if (date is Timestamp) {
        return DateFormat('yyyy-MM-dd').format(date.toDate());
      } else if (date is String) {
        final dt = DateTime.tryParse(date);
        if (dt != null) {
          return DateFormat('yyyy-MM-dd').format(dt);
        }
        return date;
      }
    } catch (_) {}
    return '';
  }

  /// Highlights section
  Widget _buildHighlightsSection(Map trip) {
    final List highlights = trip['highlights'] ?? [];
    if (highlights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trip Highlights",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: highlights.map<Widget>((highlight) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    highlight.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Optional: Show photo gallery
  Widget _buildPhotoGallerySection(Map trip) {
    final List photos = trip['photos'] ?? [];
    if (photos.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Photo Gallery",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = photos[index].toString();
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: 150,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 150, height: 120, color: Colors.grey[300]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

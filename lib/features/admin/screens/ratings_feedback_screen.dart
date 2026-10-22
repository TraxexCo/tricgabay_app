import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';

class RatingsFeedbackScreen extends ConsumerWidget {
  const RatingsFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        appBar: AppBar(
          title: const Text('Ratings & Feedback'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reviews'),
              Tab(text: 'System Feedback'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildReviewsList(), _buildFeedbackList()]),
      ),
    );
  }

  Widget _buildReviewsList() {
    final reviews = PrototypeSession.bookings.value
        .where((b) => b.status == BookingStatus.completed)
        .toList();

    if (reviews.isEmpty) {
      return const Center(child: Text('No reviews found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      review.touristName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 16,
                          color: i < 4 ? AppColors.secondary : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Driver: ${review.driverName ?? 'Unknown'}',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great ride, very knowledgeable about Bustos!',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review flagged for follow-up'),
                      ),
                    ),
                    icon: const Icon(
                      Icons.flag,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Flag',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackList() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: PrototypeSession.adminFeedbacks,
      builder: (context, feedbacks, child) {
        if (feedbacks.isEmpty) {
          return const Center(child: Text('No system feedback found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final fb = feedbacks[index];
            return AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.bug_report, color: Colors.white),
                ),
                title: Text(
                  '${fb['category'] ?? 'Feedback'} from ${fb['tourist_name'] ?? 'Unknown'}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${fb['message'] ?? ''}'),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback marked resolved')),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

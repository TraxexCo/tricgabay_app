import 'package:tricgabay_app/core/l10n/feedback_category.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/session/app_session.dart';
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
          title: Text(context.l10n.ratingsFeedback),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.reviews),
              Tab(text: context.l10n.systemFeedback),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildReviewsList(context), _buildFeedbackList()],
        ),
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context) {
    final reviews = AppSession.bookings.value
        .where((b) => b.status == BookingStatus.completed)
        .toList();

    if (reviews.isEmpty) {
      return Center(child: Text(context.l10n.noReviewsFound));
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
                      context.message(review.touristName),
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
                  context.l10n.driverValue(
                    context.message(
                      (review.driverName ?? MessageCode.unknown).toString(),
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.greatRideVeryKnowledgeableAboutBustos,
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.reviewFlaggedForFollowUp),
                      ),
                    ),
                    icon: const Icon(
                      Icons.flag,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    label: Text(
                      context.l10n.flag,
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
      valueListenable: AppSession.adminFeedbacks,
      builder: (context, feedbacks, child) {
        if (feedbacks.isEmpty) {
          return Center(child: Text(context.l10n.noSystemFeedbackFound));
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
                  context.l10n.fromValue(
                    FeedbackCategory.fromWire(
                      (fb['category'] ?? '').toString(),
                    ).label(context),
                    context.message(
                      (fb['tourist_name'] ?? MessageCode.unknown).toString(),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(context.message('${fb['message'] ?? ''}')),
                trailing: IconButton(
                  tooltip: context.l10n.markResolved,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.feedbackMarkedResolved),
                    ),
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

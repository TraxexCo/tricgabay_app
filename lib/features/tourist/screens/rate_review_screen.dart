import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';

class RateReviewScreen extends StatefulWidget {
  final String bookingId;
  const RateReviewScreen({super.key, required this.bookingId});

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  double _rating = 5.0;
  final _reviewCtrl = TextEditingController();
  final _selectedTags = <String>{};
  BookingModel? _booking;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    try {
      _booking = PrototypeSession.bookings.value.firstWhere(
        (b) => b.id == widget.bookingId,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverName = _booking?.driverName ?? 'Your Driver';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        title: Text(
          'Rate Driver',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 47,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'How was your ride with $driverName?',
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Your feedback helps keep Tric-Gabay trusted.',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 48,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, _) =>
                    const Icon(Icons.star_rounded, color: Colors.amber),
                onRatingUpdate: (rating) => setState(() => _rating = rating),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _getRatingLabel(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: ['Friendly', 'Punctual', 'Clean Vehicle', 'Safe Driver']
                  .map(
                    (tag) => FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (v) => setState(() {
                        v ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _reviewCtrl,
              label: 'Leave a comment (Optional)',
              hint: 'What did you like or dislike?',
              maxLines: 4,
            ),
            const SizedBox(height: 40),
            AppButton(
              label: 'Submit Review',
              isLoading: _isSubmitting,
              onPressed: () async {
                setState(() => _isSubmitting = true);
                if (!mounted) return;
                try {
                  await PrototypeSession.markBookingRated(
                    widget.bookingId,
                    _rating,
                    review: _reviewCtrl.text,
                  );
                } catch (e) {
                  if (context.mounted) {
                    setState(() => _isSubmitting = false);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                  return;
                }
                if (!mounted) return;
                setState(() => _isSubmitting = false);
                if (!context.mounted) return;
                AppSnackbar.showSuccess(
                  context,
                  'Thank you for your feedback!',
                );
                context.go('/tourist/bookings');
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/tourist/bookings'),
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel() {
    switch (_rating) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}

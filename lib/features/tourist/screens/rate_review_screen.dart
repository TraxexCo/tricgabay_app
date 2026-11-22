import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/session/app_session.dart';
import '../../../models/booking_model.dart';

class RateReviewScreen extends StatefulWidget {
  final String bookingId;
  const RateReviewScreen({super.key, required this.bookingId});

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

const _ratingTags = [
  MessageCode.friendly,
  MessageCode.punctual,
  MessageCode.cleanVehicle,
  MessageCode.safeDriver,
];

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
      _booking = AppSession.bookings.value.firstWhere(
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
    final driverName = _booking?.driverName ?? MessageCode.yourDriver;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.rateDriver,
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
              context.l10n.howWasYourRideWithValue(
                context.message((driverName).toString()),
              ),
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              context.l10n.yourFeedbackHelpsKeepAppTrusted(AppBrand.name),
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
                context.message(_getRatingLabel()),
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
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _ratingTags
                  .map(
                    (tag) => FilterChip(
                      label: Text(context.message(tag)),
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
              label: context.l10n.leaveACommentOptional,
              hint: context.l10n.whatDidYouLikeOrDislike,
              maxLines: 4,
            ),
            const SizedBox(height: 40),
            AppButton(
              label: context.l10n.submitReview,
              isLoading: _isSubmitting,
              onPressed: () async {
                setState(() => _isSubmitting = true);
                if (!mounted) return;
                try {
                  // Chosen tags go in front of the comment, so the driver
                  // and admins see them with the review.
                  final tags = [
                    for (final tag in _ratingTags)
                      if (_selectedTags.contains(tag)) context.message(tag),
                  ];
                  final comment = _reviewCtrl.text.trim();
                  await AppSession.markBookingRated(
                    widget.bookingId,
                    _rating,
                    review: [
                      if (tags.isNotEmpty) tags.join(', '),
                      if (comment.isNotEmpty) comment,
                    ].join('. '),
                  );
                } catch (e) {
                  if (context.mounted) {
                    setState(() => _isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.message(ErrorMessages.forError(e)),
                        ),
                      ),
                    );
                  }
                  return;
                }
                if (!mounted) return;
                setState(() => _isSubmitting = false);
                if (!context.mounted) return;
                AppSnackbar.showSuccess(
                  context,
                  MessageCode.thankYouForYourFeedback,
                );
                _returnToBooking(context);
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _returnToBooking(context),
              child: Text(
                context.l10n.skip,
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _returnToBooking(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tourist/bookings');
    }
  }

  String _getRatingLabel() {
    switch (_rating) {
      case 1:
        return MessageCode.terrible;
      case 2:
        return MessageCode.bad;
      case 3:
        return MessageCode.okay;
      case 4:
        return MessageCode.good;
      case 5:
        return MessageCode.excellent;
      default:
        return '';
    }
  }
}

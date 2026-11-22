import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/l10n/record_labels.dart';
import '../../../core/session/app_session.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/booking_model.dart';

/// One trip in the driver's lists (requests, active, history, earnings):
/// tour name and fare on top, tourist and time below, then status badges.
class DriverTripCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  /// Requests and active trips show where to pick the tourist up.
  final bool showPickup;

  /// Earnings show the amount actually received instead of the quote.
  final int? amountCents;

  const DriverTripCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.showPickup = false,
    this.amountCents,
  });

  (IconData, Color) get _accent => switch (booking.status) {
    BookingStatus.completed => (Icons.check_circle_rounded, AppColors.success),
    BookingStatus.cancelled => (Icons.cancel_rounded, AppColors.danger),
    BookingStatus.ongoing => (Icons.route_rounded, AppColors.ongoing),
    BookingStatus.accepted => (Icons.directions_car_rounded, AppColors.primary),
    BookingStatus.pending ||
    BookingStatus.scheduled => (Icons.schedule_rounded, AppColors.warning),
    _ => (Icons.receipt_long_rounded, AppColors.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final (icon, color) = _accent;
    final when = (b.completedAt ?? b.scheduledAt ?? b.createdAt).toLocal();
    final amount = (amountCents ?? b.totalFareCents) / 100;
    final secondary = GoogleFonts.poppins(
      fontSize: 13,
      color: AppColors.textSecondary,
      height: 1.35,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        onTap: onTap,
        borderRadius: 18,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          context.message(AppSession.bookingTitle(b)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '₱${AppFormatters.amount(amount)}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.twoPartSummary(
                      context.message(b.touristName),
                      AppFormatters.dateTime(when),
                    ),
                    style: secondary,
                  ),
                  if (showPickup && b.pickupAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.place_outlined,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            context.message(b.pickupAddress),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusBadge.bookingStatus(b.status),
                      if (b.trip.reviewRequired)
                        StatusBadge(
                          label: context.l10n.paymentReviewPending,
                          color: AppColors.warningLight,
                          textColor: AppColors.warning,
                        )
                      else if (!b.isActive)
                        StatusBadge(
                          label: paymentStatusLabel(context, b.paymentStatus),
                          color: b.paymentStatus == PaymentStatus.paid
                              ? AppColors.successLight
                              : AppColors.surfaceVariant,
                          textColor: b.paymentStatus == PaymentStatus.paid
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

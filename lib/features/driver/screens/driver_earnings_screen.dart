import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import '../../../core/motion/motion_widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/app_session.dart';
import '../../../models/booking_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/driver_trip_card.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});
  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  int _days = 1;
  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<BookingModel>>(
    valueListenable: AppSession.bookings,
    builder: (context, bookings, _) {
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: _days - 1));
      final own = bookings
          .where(
            (b) =>
                AppSession.ownsDriverBooking(b) &&
                !b.isActive &&
                (b.completedAt ?? b.createdAt).isAfter(
                  start.subtract(const Duration(microseconds: 1)),
                ),
          )
          .toList();
      final settled = own
          .where((b) => !b.trip.reviewRequired && b.refundDueCents == 0)
          .toList();
      final hasDirectGcash = settled.any(
        (b) =>
            b.paymentMethod == PaymentMethod.gcashDirect &&
            b.trip.receivedCents > 0,
      );
      final received = settled.fold<int>(
        0,
        (sum, b) => sum + b.trip.receivedCents,
      );
      final due = own.fold<int>(0, (sum, b) => sum + b.amountDueCents);
      final reviews = own.where((b) => b.trip.reviewRequired).length;
      final receivedById = {
        for (final b in settled) b.id: b.trip.receivedCents,
      };
      return Scaffold(
        appBar: AppBar(
          title: Text(
            hasDirectGcash ? context.l10n.earnings : context.l10n.confirmedCash,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 1, label: Text(context.l10n.today)),
                ButtonSegment(
                  value: 7,
                  label: Text(context.l10n.lastSevenDays),
                ),
                ButtonSegment(
                  value: 30,
                  label: Text(context.l10n.lastThirtyDays),
                ),
              ],
              selected: {_days},
              onSelectionChanged: (v) => setState(() => _days = v.first),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF102A43), Color(0xFF1B6CA8)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          switch (_days) {
                            1 => context.l10n.today,
                            7 => context.l10n.lastSevenDays,
                            _ => context.l10n.lastThirtyDays,
                          },
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedCount(
                    value: received / 100,
                    format: (pesos) => '₱${AppFormatters.amount(pesos)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasDirectGcash
                        ? context.l10n.gcashEarningsExplanation
                        : context
                              .l10n
                              .cashConfirmedByBothPartiesAfterReturnsFilteredByTripEndDateAmounts,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: .86),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _stat(
                    Icons.route_outlined,
                    AppColors.primary,
                    AppFormatters.integer(own.length),
                    context.l10n.trips,
                  ),
                  const SizedBox(width: 10),
                  _stat(
                    Icons.hourglass_bottom_rounded,
                    AppColors.warning,
                    '₱${AppFormatters.amount(due / 100)}',
                    context.l10n.awaitingPayment,
                  ),
                  const SizedBox(width: 10),
                  _stat(
                    Icons.fact_check_outlined,
                    reviews > 0 ? AppColors.danger : AppColors.success,
                    AppFormatters.integer(reviews),
                    context.l10n.openReviews,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              context.l10n.tripsInThisPeriod,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (own.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.noEndedTripsInThisPeriod,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            for (final (index, b) in own.indexed)
              FadeSlideIn.staggered(
                index: index,
                child: DriverTripCard(
                  booking: b,
                  amountCents: receivedById[b.id],
                  onTap: () => context.push('/driver/bookings/${b.id}'),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _stat(IconData icon, Color color, String value, String label) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

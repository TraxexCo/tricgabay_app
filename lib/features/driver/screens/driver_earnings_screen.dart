import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import '../../../core/motion/motion_widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/app_session.dart';
import '../../../models/booking_model.dart';
import '../../../core/l10n/record_labels.dart';

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
      return Scaffold(
        appBar: AppBar(
          title: Text(
            hasDirectGcash ? context.l10n.earnings : context.l10n.confirmedCash,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            SegmentedButton<int>(
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
            const SizedBox(height: 24),
            AnimatedCount(
              value: received / 100,
              format: (pesos) => '₱${AppFormatters.amount(pesos)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Text(
              hasDirectGcash
                  ? context.l10n.gcashEarningsExplanation
                  : context
                        .l10n
                        .cashConfirmedByBothPartiesAfterReturnsFilteredByTripEndDateAmounts,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.awaitingPaymentValue(
                context.message((AppFormatters.amount((due / 100))).toString()),
              ),
            ),
            Text(
              context.l10n.openReviewsValue(
                context.message(
                  (own.where((b) => b.trip.reviewRequired).length).toString(),
                ),
              ),
            ),
            const Divider(height: 32),
            if (own.isEmpty) Text(context.l10n.noEndedTripsInThisPeriod),
            ...own.map(
              (b) => Card(
                child: ListTile(
                  title: Text(context.message(b.id)),
                  subtitle: Text(
                    context.l10n.twoPartSummary(
                      context.message(bookingStatusLabel(context, b.status)),
                      context.message(
                        paymentStatusLabel(context, b.paymentStatus),
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/driver/bookings/${b.id}'),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

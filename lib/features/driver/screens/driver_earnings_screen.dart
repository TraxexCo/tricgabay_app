import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});
  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  int _days = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Confirmed cash')),
    body: ValueListenableBuilder<List<BookingModel>>(
      valueListenable: PrototypeSession.bookings,
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
                  PrototypeSession.ownsDriverBooking(b) &&
                  !b.isActive &&
                  (b.completedAt ?? b.createdAt).isAfter(
                    start.subtract(const Duration(microseconds: 1)),
                  ),
            )
            .toList();
        final settled = own
            .where((b) => !b.trip.reviewRequired && b.refundDueCents == 0)
            .toList();
        final cash = settled.fold<int>(
          0,
          (sum, b) => sum + b.trip.receivedCents,
        );
        final due = own.fold<int>(0, (sum, b) => sum + b.amountDueCents);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Today')),
                ButtonSegment(value: 7, label: Text('7 days')),
                ButtonSegment(value: 30, label: Text('30 days')),
              ],
              selected: {_days},
              onSelectionChanged: (v) => setState(() => _days = v.first),
            ),
            const SizedBox(height: 24),
            Text(
              '₱${(cash / 100).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Cash confirmed by both parties, after returns. Filtered by trip end date. Amounts under review are excluded.',
            ),
            const SizedBox(height: 16),
            Text('Awaiting payment: ₱${(due / 100).toStringAsFixed(2)}'),
            Text(
              'Open reviews: ${own.where((b) => b.trip.reviewRequired).length}',
            ),
            const Divider(height: 32),
            if (own.isEmpty) const Text('No ended trips in this period.'),
            ...own.map(
              (b) => Card(
                child: ListTile(
                  title: Text(b.id),
                  subtitle: Text('${b.status.name} · ${b.paymentStatus.name}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/driver/bookings/${b.id}'),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

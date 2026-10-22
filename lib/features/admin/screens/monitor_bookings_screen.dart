import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';

class MonitorBookingsScreen extends StatelessWidget {
  const MonitorBookingsScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Bookings & payment reviews'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Needs review'),
            Tab(text: 'Payment attention'),
            Tab(text: 'Active'),
            Tab(text: 'Unsettled cash'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: ValueListenableBuilder<List<BookingModel>>(
        valueListenable: PrototypeSession.bookings,
        builder: (context, bookings, _) => TabBarView(
          children: [
            _list(
              context,
              bookings.where((b) => b.trip.reviewRequired).toList(),
            ),
            _list(
              context,
              bookings.where((b) {
                return b.paymentStatus == PaymentStatus.failed ||
                    b.paymentStatus == PaymentStatus.refundDue ||
                    b.paymentStatus == PaymentStatus.refundProcessing ||
                    b.paymentStatus == PaymentStatus.partiallyRefunded;
              }).toList(),
            ),
            _list(context, bookings.where((b) => b.isActive).toList()),
            _list(
              context,
              bookings
                  .where(
                    (b) =>
                        !b.isActive &&
                        !b.trip.reviewRequired &&
                        (b.amountDueCents > 0 || b.refundDueCents > 0),
                  )
                  .toList(),
            ),
            _list(context, bookings),
          ],
        ),
      ),
    ),
  );
  Widget _list(BuildContext context, List<BookingModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No bookings in this category.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: list
          .map(
            (b) => Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/admin/booking/${b.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        child: Icon(
                          b.trip.reviewRequired
                              ? Icons.flag_outlined
                              : b.paymentStatus == PaymentStatus.failed
                              ? Icons.error_outline_rounded
                              : Icons.receipt_long,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking ${b.id.length <= 8 ? b.id : b.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${b.touristName} · ${b.driverName ?? "No driver yet"}',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Chip(label: Text(b.status.name)),
                                Chip(
                                  avatar: const Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    b.trip.reviewRequired
                                        ? 'payment review'
                                        : b.paymentStatus.name,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

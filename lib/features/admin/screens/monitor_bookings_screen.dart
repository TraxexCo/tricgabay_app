import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/widgets/remote_page_controls.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/app_session.dart';
import '../../../models/booking_model.dart';
import '../../../core/l10n/record_labels.dart';

class MonitorBookingsScreen extends StatelessWidget {
  const MonitorBookingsScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      bottomNavigationBar: const RemotePageControls(directory: false),
      appBar: AppBar(
        title: Text(context.l10n.bookingsPaymentReviews),
        bottom: TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: context.l10n.needsReview),
            Tab(text: context.l10n.paymentAttention),
            Tab(text: context.l10n.active),
            Tab(text: context.l10n.unsettledCash),
            Tab(text: context.l10n.all),
          ],
        ),
      ),
      body: ValueListenableBuilder<List<BookingModel>>(
        valueListenable: AppSession.bookings,
        builder: (context, bookings, _) => TabBarView(
          children: [
            _list(
              context,
              bookings.where((b) => b.trip.reviewRequired).toList(),
            ),
            _list(
              context,
              bookings.where((b) {
                return b.paymentStatus == PaymentStatus.disputed ||
                    b.paymentStatus == PaymentStatus.failed ||
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
      return Center(child: Text(context.l10n.noBookingsInThisCategory));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final b = list[index];
        return Card(
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
                          context.l10n.bookingValue(
                            context.message(
                              (b.id.length <= 8 ? b.id : b.id.substring(0, 8))
                                  .toString(),
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.twoPartSummary(
                            context.message((b.touristName).toString()),
                            context.message(
                              (b.driverName ?? MessageCode.noDriverYet)
                                  .toString(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Chip(
                              label: Text(
                                bookingStatusLabel(context, b.status),
                              ),
                            ),
                            Chip(
                              avatar: const Icon(
                                Icons.payments_outlined,
                                size: 16,
                              ),
                              label: Text(
                                context.message(
                                  b.trip.reviewRequired
                                      ? MessageCode.paymentReview
                                      : paymentStatusLabel(
                                          context,
                                          b.paymentStatus,
                                        ),
                                ),
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
        );
      },
    );
  }
}

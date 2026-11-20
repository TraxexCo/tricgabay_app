import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/widgets/remote_page_controls.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/services/realtime_refresh_policy.dart';
import '../../../core/services/server_clock.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';
import '../../../core/l10n/record_labels.dart';

class DriverBookingsScreen extends StatefulWidget {
  const DriverBookingsScreen({super.key});

  @override
  State<DriverBookingsScreen> createState() => _DriverBookingsScreenState();
}

class _DriverBookingsScreenState extends State<DriverBookingsScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    PrototypeSession.bookings.addListener(_scheduleExpiry);
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _clock?.cancel();
    final now = ServerClock.now();
    DateTime? next;
    for (final booking in PrototypeSession.bookings.value) {
      if (booking.status != BookingStatus.pending ||
          booking.isDispatchExpired ||
          booking.isOfferExpired) {
        continue;
      }
      for (final deadline in [
        booking.dispatchExpiresAt,
        booking.offerExpiresAt,
      ]) {
        if (deadline != null &&
            deadline.isAfter(now) &&
            (next == null || deadline.isBefore(next))) {
          next = deadline;
        }
      }
    }
    if (next == null) return;
    _clock = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleExpiry();
    });
  }

  @override
  void dispose() {
    PrototypeSession.bookings.removeListener(_scheduleExpiry);
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      bottomNavigationBar: const RemotePageControls(directory: false),
      appBar: AppBar(
        title: Text(context.l10n.driverBookings),
        bottom: TabBar(
          tabs: [
            Tab(text: context.l10n.requests),
            Tab(text: context.l10n.active),
            Tab(text: context.l10n.history),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          PrototypeSession.bookings,
          PrototypeSession.isDriverOnline,
          PrototypeSession.adminDrivers,
          PrototypeSession.loadingSections,
        ]),
        builder: (context, _) {
          if (PrototypeSession.bookings.value.isEmpty &&
              PrototypeSession.loadingSections.value.contains(
                RemoteSection.bookings,
              )) {
            return const ListSkeleton();
          }
          final own = PrototypeSession.bookings.value
              .where(PrototypeSession.ownsDriverBooking)
              .toList();
          final canAccept =
              PrototypeSession.isDriverOnline.value &&
              !own.any((b) => b.isActive) &&
              PrototypeSession.adminDrivers.value.any(
                (d) =>
                    d['id'] == PrototypeSession.currentDriverId &&
                    d['status'] == 'active',
              );
          return TabBarView(
            children: [
              canAccept
                  ? _list(
                      context,
                      PrototypeSession.bookings.value
                          .where(
                            (b) =>
                                b.status == BookingStatus.pending &&
                                !b.isDispatchExpired &&
                                !b.isOfferExpired,
                          )
                          .toList(),
                      request: true,
                    )
                  : Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          context
                              .l10n
                              .goOnlineWithAnApprovedAccountAndFinishYourCurrentTripToAccept,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
              _list(context, own.where((b) => b.isActive).toList()),
              _list(context, own.where((b) => !b.isActive).toList()),
            ],
          );
        },
      ),
    ),
  );
  Widget _list(
    BuildContext context,
    List<BookingModel> bookings, {
    bool request = false,
  }) {
    if (bookings.isEmpty) {
      return Center(child: Text(context.l10n.noBookingsHereYet));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return Card(
          child: ListTile(
            title: Text(
              context.message(
                b.trip.packageName ??
                    MessageCode.stopCustomTourValue(
                      (b.stops.length).toString(),
                    ),
              ),
            ),
            subtitle: Text(
              context.l10n.threeLineSummary(
                context.message((b.touristName).toString()),
                context.message(bookingStatusLabel(context, b.status)),
                context.message(
                  (b.trip.reviewRequired
                          ? context.l10n.paymentReviewPending
                          : b.pickupAddress)
                      .toString(),
                ),
              ),
            ),
            isThreeLine: true,
            trailing: Text(
              context.l10n.agreedValue(
                context.message((AppFormatters.amount(b.totalFare)).toString()),
              ),
              textAlign: TextAlign.end,
            ),
            onTap: () => context.push(
              request ? '/driver/incoming/${b.id}' : '/driver/bookings/${b.id}',
            ),
          ),
        );
      },
    );
  }
}

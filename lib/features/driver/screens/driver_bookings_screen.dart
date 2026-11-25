import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/widgets/remote_page_controls.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/services/realtime_refresh_policy.dart';
import '../../../core/services/server_clock.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/app_session.dart';
import '../../../models/booking_model.dart';
import '../widgets/driver_trip_card.dart';

class DriverBookingsScreen extends StatefulWidget {
  const DriverBookingsScreen({super.key, this.initialTab = 0});

  static const historyTab = 2;

  /// The tab shown first; trip history from the account screen opens on
  /// History.
  final int initialTab;

  @override
  State<DriverBookingsScreen> createState() => _DriverBookingsScreenState();
}

class _DriverBookingsScreenState extends State<DriverBookingsScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    AppSession.bookings.addListener(_scheduleExpiry);
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _clock?.cancel();
    final now = ServerClock.now();
    DateTime? next;
    for (final booking in AppSession.bookings.value) {
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
    AppSession.bookings.removeListener(_scheduleExpiry);
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    initialIndex: widget.initialTab,
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
          AppSession.bookings,
          AppSession.isDriverOnline,
          AppSession.adminDrivers,
          AppSession.loadingSections,
        ]),
        builder: (context, _) {
          if (AppSession.bookings.value.isEmpty &&
              AppSession.loadingSections.value.contains(
                RemoteSection.bookings,
              )) {
            return const ListSkeleton();
          }
          final own = AppSession.bookings.value
              .where(AppSession.ownsDriverBooking)
              .toList();
          final canAccept =
              AppSession.isDriverOnline.value &&
              !own.any((b) => b.isActive) &&
              AppSession.adminDrivers.value.any(
                (d) =>
                    d['id'] == AppSession.currentDriverId &&
                    d['status'] == 'active',
              );
          return TabBarView(
            children: [
              canAccept
                  ? _list(
                      context,
                      AppSession.bookings.value
                          .where(
                            (b) =>
                                b.status == BookingStatus.pending &&
                                !b.isDispatchExpired &&
                                !b.isOfferExpired,
                          )
                          .toList(),
                      request: true,
                    )
                  : EmptyStateWidget(
                      icon: Icons.wifi_tethering_off_rounded,
                      title: context
                          .l10n
                          .goOnlineWithAnApprovedAccountAndFinishYourCurrentTripToAccept,
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
      return EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: context.l10n.noBookingsHereYet,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
      itemCount: bookings.length,
      itemBuilder: (context, index) => FadeSlideIn.staggered(
        index: index,
        child: Builder(
          builder: (context) {
            final b = bookings[index];
            return DriverTripCard(
              booking: b,
              showPickup: b.isActive || request,
              onTap: () => context.push(
                request
                    ? '/driver/incoming/${b.id}'
                    : '/driver/bookings/${b.id}',
              ),
            );
          },
        ),
      ),
    );
  }
}

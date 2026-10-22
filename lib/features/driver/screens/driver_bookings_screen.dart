import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';

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
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Driver bookings'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Requests'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          PrototypeSession.bookings,
          PrototypeSession.isDriverOnline,
          PrototypeSession.adminDrivers,
        ]),
        builder: (context, _) {
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
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Go online with an approved account and finish your current trip to accept a new request.',
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
      return const Center(child: Text('No bookings here yet.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: bookings
          .map(
            (b) => Card(
              child: ListTile(
                title: Text(
                  b.trip.packageName ?? '${b.stops.length} stop custom tour',
                ),
                subtitle: Text(
                  '${b.touristName} · ${b.status.name}\n${b.trip.reviewRequired ? "Payment review pending" : b.pickupAddress}',
                ),
                isThreeLine: true,
                trailing: Text(
                  'Agreed\n₱${b.totalFare.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                ),
                onTap: () => context.push(
                  request
                      ? '/driver/incoming/${b.id}'
                      : '/driver/bookings/${b.id}',
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

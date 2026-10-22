import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';

class FindDriverScreen extends StatefulWidget {
  const FindDriverScreen({super.key});
  @override
  State<FindDriverScreen> createState() => _FindDriverScreenState();
}

class _FindDriverScreenState extends State<FindDriverScreen> {
  late final String? _bookingId;
  Timer? _timer;
  bool _navigating = false;
  bool _refreshingOffers = false;
  DateTime? _lastOfferRefresh;
  @override
  void initState() {
    super.initState();
    _bookingId = PrototypeSession.activeBookingId;
    PrototypeSession.bookings.addListener(_updated);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      if (DateTime.now().second % 30 == 0) _refreshOffers();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updated();
      _refreshOffers();
    });
  }

  Future<void> _refreshOffers() async {
    if (_refreshingOffers || _bookingId == null) return;
    final booking = PrototypeSession.bookings.value
        .where((item) => item.id == _bookingId)
        .firstOrNull;
    if (booking == null ||
        booking.status != BookingStatus.pending ||
        booking.isDispatchExpired) {
      return;
    }
    if (_lastOfferRefresh != null &&
        DateTime.now().difference(_lastOfferRefresh!).inSeconds < 25) {
      return;
    }
    _refreshingOffers = true;
    _lastOfferRefresh = DateTime.now();
    try {
      await PrototypeSession.refreshDriverOffers(booking.id);
    } catch (_) {
      // Realtime or the next scheduled refresh can recover without interrupting
      // the tourist's waiting screen.
    } finally {
      _refreshingOffers = false;
    }
  }

  void _updated() {
    if (!mounted || _navigating) return;
    final booking = PrototypeSession.bookings.value
        .where((b) => b.id == _bookingId)
        .firstOrNull;
    if (booking?.status == BookingStatus.accepted ||
        booking?.status == BookingStatus.ongoing) {
      _navigating = true;
      context.pushReplacement('/tourist/tracking/$_bookingId');
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    PrototypeSession.bookings.removeListener(_updated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = PrototypeSession.bookings.value
        .where((b) => b.id == _bookingId)
        .firstOrNull;
    final pending =
        b?.status == BookingStatus.pending && !(b?.isDispatchExpired ?? false);
    final expired = b?.isDispatchExpired ?? false;
    final remaining = b?.dispatchExpiresAt?.difference(DateTime.now());
    final remainingSeconds = remaining == null || remaining.isNegative
        ? 0
        : remaining.inSeconds;
    final countdown =
        '${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Find a driver')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(pending ? Icons.radar : Icons.receipt_long, size: 72),
              const SizedBox(height: 24),
              Text(
                pending
                    ? 'Looking for a driver'
                    : expired
                    ? 'Search window ended'
                    : 'Request is no longer pending',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                pending
                    ? 'Drivers have $countdown to accept this search request. You can leave this screen and return through Trips. No fare is charged while waiting.'
                    : expired
                    ? 'No driver accepted during this search window. Retry to open a fresh request or cancel without charge.'
                    : 'Open Trips to see the latest booking status.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (expired && b != null)
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await PrototypeSession.retryDriverSearch(b.id);
                      await _refreshOffers();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$error')));
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Search again'),
                )
              else
                FilledButton(
                  onPressed: () => context.go('/tourist/bookings'),
                  child: const Text('View my trips'),
                ),
              if (b != null)
                TextButton(
                  onPressed: () => context.push('/tourist/bookings/${b.id}'),
                  child: const Text('Booking details / cancel'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/server_clock.dart';
import '../../../core/services/error_messages.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/app_session.dart';
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
  @override
  void initState() {
    super.initState();
    _bookingId = AppSession.activeBookingId;
    AppSession.bookings.addListener(_updated);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updated();
    });
  }

  void _updated() {
    if (!mounted || _navigating) return;
    final booking = AppSession.bookings.value
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
    AppSession.bookings.removeListener(_updated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = AppSession.bookings.value
        .where((b) => b.id == _bookingId)
        .firstOrNull;
    final pending =
        b?.status == BookingStatus.pending && !(b?.isDispatchExpired ?? false);
    final expired = b?.isDispatchExpired ?? false;
    final remaining = b?.dispatchExpiresAt?.difference(ServerClock.now());
    final remainingSeconds = remaining == null || remaining.isNegative
        ? 0
        : remaining.inSeconds;
    final countdown =
        '${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.findADriver)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(pending ? Icons.radar : Icons.receipt_long, size: 72),
              const SizedBox(height: 24),
              Text(
                context.message(
                  pending
                      ? MessageCode.lookingForADriver
                      : expired
                      ? MessageCode.searchWindowEnded
                      : MessageCode.requestIsNoLongerPending,
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.message(
                  pending
                      ? MessageCode.driversHaveToAcceptThisSearchRequestYouCanLeaveThisScreenAndValue(
                          (countdown).toString(),
                        )
                      : expired
                      ? MessageCode
                            .noDriverAcceptedDuringThisSearchWindowRetryToOpenAFreshRequest
                      : MessageCode.openTripsToSeeTheLatestBookingStatus,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (expired && b != null)
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await AppSession.retryDriverSearch(b.id);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.message(ErrorMessages.forError(error)),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.searchAgain),
                )
              else
                FilledButton(
                  onPressed: () => context.go('/tourist/bookings'),
                  child: Text(context.l10n.viewMyTrips),
                ),
              if (b != null)
                TextButton(
                  onPressed: () => context.push('/tourist/bookings/${b.id}'),
                  child: Text(context.l10n.bookingDetailsCancel),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

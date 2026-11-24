import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/server_clock.dart';
import '../../../core/services/error_messages.dart';
import 'dart:async';
import '../../../core/services/backend_repository.dart';

import 'package:flutter/material.dart';
import '../../../core/motion/motion.dart';
import '../../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/app_session.dart';
import '../../../core/services/trip_rules.dart';
import '../../../models/booking_model.dart';
import '../../../models/trip_record.dart';
import '../../../core/l10n/record_labels.dart';
import 'gcash_trip_payment.dart';

part 'booking_detail_actions.dart';
part 'booking_detail_sections.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final TripActor viewer;
  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.viewer = TripActor.tourist,
  });
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _busy = false;
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

  String money(int cents) => '₱${AppFormatters.amount((cents / 100))}';

  Duration _waitRemaining(BookingModel booking) {
    final deadline = booking.trip.pickupWaitExpiresAt;
    if (deadline == null) return Duration.zero;
    final remaining = deadline.difference(ServerClock.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _clockLabel(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _cancellationExplanation(BookingModel booking) {
    if (booking.status == BookingStatus.scheduled ||
        booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.replacementPending ||
        widget.viewer == TripActor.driver ||
        booking.isWithinFreeCancellation) {
      return MessageCode
          .thisCancellationIsCurrentlyFreeGiveTheRealReasonSoTheEventCan;
    }
    return MessageCode.cancellationGraceExpired(
      booking.freeCancellationMinutes,
      booking.acceptedCancellationPercent,
      money(booking.lateCancellationFeeCents),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.message(ErrorMessages.forError(e)))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<BookingModel>>(
    valueListenable: AppSession.bookings,
    builder: (context, bookings, _) {
      final b = bookings
          .where((item) => item.id == widget.bookingId)
          .firstOrNull;
      final driver = widget.viewer == TripActor.driver;
      final admin = widget.viewer == TripActor.admin;
      final allowed =
          b != null &&
          (admin ||
              (driver
                  ? AppSession.ownsDriverBooking(b)
                  : b.touristId == AppSession.currentTouristId));
      if (!allowed) {
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.booking)),
          body: Center(child: Text(context.l10n.bookingNotFoundForThisAccount)),
        );
      }
      final booking = b;
      if (booking.status == BookingStatus.unknown ||
          booking.paymentMethod == PaymentMethod.unknown ||
          booking.paymentStatus == PaymentStatus.unknown) {
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.booking)),
          body: Center(
            child: Text(
              context
                  .l10n
                  .thisTripUsesANewerStatusUpdateTheAppOrContactSupportBefore,
            ),
          ),
        );
      }
      final t = booking.trip;
      final cashConfirmed = driver
          ? t.driverCashConfirmed
          : t.touristCashConfirmed;
      final refundConfirmed = driver
          ? t.driverRefundConfirmed
          : t.touristRefundConfirmed;
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.tripPayment)),
        backgroundColor: AppColors.background,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _hero(booking),
            const SizedBox(height: 16),
            // The pickup code is what the tourist needs at the curb, so it
            // comes before the details.
            if (!admin && !driver && booking.status == BookingStatus.accepted)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.l10n.shareThisCodeOnlyWhenYouAreOnBoard,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      t.pickupCode,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            _summaryCard(booking, admin: admin),
            if (booking.status == BookingStatus.replacementPending)
              _replacementCard(booking, driver: driver, admin: admin),
            if (!admin &&
                !driver &&
                // The code is only shown once a driver has accepted, so
                // that is the only time there is one to lose.
                booking.status == BookingStatus.accepted)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        final approved = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(context.l10n.reissuePickupCode),
                            content: Text(
                              context
                                  .l10n
                                  .yourPreviousCodeWillStopWorkingShareTheNewCodeOnlyAfterBoarding,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(context.l10n.keepCurrentCode),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(context.l10n.reissueCode),
                              ),
                            ],
                          ),
                        );
                        if (approved != true) return;
                        await BackendRepository.reissuePickupCode(booking.id);
                        await AppSession.syncRemoteState();
                      }),
                child: Text(context.l10n.lostPickupCodeReissue),
              ),
            _routeProgress(booking),
            if (booking.pendingRouteChange != null) _routeChangeCard(booking),
            if (booking.interruptedAt != null)
              _breakdownCard(booking, driver: driver, admin: admin),
            if (!admin && booking.isActive) ...[
              if (booking.status == BookingStatus.scheduled)
                Text(
                  context
                      .l10n
                      .yourTourIsReservedDriverMatchingBegins30MinutesBeforePickupAndReminders,
                ),
              if (booking.status == BookingStatus.pending)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context
                          .l10n
                          .waitingForADriverToAcceptYouCanLeaveThisPageAndResume,
                    ),
                    if (!driver)
                      _button(MessageCode.openDriverSearch, () async {
                        context.push('/tourist/find-driver');
                      }),
                  ],
                ),
              if (booking.status == BookingStatus.accepted ||
                  booking.status == BookingStatus.ongoing)
                _button(MessageCode.openTripMap, () async {
                  context.push(
                    driver
                        ? '/driver/trip/${booking.id}'
                        : '/tourist/tracking/${booking.id}',
                  );
                }),
              if (driver && booking.status == BookingStatus.accepted) ...[
                if (t.pickupArrivedAt == null)
                  _button(
                    MessageCode.arrivedAtPickup,
                    () =>
                        _run(() => AppSession.reportPickupArrival(booking.id)),
                  ),
                if (t.pickupArrivedAt != null)
                  _button(MessageCode.verifyPickupCodeStart, () async {
                    final code = await _input(
                      MessageCode.verifyPickup,
                      MessageCode
                          .askTheTouristForTheirCodeAfterTheyAreSafelyOnBoard,
                      code: true,
                    );
                    if (code != null && mounted) {
                      await _run(() => AppSession.startTrip(booking.id, code));
                    }
                  }),
                if (t.pickupWaitExpiresAt != null &&
                    _waitRemaining(booking) == Duration.zero)
                  _button(
                    MessageCode.reportTouristNoShowLabel,
                    () => _confirmNoShow(booking),
                    outlined: true,
                  ),
                _button(
                  MessageCode.requestPickupReplacement,
                  () => _requestReplacement(booking),
                  outlined: true,
                ),
              ],
              if (booking.status == BookingStatus.ongoing) ...[
                if (booking.interruptedAt == null &&
                    booking.pendingRouteChange == null &&
                    booking.stops.length - t.confirmedStops > 1)
                  _button(
                    MessageCode.requestADifferentStopOrder,
                    () => _proposeReorder(booking),
                    outlined: true,
                  ),
                if (driver &&
                    booking.interruptedAt == null &&
                    booking.pendingRouteChange == null &&
                    !t.arrivalPending &&
                    t.confirmedStops < booking.stops.length)
                  _button(
                    MessageCode.reportArrivalAtNextStop,
                    () => _run(() => AppSession.reportArrival(booking.id)),
                  ),
                if (!driver &&
                    booking.interruptedAt == null &&
                    t.arrivalPending)
                  _button(
                    MessageCode.confirmReachedStop,
                    () => _run(() => AppSession.confirmArrival(booking.id)),
                  ),
                if (driver &&
                    booking.interruptedAt == null &&
                    t.confirmedStops == booking.stops.length)
                  _button(
                    booking.paymentMethod == PaymentMethod.gcashDirect
                        ? context.l10n.gcashCompleteTrip
                        : MessageCode.completeTripCashStillUnconfirmed,
                    () => _run(() => AppSession.completeTrip(booking.id)),
                  ),
                if (driver && booking.interruptedAt == null)
                  _button(
                    MessageCode.vehicleProblemPauseTripSafely,
                    () => _reportBreakdown(booking),
                    outlined: true,
                  ),
              ],
              if (booking.status != BookingStatus.replacementPending &&
                  !(driver && booking.status == BookingStatus.accepted))
                _button(
                  booking.status == BookingStatus.ongoing
                      ? MessageCode.endTourEarlyReportAProblem
                      : booking.status == BookingStatus.scheduled ||
                            booking.status == BookingStatus.pending ||
                            driver ||
                            booking.isWithinFreeCancellation
                      ? MessageCode.cancelBookingNoCharge
                      : MessageCode.cancelBookingFeeValue(
                          (booking.acceptedCancellationPercent).toString(),
                        ),
                  () => _cancel(booking),
                  outlined: true,
                ),
            ],
            if (!admin &&
                booking.status == BookingStatus.completed &&
                booking.paymentMethod == PaymentMethod.gcashDirect &&
                booking.amountDueCents > 0 &&
                const {
                  PaymentStatus.unpaid,
                  PaymentStatus.gcashAwaitingConfirmation,
                  PaymentStatus.disputed,
                }.contains(booking.paymentStatus))
              GcashTripPayment(
                key: ValueKey(booking.id),
                booking: booking,
                driver: driver,
              ),
            if (admin &&
                booking.paymentMethod == PaymentMethod.gcashDirect &&
                booking.paymentStatus == PaymentStatus.disputed)
              _button(
                MessageCode.adminGcashDisputes,
                () async => context.push('/admin/gcash-disputes/${booking.id}'),
              ),
            if (!admin &&
                !booking.isActive &&
                !t.reviewRequired &&
                booking.paymentMethod != PaymentMethod.gcashDirect) ...[
              if (booking.amountDueCents > 0)
                _button(
                  cashConfirmed
                      ? MessageCode.waitingForTheOtherCashConfirmation
                      : driver
                      ? MessageCode.confirmCashReceived
                      : MessageCode.confirmCashPaid,
                  cashConfirmed ? null : () => _cash(booking, false),
                ),
              if (booking.refundDueCents > 0 &&
                  booking.paymentMethod == PaymentMethod.cash)
                _button(
                  refundConfirmed
                      ? MessageCode.waitingForCashReturnConfirmation
                      : driver
                      ? MessageCode.confirmCashReturnedLabel
                      : MessageCode.confirmCashReturnReceived,
                  refundConfirmed ? null : () => _cash(booking, true),
                ),
              _button(MessageCode.disputePaymentReportAProblem, () async {
                final reason = await _input(
                  MessageCode.openAPaymentReview,
                  MessageCode
                      .describeTheDisagreementCollectionAndRefundConfirmationsWillPauseUntilAnAdminReviews,
                );
                if (reason != null && mounted) {
                  await _run(
                    () => AppSession.disputeBooking(
                      booking.id,
                      widget.viewer,
                      reason,
                    ),
                  );
                }
              }, outlined: true),
            ],
            if (t.reviewRequired) ...[
              _button(MessageCode.addAStatementToThisCase, () async {
                final text = await _input(
                  MessageCode.addYourStatement,
                  MessageCode
                      .includeWhatHappenedWhereTheTripStoppedAndAnyCashAlreadyExchangedStatements,
                );
                if (text != null && mounted) {
                  await _run(
                    () => AppSession.addCaseStatement(
                      booking.id,
                      widget.viewer,
                      text,
                    ),
                  );
                }
              }, outlined: true),
              if (admin)
                _button(MessageCode.reviewFinalCharge, () => _resolve(booking)),
            ],
            if (!admin &&
                !driver &&
                booking.status == BookingStatus.completed &&
                booking.driverRating == null)
              _button(MessageCode.rateDriver, () async {
                context.push('/tourist/review/${booking.id}');
              }, outlined: true),
            if (!admin && booking.isActive)
              TextButton.icon(
                onPressed: () => context.push(
                  driver ? '/driver/emergency' : '/tourist/emergency',
                ),
                icon: const Icon(Icons.emergency_outlined),
                label: Text(context.l10n.emergencyHelp),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Material(
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.policy_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(context.l10n.agreedPolicy),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [Text(context.message(TripRules.policyText))],
                  ),
                ),
              ),
            ),
            _history(booking),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
  Widget _button(
    String text,
    Future<void> Function()? action, {
    bool outlined = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: outlined
        ? OutlinedButton(
            onPressed: _busy ? null : action,
            child: Text(context.message(text)),
          )
        : FilledButton(
            onPressed: _busy ? null : action,
            // The pressed button itself shows the work in progress.
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.medium),
              child: _busy
                  ? Row(
                      key: const ValueKey('busy'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(context.message(MessageCode.saving)),
                      ],
                    )
                  : Text(context.message(text), key: ValueKey(text)),
            ),
          ),
  );
  String _paymentLabel(BookingModel booking) => switch (booking.paymentStatus) {
    PaymentStatus.unknown =>
      MessageCode.paymentStatusUnavailableRefreshOrUpdateTheApp,
    PaymentStatus.unpaid => switch (booking.paymentMethod) {
      PaymentMethod.gcashDirect => context.l10n.unpaid,
      PaymentMethod.cash => MessageCode.cashNotConfirmed,
      _ => MessageCode.onlinePaymentNotStarted,
    },
    PaymentStatus.checkoutCreated => MessageCode.paymongoCheckoutReady,
    PaymentStatus.processing => MessageCode.paymongoIsProcessingPayment,
    PaymentStatus.failed => MessageCode.onlinePaymentFailedRetryAvailable,
    PaymentStatus.awaitingConfirmation =>
      MessageCode.awaitingBothCashConfirmations,
    PaymentStatus.gcashAwaitingConfirmation =>
      widget.viewer == TripActor.driver
          ? context.l10n.gcashAwaitingYour
          : context.l10n.gcashAwaitingDriver,
    PaymentStatus.disputed => context.l10n.gcashDisputed,
    PaymentStatus.underReview => MessageCode.adminReviewPaymentOnHold,
    PaymentStatus.paid => switch (booking.paymentMethod) {
      PaymentMethod.gcashDirect => context.l10n.gcashPaidByDriver,
      PaymentMethod.cash => MessageCode.cashConfirmedByBothParties,
      _ => MessageCode.paidOnline,
    },
    PaymentStatus.waived => MessageCode.noCharge,
    PaymentStatus.refundDue =>
      booking.paymentMethod == PaymentMethod.cash
          ? MessageCode.cashReturnOutstanding
          : MessageCode.onlineRefundAwaitingAdminAction,
    PaymentStatus.refundProcessing =>
      MessageCode.refundSentAwaitingPaymongoConfirmation,
    PaymentStatus.partiallyRefunded => MessageCode.partiallyRefunded,
    PaymentStatus.refunded =>
      booking.paymentMethod == PaymentMethod.cash
          ? MessageCode.cashReturnConfirmed
          : MessageCode.refundCompleted,
  };
}

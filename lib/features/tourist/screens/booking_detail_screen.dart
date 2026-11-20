import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/server_clock.dart';
import '../../../core/services/error_messages.dart';
import 'dart:async';
import '../../../core/services/backend_repository.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/services/trip_rules.dart';
import '../../../models/booking_model.dart';
import '../../../models/trip_record.dart';
import '../../../core/l10n/record_labels.dart';
import 'gcash_trip_payment.dart';

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

  Future<String?> _input(
    String title,
    String explanation, {
    bool code = false,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.message(title)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.message(explanation)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: code ? 4 : 1000,
                maxLines: code ? 1 : 3,
                keyboardType: code
                    ? TextInputType.number
                    : TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: context.message(
                    code ? MessageCode.pickupCode : MessageCode.reasonDetails,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                scrollPadding: const EdgeInsets.all(96),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.goBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
    // Dialog fields finish their exit animation before their controllers dispose.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    return result;
  }

  Future<void> _cancel(BookingModel b) async {
    final reason = await _input(
      b.status == BookingStatus.ongoing
          ? MessageCode.endTourEarly
          : MessageCode.cancelBooking,
      b.status == BookingStatus.ongoing
          ? MessageCode
                .stopAtASafePlaceFirstTheTripWillEndImmediatelyPaymentWill
          : _cancellationExplanation(b),
    );
    if (reason != null && mounted) {
      await _run(
        () => PrototypeSession.cancelBooking(
          b.id,
          actor: widget.viewer,
          reason: reason,
        ),
      );
    }
  }

  Future<void> _requestReplacement(BookingModel booking) async {
    final reason = await _input(
      MessageCode.requestAnotherDriver,
      MessageCode.useThisOnlyIfYouCannotCompleteThePickupTheTouristWillDecide,
    );
    if (reason != null && mounted) {
      await _run(
        () => PrototypeSession.requestDriverReplacement(booking.id, reason),
      );
    }
  }

  Future<void> _decideReplacement(
    BookingModel booking, {
    required bool findReplacement,
  }) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.message(
            findReplacement
                ? MessageCode.findAnotherDriverLabel
                : MessageCode.cancelThisBooking,
          ),
        ),
        content: Text(
          context.message(
            findReplacement
                ? MessageCode
                      .yourFixedFareRouteAndPaymentRecordStayUnchangedThePreviousDriverIs
                : MessageCode
                      .theBookingWillEndWithoutACancellationChargeIfAnOnlinePaymentWas,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.notYet),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.message(
                findReplacement
                    ? MessageCode.startNewSearch
                    : MessageCode.cancelFree,
              ),
            ),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await _run(
        () => PrototypeSession.decideDriverReplacement(
          booking.id,
          findReplacement: findReplacement,
        ),
      );
    }
  }

  Future<void> _confirmNoShow(BookingModel booking) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.reportTouristNoShow),
        content: Text(
          context.l10n
              .confirmThatYouStayedAtTheVerifiedPickupPointUntilTheWaitingPeriodValue(
                context.message((booking.noShowFeePercent).toString()),
                context.message((money(booking.noShowFeeCents)).toString()),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.keepWaiting),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.confirmNoShow),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await _run(() => PrototypeSession.declareTouristNoShow(booking.id));
    }
  }

  Future<void> _proposeSkip(BookingModel booking, BookingStop stop) async {
    final reason = await _input(
      MessageCode.requestToSkipValue((stop.spotName).toString()),
      MessageCode
          .theOtherParticipantMustApproveIfApprovedFinalPaymentWillBeHeldFor,
    );
    if (reason != null && mounted) {
      await _run(
        () => PrototypeSession.proposeRouteChange(
          booking.id,
          type: 'skip',
          targetStopId: stop.id,
          reason: reason,
        ),
      );
    }
  }

  Future<void> _proposeReorder(BookingModel booking) async {
    final remaining = booking.stops.skip(booking.trip.confirmedStops).toList();
    if (remaining.length < 2) return;
    final reason = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.proposeANewStopOrder),
          content: SizedBox(
            width: double.maxFinite,
            height: 360,
            child: Column(
              children: [
                Text(
                  context
                      .l10n
                      .onlyUnvisitedStopsMoveTheOtherParticipantMustApproveBeforeNavigationChanges,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: remaining.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setDialogState(() {
                        final item = remaining.removeAt(oldIndex);
                        remaining.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) => ListTile(
                      key: ValueKey(remaining[index].id),
                      leading: CircleAvatar(
                        child: Text(context.message('${index + 1}')),
                      ),
                      title: Text(context.message(remaining[index].spotName)),
                      trailing: const Icon(Icons.drag_handle),
                    ),
                  ),
                ),
                TextField(
                  controller: reason,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: context.l10n.reasonForChangingTheOrder,
                    border: OutlineInputBorder(),
                  ),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  scrollPadding: const EdgeInsets.all(96),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.goBack),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.sendProposal),
            ),
          ],
        ),
      ),
    );
    final explanation = reason.text.trim();
    reason.dispose();
    if (approved != true || explanation.length < 5 || !mounted) return;
    await _run(
      () => PrototypeSession.proposeRouteChange(
        booking.id,
        type: 'reorder',
        proposedOrder: remaining.map((stop) => stop.id).toList(),
        reason: explanation,
      ),
    );
  }

  Future<void> _decideRouteChange(
    BookingModel booking, {
    required bool approve,
  }) async {
    final request = booking.pendingRouteChange;
    if (request == null) return;
    await _run(
      () => PrototypeSession.decideRouteChange(
        booking.id,
        request.id,
        approve: approve,
      ),
    );
  }

  Future<void> _reportBreakdown(BookingModel booking) async {
    final reason = await _input(
      MessageCode.pauseForAVehicleProblem,
      MessageCode
          .stopSomewhereSafeFirstYourCurrentGpsLocationAndExplanationWillBeRecorded,
    );
    if (reason != null && mounted) {
      await _run(
        () => PrototypeSession.reportVehicleBreakdown(booking.id, reason),
      );
    }
  }

  Future<void> _resolve(BookingModel b) async {
    final amount = TextEditingController(
      text: AppFormatters.decimalInput((TripRules.suggestedCharge(b) / 100)),
    );
    final reason = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.resolvePaymentReview),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n
                    .agreedMaximumStopsConfirmedByTheTouristTheSuggestedProratedAmountIsAValue(
                      context.message((money(b.quotedCents)).toString()),
                      context.message((b.trip.confirmedStops).toString()),
                      context.message((b.stops.length).toString()),
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.finalCharge,
                  border: OutlineInputBorder(),
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                scrollPadding: const EdgeInsets.all(96),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reason,
                maxLength: 1000,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.decisionAndReasoning,
                  border: OutlineInputBorder(),
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                scrollPadding: const EdgeInsets.all(96),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.keepUnderReview),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.saveDecision),
          ),
        ],
      ),
    );
    final rawAmount = amount.text.trim();
    final explanation = reason.text;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    amount.dispose();
    reason.dispose();
    if (approved != true || !mounted) return;
    await _run(() async {
      if (!RegExp(r'^\d{1,6}(\.\d{1,2})?$').hasMatch(rawAmount)) {
        throw const TripRuleException(
          MessageCode.enterAValidAmountWithAtMostTwoDecimals,
        );
      }
      await PrototypeSession.resolveSettlement(
        b.id,
        (double.parse(rawAmount) * 100).round(),
        explanation,
      );
    });
  }

  Future<void> _cash(BookingModel b, bool refund) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.message(
            refund
                ? MessageCode.confirmCashReturned
                : MessageCode.confirmCashExchanged,
          ),
        ),
        content: Text(
          context.l10n
              .confirmOnlyAfterHasPhysicallyChangedHandsTheOtherPartyMustConfirmTooValue(
                context.message(
                  (money(
                    refund ? b.refundDueCents : b.amountDueCents,
                  )).toString(),
                ),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.notYet),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.confirmAmount),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await _run(
        () => PrototypeSession.confirmCash(b.id, widget.viewer, refund: refund),
      );
    }
  }

  Future<void> _showFinancialRecord(BookingModel booking) async {
    await _run(() async {
      final entries = await PrototypeSession.financialLedger(booking.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.financialRecord,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context
                        .l10n
                        .confirmedEntriesArePermanentAndCannotBeEditedOrDeleted,
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(context.l10n.noConfirmedMoneyMovementYet),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final debit = entry['direction'] == 'debit';
                          final at = DateTime.parse(
                            entry['occurred_at'] as String,
                          ).toLocal();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Icon(
                                debit
                                    ? Icons.undo_rounded
                                    : Icons.check_rounded,
                              ),
                            ),
                            title: Text(
                              context.message(
                                (entry['description'] as String)
                                        .toLowerCase()
                                        .contains('simulated')
                                    ? MessageCode.refundCompleted
                                    : entry['description'] as String,
                              ),
                            ),
                            subtitle: Text(
                              context.l10n.modeValueLabel(
                                context.message(
                                  (entry['provider'].toString().toUpperCase())
                                      .toString(),
                                ),
                                context.message(
                                  (entry['provider_mode']).toString(),
                                ),
                                context.message(
                                  (at.toString().split('.').first).toString(),
                                ),
                              ),
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              context.message(
                                '${debit ? '−' : '+'}${money(entry['amount_centavos'] as int)}',
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: debit
                                    ? Colors.orange.shade800
                                    : Colors.green.shade700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<BookingModel>>(
    valueListenable: PrototypeSession.bookings,
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
                  ? PrototypeSession.ownsDriverBooking(b)
                  : b.touristId == PrototypeSession.currentTouristId));
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
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              context.message(
                booking.trip.packageName ?? MessageCode.customTour,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              context.message(booking.id),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row(
                      MessageCode.trip,
                      bookingStatusLabel(context, booking.status),
                    ),
                    _row(
                      MessageCode.agreedFixedFare,
                      money(booking.quotedCents),
                    ),
                    _row(MessageCode.priceVersion, 'v${t.fareRevision}'),
                    _row(MessageCode.payment, _paymentLabel(booking)),
                    // Historical PayMongo bookings stay readable for finance.
                    if (admin &&
                        booking.paymentMethod == PaymentMethod.online) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _showFinancialRecord(booking),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(context.l10n.financialRecord),
                      ),
                    ],
                    if (t.reviewRequired)
                      Text(
                        context
                            .l10n
                            .paymentIsOnHoldAnAdminMustReviewTheCaseBeforeCollectionOr,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    if (!booking.isActive && !t.reviewRequired) ...[
                      _row(
                        MessageCode.finalChargeLabel,
                        money(t.finalChargeCents ?? 0),
                      ),
                      _row(switch (booking.paymentMethod) {
                        PaymentMethod.cash => MessageCode.cashConfirmedByBoth,
                        PaymentMethod.gcashDirect =>
                          context.l10n.gcashAmountReceived,
                        _ => MessageCode.onlinePaymentReceived,
                      }, money(t.receivedCents)),
                      _row(
                        MessageCode.stillToPay,
                        money(booking.amountDueCents),
                      ),
                      if (booking.refundDueCents > 0)
                        _row(
                          booking.paymentMethod == PaymentMethod.cash
                              ? MessageCode.cashToReturn
                              : MessageCode.onlineRefundDue,
                          money(booking.refundDueCents),
                        ),
                    ],
                    if (booking.driverName != null)
                      _row(
                        MessageCode.driver,
                        '${booking.driverName} · ${booking.driverPlate ?? ""}',
                      ),
                    _row(MessageCode.pickup, booking.pickupAddress),
                    if (booking.scheduledAt != null)
                      _row(
                        MessageCode.scheduledPickup,
                        ServerClock.formatManila(booking.scheduledAt!),
                      ),
                    _row(MessageCode.passengers, '${booking.passengerCount}'),
                    if (booking.luggageNotes.isNotEmpty)
                      _row(MessageCode.luggage, booking.luggageNotes),
                    if (booking.accessibilityNeeds.isNotEmpty)
                      _row(MessageCode.assistance, booking.accessibilityNeeds),
                    if (t.pickupArrivedAt != null) ...[
                      _row(
                        MessageCode.driverArrival,
                        MessageCode.verifiedNearThePickupPoint,
                      ),
                      _row(
                        MessageCode.pickupWait,
                        _waitRemaining(booking) == Duration.zero
                            ? MessageCode.waitingPeriodCompleted
                            : '${_clockLabel(_waitRemaining(booking))} remaining',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (booking.status == BookingStatus.replacementPending)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.driverReplacementRequested,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.message(
                          booking.replacementReason ??
                              MessageCode.theAssignedDriverIsUnavailable,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (driver)
                        Text(
                          context
                              .l10n
                              .waitingForTheTouristToChooseDoNotProceedToPickup,
                        )
                      else if (!admin) ...[
                        FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _decideReplacement(
                                  booking,
                                  findReplacement: true,
                                ),
                          icon: const Icon(Icons.person_search_outlined),
                          label: Text(context.l10n.findAnotherDriver),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _decideReplacement(
                                  booking,
                                  findReplacement: false,
                                ),
                          child: Text(context.l10n.cancelFreeOfCharge),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (!admin &&
                !driver &&
                const [
                  BookingStatus.paymentPending,
                  BookingStatus.scheduled,
                  BookingStatus.pending,
                  BookingStatus.accepted,
                ].contains(booking.status))
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
                        await PrototypeSession.syncRemoteState();
                      }),
                child: Text(context.l10n.lostPickupCodeReissue),
              ),
            if (!admin && !driver && booking.status == BookingStatus.accepted)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(context.l10n.shareThisCodeOnlyWhenYouAreOnBoard),
                      SelectableText(
                        t.pickupCode,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              context.l10n.routeProgressConfirmedValue(
                context.message((t.confirmedStops).toString()),
                context.message((booking.stops.length).toString()),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...booking.stops.asMap().entries.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  e.key < t.confirmedStops
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                title: Text(context.message(e.value.spotName)),
                subtitle: e.key == t.confirmedStops && t.arrivalPending
                    ? Text(context.l10n.driverReportedArrivalAwaitingTourist)
                    : null,
                trailing:
                    booking.status == BookingStatus.ongoing &&
                        booking.interruptedAt == null &&
                        booking.pendingRouteChange == null &&
                        e.key >= t.confirmedStops &&
                        booking.stops.length - t.confirmedStops > 1
                    ? IconButton(
                        tooltip: context.l10n.requestToSkipThisStop,
                        onPressed: _busy
                            ? null
                            : () => _proposeSkip(booking, e.value),
                        icon: const Icon(Icons.skip_next_outlined),
                      )
                    : null,
              ),
            ),
            if (booking.pendingRouteChange != null)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.message(
                          booking.pendingRouteChange!.type == 'skip'
                              ? MessageCode.stopSkipApprovalNeeded
                              : MessageCode.routeReorderApprovalNeeded,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(context.message(booking.pendingRouteChange!.reason)),
                      if (booking.pendingRouteChange!.type == 'skip')
                        Text(
                          context.l10n.stopValue(
                            context.message(
                              (booking.stops
                                          .where(
                                            (stop) =>
                                                stop.id ==
                                                booking
                                                    .pendingRouteChange!
                                                    .targetStopId,
                                          )
                                          .firstOrNull
                                          ?.spotName ??
                                      MessageCode.selectedStop)
                                  .toString(),
                            ),
                          ),
                        ),
                      if (booking.pendingRouteChange!.type == 'reorder') ...[
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.proposedValue(
                            context.message(
                              (booking.pendingRouteChange!.proposedOrder
                                      .map(
                                        (id) =>
                                            booking.stops
                                                .where((stop) => stop.id == id)
                                                .firstOrNull
                                                ?.spotName ??
                                            MessageCode.stop,
                                      )
                                      .join(MessageCode.formattedValue))
                                  .toString(),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (booking.pendingRouteChange!.requestedBy ==
                          PrototypeSession.authenticatedUserId)
                        Text(
                          context
                              .l10n
                              .waitingForTheOtherParticipantNavigationStaysOnTheCurrentRoute,
                        )
                      else ...[
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () =>
                                    _decideRouteChange(booking, approve: true),
                          child: Text(context.l10n.approveRouteChange),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () =>
                                    _decideRouteChange(booking, approve: false),
                          child: Text(context.l10n.keepOriginalRoute),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (booking.interruptedAt != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.tripPausedVehicleProblem,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.message(
                          booking.interruptionReason ??
                              MessageCode.theDriverReportedAVehicleProblem,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!driver &&
                          !admin &&
                          booking.touristWaitConfirmedAt == null) ...[
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => PrototypeSession.decideBreakdownWait(
                                    booking.id,
                                    wait: true,
                                  ),
                                ),
                          child: Text(context.l10n.waitForThisDriver),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => PrototypeSession.decideBreakdownWait(
                                    booking.id,
                                    wait: false,
                                  ),
                                ),
                          child: Text(context.l10n.endSafelyReviewPayment),
                        ),
                      ] else if (driver &&
                          booking.touristWaitConfirmedAt != null)
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => PrototypeSession.resumeAfterBreakdown(
                                    booking.id,
                                  ),
                                ),
                          child: Text(context.l10n.vehicleIsSafeResumeTrip),
                        )
                      else
                        Text(
                          context.message(
                            driver
                                ? MessageCode.waitingForTheTouristSDecision
                                : MessageCode
                                      .youChoseToWaitTheDriverMustConfirmTheVehicleIsSafeBefore,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
                    () => _run(
                      () => PrototypeSession.reportPickupArrival(booking.id),
                    ),
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
                      await _run(
                        () => PrototypeSession.startTrip(booking.id, code),
                      );
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
                    () =>
                        _run(() => PrototypeSession.reportArrival(booking.id)),
                  ),
                if (!driver &&
                    booking.interruptedAt == null &&
                    t.arrivalPending)
                  _button(
                    MessageCode.confirmReachedStop,
                    () =>
                        _run(() => PrototypeSession.confirmArrival(booking.id)),
                  ),
                if (driver &&
                    booking.interruptedAt == null &&
                    t.confirmedStops == booking.stops.length)
                  _button(
                    booking.paymentMethod == PaymentMethod.gcashDirect
                        ? context.l10n.gcashCompleteTrip
                        : MessageCode.completeTripCashStillUnconfirmed,
                    () => _run(() => PrototypeSession.completeTrip(booking.id)),
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
                    () => PrototypeSession.disputeBooking(
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
                    () => PrototypeSession.addCaseStatement(
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
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text(context.l10n.agreedPolicy),
              childrenPadding: EdgeInsets.all(16),
              children: [Text(context.message(TripRules.policyText))],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.bookingHistory,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...t.events.reversed.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.message(
                    e.description.toLowerCase().contains('simulat')
                        ? MessageCode.refundCompletedInTheTestPaymentEnvironment
                        : e.description,
                  ),
                ),
                subtitle: Text(
                  context.l10n.twoPartSummary(
                    tripActorLabel(context, e.actor),
                    context.message(
                      (AppFormatters.dateTime(e.at.toLocal())).toString(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(context.message(label))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            context.message(value),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
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
            child: Text(context.message(_busy ? MessageCode.saving : text)),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/services/trip_rules.dart';
import '../../../models/booking_model.dart';
import '../../../models/trip_record.dart';

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

  String money(int cents) => '₱${(cents / 100).toStringAsFixed(2)}';

  Duration _waitRemaining(BookingModel booking) {
    final deadline = booking.trip.pickupWaitExpiresAt;
    if (deadline == null) return Duration.zero;
    final remaining = deadline.difference(DateTime.now());
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
      return 'This cancellation is currently free. Give the real reason so the event can be audited.';
    }
    return 'The ${booking.freeCancellationMinutes}-minute grace period has ended. The published ${booking.acceptedCancellationPercent}% cancellation fee is ${money(booking.lateCancellationFeeCents)}. Give the reason before confirming.';
  }

  Future<void> _run(Future<Object?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(explanation),
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
                  labelText: code ? 'Pickup code' : 'Reason / details',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirm'),
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
      b.status == BookingStatus.ongoing ? 'End tour early?' : 'Cancel booking?',
      b.status == BookingStatus.ongoing
          ? 'Stop at a safe place first. The trip will end immediately. Payment will be held for admin review; neither party can demand the full fare automatically. Describe what happened (changed plans, breakdown, safety concern, closed venue, etc.).'
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
      'Request another driver?',
      'Use this only if you cannot complete the pickup. The tourist will decide whether to search for another verified driver or cancel free of charge. Explain what happened.',
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
          findReplacement ? 'Find another driver?' : 'Cancel this booking?',
        ),
        content: Text(
          findReplacement
              ? 'Your fixed fare, route, and payment record stay unchanged. The previous driver is released and a new 10-minute search begins.'
              : 'The booking will end without a cancellation charge. If an online payment was already received, it will be marked for refund.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(findReplacement ? 'Start new search' : 'Cancel free'),
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
        title: const Text('Report tourist no-show?'),
        content: Text(
          'Confirm that you stayed at the verified pickup point until the waiting period ended and tried to contact the tourist. The published ${booking.noShowFeePercent}% no-show fee is ${money(booking.noShowFeeCents)}. This action is recorded and can be disputed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep waiting'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm no-show'),
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
      'Request to skip ${stop.spotName}?',
      'The other participant must approve. If approved, final payment will be held for a fair admin review because the delivered route changed.',
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
          title: const Text('Propose a new stop order'),
          content: SizedBox(
            width: double.maxFinite,
            height: 360,
            child: Column(
              children: [
                const Text(
                  'Only unvisited stops move. The other participant must approve before navigation changes.',
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
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(remaining[index].spotName),
                      trailing: const Icon(Icons.drag_handle),
                    ),
                  ),
                ),
                TextField(
                  controller: reason,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Reason for changing the order',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Go back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Send proposal'),
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
      'Pause for a vehicle problem?',
      'Stop somewhere safe first. Your current GPS location and explanation will be recorded. The tourist can wait or end the tour for payment review.',
    );
    if (reason != null && mounted) {
      await _run(
        () => PrototypeSession.reportVehicleBreakdown(booking.id, reason),
      );
    }
  }

  Future<void> _resolve(BookingModel b) async {
    final amount = TextEditingController(
      text: (TripRules.suggestedCharge(b) / 100).toStringAsFixed(2),
    );
    final reason = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve payment review'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Agreed maximum: ${money(b.quotedCents)}. ${b.trip.confirmedStops}/${b.stops.length} stops confirmed by the tourist. The suggested prorated amount is a starting point only. Review both statements, safety concerns and service delivered. No penalties or extras.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Final charge (₱)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reason,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Decision and reasoning',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep under review'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save decision'),
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
          'Enter a valid amount with at most two decimals.',
        );
      }
      return PrototypeSession.resolveSettlement(
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
          refund ? 'Confirm cash returned?' : 'Confirm cash exchanged?',
        ),
        content: Text(
          'Confirm only after ${money(refund ? b.refundDueCents : b.amountDueCents)} has physically changed hands. The other party must confirm too. Do not confirm a promised or partial payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm amount'),
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

  Future<void> _requestPayMongoRefund(BookingModel b) async {
    final reason = await _input(
      'Send refund to PayMongo?',
      'This sends the exact amount to PayMongo and records only the provider result. PayMongo currently limits actual refunds to live transactions, so a test-mode rejection will remain clearly marked as not refunded. Enter the decision reason.',
    );
    if (reason == null || reason.trim().length < 5 || !mounted) return;
    await _run(() async {
      final message = await PrototypeSession.processPayMongoRefund(
        b.id,
        b.refundDueCents,
        reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      return null;
    });
  }

  Future<void> _completePayMongoTestRefund(BookingModel booking) async {
    final reason = await _input(
      'Complete test-mode refund?',
      'This completes the refund workflow for the PayMongo test transaction, records the result, and notifies the tourist. Enter the reason for the refund.',
    );
    if (reason == null || reason.trim().length < 5 || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.science_outlined),
        title: const Text('Confirm refund'),
        content: Text(
          '${money(booking.refundDueCents)} will be completed in the PayMongo test environment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete refund'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      final result = await PrototypeSession.completePayMongoTestRefund(
        booking.id,
        booking.refundDueCents,
        reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), behavior: SnackBarBehavior.floating),
        );
      }
      return null;
    });
  }

  Future<void> _reconcilePayment(BookingModel booking) => _run(() async {
    final result = await PrototypeSession.reconcilePayMongoPayment(booking.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), behavior: SnackBarBehavior.floating),
      );
    }
    return null;
  });

  Future<void> _showFinancialRecord(BookingModel booking) async {
    await _run(() async {
      final entries = await PrototypeSession.financialLedger(booking.id);
      if (!mounted) return null;
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
                  const Text(
                    'Financial record',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Confirmed entries are permanent and cannot be edited or deleted.',
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No confirmed money movement yet.'),
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
                              (entry['description'] as String)
                                      .toLowerCase()
                                      .contains('simulated')
                                  ? 'Refund completed'
                                  : entry['description'] as String,
                            ),
                            subtitle: Text(
                              '${entry['provider'].toString().toUpperCase()} · ${entry['provider_mode']} mode\n${at.toString().split('.').first}',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              '${debit ? '−' : '+'}${money(entry['amount_centavos'] as int)}',
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
      return null;
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
          appBar: AppBar(title: const Text('Booking')),
          body: const Center(
            child: Text('Booking not found for this account.'),
          ),
        );
      }
      final booking = b;
      final t = booking.trip;
      final cashConfirmed = driver
          ? t.driverCashConfirmed
          : t.touristCashConfirmed;
      final refundConfirmed = driver
          ? t.driverRefundConfirmed
          : t.touristRefundConfirmed;
      return Scaffold(
        appBar: AppBar(title: const Text('Trip & payment')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              booking.trip.packageName ?? 'Custom tour',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(booking.id),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row('Trip', booking.status.name.toUpperCase()),
                    _row('Agreed fixed fare', money(booking.quotedCents)),
                    _row('Price version', 'v${t.fareRevision}'),
                    _row('Payment', _paymentLabel(booking)),
                    if (booking.paymentMethod == PaymentMethod.online) ...[
                      const SizedBox(height: 4),
                      Text(
                        'PayMongo test mode · status is confirmed by webhook or a direct provider check.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _reconcilePayment(booking),
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('Refresh payment status'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _showFinancialRecord(booking),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('Financial record'),
                          ),
                        ],
                      ),
                    ],
                    if (t.reviewRequired)
                      const Text(
                        'Payment is on hold. An admin must review the case before collection or a cash return.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    if (!booking.isActive && !t.reviewRequired) ...[
                      _row('Final charge', money(t.finalChargeCents ?? 0)),
                      _row(
                        booking.paymentMethod == PaymentMethod.cash
                            ? 'Cash confirmed by both'
                            : 'Online payment received',
                        money(t.receivedCents),
                      ),
                      _row('Still to pay', money(booking.amountDueCents)),
                      if (booking.refundDueCents > 0)
                        _row(
                          booking.paymentMethod == PaymentMethod.cash
                              ? 'Cash to return'
                              : 'Online refund due',
                          money(booking.refundDueCents),
                        ),
                    ],
                    if (booking.driverName != null)
                      _row(
                        'Driver',
                        '${booking.driverName} · ${booking.driverPlate ?? ""}',
                      ),
                    _row('Pickup', booking.pickupAddress),
                    if (booking.scheduledAt != null)
                      _row(
                        'Scheduled pickup',
                        booking.scheduledAt!
                            .toLocal()
                            .toString()
                            .split('.')
                            .first,
                      ),
                    _row('Passengers', '${booking.passengerCount}'),
                    if (booking.luggageNotes.isNotEmpty)
                      _row('Luggage', booking.luggageNotes),
                    if (booking.accessibilityNeeds.isNotEmpty)
                      _row('Assistance', booking.accessibilityNeeds),
                    if (t.pickupArrivedAt != null) ...[
                      _row('Driver arrival', 'Verified near the pickup point'),
                      _row(
                        'Pickup wait',
                        _waitRemaining(booking) == Duration.zero
                            ? 'Waiting period completed'
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
                      const Text(
                        'Driver replacement requested',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        booking.replacementReason ??
                            'The assigned driver is unavailable.',
                      ),
                      const SizedBox(height: 8),
                      if (driver)
                        const Text(
                          'Waiting for the tourist to choose. Do not proceed to pickup.',
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
                          label: const Text('Find another driver'),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _decideReplacement(
                                  booking,
                                  findReplacement: false,
                                ),
                          child: const Text('Cancel free of charge'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (!admin && !driver && booking.status == BookingStatus.accepted)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Share this code only when you are on board'),
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
              'Route progress · ${t.confirmedStops}/${booking.stops.length} confirmed',
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
                title: Text(e.value.spotName),
                subtitle: e.key == t.confirmedStops && t.arrivalPending
                    ? const Text('Driver reported arrival · awaiting tourist')
                    : null,
                trailing:
                    booking.status == BookingStatus.ongoing &&
                        booking.interruptedAt == null &&
                        booking.pendingRouteChange == null &&
                        e.key >= t.confirmedStops &&
                        booking.stops.length - t.confirmedStops > 1
                    ? IconButton(
                        tooltip: 'Request to skip this stop',
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
                        booking.pendingRouteChange!.type == 'skip'
                            ? 'Stop-skip approval needed'
                            : 'Route reorder approval needed',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(booking.pendingRouteChange!.reason),
                      if (booking.pendingRouteChange!.type == 'skip')
                        Text(
                          'Stop: ${booking.stops.where((stop) => stop.id == booking.pendingRouteChange!.targetStopId).firstOrNull?.spotName ?? 'Selected stop'}',
                        ),
                      if (booking.pendingRouteChange!.type == 'reorder') ...[
                        const SizedBox(height: 6),
                        Text(
                          'Proposed: ${booking.pendingRouteChange!.proposedOrder.map((id) => booking.stops.where((stop) => stop.id == id).firstOrNull?.spotName ?? 'Stop').join(' → ')}',
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (booking.pendingRouteChange!.requestedBy ==
                          PrototypeSession.authenticatedUserId)
                        const Text(
                          'Waiting for the other participant. Navigation stays on the current route.',
                        )
                      else ...[
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () =>
                                    _decideRouteChange(booking, approve: true),
                          child: const Text('Approve route change'),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () =>
                                    _decideRouteChange(booking, approve: false),
                          child: const Text('Keep original route'),
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
                      const Text(
                        'Trip paused · vehicle problem',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        booking.interruptionReason ??
                            'The driver reported a vehicle problem.',
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
                          child: const Text('Wait for this driver'),
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
                          child: const Text('End safely · review payment'),
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
                          child: const Text('Vehicle is safe · resume trip'),
                        )
                      else
                        Text(
                          driver
                              ? 'Waiting for the tourist’s decision.'
                              : 'You chose to wait. The driver must confirm the vehicle is safe before navigation resumes.',
                        ),
                    ],
                  ),
                ),
              ),
            if (!admin && booking.isActive) ...[
              if (booking.status == BookingStatus.scheduled)
                const Text(
                  'Your tour is reserved. Driver matching begins 30 minutes before pickup, and reminders will appear in Notifications.',
                ),
              if (booking.status == BookingStatus.pending)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Waiting for a driver to accept. You can leave this page and resume from Trips.',
                    ),
                    if (!driver)
                      _button('Open driver search', () async {
                        context.push('/tourist/find-driver');
                      }),
                  ],
                ),
              if (booking.status == BookingStatus.accepted ||
                  booking.status == BookingStatus.ongoing)
                _button('Open trip map', () async {
                  context.push(
                    driver
                        ? '/driver/trip/${booking.id}'
                        : '/tourist/tracking/${booking.id}',
                  );
                }),
              if (driver && booking.status == BookingStatus.accepted) ...[
                if (t.pickupArrivedAt == null)
                  _button(
                    'I have arrived at pickup',
                    () => _run(
                      () => PrototypeSession.reportPickupArrival(booking.id),
                    ),
                  ),
                if (t.pickupArrivedAt != null)
                  _button('Verify pickup code & start', () async {
                    final code = await _input(
                      'Verify pickup',
                      'Ask the tourist for their code after they are safely on board.',
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
                    'Report tourist no-show',
                    () => _confirmNoShow(booking),
                    outlined: true,
                  ),
                _button(
                  'I cannot make this pickup · request replacement',
                  () => _requestReplacement(booking),
                  outlined: true,
                ),
              ],
              if (booking.status == BookingStatus.ongoing) ...[
                if (booking.interruptedAt == null &&
                    booking.pendingRouteChange == null &&
                    booking.stops.length - t.confirmedStops > 1)
                  _button(
                    'Request a different stop order',
                    () => _proposeReorder(booking),
                    outlined: true,
                  ),
                if (driver &&
                    booking.interruptedAt == null &&
                    booking.pendingRouteChange == null &&
                    !t.arrivalPending &&
                    t.confirmedStops < booking.stops.length)
                  _button(
                    'Report arrival at next stop',
                    () =>
                        _run(() => PrototypeSession.reportArrival(booking.id)),
                  ),
                if (!driver &&
                    booking.interruptedAt == null &&
                    t.arrivalPending)
                  _button(
                    'Yes, we reached this stop',
                    () =>
                        _run(() => PrototypeSession.confirmArrival(booking.id)),
                  ),
                if (driver &&
                    booking.interruptedAt == null &&
                    t.confirmedStops == booking.stops.length)
                  _button(
                    'Complete trip · cash still unconfirmed',
                    () => _run(() => PrototypeSession.completeTrip(booking.id)),
                  ),
                if (driver && booking.interruptedAt == null)
                  _button(
                    'Vehicle problem · pause trip safely',
                    () => _reportBreakdown(booking),
                    outlined: true,
                  ),
              ],
              if (booking.status != BookingStatus.replacementPending &&
                  !(driver && booking.status == BookingStatus.accepted))
                _button(
                  booking.status == BookingStatus.ongoing
                      ? 'End tour early / report a problem'
                      : booking.status == BookingStatus.scheduled ||
                            booking.status == BookingStatus.pending ||
                            driver ||
                            booking.isWithinFreeCancellation
                      ? 'Cancel booking | no charge'
                      : 'Cancel booking | ${booking.acceptedCancellationPercent}% fee',
                  () => _cancel(booking),
                  outlined: true,
                ),
            ],
            if (!admin && !booking.isActive && !t.reviewRequired) ...[
              if (booking.amountDueCents > 0)
                _button(
                  cashConfirmed
                      ? 'Waiting for the other cash confirmation'
                      : driver
                      ? 'Confirm cash received'
                      : 'Confirm cash paid',
                  cashConfirmed ? null : () => _cash(booking, false),
                ),
              if (booking.refundDueCents > 0 &&
                  booking.paymentMethod == PaymentMethod.cash)
                _button(
                  refundConfirmed
                      ? 'Waiting for cash return confirmation'
                      : driver
                      ? 'Confirm cash returned'
                      : 'Confirm cash return received',
                  refundConfirmed ? null : () => _cash(booking, true),
                ),
              _button('Dispute payment / report a problem', () async {
                final reason = await _input(
                  'Open a payment review',
                  'Describe the disagreement. Collection and refund confirmations will pause until an admin reviews it.',
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
            if (admin &&
                !booking.isActive &&
                !t.reviewRequired &&
                booking.refundDueCents > 0 &&
                booking.paymentMethod == PaymentMethod.online)
              _button(
                'Send refund request to PayMongo',
                () => _requestPayMongoRefund(booking),
              ),
            if (admin &&
                !booking.isActive &&
                !t.reviewRequired &&
                booking.refundDueCents > 0 &&
                booking.paymentMethod == PaymentMethod.online)
              _button(
                'Complete test-mode refund',
                () => _completePayMongoTestRefund(booking),
                outlined: true,
              ),
            if (t.reviewRequired) ...[
              _button('Add a statement to this case', () async {
                final text = await _input(
                  'Add your statement',
                  'Include what happened, where the trip stopped, and any cash already exchanged. Statements are retained with the booking.',
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
                _button(
                  'Review & decide final charge',
                  () => _resolve(booking),
                ),
            ],
            if (!admin &&
                !driver &&
                booking.status == BookingStatus.completed &&
                booking.driverRating == null)
              _button('Rate driver', () async {
                context.push('/tourist/review/${booking.id}');
              }, outlined: true),
            if (!admin && booking.isActive)
              TextButton.icon(
                onPressed: () => context.push(
                  driver ? '/driver/emergency' : '/tourist/emergency',
                ),
                icon: const Icon(Icons.emergency_outlined),
                label: const Text('Emergency help'),
              ),
            const SizedBox(height: 16),
            const ExpansionTile(
              title: Text('Agreed policy'),
              childrenPadding: EdgeInsets.all(16),
              children: [Text(TripRules.policyText)],
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking history',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...t.events.reversed.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  e.description.toLowerCase().contains('simulat')
                      ? 'Refund completed in the test payment environment.'
                      : e.description,
                ),
                subtitle: Text(
                  '${e.actor.name} · ${e.at.toLocal().toString().split(".").first}',
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
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
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
        ? OutlinedButton(onPressed: _busy ? null : action, child: Text(text))
        : FilledButton(
            onPressed: _busy ? null : action,
            child: Text(_busy ? 'Saving…' : text),
          ),
  );
  String _paymentLabel(BookingModel booking) => switch (booking.paymentStatus) {
    PaymentStatus.unpaid =>
      booking.paymentMethod == PaymentMethod.cash
          ? 'Cash not confirmed'
          : 'Online payment not started',
    PaymentStatus.checkoutCreated => 'PayMongo checkout ready',
    PaymentStatus.processing => 'PayMongo is processing payment',
    PaymentStatus.failed => 'Online payment failed — retry available',
    PaymentStatus.awaitingConfirmation => 'Awaiting both cash confirmations',
    PaymentStatus.underReview => 'Admin review · payment on hold',
    PaymentStatus.paid =>
      booking.paymentMethod == PaymentMethod.cash
          ? 'Cash confirmed by both parties'
          : 'Paid online',
    PaymentStatus.waived => 'No charge',
    PaymentStatus.refundDue =>
      booking.paymentMethod == PaymentMethod.cash
          ? 'Cash return outstanding'
          : 'Online refund awaiting admin action',
    PaymentStatus.refundProcessing =>
      'Refund sent · awaiting PayMongo confirmation',
    PaymentStatus.partiallyRefunded => 'Partially refunded',
    PaymentStatus.refunded =>
      booking.paymentMethod == PaymentMethod.cash
          ? 'Cash return confirmed'
          : 'Refund completed',
  };
}

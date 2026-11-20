part of 'booking_detail_screen.dart';

/// Dialogs and server actions behind the booking detail buttons.
extension _BookingDetailActions on _BookingDetailScreenState {
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
        () => AppSession.cancelBooking(
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
      await _run(() => AppSession.requestDriverReplacement(booking.id, reason));
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
        () => AppSession.decideDriverReplacement(
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
      await _run(() => AppSession.declareTouristNoShow(booking.id));
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
        () => AppSession.proposeRouteChange(
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
      () => AppSession.proposeRouteChange(
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
      () => AppSession.decideRouteChange(
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
      await _run(() => AppSession.reportVehicleBreakdown(booking.id, reason));
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
      await AppSession.resolveSettlement(
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
        () => AppSession.confirmCash(b.id, widget.viewer, refund: refund),
      );
    }
  }

  Future<void> _showFinancialRecord(BookingModel booking) async {
    await _run(() async {
      final entries = await AppSession.financialLedger(booking.id);
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
}

part of 'booking_detail_screen.dart';

/// Display sections of the booking detail screen.
extension _BookingDetailSections on _BookingDetailScreenState {
  Widget _summaryCard(BookingModel booking, {required bool admin}) {
    final t = booking.trip;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(MessageCode.trip, bookingStatusLabel(context, booking.status)),
            _row(MessageCode.agreedFixedFare, money(booking.quotedCents)),
            _row(MessageCode.priceVersion, 'v${t.fareRevision}'),
            _row(MessageCode.payment, _paymentLabel(booking)),
            // Historical PayMongo bookings stay readable for finance.
            if (admin && booking.paymentMethod == PaymentMethod.online) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _showFinancialRecord(booking),
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
                PaymentMethod.gcashDirect => context.l10n.gcashAmountReceived,
                _ => MessageCode.onlinePaymentReceived,
              }, money(t.receivedCents)),
              _row(MessageCode.stillToPay, money(booking.amountDueCents)),
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
    );
  }

  Widget _replacementCard(
    BookingModel booking, {
    required bool driver,
    required bool admin,
  }) {
    return Card(
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
                context.l10n.waitingForTheTouristToChooseDoNotProceedToPickup,
              )
            else if (!admin) ...[
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _decideReplacement(booking, findReplacement: true),
                icon: const Icon(Icons.person_search_outlined),
                label: Text(context.l10n.findAnotherDriver),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _decideReplacement(booking, findReplacement: false),
                child: Text(context.l10n.cancelFreeOfCharge),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeProgress(BookingModel booking) {
    final t = booking.trip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }

  Widget _routeChangeCard(BookingModel booking) {
    return Card(
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
                                      booking.pendingRouteChange!.targetStopId,
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
                AppSession.authenticatedUserId)
              Text(
                context
                    .l10n
                    .waitingForTheOtherParticipantNavigationStaysOnTheCurrentRoute,
              )
            else ...[
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _decideRouteChange(booking, approve: true),
                child: Text(context.l10n.approveRouteChange),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _decideRouteChange(booking, approve: false),
                child: Text(context.l10n.keepOriginalRoute),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _breakdownCard(
    BookingModel booking, {
    required bool driver,
    required bool admin,
  }) {
    return Card(
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
                        () => AppSession.decideBreakdownWait(
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
                        () => AppSession.decideBreakdownWait(
                          booking.id,
                          wait: false,
                        ),
                      ),
                child: Text(context.l10n.endSafelyReviewPayment),
              ),
            ] else if (driver && booking.touristWaitConfirmedAt != null)
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => AppSession.resumeAfterBreakdown(booking.id),
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
    );
  }

  Widget _history(BookingModel booking) {
    final t = booking.trip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }
}

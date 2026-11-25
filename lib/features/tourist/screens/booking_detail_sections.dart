part of 'booking_detail_screen.dart';

/// Display sections of the booking detail screen.
extension _BookingDetailSections on _BookingDetailScreenState {
  /// Photo header: tour name, reference, status and the agreed fare.
  Widget _hero(BookingModel booking) {
    final package = AppSession.tourPackages.value
        .where((p) => p.id == booking.trip.packageId)
        .firstOrNull;
    final image = package == null ? null : AppSession.packageImage(package);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 196,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              SafeAppImage(path: image)
            else
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x14000000), Color(0xD9081A33)],
                  stops: [.25, 1],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: StatusBadge.bookingStatus(booking.status),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.message(AppSession.bookingTitle(booking)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // A short reference is enough to quote to support.
                        Text(
                          context.l10n.bookingReferenceValue(
                            booking.id.split('-').first.toUpperCase(),
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: .85),
                            fontSize: 12.5,
                            letterSpacing: .4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    money(booking.quotedCents),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A titled white card used for every block of the page.
  Widget _section(
    IconData icon,
    String title,
    List<Widget> children, {
    Widget? trailing,
  }) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.message(title),
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  /// One labelled fact: small grey label above a bold value.
  Widget _info(IconData icon, String label, String value, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.message(label),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    context.message(value),
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: color ?? AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// Amount line in the payment card: label left, amount right.
  Widget _amount(
    String label,
    int cents, {
    bool strong = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            context.message(label),
            style: GoogleFonts.poppins(
              fontSize: strong ? 14.5 : 13.5,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
              color: strong ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          money(cents),
          style: GoogleFonts.poppins(
            fontSize: strong ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _summaryCard(BookingModel booking, {required bool admin}) {
    final t = booking.trip;
    final when = booking.scheduledAt;
    final paid = booking.paymentStatus == PaymentStatus.paid;
    final driverName = booking.driverName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(Icons.event_note_rounded, MessageCode.tripDetails, [
          if (when != null)
            _info(
              Icons.calendar_today_outlined,
              MessageCode.tourDate,
              ServerClock.formatManila(when),
            ),
          _info(
            Icons.flag_outlined,
            MessageCode.meetingPoint,
            booking.pickupAddress,
          ),
          _info(
            Icons.groups_2_outlined,
            MessageCode.passengers,
            '${booking.passengerCount}',
          ),
          if (booking.luggageNotes.isNotEmpty)
            _info(
              Icons.luggage_outlined,
              MessageCode.luggage,
              booking.luggageNotes,
            ),
          if (booking.accessibilityNeeds.isNotEmpty)
            _info(
              Icons.accessible_rounded,
              MessageCode.assistance,
              booking.accessibilityNeeds,
            ),
          if (t.pickupArrivedAt != null) ...[
            _info(
              Icons.where_to_vote_outlined,
              MessageCode.driverArrival,
              MessageCode.verifiedNearThePickupPoint,
              color: AppColors.success,
            ),
            _info(
              Icons.timer_outlined,
              MessageCode.pickupWait,
              _waitRemaining(booking) == Duration.zero
                  ? MessageCode.waitingPeriodCompleted
                  : '${_clockLabel(_waitRemaining(booking))} remaining',
            ),
          ],
        ]),
        if (driverName != null)
          _section(Icons.badge_outlined, MessageCode.driver, [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      AppFormatters.initials(driverName),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.message(driverName),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((booking.driverPlate ?? '').isNotEmpty)
                          Text(
                            context.l10n.plateValue(booking.driverPlate!),
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (booking.driverRating != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          AppFormatters.integer(booking.driverRating!.round()),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ]),
        _section(Icons.payments_outlined, MessageCode.payment, [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              context.message(_paymentLabel(booking)),
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: paid ? AppColors.success : AppColors.textSecondary,
                fontWeight: paid ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          _amount(MessageCode.agreedFixedFare, booking.quotedCents),
          // Fare revisions matter to finance, not to riders.
          if (admin)
            _info(
              Icons.history_rounded,
              MessageCode.priceVersion,
              'v${t.fareRevision}',
            ),
          if (t.reviewRequired)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context
                    .l10n
                    .paymentIsOnHoldAnAdminMustReviewTheCaseBeforeCollectionOr,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          if (!booking.isActive && !t.reviewRequired) ...[
            _amount(MessageCode.finalChargeLabel, t.finalChargeCents ?? 0),
            _amount(switch (booking.paymentMethod) {
              PaymentMethod.cash => MessageCode.cashConfirmedByBoth,
              PaymentMethod.gcashDirect => context.l10n.gcashAmountReceived,
              _ => MessageCode.onlinePaymentReceived,
            }, t.receivedCents),
            const Divider(height: 18),
            _amount(
              MessageCode.stillToPay,
              booking.amountDueCents,
              strong: true,
              color: booking.amountDueCents > 0
                  ? AppColors.danger
                  : AppColors.success,
            ),
            if (booking.refundDueCents > 0)
              _amount(
                booking.paymentMethod == PaymentMethod.cash
                    ? MessageCode.cashToReturn
                    : MessageCode.onlineRefundDue,
                booking.refundDueCents,
                strong: true,
                color: AppColors.warning,
              ),
          ],
          // Historical PayMongo bookings stay readable for finance.
          if (admin && booking.paymentMethod == PaymentMethod.online)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _showFinancialRecord(booking),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(context.l10n.financialRecord),
              ),
            ),
        ]),
      ],
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
    final stops = booking.stops;
    return _section(
      Icons.route_rounded,
      MessageCode.tourRoute,
      [
        for (final (i, stop) in stops.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < t.confirmedStops
                              ? AppColors.success
                              : i == t.confirmedStops && booking.isActive
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          border: Border.all(
                            color: i < t.confirmedStops
                                ? AppColors.success
                                : AppColors.primary.withValues(alpha: .35),
                          ),
                        ),
                        child: i < t.confirmedStops
                            ? const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: Colors.white,
                              )
                            : Text(
                                AppFormatters.integer(i + 1),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      i == t.confirmedStops && booking.isActive
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                      ),
                      if (i < stops.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: i < t.confirmedStops
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.message(stop.spotName),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: i < t.confirmedStops
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (i == t.confirmedStops && t.arrivalPending)
                          Text(
                            context.l10n.driverReportedArrivalAwaitingTourist,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppColors.warning,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (booking.status == BookingStatus.ongoing &&
                    booking.interruptedAt == null &&
                    booking.pendingRouteChange == null &&
                    i >= t.confirmedStops &&
                    stops.length - t.confirmedStops > 1)
                  IconButton(
                    tooltip: context.l10n.requestToSkipThisStop,
                    onPressed: _busy ? null : () => _proposeSkip(booking, stop),
                    icon: const Icon(Icons.skip_next_outlined),
                  ),
              ],
            ),
          ),
      ],
      trailing: Text(
        context.l10n.stopsDoneValue(
          AppFormatters.integer(t.confirmedStops),
          AppFormatters.integer(stops.length),
        ),
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: AppColors.textSecondary,
        ),
      ),
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
    final events = booking.trip.events.reversed.toList();
    if (events.isEmpty) return const SizedBox.shrink();
    return _section(Icons.history_rounded, MessageCode.bookingHistory, [
      for (final (i, e) in events.indexed)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 16,
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    if (i < events.length - 1)
                      Expanded(
                        child: Container(width: 2, color: AppColors.border),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.message(
                          e.description.toLowerCase().contains('simulat')
                              ? MessageCode
                                    .refundCompletedInTheTestPaymentEnvironment
                              : e.description,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: i == 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      Text(
                        context.l10n.twoPartSummary(
                          tripActorLabel(context, e.actor),
                          AppFormatters.dateTime(e.at.toLocal()),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ]);
  }
}

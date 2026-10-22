import '../../models/booking_model.dart';
import '../../models/trip_record.dart';

class TripRuleException implements Exception {
  final String message;
  const TripRuleException(this.message);
  @override
  String toString() => message;
}

/// State transitions shared by every screen. A production server must enforce
/// these same rules with authenticated actors and atomic database transactions.
class TripRules {
  static const policyText =
      'The agreed tour fare is fixed; there is no surge pricing. Pending requests and driver cancellations are free. After a driver accepts, the tourist has a short grace period, then the published cancellation fee may apply. After pickup, end safely and an admin reviews the completed service and evidence. Entrance fees and personal purchases remain separate.';

  static void require(bool condition, String message) {
    if (!condition) throw TripRuleException(message);
  }

  static BookingModel record(
    BookingModel b,
    TripActor actor,
    String description, {
    DateTime? at,
  }) => b.copyWith(
    trip: b.trip.copyWith(
      events: List.unmodifiable([
        ...b.trip.events,
        TripEvent(at ?? DateTime.now(), actor, description),
      ]),
    ),
  );

  static BookingModel start(BookingModel b, String code) {
    require(
      b.status == BookingStatus.accepted,
      'Only an accepted booking can start.',
    );
    require(
      b.trip.pickupArrivedAt != null,
      'Report your verified arrival at the pickup point before starting.',
    );
    require(
      b.trip.pickupCode.isNotEmpty && code.trim() == b.trip.pickupCode,
      'Ask the tourist for the correct pickup code once they are on board.',
    );
    return record(
      b.copyWith(status: BookingStatus.ongoing, startedAt: DateTime.now()),
      TripActor.driver,
      'Pickup code verified; trip started.',
    );
  }

  static BookingModel reportPickupArrival(
    BookingModel b, {
    DateTime? at,
    Duration waitTime = const Duration(minutes: 10),
  }) {
    require(
      b.status == BookingStatus.accepted,
      'Pickup arrival can only be reported for an accepted booking.',
    );
    require(
      b.trip.pickupArrivedAt == null,
      'Pickup arrival has already been recorded.',
    );
    final arrival = at ?? DateTime.now();
    return record(
      b.copyWith(
        trip: b.trip.copyWith(
          pickupArrivedAt: arrival,
          pickupWaitExpiresAt: arrival.add(waitTime),
        ),
      ),
      TripActor.driver,
      'Driver arrived at the verified pickup area. The waiting period started.',
      at: arrival,
    );
  }

  static BookingModel declareTouristNoShow(BookingModel b, {DateTime? at}) {
    final now = at ?? DateTime.now();
    require(
      b.status == BookingStatus.accepted &&
          b.trip.pickupArrivedAt != null &&
          b.trip.pickupWaitExpiresAt != null,
      'Verified pickup arrival is required before reporting a no-show.',
    );
    require(
      !now.isBefore(b.trip.pickupWaitExpiresAt!),
      'The pickup waiting period has not finished.',
    );
    final charge = b.noShowFeeCents;
    final status = b.trip.receivedCents > charge
        ? PaymentStatus.refundDue
        : charge == 0
        ? PaymentStatus.waived
        : PaymentStatus.unpaid;
    return record(
      b.copyWith(
        status: BookingStatus.cancelled,
        completedAt: now,
        cancellationReason: 'Tourist no-show after verified pickup wait.',
        paymentStatus: status,
        trip: b.trip.copyWith(finalChargeCents: charge),
      ),
      TripActor.driver,
      'Tourist reported as a no-show after the verified waiting period. Published no-show fee applied.',
      at: now,
    );
  }

  static BookingModel proposeArrival(BookingModel b) {
    require(b.status == BookingStatus.ongoing, 'This trip is not in progress.');
    require(
      b.trip.confirmedStops < b.stops.length && !b.trip.arrivalPending,
      'Wait for the tourist to confirm this stop.',
    );
    return record(
      b.copyWith(trip: b.trip.copyWith(arrivalPending: true)),
      TripActor.driver,
      'Arrival reported: ${b.stops[b.trip.confirmedStops].spotName}.',
    );
  }

  static BookingModel confirmArrival(BookingModel b) {
    require(
      b.status == BookingStatus.ongoing && b.trip.arrivalPending,
      'No arrival is awaiting confirmation.',
    );
    return record(
      b.copyWith(
        trip: b.trip.copyWith(
          confirmedStops: b.trip.confirmedStops + 1,
          arrivalPending: false,
        ),
      ),
      TripActor.tourist,
      'Tourist confirmed stop ${b.trip.confirmedStops + 1}.',
    );
  }

  static BookingModel complete(BookingModel b) {
    require(
      b.status == BookingStatus.ongoing,
      'Only an ongoing trip can be completed.',
    );
    require(
      b.stops.isNotEmpty && b.trip.confirmedStops == b.stops.length,
      'The tourist must confirm all booked stops. Use End tour early for an incomplete route.',
    );
    return record(
      b.copyWith(
        status: BookingStatus.completed,
        completedAt: DateTime.now(),
        trip: b.trip.copyWith(finalChargeCents: b.quotedCents),
        paymentStatus: PaymentStatus.unpaid,
      ),
      TripActor.driver,
      'Trip completed. Fixed fare due; cash not yet confirmed.',
    );
  }

  static BookingModel cancel(BookingModel b, TripActor actor, String reason) {
    require(
      actor == TripActor.driver || actor == TripActor.tourist,
      'Only a trip participant can end this trip.',
    );
    require(b.isActive, 'This trip has already ended.');
    require(
      reason.trim().length >= 5,
      'Please give a reason (at least 5 characters).',
    );
    final started = b.status == BookingStatus.ongoing;
    final touristLateCancellation =
        !started &&
        actor == TripActor.tourist &&
        b.status == BookingStatus.accepted &&
        b.acceptedAt != null &&
        DateTime.now().isAfter(
          b.acceptedAt!.add(Duration(minutes: b.freeCancellationMinutes)),
        );
    final charge = started
        ? null
        : touristLateCancellation
        ? b.lateCancellationFeeCents
        : 0;
    final paymentStatus = started
        ? PaymentStatus.underReview
        : b.trip.receivedCents > (charge ?? 0)
        ? PaymentStatus.refundDue
        : charge == 0
        ? PaymentStatus.waived
        : PaymentStatus.unpaid;
    return record(
      b.copyWith(
        status: BookingStatus.cancelled,
        completedAt: DateTime.now(),
        cancellationReason: reason.trim(),
        trip: b.trip.copyWith(
          reviewRequired: started,
          finalChargeCents: charge,
          arrivalPending: false,
        ),
        paymentStatus: paymentStatus,
      ),
      actor,
      '${started
          ? 'Tour ended early; payment held for review'
          : charge == 0
          ? 'Cancelled without charge'
          : 'Cancelled after the grace period; published cancellation fee applied'}. Reason: ${reason.trim()}',
    );
  }

  static BookingModel dispute(BookingModel b, TripActor actor, String reason) {
    require(
      !b.isActive,
      'End the tour safely first to open a settlement review.',
    );
    require(
      actor == TripActor.tourist || actor == TripActor.driver,
      'Only a participant can report a payment issue.',
    );
    require(
      !b.trip.reviewRequired,
      'This booking is already under review. Add your statement to the case.',
    );
    require(
      reason.trim().length >= 5,
      'Please explain the issue (at least 5 characters).',
    );
    return record(
      b.copyWith(
        trip: b.trip.copyWith(reviewRequired: true),
        paymentStatus: PaymentStatus.underReview,
      ),
      actor,
      'Payment disputed: ${reason.trim()}',
    );
  }

  static BookingModel statement(BookingModel b, TripActor actor, String text) {
    require(b.trip.reviewRequired, 'There is no open review on this booking.');
    require(
      text.trim().length >= 5,
      'Please provide details (at least 5 characters).',
    );
    return record(b, actor, 'Case statement: ${text.trim()}');
  }

  static int suggestedCharge(BookingModel b) => b.stops.isEmpty
      ? 0
      : (b.quotedCents * b.trip.confirmedStops / b.stops.length).round();

  static BookingModel resolve(BookingModel b, int cents, String reason) {
    require(
      b.trip.reviewRequired && !b.isActive,
      'Only an ended trip with an open review can be resolved.',
    );
    require(
      cents >= 0 && cents <= b.quotedCents,
      'The final charge must be between zero and the agreed fare.',
    );
    require(
      b.startedAt != null || cents <= (b.trip.finalChargeCents ?? 0),
      'A pre-pickup review cannot increase the snapshotted cancellation charge.',
    );
    require(
      reason.trim().length >= 10,
      'Explain the decision (at least 10 characters).',
    );
    final paid = b.trip.receivedCents;
    final status = paid > cents
        ? PaymentStatus.refundDue
        : cents == 0
        ? PaymentStatus.waived
        : paid == cents
        ? PaymentStatus.paid
        : PaymentStatus.unpaid;
    return record(
      b.copyWith(
        trip: b.trip.copyWith(
          finalChargeCents: cents,
          reviewRequired: false,
          touristCashConfirmed: false,
          driverCashConfirmed: false,
          touristRefundConfirmed: false,
          driverRefundConfirmed: false,
        ),
        paymentStatus: status,
      ),
      TripActor.admin,
      'Review resolved: ₱${(cents / 100).toStringAsFixed(2)} final charge. ${reason.trim()}',
    );
  }

  static BookingModel confirmCash(
    BookingModel b,
    TripActor actor, {
    bool refund = false,
  }) {
    require(
      actor == TripActor.tourist || actor == TripActor.driver,
      'Only the payer and receiver can confirm cash.',
    );
    require(
      !b.isActive && !b.trip.reviewRequired && b.trip.finalChargeCents != null,
      'The final charge must be settled before confirming cash.',
    );
    require(
      b.paymentMethod == PaymentMethod.cash,
      'Online payments require a verified payment provider.',
    );
    require(
      refund ? b.refundDueCents > 0 : b.amountDueCents > 0,
      'There is no outstanding amount to confirm.',
    );
    final tourist = actor == TripActor.tourist;
    final already = refund
        ? (tourist
              ? b.trip.touristRefundConfirmed
              : b.trip.driverRefundConfirmed)
        : (tourist ? b.trip.touristCashConfirmed : b.trip.driverCashConfirmed);
    if (already) return b; // Duplicate taps are idempotent.
    var trip = b.trip.copyWith(
      touristCashConfirmed: !refund && tourist ? true : null,
      driverCashConfirmed: !refund && !tourist ? true : null,
      touristRefundConfirmed: refund && tourist ? true : null,
      driverRefundConfirmed: refund && !tourist ? true : null,
    );
    final both = refund
        ? trip.touristRefundConfirmed && trip.driverRefundConfirmed
        : trip.touristCashConfirmed && trip.driverCashConfirmed;
    if (both) trip = trip.copyWith(receivedCents: trip.finalChargeCents);
    return record(
      b.copyWith(
        trip: trip,
        paymentStatus: both
            ? (refund ? PaymentStatus.refunded : PaymentStatus.paid)
            : (refund
                  ? PaymentStatus.refundDue
                  : PaymentStatus.awaitingConfirmation),
      ),
      actor,
      '${refund ? 'Cash return' : 'Cash payment'} confirmed by ${actor.name}${both ? '; both parties confirmed' : '; awaiting the other party'}.',
    );
  }
}

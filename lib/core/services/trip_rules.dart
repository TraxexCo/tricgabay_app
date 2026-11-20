import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'server_clock.dart';
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
      MessageCode.theAgreedTourFareIsFixedThereIsNoSurgePricingPendingRequests;

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
        TripEvent(at ?? ServerClock.now(), actor, description),
      ]),
    ),
  );

  static BookingModel start(BookingModel b, String code) {
    require(
      b.status == BookingStatus.accepted,
      MessageCode.onlyAnAcceptedBookingCanStart,
    );
    require(
      b.trip.pickupArrivedAt != null,
      MessageCode.reportYourVerifiedArrivalAtThePickupPointBeforeStarting,
    );
    require(
      b.trip.pickupCode.isNotEmpty && code.trim() == b.trip.pickupCode,
      MessageCode.askTheTouristForTheCorrectPickupCodeOnceTheyAreOnBoard,
    );
    return record(
      b.copyWith(status: BookingStatus.ongoing, startedAt: ServerClock.now()),
      TripActor.driver,
      MessageCode.pickupCodeVerifiedTripStarted,
    );
  }

  static BookingModel reportPickupArrival(
    BookingModel b, {
    DateTime? at,
    Duration waitTime = const Duration(minutes: 10),
  }) {
    require(
      b.status == BookingStatus.accepted,
      MessageCode.pickupArrivalCanOnlyBeReportedForAnAcceptedBooking,
    );
    require(
      b.trip.pickupArrivedAt == null,
      MessageCode.pickupArrivalHasAlreadyBeenRecorded,
    );
    final arrival = at ?? ServerClock.now();
    return record(
      b.copyWith(
        trip: b.trip.copyWith(
          pickupArrivedAt: arrival,
          pickupWaitExpiresAt: arrival.add(waitTime),
        ),
      ),
      TripActor.driver,
      MessageCode.driverArrivedAtTheVerifiedPickupAreaTheWaitingPeriodStarted,
      at: arrival,
    );
  }

  static BookingModel declareTouristNoShow(BookingModel b, {DateTime? at}) {
    final now = at ?? ServerClock.now();
    require(
      b.status == BookingStatus.accepted &&
          b.trip.pickupArrivedAt != null &&
          b.trip.pickupWaitExpiresAt != null,
      MessageCode.verifiedPickupArrivalIsRequiredBeforeReportingANoShow,
    );
    require(
      !now.isBefore(b.trip.pickupWaitExpiresAt!),
      MessageCode.thePickupWaitingPeriodHasNotFinished,
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
        cancellationReason: MessageCode.touristNoShowAfterVerifiedPickupWait,
        paymentStatus: status,
        trip: b.trip.copyWith(finalChargeCents: charge),
      ),
      TripActor.driver,
      MessageCode
          .touristReportedAsANoShowAfterTheVerifiedWaitingPeriodPublishedNo,
      at: now,
    );
  }

  static BookingModel proposeArrival(BookingModel b) {
    require(
      b.status == BookingStatus.ongoing,
      MessageCode.thisTripIsNotInProgress,
    );
    require(
      b.trip.confirmedStops < b.stops.length && !b.trip.arrivalPending,
      MessageCode.waitForTheTouristToConfirmThisStop,
    );
    return record(
      b.copyWith(trip: b.trip.copyWith(arrivalPending: true)),
      TripActor.driver,
      MessageCode.arrivalReportedValue(
        (b.stops[b.trip.confirmedStops].spotName).toString(),
      ),
    );
  }

  static BookingModel confirmArrival(BookingModel b) {
    require(
      b.status == BookingStatus.ongoing && b.trip.arrivalPending,
      MessageCode.noArrivalIsAwaitingConfirmation,
    );
    return record(
      b.copyWith(
        trip: b.trip.copyWith(
          confirmedStops: b.trip.confirmedStops + 1,
          arrivalPending: false,
        ),
      ),
      TripActor.tourist,
      MessageCode.touristConfirmedStopValue(
        (b.trip.confirmedStops + 1).toString(),
      ),
    );
  }

  static BookingModel complete(BookingModel b) {
    require(
      b.status == BookingStatus.ongoing,
      MessageCode.onlyAnOngoingTripCanBeCompleted,
    );
    require(
      b.stops.isNotEmpty && b.trip.confirmedStops == b.stops.length,
      MessageCode.theTouristMustConfirmAllBookedStopsUseEndTourEarlyForAn,
    );
    return record(
      b.copyWith(
        status: BookingStatus.completed,
        completedAt: ServerClock.now(),
        trip: b.trip.copyWith(finalChargeCents: b.quotedCents),
        paymentStatus: PaymentStatus.unpaid,
      ),
      TripActor.driver,
      MessageCode.tripCompletedFixedFareDueCashNotYetConfirmed,
    );
  }

  static BookingModel cancel(BookingModel b, TripActor actor, String reason) {
    require(
      actor == TripActor.driver || actor == TripActor.tourist,
      MessageCode.onlyATripParticipantCanEndThisTrip,
    );
    require(b.isActive, MessageCode.thisTripHasAlreadyEnded);
    require(
      reason.trim().length >= 5,
      MessageCode.pleaseGiveAReasonAtLeast5Characters,
    );
    final started = b.status == BookingStatus.ongoing;
    final touristLateCancellation =
        !started &&
        actor == TripActor.tourist &&
        b.status == BookingStatus.accepted &&
        b.acceptedAt != null &&
        ServerClock.now().isAfter(
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
        completedAt: ServerClock.now(),
        cancellationReason: reason.trim(),
        trip: b.trip.copyWith(
          reviewRequired: started,
          finalChargeCents: charge,
          arrivalPending: false,
        ),
        paymentStatus: paymentStatus,
      ),
      actor,
      MessageCode.cancellationWithReason(
        started
            ? MessageCode.tourEndedEarlyPaymentHeldForReview
            : charge == 0
            ? MessageCode.cancelledWithoutCharge
            : MessageCode
                  .cancelledAfterTheGracePeriodPublishedCancellationFeeApplied,
        reason.trim(),
      ),
    );
  }

  static BookingModel dispute(BookingModel b, TripActor actor, String reason) {
    require(
      !b.isActive,
      MessageCode.endTheTourSafelyFirstToOpenASettlementReview,
    );
    require(
      actor == TripActor.tourist || actor == TripActor.driver,
      MessageCode.onlyAParticipantCanReportAPaymentIssue,
    );
    require(
      !b.trip.reviewRequired,
      MessageCode.thisBookingIsAlreadyUnderReviewAddYourStatementToTheCase,
    );
    require(
      reason.trim().length >= 5,
      MessageCode.pleaseExplainTheIssueAtLeast5Characters,
    );
    return record(
      b.copyWith(
        trip: b.trip.copyWith(reviewRequired: true),
        paymentStatus: PaymentStatus.underReview,
      ),
      actor,
      MessageCode.paymentDisputedValue((reason.trim()).toString()),
    );
  }

  static BookingModel statement(BookingModel b, TripActor actor, String text) {
    require(
      b.trip.reviewRequired,
      MessageCode.thereIsNoOpenReviewOnThisBooking,
    );
    require(
      text.trim().length >= 5,
      MessageCode.pleaseProvideDetailsAtLeast5Characters,
    );
    return record(
      b,
      actor,
      MessageCode.caseStatementValue((text.trim()).toString()),
    );
  }

  static int suggestedCharge(BookingModel b) => b.stops.isEmpty
      ? 0
      : (b.quotedCents * b.trip.confirmedStops / b.stops.length).round();

  static BookingModel resolve(BookingModel b, int cents, String reason) {
    require(
      b.trip.reviewRequired && !b.isActive,
      MessageCode.onlyAnEndedTripWithAnOpenReviewCanBeResolved,
    );
    require(
      cents >= 0 && cents <= b.quotedCents,
      MessageCode.theFinalChargeMustBeBetweenZeroAndTheAgreedFare,
    );
    require(
      b.startedAt != null || cents <= (b.trip.finalChargeCents ?? 0),
      MessageCode
          .aPrePickupReviewCannotIncreaseTheSnapshottedCancellationCharge,
    );
    require(
      reason.trim().length >= 10,
      MessageCode.explainTheDecisionAtLeast10Characters,
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
      MessageCode.reviewResolvedFinalChargeValue(
        (AppFormatters.amount((cents / 100))).toString(),
        (reason.trim()).toString(),
      ),
    );
  }

  static BookingModel confirmCash(
    BookingModel b,
    TripActor actor, {
    bool refund = false,
  }) {
    require(
      actor == TripActor.tourist || actor == TripActor.driver,
      MessageCode.onlyThePayerAndReceiverCanConfirmCash,
    );
    require(
      !b.isActive && !b.trip.reviewRequired && b.trip.finalChargeCents != null,
      MessageCode.theFinalChargeMustBeSettledBeforeConfirmingCash,
    );
    require(
      b.paymentMethod == PaymentMethod.cash,
      MessageCode.onlinePaymentsRequireAVerifiedPaymentProvider,
    );
    require(
      refund ? b.refundDueCents > 0 : b.amountDueCents > 0,
      MessageCode.thereIsNoOutstandingAmountToConfirm,
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
      MessageCode.cashConfirmation(
        refund ? MessageCode.cashReturn : MessageCode.cashPayment,
        actor == TripActor.tourist
            ? MessageCode.tourist
            : actor == TripActor.driver
            ? MessageCode.driver
            : MessageCode.administrator,
        both
            ? MessageCode.bothPartiesConfirmed
            : MessageCode.awaitingOtherParty,
      ),
    );
  }
}

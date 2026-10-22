import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/fare_policy.dart';
import 'package:tricgabay_app/core/services/trip_rules.dart';
import 'package:tricgabay_app/models/booking_model.dart';
import 'package:tricgabay_app/models/trip_record.dart';
import 'package:tricgabay_app/models/tourist_spot_model.dart';

BookingModel accepted() => BookingModel(
  id: 'test',
  touristId: 'u1',
  touristName: 'Tourist',
  driverId: 'd1',
  driverName: 'Marco',
  stops: const [
    BookingStop(
      spotId: 'a',
      spotName: 'First',
      latitude: 14.95,
      longitude: 120.92,
      fare: 0,
    ),
    BookingStop(
      spotId: 'b',
      spotName: 'Second',
      latitude: 14.96,
      longitude: 120.93,
      fare: 0,
    ),
  ],
  pickupLat: 14.95,
  pickupLng: 120.92,
  pickupAddress: 'Pickup',
  passengerCount: 3,
  luggageNotes: 'Two backpacks',
  accessibilityNeeds: 'Allow extra boarding time',
  baseFare: 700,
  totalFare: 700,
  paymentMethod: PaymentMethod.cash,
  createdAt: DateTime(2026),
  status: BookingStatus.accepted,
  trip: TripRecord(
    pickupCode: '1234',
    fareRevision: 3,
    pickupArrivedAt: DateTime(2026, 1, 1, 9),
    pickupWaitExpiresAt: DateTime(2026, 1, 1, 9, 10),
  ),
);
BookingModel completed() {
  var b = TripRules.start(accepted(), '1234');
  for (var i = 0; i < 2; i++) {
    b = TripRules.confirmArrival(TripRules.proposeArrival(b));
  }
  return TripRules.complete(b);
}

void main() {
  test('fixed custom fare does not depend on distance or stop count', () {
    const prices = FarePolicy();
    expect(prices.quote(null), 7000);
    expect(prices.quote('tric-lakbay'), 70000);
    expect(() => prices.quote('unknown'), throwsStateError);
  });
  test('temporary attraction closure expires at the published time', () {
    final openAgain = TouristSpotModel(
      id: 'closed',
      name: 'Closed venue',
      description: '',
      history: '',
      latitude: 14.95,
      longitude: 120.92,
      category: SpotCategory.other,
      imageUrls: const [],
      openingHours: '',
      entranceFee: '',
      tips: const [],
      availabilityStatus: 'temporarily_closed',
      closedUntil: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(openAgain.isTemporarilyClosed, isFalse);
    expect(
      TouristSpotModel.fromMap(openAgain.toMap(), openAgain.id)
          .isTemporarilyClosed,
      isFalse,
    );
  });
  test(
    'prices reject NaN, infinity, zero, negative, excessive precision and excessive amounts',
    () {
      for (final input in [
        'NaN',
        'Infinity',
        '0',
        '-10',
        '12.345',
        '100000.01',
        '1e5',
      ]) {
        expect(() => FarePolicy.parsePrice(input), throwsFormatException);
      }
      expect(FarePolicy.parsePrice('0.29'), 29);
    },
  );
  test('pickup code and accepted state are required to start', () {
    expect(
      () => TripRules.start(accepted(), '9999'),
      throwsA(isA<TripRuleException>()),
    );
    expect(
      () => TripRules.start(
        accepted().copyWith(status: BookingStatus.cancelled),
        '1234',
      ),
      throwsA(isA<TripRuleException>()),
    );
    expect(TripRules.start(accepted(), '1234').startedAt, isNotNull);
  });
  test('pickup arrival starts one waiting deadline and cannot be repeated', () {
    final withoutArrival = accepted().copyWith(
      trip: const TripRecord(pickupCode: '1234', fareRevision: 3),
    );
    final arrived = TripRules.reportPickupArrival(
      withoutArrival,
      at: DateTime(2026, 1, 1, 9),
      waitTime: const Duration(minutes: 10),
    );
    expect(arrived.trip.pickupWaitExpiresAt, DateTime(2026, 1, 1, 9, 10));
    expect(
      () => TripRules.reportPickupArrival(arrived),
      throwsA(isA<TripRuleException>()),
    );
  });
  test('tourist no-show requires the verified waiting deadline', () {
    final booking = accepted();
    expect(
      () => TripRules.declareTouristNoShow(
        booking,
        at: DateTime(2026, 1, 1, 9, 9),
      ),
      throwsA(isA<TripRuleException>()),
    );
    final ended = TripRules.declareTouristNoShow(
      booking,
      at: DateTime(2026, 1, 1, 9, 10),
    );
    expect(ended.status, BookingStatus.cancelled);
    expect(ended.trip.finalChargeCents, 35000);
    expect(ended.paymentStatus, PaymentStatus.unpaid);
  });
  test(
    'driver cannot complete unconfirmed stops or request two stops at once',
    () {
      final b = TripRules.start(accepted(), '1234');
      expect(() => TripRules.complete(b), throwsA(isA<TripRuleException>()));
      expect(
        () => TripRules.confirmArrival(b),
        throwsA(isA<TripRuleException>()),
      );
      expect(
        () => TripRules.proposeArrival(TripRules.proposeArrival(b)),
        throwsA(isA<TripRuleException>()),
      );
    },
  );
  for (final actor in [TripActor.driver, TripActor.tourist]) {
    test('$actor cancellation before pickup is free', () {
      final b = TripRules.cancel(accepted(), actor, 'Changed plans');
      expect(b.status, BookingStatus.cancelled);
      expect(b.paymentStatus, PaymentStatus.waived);
      expect(b.trip.finalChargeCents, 0);
      expect(b.trip.events.last.actor, actor);
    });
    test(
      '$actor early ending holds payment and preserves confirmed progress',
      () {
        var b = TripRules.start(accepted(), '1234');
        b = TripRules.confirmArrival(TripRules.proposeArrival(b));
        b = TripRules.cancel(b, actor, 'Vehicle breakdown');
        expect(b.trip.confirmedStops, 1);
        expect(b.trip.reviewRequired, isTrue);
        expect(b.amountDueCents, 0);
        expect(TripRules.suggestedCharge(b), 35000);
        expect(
          () => TripRules.confirmCash(b, actor),
          throwsA(isA<TripRuleException>()),
        );
      },
    );
  }
  test('late tourist cancellation applies the snapshotted percentage', () {
    final booking = accepted().copyWith(
      acceptedAt: DateTime.now().subtract(const Duration(minutes: 6)),
    );
    final cancelled = TripRules.cancel(
      booking,
      TripActor.tourist,
      'Plans changed late',
    );
    expect(cancelled.trip.finalChargeCents, 14000);
    expect(cancelled.paymentStatus, PaymentStatus.unpaid);
  });
  test('terminal trip cannot be cancelled or completed again', () {
    expect(
      () => TripRules.cancel(completed(), TripActor.tourist, 'Changed mind'),
      throwsA(isA<TripRuleException>()),
    );
    expect(
      () => TripRules.complete(completed()),
      throwsA(isA<TripRuleException>()),
    );
  });
  test('admin cannot exceed quote or charge before-pickup cancellation', () {
    var b = TripRules.cancel(accepted(), TripActor.tourist, 'Not travelling');
    b = TripRules.dispute(b, TripActor.driver, 'Please review this');
    expect(
      () => TripRules.resolve(b, 1, 'Admin explanation'),
      throwsA(isA<TripRuleException>()),
    );
    b = TripRules.dispute(completed(), TripActor.tourist, 'Wrong amount');
    expect(
      () => TripRules.resolve(b, 70001, 'Admin explanation'),
      throwsA(isA<TripRuleException>()),
    );
    expect(
      () => TripRules.resolve(b, -1, 'Admin explanation'),
      throwsA(isA<TripRuleException>()),
    );
    expect(
      () => TripRules.resolve(b, 1000, ''),
      throwsA(isA<TripRuleException>()),
    );
  });
  test(
    'completion is not payment; repeated same-side confirmation is not payment',
    () {
      var b = completed();
      expect(b.paymentStatus, PaymentStatus.unpaid);
      b = TripRules.confirmCash(b, TripActor.driver);
      b = TripRules.confirmCash(b, TripActor.driver);
      expect(b.trip.receivedCents, 0);
      expect(b.paymentStatus, PaymentStatus.awaitingConfirmation);
      b = TripRules.confirmCash(b, TripActor.tourist);
      expect(b.trip.receivedCents, 70000);
      expect(b.paymentStatus, PaymentStatus.paid);
      expect(b.amountDueCents, 0);
      expect(
        () => TripRules.confirmCash(b, TripActor.driver),
        throwsA(isA<TripRuleException>()),
      );
    },
  );
  test(
    'reduction after paid trip creates outstanding cash return, never an automatic refund',
    () {
      var b = TripRules.confirmCash(
        TripRules.confirmCash(completed(), TripActor.tourist),
        TripActor.driver,
      );
      b = TripRules.dispute(b, TripActor.tourist, 'Service issue');
      b = TripRules.resolve(
        b,
        35000,
        'Both statements reviewed; half fare due.',
      );
      expect(b.refundDueCents, 35000);
      expect(b.paymentStatus, PaymentStatus.refundDue);
      b = TripRules.confirmCash(b, TripActor.driver, refund: true);
      expect(b.refundDueCents, 35000);
      b = TripRules.confirmCash(b, TripActor.tourist, refund: true);
      expect(b.trip.receivedCents, 35000);
      expect(b.refundDueCents, 0);
      expect(b.paymentStatus, PaymentStatus.refunded);
    },
  );
  test('changing settlement resets stale one-sided payment confirmation', () {
    var b = TripRules.confirmCash(completed(), TripActor.driver);
    b = TripRules.dispute(b, TripActor.tourist, 'Amount disagreement');
    b = TripRules.resolve(b, 10000, 'Reviewed and adjusted charge.');
    expect(b.trip.driverCashConfirmed, isFalse);
    b = TripRules.confirmCash(b, TripActor.tourist);
    expect(b.trip.receivedCents, 0);
  });
  test('admin cannot impersonate cash payer or receiver', () {
    expect(
      () => TripRules.confirmCash(completed(), TripActor.admin),
      throwsA(isA<TripRuleException>()),
    );
  });
  test(
    'transaction record survives serialization with amounts and history intact',
    () {
      var b = TripRules.cancel(
        TripRules.start(accepted(), '1234'),
        TripActor.driver,
        'Unsafe road',
      );
      b = TripRules.statement(b, TripActor.tourist, 'Driver stopped safely');
      b = TripRules.resolve(b, 0, 'Safety interruption; no charge.');
      b = b.copyWith(
        routeAdjustmentRequired: true,
        interruptedAt: DateTime(2026, 1, 1, 10),
        interruptionReason: 'Flat tire',
        pendingRouteChange: BookingRouteChange(
          id: 'change-1',
          requestedBy: 'u1',
          requestedRole: 'tourist',
          type: 'reorder',
          proposedOrder: const ['stop-2', 'stop-1'],
          reason: 'Venue closes early',
          createdAt: DateTime(2026, 1, 1, 9, 30),
        ),
      );
      final restored = BookingModel.fromMap(b.toMap(), b.id);
      expect(restored.toMap(), b.toMap());
      expect(restored.trip.events.length, 4);
      expect(restored.passengerCount, 3);
      expect(restored.luggageNotes, 'Two backpacks');
      expect(restored.accessibilityNeeds, 'Allow extra boarding time');
      expect(restored.routeAdjustmentRequired, isTrue);
      expect(restored.interruptionReason, 'Flat tire');
      expect(restored.pendingRouteChange?.type, 'reorder');
    },
  );
}

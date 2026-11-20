import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/fare_policy.dart';
import 'package:tricgabay_app/core/services/trip_rules.dart';
import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
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
      fareCents: 0,
    ),
    BookingStop(
      spotId: 'b',
      spotName: 'Second',
      latitude: 14.96,
      longitude: 120.93,
      fareCents: 0,
    ),
  ],
  pickupLat: 14.95,
  pickupLng: 120.92,
  pickupAddress: 'Pickup',
  passengerCount: 3,
  luggageNotes: 'Two backpacks',
  accessibilityNeeds: 'Allow extra boarding time',
  baseFareCents: 70000,
  totalFareCents: 70000,
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
      TouristSpotModel.fromMap(
        openAgain.toMap(),
        openAgain.id,
      ).isTemporarilyClosed,
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
  test('suggested early-end charge is the share of confirmed stops', () {
    final b = accepted();
    expect(TripRules.suggestedCharge(b), 0);
    final halfway = b.copyWith(trip: b.trip.copyWith(confirmedStops: 1));
    expect(TripRules.suggestedCharge(halfway), 35000);
    expect(TripRules.suggestedCharge(b.copyWith(stops: const [])), 0);
  });
  test('require throws a typed, user-facing rule exception', () {
    expect(
      () => TripRules.require(false, MessageCode.serverConnectionRequired),
      throwsA(isA<TripRuleException>()),
    );
    TripRules.require(true, MessageCode.serverConnectionRequired);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/prototype/prototype_session.dart';
import 'package:tricgabay_app/core/services/fare_policy.dart';
import 'package:tricgabay_app/core/services/trip_rules.dart';
import 'package:tricgabay_app/models/booking_model.dart';
import 'package:tricgabay_app/models/tourist_spot_model.dart';
import 'package:tricgabay_app/models/trip_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrototypeSession.bookings.value = [];
    PrototypeSession.farePolicy.value = const FarePolicy();
    PrototypeSession.allSpots.value = TouristSpotModel.catalog;
    PrototypeSession.activePackageId = null;
    PrototypeSession.itinerary.value = TouristSpotModel.catalog
        .take(2)
        .toList();
    PrototypeSession.customPickupLat = 14.95;
    PrototypeSession.customPickupLng = 120.92;
    PrototypeSession.scheduledAt = null;
    PrototypeSession.setAuthenticatedUser(
      id: 'u1',
      name: 'Tourist',
      role: 'tourist',
      email: 'tourist@example.test',
    );
    PrototypeSession.adminTourists.value = [
      {'id': 'u1', 'name': 'Tourist', 'status': 'active'},
      {'id': 'u2', 'name': 'Tourist Two', 'status': 'active'},
    ];
    PrototypeSession.adminDrivers.value = [
      {'id': 'd1', 'name': 'Marco', 'plate': 'TEST-001', 'status': 'active'},
      {
        'id': 'd2',
        'name': 'Juan Dela Cruz',
        'plate': 'TEST-002',
        'status': 'active',
      },
    ];
    PrototypeSession.isDriverOnline.value = true;
    await PrototypeSession.initialize();
  });
  void loginDriver([String id = 'd1', String name = 'Marco']) {
    PrototypeSession.setAuthenticatedUser(
      id: id,
      name: name,
      role: 'driver',
      email: '$id@example.test',
    );
    PrototypeSession.isDriverOnline.value = true;
  }

  void loginTourist() => PrototypeSession.setAuthenticatedUser(
    id: 'u1',
    name: 'Tourist',
    role: 'tourist',
    email: 'tourist@example.test',
  );
  Future<BookingModel> book() => PrototypeSession.createBooking(
    paymentMethod: PaymentMethod.cash,
    expectedFareRevision: PrototypeSession.farePolicy.value.revision,
  );
  test('duplicate concurrent submissions create only one booking', () async {
    final results = await Future.wait([
      book().then<Object>((b) => b, onError: (Object e) => e),
      book().then<Object>((b) => b, onError: (Object e) => e),
    ]);
    expect(results.whereType<BookingModel>().length, 1);
    expect(results.whereType<TripRuleException>().length, 1);
    expect(PrototypeSession.bookings.value.length, 1);
  });
  test(
    'scheduled booking preserves its pickup time and blocks duplicates',
    () async {
      final pickup = DateTime.now().add(const Duration(hours: 3));
      PrototypeSession.scheduledAt = pickup;
      final scheduled = await book();
      expect(scheduled.status, BookingStatus.scheduled);
      expect(scheduled.scheduledAt, pickup);
      expect(scheduled.isActive, isTrue);
      await expectLater(book(), throwsA(isA<TripRuleException>()));
      final cancelled = await PrototypeSession.cancelBooking(
        scheduled.id,
        actor: TripActor.tourist,
        reason: 'Schedule changed',
      );
      expect(cancelled.paymentStatus, PaymentStatus.waived);
    },
  );
  test('one driver cannot accept two live bookings', () async {
    final b = await book();
    final other = b.copyWith(id: 'another', touristId: 'u2');
    PrototypeSession.bookings.value = [b, other];
    loginDriver();
    await PrototypeSession.acceptBooking(b.id);
    await expectLater(
      PrototypeSession.acceptBooking(other.id),
      throwsA(isA<TripRuleException>()),
    );
    expect(
      PrototypeSession.bookingById(other.id).status,
      BookingStatus.pending,
    );
  });
  test(
    'two different drivers racing to accept cannot steal an accepted request',
    () async {
      final b = await book();
      loginDriver();
      final first = PrototypeSession.acceptBooking(
        b.id,
      ).then<Object>((value) => value, onError: (Object e) => e);
      loginDriver('d2', 'Juan Dela Cruz');
      final second = PrototypeSession.acceptBooking(
        b.id,
      ).then<Object>((value) => value, onError: (Object e) => e);
      final results = await Future.wait([first, second]);
      expect(results.whereType<BookingModel>().length, 1);
      expect(results.whereType<TripRuleException>().length, 1);
      expect(PrototypeSession.bookingById(b.id).driverId, 'd1');
    },
  );
  test(
    'removing an attraction does not alter a booked route snapshot',
    () async {
      final b = await book();
      expect(
        () => PrototypeSession.deleteSpot(b.stops.first.spotId),
        throwsA(isA<TripRuleException>()),
      );
      final oldName = b.stops.first.spotName;
      PrototypeSession.allSpots.value = [];
      expect(PrototypeSession.bookingById(b.id).stops.first.spotName, oldName);
    },
  );
  test('unavailable package selection cannot overwrite the existing plan', () {
    final original = PrototypeSession.itinerary.value;
    PrototypeSession.allSpots.value = [];
    expect(
      () => PrototypeSession.selectPackage(TourPackageModel.catalog.first),
      throwsA(isA<TripRuleException>()),
    );
    expect(PrototypeSession.itinerary.value, original);
    expect(PrototypeSession.activePackageId, isNull);
  });
  test(
    'cancellation wins over a later accept without resurrecting the request',
    () async {
      final b = await book();
      await PrototypeSession.cancelBooking(
        b.id,
        actor: TripActor.tourist,
        reason: 'Changed plans',
      );
      loginDriver();
      final accept = PrototypeSession.acceptBooking(b.id);
      await expectLater(accept, throwsA(isA<TripRuleException>()));
      expect(
        PrototypeSession.bookingById(b.id).status,
        BookingStatus.cancelled,
      );
    },
  );
  test(
    'price updates never reprice existing bookings and stale quotes fail',
    () async {
      final b = await book();
      await PrototypeSession.saveFares(
        customCents: 12000,
        packages: const FarePolicy().packageFares,
        expectedRevision: 1,
      );
      expect(PrototypeSession.bookingById(b.id).quotedCents, 7000);
      expect(PrototypeSession.estimatedFare, 120);
      await PrototypeSession.cancelBooking(
        b.id,
        actor: TripActor.tourist,
        reason: 'Changed plans',
      );
      await expectLater(
        PrototypeSession.createBooking(
          paymentMethod: PaymentMethod.cash,
          expectedFareRevision: 1,
        ),
        throwsA(isA<TripRuleException>()),
      );
      expect((await book()).quotedCents, 12000);
    },
  );
  test('online payment cannot be faked by submitting the enum', () async {
    await expectLater(
      PrototypeSession.createBooking(
        paymentMethod: PaymentMethod.online,
        expectedFareRevision: 1,
      ),
      throwsA(isA<TripRuleException>()),
    );
  });
  test('missing pickup, empty itinerary and duplicate stops fail', () async {
    PrototypeSession.customPickupLat = null;
    PrototypeSession.customPickupLng = null;
    PrototypeSession.userLatitude.value = null;
    PrototypeSession.userLongitude.value = null;
    await expectLater(book(), throwsA(isA<TripRuleException>()));
    PrototypeSession.customPickupLat = 14.95;
    PrototypeSession.customPickupLng = 120.92;
    PrototypeSession.itinerary.value = [];
    await expectLater(book(), throwsA(isA<TripRuleException>()));
    final spot = TouristSpotModel.catalog.first;
    PrototypeSession.itinerary.value = [spot, spot];
    await expectLater(book(), throwsA(isA<TripRuleException>()));
  });
  test('review cannot force pending trip to completed', () async {
    final b = await book();
    await expectLater(
      PrototypeSession.markBookingRated(b.id, 5),
      throwsA(isA<TripRuleException>()),
    );
    expect(PrototypeSession.bookingById(b.id).status, BookingStatus.pending);
  });
  test('another driver cannot mutate assigned trip', () async {
    final b = await book();
    loginDriver();
    await PrototypeSession.acceptBooking(b.id);
    loginDriver('d2', 'Juan Dela Cruz');
    await expectLater(
      PrototypeSession.cancelBooking(
        b.id,
        actor: TripActor.driver,
        reason: 'Not my trip',
      ),
      throwsA(isA<TripRuleException>()),
    );
  });
  test(
    'bookings and fixed rates restore after local state is cleared',
    () async {
      final b = await book();
      loginDriver();
      await PrototypeSession.acceptBooking(b.id);
      await PrototypeSession.saveFares(
        customCents: 11000,
        packages: const FarePolicy().packageFares,
        expectedRevision: 1,
      );
      PrototypeSession.bookings.value = [];
      PrototypeSession.farePolicy.value = const FarePolicy();
      PrototypeSession.activeBookingId = null;
      loginTourist();
      await PrototypeSession.initialize();
      expect(PrototypeSession.bookingById(b.id).status, BookingStatus.accepted);
      expect(PrototypeSession.activeBookingId, b.id);
      expect(PrototypeSession.farePolicy.value.customFareCents, 11000);
      expect(PrototypeSession.bookingById(b.id).totalFareCents, 7000);
    },
  );

  test('ending a session clears all user-scoped state', () async {
    await book();
    PrototypeSession.notifications.value = [
      NotificationItem(
        id: 'private',
        title: 'Private update',
        subtitle: 'Only for this account',
        time: DateTime.now(),
        type: NotificationType.booking,
      ),
    ];
    PrototypeSession.favorites.value = {'s1'};
    PrototypeSession.userLatitude.value = 14.95;
    PrototypeSession.userLongitude.value = 120.92;

    PrototypeSession.clearAuthenticatedUser();

    expect(PrototypeSession.authenticatedUserId, isNull);
    expect(PrototypeSession.bookings.value, isEmpty);
    expect(PrototypeSession.notifications.value, isEmpty);
    expect(PrototypeSession.favorites.value, isEmpty);
    expect(PrototypeSession.itinerary.value, isEmpty);
    expect(PrototypeSession.userLatitude.value, isNull);
    expect(PrototypeSession.userLongitude.value, isNull);
  });
}

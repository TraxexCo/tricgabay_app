import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/core/services/fare_policy.dart';
import 'package:tricgabay_app/core/services/trip_rules.dart';
import 'package:tricgabay_app/models/booking_model.dart';
import 'package:tricgabay_app/models/tourist_spot_model.dart';
import 'package:tricgabay_app/models/trip_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSession.bookings.value = [];
    AppSession.farePolicy.value = const FarePolicy();
    AppSession.allSpots.value = TouristSpotModel.catalog;
    AppSession.activePackageId = null;
    AppSession.itinerary.value = TouristSpotModel.catalog.take(2).toList();
    AppSession.draft.pickupLat = 14.95;
    AppSession.draft.pickupLng = 120.92;
    AppSession.draft.scheduledAt = null;
    AppSession.setAuthenticatedUser(
      id: 'u1',
      name: 'Tourist',
      role: 'tourist',
      email: 'tourist@example.test',
    );
    AppSession.adminTourists.value = [
      {'id': 'u1', 'name': 'Tourist', 'status': 'active'},
      {'id': 'u2', 'name': 'Tourist Two', 'status': 'active'},
    ];
    AppSession.adminDrivers.value = [
      {'id': 'd1', 'name': 'Marco', 'plate': 'TEST-001', 'status': 'active'},
      {
        'id': 'd2',
        'name': 'Juan Dela Cruz',
        'plate': 'TEST-002',
        'status': 'active',
      },
    ];
    AppSession.isDriverOnline.value = true;
    await AppSession.initialize();
  });
  void loginDriver([String id = 'd1', String name = 'Marco']) {
    AppSession.setAuthenticatedUser(
      id: id,
      name: name,
      role: 'driver',
      email: '$id@example.test',
    );
    AppSession.isDriverOnline.value = true;
  }

  void loginTourist() => AppSession.setAuthenticatedUser(
    id: 'u1',
    name: 'Tourist',
    role: 'tourist',
    email: 'tourist@example.test',
  );
  Future<BookingModel> book() => AppSession.createBooking(
    paymentMethod: PaymentMethod.cash,
    expectedFareRevision: AppSession.farePolicy.value.revision,
  );
  test('duplicate concurrent submissions create only one booking', () async {
    final results = await Future.wait([
      book().then<Object>((b) => b, onError: (Object e) => e),
      book().then<Object>((b) => b, onError: (Object e) => e),
    ]);
    expect(results.whereType<BookingModel>().length, 1);
    expect(results.whereType<TripRuleException>().length, 1);
    expect(AppSession.bookings.value.length, 1);
  });
  test(
    'scheduled booking preserves its pickup time and blocks duplicates',
    () async {
      final pickup = DateTime.now().add(const Duration(hours: 3));
      AppSession.draft.scheduledAt = pickup;
      final scheduled = await book();
      expect(scheduled.status, BookingStatus.scheduled);
      expect(scheduled.scheduledAt, pickup);
      expect(scheduled.isActive, isTrue);
      await expectLater(book(), throwsA(isA<TripRuleException>()));
      final cancelled = await AppSession.cancelBooking(
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
    AppSession.bookings.value = [b, other];
    loginDriver();
    await AppSession.acceptBooking(b.id);
    await expectLater(
      AppSession.acceptBooking(other.id),
      throwsA(isA<TripRuleException>()),
    );
    expect(AppSession.bookingById(other.id).status, BookingStatus.pending);
  });
  test(
    'two different drivers racing to accept cannot steal an accepted request',
    () async {
      final b = await book();
      loginDriver();
      final first = AppSession.acceptBooking(
        b.id,
      ).then<Object>((value) => value, onError: (Object e) => e);
      loginDriver('d2', 'Juan Dela Cruz');
      final second = AppSession.acceptBooking(
        b.id,
      ).then<Object>((value) => value, onError: (Object e) => e);
      final results = await Future.wait([first, second]);
      expect(results.whereType<BookingModel>().length, 1);
      expect(results.whereType<TripRuleException>().length, 1);
      expect(AppSession.bookingById(b.id).driverId, 'd1');
    },
  );
  test(
    'removing an attraction does not alter a booked route snapshot',
    () async {
      final b = await book();
      expect(
        () => AppSession.deleteSpot(b.stops.first.spotId),
        throwsA(isA<TripRuleException>()),
      );
      final oldName = b.stops.first.spotName;
      AppSession.allSpots.value = [];
      expect(AppSession.bookingById(b.id).stops.first.spotName, oldName);
    },
  );
  test('unavailable package selection cannot overwrite the existing plan', () {
    final original = AppSession.itinerary.value;
    AppSession.allSpots.value = [];
    expect(
      () => AppSession.selectPackage(TourPackageModel.catalog.first),
      throwsA(isA<TripRuleException>()),
    );
    expect(AppSession.itinerary.value, original);
    expect(AppSession.activePackageId, isNull);
  });
  test(
    'cancellation wins over a later accept without resurrecting the request',
    () async {
      final b = await book();
      await AppSession.cancelBooking(
        b.id,
        actor: TripActor.tourist,
        reason: 'Changed plans',
      );
      loginDriver();
      final accept = AppSession.acceptBooking(b.id);
      await expectLater(accept, throwsA(isA<TripRuleException>()));
      expect(AppSession.bookingById(b.id).status, BookingStatus.cancelled);
    },
  );
  test(
    'price updates never reprice existing bookings and stale quotes fail',
    () async {
      final b = await book();
      await AppSession.saveFares(
        customCents: 12000,
        packages: const FarePolicy().packageFares,
        expectedRevision: 1,
      );
      expect(AppSession.bookingById(b.id).quotedCents, 7000);
      expect(AppSession.estimatedFare, 120);
      await AppSession.cancelBooking(
        b.id,
        actor: TripActor.tourist,
        reason: 'Changed plans',
      );
      await expectLater(
        AppSession.createBooking(
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
      AppSession.createBooking(
        paymentMethod: PaymentMethod.online,
        expectedFareRevision: 1,
      ),
      throwsA(isA<TripRuleException>()),
    );
  });
  test('missing pickup, empty itinerary and duplicate stops fail', () async {
    AppSession.draft.pickupLat = null;
    AppSession.draft.pickupLng = null;
    AppSession.userLatitude.value = null;
    AppSession.userLongitude.value = null;
    await expectLater(book(), throwsA(isA<TripRuleException>()));
    AppSession.draft.pickupLat = 14.95;
    AppSession.draft.pickupLng = 120.92;
    AppSession.itinerary.value = [];
    await expectLater(book(), throwsA(isA<TripRuleException>()));
    final spot = TouristSpotModel.catalog.first;
    AppSession.itinerary.value = [spot, spot];
    await expectLater(book(), throwsA(isA<TripRuleException>()));
  });
  test('review cannot force pending trip to completed', () async {
    final b = await book();
    await expectLater(
      AppSession.markBookingRated(b.id, 5),
      throwsA(isA<TripRuleException>()),
    );
    expect(AppSession.bookingById(b.id).status, BookingStatus.pending);
  });
  test('another driver cannot mutate assigned trip', () async {
    final b = await book();
    loginDriver();
    await AppSession.acceptBooking(b.id);
    loginDriver('d2', 'Juan Dela Cruz');
    await expectLater(
      AppSession.cancelBooking(
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
      await AppSession.acceptBooking(b.id);
      await AppSession.saveFares(
        customCents: 11000,
        packages: const FarePolicy().packageFares,
        expectedRevision: 1,
      );
      AppSession.bookings.value = [];
      AppSession.farePolicy.value = const FarePolicy();
      AppSession.activeBookingId = null;
      loginTourist();
      await AppSession.initialize();
      expect(AppSession.bookingById(b.id).status, BookingStatus.accepted);
      expect(AppSession.activeBookingId, b.id);
      expect(AppSession.farePolicy.value.customFareCents, 11000);
      expect(AppSession.bookingById(b.id).totalFareCents, 7000);
    },
  );

  test('ending a session clears all user-scoped state', () async {
    await book();
    AppSession.notifications.value = [
      NotificationItem(
        id: 'private',
        title: 'Private update',
        subtitle: 'Only for this account',
        time: DateTime.now(),
        type: NotificationType.booking,
      ),
    ];
    AppSession.favorites.value = {'s1'};
    AppSession.userLatitude.value = 14.95;
    AppSession.userLongitude.value = 120.92;

    AppSession.clearAuthenticatedUser();

    expect(AppSession.authenticatedUserId, isNull);
    expect(AppSession.bookings.value, isEmpty);
    expect(AppSession.notifications.value, isEmpty);
    expect(AppSession.favorites.value, isEmpty);
    expect(AppSession.itinerary.value, isEmpty);
    expect(AppSession.userLatitude.value, isNull);
    expect(AppSession.userLongitude.value, isNull);
  });
}

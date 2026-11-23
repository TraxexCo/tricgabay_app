import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/core/services/fare_policy.dart';
import 'package:tricgabay_app/core/services/trip_rules.dart';
import 'package:tricgabay_app/models/booking_model.dart';
import 'package:tricgabay_app/models/tourist_spot_model.dart';
import 'package:tricgabay_app/models/trip_record.dart';
import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'trip_rules_test.dart' show accepted;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSession.bookings.value = [];
    AppSession.farePolicy.value = const FarePolicy();
    AppSession.allSpots.value = TouristSpotModel.catalog;
    AppSession.activePackageId = null;
    AppSession.itinerary.value = TouristSpotModel.catalog.take(2).toList();
    // Tours are booked for a chosen day and start time.
    AppSession.draft.scheduledAt = DateTime.now().toUtc().add(
      const Duration(days: 1),
    );
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
  Future<BookingModel> book() => AppSession.createBooking(
    paymentMethod: PaymentMethod.cash,
    expectedFareRevision: AppSession.farePolicy.value.revision,
  );
  Matcher rule(String code) => throwsA(
    isA<TripRuleException>().having((e) => e.message, 'message', code),
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
  test('online payment cannot be faked by submitting the enum', () async {
    await expectLater(
      AppSession.createBooking(
        paymentMethod: PaymentMethod.online,
        expectedFareRevision: 1,
      ),
      rule(MessageCode.onlinePaymentUnavailable),
    );
  });
  test('missing tour day, empty itinerary and duplicate stops fail', () async {
    // The meeting point is fixed (tourism office); the day is required.
    final day = AppSession.draft.scheduledAt;
    AppSession.draft.scheduledAt = null;
    await expectLater(book(), rule(MessageCode.chooseATourDayAndStartTime));
    AppSession.draft.scheduledAt = day;
    AppSession.itinerary.value = [];
    await expectLater(
      book(),
      rule(MessageCode.selectBetween1And12Destinations),
    );
    final spot = TouristSpotModel.catalog.first;
    AppSession.itinerary.value = [spot, spot];
    await expectLater(book(), rule(MessageCode.removeDuplicateDestinations));
  });

  test(
    'a valid booking still needs the server; nothing is simulated',
    () async {
      await expectLater(book(), rule(MessageCode.serverConnectionRequired));
      expect(AppSession.bookings.value, isEmpty);
    },
  );

  test('trip actions need the server', () async {
    for (final action in <Future<Object?> Function()>[
      () => AppSession.cancelBooking(
        'b1',
        actor: TripActor.tourist,
        reason: 'Plans changed',
      ),
      () => AppSession.acceptBooking('b1'),
      () => AppSession.startTrip('b1', '1234'),
      () => AppSession.completeTrip('b1'),
      () => AppSession.confirmCash('b1', TripActor.tourist),
      () => AppSession.markBookingRated('b1', 5),
    ]) {
      await expectLater(action(), rule(MessageCode.serverConnectionRequired));
    }
  });

  test('ending a session clears all user-scoped state', () async {
    AppSession.bookings.value = [accepted()];
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

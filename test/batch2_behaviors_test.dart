import 'package:tricgabay_app/core/services/pickup_recovery_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tricgabay_app/core/services/booking_request_material.dart';
import 'package:tricgabay_app/core/services/booking_payment_flow.dart';
import 'package:tricgabay_app/core/services/error_messages.dart';
import 'package:tricgabay_app/core/services/pickup_service_area.dart';
import 'package:tricgabay_app/core/services/route_geometry.dart';
import 'package:tricgabay_app/core/services/section_refresh.dart';
import 'package:tricgabay_app/core/services/server_clock.dart';
import 'package:tricgabay_app/core/utils/validators.dart';
import 'package:tricgabay_app/core/widgets/minimum_version_gate.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/core/widgets/registration_privacy.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';
import 'package:tricgabay_app/models/booking_model.dart';
import 'package:tricgabay_app/models/trip_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(ServerClock.reset);
  test(
    'booking retries and a restarted caller reuse the persisted UUID',
    () async {
      final storage = <String, String>{};
      Future<String> prepare(String owner, Map<String, dynamic> payload) =>
          BookingRequestMaterial.prepare(
            userId: owner,
            payload: payload,
            read: (key) async => storage[key],
            write: (key, value) async {
              storage[key] = value;
            },
          );
      final id = await prepare('one', {'fare': 100});
      expect(await prepare('one', {'fare': 100}), id);
      expect(await prepare('two', {'fare': 100}), isNot(id));
      await expectLater(
        prepare('one', {'fare': 200}),
        throwsA(isA<ClientOperationException>()),
      );
    },
  );
  test('request recovery rejects other active bookings and other accounts', () {
    expect(
      matchingBookingRequest(
        {
          'id': 'wrong',
          'tourist_id': 'owner',
          'client_request_id': 'different',
        },
        userId: 'owner',
        requestId: 'right',
      ),
      isNull,
    );
    expect(
      matchingBookingRequest(
        {'id': 'wrong', 'tourist_id': 'other', 'client_request_id': 'right'},
        userId: 'owner',
        requestId: 'right',
      ),
      isNull,
    );
    expect(
      matchingBookingRequest(
        {
          'id': 'right-booking',
          'tourist_id': 'owner',
          'client_request_id': 'right',
        },
        userId: 'owner',
        requestId: 'right',
      ),
      'right-booking',
    );
  });
  test(
    'pickup reissue retries the same material after a lost response',
    () async {
      final storage = <String, String>{'pickup_code_owner_booking': '1111'};
      final materials = <PickupRecoveryMaterial>[];
      var fail = true;
      Future<String> reissue() => reissuePickupWithMaterial(
        userId: 'owner',
        bookingId: 'booking',
        read: (key) async => storage[key],
        write: (key, value) async {
          storage[key] = value;
        },
        delete: (key) async {
          storage.remove(key);
        },
        issue: (material) async {
          materials.add(material);
          if (fail) throw StateError('lost response');
          return material.code;
        },
      );
      await expectLater(reissue(), throwsStateError);
      expect(storage['pickup_code_owner_booking'], '1111');
      fail = false;
      final code = await reissue();
      expect(code, isNot('1111'));
      expect(materials.first.requestId, materials.last.requestId);
      expect(materials.first.code, materials.last.code);
      expect(storage['pickup_code_owner_booking'], code);
      expect(
        storage.containsKey(pickupRecoveryRequestKey('owner', 'booking')),
        isFalse,
      );
    },
  );
  test('bad rows do not discard later valid records', () async {
    final collected = <int>[], failures = <Object>[];
    for (final value in [1, 'bad', 2]) {
      await readRowIndependently(() async {
        collected.add(value as int);
      }, (error, stack) => failures.add(error));
    }
    expect(collected, [1, 2]);
    expect(failures, hasLength(1));
  });
  test('a failed secure write cannot send an unpersisted request ID', () async {
    await expectLater(
      BookingRequestMaterial.prepare(
        userId: 'one',
        payload: {},
        read: (key) async => null,
        write: (key, value) async {
          throw StateError('disk');
        },
      ),
      throwsStateError,
    );
  });
  test('checkout creation failure does not launch a browser', () async {
    var launched = false;
    await expectLater(
      openBookingPayment(
        bookingId: 'one',
        createCheckout: (id) async => throw StateError('offline'),
        launch: (uri) async {
          launched = true;
          return true;
        },
      ),
      throwsStateError,
    );
    expect(launched, isFalse);
  });
  test(
    'browser launch failure leaves the same booking available for retry',
    () async {
      final ids = <String>[];
      Future<String> checkout(String id) async {
        ids.add(id);
        return 'https://checkout.paymongo.com/cs_test';
      }

      await expectLater(
        openBookingPayment(
          bookingId: 'one',
          createCheckout: checkout,
          launch: (uri) async => false,
        ),
        throwsA(isA<ClientOperationException>()),
      );
      await openBookingPayment(
        bookingId: 'one',
        createCheckout: checkout,
        launch: (uri) async => true,
      );
      expect(ids, ['one', 'one']);
    },
  );
  test('untrusted checkout origins never launch', () async {
    for (final url in [
      'http://checkout.paymongo.com/x',
      'https://checkout.paymongo.com.attacker.test/x',
      'https://person@checkout.paymongo.com/x',
      'https://checkout.paymongo.com:444/x',
    ]) {
      await expectLater(
        openBookingPayment(
          bookingId: 'one',
          createCheckout: (id) async => url,
          launch: (uri) async => fail('untrusted launch'),
        ),
        throwsA(isA<ClientOperationException>()),
      );
    }
  });
  test(
    'pickup circle includes its centre and rejects distant/invalid pins',
    () {
      const area = PickupServiceArea(14.9571, 120.9188, 15);
      expect(area.contains(14.9571, 120.9188), isTrue);
      expect(area.contains(15.3, 120.9188), isFalse);
      expect(area.contains(double.nan, 120), isFalse);
      expect(area.contains(91, 120), isFalse);
      expect(
        const PickupServiceArea(14.9571, 120.9188, 1).contains(14.98, 120.9188),
        isFalse,
      );
    },
  );
  test('names accept Filipino, accented and decomposed Unicode names', () {
    for (final name in [
      'Niño Muñoz',
      'José Dela Cruz',
      'Maria-José O’Neill',
      "Anne O'Brien",
      'Jose\u0301 Cruz',
    ]) {
      expect(Validators.fullName(name), isNull, reason: name);
    }
    expect(Validators.fullName('Juan123'), isNotNull);
    expect(Validators.fullName('<script>'), isNotNull);
  });
  test('phone formats normalize to E.164 without changing foreign numbers', () {
    expect(Validators.normalizePhone('09123456789'), '+639123456789');
    expect(Validators.normalizePhone('+63 912 345 6789'), '+639123456789');
    for (final phone in [
      '09123456789',
      '+639123456789',
      '+14155550123',
      '+44 20 7946 0958',
    ]) {
      expect(Validators.phoneNumber(phone), isNull, reason: phone);
    }
    for (final phone in [
      '+0123456789',
      '0912',
      '+1234567890123456',
      'call me',
      '123456789',
    ]) {
      expect(Validators.phoneNumber(phone), isNotNull, reason: phone);
    }
  });
  test('email accepts plus tags and long TLDs', () {
    expect(Validators.email('name+tag@gmail.com'), isNull);
    expect(Validators.email('hello@example.technology'), isNull);
    expect(Validators.email('hello @example.com'), isNotNull);
    expect(Validators.email('hello@@example.com'), isNotNull);
  });
  test('user messages do not echo backend details, contact data or URLs', () {
    const secret = 'https://service.test?token=secret&phone=09123456789';
    for (final error in [
      StateError(secret),
      const PostgrestException(message: secret, code: 'XX000'),
      const AuthException(secret),
    ]) {
      final message = ErrorMessages.forError(error);
      expect(message, isNot(contains('secret')));
      expect(message, isNot(contains('09123456789')));
      expect(message, isNot(contains('https://')));
    }
  });
  test('long straight route segments do not produce false deviations', () {
    final route = [Position(120.9, 14.95), Position(121.0, 14.95)];
    expect(distanceToRouteMeters(14.95, 120.95, route), closeTo(0, 0.01));
    expect(
      distanceToRouteMeters(14.951, 120.95, route),
      inInclusiveRange(110, 112),
    );
    expect(distanceToRouteMeters(14.95, 120.89, route), greaterThan(1000));
    expect(distanceToRouteMeters(14.95, 120.9, [route.first, route.first]), 0);
  });
  test(
    'route reuse depends on destinations and distance to existing geometry',
    () {
      final policy = RouteRefreshPolicy();
      final points = [Position(120.9, 14.95), Position(121, 14.95)];
      expect(policy.canReuse(points), isFalse);
      policy.remember(points, points);
      expect(policy.canReuse([Position(120.95, 14.95), points.last]), isTrue);
      expect(policy.canReuse([Position(120.95, 14.96), points.last]), isFalse);
      expect(policy.canReuse([points.first, Position(121.1, 14.95)]), isFalse);
    },
  );
  test(
    'one section failure preserves its previous data and other successes',
    () async {
      final failures = <Object>[];
      final values = await Future.wait([
        refreshSection(
          () async => throw StateError('offline'),
          ['old'],
          (error, stack) => failures.add(error),
        ),
        refreshSection(() async => ['new'], [
          'stale',
        ], (error, stack) => failures.add(error)),
      ]);
      expect(values, [
        ['old'],
        ['new'],
      ]);
      expect(failures, hasLength(1));
    },
  );
  test(
    'unknown booking/payment/actor values do not become actionable defaults',
    () {
      final model = BookingModel(
        id: 'one',
        touristId: 't',
        touristName: 'Test',
        stops: const [],
        pickupLat: 14.95,
        pickupLng: 120.9,
        pickupAddress: 'Test',
        baseFare: 100,
        totalFare: 100,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.utc(2026),
      );
      final decoded = BookingModel.fromMap({
        ...model.toMap(),
        'status': 'future',
        'paymentStatus': 'future',
        'paymentMethod': 'future',
      }, 'one');
      expect(decoded.status, BookingStatus.unknown);
      expect(decoded.paymentStatus, PaymentStatus.unknown);
      expect(decoded.paymentMethod, PaymentMethod.unknown);
      expect(decoded.isActive, isTrue);
      expect(
        TripEvent.fromMap({
          'at': '2026-01-01T00:00:00Z',
          'actor': 'future',
          'description': 'Event',
        }).actor,
        TripActor.unknown,
      );
      expect(
        model.copyWith(status: BookingStatus.paymentPending).isActive,
        isTrue,
      );
    },
  );
  test('version policy blocks old builds and validates store links', () {
    const policy = VersionPolicy(
      2,
      'https://play.google.com/store/apps/details?id=app.tricgabay',
    );
    expect(policy.blocks(1), isTrue);
    expect(policy.blocks(2), isFalse);
    expect(policy.storeUri, isNotNull);
    expect(
      const VersionPolicy(2, 'https://attacker.test/app').storeUri,
      isNull,
    );
  });
  test(
    'server clock and Manila schedule conversion ignore device timezone',
    () {
      final instant = DateTime.utc(2026, 11, 3, 2, 30);
      ServerClock.synchronize(instant, roundTrip: const Duration(seconds: 2));
      expect(
        ServerClock.now().difference(instant).inMilliseconds,
        inInclusiveRange(1000, 1200),
      );
      expect(ServerClock.fromManila(2026, 11, 3, 10, 30), instant);
      expect(
        ServerClock.formatManila(instant, locale: 'en'),
        matches(RegExp(r'10:30\s*AM')),
      );
      expect(
        ServerClock.formatManila(instant, locale: 'en'),
        contains('Philippine time'),
      );
    },
  );
  testWidgets('required update blocks the protected child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MinimumVersionGate(
          loader: () async => (policy: const VersionPolicy(3, ''), build: 2),
          child: const Text('protected booking'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('protected booking'), findsNothing);
  });
  testWidgets('generated Filipino localization translates payment labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) =>
              Scaffold(body: Text(context.l10n.resumePayment)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ipagpatuloy ang pagbabayad'), findsOneWidget);
  });
  testWidgets('registration cannot proceed without privacy acceptance', (
    tester,
  ) async {
    PrivacyNotice? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await requestRegistrationConsent(
                context,
                loader: () async =>
                    const PrivacyNotice('fixture', 'Test notice', 'Paunawa'),
              );
            },
            child: const Text('Register'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Agree and continue'),
          )
          .onPressed,
      isNull,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('telemetry_consent_v1'), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}

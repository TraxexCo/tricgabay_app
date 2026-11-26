import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/services/active_trip_tracking_service.dart';
import 'package:tricgabay_app/core/services/battery_optimization_service.dart';
import 'package:tricgabay_app/core/services/consent_state.dart';
import 'package:tricgabay_app/core/services/driver_location_guard.dart';
import 'package:tricgabay_app/core/widgets/location_issue_banner.dart';
import 'package:tricgabay_app/features/driver/screens/incoming_booking_screen.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';

import 'location_services_test.dart' show FakeLocationGateway, positionAt;

Widget host(Widget child, {bool scaffold = true}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('fil')],
  home: scaffold ? Scaffold(body: child) : Material(child: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('consent gate for permission prompts', () {
    tearDown(() => ConsentState.blocked.value = false);

    test('no notice showing: nothing to wait for', () async {
      ConsentState.blocked.value = false;
      await ConsentState.whenClear().timeout(const Duration(seconds: 1));
    });

    test('waits while the privacy notice is up, then continues', () async {
      ConsentState.blocked.value = true;
      var released = false;
      final waiting = ConsentState.whenClear().then((_) => released = true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(released, isFalse);
      ConsentState.blocked.value = false;
      await waiting;
      expect(released, isTrue);
    });

    test(
      'tracking does not raise the permission prompt over the notice',
      () async {
        SharedPreferences.setMockInitialValues({});
        final location = FakeLocationGateway()
          ..permission = geo.LocationPermission.denied
          ..requestedPermission = geo.LocationPermission.whileInUse;
        var promptShown = false;
        final gateway = _PromptSpy(location, () => promptShown = true);
        await ActiveTripTrackingService.configureForTesting(
          location: gateway,
          publisher: (_) async {},
        );
        ConsentState.blocked.value = true;
        final starting = ActiveTripTrackingService.start('booking-1');
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(promptShown, isFalse);
        ConsentState.blocked.value = false;
        await starting;
        expect(promptShown, isTrue);
        await ActiveTripTrackingService.resetAfterTesting();
        await location.close();
      },
    );
  });

  group('battery optimization status', () {
    const channel = MethodChannel('com.tricgabay.app/battery');
    var ignoring = false;
    var opened = 0;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      ignoring = false;
      opened = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isIgnoringBatteryOptimizations') {
              return ignoring;
            }
            if (call.method == 'openBatterySettings') {
              opened++;
              return true;
            }
            return null;
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('reports restricted and unrestricted from the system', () async {
      expect(
        await BatteryOptimizationService.status(),
        BatteryStatus.restricted,
      );
      ignoring = true;
      expect(
        await BatteryOptimizationService.status(),
        BatteryStatus.unrestricted,
      );
    });

    test('prompts once, only while still restricted', () async {
      expect(await BatteryOptimizationService.shouldPrompt(), isTrue);
      await BatteryOptimizationService.markPrompted();
      expect(await BatteryOptimizationService.shouldPrompt(), isFalse);
    });

    test('never prompts a driver who already lifted the restriction', () async {
      ignoring = true;
      expect(await BatteryOptimizationService.shouldPrompt(), isFalse);
    });

    test('opens the system battery settings', () async {
      expect(await BatteryOptimizationService.openSettings(), isTrue);
      expect(opened, 1);
    });

    test('a phone without the channel reports unknown, no prompt', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      expect(await BatteryOptimizationService.status(), BatteryStatus.unknown);
      expect(await BatteryOptimizationService.shouldPrompt(), isFalse);
    });
  });

  group('location banner', () {
    late FakeLocationGateway location;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      location = FakeLocationGateway();
      await ActiveTripTrackingService.configureForTesting(
        location: location,
        publisher: (_) async {},
      );
    });

    tearDown(() async {
      await DriverLocationGuard.resetAfterTesting();
      await ActiveTripTrackingService.resetAfterTesting();
      await location.close();
    });

    testWidgets('location off: message and a button to the location settings', (
      tester,
    ) async {
      location.serviceEnabled = false;
      DriverLocationGuard.start(
        shouldShare: () => true,
        isOnline: () => true,
        setOnline: (_) async {},
        onOnlineRestored: (_) {},
        location: location,
        interval: const Duration(milliseconds: 30),
      );
      await tester.pumpWidget(host(const LocationIssueBanner()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
      expect(find.text('Open location settings'), findsOneWidget);
      await tester.tap(find.text('Open location settings'));
      await tester.pump();
      expect(location.openedLocationSettings, 1);
      DriverLocationGuard.stop();
    });

    testWidgets('permission lost: button opens the app settings', (
      tester,
    ) async {
      location.permission = geo.LocationPermission.deniedForever;
      DriverLocationGuard.start(
        shouldShare: () => true,
        isOnline: () => true,
        setOnline: (_) async {},
        onOnlineRestored: (_) {},
        location: location,
        interval: const Duration(milliseconds: 30),
      );
      await tester.pumpWidget(host(const LocationIssueBanner()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
      expect(find.text('Open app settings'), findsOneWidget);
      await tester.tap(find.text('Open app settings'));
      await tester.pump();
      expect(location.openedAppSettings, 1);
      DriverLocationGuard.stop();
    });

    testWidgets('nothing is shown when location works', (tester) async {
      DriverLocationGuard.start(
        shouldShare: () => true,
        isOnline: () => true,
        setOnline: (_) async {},
        onOnlineRestored: (_) {},
        location: location,
        interval: const Duration(milliseconds: 30),
      );
      await tester.pumpWidget(host(const LocationIssueBanner()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
      expect(find.text('Open location settings'), findsNothing);
      expect(find.text('Open app settings'), findsNothing);
      DriverLocationGuard.stop();
    });

    testWidgets('hidden under the privacy notice', (tester) async {
      location.serviceEnabled = false;
      ConsentState.blocked.value = true;
      DriverLocationGuard.start(
        shouldShare: () => true,
        isOnline: () => true,
        setOnline: (_) async {},
        onOnlineRestored: (_) {},
        location: location,
        interval: const Duration(milliseconds: 30),
      );
      await tester.pumpWidget(host(const LocationIssueBanner()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
      expect(find.text('Open location settings'), findsNothing);
      ConsentState.blocked.value = false;
      DriverLocationGuard.stop();
    });
  });

  group('banner layout', () {
    late FakeLocationGateway location;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      location = FakeLocationGateway();
      await ActiveTripTrackingService.configureForTesting(
        location: location,
        publisher: (_) async {},
      );
    });

    tearDown(() async {
      await DriverLocationGuard.resetAfterTesting();
      await ActiveTripTrackingService.resetAfterTesting();
      await location.close();
    });

    testWidgets('banner is full width and screens below drop the top inset', (
      tester,
    ) async {
      double? bodyTopInset;
      await tester.pumpWidget(
        host(
          scaffold: false,
          MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(top: 40),
            ),
            child: Column(
              children: [
                const LocationIssueBanner(),
                Expanded(
                  child: LocationBannerBody(
                    child: Builder(
                      builder: (context) {
                        bodyTopInset = MediaQuery.paddingOf(context).top;
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(bodyTopInset, 40); // no banner: normal status-bar inset
      DriverLocationGuard.start(
        shouldShare: () => true,
        isOnline: () => true,
        setOnline: (_) async {},
        onOnlineRestored: (_) {},
        location: location,
        interval: const Duration(milliseconds: 30),
      );
      location.setServiceEnabled(false);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      expect(find.text('Open location settings'), findsOneWidget);
      expect(
        tester.getSize(find.byType(LocationIssueBanner)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
      expect(bodyTopInset, 0); // the banner already covers the status bar
      location.autoEmit = () => positionAt(DateTime.now(), accuracy: 20);
      location.setServiceEnabled(true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      expect(find.text('Open location settings'), findsNothing);
      expect(bodyTopInset, 40);
      DriverLocationGuard.stop();
      // Let any fix-wait timeout started by the last check run out.
      await tester.pump(const Duration(seconds: 15));
    });
  });

  group('offer countdown', () {
    testWidgets('counts down and says when the offer has expired', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          OfferCountdown(
            expiresAt: DateTime.now().add(const Duration(seconds: 90)),
          ),
        ),
      );
      expect(find.textContaining('Offer expires in 1:'), findsOneWidget);
      await tester.pumpWidget(
        host(
          OfferCountdown(
            expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('This offer has expired.'), findsOneWidget);
    });
  });
}

/// Wraps the fake so a test can see when the system prompt would appear.
class _PromptSpy extends FakeLocationGateway {
  final FakeLocationGateway inner;
  final void Function() onPrompt;
  _PromptSpy(this.inner, this.onPrompt);

  @override
  Future<geo.LocationPermission> checkPermission() => inner.checkPermission();

  @override
  Future<bool> isServiceEnabled() => inner.isServiceEnabled();

  @override
  Future<geo.LocationPermission> requestPermission() {
    onPrompt();
    return inner.requestPermission();
  }

  @override
  Stream<geo.Position> positionStream({
    required geo.LocationSettings settings,
  }) => inner.positionStream(settings: settings);
}

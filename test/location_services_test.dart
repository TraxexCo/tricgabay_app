import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/services/active_trip_tracking_service.dart';
import 'package:tricgabay_app/core/services/driver_availability_controller.dart';
import 'package:tricgabay_app/core/services/driver_location_guard.dart';
import 'package:tricgabay_app/core/services/location_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('location sample freshness boundaries', () {
    final now = DateTime.utc(2026, 10, 24, 8);

    test('accepts both documented clock-skew boundaries', () {
      expect(
        isUsableLocationSample(
          positionAt(now.subtract(const Duration(minutes: 2))),
          now: now,
        ),
        isTrue,
      );
      expect(
        isUsableLocationSample(
          positionAt(now.add(const Duration(seconds: 30))),
          now: now,
        ),
        isTrue,
      );
    });

    test('rejects stale, future-skewed, duplicate, and inaccurate samples', () {
      expect(
        isUsableLocationSample(
          positionAt(now.subtract(const Duration(minutes: 2, milliseconds: 1))),
          now: now,
        ),
        isFalse,
      );
      expect(
        isUsableLocationSample(
          positionAt(now.add(const Duration(seconds: 30, milliseconds: 1))),
          now: now,
        ),
        isFalse,
      );
      expect(
        isUsableLocationSample(positionAt(now), now: now, newerThan: now),
        isFalse,
      );
      expect(
        isUsableLocationSample(positionAt(now, accuracy: 200.01), now: now),
        isFalse,
      );
    });
  });

  group('driver availability location boundary', () {
    late FakeLocationGateway location;
    late List<String> events;
    late DriverAvailabilityController controller;

    setUp(() {
      location = FakeLocationGateway();
      events = [];
      controller = DriverAvailabilityController(
        location: location,
        writeOnline: (online) async => events.add('online:$online'),
        publish: (position) async => events.add('publish:${position.latitude}'),
        onPosition: (position) => events.add('position:${position.latitude}'),
        currentSettings: const geo.LocationSettings(),
        streamSettings: const geo.LocationSettings(),
        positionTimeout: const Duration(milliseconds: 10),
      );
    });

    tearDown(() async {
      await controller.dispose();
      await location.close();
    });

    test(
      'disabled location leaves driver offline without opening a stream',
      () async {
        location.serviceEnabled = false;
        final result = await controller.setOnline(true);
        expect(result.failure, DriverAvailabilityFailure.locationDisabled);
        expect(events, isEmpty);
        expect(location.streamRequests, 0);
      },
    );

    test('denied and permanently denied permission fail safely', () async {
      location.permission = geo.LocationPermission.denied;
      location.requestedPermission = geo.LocationPermission.denied;
      var result = await controller.setOnline(true);
      expect(result.failure, DriverAvailabilityFailure.permissionDenied);
      expect(events, isEmpty);

      location.requestedPermission = geo.LocationPermission.deniedForever;
      result = await controller.setOnline(true);
      expect(result.failure, DriverAvailabilityFailure.permissionDeniedForever);
      expect(events, isEmpty);
    });

    test('position failure and timeout never mark the driver online', () async {
      location.positionError = StateError('gps failed');
      var result = await controller.setOnline(true);
      expect(result.failure, DriverAvailabilityFailure.positionUnavailable);
      expect(events, isEmpty);

      location.positionError = null;
      location.neverCompletePosition = true;
      result = await controller.setOnline(true);
      expect(result.failure, DriverAvailabilityFailure.positionUnavailable);
      expect(events, isEmpty);
    });

    test(
      'online transition waits for a usable position and server approval',
      () async {
        location.onCurrentPosition = () => events.add('current');
        final result = await controller.setOnline(true);
        expect(result.success, isTrue);
        expect(events, [
          'current',
          'online:true',
          'publish:14.95',
          'position:14.95',
        ]);
        expect(controller.isSharing, isTrue);
      },
    );

    test(
      'server rejection cancels startup and repeated taps share one transition',
      () async {
        final release = Completer<void>();
        var writes = 0;
        controller = DriverAvailabilityController(
          location: location,
          writeOnline: (_) async {
            writes++;
            await release.future;
            throw StateError('rejected');
          },
          publish: (_) async {},
          onPosition: (_) {},
          currentSettings: const geo.LocationSettings(),
          streamSettings: const geo.LocationSettings(),
        );
        final first = controller.setOnline(true);
        final second = controller.setOnline(true);
        expect(identical(first, second), isTrue);
        release.complete();
        final result = await first;
        expect(result.failure, DriverAvailabilityFailure.serverRejected);
        expect(writes, 1);
        expect(controller.isSharing, isFalse);
      },
    );

    test('offline confirmation cancels the stream and later samples', () async {
      expect((await controller.setOnline(true)).success, isTrue);
      expect((await controller.setOnline(false)).success, isTrue);
      expect(controller.isSharing, isFalse);
      expect(location.cancelCount, 1);
    });

    test('stale and out-of-order samples are ignored', () async {
      expect((await controller.setOnline(true)).success, isTrue);
      events.clear();
      location.emit(position(minutesAgo: 3, latitude: 1));
      location.emit(position(secondsAgo: 1, latitude: 2));
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
    });
  });

  group('active trip tracking lifecycle', () {
    late FakeLocationGateway location;
    late List<geo.Position> published;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      location = FakeLocationGateway();
      published = [];
      await ActiveTripTrackingService.configureForTesting(
        location: location,
        publisher: (sample) async => published.add(sample),
      );
    });

    tearDown(() async {
      await ActiveTripTrackingService.resetAfterTesting();
      await location.close();
    });

    test('cached recovery data alone never starts transmission', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'active_driver_tracking_booking_v1',
        'cached-booking',
      );
      expect(
        await ActiveTripTrackingService.recoveryBookingId(),
        'cached-booking',
      );
      expect(location.streamRequests, 0);
      expect(ActiveTripTrackingService.health.value, TrackingHealth.stopped);
    });

    test(
      'authoritative assignment starts and terminal state stops tracking',
      () async {
        await ActiveTripTrackingService.reconcileAuthoritativeBooking(
          'booking-1',
        );
        expect(location.streamRequests, 1);
        location.emit(position());
        await Future<void>.delayed(Duration.zero);
        expect(published, hasLength(1));

        await ActiveTripTrackingService.reconcileAuthoritativeBooking(null);
        expect(location.cancelCount, 1);
        expect(ActiveTripTrackingService.health.value, TrackingHealth.stopped);
        expect(await ActiveTripTrackingService.recoveryBookingId(), isNull);
      },
    );

    test('mock samples remain publishable and carry the review flag', () async {
      await ActiveTripTrackingService.reconcileAuthoritativeBooking(
        'booking-1',
      );
      location.emit(position(isMocked: true));
      await Future<void>.delayed(Duration.zero);
      expect(published.single.isMocked, isTrue);
      expect(ActiveTripTrackingService.health.value, TrackingHealth.live);
    });

    test('tracking rejects stale and out-of-order positions', () async {
      await ActiveTripTrackingService.reconcileAuthoritativeBooking(
        'booking-1',
      );
      location.emit(position());
      location.emit(position(minutesAgo: 3, latitude: 1));
      location.emit(position(secondsAgo: 1, latitude: 2));
      await Future<void>.delayed(Duration.zero);
      expect(published, hasLength(1));
    });

    test(
      'logout-style stop disposes the stream and cannot restart itself',
      () async {
        await ActiveTripTrackingService.reconcileAuthoritativeBooking(
          'booking-1',
        );
        await ActiveTripTrackingService.stop();
        location.emit(position());
        await Future<void>.delayed(Duration.zero);
        expect(published, isEmpty);
        expect(location.streamRequests, 1);
        expect(location.cancelCount, 1);
        expect(ActiveTripTrackingService.bookingId, isNull);
      },
    );
  });

  group('fresh fix for arrival', () {
    late FakeLocationGateway location;
    late List<geo.Position> published;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      location = FakeLocationGateway();
      published = [];
      await ActiveTripTrackingService.configureForTesting(
        location: location,
        publisher: (sample) async => published.add(sample),
      );
    });

    tearDown(() async {
      await ActiveTripTrackingService.resetAfterTesting();
      await location.close();
    });

    const shortWait = Duration(milliseconds: 150);

    test('returns a fresh accurate fix and publishes it first', () async {
      location.autoEmit = () => positionAt(DateTime.now(), accuracy: 20);
      final result = await ActiveTripTrackingService.publishFreshFix(
        timeout: shortWait,
      );
      expect(result.ok, isTrue);
      expect(published, hasLength(1));
      expect(ActiveTripTrackingService.lastPublishedAt.value, isNotNull);
    });

    test('accuracy over the 100 m server limit is a weak signal', () async {
      location.autoEmit = () => positionAt(DateTime.now(), accuracy: 101);
      final result = await ActiveTripTrackingService.publishFreshFix(
        timeout: shortWait,
      );
      expect(result.failure, FreshFixFailure.weakSignal);
      expect(published, isEmpty);
    });

    test('accuracy exactly 100 m is accepted', () async {
      location.autoEmit = () => positionAt(DateTime.now(), accuracy: 100);
      final result = await ActiveTripTrackingService.publishFreshFix(
        timeout: shortWait,
      );
      expect(result.ok, isTrue);
    });

    test('an old fix is never reused', () async {
      location.autoEmit = () => positionAt(
        DateTime.now().subtract(const Duration(seconds: 40)),
        accuracy: 10,
      );
      final result = await ActiveTripTrackingService.publishFreshFix(
        timeout: shortWait,
      );
      expect(result.failure, FreshFixFailure.weakSignal);
      expect(published, isEmpty);
    });

    test('no signal at all times out as a weak signal', () async {
      final result = await ActiveTripTrackingService.publishFreshFix(
        timeout: shortWait,
      );
      expect(result.failure, FreshFixFailure.weakSignal);
    });

    test('location off and permission lost are named separately', () async {
      location.serviceEnabled = false;
      expect(
        (await ActiveTripTrackingService.acquireFreshFix(
          timeout: shortWait,
        )).failure,
        FreshFixFailure.locationDisabled,
      );
      location.serviceEnabled = true;
      location.permission = geo.LocationPermission.denied;
      expect(
        (await ActiveTripTrackingService.acquireFreshFix(
          timeout: shortWait,
        )).failure,
        FreshFixFailure.permissionDenied,
      );
    });
  });

  group('trip heartbeat', () {
    late FakeLocationGateway location;
    late List<geo.Position> published;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      location = FakeLocationGateway();
      published = [];
      await ActiveTripTrackingService.configureForTesting(
        location: location,
        publisher: (sample) async => published.add(sample),
        heartbeatInterval: const Duration(milliseconds: 60),
        heartbeatFixTimeout: const Duration(milliseconds: 80),
      );
    });

    tearDown(() async {
      await ActiveTripTrackingService.resetAfterTesting();
      await location.close();
    });

    test(
      'a still phone still publishes: the heartbeat asks for its own fix',
      () async {
        await ActiveTripTrackingService.start('booking-1');
        expect(location.streamRequests, 1);
        // The device stream stays silent (driver not moving) ...
        location.autoEmit = () => positionAt(DateTime.now(), accuracy: 30);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        // ... yet the service opened extra fresh-fix requests and published.
        expect(location.streamRequests, greaterThan(1));
        expect(published, isNotEmpty);
        expect(ActiveTripTrackingService.health.value, TrackingHealth.live);
      },
    );

    test('the heartbeat stops with the trip', () async {
      await ActiveTripTrackingService.start('booking-1');
      await ActiveTripTrackingService.stop();
      final requests = location.streamRequests;
      location.autoEmit = () => positionAt(DateTime.now(), accuracy: 30);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(location.streamRequests, requests);
      expect(published, isEmpty);
    });

    test('a failed heartbeat marks tracking degraded, not stopped', () async {
      await ActiveTripTrackingService.start('booking-1');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(ActiveTripTrackingService.health.value, TrackingHealth.degraded);
      expect(ActiveTripTrackingService.bookingId, 'booking-1');
    });

    test('location switched off during the trip is reported', () async {
      await ActiveTripTrackingService.start('booking-1');
      location.serviceEnabled = false;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(
        ActiveTripTrackingService.health.value,
        TrackingHealth.locationDisabled,
      );
    });
  });

  group('driver location guard', () {
    late FakeLocationGateway location;
    var shouldShare = true;
    var online = true;
    late List<bool> writes;
    late List<bool> restored;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      shouldShare = true;
      online = true;
      writes = [];
      restored = [];
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

    void startGuard() => DriverLocationGuard.start(
      shouldShare: () => shouldShare,
      isOnline: () => online,
      setOnline: (value) async => writes.add(value),
      onOnlineRestored: restored.add,
      location: location,
      interval: const Duration(milliseconds: 40),
    );

    Future<void> until(bool Function() condition) async {
      for (var i = 0; i < 60 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    test('location off while online shows the banner state', () async {
      location.serviceEnabled = false;
      startGuard();
      await until(
        () => DriverLocationGuard.issue.value == LocationIssue.serviceOff,
      );
      expect(DriverLocationGuard.issue.value, LocationIssue.serviceOff);
      await DriverLocationGuard.openSettingsForIssue();
      expect(location.openedLocationSettings, 1);
    });

    test('lost permission opens the app settings instead', () async {
      location.permission = geo.LocationPermission.deniedForever;
      startGuard();
      await until(
        () =>
            DriverLocationGuard.issue.value ==
            LocationIssue.permissionDeniedForever,
      );
      await DriverLocationGuard.openSettingsForIssue();
      expect(location.openedAppSettings, 1);
      expect(location.openedLocationSettings, 0);
    });

    test('an offline driver with working location sees nothing', () async {
      shouldShare = false;
      online = false;
      location.serviceEnabled = false;
      startGuard();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(DriverLocationGuard.issue.value, LocationIssue.none);
    });

    test(
      'driver put offline because fixes stopped is restored automatically',
      () async {
        location.serviceEnabled = false;
        startGuard();
        await until(
          () => DriverLocationGuard.issue.value == LocationIssue.serviceOff,
        );
        // The server's heartbeat check puts the driver offline meanwhile.
        online = false;
        shouldShare = false;
        location.autoEmit = () => positionAt(DateTime.now(), accuracy: 25);
        location.setServiceEnabled(true);
        await until(() => writes.isNotEmpty);
        expect(writes, [true]);
        expect(restored, [true]);
        expect(DriverLocationGuard.issue.value, LocationIssue.none);
        expect(DriverLocationGuard.restoredNotice.value, isTrue);
        // And only once.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(writes, [true]);
      },
    );

    test('a driver who chose to go offline is never put back online', () async {
      location.serviceEnabled = false;
      startGuard();
      await until(
        () => DriverLocationGuard.issue.value == LocationIssue.serviceOff,
      );
      online = false;
      shouldShare = false;
      await DriverLocationGuard.driverChoseOffline();
      location.autoEmit = () => positionAt(DateTime.now(), accuracy: 25);
      location.setServiceEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(writes, isEmpty);
    });

    test('no restore until a real fix proves location works again', () async {
      location.serviceEnabled = false;
      startGuard();
      await until(
        () => DriverLocationGuard.issue.value == LocationIssue.serviceOff,
      );
      online = false;
      shouldShare = false;
      location.setServiceEnabled(true); // switch is on, but no fix arrives
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(writes, isEmpty);
    });
  });
}

geo.Position positionAt(DateTime timestamp, {double accuracy = 5}) =>
    geo.Position(
      longitude: 120.92,
      latitude: 14.95,
      timestamp: timestamp,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

geo.Position position({
  int minutesAgo = 0,
  int secondsAgo = 0,
  double latitude = 14.95,
  bool isMocked = false,
}) => geo.Position(
  isMocked: isMocked,
  longitude: 120.92,
  latitude: latitude,
  timestamp: DateTime.now().subtract(
    Duration(minutes: minutesAgo, seconds: secondsAgo),
  ),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class FakeLocationGateway implements LocationGateway {
  bool serviceEnabled = true;
  geo.LocationPermission permission = geo.LocationPermission.whileInUse;
  geo.LocationPermission requestedPermission =
      geo.LocationPermission.whileInUse;
  Object? positionError;
  bool neverCompletePosition = false;
  int streamRequests = 0;
  int cancelCount = 0;
  void Function()? onCurrentPosition;
  final _stream = StreamController<geo.Position>.broadcast();
  final _serviceChanges = StreamController<bool>.broadcast();

  /// When set, every new position stream receives this sample right away.
  geo.Position Function()? autoEmit;
  int openedLocationSettings = 0;
  int openedAppSettings = 0;

  @override
  Future<geo.LocationPermission> checkPermission() async => permission;

  @override
  Future<geo.Position> currentPosition({
    required geo.LocationSettings settings,
  }) async {
    onCurrentPosition?.call();
    if (positionError case final error?) throw error;
    if (neverCompletePosition) return Completer<geo.Position>().future;
    return position();
  }

  geo.Position? lastKnown;

  @override
  Future<geo.Position?> lastKnownPosition() async => lastKnown;

  void emit(geo.Position value) => _stream.add(value);

  Future<void> close() async {
    await _stream.close();
    await _serviceChanges.close();
  }

  void setServiceEnabled(bool value) {
    serviceEnabled = value;
    _serviceChanges.add(value);
  }

  @override
  Stream<bool> serviceEnabledChanges() => _serviceChanges.stream;

  @override
  Future<bool> openLocationSettings() async {
    openedLocationSettings++;
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    openedAppSettings++;
    return true;
  }

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Stream<geo.Position> positionStream({
    required geo.LocationSettings settings,
  }) {
    streamRequests++;
    final build = autoEmit;
    if (build != null) {
      Timer(Duration.zero, () {
        if (!_stream.isClosed) _stream.add(build());
      });
    }
    return _stream.stream.doOnCancel(() => cancelCount++);
  }

  @override
  Future<geo.LocationPermission> requestPermission() async =>
      requestedPermission;
}

extension<T> on Stream<T> {
  Stream<T> doOnCancel(void Function() onCancel) => Stream<T>.multi((sink) {
    final subscription = listen(
      sink.add,
      onError: sink.addError,
      onDone: sink.close,
    );
    sink.onCancel = () async {
      onCancel();
      await subscription.cancel();
    };
  });
}

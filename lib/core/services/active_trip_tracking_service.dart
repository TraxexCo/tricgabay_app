import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import 'backend_repository.dart';
import 'consent_state.dart';
import 'location_gateway.dart';

enum TrackingHealth {
  stopped,
  starting,
  live,
  permissionRequired,
  locationDisabled,
  degraded,
}

enum FreshFixFailure { none, locationDisabled, permissionDenied, weakSignal }

/// Outcome of asking the device for a brand-new position.
class FreshFixResult {
  final geo.Position? position;
  final FreshFixFailure failure;
  const FreshFixResult._(this.position, this.failure);
  const FreshFixResult.ok(geo.Position position)
    : this._(position, FreshFixFailure.none);
  const FreshFixResult.failed(FreshFixFailure failure) : this._(null, failure);
  bool get ok => position != null;
}

/// Owns driver tracking independently from any screen so navigation or widget
/// disposal cannot silently stop an accepted/ongoing trip's location stream.
class ActiveTripTrackingService {
  ActiveTripTrackingService._();

  static final position = ValueNotifier<geo.Position?>(null);
  static final health = ValueNotifier<TrackingHealth>(TrackingHealth.stopped);
  static final lastPublishedAt = ValueNotifier<DateTime?>(null);
  static StreamSubscription<geo.Position>? _subscription;
  static String? _bookingId;
  static bool _starting = false;
  static LocationGateway _location = const GeolocatorLocationGateway();
  static Future<void> Function(geo.Position position) _publisher =
      _publishPosition;
  static bool _publisherOverridden = false;
  static Future<SharedPreferences> Function() _preferences =
      SharedPreferences.getInstance;
  static DateTime? _lastAcceptedAt;
  static const _recoveryKey = 'active_driver_tracking_booking_v1';

  /// A phone that sits still can go 30-50 s between fixes, which is longer
  /// than the server's 60 s freshness window allows for arrival. While a trip
  /// is active the service therefore asks for a fresh fix itself whenever the
  /// stream has been quiet.
  static const defaultHeartbeatInterval = Duration(seconds: 15);
  static const arrivalFixTimeout = Duration(seconds: 12);

  /// Server rule for arrival (unchanged): accuracy at most 100 m.
  static const arrivalMaxAccuracyMeters = 100.0;
  static const _arrivalMaxFixAge = Duration(seconds: 15);
  static Duration _heartbeatInterval = defaultHeartbeatInterval;
  static Duration _heartbeatFixTimeout = const Duration(seconds: 10);
  static Timer? _heartbeat;
  static bool _heartbeatBusy = false;

  static String? get bookingId => _bookingId;

  static geo.LocationSettings get _settings {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: geo.ForegroundNotificationConfig(
          notificationTitle: currentAppL10n.activeTripLocationTitle(
            AppBrand.name,
          ),
          notificationText:
              currentAppL10n.yourAssignedTouristCanSeeYourLiveLocation,
          enableWakeLock: true,
        ),
      );
    }
    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  static Future<void> start(String bookingId) async {
    if (_starting || (_bookingId == bookingId && _subscription != null)) return;
    _starting = true;
    health.value = TrackingHealth.starting;
    try {
      if (_bookingId != null && _bookingId != bookingId) {
        await _subscription?.cancel();
        _subscription = null;
        _bookingId = null;
      }
      if (!await _location.isServiceEnabled()) {
        health.value = TrackingHealth.locationDisabled;
        return;
      }
      var permission = await _location.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        // Never show the system prompt over the privacy notice.
        await ConsentState.whenClear();
        permission = await _location.requestPermission();
      }
      if (permission != geo.LocationPermission.always &&
          permission != geo.LocationPermission.whileInUse) {
        health.value = TrackingHealth.permissionRequired;
        return;
      }
      await _subscription?.cancel();
      _bookingId = bookingId;
      final prefs = await _preferences();
      await prefs.setString(_recoveryKey, bookingId);
      _subscription = _location
          .positionStream(settings: _settings)
          .listen(
            _handleSample,
            onError: (_) => health.value = TrackingHealth.degraded,
          );
      _startHeartbeat();
    } finally {
      _starting = false;
    }
  }

  static void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      _heartbeatInterval,
      (_) => unawaited(_heartbeatTick()),
    );
  }

  static Future<void> _heartbeatTick() async {
    if (_bookingId == null || _heartbeatBusy) return;
    final last = lastPublishedAt.value;
    final quietFor = last == null ? null : DateTime.now().difference(last);
    // The stream is delivering often enough; nothing to add.
    if (quietFor != null &&
        quietFor < _heartbeatInterval - const Duration(seconds: 2)) {
      return;
    }
    _heartbeatBusy = true;
    try {
      final result = await publishFreshFix(
        timeout: _heartbeatFixTimeout,
        maxAccuracyMeters: 200,
        maxFixAge: const Duration(seconds: 30),
      );
      if (result.ok) {
        health.value = TrackingHealth.live;
      } else {
        health.value = switch (result.failure) {
          FreshFixFailure.locationDisabled => TrackingHealth.locationDisabled,
          FreshFixFailure.permissionDenied => TrackingHealth.permissionRequired,
          _ => TrackingHealth.degraded,
        };
      }
    } catch (_) {
      health.value = TrackingHealth.degraded;
    } finally {
      _heartbeatBusy = false;
    }
  }

  /// Asks the device for a brand-new position and waits up to [timeout] for
  /// one that is recent and accurate enough. Never returns an old fix.
  static Future<FreshFixResult> acquireFreshFix({
    Duration timeout = arrivalFixTimeout,
    double maxAccuracyMeters = arrivalMaxAccuracyMeters,
    Duration maxFixAge = _arrivalMaxFixAge,
  }) async {
    if (!await _location.isServiceEnabled()) {
      return const FreshFixResult.failed(FreshFixFailure.locationDisabled);
    }
    final permission = await _location.checkPermission();
    if (permission != geo.LocationPermission.always &&
        permission != geo.LocationPermission.whileInUse) {
      return const FreshFixResult.failed(FreshFixFailure.permissionDenied);
    }
    try {
      final sample = await _location
          .positionStream(
            settings: const geo.LocationSettings(
              accuracy: geo.LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
            ),
          )
          .firstWhere(
            (candidate) =>
                isUsableLocationSample(candidate) &&
                candidate.accuracy <= maxAccuracyMeters &&
                DateTime.now().difference(candidate.timestamp) <= maxFixAge,
          )
          .timeout(timeout);
      return FreshFixResult.ok(sample);
    } catch (_) {
      return const FreshFixResult.failed(FreshFixFailure.weakSignal);
    }
  }

  /// Gets a fresh fix and publishes it before returning, so the server holds
  /// a current position when the caller's next request is checked against it.
  /// Throws if the fix was good but publishing failed.
  static Future<FreshFixResult> publishFreshFix({
    Duration timeout = arrivalFixTimeout,
    double maxAccuracyMeters = arrivalMaxAccuracyMeters,
    Duration maxFixAge = _arrivalMaxFixAge,
  }) async {
    final result = await acquireFreshFix(
      timeout: timeout,
      maxAccuracyMeters: maxAccuracyMeters,
      maxFixAge: maxFixAge,
    );
    final sample = result.position;
    if (sample == null) return result;
    if (BackendConfig.isConfigured || _publisherOverridden) {
      await _publisher(sample);
      lastPublishedAt.value = DateTime.now();
    }
    final previous = _lastAcceptedAt;
    if (previous == null || sample.timestamp.isAfter(previous)) {
      _lastAcceptedAt = sample.timestamp;
    }
    position.value = sample;
    return result;
  }

  static Future<String?> recoveryBookingId() async {
    final prefs = await _preferences();
    return prefs.getString(_recoveryKey);
  }

  static void _handleSample(geo.Position sample) {
    if (!isUsableLocationSample(sample, newerThan: _lastAcceptedAt)) return;
    _lastAcceptedAt = sample.timestamp;
    position.value = sample;
    health.value = TrackingHealth.live;
    if (!BackendConfig.isConfigured && !_publisherOverridden) {
      return;
    }
    unawaited(
      _publisher(sample)
          .then((_) {
            lastPublishedAt.value = DateTime.now();
          })
          .catchError((Object _) {
            health.value = TrackingHealth.degraded;
          }),
    );
  }

  static Future<void> _publishPosition(geo.Position sample) =>
      BackendRepository.publishLocation(
        latitude: sample.latitude,
        longitude: sample.longitude,
        accuracy: sample.accuracy,
        heading: sample.heading,
        speed: sample.speed,
        recordedAt: sample.timestamp,
        isMocked: sample.isMocked,
      );

  /// Applies only a server-confirmed active assignment. Cached booking state
  /// must never call this method during offline restoration.
  static Future<void> reconcileAuthoritativeBooking(String? bookingId) =>
      bookingId == null ? stop() : start(bookingId);

  static Future<void> stop() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _subscription?.cancel();
    _subscription = null;
    _bookingId = null;
    _lastAcceptedAt = null;
    position.value = null;
    health.value = TrackingHealth.stopped;
    final prefs = await _preferences();
    await prefs.remove(_recoveryKey);
  }

  @visibleForTesting
  static Future<void> configureForTesting({
    required LocationGateway location,
    required Future<void> Function(geo.Position position) publisher,
    Duration heartbeatInterval = defaultHeartbeatInterval,
    Duration heartbeatFixTimeout = const Duration(seconds: 10),
  }) async {
    await stop();
    _location = location;
    _publisher = publisher;
    _publisherOverridden = true;
    _heartbeatInterval = heartbeatInterval;
    _heartbeatFixTimeout = heartbeatFixTimeout;
  }

  @visibleForTesting
  static Future<void> resetAfterTesting() async {
    await stop();
    _location = const GeolocatorLocationGateway();
    _publisher = _publishPosition;
    _publisherOverridden = false;
    _preferences = SharedPreferences.getInstance;
    _heartbeatInterval = defaultHeartbeatInterval;
    _heartbeatFixTimeout = const Duration(seconds: 10);
    _heartbeatBusy = false;
    lastPublishedAt.value = null;
  }
}

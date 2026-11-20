import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import 'backend_repository.dart';
import 'location_gateway.dart';

enum TrackingHealth {
  stopped,
  starting,
  live,
  permissionRequired,
  locationDisabled,
  degraded,
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
    } finally {
      _starting = false;
    }
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
  }) async {
    await stop();
    _location = location;
    _publisher = publisher;
    _publisherOverridden = true;
  }

  @visibleForTesting
  static Future<void> resetAfterTesting() async {
    await stop();
    _location = const GeolocatorLocationGateway();
    _publisher = _publishPosition;
    _publisherOverridden = false;
    _preferences = SharedPreferences.getInstance;
    lastPublishedAt.value = null;
  }
}

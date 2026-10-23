import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import 'backend_repository.dart';

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
  static const _recoveryKey = 'active_driver_tracking_booking_v1';

  static String? get bookingId => _bookingId;

  static geo.LocationSettings get _settings {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationTitle: 'Tric-Gabay trip location active',
          notificationText: 'Your assigned tourist can see your live location',
          enableWakeLock: true,
        ),
      );
    }
    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
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
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        health.value = TrackingHealth.locationDisabled;
        return;
      }
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission != geo.LocationPermission.always &&
          permission != geo.LocationPermission.whileInUse) {
        health.value = TrackingHealth.permissionRequired;
        return;
      }
      await _subscription?.cancel();
      _bookingId = bookingId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recoveryKey, bookingId);
      _subscription =
          geo.Geolocator.getPositionStream(locationSettings: _settings).listen((
            sample,
          ) {
            position.value = sample;
            health.value = TrackingHealth.live;
            if (!BackendConfig.isConfigured) return;
            unawaited(
              BackendRepository.publishLocation(
                    latitude: sample.latitude,
                    longitude: sample.longitude,
                    accuracy: sample.accuracy,
                    heading: sample.heading,
                    speed: sample.speed,
                    recordedAt: sample.timestamp,
                  )
                  .then((_) {
                    lastPublishedAt.value = DateTime.now();
                  })
                  .catchError((Object _) {
                    health.value = TrackingHealth.degraded;
                  }),
            );
          }, onError: (_) => health.value = TrackingHealth.degraded);
    } finally {
      _starting = false;
    }
  }

  static Future<String?> recoveryBookingId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recoveryKey);
  }

  static Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _bookingId = null;
    position.value = null;
    health.value = TrackingHealth.stopped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recoveryKey);
  }
}

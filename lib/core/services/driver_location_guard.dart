import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

import 'active_trip_tracking_service.dart';
import 'consent_state.dart';
import 'location_gateway.dart';

enum LocationIssue {
  none,
  serviceOff,
  permissionDenied,
  permissionDeniedForever,
}

/// Watches the phone's location switch and the app's location permission
/// while a driver is online or on a trip. It tells the screens (a banner with
/// a settings button) and, once fixes work again, puts the driver back online
/// if they only went offline because the fixes stopped.
class DriverLocationGuard {
  DriverLocationGuard._();

  /// What the banner shows. [LocationIssue.none] unless a driver who should be
  /// sharing location has no usable location.
  static final issue = ValueNotifier<LocationIssue>(LocationIssue.none);

  /// Set for a few seconds after the driver was put back online automatically.
  static final restoredNotice = ValueNotifier<bool>(false);

  static const pollInterval = Duration(seconds: 5);
  static const _resumeKey = 'driver_resume_online_v1';

  static LocationGateway _location = const GeolocatorLocationGateway();
  static bool Function() _shouldShare = () => false;
  static bool Function() _isOnline = () => false;
  static Future<void> Function(bool online) _setOnline = (_) async {};
  static void Function(bool online) _onOnlineRestored = (_) {};
  static Future<SharedPreferences> Function() _preferences =
      SharedPreferences.getInstance;
  static Duration _interval = pollInterval;

  static StreamSubscription<bool>? _serviceSubscription;
  static Timer? _poll;
  static bool _evaluating = false;
  static bool _resumePending = false;
  static bool _loaded = false;
  static Timer? _noticeTimer;

  /// [shouldShare]: the signed-in account is a driver who is online or has an
  /// active trip. [isOnline]: the app's current view of the driver's online
  /// state. [setOnline]: writes availability to the server.
  static void start({
    required bool Function() shouldShare,
    required bool Function() isOnline,
    required Future<void> Function(bool online) setOnline,
    required void Function(bool online) onOnlineRestored,
    LocationGateway? location,
    Duration? interval,
  }) {
    stop();
    _shouldShare = shouldShare;
    _isOnline = isOnline;
    _setOnline = setOnline;
    _onOnlineRestored = onOnlineRestored;
    if (location != null) _location = location;
    if (interval != null) _interval = interval;
    try {
      _serviceSubscription = _location.serviceEnabledChanges().listen(
        (_) => unawaited(evaluate()),
        onError: (_) {},
      );
    } catch (_) {}
    _poll = Timer.periodic(_interval, (_) => unawaited(evaluate()));
    unawaited(evaluate());
  }

  static void stop() {
    _serviceSubscription?.cancel();
    _serviceSubscription = null;
    _poll?.cancel();
    _poll = null;
    _noticeTimer?.cancel();
    issue.value = LocationIssue.none;
    restoredNotice.value = false;
  }

  /// The driver turned themselves offline: never bring them back online.
  static Future<void> driverChoseOffline() async {
    _resumePending = false;
    final prefs = await _preferences();
    await prefs.remove(_resumeKey);
  }

  static Future<void> _remember(bool pending) async {
    _resumePending = pending;
    final prefs = await _preferences();
    if (pending) {
      await prefs.setBool(_resumeKey, true);
    } else {
      await prefs.remove(_resumeKey);
    }
  }

  /// Re-checks the location switch and permission. Called by a timer, by the
  /// service-status stream and when the app returns to the foreground.
  static Future<void> evaluate() async {
    if (_evaluating) return;
    _evaluating = true;
    try {
      if (!_loaded) {
        _loaded = true;
        final prefs = await _preferences();
        _resumePending = prefs.getBool(_resumeKey) ?? false;
      }
      final sharing = _shouldShare();
      if (!sharing && !_resumePending) {
        issue.value = LocationIssue.none;
        return;
      }
      final enabled = await _location.isServiceEnabled();
      final permission = await _location.checkPermission();
      final next = !enabled
          ? LocationIssue.serviceOff
          : permission == geo.LocationPermission.deniedForever
          ? LocationIssue.permissionDeniedForever
          : permission == geo.LocationPermission.denied
          ? LocationIssue.permissionDenied
          : LocationIssue.none;
      if (next != LocationIssue.none) {
        if (sharing && !_resumePending) await _remember(true);
        issue.value = next;
        return;
      }
      issue.value = LocationIssue.none;
      if (_resumePending) await _restoreOnline();
    } catch (_) {
      // A failed check changes nothing; the next poll tries again.
    } finally {
      _evaluating = false;
    }
  }

  static Future<void> _restoreOnline() async {
    if (ConsentState.blocked.value) return;
    // Wait for proof that fixes work again before touching availability.
    final fix = await ActiveTripTrackingService.publishFreshFix(
      timeout: const Duration(seconds: 10),
      maxAccuracyMeters: 200,
      maxFixAge: const Duration(seconds: 30),
    );
    if (!fix.ok) return;
    try {
      if (!_isOnline()) {
        await _setOnline(true);
        _onOnlineRestored(true);
        restoredNotice.value = true;
        _noticeTimer?.cancel();
        _noticeTimer = Timer(const Duration(seconds: 8), () {
          restoredNotice.value = false;
        });
      }
    } catch (_) {
      // The server refused (for example missing documents). The driver can go
      // online from the home screen; do not keep retrying every few seconds.
    }
    await _remember(false);
  }

  /// Opens the screen that fixes the current [issue].
  static Future<void> openSettingsForIssue() async {
    switch (issue.value) {
      case LocationIssue.serviceOff:
        await _location.openLocationSettings();
      case LocationIssue.permissionDenied:
      case LocationIssue.permissionDeniedForever:
        await _location.openAppSettings();
      case LocationIssue.none:
        break;
    }
  }

  @visibleForTesting
  static Future<void> resetAfterTesting() async {
    stop();
    _location = const GeolocatorLocationGateway();
    _shouldShare = () => false;
    _isOnline = () => false;
    _setOnline = (_) async {};
    _onOnlineRestored = (_) {};
    _preferences = SharedPreferences.getInstance;
    _interval = pollInterval;
    _resumePending = false;
    _loaded = false;
    _evaluating = false;
  }

  @visibleForTesting
  static void usePreferencesForTesting(
    Future<SharedPreferences> Function() preferences,
  ) {
    _preferences = preferences;
  }
}

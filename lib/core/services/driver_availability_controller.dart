import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;

import 'consent_state.dart';
import 'location_gateway.dart';

enum DriverAvailabilityFailure {
  none,
  locationDisabled,
  permissionDenied,
  permissionDeniedForever,
  positionUnavailable,
  serverRejected,
  disposed,
}

class DriverAvailabilityResult {
  final bool success;
  final DriverAvailabilityFailure failure;
  final String? message;

  const DriverAvailabilityResult._(this.success, this.failure, [this.message]);

  const DriverAvailabilityResult.success()
    : this._(true, DriverAvailabilityFailure.none);

  const DriverAvailabilityResult.failure(
    DriverAvailabilityFailure failure,
    String message,
  ) : this._(false, failure, message);
}

typedef DriverOnlineWriter = Future<void> Function(bool online);
typedef DriverPositionPublisher = Future<void> Function(geo.Position position);
typedef DriverPositionObserver = void Function(geo.Position position);

/// Serializes the driver's online transition with its GPS prerequisites.
/// Financial/trip actions are deliberately outside this controller.
class DriverAvailabilityController {
  final LocationGateway location;
  final DriverOnlineWriter writeOnline;
  final DriverPositionPublisher publish;
  final DriverPositionObserver onPosition;
  final geo.LocationSettings currentSettings;
  final geo.LocationSettings streamSettings;
  final Duration positionTimeout;

  StreamSubscription<geo.Position>? _subscription;
  Future<DriverAvailabilityResult>? _transition;
  DateTime? _lastAcceptedAt;
  bool _disposed = false;

  DriverAvailabilityController({
    required this.location,
    required this.writeOnline,
    required this.publish,
    required this.onPosition,
    required this.currentSettings,
    required this.streamSettings,
    this.positionTimeout = const Duration(seconds: 8),
  });

  bool get isBusy => _transition != null;
  bool get isSharing => _subscription != null;

  Future<DriverAvailabilityResult> setOnline(bool online) {
    final pending = _transition;
    if (pending != null) return pending;
    final operation = _safeTransition(online);
    _transition = operation;
    operation.whenComplete(() {
      if (identical(_transition, operation)) _transition = null;
    });
    return operation;
  }

  Future<DriverAvailabilityResult> _safeTransition(bool online) async {
    try {
      return await (online ? _goOnline() : _goOffline());
    } catch (_) {
      await _cancelStream();
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.positionUnavailable,
        MessageCode.locationIsUnavailableRightNowCheckYourSettingsAndTryAgain,
      );
    }
  }

  Future<DriverAvailabilityResult> resumeSharing() async {
    if (_disposed) {
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.disposed,
        MessageCode.locationSharingIsNoLongerAvailableOnThisScreen,
      );
    }
    return _prepareLocation(writeAvailability: false);
  }

  Future<DriverAvailabilityResult> _goOnline() =>
      _prepareLocation(writeAvailability: true);

  Future<DriverAvailabilityResult> _prepareLocation({
    required bool writeAvailability,
  }) async {
    if (_disposed) {
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.disposed,
        MessageCode.locationSharingIsNoLongerAvailableOnThisScreen,
      );
    }
    if (!await location.isServiceEnabled()) {
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.locationDisabled,
        MessageCode.turnOnGpsToShareYourLocation,
      );
    }
    var permission = await location.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      await ConsentState.whenClear();
      permission = await location.requestPermission();
    }
    if (permission == geo.LocationPermission.deniedForever) {
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.permissionDeniedForever,
        MessageCode.allowLocationAccessInAndroidSettings,
      );
    }
    if (permission != geo.LocationPermission.always &&
        permission != geo.LocationPermission.whileInUse) {
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.permissionDenied,
        MessageCode.locationPermissionIsNeededToReceiveRides,
      );
    }

    // A precise GPS fix can take long indoors. Try it briefly, then use a
    // recent fix the phone already has, then a Wi-Fi/cell based fix.
    geo.Position? position;
    try {
      position = await location
          .currentPosition(settings: currentSettings)
          .timeout(positionTimeout);
    } catch (_) {}
    if (position == null || !isUsableLocationSample(position)) {
      try {
        final last = await location.lastKnownPosition();
        if (last != null && isUsableLocationSample(last)) position = last;
      } catch (_) {}
    }
    if (position == null) {
      try {
        position = await location
            .currentPosition(
              settings: const geo.LocationSettings(
                accuracy: geo.LocationAccuracy.medium,
              ),
            )
            .timeout(positionTimeout);
      } catch (_) {}
    }
    if (position == null) {
      await _cancelStream();
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.positionUnavailable,
        MessageCode.couldNotGetACurrentGpsPositionCheckYourSignalAndTryAgain,
      );
    }
    if (!isUsableLocationSample(position)) {
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.positionUnavailable,
        MessageCode.theGpsPositionIsStaleOrInvalidWaitForAFreshSignalAnd,
      );
    }

    var markedOnline = false;
    try {
      if (writeAvailability) {
        await writeOnline(true);
        markedOnline = true;
      }
      if (_disposed) {
        if (writeAvailability) await writeOnline(false);
        return const DriverAvailabilityResult.failure(
          DriverAvailabilityFailure.disposed,
          MessageCode.locationSharingWasCancelled,
        );
      }
      await _accept(position);
      await _cancelStream();
      _subscription = location
          .positionStream(settings: streamSettings)
          .listen(_handleSample, onError: (_) {});
      return const DriverAvailabilityResult.success();
    } catch (error) {
      await _cancelStream();
      if (markedOnline) {
        try {
          await writeOnline(false);
        } catch (_) {
          // The UI refreshes authoritative state after reporting this failure.
        }
      }
      // The server refuses drivers whose documents are missing, expired or
      // unverified; say so instead of a generic failure.
      if (error.toString().contains('Cannot go online')) {
        return const DriverAvailabilityResult.failure(
          DriverAvailabilityFailure.serverRejected,
          MessageCode.driverDocumentsBlockOnline,
        );
      }
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.serverRejected,
        MessageCode.couldNotGoOnlineYourAvailabilityWasNotChanged,
      );
    }
  }

  Future<void> _handleSample(geo.Position position) async {
    if (_disposed ||
        !isUsableLocationSample(position, newerThan: _lastAcceptedAt)) {
      return;
    }
    try {
      await _accept(position);
    } catch (_) {
      // Keep listening: a later sample can recover after a transient failure.
    }
  }

  Future<void> _accept(geo.Position position) async {
    await publish(position);
    if (_disposed) return;
    _lastAcceptedAt = position.timestamp;
    onPosition(position);
  }

  Future<DriverAvailabilityResult> _goOffline() async {
    if (_disposed) {
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.disposed,
        MessageCode.locationSharingIsAlreadyStopped,
      );
    }
    try {
      await writeOnline(false);
    } catch (_) {
      return const DriverAvailabilityResult.failure(
        DriverAvailabilityFailure.serverRejected,
        MessageCode
            .couldNotGoOfflineLocationSharingRemainsActiveUntilTheServerConfirmsIt,
      );
    }
    await _cancelStream();
    return const DriverAvailabilityResult.success();
  }

  Future<void> _cancelStream() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _cancelStream();
  }
}

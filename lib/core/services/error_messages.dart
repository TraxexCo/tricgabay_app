import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'telemetry_service.dart';
import 'trip_rules.dart';

class ErrorMessages {
  ErrorMessages._();

  /// Phone-test builds (config/phone-test.json sets SHOW_ERROR_DETAILS)
  /// name the underlying error so a tester's screenshot shows the cause.
  /// Every other build, including release, keeps plain messages that never
  /// echo server details.
  static const showDetails =
      !kReleaseMode && bool.fromEnvironment('SHOW_ERROR_DETAILS');
  static String forError(Object error) {
    unawaited(TelemetryService.recordNonFatal(error, StackTrace.current));
    if (error is ClientOperationException) {
      return switch (error.failure) {
        ClientFailure.routeUnavailable =>
          MessageCode.roadRouteUnavailableCheckYourConnectionAndTryAgain,
        ClientFailure.pendingBooking =>
          MessageCode
              .aPreviousBookingRequestIsAwaitingConfirmationReconnectAndOpenTripsBeforeChanging,
      };
    }
    if (error is FormatException && error.message.startsWith('@l10n/')) {
      return error.message;
    }
    if (error is StateError && error.message.startsWith('@l10n/')) {
      return error.message;
    }
    if (error is TripRuleException) return error.message;
    if (error is SocketException || error is TimeoutException) {
      return MessageCode
          .connectionUnavailableCheckYourInternetConnectionAndTryAgain;
    }
    if (error is AuthException) {
      return MessageCode
          .accountAccessCouldNotBeCompletedCheckYourDetailsAndTryAgain;
    }
    if (error is PostgrestException) {
      if (error.message.contains('A cancellation reason is required')) {
        return MessageCode.writeAtLeast5Characters;
      }
      if (error.message.contains('Booking cannot be cancelled')) {
        return MessageCode.thisTripCanNoLongerBeCancelled;
      }
      if (error.message.contains('Completed tourist booking required')) {
        return MessageCode.youCanRateTheDriverAfterTheTripIsCompleted;
      }
      if (error.code == '23505' && error.message.contains('booking_reviews')) {
        return MessageCode.youAlreadyRatedThisTrip;
      }
      if (error.message.contains('Export request limit reached')) {
        return MessageCode.youCanRequestUpTo3ExportsADay;
      }
      // Tour package editor (admin).
      if (error.message.contains('Another package already uses this name')) {
        return MessageCode.anotherPackageAlreadyUsesThisName;
      }
      if (error.message.contains('This package no longer exists')) {
        return MessageCode.thisPackageNoLongerExists;
      }
      if (error.message.contains('Every stop must be an active tourist spot')) {
        return MessageCode.everyStopMustBeAnActiveTouristSpot;
      }
      if (error.message.contains('OUTSTANDING_FARE')) {
        return MessageCode.outstandingFareBlocked;
      }
      if (error.message.contains('GCASH_REFERENCE_USED')) {
        return MessageCode.gcashReferenceUsed;
      }
      if (error.message.contains('GCASH_PROOF_REQUIRED')) {
        return MessageCode.gcashProofRequired;
      }
      if (error.message.contains('ONLINE_PAYMENT_UNAVAILABLE')) {
        return MessageCode.onlinePaymentUnavailable;
      }
      if (error.code == '42501') {
        return MessageCode
            .yourAccountCannotPerformThisActionRefreshYourAccountOrContactSupport;
      }
      if (error.code == '23505') {
        return MessageCode
            .thisRequestAlreadyExistsRefreshYourTripsBeforeTryingAgain;
      }
      if (error.message.contains('outside the service area')) {
        return MessageCode
            .thePickupPinIsOutsideTheServiceAreaChooseAnotherPickupPoint;
      }
      // Trip-step refusals: say what to do instead of a generic failure.
      if (error.message.contains('within 150 meters of the pickup')) {
        return MessageCode.moveWithin150mOfPickup;
      }
      if (error.message.contains('GPS accuracy is too low')) {
        return MessageCode.gpsAccuracyTooLow;
      }
      if (error.message.contains('fresh driver location is required')) {
        return MessageCode.theGpsPositionIsStaleOrInvalidWaitForAFreshSignalAnd;
      }
      if (error.message.contains('Cannot go online')) {
        return MessageCode.driverDocumentsBlockOnline;
      }
      if (error.message.contains('Wait before requesting')) {
        return MessageCode
            .pleaseWaitFiveMinutesBeforeRequestingAnotherPickupCode;
      }
      if (error.message.contains('temporarily locked')) {
        return MessageCode
            .pickupVerificationIsTemporarilyLockedPleaseWaitAndTryAgain;
      }
    }
    // Test builds name the underlying error so a tester's screenshot shows
    // the real cause; release builds keep the plain message.
    if (showDetails) {
      return MessageCode.actionFailedWithDetailValue(detailFor(error));
    }
    return MessageCode
        .thisActionCouldNotBeCompletedYourExistingRecordsArePreservedRefreshAnd;
  }

  /// Short technical description of an error, for test builds only.
  static String detailFor(Object error) {
    final text = error is PostgrestException
        ? '${error.code ?? ''} ${error.message}'
        : '${error.runtimeType}: $error';
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length > 160 ? '${clean.substring(0, 160)}…' : clean;
  }
}

enum ClientFailure { routeUnavailable, pendingBooking }

class ClientOperationException implements Exception {
  final ClientFailure failure;
  const ClientOperationException(this.failure);
}

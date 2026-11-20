import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'telemetry_service.dart';
import 'trip_rules.dart';

class ErrorMessages {
  ErrorMessages._();
  static String forError(Object error) {
    unawaited(TelemetryService.recordNonFatal(error, StackTrace.current));
    if (error is ClientOperationException) {
      return switch (error.failure) {
        ClientFailure.routeUnavailable =>
          MessageCode.roadRouteUnavailableCheckYourConnectionAndTryAgain,
        ClientFailure.checkoutLaunch =>
          MessageCode.couldNotOpenCheckoutResumePaymentFromThisBooking,
        ClientFailure.checkoutUntrusted =>
          MessageCode
              .theCheckoutAddressCouldNotBeVerifiedRefreshThisBookingBeforePaying,
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
      if (error.message.contains('Wait before requesting')) {
        return MessageCode
            .pleaseWaitFiveMinutesBeforeRequestingAnotherPickupCode;
      }
      if (error.message.contains('temporarily locked')) {
        return MessageCode
            .pickupVerificationIsTemporarilyLockedPleaseWaitAndTryAgain;
      }
    }
    return MessageCode
        .thisActionCouldNotBeCompletedYourExistingRecordsArePreservedRefreshAnd;
  }
}

enum ClientFailure {
  routeUnavailable,
  checkoutLaunch,
  checkoutUntrusted,
  pendingBooking,
}

class ClientOperationException implements Exception {
  final ClientFailure failure;
  const ClientOperationException(this.failure);
}

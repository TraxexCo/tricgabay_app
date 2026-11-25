import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tricgabay_app/core/l10n/message_codes.g.dart';

/// Why an emailed-code step (verify, resend, request a reset) failed.
enum EmailCodeFailure { wrongOrExpired, rateLimited, network, other }

/// A 6-digit emailed code, trimmed. Null when it is not exactly six digits.
String? normalizeEmailCode(String? value) {
  final code = (value ?? '').replaceAll(RegExp(r'\s'), '');
  return RegExp(r'^\d{6}$').hasMatch(code) ? code : null;
}

/// Sorts an error from Supabase Auth (or the network) into what the user can
/// act on. Supabase answers a wrong code and an expired code with the same
/// error ("Token has expired or is invalid"), so they share one failure.
EmailCodeFailure emailCodeFailureFor(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is AuthRetryableFetchException) {
    return EmailCodeFailure.network;
  }
  if (error is AuthException) {
    final code = (error.code ?? '').toLowerCase();
    final message = error.message.toLowerCase();
    if (error.statusCode == '429' ||
        code.contains('rate_limit') ||
        message.contains('rate limit') ||
        message.contains('security purposes')) {
      return EmailCodeFailure.rateLimited;
    }
    if (code == 'otp_expired' ||
        code == 'otp_invalid' ||
        message.contains('expired') ||
        message.contains('invalid')) {
      return EmailCodeFailure.wrongOrExpired;
    }
  }
  return EmailCodeFailure.other;
}

/// The message to show for [failure].
String emailCodeMessage(EmailCodeFailure failure) => switch (failure) {
  EmailCodeFailure.wrongOrExpired => MessageCode.codeWrongOrExpired,
  EmailCodeFailure.rateLimited => MessageCode.codeRateLimited,
  EmailCodeFailure.network =>
    MessageCode.connectionUnavailableCheckYourInternetConnectionAndTryAgain,
  EmailCodeFailure.other =>
    MessageCode.accountAccessCouldNotBeCompletedCheckYourDetailsAndTryAgain,
};

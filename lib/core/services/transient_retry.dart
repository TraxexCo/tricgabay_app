import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True for failures that usually clear on their own: a dropped or slow
/// connection, a gateway hiccup, or a session token that was refreshed
/// while the request was in flight.
bool isTransientFailure(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException ||
      error is HandshakeException ||
      error is AuthRetryableFetchException) {
    return true;
  }
  if (error is PostgrestException) {
    final code = error.code ?? '';
    return code.startsWith('5') ||
        code == 'PGRST301' ||
        error.message.contains('JWT expired');
  }
  return false;
}

/// Runs [operation]; when it fails with a transient error it waits and tries
/// again, once per entry of [delays]. Each try is cut off after [timeout] so
/// a stalled request cannot hold the launch screen forever. The last error is
/// rethrown, and every failure is logged so a phone test shows the real cause.
Future<T> retryTransient<T>(
  Future<T> Function() operation, {
  required String label,
  List<Duration> delays = const [
    Duration(milliseconds: 600),
    Duration(milliseconds: 1500),
  ],
  Duration timeout = const Duration(seconds: 10),
  bool Function(Object error) isTransient = isTransientFailure,
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await operation().timeout(timeout);
    } catch (error) {
      debugPrint(
        '$label failed (try ${attempt + 1}): ${error.runtimeType}: $error',
      );
      if (attempt >= delays.length || !isTransient(error)) rethrow;
      await Future<void>.delayed(delays[attempt]);
    }
  }
}

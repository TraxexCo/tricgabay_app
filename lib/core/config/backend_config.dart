import 'package:supabase_flutter/supabase_flutter.dart';

/// Public client configuration supplied at build time.
///
/// Never put the PayMongo secret key here. It belongs in Supabase secrets and
/// is only read by Edge Functions.
class BackendConfig {
  BackendConfig._();

  static bool _initialized = false;

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xcsrjuqzwequmeqzedzd.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'REDACTED',
  );

  static bool get hasConfiguration =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;

  /// Whether the client is configured and has completed initialization.
  ///
  /// Keeping this distinct from [hasConfiguration] prevents unit tests and
  /// other pre-startup code from trying to use `Supabase.instance` merely
  /// because build-time defaults are present.
  static bool get isConfigured => hasConfiguration && _initialized;

  static Future<void> initialize() async {
    if (!hasConfiguration) return;
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client {
    if (!isConfigured) {
      throw const BackendUnavailableException(
        'The server is not configured on this build. Add the Supabase URL and publishable key, then rebuild the app.',
      );
    }
    return Supabase.instance.client;
  }
}

class BackendUnavailableException implements Exception {
  final String message;
  const BackendUnavailableException(this.message);
  @override
  String toString() => message;
}

import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'build_environment.dart';

/// Public client configuration supplied at build time.
///
/// Never put the PayMongo secret key here. It belongs in Supabase secrets and
/// is only read by Edge Functions.
class BackendConfig {
  BackendConfig._();

  static bool _initialized = false;

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get hasConfiguration =>
      (supabaseUrl.startsWith('https://') ||
          (BuildEnvironment.isDevelopment && _isLocalHttp(supabaseUrl))) &&
      supabasePublishableKey.isNotEmpty;

  static bool _isLocalHttp(String value) {
    final uri = Uri.tryParse(value);
    return uri?.scheme == 'http' &&
        const ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri?.host);
  }

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
        MessageCode.theServerIsNotConfiguredOnThisBuildAddTheSupabaseUrlAnd,
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

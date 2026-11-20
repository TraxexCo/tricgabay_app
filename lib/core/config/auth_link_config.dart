import 'package:tricgabay_app/core/l10n/message_codes.g.dart';

class AuthLinkConfig {
  static const host = String.fromEnvironment('AUTH_APP_LINK_HOST');
  static Uri resetUri([String configuredHost = host]) {
    final normalized = configuredHost.trim().toLowerCase();
    if (!RegExp(
          r'^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\.[a-z]{2,}$',
        ).hasMatch(normalized) ||
        normalized.contains('..') ||
        normalized.endsWith('.invalid')) {
      throw StateError(MessageCode.authResetConfigurationRequired);
    }
    return Uri(scheme: 'https', host: normalized, path: '/auth/reset-password');
  }
}

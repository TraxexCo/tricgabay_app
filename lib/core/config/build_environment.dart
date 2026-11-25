import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'package:flutter/foundation.dart';

class BuildEnvironment {
  static const name = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static bool get isDevelopment => name == 'dev';

  static void validate({
    required Map<String, String> values,
    bool release = kReleaseMode,
  }) {
    if (!const ['dev', 'staging', 'production'].contains(name)) {
      throw StateError(MessageCode.unknownApplicationEnvironment);
    }
    if (!release) return;
    final missing = values.entries
        .where((entry) => entry.value.trim().isEmpty)
        .map((entry) => entry.key);
    if (missing.isNotEmpty) {
      throw StateError(
        MessageCode.releaseConfigurationIsIncompleteValue(
          (missing.join(', ')).toString(),
        ),
      );
    }
  }
}

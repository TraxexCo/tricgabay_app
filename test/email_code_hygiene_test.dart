import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the things that must stay true of the emailed-code flows.
void main() {
  final flowFiles = [
    'lib/core/services/email_code_auth.dart',
    'lib/core/services/email_code_errors.dart',
    'lib/features/auth/screens/verify_email_code_screen.dart',
    'lib/features/auth/screens/forgot_password_screen.dart',
    'lib/features/auth/screens/reset_password_screen.dart',
    'lib/features/auth/widgets/email_code_widgets.dart',
  ];

  test('the code flows write nothing to logs', () {
    final logging = RegExp(r'\b(print|debugPrint|log|developer\.log)\s*\(');
    for (final path in flowFiles) {
      expect(
        logging.hasMatch(File(path).readAsStringSync()),
        isFalse,
        reason: '$path logs',
      );
    }
    // The AuthService methods that handle codes and passwords do not log either.
    final service = File(
      'lib/core/services/auth_service.dart',
    ).readAsStringSync();
    expect(logging.hasMatch(service), isFalse);
  });

  test('no auth link domain is needed any more', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, isNot(contains('autoVerify')));
    expect(manifest, isNot(contains('authAppLinkHost')));
    expect(manifest, isNot(contains('/auth/reset-password')));

    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, isNot(contains('AUTH_APP_LINK_HOST')));
    expect(gradle, isNot(contains('authAppLinkHost')));
    expect(gradle, isNot(contains('unconfigured.invalid')));

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      expect(text, isNot(contains('AUTH_APP_LINK_HOST')), reason: entity.path);
      expect(text, isNot(contains('AuthLinkConfig')), reason: entity.path);
    }
    expect(File('lib/core/config/auth_link_config.dart').existsSync(), isFalse);
  });

  test('reset and sign-up requests carry no redirect link', () {
    final service = File(
      'lib/core/services/auth_service.dart',
    ).readAsStringSync();
    expect(service, isNot(contains('redirectTo')));
    expect(service, isNot(contains('emailRedirectTo')));
    expect(service, contains('OtpType.signup'));
    expect(service, contains('OtpType.recovery'));
  });
}

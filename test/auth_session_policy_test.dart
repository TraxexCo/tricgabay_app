import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/auth_session_policy.dart';

void main() {
  test('active tourist enters only the tourist portal', () {
    expect(
      evaluateAuthAccess(
        role: 'tourist',
        status: 'active',
        expectedRole: 'tourist',
      ).allowed,
      isTrue,
    );
    final mismatch = evaluateAuthAccess(
      role: 'tourist',
      status: 'active',
      expectedRole: 'driver',
    );
    expect(mismatch.allowed, isFalse);
    expect(mismatch.message, startsWith('@l10n/'));
    expect(
      resolveMessage(AppLocalizationsEn(), mismatch.message!).toLowerCase(),
      contains('tourist portal'),
    );
  });

  test('administrators sign in from the shared screen', () {
    // The tourist/driver toggle doesn't apply to admins.
    for (final portal in ['tourist', 'driver']) {
      expect(
        evaluateAuthAccess(
          role: 'admin',
          status: 'active',
          expectedRole: portal,
        ).allowed,
        isTrue,
      );
    }
    expect(
      evaluateAuthAccess(
        role: 'admin',
        status: 'suspended',
        expectedRole: 'tourist',
      ).allowed,
      isFalse,
    );
    expect(
      evaluateAuthAccess(
        role: 'driver',
        status: 'active',
        expectedRole: 'tourist',
        driverApproval: 'approved',
      ).allowed,
      isFalse,
    );
  });

  test('invalid, suspended, and revoked identities fail closed', () {
    expect(
      evaluateAuthAccess(role: 'unknown', status: 'active').allowed,
      isFalse,
    );
    expect(
      evaluateAuthAccess(role: 'tourist', status: 'suspended').allowed,
      isFalse,
    );
    expect(
      evaluateAuthAccess(role: 'driver', status: 'revoked').allowed,
      isFalse,
    );
  });

  test(
    'driver operational access requires approval; pending access is restricted',
    () {
      expect(
        evaluateAuthAccess(role: 'driver', status: 'active').applicationPending,
        isTrue,
      );
      expect(
        evaluateAuthAccess(
          role: 'driver',
          status: 'active',
          driverApproval: 'suspended',
        ).allowed,
        isFalse,
      );
      final approved = evaluateAuthAccess(
        role: 'driver',
        status: 'active',
        driverApproval: 'approved',
      );
      expect(approved.allowed, isTrue);
      expect(approved.applicationPending, isFalse);
      final pending = evaluateAuthAccess(
        role: 'driver',
        status: 'pending',
        driverApproval: 'pending',
      );
      expect(pending.allowed, isTrue);
      expect(pending.applicationPending, isTrue);
    },
  );

  test('password recovery requires a live provider session', () {
    expect(evaluatePasswordRecoverySession(false).allowed, isFalse);
    expect(evaluatePasswordRecoverySession(true).allowed, isTrue);
  });
}

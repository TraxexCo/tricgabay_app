import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/session_termination_coordinator.dart';

void main() {
  test('cache erasure failure still attempts remote revocation', () async {
    var revoked = false;
    await SessionTerminationCoordinator(
      clearLocal: () async => throw StateError('cache I/O failed'),
      remoteSignOut: () async {
        revoked = true;
      },
    ).terminate();
    expect(revoked, isTrue);
  });
  test('protected local state is cleared before remote sign-out', () async {
    final events = <String>[];
    await SessionTerminationCoordinator(
      clearLocal: () async => events.add('local-cleared'),
      remoteSignOut: () async => events.add('remote-signout'),
    ).terminate();
    expect(events, ['local-cleared', 'remote-signout']);
  });

  test(
    'remote sign-out failure cannot restore protected local state',
    () async {
      var protectedState = 'account-a';
      await SessionTerminationCoordinator(
        clearLocal: () async => protectedState = '',
        remoteSignOut: () async => throw StateError('provider unavailable'),
      ).terminate();
      expect(protectedState, isEmpty);
    },
  );
}

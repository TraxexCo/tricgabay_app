import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/core/services/auth_service.dart';
import 'package:tricgabay_app/core/services/session_termination_coordinator.dart';

SignedInProfile driver({String id = 'driver-a', bool pending = false}) =>
    SignedInProfile(
      id: id,
      name: 'Test Driver',
      email: 'driver@example.test',
      role: AppRole.driver,
      status: pending ? 'pending' : 'active',
      applicationPending: pending,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSession.clearAuthenticatedUser();
  });
  tearDown(() async {
    AppSession.clearAuthenticatedUser();
    await Future<void>.delayed(Duration.zero);
  });
  test(
    'pending approval promotes to driver and clears old role-scoped state',
    () async {
      AppSession.setAuthenticatedUser(
        id: 'driver-a',
        name: 'Test',
        role: 'driver_pending',
        email: 'driver@example.test',
      );
      AppSession.adminCapabilities.value = {'super_admin'};
      expect(
        await AppSession.refreshAccountAccess(load: () async => driver()),
        isFalse,
      );
      expect(AppSession.authenticatedRole, 'driver');
      expect(AppSession.adminCapabilities.value, isEmpty);
      expect(
        await AppSession.refreshAccountAccess(load: () async => driver()),
        isTrue,
      );
    },
  );
  test(
    'approval revoked to pending removes operational role without signing out',
    () async {
      AppSession.setAuthenticatedUser(
        id: 'driver-a',
        name: 'Test',
        role: 'driver',
        email: 'driver@example.test',
      );
      AppSession.isDriverOnline.value = true;
      expect(
        await AppSession.refreshAccountAccess(
          load: () async => driver(pending: true),
        ),
        isFalse,
      );
      expect(AppSession.authenticatedUserId, 'driver-a');
      expect(AppSession.authenticatedRole, 'driver_pending');
      expect(AppSession.isDriverOnline.value, isFalse);
      expect(
        await AppSession.refreshAccountAccess(
          load: () async => driver(pending: true),
        ),
        isFalse,
      );
    },
  );
  test(
    'late approval result from account A cannot overwrite account B',
    () async {
      AppSession.setAuthenticatedUser(
        id: 'driver-a',
        name: 'A',
        role: 'driver_pending',
        email: 'a@example.test',
      );
      final pending = Completer<SignedInProfile?>();
      final refresh = AppSession.refreshAccountAccess(
        load: () => pending.future,
      );
      AppSession.setAuthenticatedUser(
        id: 'driver-b',
        name: 'B',
        role: 'driver_pending',
        email: 'b@example.test',
      );
      pending.complete(driver());
      expect(await refresh, isFalse);
      expect(AppSession.authenticatedUserId, 'driver-b');
      expect(AppSession.authenticatedRole, 'driver_pending');
    },
  );
  test(
    'sign-out clears local access before a stalled disconnection and still starts auth sign-out',
    () async {
      var visibleAccount = 'account-a';
      var authSignOutStarted = false;
      final network = Completer<void>();
      final result = SessionTerminationCoordinator(
        clearLocal: () async {
          visibleAccount = '';
        },
        disconnect: () => network.future,
        remoteSignOut: () async {
          authSignOutStarted = true;
        },
      ).terminate();
      await Future<void>.delayed(Duration.zero);
      expect(visibleAccount, isEmpty);
      expect(authSignOutStarted, isTrue);
      network.complete();
      await result;
    },
  );
  test('failed disconnection cannot prevent auth sign-out', () async {
    var signedOut = false;
    await SessionTerminationCoordinator(
      clearLocal: () async {},
      disconnect: () async => throw StateError('offline'),
      remoteSignOut: () async {
        signedOut = true;
      },
    ).terminate();
    expect(signedOut, isTrue);
  });
  test(
    'clearing an account disables its optional diagnostics preference',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('telemetry_consent_v1', true);
      AppSession.clearAuthenticatedUser();
      await Future<void>.delayed(Duration.zero);
      expect(prefs.getBool('telemetry_consent_v1'), isFalse);
    },
  );
}

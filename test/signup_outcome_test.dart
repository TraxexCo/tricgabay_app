import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tricgabay_app/core/constants/app_routes.dart';
import 'package:tricgabay_app/core/services/auth_service.dart';
import 'package:tricgabay_app/features/auth/post_auth_route.dart';

User _user() => const User(
  id: '00000000-0000-4000-8000-000000000001',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-11-26T00:00:00Z',
);

Session _session() =>
    Session(accessToken: 'token', tokenType: 'bearer', user: _user());

SignedInProfile _profile(AppRole role, {bool pending = false}) =>
    SignedInProfile(
      id: 'id',
      name: 'Name',
      email: 'a@example.test',
      role: role,
      status: 'active',
      applicationPending: pending,
    );

void main() {
  tearDown(() => AuthService.signUpOverride = null);

  group('sign-up outcome', () {
    test('a session means the account is signed in', () {
      expect(signUpOutcomeFor(_session()), SignUpOutcome.signedIn);
    });

    test('no session means the email must be confirmed', () {
      expect(signUpOutcomeFor(null), SignUpOutcome.awaitingEmailConfirmation);
    });
  });

  group('tourist sign-up', () {
    Future<SignUpOutcome> register() => AuthService.registerTourist(
      privacyVersion: 'v1',
      privacyLanguage: 'en',
      name: ' Demo Tourist ',
      email: ' demo@example.test ',
      phone: '09171234567',
      password: 'a-throwaway-password',
    );

    test(
      'Confirm email off: the server returns a session, so sign in',
      () async {
        Map<String, dynamic>? sentData;
        String? sentEmail;
        AuthService.signUpOverride =
            ({required email, required password, required data}) async {
              sentEmail = email;
              sentData = data;
              return AuthResponse(session: _session(), user: _user());
            };
        expect(await register(), SignUpOutcome.signedIn);
        expect(sentEmail, 'demo@example.test');
        expect(sentData!['requested_role'], 'tourist');
        expect(sentData!['full_name'], 'Demo Tourist');
        expect(sentData!['privacy_notice_version'], 'v1');
      },
    );

    test('Confirm email on: the user comes back with no session', () async {
      AuthService.signUpOverride =
          ({required email, required password, required data}) async =>
              AuthResponse(user: _user());
      expect(await register(), SignUpOutcome.awaitingEmailConfirmation);
    });

    test('a server error is not turned into an outcome', () async {
      AuthService.signUpOverride =
          ({required email, required password, required data}) async =>
              throw const AuthException('User already registered');
      expect(register(), throwsA(isA<AuthException>()));
    });

    test('the privacy notice is still required', () async {
      AuthService.signUpOverride =
          ({required email, required password, required data}) async =>
              fail('must not reach the server without a privacy version');
      expect(
        AuthService.registerTourist(
          privacyVersion: ' ',
          privacyLanguage: 'en',
          name: 'N',
          email: 'a@example.test',
          phone: '09171234567',
          password: 'x',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('where a signed-in profile lands', () {
    test('a tourist goes to the tourist home', () {
      expect(routeForProfile(_profile(AppRole.tourist)), '/tourist/home');
    });

    test('a driver with an approved account goes to the driver home', () {
      expect(routeForProfile(_profile(AppRole.driver)), '/driver/home');
    });

    test('a driver with an application in review waits for approval', () {
      expect(
        routeForProfile(_profile(AppRole.driver, pending: true)),
        '/driver/application-pending',
      );
    });

    test('an admin goes to the dashboard', () {
      expect(
        routeForProfile(_profile(AppRole.admin)),
        AppRoutes.adminDashboard,
      );
    });
  });
}

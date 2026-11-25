import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tricgabay_app/core/services/email_code_auth.dart';
import 'package:tricgabay_app/features/auth/screens/forgot_password_screen.dart';
import 'package:tricgabay_app/features/auth/screens/reset_password_screen.dart';
import 'package:tricgabay_app/features/auth/screens/verify_email_code_screen.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';

const _wrongOrExpired = AuthException(
  'Token has expired or is invalid',
  statusCode: '403',
  code: 'otp_expired',
);
const _rateLimited = AuthException(
  'email rate limit exceeded',
  statusCode: '429',
  code: 'over_email_send_rate_limit',
);

/// Records every call and fails the ones the test asks to fail. The codes and
/// passwords here are made-up test values.
class FakeEmailCodeAuth extends EmailCodeAuth {
  Object? verifySignUpError;
  Object? resendError;
  Object? requestError;
  Object? verifyRecoveryError;
  Object? updateError;
  final calls = <String>[];

  int count(String name) => calls.where((c) => c.startsWith(name)).length;

  @override
  Future<void> verifySignUpCode(String email, String code) async {
    calls.add('verifySignUp:$email:$code');
    if (verifySignUpError != null) throw verifySignUpError!;
  }

  @override
  Future<void> resendSignUpCode(String email) async {
    calls.add('resendSignUp:$email');
    if (resendError != null) throw resendError!;
  }

  @override
  Future<void> requestPasswordResetCode(String email) async {
    calls.add('requestReset:$email');
    if (requestError != null) throw requestError!;
  }

  @override
  Future<void> verifyRecoveryCode(String email, String code) async {
    calls.add('verifyRecovery:$email:$code');
    if (verifyRecoveryError != null) throw verifyRecoveryError!;
  }

  @override
  Future<void> updateRecoveredPassword(String password) async {
    calls.add('updatePassword');
    if (updateError != null) throw updateError!;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> show(WidgetTester tester, GoRouter router) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder codeField() => find.widgetWithText(TextFormField, '6-digit code');
  Finder button(String label) => find.widgetWithText(ElevatedButton, label);
  Finder resendButton() => find.ancestor(
    of: find.textContaining('Resend code'),
    matching: find.byType(TextButton),
  );

  // A home page that opens the sign-up code screen and shows what it returned.
  GoRouter verifyRouter(
    FakeEmailCodeAuth auth, {
    Duration cooldown = const Duration(seconds: 60),
    bool codeJustSent = true,
  }) => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: Column(
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: _result,
                  builder: (_, value, _) => Text('result: $value'),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await context.push<bool>(
                      '/verify',
                      extra: VerifyEmailArgs(
                        'tourist@example.test',
                        codeJustSent: codeJustSent,
                      ),
                    );
                    _result.value = '$result';
                  },
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => VerifyEmailCodeScreen(
          args: state.extra! as VerifyEmailArgs,
          auth: auth,
          resendCooldown: cooldown,
        ),
      ),
    ],
  );

  Future<void> openVerify(WidgetTester tester, GoRouter router) async {
    _result.value = 'none';
    await show(tester, router);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('sign-up code screen', () {
    testWidgets('shows who the code was sent to and has what is needed', (
      tester,
    ) async {
      await openVerify(tester, verifyRouter(FakeEmailCodeAuth()));
      expect(
        find.text('Enter the 6-digit code we emailed you'),
        findsOneWidget,
      );
      expect(
        find.text('We sent a code to tourist@example.test.'),
        findsOneWidget,
      );
      expect(find.text('Never share this code with anyone.'), findsOneWidget);
      expect(codeField(), findsOneWidget);
      expect(find.text('Back to sign in'), findsOneWidget);
    });

    testWidgets('a right code signs in and returns true', (tester) async {
      final auth = FakeEmailCodeAuth();
      await openVerify(tester, verifyRouter(auth));
      await tester.enterText(codeField(), '123456');
      await tester.tap(button('Verify'));
      await tester.pumpAndSettle();
      expect(auth.calls, contains('verifySignUp:tourist@example.test:123456'));
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('a wrong or expired code says so and stays', (tester) async {
      final auth = FakeEmailCodeAuth()..verifySignUpError = _wrongOrExpired;
      await openVerify(tester, verifyRouter(auth));
      await tester.enterText(codeField(), '000000');
      await tester.tap(button('Verify'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'That code is wrong or has expired. Check it, or ask for a new one.',
        ),
        findsOneWidget,
      );
      expect(codeField(), findsOneWidget);
      // The user can try again with the right code.
      auth.verifySignUpError = null;
      await tester.enterText(codeField(), '654321');
      await tester.tap(button('Verify'));
      await tester.pumpAndSettle();
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('a rate-limited verify says to wait', (tester) async {
      final auth = FakeEmailCodeAuth()..verifySignUpError = _rateLimited;
      await openVerify(tester, verifyRouter(auth));
      await tester.enterText(codeField(), '123456');
      await tester.tap(button('Verify'));
      await tester.pumpAndSettle();
      expect(
        find.text('Too many tries. Wait a few minutes, then try again.'),
        findsOneWidget,
      );
    });

    testWidgets('fewer than six digits never reaches the server', (
      tester,
    ) async {
      final auth = FakeEmailCodeAuth();
      await openVerify(tester, verifyRouter(auth));
      await tester.enterText(codeField(), '123');
      await tester.tap(button('Verify'));
      await tester.pumpAndSettle();
      expect(find.text('Enter all 6 digits.'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('the box takes digits only, six at most', (tester) async {
      await openVerify(tester, verifyRouter(FakeEmailCodeAuth()));
      await tester.enterText(codeField(), '12ab34-56789');
      final field = tester.widget<TextField>(
        find.descendant(of: codeField(), matching: find.byType(TextField)),
      );
      expect(field.controller!.text, '123456');
    });

    testWidgets('resend waits out a cooldown, then sends and waits again', (
      tester,
    ) async {
      final auth = FakeEmailCodeAuth();
      await openVerify(
        tester,
        verifyRouter(auth, cooldown: const Duration(seconds: 3)),
      );
      expect(find.text('Resend code in 3s'), findsOneWidget);
      expect(tester.widget<TextButton>(resendButton()).onPressed, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend code in 2s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Resend code'), findsOneWidget);
      expect(tester.widget<TextButton>(resendButton()).onPressed, isNotNull);

      await tester.tap(resendButton());
      await tester.pump();
      await tester.pump();
      expect(auth.calls, ['resendSignUp:tourist@example.test']);
      expect(find.text('A new code is on its way.'), findsOneWidget);
      expect(find.text('Resend code in 3s'), findsOneWidget);
    });

    testWidgets('resend is waiting for a full minute by default', (
      tester,
    ) async {
      await openVerify(tester, verifyRouter(FakeEmailCodeAuth()));
      expect(find.text('Resend code in 60s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 59));
      expect(find.text('Resend code in 1s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend code'), findsOneWidget);
    });

    testWidgets('arriving from login, resend is ready straight away', (
      tester,
    ) async {
      await openVerify(
        tester,
        verifyRouter(FakeEmailCodeAuth(), codeJustSent: false),
      );
      expect(find.text('Resend code'), findsOneWidget);
      expect(tester.widget<TextButton>(resendButton()).onPressed, isNotNull);
    });

    testWidgets('a rate-limited resend shows it and starts the wait again', (
      tester,
    ) async {
      final auth = FakeEmailCodeAuth()..resendError = _rateLimited;
      await openVerify(
        tester,
        verifyRouter(
          auth,
          cooldown: const Duration(seconds: 5),
          codeJustSent: false,
        ),
      );
      await tester.tap(resendButton());
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Too many tries. Wait a few minutes, then try again.'),
        findsOneWidget,
      );
      expect(find.text('Resend code in 5s'), findsOneWidget);
    });

    testWidgets('back to sign in returns false', (tester) async {
      await openVerify(tester, verifyRouter(FakeEmailCodeAuth()));
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.text('result: false'), findsOneWidget);
    });

    testWidgets('the code box is labelled and the buttons are easy to hit', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openVerify(
        tester,
        verifyRouter(FakeEmailCodeAuth(), codeJustSent: false),
      );
      expect(find.bySemanticsLabel('6-digit code'), findsWidgets);
      for (final target in [button('Verify'), resendButton()]) {
        expect(
          tester.getSize(target).height,
          greaterThanOrEqualTo(48),
          reason: '$target',
        );
      }
      expect(tester.getSize(codeField()).height, greaterThanOrEqualTo(48));
      semantics.dispose();
    });

    testWidgets('survives large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openVerify(tester, verifyRouter(FakeEmailCodeAuth()));
      expect(tester.takeException(), isNull);
      expect(button('Verify'), findsOneWidget);
    });
  });

  group('forgot password', () {
    GoRouter forgotRouter(FakeEmailCodeAuth auth) => GoRouter(
      initialLocation: '/forgot',
      routes: [
        GoRoute(
          path: '/forgot',
          builder: (context, _) =>
              ForgotPasswordScreen(auth: auth, skipConfigurationCheck: true),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) =>
              Scaffold(body: Text('reset page for ${state.extra}')),
        ),
      ],
    );

    Future<void> submit(WidgetTester tester, String email) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        email,
      );
      await tester.tap(button('Send code'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for a code and opens the reset page', (tester) async {
      final auth = FakeEmailCodeAuth();
      await show(tester, forgotRouter(auth));
      await submit(tester, 'tourist@example.test');
      expect(auth.calls, ['requestReset:tourist@example.test']);
      expect(find.text('reset page for tourist@example.test'), findsOneWidget);
    });

    testWidgets('an unknown email looks exactly the same', (tester) async {
      // Supabase answers success; and an error that would only occur for a real
      // account (such as the email sender failing) is not shown either.
      for (final error in <Object?>[
        null,
        const AuthException('Error sending recovery email', statusCode: '500'),
        const AuthException('User not found', statusCode: '404'),
      ]) {
        final auth = FakeEmailCodeAuth()..requestError = error;
        await show(tester, forgotRouter(auth));
        await submit(tester, 'nobody@example.test');
        expect(
          find.text('reset page for nobody@example.test'),
          findsOneWidget,
          reason: '$error',
        );
      }
    });

    testWidgets('a rate limit is shown and stays on the page', (tester) async {
      final auth = FakeEmailCodeAuth()..requestError = _rateLimited;
      await show(tester, forgotRouter(auth));
      await submit(tester, 'tourist@example.test');
      expect(
        find.text('Too many tries. Wait a few minutes, then try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('reset page for'), findsNothing);
    });

    testWidgets('a bad email is stopped before anything is sent', (
      tester,
    ) async {
      final auth = FakeEmailCodeAuth();
      await show(tester, forgotRouter(auth));
      await submit(tester, 'not-an-email');
      expect(auth.calls, isEmpty);
      expect(find.textContaining('reset page for'), findsNothing);
    });
  });

  group('reset password', () {
    GoRouter resetRouter(
      FakeEmailCodeAuth auth, {
      Duration cooldown = const Duration(seconds: 60),
    }) => GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: '/reset',
          builder: (context, _) => ResetPasswordScreen(
            email: 'tourist@example.test',
            auth: auth,
            resendCooldown: cooldown,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, _) => const Scaffold(body: Text('login page')),
        ),
      ],
    );

    Future<void> fill(
      WidgetTester tester, {
      String code = '123456',
      String password = 'Newpass1234',
      String? confirm,
    }) async {
      await tester.enterText(codeField(), code);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        password,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        confirm ?? password,
      );
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(button('Update password'));
      await tester.tap(button('Update password'));
      await tester.pumpAndSettle();
    }

    testWidgets('says where the code went without confirming the account', (
      tester,
    ) async {
      await show(tester, resetRouter(FakeEmailCodeAuth()));
      expect(
        find.text(
          'If an account exists for tourist@example.test, we sent a 6-digit code to it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a right code and a good password change it and go to login', (
      tester,
    ) async {
      final auth = FakeEmailCodeAuth();
      await show(tester, resetRouter(auth));
      await fill(tester);
      await save(tester);
      expect(auth.calls, [
        'verifyRecovery:tourist@example.test:123456',
        'updatePassword',
      ]);
      expect(find.text('login page'), findsOneWidget);
    });

    testWidgets('a wrong or expired code stops before any password change', (
      tester,
    ) async {
      final auth = FakeEmailCodeAuth()..verifyRecoveryError = _wrongOrExpired;
      await show(tester, resetRouter(auth));
      await fill(tester, code: '000000');
      await save(tester);
      expect(
        find.text(
          'That code is wrong or has expired. Check it, or ask for a new one.',
        ),
        findsOneWidget,
      );
      expect(auth.calls, ['verifyRecovery:tourist@example.test:000000']);
      expect(find.text('login page'), findsNothing);
    });

    testWidgets('the app password rules apply', (tester) async {
      final auth = FakeEmailCodeAuth();
      await show(tester, resetRouter(auth));
      // No capital letter or number.
      await fill(tester, password: 'alllowercase');
      await save(tester);
      expect(auth.calls, isEmpty);
      expect(find.textContaining('uppercase'), findsOneWidget);
    });

    testWidgets('the two passwords must match', (tester) async {
      final auth = FakeEmailCodeAuth();
      await show(tester, resetRouter(auth));
      await fill(tester, password: 'Newpass1234', confirm: 'Newpass1235');
      await save(tester);
      expect(auth.calls, isEmpty);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('fewer than six digits is stopped', (tester) async {
      final auth = FakeEmailCodeAuth();
      await show(tester, resetRouter(auth));
      await fill(tester, code: '12');
      await save(tester);
      expect(auth.calls, isEmpty);
      expect(find.text('Enter all 6 digits.'), findsWidgets);
    });

    testWidgets(
      'if the password change fails, trying again does not need a new code',
      (tester) async {
        final auth = FakeEmailCodeAuth()
          ..updateError = const AuthException('Password is too weak');
        await show(tester, resetRouter(auth));
        await fill(tester);
        await save(tester);
        expect(find.text('login page'), findsNothing);
        auth.updateError = null;
        await save(tester);
        expect(auth.count('verifyRecovery'), 1);
        expect(auth.count('updatePassword'), 2);
        expect(find.text('login page'), findsOneWidget);
      },
    );

    testWidgets('resending the code uses the same private response', (
      tester,
    ) async {
      final auth = FakeEmailCodeAuth()
        ..requestError = const AuthException('Error sending recovery email');
      await show(
        tester,
        resetRouter(auth, cooldown: const Duration(seconds: 2)),
      );
      expect(find.text('Resend code in 2s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.ensureVisible(resendButton());
      await tester.tap(resendButton());
      await tester.pump();
      await tester.pump();
      expect(auth.calls, ['requestReset:tourist@example.test']);
    });
  });
}

final _result = ValueNotifier<String>('none');

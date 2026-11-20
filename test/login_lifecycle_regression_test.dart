import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/app.dart';
import 'package:tricgabay_app/core/prototype/prototype_session.dart';
import 'package:tricgabay_app/core/services/privacy_service.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'package:tricgabay_app/core/widgets/minimum_version_gate.dart';
import 'package:tricgabay_app/core/widgets/privacy_consent_gate.dart';
import 'package:tricgabay_app/features/auth/screens/login_screen.dart';
import 'quality/fake_http.dart';
import 'quality/screen_fixtures.dart';

const notice = PrivacyNotice(
  'test-v1',
  'Test privacy notice.',
  'Paunawa sa pagkapribado.',
);
typedef VersionResult = ({VersionPolicy policy, int build});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    HttpOverrides.global = FixtureHttp();
    MapSurface.testBuilder = (_) => const ColoredBox(color: Colors.white);
    PrototypeSession.authenticatedUserId = null;
    PrototypeSession.authenticatedRole = null;
    for (final channel in [
      'flutter.baseflow.com/geolocator',
      'flutter.baseflow.com/geolocator_android',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel(channel),
            (call) async =>
                call.method == 'isLocationServiceEnabled' ? false : 1,
          );
    }
  });
  tearDown(() {
    HttpOverrides.global = null;
    MapSurface.testBuilder = null;
    PrototypeSession.authenticatedUserId = null;
    PrototypeSession.authenticatedRole = null;
  });

  testWidgets(
    'switching to Notes and returning preserves both login fields through both delayed gates',
    (tester) async {
      Completer<VersionResult>? versionRefresh;
      Completer<PrivacyState?>? privacyRefresh;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MinimumVersionGate(
              loader: () =>
                  versionRefresh?.future ??
                  Future.value((policy: const VersionPolicy(1, ''), build: 3)),
              child: PrivacyConsentGate(
                loader: () => privacyRefresh?.future ?? Future.value(null),
                child: const LoginScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'tourist@example.test');
      await tester.enterText(fields.at(1), 'sample-password');
      final emailController = tester
          .widget<TextFormField>(fields.at(0))
          .controller!;
      final passwordController = tester
          .widget<TextFormField>(fields.at(1))
          .controller!;
      for (var cycle = 0; cycle < 3; cycle++) {
        versionRefresh = Completer<VersionResult>();
        privacyRefresh = Completer<PrivacyState?>();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(fields, findsNothing);
        versionRefresh.complete((policy: const VersionPolicy(1, ''), build: 3));
        privacyRefresh.complete(null);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextFormField>(fields.at(0)).controller,
          same(emailController),
        );
        expect(
          tester.widget<TextFormField>(fields.at(1)).controller,
          same(passwordController),
        );
        expect(emailController.text, 'tourist@example.test');
        expect(passwordController.text, 'sample-password');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final entry in {
    'tourist': '/tourist/home',
    'driver': '/driver/home',
    'admin': '/admin/dashboard',
    'driver_pending': '/driver/application-pending',
  }.entries) {
    testWidgets(
      '${entry.key} session routes to its landing page while privacy overlays the router',
      (tester) async {
        var signedIn = false;
        var accepted = false;
        appRouter.go('/login');
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: appRouter,
              builder: (context, child) => PrivacyConsentGate(
                loader: () async =>
                    signedIn ? PrivacyState(notice, accepted) : null,
                record: (_) async {
                  accepted = true;
                },
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(appRouter.routeInformationProvider.value.uri.path, '/login');
        seedScreen(entry.key == 'driver_pending' ? 'driver' : entry.key, '');
        signedIn = true;
        PrototypeSession.authenticatedRole = entry.key;
        PrototypeSession.authRevision.value++;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(appRouter.routeInformationProvider.value.uri.path, entry.value);
        expect(find.text('Privacy notice'), findsOneWidget);
        expect(find.text('Privacy update'), findsNothing);
        await tester.ensureVisible(
          find.text('I have read and accept this notice.'),
        );
        await tester.tap(find.text('I have read and accept this notice.'));
        await tester.pump();
        await tester.ensureVisible(find.text('Accept and continue'));
        await tester.tap(find.text('Accept and continue'));
        await tester.pumpAndSettle();
        expect(accepted, isTrue);
        expect(find.text('Privacy notice'), findsNothing);
        expect(appRouter.routeInformationProvider.value.uri.path, entry.value);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}

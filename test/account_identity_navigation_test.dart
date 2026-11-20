import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/app.dart';
import 'package:tricgabay_app/core/constants/app_routes.dart';
import 'package:tricgabay_app/core/prototype/prototype_session.dart';
import 'package:tricgabay_app/core/services/auth_service.dart';
import 'package:tricgabay_app/core/theme/app_theme.dart';
import 'package:tricgabay_app/core/widgets/account_widgets.dart';
import 'package:tricgabay_app/core/widgets/shared_widgets.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';
import 'package:tricgabay_app/models/tourist_spot_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    PrototypeSession.clearAuthenticatedUser();
  });
  tearDown(PrototypeSession.clearAuthenticatedUser);

  void signInDriver() {
    PrototypeSession.setAuthenticatedUser(
      id: 'driver-account',
      name: 'Test Driver',
      role: 'driver',
      email: 'driver-account@example.test',
    );
  }

  Future<void> openDriverAccount(WidgetTester tester) async {
    signInDriver();
    appRouter.go(AppRoutes.driverProfile);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'identity card updates the name and email together when accounts change',
    (tester) async {
      PrototypeSession.setAuthenticatedUser(
        id: 'tourist-account',
        name: 'Test Tourist',
        role: 'tourist',
        email: 'tourist-account@example.test',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AccountIdentityCard(roleLabel: 'Account')),
        ),
      );
      expect(find.text('Test Tourist'), findsOneWidget);
      expect(find.text('tourist-account@example.test'), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);

      signInDriver();
      await tester.pump();
      expect(find.text('Test Tourist'), findsNothing);
      expect(find.text('tourist-account@example.test'), findsNothing);
      expect(find.text('Test Driver'), findsOneWidget);
      expect(find.text('driver-account@example.test'), findsOneWidget);

      await PrototypeSession.refreshAccountAccess(
        load: () async => const SignedInProfile(
          id: 'driver-account',
          name: 'Updated Driver',
          email: 'updated@example.test',
          role: AppRole.driver,
          status: 'active',
        ),
      );
      await tester.pump();
      expect(find.text('Updated Driver'), findsOneWidget);
      expect(find.text('updated@example.test'), findsOneWidget);

      PrototypeSession.clearAuthenticatedUser();
      await tester.pump();
      expect(find.text('updated@example.test'), findsNothing);
    },
  );

  testWidgets(
    'driver support opens under the driver role and Back returns to Account',
    (tester) async {
      await openDriverAccount(tester);
      final support = find.text('Help & support');
      await tester.scrollUntilVisible(support, 180);
      await tester.tap(support);
      await tester.pumpAndSettle();
      expect(find.text('Submit feedback'), findsWidgets);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(
        appRouter.routeInformationProvider.value.uri.path,
        AppRoutes.driverProfile,
      );
      expect(find.text('Driver account'), findsOneWidget);
    },
  );

  testWidgets('Back from the Jobs tab opened from Account returns to Account', (
    tester,
  ) async {
    await openDriverAccount(tester);
    await tester.tap(find.text('Trip history'));
    await tester.pumpAndSettle();
    expect(
      appRouter.routeInformationProvider.value.uri.path,
      AppRoutes.driverBookings,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      appRouter.routeInformationProvider.value.uri.path,
      AppRoutes.driverProfile,
    );
    expect(find.text('Driver account'), findsOneWidget);
  });

  test('published package rows use server text and ordered stops', () {
    final package = TourPackageModel.fromPublishedRow({
      'id': 'tric-lakbay',
      'name': 'Published package name',
      'description': 'Published package description',
      'tour_package_stops': [
        {'spot_id': 'second', 'stop_order': 2},
        {'spot_id': 'first', 'stop_order': 1},
      ],
    });
    expect(package.name, 'Published package name');
    expect(package.description, 'Published package description');
    expect(package.spotIds, ['first', 'second']);
    expect(package.highlights, isEmpty);
  });
}

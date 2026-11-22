// Renders every registered screen ON THE PHONE (real fonts, density and
// text rendering) with the same sample data as the desktop snapshots, and
// saves a screenshot of each. Run with scripts/phone_screens.cmd, or:
//   flutter drive --driver=test_driver/integration_test.dart
//     --target=integration_test/screens_on_device_test.dart
//     --flavor production --dart-define=APP_ENV=production
// Output: build/phone_screens/<ScreenName>.png
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/core/theme/app_theme.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';

import '../test/quality/fake_http.dart';
import '../test/quality/screen_fixtures.dart';
import '../test/quality/screen_registry.dart';

const screenFilter = String.fromEnvironment('QUALITY_SCREEN');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en_PH');
    // Sample data only: no backend, no real accounts, nothing saved on the
    // phone. Network images resolve to a placeholder; the map is a plain
    // panel because sample screens have no live map tiles.
    HttpOverrides.global = FixtureHttp();
    MapSurface.testBuilder = (_) => const ColoredBox(color: Color(0xffe8eef7));
    SharedPreferences.setMockInitialValues({});
  });

  for (final screen in screenCases.where(
    (s) => screenFilter.isEmpty || s.name.contains(screenFilter),
  )) {
    testWidgets(screen.name, (tester) async {
      Intl.defaultLocale = 'en_PH';
      seedScreen(screen.role, screen.name);
      AppSession.isFilipino.value = false;
      final router = fixtureRouter(screen);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: AppTheme.lightTheme,
          ),
        ),
      );
      // Let entrance animations finish and images decode.
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Android needs this before every screenshot; the test framework
      // switches it back off when each test ends.
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 100));
      await binding.takeScreenshot(screen.name);
      while (tester.takeException() != null) {}
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

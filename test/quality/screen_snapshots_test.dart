// Renders every registered screen to a PNG with real fonts and icons, for
// visual review. Skipped unless requested:
//   flutter test test/quality/screen_snapshots_test.dart --update-goldens --dart-define=SNAPSHOTS=true
// Optional: --dart-define=QUALITY_SCREEN=Login to render a subset.
// Output: build/screens/<ScreenName>.png
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/core/theme/app_theme.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';

import 'fake_http.dart';
import 'screen_fixtures.dart';
import 'screen_registry.dart';

const enabled = bool.fromEnvironment('SNAPSHOTS');
const screenFilter = String.fromEnvironment('QUALITY_SCREEN');

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final path in files) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    if (!enabled) return;
    await initializeDateFormatting('en_PH');
    GoogleFonts.config.allowRuntimeFetching = false;
    HttpOverrides.global = FixtureHttp();
    MapSurface.testBuilder = (_) => const ColoredBox(color: Color(0xffe8eef7));
    SharedPreferences.setMockInitialValues({});
    final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
    final icons =
        '${sdk.path}/artifacts/material_fonts/MaterialIcons-Regular.otf';
    await _loadFont('MaterialIcons', [icons]);
    for (final (weight, file) in [
      ('regular', 'Regular'),
      ('500', 'Medium'),
      ('600', 'SemiBold'),
      ('700', 'Bold'),
      ('800', 'ExtraBold'),
    ]) {
      await _loadFont('Poppins_$weight', [
        'assets/google_fonts/Poppins-$file.ttf',
      ]);
    }
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  for (final screen in screenCases.where(
    (s) => screenFilter.isEmpty || s.name.contains(screenFilter),
  )) {
    testWidgets(
      'snapshot ${screen.name}',
      skip: !enabled,
      timeout: const Timeout(Duration(seconds: 90)),
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Intl.defaultLocale = 'en_PH';
        seedScreen(screen.role, screen.name);
        AppSession.isFilipino.value = false;
        final boundary = GlobalKey();
        final router = fixtureRouter(screen);
        addTearDown(router.dispose);
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ProviderScope(
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                locale: const Locale('en'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: AppTheme.lightTheme,
              ),
            ),
          ),
        );
        // Let entrance animations finish and images decode.
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate()) {
            final image = (element.widget as Image).image;
            await precacheImage(image, element);
          }
        });
        await tester.pump(const Duration(milliseconds: 100));
        await expectLater(
          find.byKey(boundary),
          matchesGoldenFile('../../build/screens/${screen.name}.png'),
        );
        while (tester.takeException() != null) {}
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

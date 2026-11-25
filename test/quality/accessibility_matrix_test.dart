import 'package:tricgabay_app/core/l10n/feedback_category.dart';
import 'scroll_fixture.dart';
import 'package:intl/intl.dart';
import 'package:tricgabay_app/core/widgets/responsive_app_frame.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';
import 'package:tricgabay_app/core/theme/app_theme.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'package:tricgabay_app/core/widgets/app_text_field.dart';
import 'screen_registry.dart';
import 'screen_fixtures.dart';
import 'fake_http.dart';

const recordOnly = bool.fromEnvironment('QUALITY_RECORD_ONLY');
const reportPath = String.fromEnvironment(
  'QUALITY_REPORT',
  defaultValue: '.audit-output/batch6a/accessibility.json',
);
const names = {
  'TouristShellScreen',
  'DriverShellScreen',
  'AdminShellScreen',
  'LoginScreen',
  'RegisterTouristScreen',
  'RegisterDriverScreen',
  'TouristHomeScreen',
  'FareSummaryScreen',
  'BookingDetailScreen',
  'TouristProfileScreen',
  'DriverHomeScreen',
  'ActiveTripScreen',
  'DriverProfileScreen',
  'AdminDashboardScreen',
  'FareSettingsScreen',
  'SendAnnouncementScreen',
  'FeedbackScreen',
};
void main() {
  final results = <Map<String, Object?>>[];
  setUpAll(() async {
    await initializeDateFormatting('en_PH');
    await initializeDateFormatting('fil_PH');
    GoogleFonts.config.allowRuntimeFetching = false;
    HttpOverrides.global = FixtureHttp();
    MapSurface.testBuilder = (_) => const ColoredBox(color: Color(0xffe8eef7));
    SharedPreferences.setMockInitialValues({});
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
  tearDownAll(() async {
    final file = File(reportPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'cases': results.length,
        'guideline_failures': results.where((r) => r['passed'] == false).length,
        'results': results,
      }),
    );
    HttpOverrides.global = null;
    MapSurface.testBuilder = null;
  });
  for (final screen in screenCases.where((s) => names.contains(s.name))) {
    for (final scale in [1.0, 2.0]) {
      for (final locale in ['en', 'fil']) {
        testWidgets('${screen.name} accessibility text=$scale $locale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          Intl.defaultLocale = locale == 'fil' ? 'fil_PH' : 'en_PH';
          seedScreen(screen.role, screen.name);
          final errors = <String>[];
          final handler = FlutterError.onError;
          FlutterError.onError = (details) => errors.add(details.toString());
          final router = fixtureRouter(screen);
          try {
            await tester.pumpWidget(
              ProviderScope(
                child: MaterialApp.router(
                  routerConfig: router,
                  locale: Locale(locale),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: AppTheme.lightTheme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                    ),
                    child: ResponsiveAppFrame(child: child!),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 250));
            FlutterError.onError = handler;
            for (final viewport in ['top', 'end']) {
              if (viewport == 'end') {
                FlutterError.onError = (details) =>
                    errors.add(details.toString());
                await revealFixtureEnd(tester);
                if (screen.name == 'RegisterTouristScreen' ||
                    screen.name == 'FeedbackScreen' ||
                    screen.name == 'SendAnnouncementScreen') {
                  // Keep the first visible field whole at the footer sample.
                  // Flutter can report a clipped editable/suffix as a small
                  // target even though the full control meets the guideline.
                  final viewport = tester.getRect(
                    find.byType(SingleChildScrollView).first,
                  );
                  for (final field
                      in find
                          .byWidgetPredicate(
                            (w) =>
                                w is AppTextField ||
                                w is ChoiceChip ||
                                w.key is ValueKey<FeedbackCategory> ||
                                w is DropdownButtonFormField,
                          )
                          .evaluate()) {
                    final finder = find.byElementPredicate((e) => e == field);
                    final rect = tester.getRect(finder);
                    if (rect.top < viewport.top && rect.bottom > viewport.top) {
                      final position = Scrollable.of(field).position;
                      position.jumpTo(
                        (position.pixels - (viewport.top - rect.top) - 4).clamp(
                          position.minScrollExtent,
                          position.maxScrollExtent,
                        ),
                      );
                      await tester.pump();
                      break;
                    }
                  }
                }
                FlutterError.onError = handler;
              }
              for (final entry in {
                'androidTapTarget': androidTapTargetGuideline,
                'labeledTapTarget': labeledTapTargetGuideline,
                'textContrast': textContrastGuideline,
              }.entries) {
                final result = await entry.value.evaluate(tester);
                results.add({
                  'screen': screen.name,
                  'viewport': viewport,
                  'scale': scale,
                  'locale': locale,
                  'guideline': entry.key,
                  'passed': result.passed,
                  'reason': result.reason,
                  'render_errors': errors,
                });
                if (!recordOnly) {
                  await expectLater(tester, meetsGuideline(entry.value));
                }
              }
            }
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            router.dispose();
            FlutterError.onError = handler;
            semantics.dispose();
          }
          if (!recordOnly) expect(errors, isEmpty);
        });
      }
    }
  }
}

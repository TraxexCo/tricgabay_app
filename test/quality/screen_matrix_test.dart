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
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'screen_registry.dart';
import 'screen_fixtures.dart';
import 'fake_http.dart';

const recordOnly = bool.fromEnvironment('QUALITY_RECORD_ONLY');
const reportPath = String.fromEnvironment(
  'QUALITY_REPORT',
  defaultValue: '.audit-output/batch6a/layout.json',
);
const screenFilter = String.fromEnvironment('QUALITY_SCREEN');
const sizes = [
  Size(320, 568),
  Size(360, 640),
  Size(412, 915),
  Size(600, 960),
  Size(960, 600),
  Size(568, 320),
];
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });
  tearDownAll(() async {
    final file = File(reportPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'cases': results.length,
        'failed_cases': results
            .where((r) => (r['errors'] as List).isNotEmpty)
            .length,
        'overflow_cases': results
            .where(
              (r) => (r['errors'] as List).any(
                (e) => e.toString().contains('overflowed'),
              ),
            )
            .length,
        'results': results,
      }),
    );
    HttpOverrides.global = null;
    MapSurface.testBuilder = null;
  });
  for (final screen in screenCases.where(
    (s) => screenFilter.isEmpty || s.name.contains(screenFilter),
  )) {
    for (final size in sizes) {
      for (final scale in [1.0, 1.5, 2.0]) {
        for (final locale in ['en', 'fil']) {
          testWidgets(
            '${screen.name} ${size.width}x${size.height} text=$scale $locale',
            (tester) async {
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              Intl.defaultLocale = locale == 'fil' ? 'fil_PH' : 'en_PH';
              seedScreen(screen.role, screen.name);
              AppSession.isFilipino.value = locale == 'fil';
              final errors = <String>[];
              final oldHandler = FlutterError.onError;
              FlutterError.onError = (details) {
                errors.add(details.toString());
              };
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
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(scale)),
                        child: ResponsiveAppFrame(child: child!),
                      ),
                    ),
                  ),
                );
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 250));
                void checkVisibleMessages() {
                  for (final text in tester.widgetList<Text>(
                    find.byType(Text),
                  )) {
                    final value =
                        text.data ?? text.textSpan?.toPlainText() ?? '';
                    if (value.contains('@l10n/')) {
                      errors.add('UNRESOLVED_MESSAGE_CODE: $value');
                    }
                  }
                }

                checkVisibleMessages();
                await revealFixtureEnd(tester);
                checkVisibleMessages();
                Object? exception;
                while ((exception = tester.takeException()) != null) {
                  errors.add(exception.toString());
                }
                await tester.pumpWidget(const SizedBox.shrink());
                await tester.pump();
              } catch (error) {
                errors.add(error.toString());
              } finally {
                FlutterError.onError = oldHandler;
                router.dispose();
              }
              results.add({
                'screen': screen.name,
                'width': size.width,
                'height': size.height,
                'scale': scale,
                'locale': locale,
                'errors': errors,
              });
              if (!recordOnly) {
                expect(
                  errors,
                  isEmpty,
                  reason: '${screen.name}: ${errors.join('\n')}',
                );
              }
            },
          );
        }
      }
    }
  }
}

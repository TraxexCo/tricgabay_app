import 'dart:ui' show SemanticsAction;
import 'package:tricgabay_app/core/widgets/swipe_to_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/core/l10n/feedback_category.dart';
import 'package:tricgabay_app/core/l10n/locale_controller.dart';
import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/utils/validators.dart';
import 'package:tricgabay_app/core/widgets/responsive_app_frame.dart';
import 'package:tricgabay_app/l10n/app_localizations_en.dart';
import 'package:tricgabay_app/l10n/app_localizations_fil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('en_PH');
    await initializeDateFormatting('fil_PH');
  });
  tearDown(LocaleController.resetForTesting);
  test('Device language maps fil/tl to Filipino and others to English', () {
    expect(
      LocaleController.resolve(const Locale('fil', 'PH')),
      const Locale('fil'),
    );
    expect(LocaleController.resolve(const Locale('tl')), const Locale('fil'));
    expect(
      LocaleController.resolve(const Locale('en', 'US')),
      const Locale('en'),
    );
    expect(LocaleController.resolve(const Locale('ja')), const Locale('en'));
  });
  test('Manual override persists, follows device again when removed', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await LocaleController.initialize(prefs, device: const Locale('fil'));
    expect(LocaleController.overrideLocale, isNull);
    expect(LocaleController.effectiveLocale, const Locale('fil'));
    await LocaleController.choose(AppLanguage.english);
    expect(prefs.getString(LocaleController.preferenceKey), 'en');
    await LocaleController.initialize(prefs, device: const Locale('fil'));
    expect(LocaleController.effectiveLocale, const Locale('en'));
    await LocaleController.choose(AppLanguage.device);
    expect(prefs.containsKey(LocaleController.preferenceKey), isFalse);
    LocaleController.updateDevice(const Locale('tl'));
    expect(LocaleController.effectiveLocale, const Locale('fil'));
    LocaleController.updateDevice(const Locale('fr'));
    expect(LocaleController.effectiveLocale, const Locale('en'));
  });
  test('Legacy explicit choice migrates once', () async {
    SharedPreferences.setMockInitialValues({
      LocaleController.legacyPreferenceKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    await LocaleController.initialize(prefs, device: const Locale('en'));
    expect(LocaleController.selection, AppLanguage.filipino);
    expect(prefs.getString(LocaleController.preferenceKey), 'fil');
    expect(prefs.containsKey(LocaleController.legacyPreferenceKey), isFalse);
  });
  for (final locale in ['en', 'fil']) {
    test('$locale dates, time, peso grouping and decimal input', () {
      final date = DateTime(2026, 11, 4, 13, 5);
      expect(
        AppFormatters.currency(12345.67, locale: locale),
        contains('₱12,345.67'),
      );
      expect(AppFormatters.amount(12345.67, locale: locale), '12,345.67');
      expect(AppFormatters.decimalInput(12345.67), '12345.67');
      expect(
        AppFormatters.date(date, locale: locale),
        contains(locale == 'fil' ? 'Nobyembre' : 'November'),
      );
      expect(AppFormatters.time(date, locale: locale), contains('1:05'));
      expect(
        AppFormatters.philippineDateTime(
          DateTime.utc(2026, 11, 4, 5, 5),
          locale: locale,
        ),
        contains('1:05'),
      );
      expect(
        AppFormatters.philippineDateTime(
          DateTime.utc(2026, 11, 4, 5, 5),
          locale: locale,
        ),
        contains(locale == 'fil' ? 'Pilipinas' : 'Philippine'),
      );
    });
  }
  test(
    'Validator codes render in either locale; ICU count has no lost suffix',
    () {
      final code = Validators.email('')!;
      expect(code, startsWith('@l10n/'));
      expect(
        resolveMessage(AppLocalizationsEn(), code),
        'Email address is required',
      );
      expect(
        resolveMessage(AppLocalizationsFil(), code),
        isNot(contains('@l10n/')),
      );
      expect(AppLocalizationsEn().passengerCount(1), '1 passenger');
      expect(AppLocalizationsEn().passengerCount(4), '4 passengers');
      expect(AppLocalizationsFil().passengerCount(4), '4 pasahero');
      expect(AppBrand.name, 'Tric Gabay');
      expect(FeedbackCategory.suggestion.wireValue, 'Suggestion');
    },
  );
  test('Only large screens allow landscape', () {
    expect(orientationPolicy(600), contains(DeviceOrientation.landscapeLeft));
    expect(orientationPolicy(599), [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  });
  testWidgets(
    'Large content is bounded, text remains scalable and motion stops',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late BuildContext inside;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: ResponsiveAppFrame(child: child!),
          ),
          home: Builder(
            builder: (context) {
              inside = context;
              return const SizedBox.expand(key: ValueKey('content'));
            },
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('content'))).width, 840);
      expect(MediaQuery.textScalerOf(inside).scale(14), 28);
      expect(TickerMode.valuesOf(inside).enabled, isFalse);
    },
  );
  testWidgets(
    'Focused fields scroll above keyboard and background tap dismisses',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ResponsiveAppFrame(child: child!),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 900),
                  TextField(
                    focusNode: focus,
                    onTapOutside: (_) => focus.unfocus(),
                    scrollPadding: const EdgeInsets.all(96),
                  ),
                  const SizedBox(height: 500),
                ],
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(focus.hasFocus, isTrue);
      expect(
        tester.getBottomRight(find.byType(TextField)).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height - 260),
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(focus.hasFocus, isFalse);
    },
  );
  testWidgets('Long swipe labels wrap and assistive confirmation fires once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var confirmed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: SwipeToConfirm(
                  text: MessageCode.iAgreeToTheTermsAndConditions,
                  onConfirm: () => confirmed++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(SwipeToConfirm)).height,
      greaterThan(100),
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel(AppLocalizationsEn().iAgreeToTheTermsAndConditions),
    );
    tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await tester.pump();
    expect(confirmed, 1);
    tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await tester.pump();
    expect(confirmed, 1);
    semantics.dispose();
  });
}

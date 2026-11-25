import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/core/widgets/app_button.dart';
import 'package:tricgabay_app/features/tourist/screens/rate_review_screen.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSession.bookings.value = [];
    await AppSession.initialize();
  });

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RateReviewScreen(bookingId: 'none'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppButton submit(WidgetTester tester) =>
      tester.widget<AppButton>(find.byType(AppButton));

  testWidgets('starts with no star selected and Submit disabled', (
    tester,
  ) async {
    await show(tester);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    expect(submit(tester).onPressed, isNull);
    // No rating label such as "Excellent" is shown before a choice.
    expect(find.text('Excellent'), findsNothing);
  });

  testWidgets('picking a rating enables Submit', (tester) async {
    await show(tester);
    await tester.tap(find.byIcon(Icons.star_rounded).at(2));
    await tester.pumpAndSettle();
    expect(submit(tester).onPressed, isNotNull);
    expect(find.text('Okay'), findsOneWidget);
  });
}

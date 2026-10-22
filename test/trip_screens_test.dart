import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/prototype/prototype_session.dart';
import 'package:tricgabay_app/core/services/trip_rules.dart';
import 'package:tricgabay_app/features/admin/screens/fare_settings_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/booking_detail_screen.dart';
import 'package:tricgabay_app/models/trip_record.dart';
import 'trip_rules_test.dart' show accepted;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrototypeSession.bookings.value = [];
    PrototypeSession.setAuthenticatedUser(
      id: 'u1',
      name: 'Tourist',
      role: 'tourist',
      email: 'tourist@example.test',
    );
    await PrototypeSession.initialize();
  });
  Future<void> showSmall(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'small-screen tourist details expose code, route and cancellation without overflow',
    (tester) async {
      final b = accepted();
      PrototypeSession.bookings.value = [b];
      await showSmall(tester, BookingDetailScreen(bookingId: b.id));
      await tester.scrollUntilVisible(
        find.text('1234'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1234'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Cancel booking | no charge'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'admin review displays payment hold and reachable decision control on a small screen',
    (tester) async {
      final b = TripRules.cancel(
        TripRules.start(accepted(), '1234'),
        TripActor.driver,
        'Vehicle breakdown',
      );
      PrototypeSession.bookings.value = [b];
      await showSmall(
        tester,
        BookingDetailScreen(bookingId: b.id, viewer: TripActor.admin),
      );
      await tester.scrollUntilVisible(
        find.text('Review & decide final charge'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Review & decide final charge'), findsOneWidget);
      expect(find.text('Confirm cash received'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('fixed fare settings remain scrollable with larger text', (
    tester,
  ) async {
    await showSmall(tester, const FareSettingsScreen());
    await tester.scrollUntilVisible(
      find.text('Review and publish fares'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Review and publish fares'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/widgets/app_button.dart';
import 'package:tricgabay_app/core/widgets/app_text_field.dart';
import 'package:tricgabay_app/core/widgets/shared_widgets.dart';
import 'package:tricgabay_app/models/booking_model.dart';

void main() {
  testWidgets('loading action exposes one disabled live status', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppButton(label: 'Pay securely', isLoading: true)),
      ),
    );
    final data = tester.getSemantics(find.byType(AppButton)).getSemanticsData();
    expect(data.label, 'Pay securely');
    expect(data.value, 'Loading');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled.name, 'isFalse');
    expect(data.flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });

  testWidgets('booking state is announced as a status without duplicate text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StatusBadge.bookingStatus(BookingStatus.ongoing)),
      ),
    );
    expect(
      tester.getSemantics(find.byType(StatusBadge)),
      matchesSemantics(label: 'ongoing status', isReadOnly: true),
    );
    semantics.dispose();
  });

  testWidgets('password visibility control has a meaningful tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTextField(label: 'Password', obscureText: true),
        ),
      ),
    );
    expect(find.byTooltip('Show Password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show Password'));
    await tester.pump();
    expect(find.byTooltip('Hide Password'), findsOneWidget);
  });

  testWidgets('loading overlay announces its current operation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: LoadingOverlay(message: 'Confirming booking')),
    );
    expect(
      tester.getSemantics(find.byType(LoadingOverlay)),
      matchesSemantics(label: 'Confirming booking', isLiveRegion: true),
    );
    semantics.dispose();
  });
}

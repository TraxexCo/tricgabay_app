import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/features/admin/screens/manage_tourists_screen.dart';

void main() {
  testWidgets('tourist status action confirms success and updates semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final previous = AppSession.adminTourists.value;
    addTearDown(() => AppSession.adminTourists.value = previous);
    AppSession.adminTourists.value = [
      {
        'id': 'tourist-feedback-test',
        'name': 'Maria Clara',
        'email': 'maria@example.test',
        'status': 'active',
        'trips': 2,
      },
    ];

    await tester.pumpWidget(const MaterialApp(home: ManageTouristsScreen()));

    expect(
      find.bySemanticsLabel(RegExp('Suspend Maria Clara')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Suspend tourist'));
    await tester.pumpAndSettle();
    expect(AppSession.adminTourists.value.single['status'], 'active');
    await tester.enterText(find.byType(TextField), 'Support review completed');
    await tester.tap(find.text('Confirm change'));
    await tester.pumpAndSettle();

    expect(AppSession.adminTourists.value.single['status'], 'suspended');
    expect(find.text('Tourist account suspended'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Activate Maria Clara')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

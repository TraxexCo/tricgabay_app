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

    // Stand-in for the server: flip the status the way the RPC + refresh would.
    Future<void> toggle(String id, {required String reason}) async {
      AppSession.adminTourists.value = [
        for (final u in AppSession.adminTourists.value)
          u['id'] == id
              ? {
                  ...u,
                  'status': u['status'] == 'active' ? 'suspended' : 'active',
                }
              : u,
      ];
    }

    await tester.pumpWidget(
      MaterialApp(home: ManageTouristsScreen(onToggleStatus: toggle)),
    );

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

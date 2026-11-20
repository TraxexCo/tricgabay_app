import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tricgabay_app/core/prototype/prototype_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/services/privacy_service.dart';
import 'package:tricgabay_app/core/widgets/privacy_consent_gate.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'account switch resets optional diagnostics and required acceptance',
    (tester) async {
      const notice = PrivacyNotice('v1', 'Test notice', 'Paunawa');
      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyConsentGate(
            loader: () async => const PrivacyState(notice, false),
            child: const Text('Protected'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      PrototypeSession.authRevision.value++;
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
    },
  );
  testWidgets(
    'late consent failure for account A cannot change account B saving state or error',
    (tester) async {
      var version = 'account-a';
      var accepted = false;
      final a = Completer<void>(), b = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyConsentGate(
            loader: () async => PrivacyState(
              PrivacyNotice(version, 'Test notice', 'Paunawa'),
              accepted,
            ),
            record: (shown) async {
              await (shown == 'account-a' ? a.future : b.future);
              if (shown == version) accepted = true;
            },
            child: const Text('Protected'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> accept() async {
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await tester.ensureVisible(find.text('Accept and continue'));
        await tester.tap(find.text('Accept and continue'));
        await tester.pump();
      }

      await accept();
      version = 'account-b';
      PrototypeSession.authRevision.value++;
      await tester.pumpAndSettle();
      await accept();
      a.completeError(StateError('Account A failed'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.text('Accept and continue'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      b.complete();
      await tester.pumpAndSettle();
      expect(find.text('Protected'), findsOneWidget);
    },
  );
  testWidgets('existing user cannot enter until current notice is accepted', (
    tester,
  ) async {
    var accepted = false;
    String? recorded;
    const notice = PrivacyNotice(
      'server-version',
      'Current notice',
      'Kasalukuyang paunawa',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyConsentGate(
          loader: () async => PrivacyState(notice, accepted),
          record: (version) async {
            recorded = version;
            accepted = true;
          },
          child: const Text('Protected trips'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Protected trips'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Accept and continue'),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(
      find.text('I have read and accept this notice.'),
    );
    await tester.tap(find.text('I have read and accept this notice.'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Accept and continue'));
    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();
    expect(recorded, 'server-version');
    expect(find.text('Protected trips'), findsOneWidget);
  });
  testWidgets('consent lookup failure blocks protected content with retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyConsentGate(
          loader: () async => throw StateError('offline'),
          child: const Text('Protected trips'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Protected trips'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}

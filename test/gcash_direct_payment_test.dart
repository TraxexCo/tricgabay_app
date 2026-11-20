import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/utils/gcash_payment.dart';
import 'package:tricgabay_app/core/widgets/swipe_to_confirm.dart';
import 'package:tricgabay_app/features/tourist/screens/gcash_trip_payment.dart';
import 'package:tricgabay_app/models/booking_model.dart';

void main() {
  test('GCash accepts only local and international PH mobile numbers', () {
    expect(normalizeGcashNumber('09171234567'), '09171234567');
    expect(normalizeGcashNumber('+639171234567'), '09171234567');
    for (final invalid in [
      '9171234567',
      '639171234567',
      '08171234567',
      '0917123456',
      '091712345678',
      ' 09171234567',
      '0917-123-4567',
      '+649171234567',
    ]) {
      expect(normalizeGcashNumber(invalid), isNull);
    }
  });

  test(
    'GCash references are optional and limited to 8–20 ASCII letters or digits',
    () {
      for (final valid in [
        '',
        '  ',
        'AB123456',
        'a1234567890123456789',
        '  AB123456  ',
      ]) {
        expect(isValidGcashReference(valid), isTrue);
      }
      for (final invalid in [
        '1234567',
        '123456789012345678901',
        'ABC-123456',
        'ABCDEé12',
      ]) {
        expect(isValidGcashReference(invalid), isFalse);
      }
    },
  );

  test(
    'GCash display and clipboard share the fare but use distinct formats',
    () {
      expect(AppFormatters.currency(150, locale: 'en'), '₱150.00');
      expect(AppFormatters.currency(1250.25, locale: 'en'), '₱1,250.25');
      expect(AppFormatters.decimalInput(1250.25), '1250.25');
    },
  );

  Widget tourist({
    bool hasNumber = true,
    Future<bool> Function()? open,
    Future<void> Function(String)? sent,
    Future<void> Function()? cash,
    PaymentStatus status = PaymentStatus.unpaid,
  }) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: GcashTouristPayment(
          accountName: hasNumber ? 'Driver Test' : null,
          number: hasNumber ? '09171234567' : null,
          fareCents: hasNumber ? 15000 : null,
          status: status,
          openGcash: open ?? () async => true,
          onSent: sent ?? (_) async {},
          onCash: cash ?? () async {},
        ),
      ),
    ),
  );

  testWidgets(
    'tourist sees the saved fare and payee and can submit an optional reference',
    (tester) async {
      String? reference;
      await tester.pumpWidget(
        tourist(sent: (value) async => reference = value),
      );
      expect(find.text('₱150.00'), findsOneWidget);
      expect(find.text('Driver Test'), findsOneWidget);
      expect(find.text('09171234567'), findsOneWidget);
      await tester.tap(find.text("I've sent the payment"));
      await tester.pumpAndSettle();
      expect(reference, '');
      await tester.enterText(find.byType(TextFormField), 'REF12345');
      await tester.tap(find.text("I've sent the payment"));
      await tester.pumpAndSettle();
      expect(reference, 'REF12345');
    },
  );

  testWidgets('no active number shows only the cash fallback', (tester) async {
    var switched = false;
    await tester.pumpWidget(
      tourist(hasNumber: false, cash: () async => switched = true),
    );
    expect(
      find.text("Your driver hasn't set up GCash. Please pay with cash."),
      findsOneWidget,
    );
    expect(find.text('Open GCash'), findsNothing);
    expect(find.text('Copy number'), findsNothing);
    expect(find.text("I've sent the payment"), findsNothing);
    await tester.tap(find.text('Pay with cash instead'));
    expect(switched, isTrue);
  });

  testWidgets(
    'failed GCash launch keeps number and decimal copy actions usable',
    (tester) async {
      final copied = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(tourist(open: () async => false));
      await tester.tap(find.text('Open GCash'));
      await tester.pumpAndSettle();
      expect(find.textContaining("GCash isn't installed"), findsOneWidget);
      await tester.tap(find.text('Copy number'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy amount'));
      await tester.pumpAndSettle();
      expect(copied, ['09171234567', '150.00']);
    },
  );

  testWidgets('slide resets early, waits for response, and supports retry', (
    tester,
  ) async {
    var calls = 0;
    final first = Completer<void>();
    final second = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: SwipeToConfirm(
                text: 'Slide to confirm',
                accessibilityLabel: 'Confirm payment received',
                errorText: 'Try again',
                onConfirmAsync: () =>
                    ++calls == 1 ? first.future : second.future,
              ),
            ),
          ),
        ),
      ),
    );
    final thumb = find.byIcon(Icons.arrow_forward_ios);
    final start = tester.getCenter(thumb);
    await tester.drag(thumb, const Offset(85, 0));
    await tester.pump();
    expect(calls, 0);
    expect(tester.getCenter(thumb), start);

    // The confirm action is also exposed to screen readers.
    final control = find.bySemanticsLabel('Confirm payment received');
    final semantics = tester.ensureSemantics();
    try {
      expect(control, findsOneWidget);
    } finally {
      semantics.dispose();
    }
    await tester.drag(thumb, const Offset(285, 0));
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    first.completeError(StateError('failed'));
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
    await tester.drag(thumb, const Offset(285, 0));
    await tester.pump();
    second.complete();
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}

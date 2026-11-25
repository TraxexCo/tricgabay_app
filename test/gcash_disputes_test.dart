import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tricgabay_app/core/services/gcash_repository.dart';
import 'package:tricgabay_app/features/admin/screens/gcash_disputes_screen.dart';
import 'package:tricgabay_app/features/payment/gcash_dispute_panel.dart';
import 'package:tricgabay_app/features/payment/outstanding_fare_banner.dart';
import 'package:tricgabay_app/l10n/app_localizations_en.dart';

final l10n = AppLocalizationsEn();
final receipt = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Widget routed(Widget child) => MaterialApp.router(
  routerConfig: GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => child),
      GoRoute(
        path: '/tourist/bookings/:id',
        builder: (_, state) => Text('trip ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/admin/gcash-disputes/:id',
        builder: (_, state) => Text('dispute ${state.pathParameters['id']}'),
      ),
    ],
  ),
);

GcashDisputePanel panel(
  GcashDisputeDetail detail, {
  bool driver = false,
  Future<void> Function(String, Uint8List)? submit,
  Future<void> Function(String?)? ask,
  VoidCallback? view,
}) => GcashDisputePanel(
  detail: detail,
  driver: driver,
  onSubmitProof: submit ?? (_, _) async {},
  onAskAdmin: ask ?? (_) async {},
  pickReceipt: () async => receipt,
  onViewReceipt: view,
);

void main() {
  group('proof form', () {
    testWidgets('needs a receipt and a valid reference before sending', (
      tester,
    ) async {
      String? sentRef;
      Uint8List? sentBytes;
      await tester.pumpWidget(
        host(
          GcashProofForm(
            pickReceipt: () async => receipt,
            onSubmit: (ref, bytes) async {
              sentRef = ref;
              sentBytes = bytes;
            },
          ),
        ),
      );
      final send = find.widgetWithText(FilledButton, l10n.gcashSubmitProof);
      expect(tester.widget<FilledButton>(send).onPressed, isNull);

      await tester.tap(find.text(l10n.gcashChooseReceipt));
      await tester.pumpAndSettle();
      expect(find.text(l10n.gcashReceiptChosen), findsOneWidget);

      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.text(l10n.gcashInvalidReference), findsOneWidget);
      expect(sentRef, isNull);

      await tester.enterText(
        find.byKey(const Key('gcash-proof-reference')),
        ' 1234567890123 ',
      );
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(sentRef, '1234567890123');
      expect(sentBytes, receipt);
    });
  });

  group('dispute panel', () {
    testWidgets('tourist without proof sees the proof form and ask-admin', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(panel(const GcashDisputeDetail(fareCents: 15000))),
      );
      expect(find.text(l10n.gcashProofTitle), findsOneWidget);
      expect(find.text(l10n.gcashAskAdmin), findsOneWidget);
    });

    testWidgets('ask-admin sends the optional note', (tester) async {
      String? note = 'unset';
      await tester.pumpWidget(
        host(
          panel(
            const GcashDisputeDetail(fareCents: 15000),
            ask: (value) async => note = value,
          ),
        ),
      );
      await tester.tap(find.text(l10n.gcashAskAdmin));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Please check');
      await tester.tap(find.widgetWithText(FilledButton, l10n.gcashAskAdmin));
      await tester.pumpAndSettle();
      expect(note, 'Please check');
    });

    testWidgets('escalated dispute shows the notice and no ask-admin', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          panel(
            GcashDisputeDetail(fareCents: 15000, escalatedAt: DateTime(2026)),
          ),
        ),
      );
      expect(find.text(l10n.gcashEscalatedNotice), findsOneWidget);
      expect(find.text(l10n.gcashAskAdmin), findsNothing);
    });

    testWidgets('a not-paid ruling is shown with its reason', (tester) async {
      await tester.pumpWidget(
        host(
          panel(
            GcashDisputeDetail(
              fareCents: 15000,
              escalatedAt: DateTime(2026),
              ruling: GcashRuling.notPaid,
              rulingReason: 'No matching transfer',
            ),
          ),
        ),
      );
      expect(find.text(l10n.gcashRulingNotPaid), findsOneWidget);
      expect(find.text('No matching transfer'), findsOneWidget);
      expect(find.text(l10n.gcashProofTitle), findsNothing);
    });

    testWidgets('driver sees the reference and can open the receipt', (
      tester,
    ) async {
      var viewed = false;
      await tester.pumpWidget(
        host(
          panel(
            const GcashDisputeDetail(
              fareCents: 15000,
              referenceNo: '1234567890123',
              receiptPath: 'b/r.jpg',
              disputeNote: 'Not in history',
            ),
            driver: true,
            view: () => viewed = true,
          ),
        ),
      );
      expect(find.textContaining('1234567890123'), findsOneWidget);
      expect(find.textContaining('Not in history'), findsOneWidget);
      expect(find.text(l10n.gcashProofTitle), findsNothing);
      await tester.tap(find.text(l10n.gcashViewReceipt));
      expect(viewed, isTrue);
    });
  });

  group('admin', () {
    GcashDispute dispute({
      required String id,
      DateTime? escalatedAt,
      GcashRuling? ruling,
    }) => GcashDispute(
      bookingId: id,
      referenceLabel: 'TRIC-$id',
      touristName: 'Tourist $id',
      driverName: 'Driver $id',
      fareCents: 15000,
      disputedAt: DateTime(2026),
      escalatedAt: escalatedAt,
      hasProof: true,
      ruling: ruling,
    );

    testWidgets('queue labels escalated, waiting and unsettled disputes', (
      tester,
    ) async {
      await tester.pumpWidget(
        routed(
          GcashDisputesScreen(
            loader: () async => [
              dispute(id: 'a', escalatedAt: DateTime(2026)),
              dispute(id: 'b'),
              dispute(id: 'c', ruling: GcashRuling.notPaid),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(l10n.adminDisputeEscalated), findsOneWidget);
      expect(find.textContaining(l10n.adminDisputeWaiting), findsOneWidget);
      expect(find.textContaining(l10n.adminDisputeUnsettled), findsOneWidget);
      await tester.tap(find.textContaining('TRIC-a'));
      await tester.pumpAndSettle();
      expect(find.text('dispute a'), findsOneWidget);
    });

    testWidgets('empty queue says so', (tester) async {
      await tester.pumpWidget(
        routed(GcashDisputesScreen(loader: () async => [])),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.adminGcashDisputesEmpty), findsOneWidget);
    });

    testWidgets('ruling requires a reason and reaches the server call', (
      tester,
    ) async {
      final calls = <(GcashRuling, String)>[];
      await tester.pumpWidget(
        routed(
          GcashDisputeDetailScreen(
            bookingId: 'b1',
            loader: (_) async => const GcashDisputeDetail(
              fareCents: 15000,
              referenceNo: '1234567890123',
            ),
            onRule: (_, ruling, reason) async => calls.add((ruling, reason)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.adminNoReceipt), findsOneWidget);
      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n.adminRuleNotPaid),
      );
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, l10n.adminRuleNotPaid);
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(calls, isEmpty, reason: 'reasons under five characters stay open');
      await tester.enterText(find.byType(TextField), 'No transfer found');
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(calls, [(GcashRuling.notPaid, 'No transfer found')]);
    });

    testWidgets('unsettled not-paid ruling offers a waiver', (tester) async {
      await tester.pumpWidget(
        routed(
          GcashDisputeDetailScreen(
            bookingId: 'b1',
            loader: (_) async => const GcashDisputeDetail(
              fareCents: 15000,
              ruling: GcashRuling.notPaid,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.adminWaiveFare), findsOneWidget);
      expect(find.text(l10n.adminRulePaid), findsNothing);
    });
  });

  group('outstanding fare banner', () {
    testWidgets('links to the unpaid trip when one is owed', (tester) async {
      await tester.pumpWidget(
        routed(OutstandingFareBanner(loader: () async => 'owed-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.outstandingFareBlocked), findsOneWidget);
      await tester.tap(find.text(l10n.outstandingFareAction));
      await tester.pumpAndSettle();
      expect(find.text('trip owed-1'), findsOneWidget);
    });

    testWidgets('renders nothing when nothing is owed', (tester) async {
      await tester.pumpWidget(
        routed(OutstandingFareBanner(loader: () async => null)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.outstandingFareTitle), findsNothing);
    });
  });

  test('image objects follow the server path rule', () {
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, //
    ]);
    final object = gcashImageObject(
      'c6170000-0000-4000-8000-000000000001',
      png,
      newId: () => 'd6170000-0000-4000-8000-000000000001',
    );
    expect(
      RegExp(r'^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|png)$').hasMatch(object.path),
      isTrue,
    );
    expect(object.contentType, 'image/png');
    expect(
      () => gcashImageObject('x', Uint8List.fromList([1, 2, 3])),
      throwsStateError,
    );
  });
}

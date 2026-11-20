import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/remote_pagination.dart';
import 'package:tricgabay_app/core/prototype/prototype_session.dart';
import 'package:tricgabay_app/core/widgets/remote_page_controls.dart';

void main() {
  test('pagination fetches only the requested history window', () async {
    final calls = <int>[];
    Future<({List<int> items, bool hasMore})> fetch(int page) async {
      calls.add(page);
      return (items: [page], hasMore: page < 1);
    }

    final first = await readPageWindow(throughPage: 0, fetch: fetch);
    expect(calls, [0]);
    expect(first.items, [0]);
    expect(first.hasMore, isTrue);
    calls.clear();
    final next = await readPageWindow(throughPage: 5, fetch: fetch);
    expect(calls, [0, 1]);
    expect(next.items, [0, 1]);
    expect(next.hasMore, isFalse);
  });
  testWidgets('load-more control shows progress and disappears at the end', (
    tester,
  ) async {
    final oldMore = PrototypeSession.hasMoreBookings.value,
        oldBusy = PrototypeSession.loadingMoreBookings.value;
    addTearDown(() {
      PrototypeSession.hasMoreBookings.value = oldMore;
      PrototypeSession.loadingMoreBookings.value = oldBusy;
    });
    PrototypeSession.hasMoreBookings.value = true;
    PrototypeSession.loadingMoreBookings.value = false;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(bottomNavigationBar: RemotePageControls()),
      ),
    );
    expect(find.text('Load more bookings'), findsOneWidget);
    PrototypeSession.loadingMoreBookings.value = true;
    await tester.pump();
    expect(find.text('Loading more…'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    PrototypeSession.hasMoreBookings.value = false;
    await tester.pump();
    expect(find.byType(TextButton), findsNothing);
  });
}

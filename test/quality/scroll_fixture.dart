import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercise lazy content and form actions after checking the initial viewport.
Future<void> revealFixtureEnd(WidgetTester tester) async {
  final positions = tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .where(
        (s) =>
            s.widget.axisDirection == AxisDirection.down ||
            s.widget.axisDirection == AxisDirection.up,
      )
      .map((s) => s.position)
      .toList();
  for (final position in positions) {
    if (position.hasContentDimensions && position.maxScrollExtent > 0) {
      position.jumpTo(position.maxScrollExtent);
    }
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

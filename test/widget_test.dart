import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tricgabay_app/main.dart';

void main() {
  testWidgets('TricGabay app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TricGabayApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

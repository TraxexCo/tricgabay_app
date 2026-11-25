import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'screen_registry.dart';

void main() {
  test('Every public feature screen has an entry in the rendering matrix', () {
    final registered = screenCases.map((s) => s.name).toSet();
    final discovered = <String>{};
    for (final file
        in Directory('lib/features')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      discovered.addAll(
        RegExp(
          r'class\s+([A-Z]\w*Screen)\s+extends',
        ).allMatches(file.readAsStringSync()).map((m) => m[1]!),
      );
    }
    expect(
      discovered.difference(registered),
      isEmpty,
      reason: 'Register each new screen with populated local fixtures.',
    );
    expect(registered.length, greaterThanOrEqualTo(60));
  });
}

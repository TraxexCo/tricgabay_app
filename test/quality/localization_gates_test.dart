import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/localization_audit.dart';

Map<String, dynamic> arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;
Set<String> keys(Map<String, dynamic> a) =>
    a.keys.where((k) => !k.startsWith('@')).toSet();
Set<String> placeholders(String text) => RegExp(
  r'\{([a-zA-Z]\w*)\s*[,}]',
).allMatches(text).map((m) => m[1]!).toSet();
void main() {
  test('English and Filipino keys have exact parity', () {
    expect(keys(arb('fil')), keys(arb('en')));
  });
  test('All placeholders and their declared types have parity', () {
    final en = arb('en'), fil = arb('fil');
    for (final key in keys(en)) {
      final expected = placeholders(en[key] as String);
      expect(placeholders(fil[key] as String), expected, reason: key);
      for (final locale in [en, fil]) {
        final declared = Map<String, dynamic>.from(
          (locale['@$key'] as Map?)?['placeholders'] as Map? ?? {},
        );
        expect(declared.keys.toSet(), expected, reason: '$key metadata');
        for (final name in expected) {
          expect(
            declared[name]['type'],
            (en['@$key'] as Map)['placeholders'][name]['type'],
            reason: '$key/$name',
          );
        }
      }
    }
  });
  test('No unreviewed user-visible literal exists in lib', () {
    final allowed =
        jsonDecode(File('tool/localization_allowlist.json').readAsStringSync())
            as List;
    for (final entry in allowed) {
      expect(
        {'brand', 'data', 'example', 'protocol'}.contains(entry['kind']),
        isTrue,
      );
      expect((entry['reason'] as String).length, greaterThan(15));
    }
    final unexpected = unexpectedLiterals(visibleLiterals(), allowed);
    expect(
      unexpected,
      isEmpty,
      reason: unexpected
          .map((r) => "${r['file']}:${r['line']} ${r['value']}")
          .join('\n'),
    );
  });
  test('Literal gate catches new text and ignores data keys', () {
    const sample =
        "Widget build(context)=>Text('New untranslated label'); final wire={'booking_id':'abc'};";
    final visitor = VisibleLiteralVisitor('lib/new.dart');
    parseString(content: sample).unit.accept(visitor);
    expect(visitor.found.map((r) => r['value']), ['New untranslated label']);
  });
  test('Legacy English matching and fixed currency formatting cannot return', () {
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) =>
                  f.path.endsWith('.dart') &&
                  !f.path.endsWith('.g.dart') &&
                  !f.path.contains('app_localizations'),
            )) {
      final text = file.readAsStringSync();
      expect(
        RegExp(
          r'lookupLabel|\bL10nText\b|\blocalizedLabel\s*\(|\btranslatedLabel\s*\(|\bcontext\.tr\s*\(',
        ).hasMatch(text),
        isFalse,
        reason: file.path,
      );
      expect(text.contains('toStringAsFixed(2)'), isFalse, reason: file.path);
      expect(text.contains('PHT'), isFalse, reason: file.path);
    }
  });
  test('Glossary terms remain consistent', () {
    final fil = arb('fil');
    const terms = {
      'booking': 'reserbasyon',
      'driver': 'drayber',
      'tourist': 'turista',
      'tricycle': 'traysikel',
      'trip': 'biyahe',
      'pickup': 'sunduan',
      'pending': 'naghihintay',
      'completed': 'natapos',
    };
    for (final entry in terms.entries) {
      expect(
        (fil[entry.key] as String).toLowerCase(),
        entry.value,
        reason: entry.key,
      );
    }
    for (final key in keys(fil)) {
      expect(
        RegExp(
          r'\b(driver|tourist|tricycle|booking|pick-up|mag-book)\b',
          caseSensitive: false,
        ).hasMatch(fil[key] as String),
        isFalse,
        reason: key,
      );
    }
    expect(
      File('docs/GLOSSARY.md').readAsStringSync(),
      contains('native-speaker'),
    );
  });
  test('Review CSV is a complete exact export of the catalogs', () {
    final en = arb('en'), fil = arb('fil');
    String quote(String s) => '"${s.replaceAll('"', '""')}"';
    final sorted = keys(en).toList()..sort();
    final expected =
        'key,en,fil,review_status\r\n${sorted.map((k) => [k, en[k] as String, fil[k] as String, 'Needs native-speaker review'].map(quote).join(',')).join('\r\n')}\r\n';
    expect(File('docs/localization-review.csv').readAsStringSync(), expected);
  });
}

import 'dart:convert';
import 'dart:io';

void main() {
  final en =
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final fil =
      jsonDecode(File('lib/l10n/app_fil.arb').readAsStringSync())
          as Map<String, dynamic>;
  final keys = en.keys.where((k) => !k.startsWith('@')).toList()..sort();
  String quote(String s) => '"${s.replaceAll('"', '""')}"';
  final csv =
      'key,en,fil,review_status\r\n${keys.map((k) => [k, en[k] as String, fil[k] as String, 'Needs native-speaker review'].map(quote).join(',')).join('\r\n')}\r\n';
  Directory('docs').createSync(recursive: true);
  File('docs/localization-review.csv').writeAsStringSync(csv);
  stdout.writeln('LOCALIZATION_REVIEW_EXPORTED pairs=${keys.length}');
}

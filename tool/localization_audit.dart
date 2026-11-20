import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

const visibleArguments = {
  'label',
  'title',
  'subtitle',
  'hint',
  'hintText',
  'labelText',
  'tooltip',
  'message',
  'semanticsLabel',
  'semanticLabel',
  'helperText',
  'errorText',
  'emptyTitle',
  'emptySubtitle',
};
String literalTemplate(StringLiteral n) {
  if (n is StringInterpolation) {
    var result = '', index = 0;
    for (final e in n.elements) {
      result += e is InterpolationString ? e.value : '{${++index}}';
    }
    return result;
  }
  if (n is AdjacentStrings) return n.strings.map(literalTemplate).join();
  return n.stringValue ?? '';
}

class VisibleLiteralVisitor extends RecursiveAstVisitor<void> {
  final String file;
  final List<Map<String, dynamic>> found = [];
  VisibleLiteralVisitor(this.file);
  void inspect(StringLiteral node) {
    if (node.parent is Directive || node.parent is AdjacentStrings) return;
    final value = literalTemplate(node);
    if (value.isEmpty ||
        value.startsWith('@l10n/') ||
        value.startsWith('assets/') ||
        value.startsWith('package:') ||
        value.startsWith('/') ||
        value.contains('://')) {
      return;
    }
    if (node is SimpleStringLiteral && node.isRaw) return;
    if (node.parent case MapLiteralEntry entry
        when identical(entry.key, node)) {
      return;
    }
    if (node.parent case IndexExpression entry
        when identical(entry.index, node)) {
      return;
    }
    var display = false, label = false;
    for (AstNode? p = node.parent; p != null; p = p.parent) {
      if (p is IndexExpression &&
          node.offset >= p.index.offset &&
          node.end <= p.index.end) {
        return;
      }
      if (p is SwitchExpressionCase && node.end <= p.guardedPattern.end) return;
      if (p is NamedExpression && visibleArguments.contains(p.name.label.name)) {
        display = true;
      }
      String? name;
      if (p is MethodInvocation) name = p.methodName.name;
      if (p is InstanceCreationExpression) {
        name = p.constructorName.type.toSource();
      }
      if ({'Text', 'TextSpan', 'L10nText', 'Tab', 'Tooltip'}.contains(name)) {
        display = true;
      }
      if ({
        'RegExp',
        'Uri',
        'DateFormat',
        'NumberFormat',
        'Color',
        'MethodChannel',
        'EventChannel',
      }.contains(name)) {
        return;
      }
      if (!display &&
          {
            'rpc',
            'from',
            'select',
            'eq',
            'neq',
            'order',
            'contains',
            'startsWith',
            'endsWith',
            'debugPrint',
            'log',
            'split',
            'replaceAll',
            'replaceFirst',
            'join',
            'padLeft',
          }.contains(name)) {
        return;
      }
      if (p is MethodDeclaration) {
        label =
            p.isGetter &&
            (p.name.lexeme.toLowerCase().contains('label') ||
                p.name.lexeme == 'display');
        break;
      }
      if (p is FunctionDeclaration || p is ConstructorDeclaration) break;
    }
    if (node.parent is BinaryExpression &&
        {
          '==',
          '!=',
          '>',
          '<',
        }.contains((node.parent as BinaryExpression).operator.lexeme)) {
      return;
    }
    final words = value.replaceAll(RegExp(r'\{\d+\}'), '').trim();
    if (!RegExp(r'[A-Za-zÀ-ž]').hasMatch(words)) return;
    if (!display &&
        !label &&
        !RegExp(
          r'^[A-Z][a-z]+$|[A-Za-zÀ-ž]{2,}[ ,;:!?-]+[A-Za-zÀ-ž]{2,}',
        ).hasMatch(words)) {
      return;
    }
    if (RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)+$').hasMatch(words) &&
        !display &&
        !label) {
      return;
    }
    if (words.contains('\\') && !display) return;
    found.add({'file': file, 'value': value, 'offset': node.offset});
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral n) {
    inspect(n);
    super.visitSimpleStringLiteral(n);
  }

  @override
  void visitStringInterpolation(StringInterpolation n) {
    inspect(n);
    super.visitStringInterpolation(n);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings n) {
    inspect(n);
    super.visitAdjacentStrings(n);
  }
}

List<Map<String, dynamic>> visibleLiterals({String root = '.'}) {
  final rows = <Map<String, dynamic>>[];
  final base = Directory(root).absolute.path.replaceAll('\\', '/');
  for (final file in Directory(
    '$root/lib',
  ).listSync(recursive: true).whereType<File>()) {
    final absolute = file.absolute.path.replaceAll('\\', '/');
    final relative = absolute.substring(base.length + 1);
    if (!relative.endsWith('.dart') ||
        relative.startsWith('lib/l10n/') ||
        relative.endsWith('.g.dart')) {
      continue;
    }
    final parsed = parseString(
      content: file.readAsStringSync(),
      path: relative,
    );
    final visitor = VisibleLiteralVisitor(relative);
    parsed.unit.accept(visitor);
    for (final row in visitor.found) {
      row['line'] = parsed.lineInfo
          .getLocation(row['offset'] as int)
          .lineNumber;
      rows.add(row);
    }
  }
  return rows;
}

List<Map<String, dynamic>> unexpectedLiterals(
  List<Map<String, dynamic>> rows,
  List<dynamic> allowed,
) => rows
    .where(
      (r) => !allowed.any(
        (a) => a['file'] == r['file'] && a['value'] == r['value'],
      ),
    )
    .toList();
void main(List<String> args) {
  final root = args.isEmpty ? '.' : args.first,
      rows = visibleLiterals(root: root);
  final allowed = File('tool/localization_allowlist.json').existsSync()
      ? jsonDecode(File('tool/localization_allowlist.json').readAsStringSync())
            as List
      : [];
  final failures = unexpectedLiterals(rows, allowed);
  if (args.length > 1) {
    File(args[1]).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'candidates': rows.length,
        'unexpected': failures.length,
        'rows': rows,
        'failures': failures,
      }),
    );
  }
  stdout.writeln(
    'LOCALIZATION_LITERAL_GATE candidates=${rows.length} allowlisted=${rows.length - failures.length} unexpected=${failures.length}',
  );
  if (failures.isNotEmpty) {
    for (final row in failures) {
      stdout.writeln('${row['file']}:${row['line']} ${row['value']}');
    }
    exitCode = 1;
  }
}

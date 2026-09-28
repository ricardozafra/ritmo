import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

const operationalClockPath = 'lib/domain/time/operational_clock.dart';
const _message =
    'Use OperationalClock; DateTime.now() is forbidden outside it.';

final class ClockLintViolation {
  const ClockLintViolation({
    required this.path,
    required this.line,
    required this.column,
  });

  final String path;
  final int line;
  final int column;

  @override
  String toString() => '$path:$line:$column: $_message';
}

List<ClockLintViolation> lintClockSource({
  required String source,
  required String path,
}) {
  if (_isOperationalClockPath(path)) {
    return const [];
  }

  final parsed = parseString(content: source, path: path);
  final visitor = _DateTimeNowVisitor(path, parsed.lineInfo);
  parsed.unit.accept(visitor);
  return visitor.violations;
}

List<ClockLintViolation> lintClockPaths(Iterable<String> paths) {
  final files = <File>[];
  for (final path in paths) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file && path.endsWith('.dart')) {
      files.add(File(path));
    } else if (type == FileSystemEntityType.directory) {
      files.addAll(
        Directory(path)
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart')),
      );
    }
  }

  files.sort((left, right) => left.path.compareTo(right.path));
  return [
    for (final file in files)
      ...lintClockSource(source: file.readAsStringSync(), path: file.path),
  ];
}

bool _isOperationalClockPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized == operationalClockPath ||
      normalized.endsWith('/$operationalClockPath');
}

final class _DateTimeNowVisitor extends RecursiveAstVisitor<void> {
  _DateTimeNowVisitor(this.path, this.lineInfo);

  final String path;
  final LineInfo lineInfo;
  final violations = <ClockLintViolation>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Covers the explicit forms `new DateTime.now()` and `const`/prefixed
    // constructions that the parser resolves as instance creations.
    final constructor = node.constructorName;
    if (constructor.name?.name == 'now' &&
        constructor.type.name.lexeme == 'DateTime') {
      _report(node.offset);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Without `new`, `DateTime.now()` and `core.DateTime.now()` are parsed as
    // method invocations, since the parser cannot resolve `DateTime` to a type.
    if (node.methodName.name == 'now' && _targetsDateTime(node.target)) {
      _report(node.offset);
    }
    super.visitMethodInvocation(node);
  }

  bool _targetsDateTime(Expression? target) {
    if (target is SimpleIdentifier) {
      return target.name == 'DateTime';
    }
    if (target is PrefixedIdentifier) {
      return target.identifier.name == 'DateTime';
    }
    return false;
  }

  void _report(int offset) {
    final location = lineInfo.getLocation(offset);
    violations.add(
      ClockLintViolation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
      ),
    );
  }
}

void main(List<String> arguments) {
  final targets = arguments.isEmpty ? const ['lib'] : arguments;
  final violations = lintClockPaths(targets);

  if (violations.isEmpty) {
    stdout.writeln('clock_lint: no forbidden DateTime.now() calls found.');
    return;
  }

  stderr.writeln(
    'clock_lint: ${violations.length} forbidden DateTime.now() call(s):',
  );
  for (final violation in violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}

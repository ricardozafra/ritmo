import 'package:flutter_test/flutter_test.dart';

import '../../tool/clock_lint.dart';

void main() {
  group('clock lint', () {
    test('reports DateTime.now outside OperationalClock', () {
      final violations = lintClockSource(
        // A primeira linha em branco é intencional: fixa a numeração esperada,
        // já que Dart descarta o newline imediatamente após o `'''`.
        source: '''

void loadToday() {
  final instant = DateTime.now();
}
''',
        path: 'lib/app/today_controller.dart',
      );

      expect(violations, hasLength(1));
      expect(violations.single.line, 3);
      expect(violations.single.column, 19);
      expect(violations.single.toString(), contains('Use OperationalClock'));
    });

    test('allows DateTime.now inside the OperationalClock source', () {
      final violations = lintClockSource(
        source: 'final instant = DateTime.now();',
        path: 'lib/domain/time/operational_clock.dart',
      );

      expect(violations, isEmpty);
    });

    test('recognizes the exception with Windows absolute paths', () {
      final violations = lintClockSource(
        source: 'final instant = DateTime.now();',
        path: r'C:\repo\lib\domain\time\operational_clock.dart',
      );

      expect(violations, isEmpty);
    });

    test('ignores comments and strings containing the forbidden spelling', () {
      final violations = lintClockSource(
        source: r'''
// DateTime.now()
const documentation = 'DateTime.now()';
''',
        path: 'lib/core/documentation.dart',
      );

      expect(violations, isEmpty);
    });

    test('reports prefixed DateTime.now calls', () {
      final violations = lintClockSource(
        source: '''
import 'dart:core' as core;
final instant = core.DateTime.now();
''',
        path: 'lib/data/repository.dart',
      );

      expect(violations, hasLength(1));
    });

    test('current production sources comply with the clock contract', () {
      expect(lintClockPaths(const ['lib']), isEmpty);
    });
  });
}

/// Varredura estática do escopo do MVP (tarefa 18.2).
///
/// Falha determinística quando o código de produção reintroduz gamificação,
/// telemetria, cliente HTTP/backend, login/permissões de rede ou reconciliação
/// manual de timer, ou quando ativa por padrão flags que o MVP mantém
/// desligadas. A varredura é textual e conservadora: cada regra procura um
/// padrão específico em `lib/` e ignora comentários de linha para não penalizar
/// documentação (Restrições 6.1, 6.5, 6.6; RNF-02.1, RNF-02.2, RNF-02.3,
/// RNF-03.2; RA-01.4; RD-10; RF-02.19; RF-03.21; RF-06.13).
library;

import 'dart:io';

/// Violação única encontrada pela varredura, com origem legível.
final class MvpScopeViolation {
  const MvpScopeViolation({
    required this.rule,
    required this.path,
    required this.line,
    required this.evidence,
  });

  final String rule;
  final String path;
  final int line;
  final String evidence;

  @override
  String toString() => '$path:$line: [$rule] $evidence';
}

/// Regra de proibição textual aplicada linha a linha ao código de produção.
final class _ForbiddenPattern {
  const _ForbiddenPattern({
    required this.rule,
    required this.pattern,
    this.allowPaths = const <String>[],
  });

  final String rule;
  final RegExp pattern;
  final List<String> allowPaths;

  bool allows(String normalizedPath) => allowPaths.any(normalizedPath.contains);
}

/// Palavras de gamificação recusadas pelo produto (Restrição 6.1, RF-02.19).
///
/// Cada termo é ancorado em fronteira de palavra e casa sem diferenciar
/// maiúsculas para alcançar identificadores, literais e nomes de rota.
final List<_ForbiddenPattern> _antiGamificationPatterns = <_ForbiddenPattern>[
  _ForbiddenPattern(
    rule: 'anti-gamification',
    pattern: RegExp(
      r'\b(streak|streaks|leaderboard|ranking|reward|rewards|badge|badges|'
      r'trophy|trophies|achievement|achievements|points|scoreboard)\b',
      caseSensitive: false,
    ),
  ),
];

/// Dependências e superfícies proibidas no MVP.
///
/// `flutter_local_notifications` e `just_audio` são permitidos porque a Fase 1
/// já os declara como portas locais; o que se proíbe é rede, telemetria,
/// backend e autenticação (RNF-02.1, RNF-02.3).
final List<_ForbiddenPattern> _forbiddenImportPatterns = <_ForbiddenPattern>[
  _ForbiddenPattern(
    rule: 'no-network-client',
    pattern: RegExp(
      r'''^\s*import\s+['"](?:package:(?:http|dio|http2|grpc|web_socket_channel|'''
      r'''googleapis|googleapis_auth|firebase_[a-z_]+|cloud_firestore|'''
      r'''google_sign_in|amplify_[a-z_]+)/|dart:html)''',
      multiLine: false,
    ),
  ),
  _ForbiddenPattern(
    rule: 'no-telemetry',
    pattern: RegExp(
      r'\b(FirebaseAnalytics|Sentry|Crashlytics|Mixpanel|Amplitude|'
      r'PostHog|logEvent|trackEvent|analytics)\b',
    ),
  ),
  _ForbiddenPattern(
    rule: 'no-raw-sockets',
    pattern: RegExp(
      r'\b(HttpClient|Socket\.connect|RawSocket|WebSocket\.connect)\b',
    ),
  ),
];

/// Reconciliação manual de timer é proibida (Restrição 6.6, RD-10).
///
/// A palavra "timer" sozinha é legítima (o `Timer` de agendamento da fronteira),
/// então a regra procura apenas o vocabulário de reconciliação manual.
final List<_ForbiddenPattern> _manualTimerPatterns = <_ForbiddenPattern>[
  _ForbiddenPattern(
    rule: 'no-manual-timer-reconciliation',
    pattern: RegExp(
      r'\b(reconcileTimer|manualTimer|timerReconcil\w*|resumeTimer|'
      r'pauseTimer|timerDuration|elapsedTimer)\b',
    ),
  ),
];

/// Ativações padrão que o MVP mantém desligadas (RA-01.4, RF-08 blackout).
final List<_ForbiddenPattern> _defaultFlagPatterns = <_ForbiddenPattern>[
  _ForbiddenPattern(
    rule: 'sync-flag-must-default-off',
    pattern: RegExp(r'sync_enabled[^\n]*?\b(TRUE|1)\b', caseSensitive: false),
    allowPaths: <String>[],
  ),
  _ForbiddenPattern(
    rule: 'sunday-notification-must-default-off',
    pattern: RegExp(
      r'sunday_notification_enabled[^\n]*?\b(TRUE|1)\b',
      caseSensitive: false,
    ),
  ),
];

/// Identificadores de destino/rota que pertencem a fases ainda não habilitadas
/// e não podem ser registrados como rotas invocáveis (RF-06.13, RA-01.10).
///
/// Pessoas e a Revisão Semanal foram habilitadas na Fase 2 (tarefas 20.9 e
/// 21.1). O editor de ciclos (tarefa 24.1) e o fluxo de Encerramento de Ciclo
/// (tarefa 24.3) foram habilitados na Fase 3 e saíram desta lista. A Exportação
/// permanece sem rota invocável até a tarefa 24.8.
const List<String> _futurePhaseRouteTokens = <String>[
  'export',
  'exportacao',
  'exportação',
];

/// Resultado agregado da varredura para consumo por testes e CLI.
final class MvpScopeReport {
  const MvpScopeReport({required this.violations, required this.scannedFiles});

  final List<MvpScopeViolation> violations;
  final int scannedFiles;

  bool get isClean => violations.isEmpty;
}

/// Executa todas as regras textuais sobre [source] atribuído a [path].
///
/// Comentários de linha iniciados por `//` são removidos antes da checagem de
/// padrões de conteúdo, preservando a intenção documental. Regras de import
/// operam sobre a linha íntegra porque diretivas nunca são comentadas.
List<MvpScopeViolation> scanMvpScopeSource({
  required String source,
  required String path,
}) {
  final normalizedPath = path.replaceAll('\\', '/');
  final lines = source.split('\n');
  final violations = <MvpScopeViolation>[];

  for (var index = 0; index < lines.length; index++) {
    final rawLine = lines[index];
    final lineNumber = index + 1;
    final withoutComment = _stripLineComment(rawLine);

    for (final rule in _forbiddenImportPatterns) {
      if (rule.allows(normalizedPath)) continue;
      if (rule.pattern.hasMatch(rawLine)) {
        violations.add(
          MvpScopeViolation(
            rule: rule.rule,
            path: normalizedPath,
            line: lineNumber,
            evidence: rawLine.trim(),
          ),
        );
      }
    }

    for (final rule in <_ForbiddenPattern>[
      ..._antiGamificationPatterns,
      ..._manualTimerPatterns,
      ..._defaultFlagPatterns,
    ]) {
      if (rule.allows(normalizedPath)) continue;
      final match = rule.pattern.firstMatch(withoutComment);
      if (match != null) {
        violations.add(
          MvpScopeViolation(
            rule: rule.rule,
            path: normalizedPath,
            line: lineNumber,
            evidence: match.group(0) ?? withoutComment.trim(),
          ),
        );
      }
    }
  }

  return violations;
}

/// Varredura recursiva de diretórios e arquivos `.dart` de produção.
MvpScopeReport scanMvpScopePaths(Iterable<String> paths) {
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
            .where(
              (file) =>
                  file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'),
            ),
      );
    }
  }

  files.sort((left, right) => left.path.compareTo(right.path));
  final violations = <MvpScopeViolation>[
    for (final file in files)
      ...scanMvpScopeSource(source: file.readAsStringSync(), path: file.path),
  ];
  return MvpScopeReport(violations: violations, scannedFiles: files.length);
}

/// Identificadores de fase futura registrados como rota invocável, extraídos do
/// arquivo do roteador. Detecta `GoRoute(... path: '/...' ...)` cujo caminho ou
/// nome contenha um token proibido; a `RouteUnavailableScreen` é permitida.
List<MvpScopeViolation> findGatedRouteRegistrations({
  required String routerSource,
  required String path,
}) {
  final normalizedPath = path.replaceAll('\\', '/');
  final violations = <MvpScopeViolation>[];
  final routePattern = RegExp(
    '''(?:path|name):\\s*['"]([^'"]+)['"]''',
    caseSensitive: false,
  );
  final lines = routerSource.split('\n');
  for (var index = 0; index < lines.length; index++) {
    final withoutComment = _stripLineComment(lines[index]);
    for (final match in routePattern.allMatches(withoutComment)) {
      final value = (match.group(1) ?? '').toLowerCase();
      final collapsed = value.replaceAll(RegExp(r'[\s_/-]'), '');
      for (final token in _futurePhaseRouteTokens) {
        final collapsedToken = token.replaceAll(RegExp(r'[\s_/-]'), '');
        if (collapsed.contains(collapsedToken)) {
          violations.add(
            MvpScopeViolation(
              rule: 'no-future-phase-route',
              path: normalizedPath,
              line: index + 1,
              evidence: match.group(0) ?? value,
            ),
          );
        }
      }
    }
  }
  return violations;
}

String _stripLineComment(String line) {
  final index = _lineCommentIndex(line);
  return index < 0 ? line : line.substring(0, index);
}

/// Índice do `//` que inicia um comentário, ignorando `//` dentro de literais
/// de string simples. É uma heurística suficiente para código formatado.
int _lineCommentIndex(String line) {
  var inSingle = false;
  var inDouble = false;
  for (var i = 0; i < line.length - 1; i++) {
    final char = line[i];
    if (char == "'" && !inDouble) inSingle = !inSingle;
    if (char == '"' && !inSingle) inDouble = !inDouble;
    if (!inSingle && !inDouble && char == '/' && line[i + 1] == '/') {
      return i;
    }
  }
  return -1;
}

void main(List<String> arguments) {
  final targets = arguments.isEmpty ? const ['lib'] : arguments;
  final report = scanMvpScopePaths(targets);

  if (report.isClean) {
    stdout.writeln(
      'mvp_scope_check: ${report.scannedFiles} file(s) scanned; '
      'no out-of-scope patterns found.',
    );
    return;
  }

  stderr.writeln(
    'mvp_scope_check: ${report.violations.length} out-of-scope pattern(s):',
  );
  for (final violation in report.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}

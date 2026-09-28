// Feature: ritmo, Property 48: Limite do manifesto em bytes UTF-8
//
// Para qualquer conteúdo Markdown, save aceita se e somente se a codificação
// UTF-8 ocupa no máximo 1 MiB. A rejeição informa o limite exato e não observa
// nem altera dependências externas ou a cópia local previamente válida.
//
// **Validates: Requirements RD-34, RNF-05.7, RF-09.4**

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test;
import 'package:ritmo/core/limits.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/manifest/manifest_service.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

typedef _Utf8Atom = ({String value, int bytes});
typedef _SmallManifestCase = ({int atomIndex, int repetitions, int asciiTail});
typedef _ManifestSnapshot = ({
  String id,
  String contentMarkdown,
  String assetVersion,
  int firstCopiedAtMicros,
  int? lastEditedAtMicros,
});
typedef _SaveRequest = ({String id, String contentMarkdown, DateTime editedAt});

const List<_Utf8Atom> _utf8Atoms = <_Utf8Atom>[
  (value: 'a', bytes: 1),
  (value: 'á', bytes: 2),
  (value: '€', bytes: 3),
  (value: '😀', bytes: 4),
];

final Generator<_SmallManifestCase> _anySmallManifestCase = any.simple(
  generate: (Random random, int size) {
    final width = max(1, min(size + 1, 128));
    return (
      atomIndex: random.nextInt(_utf8Atoms.length),
      repetitions: random.nextInt(width),
      asciiTail: random.nextInt(9),
    );
  },
  shrink: (_SmallManifestCase value) sync* {
    if (value != (atomIndex: 0, repetitions: 0, asciiTail: 0)) {
      yield (atomIndex: 0, repetitions: 0, asciiTail: 0);
    }
  },
);

_ManifestSnapshot _snapshot(Manifest manifest) => (
  id: manifest.id,
  contentMarkdown: manifest.contentMarkdown,
  assetVersion: manifest.assetVersion,
  firstCopiedAtMicros: manifest.firstCopiedAt.microsecondsSinceEpoch,
  lastEditedAtMicros: manifest.lastEditedAt?.microsecondsSinceEpoch,
);

final class _RecordingOperationalClock implements OperationalClock {
  _RecordingOperationalClock(this.instant);

  final tz.TZDateTime instant;
  int nowCalls = 0;

  @override
  tz.TZDateTime nowInBusinessZone() {
    nowCalls++;
    return instant;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'ManifestService não deveria chamar ${invocation.memberName} neste teste',
  );
}

final class _ObservingManifestAssetLoader implements ManifestAssetLoader {
  int loadCalls = 0;

  @override
  Future<ManifestAsset> load() {
    loadCalls++;
    return Future<ManifestAsset>.error(
      StateError('asset não deveria ser consultado com cópia local válida'),
    );
  }
}

final class _RecordingManifestRepository implements ManifestRepository {
  _RecordingManifestRepository(this.stored);

  Manifest? stored;
  int findCalls = 0;
  int insertAttempts = 0;
  int successfulInsertions = 0;
  int saveCalls = 0;
  final List<String> findIds = <String>[];
  final List<_SaveRequest> saveRequests = <_SaveRequest>[];

  @override
  Future<Manifest?> findById(String id) {
    findCalls++;
    findIds.add(id);
    return Future<Manifest?>.value(stored);
  }

  @override
  Future<Manifest> insertIfAbsent(Manifest manifest) {
    insertAttempts++;
    final existing = stored;
    if (existing != null) return Future<Manifest>.value(existing);
    stored = manifest;
    successfulInsertions++;
    return Future<Manifest>.value(manifest);
  }

  @override
  Future<Manifest> saveEdit({
    required String id,
    required String contentMarkdown,
    required DateTime editedAt,
  }) {
    saveCalls++;
    saveRequests.add((
      id: id,
      contentMarkdown: contentMarkdown,
      editedAt: editedAt,
    ));

    final current = stored;
    if (current == null) {
      return Future<Manifest>.error(StateError('manifesto ausente'));
    }
    final saved = Manifest(
      id: id,
      contentMarkdown: contentMarkdown,
      assetVersion: current.assetVersion,
      firstCopiedAt: current.firstCopiedAt,
      lastEditedAt: editedAt,
    );
    stored = saved;
    return Future<Manifest>.value(saved);
  }
}

String _repeatSmall(_Utf8Atom atom, int repetitions, int asciiTail) =>
    '${List<String>.filled(repetitions, atom.value, growable: false).join()}'
    '${List<String>.filled(asciiTail, 'x', growable: false).join()}';

/// Materializa exatamente [targetBytes] sem criar uma lista com um milhão de
/// elementos. O bloco intermediário tem no máximo 4096 átomos e é reutilizado.
String _textWithExactUtf8Bytes(_Utf8Atom atom, int targetBytes) {
  if (targetBytes < 0) throw ArgumentError.value(targetBytes, 'targetBytes');
  if (targetBytes == 0) return '';

  final atomCount = targetBytes ~/ atom.bytes;
  final remainder = targetBytes % atom.bytes;
  final chunkAtomCount = min(atomCount, 4096);
  final chunk = List<String>.filled(
    chunkAtomCount,
    atom.value,
    growable: false,
  ).join();
  final buffer = StringBuffer();
  var remainingAtoms = atomCount;

  while (remainingAtoms >= chunkAtomCount) {
    buffer.write(chunk);
    remainingAtoms -= chunkAtomCount;
  }
  if (remainingAtoms > 0) {
    buffer.write(
      List<String>.filled(remainingAtoms, atom.value, growable: false).join(),
    );
  }
  if (remainder > 0) {
    buffer.write(List<String>.filled(remainder, 'a', growable: false).join());
  }
  return buffer.toString();
}

Future<void> _verifySave({
  required String markdown,
  required int expectedBytes,
  required String context,
}) async {
  expect(utf8.encode(markdown).length, expectedBytes, reason: context);

  final original = Manifest(
    id: ManifestService.manifestId,
    contentMarkdown: '# cópia válida anterior',
    assetVersion: 'asset-preservado-v7',
    firstCopiedAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
    lastEditedAt: DateTime.utc(2025, 2, 3, 4, 5, 6),
  );
  final before = _snapshot(original);
  final repository = _RecordingManifestRepository(original);
  final loader = _ObservingManifestAssetLoader();
  final clock = _RecordingOperationalClock(tz.TZDateTime.utc(2026, 4, 5, 6));
  final service = ManifestService(repository, loader, clock: clock);

  final result = await service.save(markdown);
  if (expectedBytes <= Limits.manifestMaxUtf8Bytes) {
    expect(result, isA<Success<Manifest, LimitViolation>>(), reason: context);
    final saved = (result as Success<Manifest, LimitViolation>).value;
    final persisted = repository.stored!;
    final request = repository.saveRequests.single;

    // Comparações booleanas evitam despejar um payload de 1 MiB no relatório.
    expect(saved.contentMarkdown == markdown, isTrue, reason: context);
    expect(persisted.contentMarkdown == markdown, isTrue, reason: context);
    expect(request.contentMarkdown == markdown, isTrue, reason: context);
    expect(saved.assetVersion, original.assetVersion, reason: context);
    expect(persisted.assetVersion, original.assetVersion, reason: context);
    expect(
      saved.firstCopiedAt.microsecondsSinceEpoch,
      original.firstCopiedAt.microsecondsSinceEpoch,
      reason: context,
    );
    expect(
      persisted.firstCopiedAt.microsecondsSinceEpoch,
      original.firstCopiedAt.microsecondsSinceEpoch,
      reason: context,
    );
    expect(
      saved.lastEditedAt?.microsecondsSinceEpoch,
      clock.instant.microsecondsSinceEpoch,
      reason: context,
    );
    expect(request.id, ManifestService.manifestId, reason: context);
    expect(
      request.editedAt.microsecondsSinceEpoch,
      clock.instant.microsecondsSinceEpoch,
      reason: context,
    );
    expect(repository.findCalls, 1, reason: context);
    expect(repository.findIds, <String>[ManifestService.manifestId]);
    expect(repository.insertAttempts, 0, reason: context);
    expect(repository.successfulInsertions, 0, reason: context);
    expect(repository.saveCalls, 1, reason: context);
    expect(loader.loadCalls, 0, reason: context);
    expect(clock.nowCalls, 1, reason: context);
    return;
  }

  expect(result, isA<Failure<Manifest, LimitViolation>>(), reason: context);
  final violation = (result as Failure<Manifest, LimitViolation>).failure;
  expect(violation.actual, expectedBytes, reason: context);
  expect(violation.maximum, Limits.manifestMaxUtf8Bytes, reason: context);
  expect(violation.unit, LimitUnit.utf8Bytes, reason: context);
  expect(_snapshot(repository.stored!), before, reason: context);
  expect(repository.findCalls, 0, reason: context);
  expect(repository.findIds, isEmpty, reason: context);
  expect(repository.insertAttempts, 0, reason: context);
  expect(repository.successfulInsertions, 0, reason: context);
  expect(repository.saveCalls, 0, reason: context);
  expect(repository.saveRequests, isEmpty, reason: context);
  expect(loader.loadCalls, 0, reason: context);
  expect(clock.nowCalls, 0, reason: context);
}

void main() {
  Glados<_SmallManifestCase>(_anySmallManifestCase, RitmoGlados.ci()).test(
    'Propriedade 48: save respeita o tamanho UTF-8 exato',
    (_SmallManifestCase input) async {
      final atom = _utf8Atoms[input.atomIndex];
      final markdown = _repeatSmall(atom, input.repetitions, input.asciiTail);
      final expectedBytes = atom.bytes * input.repetitions + input.asciiTail;
      await _verifySave(
        markdown: markdown,
        expectedBytes: expectedBytes,
        context:
            'pequeno: átomo ${atom.bytes}B, '
            '${input.repetitions} repetições, cauda ${input.asciiTail}B',
      );
    },
  );

  // Matriz compartilhada executada uma única vez, fora das 100 entradas. Cada
  // payload é criado, validado e liberado antes do próximo caso.
  test(
    'Propriedade 48: matriz max-1/max/max+1 para átomos de 1, 2, 3 e 4 bytes',
    () async {
      const targets = <int>[
        Limits.manifestMaxUtf8Bytes - 1,
        Limits.manifestMaxUtf8Bytes,
        Limits.manifestMaxUtf8Bytes + 1,
      ];

      for (final atom in _utf8Atoms) {
        expect(utf8.encode(atom.value).length, atom.bytes);
        for (final target in targets) {
          final markdown = _textWithExactUtf8Bytes(atom, target);
          await _verifySave(
            markdown: markdown,
            expectedBytes: target,
            context: 'fronteira: átomo ${atom.bytes}B, alvo $target bytes',
          );
        }
      }
    },
  );
}

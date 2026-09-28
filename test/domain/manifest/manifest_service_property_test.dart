// Feature: ritmo, Property 44: A cópia local do manifesto é idempotente e
// nunca sobrescrita
//
// Para qualquer conteúdo local e qualquer número de garantias/leitura, a
// cópia local prevalece mesmo após troca do asset. Sem cópia, o asset é apenas
// fallback de leitura; a primeira garantia fixa o asset vigente e inserções
// concorrentes convergem para uma única linha.
//
// **Validates: Requirements RF-09.2, RF-09.3, RF-09.5, RF-09.13**

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/manifest/manifest_service.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

typedef _AssetFixture = ({String markdown, String version});
typedef _ManifestCase = ({
  String localMarkdown,
  String localVersion,
  _AssetFixture firstAsset,
  _AssetFixture secondAsset,
  _AssetFixture fallbackAsset,
  int repetitions,
  int concurrency,
});
typedef _ManifestSnapshot = ({
  String id,
  String contentMarkdown,
  String assetVersion,
  int firstCopiedAtMicros,
  int? lastEditedAtMicros,
});
typedef _AssetTransform =
    ManifestAsset Function(ManifestAsset current, int callIndex);

const _ManifestCase _minimalCase = (
  localMarkdown: '# local\n\n> edição preservada',
  localVersion: 'local-v0',
  firstAsset: (markdown: '# asset inicial', version: 'asset-v1'),
  secondAsset: (markdown: '# asset atualizado', version: 'asset-v2'),
  fallbackAsset: (markdown: '# asset fallback', version: 'asset-v3'),
  repetitions: 1,
  concurrency: 2,
);

final Generator<_ManifestCase> _anyManifestCase = any.simple(
  generate: (Random random, int size) {
    final width = max(1, min(size + 1, 8));
    final token = random.nextInt(1 << 30);
    return (
      localMarkdown: _markdown(random, width, 'local-$token'),
      localVersion: 'local-$token',
      firstAsset: (
        markdown: _markdown(random, width, 'asset-inicial-$token'),
        version: 'asset-v1-$token',
      ),
      secondAsset: (
        markdown: _markdown(random, width, 'asset-atualizado-$token'),
        version: 'asset-v2-$token',
      ),
      fallbackAsset: (
        markdown: _markdown(random, width, 'asset-fallback-$token'),
        version: 'asset-v3-$token',
      ),
      repetitions: 1 + random.nextInt(width),
      concurrency: 2 + random.nextInt(max(1, min(width, 7))),
    );
  },
  shrink: (_ManifestCase value) sync* {
    if (value != _minimalCase) yield _minimalCase;
  },
);

String _markdown(Random random, int width, String label) {
  const atoms = <String>['a', 'á', '€', '😀'];
  final atom = atoms[random.nextInt(atoms.length)];
  final body = List<String>.filled(
    1 + random.nextInt(width),
    atom,
    growable: false,
  ).join();
  return '# $label\n\n> $body';
}

ManifestAsset _asset(_AssetFixture fixture) =>
    ManifestAsset(contentMarkdown: fixture.markdown, version: fixture.version);

_ManifestSnapshot _snapshot(Manifest manifest) => (
  id: manifest.id,
  contentMarkdown: manifest.contentMarkdown,
  assetVersion: manifest.assetVersion,
  firstCopiedAtMicros: manifest.firstCopiedAt.microsecondsSinceEpoch,
  lastEditedAtMicros: manifest.lastEditedAt?.microsecondsSinceEpoch,
);

final class _RecordingOperationalClock implements OperationalClock {
  _RecordingOperationalClock(this._firstInstant);

  final tz.TZDateTime _firstInstant;
  final List<tz.TZDateTime> observedInstants = <tz.TZDateTime>[];

  int get nowCalls => observedInstants.length;

  @override
  tz.TZDateTime nowInBusinessZone() {
    final instant = _firstInstant.add(
      Duration(microseconds: observedInstants.length),
    );
    observedInstants.add(instant);
    return instant;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'ManifestService não deveria chamar ${invocation.memberName} neste teste',
  );
}

final class _RecordingManifestAssetLoader implements ManifestAssetLoader {
  _RecordingManifestAssetLoader(this.current, {this.transform});

  ManifestAsset current;
  _AssetTransform? transform;
  int loadCalls = 0;
  final List<ManifestAsset> loadedAssets = <ManifestAsset>[];

  @override
  Future<ManifestAsset> load() {
    final callIndex = loadCalls++;
    final loaded = transform?.call(current, callIndex) ?? current;
    loadedAssets.add(loaded);
    return Future<ManifestAsset>.value(loaded);
  }
}

final class _RecordingManifestRepository implements ManifestRepository {
  _RecordingManifestRepository([this.stored]);

  Manifest? stored;
  int findCalls = 0;
  int insertAttempts = 0;
  int successfulInsertions = 0;
  int saveCalls = 0;
  final List<String> findIds = <String>[];
  final List<Manifest> insertCandidates = <Manifest>[];

  Object? _nextFindFailure;
  int _findsToBlock = 0;
  Completer<void>? _allFindsBlocked;
  Completer<void>? _releaseFinds;

  void failNextFind() {
    if (_nextFindFailure != null) {
      throw StateError('já existe uma falha de leitura armada');
    }
    _nextFindFailure = StateError('armazenamento temporariamente indisponível');
  }

  void blockNextFinds(int count) {
    if (count < 1 || _findsToBlock != 0) {
      throw StateError('barreira de leitura inválida');
    }
    _findsToBlock = count;
    _allFindsBlocked = Completer<void>();
    _releaseFinds = Completer<void>();
  }

  Future<void> waitUntilFindsAreBlocked() {
    final blocked = _allFindsBlocked;
    if (blocked == null) throw StateError('barreira não armada');
    return blocked.future;
  }

  void releaseBlockedFinds() {
    final blocked = _allFindsBlocked;
    final release = _releaseFinds;
    if (blocked == null || !blocked.isCompleted || release == null) {
      throw StateError('nem todas as leituras chegaram à barreira');
    }
    if (!release.isCompleted) release.complete();
  }

  @override
  Future<Manifest?> findById(String id) async {
    findCalls++;
    findIds.add(id);

    final failure = _nextFindFailure;
    if (failure != null) {
      _nextFindFailure = null;
      throw failure;
    }

    // Captura antes da espera: todas as chamadas bloqueadas observam a mesma
    // ausência, forçando a decisão final para insertIfAbsent.
    final visible = stored;
    if (_findsToBlock > 0) {
      _findsToBlock--;
      if (_findsToBlock == 0) _allFindsBlocked!.complete();
      await _releaseFinds!.future;
    }
    return visible;
  }

  @override
  Future<Manifest> insertIfAbsent(Manifest manifest) {
    insertAttempts++;
    insertCandidates.add(manifest);

    final winner = stored;
    if (winner != null) return Future<Manifest>.value(winner);

    // Não há await entre observar e atribuir: esta é a seção atômica do fake.
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

Future<void> _verifyExistingCopyIsNeverOverwritten(_ManifestCase input) async {
  final existing = Manifest(
    id: ManifestService.manifestId,
    contentMarkdown: input.localMarkdown,
    assetVersion: input.localVersion,
    firstCopiedAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
    lastEditedAt: DateTime.utc(2025, 2, 3, 4, 5, 6),
  );
  final expected = _snapshot(existing);
  final repository = _RecordingManifestRepository(existing);
  final loader = _RecordingManifestAssetLoader(_asset(input.firstAsset));
  final clock = _RecordingOperationalClock(tz.TZDateTime.utc(2026, 1, 1));
  final service = ManifestService(repository, loader, clock: clock);

  for (var index = 0; index < input.repetitions; index++) {
    loader.current = _asset(
      index.isEven ? input.firstAsset : input.secondAsset,
    );
    final context = 'cópia existente, repetição $index';

    if (index.isEven) {
      expect(
        _snapshot(await service.ensureLocalCopy()),
        expected,
        reason: context,
      );
      expect(
        await service.readForDisplay(),
        input.localMarkdown,
        reason: context,
      );
    } else {
      expect(
        await service.readForDisplay(),
        input.localMarkdown,
        reason: context,
      );
      expect(
        _snapshot(await service.ensureLocalCopy()),
        expected,
        reason: context,
      );
    }
    expect(_snapshot(repository.stored!), expected, reason: context);
  }

  // A troca é obrigatória mesmo quando o caso gerado pede só uma repetição.
  loader.current = _asset(input.secondAsset);
  expect(_snapshot(await service.ensureLocalCopy()), expected);
  expect(await service.readForDisplay(), input.localMarkdown);
  expect(_snapshot(repository.stored!), expected);
  expect(loader.loadCalls, 0);
  expect(repository.insertAttempts, 0);
  expect(repository.saveCalls, 0);
  expect(clock.nowCalls, 0);

  // Uma indisponibilidade transitória usa o asset sem apagar nem substituir a
  // linha local já editada.
  loader.current = _asset(input.fallbackAsset);
  repository.failNextFind();
  expect(await service.readForDisplay(), input.fallbackAsset.markdown);
  expect(_snapshot(repository.stored!), expected);
  expect(loader.loadCalls, 1);
  expect(repository.insertAttempts, 0);
  expect(repository.saveCalls, 0);
  expect(clock.nowCalls, 0);

  expect(await service.readForDisplay(), input.localMarkdown);
  expect(_snapshot(repository.stored!), expected);
  expect(loader.loadCalls, 1);
  expect(
    repository.findIds.every((id) => id == ManifestService.manifestId),
    isTrue,
  );
}

Future<void> _verifyReadFallbackAndFirstCopy(_ManifestCase input) async {
  final repository = _RecordingManifestRepository();
  final loader = _RecordingManifestAssetLoader(_asset(input.firstAsset));
  final clock = _RecordingOperationalClock(tz.TZDateTime.utc(2026, 2, 3, 4));
  final service = ManifestService(repository, loader, clock: clock);

  expect(await service.readForDisplay(), input.firstAsset.markdown);
  expect(repository.stored, isNull);
  expect(repository.insertAttempts, 0);
  expect(clock.nowCalls, 0);

  loader.current = _asset(input.secondAsset);
  expect(await service.readForDisplay(), input.secondAsset.markdown);
  expect(repository.stored, isNull);
  expect(repository.insertAttempts, 0);
  expect(clock.nowCalls, 0);

  final firstCopy = await service.ensureLocalCopy();
  final firstSnapshot = _snapshot(firstCopy);
  expect(firstCopy.contentMarkdown, input.secondAsset.markdown);
  expect(firstCopy.assetVersion, input.secondAsset.version);
  expect(
    firstCopy.firstCopiedAt.microsecondsSinceEpoch,
    clock.observedInstants.single.microsecondsSinceEpoch,
  );
  expect(_snapshot(repository.stored!), firstSnapshot);
  expect(loader.loadCalls, 3);
  expect(repository.insertAttempts, 1);
  expect(repository.successfulInsertions, 1);
  expect(clock.nowCalls, 1);

  loader.current = _asset(input.fallbackAsset);
  for (var index = 0; index < input.repetitions; index++) {
    final context = 'primeira cópia fixada, repetição $index';
    expect(
      _snapshot(await service.ensureLocalCopy()),
      firstSnapshot,
      reason: context,
    );
    expect(
      await service.readForDisplay(),
      input.secondAsset.markdown,
      reason: context,
    );
    expect(_snapshot(repository.stored!), firstSnapshot, reason: context);
  }

  expect(loader.loadCalls, 3);
  expect(repository.insertAttempts, 1);
  expect(repository.successfulInsertions, 1);
  expect(repository.saveCalls, 0);
  expect(clock.nowCalls, 1);
}

Future<void> _verifyConcurrentCallsConverge(_ManifestCase input) async {
  final repository = _RecordingManifestRepository()
    ..blockNextFinds(input.concurrency);
  final loader = _RecordingManifestAssetLoader(
    _asset(input.firstAsset),
    transform: (ManifestAsset current, int callIndex) => ManifestAsset(
      contentMarkdown: '${current.contentMarkdown}\n\nconcorrente-$callIndex',
      version: '${current.version}-$callIndex',
    ),
  );
  final clock = _RecordingOperationalClock(tz.TZDateTime.utc(2026, 3, 4, 5));
  final service = ManifestService(repository, loader, clock: clock);

  final pending = List<Future<Manifest>>.generate(
    input.concurrency,
    (_) => service.ensureLocalCopy(),
    growable: false,
  );
  await repository.waitUntilFindsAreBlocked();
  repository.releaseBlockedFinds();
  final results = await Future.wait<Manifest>(pending);

  final winner = _snapshot(repository.stored!);
  final resultSnapshots = results.map(_snapshot).toSet();
  final candidateSnapshots = repository.insertCandidates.map(_snapshot).toSet();
  final loadedAssets = loader.loadedAssets
      .map(
        (asset) =>
            (contentMarkdown: asset.contentMarkdown, version: asset.version),
      )
      .toSet();

  expect(resultSnapshots, hasLength(1));
  expect(resultSnapshots.single, winner);
  expect(candidateSnapshots, hasLength(input.concurrency));
  expect(candidateSnapshots, contains(winner));
  expect(loadedAssets, hasLength(input.concurrency));
  expect(repository.findCalls, input.concurrency);
  expect(repository.insertAttempts, input.concurrency);
  expect(repository.successfulInsertions, 1);
  expect(loader.loadCalls, input.concurrency);
  expect(clock.nowCalls, input.concurrency);
  expect(repository.saveCalls, 0);

  // Depois da corrida, nem uma nova versão do asset nem novas chamadas mudam
  // a única linha vencedora.
  loader
    ..transform = null
    ..current = _asset(input.secondAsset);
  final loadsAfterRace = loader.loadCalls;
  final insertionsAfterRace = repository.insertAttempts;
  final clockReadsAfterRace = clock.nowCalls;
  for (var index = 0; index < input.repetitions; index++) {
    expect(_snapshot(await service.ensureLocalCopy()), winner);
    expect(await service.readForDisplay(), winner.contentMarkdown);
    expect(_snapshot(repository.stored!), winner);
  }
  expect(loader.loadCalls, loadsAfterRace);
  expect(repository.insertAttempts, insertionsAfterRace);
  expect(clock.nowCalls, clockReadsAfterRace);

  // O fallback causado por uma falha de leitura também é estritamente efêmero.
  loader.current = _asset(input.fallbackAsset);
  repository.failNextFind();
  expect(await service.readForDisplay(), input.fallbackAsset.markdown);
  expect(_snapshot(repository.stored!), winner);
  expect(loader.loadCalls, loadsAfterRace + 1);
  expect(repository.insertAttempts, insertionsAfterRace);
  expect(clock.nowCalls, clockReadsAfterRace);

  expect(await service.readForDisplay(), winner.contentMarkdown);
  expect(_snapshot(repository.stored!), winner);
  expect(loader.loadCalls, loadsAfterRace + 1);
  expect(
    repository.findIds.every((id) => id == ManifestService.manifestId),
    isTrue,
  );
}

void main() {
  Glados<_ManifestCase>(_anyManifestCase, RitmoGlados.ci()).test(
    'Propriedade 44: cópia local idempotente e nunca sobrescrita',
    (_ManifestCase input) async {
      await _verifyExistingCopyIsNeverOverwritten(input);
      await _verifyReadFallbackAndFirstCopy(input);
      await _verifyConcurrentCallsConverge(input);
    },
  );
}

/// Dobras controladas usadas por todos os testes do Ritmo.
///
/// Nenhuma delas consulta relógio real, disco real, notificação real ou áudio
/// real. Cada dobra é determinística e observável, o que permite escrever
/// propriedades sobre o domínio sem emulador (RNF-04.1, RNF-04.2).
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

/// Relógio controlado por testes, sem espera real nem consulta ao aparelho.
///
/// O instante é uma coordenada civil do fuso oficial, na mesma convenção de
/// `CivilMoment.toCivilDateTime()`: o flag UTC é apenas invólucro.
final class FakeClock {
  FakeClock(
    DateTime civilInstant, {
    this.deviceZoneId = kBusinessTimeZone,
    this.calendar = const OperationalCalendar.seed(),
  }) : _instant = civilInstant.toUtc();

  DateTime _instant;
  String deviceZoneId;
  final OperationalCalendar calendar;

  DateTime get now => _instant;

  bool get deviceZoneDiverges => deviceZoneId != kBusinessTimeZone;

  /// Data operacional vigente segundo o `day_close_time` configurado.
  OperationalDate get operationalDate => calendar.operationalDateOf(_instant);

  /// Coordenada civil corrente (data civil + hora local).
  CivilMoment get civilMoment => CivilMoment(
    date: OperationalDate.fromCivilDateTime(_instant),
    time: LocalTimeOfDay.fromDateTime(_instant),
  );

  void set(DateTime civilInstant) => _instant = civilInstant.toUtc();
  void advance(Duration duration) => _instant = _instant.add(duration);
  void rewind(Duration duration) => _instant = _instant.subtract(duration);

  /// Salta para a fronteira que encerra a data operacional corrente.
  void advanceToOperationalClose() =>
      _instant = calendar.operationalClose(operationalDate).toCivilDateTime();
}

/// Banco drift/SQLite em memória, já aberto e pronto para SQL real.
///
/// Substitui o arquivo do diretório privado do aplicativo sem mudar o dialeto:
/// os mesmos `CHECK`s, índices únicos parciais e chaves estrangeiras valem aqui
/// (RNF-04.6). Cada instância é isolada e some ao ser fechada.
final class InMemoryDatabase {
  InMemoryDatabase._(this.executor, this._user);

  /// Abre um executor isolado, com `PRAGMA foreign_keys` ligado como em
  /// produção. Precisa ser aguardado: drift exige `ensureOpen` antes de
  /// qualquer operação.
  static Future<InMemoryDatabase> open({int schemaVersion = 1}) async {
    final user = _InMemorySchema(schemaVersion);
    final executor = NativeDatabase.memory(
      setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
    );
    await executor.ensureOpen(user);
    return InMemoryDatabase._(executor, user);
  }

  final QueryExecutor executor;
  final _InMemorySchema _user;

  int get schemaVersion => _user.schemaVersion;

  /// DDL e comandos sem retorno.
  Future<void> execute(String sql, [List<Object?> args = const []]) =>
      executor.runCustom(sql, args);

  Future<List<Map<String, Object?>>> select(
    String sql, [
    List<Object?> args = const [],
  ]) => executor.runSelect(sql, args);

  /// Retorna o `rowid` inserido.
  Future<int> insert(String sql, [List<Object?> args = const []]) =>
      executor.runInsert(sql, args);

  /// Número de linhas afetadas.
  Future<int> update(String sql, [List<Object?> args = const []]) =>
      executor.runUpdate(sql, args);

  /// Executa [body] em uma transação: confirma no retorno normal e desfaz por
  /// completo quando [body] lança, sem escrita parcial (RNF-05.8).
  Future<T> transaction<T>(Future<T> Function(QueryExecutor tx) body) async {
    final tx = executor.beginTransaction();
    await tx.ensureOpen(_user);
    try {
      final result = await body(tx);
      await tx.send();
      return result;
    } catch (_) {
      await tx.rollback();
      rethrow;
    }
  }

  Future<void> close() => executor.close();
}

/// Usuário mínimo exigido por `QueryExecutor.ensureOpen`. O schema real é
/// criado pelo próprio teste (ou pelo futuro `RitmoDatabase`).
final class _InMemorySchema implements QueryExecutorUser {
  const _InMemorySchema(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

typedef RecordedNotification = ({
  String key,
  DateTime scheduledFor,
  String? payload,
});

/// Gateway de notificação que apenas registra o que teria sido agendado.
/// Nenhum push sai daqui; a lista é a asserção.
final class RecordingNotificationGateway {
  final List<RecordedNotification> scheduled = [];
  final List<String> cancelledKeys = [];
  NotificationFailure? failNext;

  Future<void> schedule({
    required String key,
    required DateTime scheduledFor,
    String? payload,
  }) async {
    _throwPendingFailure();
    scheduled.add((
      key: key,
      scheduledFor: scheduledFor.toUtc(),
      payload: payload,
    ));
  }

  Future<void> cancel(String key) async {
    _throwPendingFailure();
    cancelledKeys.add(key);
    scheduled.removeWhere((entry) => entry.key == key);
  }

  void clear() {
    scheduled.clear();
    cancelledKeys.clear();
    failNext = null;
  }

  void _throwPendingFailure() {
    final failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
  }
}

/// Armazenamento local em memória com capacidade configurável, para exercitar
/// o caminho de "espaço insuficiente" sem encher o disco do desenvolvedor.
final class FakeFileStore {
  FakeFileStore({required this.capacityBytes});

  int capacityBytes;
  final Map<String, Uint8List> _files = {};
  StorageFailure? failNext;

  int get usedBytes =>
      _files.values.fold(0, (sum, bytes) => sum + bytes.length);
  int get freeBytes => capacityBytes - usedBytes;
  bool exists(String path) => _files.containsKey(path);
  List<String> get paths => _files.keys.toList(growable: false);

  Uint8List? read(String path) {
    final bytes = _files[path];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  /// Escrita tudo-ou-nada: no estouro de capacidade nada é gravado.
  Future<void> write(String path, List<int> bytes) async {
    _throwPendingFailure();
    final previousLength = _files[path]?.length ?? 0;
    final requiredBytes = bytes.length - previousLength;
    if (requiredBytes > freeBytes) {
      throw StorageFailure(
        message: 'Espaço local insuficiente para concluir a gravação.',
      );
    }
    _files[path] = Uint8List.fromList(bytes);
  }

  Future<void> delete(String path) async {
    _throwPendingFailure();
    _files.remove(path);
  }

  void clear() {
    _files.clear();
    failNext = null;
  }

  void _throwPendingFailure() {
    final failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
  }
}

enum FakeAudioState { idle, playing, recording, completed }

/// Áudio local determinístico: reprodução do briefing MP3 e gravação de nota,
/// sem rede e sem plugin de plataforma (RF-01.6).
final class FakeAudioGateway {
  FakeAudioGateway({this.availableRecordingBytes = 1 << 30});

  int availableRecordingBytes;
  FakeAudioState state = FakeAudioState.idle;
  String? activeAsset;
  Duration position = Duration.zero;
  AudioFailure? failNext;
  final List<String> playedAssets = [];

  Future<void> playLocal(String assetPath) async {
    _throwPendingFailure();
    activeAsset = assetPath;
    playedAssets.add(assetPath);
    position = Duration.zero;
    state = FakeAudioState.playing;
  }

  /// Fim natural da faixa: é o gatilho da conclusão automática do briefing.
  Future<void> complete() async {
    _throwPendingFailure();
    state = FakeAudioState.completed;
  }

  Future<void> startRecording({required int requiredBytes}) async {
    _throwPendingFailure();
    if (requiredBytes > availableRecordingBytes) {
      throw AudioFailure(
        message: 'Espaço local insuficiente para iniciar a gravação.',
      );
    }
    state = FakeAudioState.recording;
  }

  Future<void> stop() async {
    _throwPendingFailure();
    state = FakeAudioState.idle;
    activeAsset = null;
  }

  void advance(Duration elapsed) {
    if (state == FakeAudioState.playing || state == FakeAudioState.recording) {
      position += elapsed;
    }
  }

  void _throwPendingFailure() {
    final failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
  }
}

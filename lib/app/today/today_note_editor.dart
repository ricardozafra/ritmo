import '../../core/limits.dart';
import '../../data/db/database.dart' as db;
import '../../data/repositories/open_day_commands_repository.dart';
import '../../domain/time/operational_calendar.dart';
import '../editor_registry.dart';

final class TodayNoteEditorFactory {
  const TodayNoteEditorFactory(this._database);

  final db.RitmoDatabase _database;
  final LimitPolicy _limitPolicy = const LimitPolicy();

  DayScopedEditor create({
    required OperationalDate operationalDate,
    required String Function() readText,
  }) => _TodayNoteEditor(_database, operationalDate, readText, _limitPolicy);
}

final class _TodayNoteEditor implements DayScopedEditor {
  const _TodayNoteEditor(
    this._database,
    this.operationalDate,
    this._readText,
    this._limitPolicy,
  );

  final db.RitmoDatabase _database;
  @override
  final OperationalDate operationalDate;
  final String Function() _readText;
  final LimitPolicy _limitPolicy;

  @override
  DayEditSnapshot captureSnapshot() {
    final raw = _readText().trim();
    final note = raw.isEmpty ? null : raw;
    if (note != null) {
      final checked = _limitPolicy.clampRunes(note, Limits.shortTextMaxRunes);
      final violation = checked.violation;
      if (violation != null) {
        throw StateError('${violation.code}: ${violation.message}');
      }
    }
    return _TodayNoteSnapshot(_database, operationalDate, note);
  }
}

final class _TodayNoteSnapshot implements DayEditSnapshot {
  const _TodayNoteSnapshot(this._database, this.operationalDate, this.note);

  final db.RitmoDatabase _database;
  @override
  final OperationalDate operationalDate;
  final String? note;

  @override
  Future<void> persist() async {
    final result = await OpenDayCommandsRepository(
      _database,
    ).setDayNote(operationalDate, note: note);
    result.fold<void>(
      onSuccess: (_) {},
      onFailure: (failure) {
        throw StateError('${failure.code}: ${failure.message}');
      },
    );
  }
}

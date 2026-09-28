import 'package:drift/drift.dart';

import '../../core/limits.dart';
import '../../core/result.dart';
import '../../data/repositories/contact_repository.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';

/// Cadastro e edição de contatos (RF-07.4). Não toca em mentoria nem no rodízio
/// semanal, e nunca infere vínculos (RF-07.18, RF-07.19).
final class ContactController {
  ContactController(
    this._repository, {
    required Future<OperationalClock> Function() loadClock,
    this.onChanged,
    this.limitPolicy = const LimitPolicy(),
    // `loadClock` compõe a API nomeada pública; `_loadClock` a mantém interna.
    // ignore: prefer_initializing_formals
  }) : _loadClock = loadClock;

  final ContactRepository _repository;
  final Future<OperationalClock> Function() _loadClock;
  final void Function()? onChanged;
  final LimitPolicy limitPolicy;

  int _idCounter = 0;

  /// Cadastra um contato com nome obrigatório (≤120), contexto opcional (≤500)
  /// e data de último toque opcional. `created_at` vem do relógio oficial.
  Future<Result<void, RitmoFailure>> create({
    required String name,
    String? contextNote,
    OperationalDate? lastTouchDate,
  }) async {
    final validName = _requiredName(name);
    if (validName case Failure<String, RitmoFailure>(:final failure)) {
      return Result<void, RitmoFailure>.failure(failure);
    }
    final normalizedName = (validName as Success<String, RitmoFailure>).value;

    final validNote = _optionalContext(contextNote);
    if (validNote case Failure<String?, RitmoFailure>(:final failure)) {
      return Result<void, RitmoFailure>.failure(failure);
    }
    final normalizedNote = (validNote as Success<String?, RitmoFailure>).value;

    try {
      final clock = await _loadClock();
      final now = clock.nowInBusinessZone();
      await _repository.create(
        id: _nextId(now.microsecondsSinceEpoch),
        name: normalizedName,
        createdAt: now,
        contextNote: normalizedNote,
        lastTouchDate: lastTouchDate,
      );
      onChanged?.call();
      return const Result<void, RitmoFailure>.success(null);
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }

  /// Edita nome e/ou contexto de um contato existente.
  Future<Result<void, RitmoFailure>> edit(
    String id, {
    required String name,
    String? contextNote,
  }) async {
    final validName = _requiredName(name);
    if (validName case Failure<String, RitmoFailure>(:final failure)) {
      return Result<void, RitmoFailure>.failure(failure);
    }
    final normalizedName = (validName as Success<String, RitmoFailure>).value;

    final validNote = _optionalContext(contextNote);
    if (validNote case Failure<String?, RitmoFailure>(:final failure)) {
      return Result<void, RitmoFailure>.failure(failure);
    }
    final normalizedNote = (validNote as Success<String?, RitmoFailure>).value;

    try {
      final changed = await _repository.update(
        id: id,
        name: Value(normalizedName),
        contextNote: Value(normalizedNote),
      );
      if (!changed) {
        return const Result<void, RitmoFailure>.failure(
          ContactViolation(
            code: 'contact_not_found',
            message: 'O contato informado não existe.',
          ),
        );
      }
      onChanged?.call();
      return const Result<void, RitmoFailure>.success(null);
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }

  Result<String, RitmoFailure> _requiredName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Result<String, RitmoFailure>.failure(
        ContactViolation(
          code: 'contact_name_empty',
          message: 'Informe o nome do contato.',
        ),
      );
    }
    final clamped = limitPolicy.clampRunes(
      trimmed,
      Limits.editableNameMaxRunes,
    );
    final violation = clamped.violation;
    return violation == null
        ? Result<String, RitmoFailure>.success(trimmed)
        : Result<String, RitmoFailure>.failure(violation);
  }

  Result<String?, RitmoFailure> _optionalContext(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const Result<String?, RitmoFailure>.success(null);
    }
    final clamped = limitPolicy.clampRunes(trimmed, Limits.shortTextMaxRunes);
    final violation = clamped.violation;
    return violation == null
        ? Result<String?, RitmoFailure>.success(trimmed)
        : Result<String?, RitmoFailure>.failure(violation);
  }

  String _nextId(int microseconds) => 'contact-$microseconds-${_idCounter++}';
}

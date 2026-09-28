import '../../core/limits.dart';
import '../../core/result.dart';

export '../../core/result.dart' show ChangeInitiativeViolation;

/// Iniciativa visível no Pilar do Dia.
final class ChangeInitiative {
  const ChangeInitiative({
    required this.id,
    required this.name,
    required this.active,
  });

  final String id;
  final String name;
  final bool active;

  static Result<ChangeInitiative, BusinessViolation> create({
    required String id,
    required String name,
    bool active = true,
    LimitPolicy limitPolicy = const LimitPolicy(),
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      return const Result.failure(
        ChangeInitiativeViolation(
          code: 'change_initiative_id_empty',
          message: 'A iniciativa precisa de um identificador.',
        ),
      );
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return const Result.failure(
        ChangeInitiativeViolation(
          code: 'change_initiative_name_empty',
          message: 'Informe o nome da iniciativa de mudança.',
        ),
      );
    }

    final bounded = limitPolicy.clampRunes(
      normalizedName,
      Limits.editableNameMaxRunes,
    );
    if (bounded.violation case final violation?) {
      return Result.failure(violation);
    }
    return Result.success(
      ChangeInitiative(id: normalizedId, name: normalizedName, active: active),
    );
  }

  ChangeInitiative withActive(bool value) =>
      ChangeInitiative(id: id, name: name, active: value);
}

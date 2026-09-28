/// Resultado explícito para operações cujo fracasso é esperado pelo domínio.
sealed class Result<T, F> {
  const Result();

  const factory Result.success(T value) = Success<T, F>;
  const factory Result.failure(F failure) = Failure<T, F>;

  bool get isSuccess => this is Success<T, F>;
  bool get isFailure => this is Failure<T, F>;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(F failure) onFailure,
  });

  Result<R, F> map<R>(R Function(T value) transform) => fold(
    onSuccess: (value) => Result<R, F>.success(transform(value)),
    onFailure: Result<R, F>.failure,
  );
}

final class Success<T, F> extends Result<T, F> {
  const Success(this.value);

  final T value;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(F failure) onFailure,
  }) => onSuccess(value);
}

final class Failure<T, F> extends Result<T, F> {
  const Failure(this.failure);

  final F failure;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(F failure) onFailure,
  }) => onFailure(failure);
}

/// Raiz de todas as falhas conhecidas do Ritmo.
sealed class RitmoFailure {
  const RitmoFailure({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// Violações previstas de regra de negócio, tratáveis sem exceção.
sealed class BusinessViolation extends RitmoFailure {
  const BusinessViolation({required super.code, required super.message});
}

/// Falhas de infraestrutura, recuperáveis por retentativa ou degradação.
sealed class InfrastructureFailure extends RitmoFailure {
  const InfrastructureFailure({
    required super.code,
    required super.message,
    this.cause,
  });

  final Object? cause;
}

base class DayViolation extends BusinessViolation {
  const DayViolation({
    super.code = 'day_violation',
    super.message = 'A ação não está disponível para este dia.',
  });
}

base class NightWindowViolation extends BusinessViolation {
  const NightWindowViolation({
    super.code = 'night_window_violation',
    super.message = 'A ação não está disponível neste horário.',
  });
}

base class StudyBlockViolation extends BusinessViolation {
  const StudyBlockViolation({
    super.code = 'study_block_violation',
    super.message = 'O bloco de estudo não pôde ser alterado.',
  });
}

base class WaiverViolation extends BusinessViolation {
  const WaiverViolation({
    super.code = 'waiver_violation',
    super.message = 'A dispensa não pôde ser aplicada.',
  });
}

base class ChangeInitiativeViolation extends BusinessViolation {
  const ChangeInitiativeViolation({
    super.code = 'change_initiative_violation',
    super.message = 'A iniciativa de mudança não pôde ser alterada.',
  });
}

base class ProtocolViolation extends BusinessViolation {
  const ProtocolViolation({
    super.code = 'protocol_violation',
    super.message = 'O protocolo não pôde ser respondido.',
  });
}

base class HolidayViolation extends BusinessViolation {
  const HolidayViolation({
    super.code = 'holiday_violation',
    super.message = 'A alteração de feriado não pôde ser concluída.',
  });
}

base class ReviewViolation extends BusinessViolation {
  const ReviewViolation({
    super.code = 'review_violation',
    super.message = 'A revisão não pode mais ser alterada.',
  });
}

base class CycleViolation extends BusinessViolation {
  const CycleViolation({
    super.code = 'cycle_violation',
    super.message = 'A edição do ciclo não pôde ser concluída.',
  });
}

base class MentorshipViolation extends BusinessViolation {
  const MentorshipViolation({
    super.code = 'mentorship_violation',
    super.message = 'A edição da mentoria não pôde ser concluída.',
  });
}

base class ContactViolation extends BusinessViolation {
  const ContactViolation({
    super.code = 'contact_violation',
    super.message = 'A operação de contato não pôde ser concluída.',
  });
}

enum LimitUnit { runes, utf8Bytes }

base class LimitViolation extends BusinessViolation {
  const LimitViolation({
    required this.actual,
    required this.maximum,
    required this.unit,
    super.code = 'limit_exceeded',
    super.message = 'O conteúdo excede o limite permitido.',
  });

  final int actual;
  final int maximum;
  final LimitUnit unit;
}

base class ConfigViolation extends BusinessViolation {
  const ConfigViolation({
    super.code = 'config_violation',
    super.message = 'A configuração informada não é válida.',
  });
}

base class StorageFailure extends InfrastructureFailure {
  const StorageFailure({
    super.code = 'storage_failure',
    super.message = 'Não foi possível acessar o armazenamento.',
    super.cause,
  });
}

base class DatabaseFailure extends InfrastructureFailure {
  const DatabaseFailure({
    super.code = 'database_failure',
    super.message = 'Não foi possível concluir a operação de dados.',
    super.cause,
  });
}

base class AudioFailure extends InfrastructureFailure {
  const AudioFailure({
    super.code = 'audio_failure',
    super.message = 'Não foi possível concluir a operação de áudio.',
    super.cause,
  });
}

base class NotificationFailure extends InfrastructureFailure {
  const NotificationFailure({
    super.code = 'notification_failure',
    super.message = 'Não foi possível concluir a operação de notificação.',
    super.cause,
  });
}

base class ManifestFailure extends InfrastructureFailure {
  const ManifestFailure({
    super.code = 'manifest_failure',
    super.message = 'Não foi possível acessar o manifesto.',
    super.cause,
  });
}

base class ExportFailure extends InfrastructureFailure {
  const ExportFailure({
    super.code = 'export_failure',
    super.message = 'Não foi possível concluir a exportação.',
    super.cause,
  });
}

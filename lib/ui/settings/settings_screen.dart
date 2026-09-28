import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/providers/holiday_providers.dart';
import '../../app/providers/settings_providers.dart';
import '../../core/limits.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/holidays/holiday_recalculation.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const screenKey = ValueKey<String>('settings-screen');
  static const dayCloseButtonKey = ValueKey<String>(
    'settings-day-close-button',
  );
  static const nightEndButtonKey = ValueKey<String>(
    'settings-night-end-button',
  );
  static const saveTimesButtonKey = ValueKey<String>(
    'settings-save-times-button',
  );

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _dayCloseTimeMinutes;
  int? _nightEndTimeMinutes;
  String? _persistedTimesKey;
  bool _savingTimes = false;
  String? _holidayBusyDate;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsSnapshotProvider);
    final holidays = ref.watch(holidaySettingsEntriesProvider);

    return Scaffold(
      key: SettingsScreen.screenKey,
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: settings.when(
                  loading: () => const _LoadingCard(
                    label: 'Carregando horários operacionais',
                  ),
                  error: (error, stackTrace) => _LoadFailureCard(
                    message: 'Não foi possível carregar os horários.',
                    onRetry: () => ref.invalidate(settingsSnapshotProvider),
                  ),
                  data: (snapshot) {
                    _synchronizeTimes(snapshot);
                    return _OperationalTimesCard(
                      dayCloseTimeMinutes: _dayCloseTimeMinutes!,
                      nightEndTimeMinutes: _nightEndTimeMinutes!,
                      saving: _savingTimes,
                      changed: _timesChanged(snapshot),
                      onPickDayClose: _savingTimes
                          ? null
                          : () => _pickDayCloseTime(snapshot),
                      onPickNightEnd: _savingTimes
                          ? null
                          : () => _pickNightEndTime(snapshot),
                      onSave: _savingTimes || !_timesChanged(snapshot)
                          ? null
                          : _saveTimes,
                    );
                  },
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(child: _HolidayHeader()),
            ),
            ..._holidaySlivers(holidays),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(child: _SyncCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  List<Widget> _holidaySlivers(
    AsyncValue<List<HolidaySettingsEntry>> holidays,
  ) => holidays.when(
    loading: () => const <Widget>[
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: _LoadingCard(label: 'Carregando feriados'),
        ),
      ),
    ],
    error: (error, stackTrace) => <Widget>[
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: _LoadFailureCard(
            message: 'Não foi possível carregar as datas materializadas.',
            onRetry: () => ref.invalidate(holidaySettingsEntriesProvider),
          ),
        ),
      ),
    ],
    data: (entries) {
      if (entries.isEmpty) {
        return const <Widget>[
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.event_busy_outlined),
                  title: Text('Nenhuma data operacional disponível'),
                  subtitle: Text(
                    'Os feriados poderão ser gerenciados depois que o '
                    'primeiro dia for materializado.',
                  ),
                ),
              ),
            ),
          ),
        ];
      }

      return <Widget>[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index.isOdd) return const SizedBox(height: 8);
              final entry = entries[index ~/ 2];
              return _HolidayCard(
                entry: entry,
                anyOperationRunning: _holidayBusyDate != null,
                operationRunning: _holidayBusyDate == entry.date.iso,
                onChange: entry.canManageHoliday
                    ? () => _changeHoliday(entry)
                    : null,
              );
            }, childCount: entries.length * 2 - 1),
          ),
        ),
      ];
    },
  );

  void _synchronizeTimes(SettingsSnapshot snapshot) {
    final key =
        '${snapshot.dayCloseTimeMinutes}:${snapshot.nightEndTimeMinutes}';
    if (_persistedTimesKey == key) return;
    _persistedTimesKey = key;
    _dayCloseTimeMinutes = snapshot.dayCloseTimeMinutes;
    _nightEndTimeMinutes = snapshot.nightEndTimeMinutes;
  }

  bool _timesChanged(SettingsSnapshot snapshot) =>
      _dayCloseTimeMinutes != snapshot.dayCloseTimeMinutes ||
      _nightEndTimeMinutes != snapshot.nightEndTimeMinutes;

  Future<void> _pickDayCloseTime(SettingsSnapshot snapshot) async {
    final selected = await _pickTime(
      initialMinutes: _dayCloseTimeMinutes ?? snapshot.dayCloseTimeMinutes,
      helpText: 'Fechamento do dia',
    );
    if (selected == null || !mounted) return;
    if (selected < 0 || selected > 4 * Duration.minutesPerHour) {
      _showMessage('O fechamento do dia deve ficar entre 00:00 e 04:00.');
      return;
    }
    setState(() => _dayCloseTimeMinutes = selected);
  }

  Future<void> _pickNightEndTime(SettingsSnapshot snapshot) async {
    final selected = await _pickTime(
      initialMinutes: _nightEndTimeMinutes ?? snapshot.nightEndTimeMinutes,
      helpText: 'Limite da noite',
    );
    if (selected == null || !mounted) return;
    setState(() => _nightEndTimeMinutes = selected);
  }

  Future<int?> _pickTime({
    required int initialMinutes,
    required String helpText,
  }) async {
    final selected = await showTimePicker(
      context: context,
      helpText: helpText,
      initialTime: TimeOfDay(
        hour: initialMinutes ~/ Duration.minutesPerHour,
        minute: initialMinutes % Duration.minutesPerHour,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    return selected == null
        ? null
        : selected.hour * Duration.minutesPerHour + selected.minute;
  }

  Future<void> _saveTimes() async {
    final dayClose = _dayCloseTimeMinutes;
    final nightEnd = _nightEndTimeMinutes;
    if (dayClose == null || nightEnd == null) return;

    setState(() => _savingTimes = true);
    final result = await ref
        .read(settingsControllerProvider)
        .updateOperationalTimes(
          dayCloseTimeMinutes: dayClose,
          nightEndTimeMinutes: nightEnd,
        );
    if (!mounted) return;
    setState(() => _savingTimes = false);
    result.fold<void>(
      onSuccess: (_) => _showMessage(
        'Horários salvos. A nova fronteira vale somente para dias ainda abertos.',
      ),
      onFailure: (failure) => _showMessage(failure.message),
    );
  }

  Future<void> _changeHoliday(HolidaySettingsEntry entry) async {
    if (_holidayBusyDate != null || !entry.canManageHoliday) return;
    final operation = entry.isHolidayActive
        ? HolidayOperation.remove
        : HolidayOperation.apply;
    final controller = ref.read(holidayControllerProvider);
    final preview = controller.preview(entry.date, operation);
    final reason = await _showHolidayPreview(preview);
    if (reason == null || !mounted) return;

    setState(() => _holidayBusyDate = entry.date.iso);
    try {
      final result = operation == HolidayOperation.apply
          ? await controller.apply(
              entry.date,
              confirmed: true,
              reasonText: reason,
            )
          : await controller.remove(
              entry.date,
              confirmed: true,
              reasonText: reason,
            );
      if (!mounted) return;
      result.fold<void>(
        onSuccess: (report) => _showMessage(report.message),
        onFailure: (failure) => _showMessage(failure.message),
      );
    } on Object {
      if (mounted) {
        _showMessage('Não foi possível alterar o feriado. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _holidayBusyDate = null);
    }
  }

  Future<String?> _showHolidayPreview(RecalcPreview preview) async {
    final reasonController = TextEditingController();
    var runeCount = 0;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(preview.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(preview.message),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLength: Limits.shortTextMaxRunes,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(Limits.shortTextMaxRunes),
                  ],
                  maxLines: 4,
                  onChanged: (text) {
                    setDialogState(() => runeCount = text.runes.length);
                  },
                  decoration: InputDecoration(
                    labelText: 'Motivo opcional',
                    alignLabelWithHint: true,
                    helperText:
                        '$runeCount de ${Limits.shortTextMaxRunes} caracteres',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, reasonController.text),
              child: Text(
                preview.operation == HolidayOperation.apply
                    ? 'Aplicar feriado'
                    : 'Remover feriado',
              ),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
    return value;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OperationalTimesCard extends StatelessWidget {
  const _OperationalTimesCard({
    required this.dayCloseTimeMinutes,
    required this.nightEndTimeMinutes,
    required this.saving,
    required this.changed,
    required this.onPickDayClose,
    required this.onPickNightEnd,
    required this.onSave,
  });

  final int dayCloseTimeMinutes;
  final int nightEndTimeMinutes;
  final bool saving;
  final bool changed;
  final VoidCallback? onPickDayClose;
  final VoidCallback? onPickNightEnd;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Horários operacionais', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Todos os horários seguem America/Sao_Paulo. Alterações não '
              'reabrem nem renomeiam dias já encerrados.',
            ),
            const SizedBox(height: 16),
            _TimeSetting(
              label: 'Fechamento do dia',
              description: 'Permitido entre 00:00 e 04:00.',
              value: _formatTime(dayCloseTimeMinutes),
              buttonKey: SettingsScreen.dayCloseButtonKey,
              onPressed: onPickDayClose,
            ),
            const SizedBox(height: 12),
            _TimeSetting(
              label: 'Limite da noite',
              description:
                  'Define até quando um Estudo pode permanecer ativo dentro '
                  'do dia operacional.',
              value: _formatTime(nightEndTimeMinutes),
              buttonKey: SettingsScreen.nightEndButtonKey,
              onPressed: onPickNightEnd,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: SettingsScreen.saveTimesButtonKey,
              onPressed: onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                saving
                    ? 'Salvando horários'
                    : changed
                    ? 'Salvar horários'
                    : 'Horários salvos',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSetting extends StatelessWidget {
  const _TimeSetting({
    required this.label,
    required this.description,
    required this.value,
    required this.buttonKey,
    required this.onPressed,
  });

  final String label;
  final String description;
  final String value;
  final Key buttonKey;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label, $value',
    button: true,
    child: OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.schedule_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(description),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    ),
  );
}

class _HolidayHeader extends StatelessWidget {
  const _HolidayHeader();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('Feriados manuais', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      const Text(
        'Escolha uma data já materializada. Antes de aplicar ou remover, o '
        'Ritmo apresentará os efeitos esperados em métricas e protocolos.',
      ),
    ],
  );
}

class _HolidayCard extends StatelessWidget {
  const _HolidayCard({
    required this.entry,
    required this.anyOperationRunning,
    required this.operationRunning,
    required this.onChange,
  });

  final HolidaySettingsEntry entry;
  final bool anyOperationRunning;
  final bool operationRunning;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      _classificationText(entry),
      entry.isClosed ? 'Dia encerrado' : 'Dia aberto',
      if (entry.createdAtMillisecondsSinceEpoch != null)
        'Aplicado em ${_formatInstant(entry.createdAtMillisecondsSinceEpoch!)}',
      if (entry.applyReasonText != null)
        'Motivo da aplicação: ${entry.applyReasonText}',
      if (entry.removedAtMillisecondsSinceEpoch != null)
        'Removido em ${_formatInstant(entry.removedAtMillisecondsSinceEpoch!)}',
      if (entry.removeReasonText != null)
        'Motivo da remoção: ${entry.removeReasonText}',
    ];
    final canChange = onChange != null && !anyOperationRunning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  entry.isHolidayActive
                      ? Icons.event_available_outlined
                      : entry.date.isWeekend
                      ? Icons.weekend_outlined
                      : Icons.event_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _formatDate(entry.date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      for (final detail in details)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(detail),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (entry.canManageHoliday) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: canChange ? onChange : null,
                child: operationRunning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        entry.isHolidayActive
                            ? 'Remover feriado'
                            : 'Marcar como feriado',
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context) => Card(
    child: SwitchListTile(
      value: false,
      onChanged: null,
      secondary: const Icon(Icons.cloud_off_outlined),
      title: const Text('Sincronização'),
      subtitle: const Text(
        'Desligada no MVP. Os dados permanecem locais e nenhuma conta é '
        'necessária.',
      ),
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Semantics(
          label: label,
          child: const CircularProgressIndicator(),
        ),
      ),
    ),
  );
}

class _LoadFailureCard extends StatelessWidget {
  const _LoadFailureCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

String _formatTime(int minutes) =>
    LocalTimeOfDay.fromMinutes(minutes).toString();

String _formatDate(OperationalDate date) {
  const weekdays = <int, String>{
    DateTime.monday: 'segunda-feira',
    DateTime.tuesday: 'terça-feira',
    DateTime.wednesday: 'quarta-feira',
    DateTime.thursday: 'quinta-feira',
    DateTime.friday: 'sexta-feira',
    DateTime.saturday: 'sábado',
    DateTime.sunday: 'domingo',
  };
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year} · ${weekdays[date.weekday]}';
}

String _formatInstant(int millisecondsSinceEpoch) {
  final instant = tz.TZDateTime.fromMillisecondsSinceEpoch(
    ensureBusinessLocation(),
    millisecondsSinceEpoch,
  );
  final day = instant.day.toString().padLeft(2, '0');
  final month = instant.month.toString().padLeft(2, '0');
  final hour = instant.hour.toString().padLeft(2, '0');
  final minute = instant.minute.toString().padLeft(2, '0');
  return '$day/$month/${instant.year} às $hour:$minute';
}

String _classificationText(HolidaySettingsEntry entry) {
  if (entry.date.isWeekend) {
    return 'Fim de semana · classificação automática';
  }
  if (entry.isHolidayActive) return 'Feriado ativo';
  if (entry.hasHolidayRecord) return 'Feriado removido · histórico preservado';
  return 'Sem feriado manual';
}

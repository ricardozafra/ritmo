import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/ritmo_providers.dart';
import '../../app/ritmo/ritmo_projection.dart';
import '../../domain/day/day_state_machine.dart';
import '../../domain/time/operational_calendar.dart';

class RitmoDayDetailScreen extends ConsumerWidget {
  const RitmoDayDetailScreen({required this.operationalDate, super.key});

  static const screenKey = ValueKey<String>('ritmo-day-detail-screen');

  final OperationalDate operationalDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(ritmoDayDetailProvider(operationalDate));
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: Text(operationalDate.iso)),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _DetailError(
            onRetry: () =>
                ref.invalidate(ritmoDayDetailProvider(operationalDate)),
          ),
          data: (view) => view == null
              ? const _MissingDay()
              : _PersistedDayDetail(view: view),
        ),
      ),
    );
  }
}

class _PersistedDayDetail extends StatelessWidget {
  const _PersistedDayDetail({required this.view});

  final RitmoDayDetailView view;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text(
          'Dados persistidos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'Esta visualização é somente leitura e não recalcula a classificação.',
        ),
        const SizedBox(height: 16),
        _DetailField(
          label: 'operational_date',
          value: view.operationalDate.iso,
        ),
        _DetailField(label: 'base_result', value: view.baseResult.name),
        _DetailField(
          label: 'effective_result',
          value: view.effectiveResult.name,
        ),
        _DetailField(label: 'mute_cause', value: _muteCause(view.muteCause)),
        _DetailField(
          label: 'previous_result',
          value: view.previousResult?.name ?? '—',
        ),
        _DetailField(
          label: 'lifecycle',
          value: view.isOpen ? 'open' : 'closed',
        ),
        _DetailField(label: 'closed_at', value: _instant(view.closedAt)),
        _DetailField(
          label: 'seal_timestamp',
          value: _instant(view.sealTimestamp),
        ),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(label), subtitle: SelectableText(value)),
    );
  }
}

class _MissingDay extends StatelessWidget {
  const _MissingDay();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Não há registro persistido para esta data operacional.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Não foi possível carregar os dados persistidos.'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

String _muteCause(MuteCause? cause) => cause?.name ?? '—';

String _instant(DateTime? value) {
  if (value == null) return '—';
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-'
      '${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
      '${twoDigits(value.second)} $kBusinessTimeZone';
}

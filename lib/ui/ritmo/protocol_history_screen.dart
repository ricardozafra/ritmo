import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/protocol_providers.dart';
import '../../domain/protocol/protocol_alarm.dart';
import '../../domain/time/operational_calendar.dart';

class ProtocolHistoryScreen extends ConsumerWidget {
  const ProtocolHistoryScreen({super.key});

  static const screenKey = ValueKey<String>('protocol-history-screen');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(protocolHistoryProvider);
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Histórico de Protocolos')),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _HistoryError(
            onRetry: () => ref.invalidate(protocolHistoryProvider),
          ),
          data: (protocols) => protocols.isEmpty
              ? const _EmptyHistory()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: protocols.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _ProtocolCard(protocol: protocols[index]),
                ),
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({required this.protocol});

  final ProtocolAlarm protocol;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${protocol.startDate.iso} a ${protocol.endDate.iso}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(protocol.state.name)),
              ],
            ),
            Text('Identificador: ${protocol.id}'),
            Text('Dias registrados: ${protocol.sequenceLength}'),
            if (protocol.previousState case final previous?)
              Text('Estado anterior: ${previous.name}'),
            if (protocol.triggeredAt case final triggeredAt?)
              Text('Disparado em: ${_instant(triggeredAt)}'),
            if (protocol.cause case final cause?) ...<Widget>[
              const SizedBox(height: 12),
              _ProtocolField(label: 'Causa', value: cause),
            ],
            if (protocol.planOrExecution case final classification?)
              _ProtocolField(
                label: 'Plano ou execução',
                value: classification.name,
              ),
            if (protocol.adjustment case final adjustment?)
              _ProtocolField(label: 'Ajuste', value: adjustment),
          ],
        ),
      ),
    );
  }
}

class _ProtocolField extends StatelessWidget {
  const _ProtocolField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text('$label: $value'),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Nenhum Alarme de Protocolo foi registrado.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Não foi possível carregar o histórico de protocolos.'),
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

String _instant(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-'
      '${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)} '
      '$kBusinessTimeZone';
}

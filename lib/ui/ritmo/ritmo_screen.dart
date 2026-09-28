import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation/app_router.dart';
import '../../app/providers/metrics_providers.dart';
import '../../app/providers/protocol_providers.dart';
import '../../app/providers/ritmo_providers.dart';
import '../../app/ritmo/ritmo_projection.dart';
import '../../domain/metrics/metrics_calculator.dart';
import '../../domain/protocol/single_lost_day_copy.dart';
import 'competency_evolution_card.dart';
import 'monthly_heatmap.dart';

class RitmoScreen extends ConsumerStatefulWidget {
  const RitmoScreen({super.key});

  static const screenKey = ValueKey<String>('ritmo-screen');
  static const historyButtonKey = ValueKey<String>(
    'ritmo-protocol-history-button',
  );

  @override
  ConsumerState<RitmoScreen> createState() => _RitmoScreenState();
}

class _RitmoScreenState extends ConsumerState<RitmoScreen> {
  RitmoMonth? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final currentDate = ref.watch(ritmoCurrentOperationalDateProvider);
    final rate = ref.watch(metricsRateProvider);
    final singleLostDay = ref.watch(singleLostDayCopyProvider);

    return Scaffold(
      key: RitmoScreen.screenKey,
      appBar: AppBar(title: const Text('Ritmo')),
      body: SafeArea(
        child: currentDate.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _RitmoError(
            onRetry: () => ref.invalidate(ritmoCurrentOperationalDateProvider),
          ),
          data: (date) {
            final currentMonth = RitmoMonth.fromDate(date);
            final visibleMonth = _selectedMonth ?? currentMonth;
            final monthView = ref.watch(ritmoMonthProvider(visibleMonth));
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                _RateCard(rate: rate),
                _SingleLostDayCard(presentation: singleLostDay),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _MonthNavigation(
                          month: visibleMonth,
                          isCurrentMonth: visibleMonth == currentMonth,
                          onPrevious: () =>
                              _selectMonth(visibleMonth.previous, currentMonth),
                          onNext: () =>
                              _selectMonth(visibleMonth.next, currentMonth),
                          onCurrent: () =>
                              setState(() => _selectedMonth = null),
                        ),
                        const SizedBox(height: 16),
                        monthView.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stackTrace) => _SectionError(
                            message: 'Não foi possível carregar este mês.',
                            onRetry: () => ref.invalidate(
                              ritmoMonthProvider(visibleMonth),
                            ),
                          ),
                          data: (view) => MonthlyHeatmap(
                            view: view,
                            onDaySelected: (selectedDate) => context.push(
                              AppRoute.ritmoDayPath(selectedDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: RitmoScreen.historyButtonKey,
                  onPressed: () => context.push(AppRoute.ritmoProtocolsPath),
                  icon: const Icon(Icons.history),
                  label: const Text('Histórico de Protocolos'),
                ),
                const SizedBox(height: 12),
                const CompetencyEvolutionCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  void _selectMonth(RitmoMonth month, RitmoMonth currentMonth) {
    setState(() {
      _selectedMonth = month == currentMonth ? null : month;
    });
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.rate});

  final AsyncValue<Rate> rate;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey<String>('ritmo-rate-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: rate.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) =>
              const Text('A taxa não está disponível neste momento.'),
          data: (value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Taxa', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
                semanticsLabel:
                    '${value.numerator} de ${value.denominator} dias elegíveis encerrados',
              ),
              const SizedBox(height: 4),
              const Text(
                'Dias úteis elegíveis encerrados e selados sobre dias úteis elegíveis encerrados.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SingleLostDayCard extends StatelessWidget {
  const _SingleLostDayCard({required this.presentation});

  final AsyncValue<FailureCopyPresentation?> presentation;

  @override
  Widget build(BuildContext context) => switch (presentation) {
    AsyncData(:final value) when value != null => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          value.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ),
    _ => const SizedBox.shrink(),
  };
}

class _MonthNavigation extends StatelessWidget {
  const _MonthNavigation({
    required this.month,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  final RitmoMonth month;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: 'Mês anterior',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              month.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
        if (!isCurrentMonth)
          TextButton(onPressed: onCurrent, child: const Text('Mês atual')),
      ],
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(message),
      const SizedBox(height: 8),
      TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
    ],
  );
}

class _RitmoError extends StatelessWidget {
  const _RitmoError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Não foi possível carregar a tela Ritmo.'),
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

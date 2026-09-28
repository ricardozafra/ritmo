import 'package:flutter/material.dart';

import '../../app/ritmo/ritmo_projection.dart';
import '../../domain/time/operational_calendar.dart';

class MonthlyHeatmap extends StatelessWidget {
  const MonthlyHeatmap({
    required this.view,
    required this.onDaySelected,
    super.key,
  });

  final RitmoMonthView view;
  final ValueChanged<OperationalDate> onDaySelected;

  static const _weekdays = <String>[
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    final itemCount = view.leadingEmptyCells + view.cells.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: [
            for (final weekday in _weekdays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        GridView.builder(
          key: const ValueKey<String>('ritmo-monthly-heatmap'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            if (index < view.leadingEmptyCells) {
              return const SizedBox.shrink();
            }
            final cell = view.cells[index - view.leadingEmptyCells];
            return _HeatmapDay(
              cell: cell,
              onTap: cell.hasPersistedDay
                  ? () => onDaySelected(cell.date)
                  : null,
            );
          },
        ),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 16,
          runSpacing: 8,
          children: <Widget>[
            _LegendItem(state: RitmoDayCellState.sealed, label: 'Selado'),
            _LegendItem(
              state: RitmoDayCellState.closedUnsealed,
              label: 'Encerrado não selado',
            ),
            _LegendItem(state: RitmoDayCellState.open, label: 'Aberto'),
            _LegendItem(state: RitmoDayCellState.mute, label: 'Sem rotina'),
          ],
        ),
      ],
    );
  }
}

class _HeatmapDay extends StatelessWidget {
  const _HeatmapDay({required this.cell, required this.onTap});

  final RitmoDayCell cell;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _cellColors(Theme.of(context).colorScheme, cell.state);
    final label = '${cell.date.iso}: ${_stateLabel(cell.state)}';
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: colors.border),
    );

    return Semantics(
      label: label,
      button: onTap != null,
      child: Tooltip(
        message: label,
        child: Material(
          color: colors.background,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: Center(
              child: Text(
                '${cell.date.day}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.state, required this.label});

  final RitmoDayCellState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _cellColors(Theme.of(context).colorScheme, state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

({Color background, Color foreground, Color border}) _cellColors(
  ColorScheme scheme,
  RitmoDayCellState state,
) => switch (state) {
  RitmoDayCellState.sealed => (
    background: scheme.primaryContainer,
    foreground: scheme.onPrimaryContainer,
    border: scheme.primary,
  ),
  RitmoDayCellState.closedUnsealed => (
    background: scheme.surfaceContainerHighest,
    foreground: scheme.onSurfaceVariant,
    border: scheme.outline,
  ),
  RitmoDayCellState.open => (
    background: scheme.surfaceContainerLow,
    foreground: scheme.onSurface,
    border: scheme.outlineVariant,
  ),
  RitmoDayCellState.mute => (
    background: Colors.transparent,
    foreground: scheme.onSurfaceVariant,
    border: scheme.outlineVariant,
  ),
  RitmoDayCellState.unavailable => (
    background: Colors.transparent,
    foreground: scheme.outline,
    border: Colors.transparent,
  ),
};

String _stateLabel(RitmoDayCellState state) => switch (state) {
  RitmoDayCellState.unavailable => 'sem registro persistido',
  RitmoDayCellState.open => 'dia aberto',
  RitmoDayCellState.sealed => 'dia selado',
  RitmoDayCellState.closedUnsealed => 'dia encerrado não selado',
  RitmoDayCellState.mute => 'dia sem rotina diária',
};

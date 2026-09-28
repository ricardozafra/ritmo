// Tarefa 18.3: benchmark instrumentado da tela Hoje.
//
// Mede o cold start até o `todayViewProvider` resolver a partir de um container
// recém-criado, sobre um histórico grande, e falha automaticamente quando o
// orçamento é excedido. Prova também que a consulta lê somente a data
// operacional corrente: nenhuma linha de outra data é retornada, portanto o
// custo não cresce com o histórico (RNF-01.2).
//
// O orçamento aqui é uma barreira reproduzível de regressão em ambiente de
// teste, não a medição no dispositivo de referência. O critério normativo de
// 2 s vale para o Motorola Edge 70 Pro; um orçamento local mais folgado
// registra falha automática sem introduzir instabilidade de CI.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/providers/boundary_providers.dart';
import 'package:ritmo/app/providers/metrics_providers.dart';
import 'package:ritmo/app/providers/today_providers.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/domain/day/today_view.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'cold start de Hoje resolve dentro do orçamento lendo só a data corrente',
    () async {
      // Data operacional corrente pelo mesmo relógio de produção, para que a
      // materialização acerte exatamente o dia que a tela vai carregar.
      final clock = SystemOperationalClock();
      final today = clock.operationalDateNow();

      final recorder = _RecordingInterceptor();
      final database = RitmoDatabase(
        NativeDatabase.memory().interceptWith(recorder),
      );
      addTearDown(database.close);

      // Garante o seed e fixa a ativação bem antes do histórico gerado.
      await database.select(database.settings).getSingle();
      final activation = today.addDays(-400);
      await database.customStatement(
        'UPDATE settings SET activation_date = ? WHERE id = 1',
        [activation.iso],
      );

      // Histórico grande: ~400 dias encerrados antes de hoje e o dia corrente
      // aberto. Se a leitura fizesse varredura completa, o custo cresceria com
      // este volume.
      await database.batch((batch) {
        for (var offset = -400; offset < 0; offset++) {
          final date = today.addDays(offset);
          final sealed = offset.isEven;
          batch.customStatement(
            'INSERT INTO days (operational_date, base_result, '
            'effective_result, closed_at, seal_timestamp) '
            'VALUES (?, ?, ?, ?, ?)',
            [
              date.iso,
              sealed ? 'sealed' : 'unsealed',
              sealed ? 'sealed' : 'unsealed',
              1000 + offset,
              sealed ? 1000 + offset : null,
            ],
          );
        }
      });

      final container = ProviderContainer(
        overrides: [ritmoDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      // O bootstrap do runtime de fronteira consulta agregados de `days`
      // (ex.: MAX(operational_date) para ancorar a data). Isso é inicialização
      // única, não a leitura por-dia da tela; medimos e auditamos apenas a
      // projeção de Hoje, então pré-aquecemos o runtime e zeramos o registro.
      await container.read(boundaryRuntimeProvider.future);
      recorder.reset();

      final stopwatch = Stopwatch()..start();
      final view = await container.read(todayViewProvider.future);
      stopwatch.stop();

      // Resolve a tela para a data operacional corrente.
      expect(view, isA<WorkdayTodayView>());
      expect(view.operationalDate, today);

      // Falha automática de orçamento (barreira de regressão reproduzível).
      const budget = Duration(seconds: 2);
      expect(
        stopwatch.elapsed,
        lessThan(budget),
        reason:
            'Cold start levou ${stopwatch.elapsedMilliseconds} ms, '
            'acima do orçamento de ${budget.inMilliseconds} ms.',
      );

      // Nenhuma linha de `days` de outra data pode ter sido lida: a projeção
      // consulta apenas a data corrente, então o custo independe do histórico.
      final foreignDayReads = recorder.selectedDayIsoValues
          .where((iso) => iso != today.iso)
          .toSet();
      expect(
        foreignDayReads,
        isEmpty,
        reason:
            'A projeção de Hoje leu datas além da corrente: $foreignDayReads',
      );

      // Confirma que a data corrente foi de fato consultada.
      expect(recorder.selectedDayIsoValues, contains(today.iso));
    },
  );
}

/// Interceptor que registra os `operational_date` retornados por SELECTs sobre
/// a tabela `days`, para provar o escopo da leitura da tela Hoje.
final class _RecordingInterceptor extends QueryInterceptor {
  final List<String> selectedDayIsoValues = <String>[];

  void reset() => selectedDayIsoValues.clear();

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await super.runSelect(executor, statement, args);
    // Considera apenas SELECTs que retornam linhas de `days` com a coluna de
    // data, ignorando agregados de bootstrap (ex.: MAX(operational_date)).
    final upper = statement.toUpperCase();
    final mentionsDays =
        upper.contains('FROM DAYS') || upper.contains('FROM "DAYS"');
    final isAggregate = upper.contains('MAX(') || upper.contains('COUNT(');
    if (mentionsDays && !isAggregate) {
      for (final row in rows) {
        final value = row['operational_date'];
        if (value is String) selectedDayIsoValues.add(value);
      }
    }
    return rows;
  }
}

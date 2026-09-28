# Correções pós-revisão da entrega — Ritmo

Plano de correção derivado da revisão da entrega (Fase 3: áudio local e exportação).
As tarefas abaixo endereçam defeitos reais de código, ruído de análise estática e
imprecisões de relatório. Nenhuma foi executada ainda.

Convenções:
- Cada tarefa lista arquivos-alvo, o que fazer e como validar.
- Validação padrão do projeto: `dart format`, `flutter analyze --no-pub`,
  `dart run tool\clock_lint.dart`, `dart run tool\mvp_scope_check.dart` e
  `flutter test --no-pub --concurrency=1`.
- Linha de base atual observada: **378 testes verdes**; `flutter analyze` com
  **15 issues** (8 pré-existentes fora de escopo + 7 novos a remover nesta lista);
  `clock_lint` e `mvp_scope_check` limpos.
- Alvo ao final: `flutter analyze` volta a **8 issues** (somente os pré-existentes),
  suíte permanece verde.

---

## 1. Remover os 7 warnings novos de análise estática (arquivos de teste)

- [x] 1.1 Limpar imports e variáveis não usados introduzidos pelos testes opcionais
  - Remover imports não usados:
    - `test/app/notifications_integration_test.dart:9` — `package:ritmo/domain/notifications/blackout_policy.dart`
    - `test/app/notifications_integration_test.dart:11` — `package:ritmo/domain/review/review_schedule_validator.dart`
    - `test/data/weekly_review_autosave_property_test.dart:16` — `package:ritmo/data/db/guarded_writer.dart`
    - `test/domain/notifications/review_notification_uniqueness_property_test.dart:20` — `package:ritmo/domain/notifications/blackout_policy.dart`
  - Remover (ou passar a usar) variáveis locais não usadas:
    - `test/app/notifications_integration_test.dart:70` — `sunday`
    - `test/domain/notifications/review_notification_uniqueness_property_test.dart:171` — `delivered`
    - `test/domain/people/mentorship_contacts_separation_property_test.dart:132` — `mentorships`
  - Cuidado: se uma variável documentava a intenção do caso de teste, preferir de fato
    usá-la em uma asserção em vez de apenas apagá-la, para não enfraquecer o teste.
  - _Validação:_ `flutter analyze --no-pub` cai de 15 para 8 issues; os 8 restantes são
    exatamente os pré-existentes fora de escopo (`metrics_repository.dart:66` curly_braces;
    `holiday_recalculation_idempotence_property_test.dart:11` unused_import drift; 6
    `deprecated_member_use` de `dispose` em `schema_v1_migration_harness_test.dart` e
    `support/migration_test_harness.dart`). Suíte permanece verde.

---

## 2. Corrigir `awaitingClosure` no envelope de exportação (defeito real)

- [x] 2.1 Derivar `awaitingClosure` via `CyclePolicy` em vez de comparar a estado inexistente
  - Arquivo: `lib/data/export/local_export_service.dart` (construção de `ExportCycleDerived`).
  - Problema: hoje faz `awaitingClosure: cRow.state == 'awaiting_closure'`, mas o schema de
    `cycles.state` só admite `active|archived` (RD-20). O marcador "aguardando encerramento"
    é **derivado**, portanto o campo exportado é sempre `false`.
  - Correção: computar o valor com `CyclePolicy.awaitingClosure(cycle, checkpoints, today)`,
    usando o `Cycle`/`List<Checkpoint>` de domínio (mapeados a partir das linhas já lidas) e a
    data operacional corrente obtida do relógio oficial (o serviço já recebe `businessLocation`;
    prover o `OperationalClock`/`operationalDateNow` de forma injetável para manter testabilidade
    e não violar o `clock_lint`).
  - Considerar expor a data operacional de referência no `buildEnvelope` (ex.: derivar de
    `generatedAt` via `OperationalCalendar.operationalDateOf`) para permanecer puro e determinístico.
  - _Requisitos:_ RD-20, RF-06.8, RF-06.19, RF-06.21.
  - _Validação:_ adicionar/estender teste de exportação cobrindo um ciclo ativo cujo último
    checkpoint já passou (espera `awaiting_closure = true`) e um ciclo em dia (espera `false`).
    `flutter test` verde.

---

## 3. Corrigir o fallback de `ExportSettings` fora do domínio (defeito real)

- [x] 3.1 Alinhar o fallback de settings aos defaults normativos
  - Arquivo: `lib/data/export/local_export_service.dart` (ramo `settingsRow == null`).
  - Problema: o fallback usa valores fora do domínio — `dayCloseTime '04:00'`,
    `nightEndTime '10:00'`, `review.time '18:00'`. Os defaults reais são
    `day_close_time = 03:00`, `night_end_time = 03:00` (seed) e revisão `sunday 21:00`
    (`review_time_min = 1260`), com `sundayNotificationEnabled = false`.
  - Opção preferida: como o seed sempre insere `settings id=1`, tratar a ausência como
    estado inválido e falhar com `ExportFailure` explícita, em vez de fabricar configuração.
  - Opção alternativa: se um fallback for mantido, refletir os defaults reais
    (`03:00`/`03:00`/`sunday 21:00`) derivados de `OperationalCalendar.seed()` /
    `SettingsValidator`/`Limits`, sem literais divergentes.
  - _Requisitos:_ RF-05.3, RF-08.5, RF-08.6.
  - _Validação:_ teste do `buildEnvelope` sem linha de settings segue o comportamento escolhido
    (falha explícita OU defaults corretos). `flutter test` verde.

---

## 4. Remover código morto e alinhar a cópia de áudio ao layout `audio/`

- [x] 4.1 Tornar a cópia de áudio consistente com o subdiretório `audio/` declarado
  - Arquivo: `lib/data/export/local_export_service.dart` (bloco de cópia de áudios no staging).
  - Problema: cria-se `stagingAudioDir = <staging>/audio` que **nunca é usado**; a cópia usa
    `dstFile = File(p.join(stagingDir.path, asset.relativePath))`. Funciona apenas se
    `relativePath` já começar com `audio/`, e o `stagingAudioDir` é código morto.
  - Correção: remover a variável não usada e garantir explicitamente que o destino fique sob
    `<staging>/audio/`, definindo uma convenção única (ex.: destino = `audio/<basename>` ou
    validar/normalizar `relativePath`). Documentar a convenção no cabeçalho do serviço.
  - Verificar o pareamento com a origem: `srcFile = <appDirectory>/<relativePath>` deve casar
    com onde o `AudioRepository` efetivamente grava os arquivos (conferir `audio_repository.dart`).
  - _Requisitos:_ RD-27, RNF-05.5.
  - _Validação:_ teste de exportação confirma que cada áudio referenciado aparece sob
    `audio/` no pacote final e que a contagem `audioFileCount` corresponde. `flutter analyze`
    sem novos warnings. `flutter test` verde.

---

## 5. Corrigir as imprecisões factuais do relatório de entrega

- [x] 5.1 Ajustar as descrições incorretas no relatório de entrega
  - Alvo: o documento/relatório de entrega (texto de comunicação, não código-fonte).
  - Correções:
    - Blackout: descrever como `[sábado 00h00 civil, abertura operacional de segunda-feira)`
      (RF-05.19/RF-05.22), **não** "22:00 às 10:00".
    - `day_close_time`: o padrão é **03h00** (RF-05.3), configurável em `[00h00, 04h00]`;
      04h00 é o limite máximo, não o padrão. Corrigir a menção a "virada às 04:00".
    - Contagem de entidades: o banco registra **19 tabelas** no `@DriftDatabase`; ajustar a
      alegação de "13 entidades".
    - Lista de tabelas: usar EXATAMENTE os 19 nomes reais abaixo. NÃO inventar `Alarms`
      (o correto é `ProtocolAlarms`, sem uma entrada `Alarms` separada) nem `MetricsSnapshots`
      (métricas não são materializadas — não existe tabela). Lista canônica (fonte de verdade:
      `lib/data/db/database.dart`):
      `Settings, Days, StudyBlocks, AudioAssets, ChangeInitiatives, PillarEntries,
      PillarWaivers, ProtocolAlarms, Holidays, Mentorships, Contacts,
      WeeklyContactSuggestions, Cycles, Checkpoints, WeeklyReviews, CheckpointEvals,
      CycleClosureInvites, Manifests, NotificationPlans`.
    - `flutter analyze`: não afirmar "conformidade total" enquanto houver issues; reportar o
      número real (meta: 8 pré-existentes após a tarefa 1).
  - _Validação:_ releitura do relatório conferindo cada número/afirmação contra
    `requirements.md`, `database.dart` e a saída real de `flutter analyze`.

---

## Ordem sugerida e verificação final

1. Tarefa 1 (baixo risco, destrava um `analyze` limpo como base de comparação).
2. Tarefas 2, 3, 4 (defeitos de código no `LocalExportService`), validando a suíte a cada uma.
3. Tarefa 5 (texto do relatório), por último.

Verificação final consolidada:
- `dart format` aplicado nos arquivos alterados.
- `flutter analyze --no-pub` = 8 issues (somente pré-existentes fora de escopo).
- `dart run tool\clock_lint.dart` limpo.
- `dart run tool\mvp_scope_check.dart` limpo.
- `flutter test --no-pub --concurrency=1` verde (>= 378 testes; pode aumentar com os
  testes adicionados nas tarefas 2 a 4).

> Nota de ambiente (Windows): se o `sqlite3.dll` ficar travado entre execuções de teste,
> encerrar processos `flutter_tester.exe` cujo `CommandLine` aponte para o workspace e
> remover `build\native_assets\windows\sqlite3.dll` antes de repetir.

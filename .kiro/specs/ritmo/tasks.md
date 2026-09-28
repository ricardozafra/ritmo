# Implementation Plan: Ritmo

## Overview

Implementação em Flutter/Dart (Android primeiro) seguindo as três camadas do design: domínio puro sem I/O, dados em `drift`/SQLite e UI com Riverpod. A ordem das tarefas parte do núcleo temporal (do qual todo o resto depende), avança para persistência, máquina de estados do dia, pilares, selo/dispensa, métricas, protocolo, feriados e fronteira operacional, e só então monta a UI do MVP. Fases 2 e 3 vêm em blocos separados, sem antecipar escopo.

Testes de propriedade usam `glados` (mínimo de 100 iterações, semente fixa em CI, um teste por propriedade de design) sobre o domínio puro com dobras controladas (`FakeClock`, banco em memória, gateways de gravação).

## Tasks

- [x] 1. Fundação do projeto, copies e limites
  - [x] 1.1 Inicializar projeto Flutter e estrutura de pastas
    - Criar o projeto Android-first e as pastas `lib/core`, `lib/domain`, `lib/data`, `lib/app`, `lib/ui`, `test/{domain,data,app,ui,generators,integration}`
    - Adicionar dependências fixadas: `drift`, `sqlite3_flutter_libs`, `riverpod`/`riverpod_generator`, `timezone`, `flutter_local_notifications`, `just_audio`, `flutter_markdown`, `go_router`, `glados`
    - _Requirements: RNF-01.1, RNF-01.3, RNF-02.1, RNF-02.3_

  - [x] 1.2 Implementar o catálogo de copies literais
    - Criar `lib/core/copy.dart` com todas as copies declaradas literais: toggle do Dia, frase do dia mute, janela noturna, dia perdido, pontes da semana, "sem pedir nada", perguntas do protocolo e da revisão, rótulo "Treino de musculação"
    - _Requirements: RF-01.8, RF-01.28, RF-03.2, RF-03.14, RF-05.14, RF-07.11, RF-07.14, RF-08.1, RNF-03.3, RNF-03.4_

  - [x] 1.3 Implementar `Result`, taxonomia de falhas e `LimitPolicy`
    - Criar `lib/core/result.dart` com `Result<T, Violation>` e a hierarquia `RitmoFailure` (violações de negócio e falhas de infraestrutura)
    - Criar `lib/core/limits.dart` como fonte única dos limites (runes para texto, bytes UTF-8 para o manifesto) e `LimitPolicy` que bloqueia apenas o excedente, sem truncamento silencioso nem mínimo implícito
    - _Requirements: RD-28, RD-29, RD-30, RD-31, RD-32, RD-33, RD-34, RD-36, RNF-05.1, RNF-05.6_

  - [x]* 1.4 Configurar glados e geradores compartilhados
    - Criar `test/generators/` com `anyOperationalDate`, `anyInstant`, `anySettings`, `anyTimeline`, `anyDayState`, `anyPillarState`, `anyStudyBlockSeq`, `anyUnicodeText`, `anyMarkdown`, `anyContactList`, `anyDeviceZone`, `anyFailurePoint`
    - Criar as dobras `FakeClock`, banco drift em memória, `RecordingNotificationGateway`, `FakeFileStore` com espaço configurável e `FakeAudioGateway`
    - _Requirements: RNF-04.1, RNF-04.2_

  - [x]* 1.5 Escrever teste de propriedade dos limites textuais
    - **Propriedade 47: Limites textuais em caracteres Unicode**
    - **Valida: Requisitos RD-28, RD-29, RD-30, RD-31, RD-32, RD-33, RD-36, RNF-05.1, RNF-05.6**

  - [x]* 1.6 Escrever teste de propriedade do catálogo de copies
    - **Propriedade 52: Catálogo de copies literais e sóbrias**
    - **Valida: Requisitos RF-02.19, RF-01.8, RF-01.28, RF-03.2, RF-03.14, RF-05.14, RF-07.11, RF-07.14, RF-08.1, RNF-03.3, RNF-03.4**

- [x] 2. Serviço de tempo operacional
  - [x] 2.1 Implementar `OperationalDate`, `LocalTimeOfDay` e `OperationalCalendar`
    - Funções puras: `civilTime`, `operationalDateOf`, `operationalOpen`, `operationalClose`, `offset(h)`, `blockDeadline`
    - _Requirements: RF-05.4, RF-05.5, RF-01.12, RNF-04.1_

  - [x] 2.2 Implementar `OperationalClock` sobre `timezone`
    - Fuso fixo `America/Sao_Paulo`, normalização de horas inexistentes/ambíguas e `deviceZoneDiverges`
    - _Requirements: RF-05.1, RF-05.2, RNF-04.1, RNF-04.2, RNF-04.3_

  - [x]* 2.3 Escrever teste de propriedade do particionamento temporal
    - **Propriedade 1: Particionamento da linha temporal operacional**
    - **Valida: Requisitos RF-05.1, RF-05.4, RF-05.5, RF-05.9, RF-05.10, RF-05.11, RNF-04.1, RNF-04.2**

  - [x] 2.4 Implementar `SettingsValidator`
    - `day_close_time ∈ [00:00, 04:00]` com padrão 03:00; `offset(night_end_time) ∈ (0, 24h]`; seed com `night_end_time = day_close_time`
    - _Requirements: RF-05.3, RA-01.1, RF-01.12_

  - [x]* 2.5 Escrever teste de propriedade da validação de fronteiras
    - **Propriedade 2: Validação das fronteiras configuráveis**
    - **Valida: Requisitos RF-05.3, RA-01.1, RF-01.12**

  - [x] 2.6 Implementar `NightWindow`
    - Função pura de `now` e data operacional que retorna `{study, recovery}`, `{recovery}` + copy literal, ou nenhuma ação após o fechamento
    - _Requirements: RF-01.11, RF-01.13, RF-01.17, RF-01.19, RF-01.21_

  - [x]* 2.7 Escrever teste de propriedade da janela noturna
    - **Propriedade 3: Particionamento da janela noturna**
    - **Valida: Requisitos RF-01.11, RF-01.13, RF-01.17, RF-01.19, RF-01.21**

- [x] 3. Checkpoint — núcleo temporal
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Persistência: schema drift versão 1
  - [x] 4.1 Criar `RitmoDatabase` e as tabelas do dia
    - `settings` (linha única), `days`, `pillar_entries` com `UNIQUE(operational_date, pillar)`, `study_blocks` com `CHECK`s de duração e deadline; habilitar `PRAGMA foreign_keys` e armazenar o banco no diretório privado do aplicativo
    - _Requirements: RD-1, RD-2, RD-3, RD-4, RD-5, RD-6, RD-7, RD-8, RD-9, RD-10, RNF-02.2, RNF-04.6_

  - [x] 4.2 Criar tabelas de dispensa, protocolo e feriado com índices parciais
    - `pillar_waivers` com `UNIQUE ... WHERE revoked_at IS NULL`; `protocol_alarms` com `UNIQUE(generation_id) WHERE state <> 'invalidated'`; `holidays` com instantes e motivos auditáveis
    - _Requirements: RD-11, RD-12, RD-13, RD-14, RD-15, RD-16_

  - [x] 4.3 Criar as demais tabelas e o seed da migração v1
    - `mentorships`, `contacts`, `weekly_contact_suggestions`, `cycles`, `checkpoints`, `checkpoint_evals`, `cycle_closure_invites`, `weekly_reviews`, `manifests`, `change_initiatives`, `audio_assets`, `notification_plans`
    - Seed do ciclo ativo com a finalidade exata e os três checkpoints (`2026-12-31` Innovative, `2027-02-28` Strategic Thinking, `2027-06-30` Change Advocate), além das três mentorias fixas `ST|IN|CA`; manter `sync_enabled = 0` e notificação dominical desligada
    - _Requirements: RD-1, RD-17, RD-18, RD-19, RD-20, RD-21, RD-22, RD-23, RD-24, RD-25, RD-37, RF-06.1, RF-06.2, RF-07.1, RA-01.4, RF-08.6_

  - [x] 4.4 Implementar `GuardedWriter`/`GuardedDayWriter` e helpers transacionais
    - `assertMutable` executado dentro da transação, imediatamente antes da escrita; guarda de revisão `finalized`; caminho separado para reclassificação por feriado
    - _Requirements: RF-01.27, RF-02.6, RF-02.27, RF-08.23, RD-26, RNF-05.8_

  - [x]* 4.5 Escrever testes de integração de restrições do banco
    - Índices únicos parciais (dispensa ativa, protocolo vivo, iniciativa ativa e ciclo ativo) sob inserções concorrentes; `CHECK`s de `study_blocks`; FK inválida rejeitada
    - _Requirements: RD-5, RD-9, RD-11, RD-14, RD-20, RD-25, RNF-04.6_

  - [x]* 4.6 Criar o schema dump v1 e o harness de testes de migração
    - Verificar criação do schema v1, seeds e constraints em banco novo; versionar o dump e preparar o harness que, a partir da primeira versão posterior, aplicará v(n-1) → v(n) sobre banco povoado e comparará todos os pares `(id, operational_date)`
    - _Requirements: RF-06.1, RF-06.2, RF-06.16, RD-38, RNF-05.8_

- [x] 5. Dia: máquina de estados, materialização e selo
  - [x] 5.1 Implementar `DayStateMachine`
    - Comandos `SealDay`, `ReopenDay`, `CloseDay`, `ApplyHoliday`, `RemoveHoliday`; invariantes de `effective_result`, `mute_cause`, `previous_result` e `seal_timestamp`; rejeição com motivo neutro
    - _Requirements: RF-02.1, RF-02.4, RF-02.6, RF-05.6, RF-05.12, RF-05.13, RF-05.17_

  - [x]* 5.2 Escrever teste de propriedade do congelamento
    - **Propriedade 7: Congelamento é absorvente**
    - **Valida: Requisitos RF-01.27, RF-02.6, RF-02.27, RF-05.32, RF-08.23, RF-08.26**

  - [x] 5.3 Implementar `ensureDayMaterialized` no repositório de dias
    - Única porta de criação de `Day`, em transação, com classificação inicial (`mute` em fim de semana/feriado ativo, `unsealed` em dia útil) e nunca antes de `activation_date`; persistir `activation_date` no primeiro uso
    - _Requirements: RF-05.7, RF-05.8, RF-05.12, RF-05.13, RNF-04.4_

  - [x] 5.4 Implementar `sealEligible` e os comandos de selo/reabertura
    - Selo com três pilares concluídos ou dois concluídos + um coberto pela dispensa ativa; reabertura explícita limpa `seal_timestamp`
    - _Requirements: RF-02.1, RF-02.2, RF-02.3, RF-02.4, RF-02.5, RF-02.7, RF-02.8_

  - [x]* 5.5 Escrever teste de propriedade da elegibilidade do selo
    - **Propriedade 8: Elegibilidade do selo**
    - **Valida: Requisitos RF-02.1, RF-02.2, RF-02.3, RF-02.7, RF-02.8**

  - [x]* 5.6 Escrever teste de propriedade do último `seal_timestamp`
    - **Propriedade 9: Selo e reabertura preservam apenas o último timestamp**
    - **Valida: Requisitos RF-02.2, RF-02.4, RF-02.5**

- [x] 6. Três pilares, bloco de Estudo e iniciativa de mudança
  - [x] 6.1 Implementar `PillarRules` e repositórios de `pillar_entries`
    - Conclusão de `morning` (treino + briefing ou dispensa), `day` (toggle literal, nota sempre opcional) e `night` (Recuperação confirmada ou Estudo encerrado); briefing automático ao fim do MP3 local ou manual com duração zero
    - _Requirements: RF-01.2, RF-01.3, RF-01.4, RF-01.5, RF-01.6, RF-01.8, RF-01.9, RF-01.10, RF-01.16, RF-01.18, RF-02.11, RF-04.1, RF-04.2_

  - [x]* 6.2 Escrever teste de propriedade da conclusão de pilares
    - **Propriedade 5: Conclusão de pilares**
    - **Valida: Requisitos RF-01.3, RF-01.9, RF-01.10, RF-01.16, RF-01.18, RF-02.11, RF-04.1, RF-04.2**

  - [x] 6.3 Implementar ciclo de vida do `StudyBlock` e `OrphanBlockCloser`
    - Iniciar apenas antes de `block_deadline`, encerrar no deadline, fechar bloco órfão silenciosamente no deadline persistido, preservar a `operational_date` de origem
    - _Requirements: RF-01.12, RF-01.13, RF-01.14, RF-01.15, RF-01.20, RF-01.22, RD-9, RD-10, RNF-04.5, RNF-04.6_

  - [x]* 6.4 Escrever teste de propriedade do bloco de Estudo
    - **Propriedade 4: Invariante do bloco de Estudo**
    - **Valida: Requisitos RF-01.12, RF-01.14, RF-01.15, RF-01.22, RD-9, RD-10, RNF-04.5, RNF-04.6**

  - [x] 6.5 Implementar os comandos reversíveis do dia aberto
    - Marcar/desmarcar treino e briefing, ligar/desligar o toggle, editar/remover nota, cancelar Estudo descartando o bloco-rascunho, substituir Estudo ↔ Recuperação dentro dos limites temporais
    - _Requirements: RF-01.23, RF-01.24, RF-01.25, RF-01.26, RF-01.29, RF-02.22_

  - [x]* 6.6 Escrever teste de propriedade da reversibilidade
    - **Propriedade 6: Reversibilidade em `open/unsealed`**
    - **Valida: Requisitos RF-01.23, RF-01.24, RF-01.25, RF-01.26, RF-01.29, RF-02.4, RF-02.22**

  - [x] 6.7 Implementar `ChangeInitiative`
    - No máximo uma iniciativa ativa via índice parcial; `DayEntry` referencia a iniciativa vigente
    - _Requirements: RF-01.7, RD-25_

  - [x]* 6.8 Escrever teste de propriedade da iniciativa única
    - **Propriedade 53: Iniciativa de mudança única**
    - **Valida: Requisitos RF-01.7, RD-25**

- [x] 7. Checkpoint — dia, pilares e selo
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Dispensa de pilar com revogação
  - [x] 8.1 Implementar `WaiverPolicy.create`
    - Exigir pilar e motivo não vazio após trim; no máximo uma dispensa ativa por data operacional
    - _Requirements: RF-02.9, RF-02.10, RD-11_

  - [x]* 8.2 Escrever teste de propriedade do motivo da dispensa
    - **Propriedade 10: Dispensa exige motivo com conteúdo**
    - **Valida: Requisitos RF-02.9**

  - [x]* 8.3 Escrever teste de propriedade da unicidade e do histórico
    - **Propriedade 11: No máximo uma dispensa ativa, com histórico monotônico**
    - **Valida: Requisitos RF-02.10, RF-02.25, RF-02.26, RF-02.28, RD-11**

  - [x] 8.4 Implementar `WaiverRecurrence`
    - Caminhada para trás sobre dias úteis ignorando dias `mute`, contando apenas dispensas ativas do mesmo pilar, com os três cortes de cadeia; veredito que exige o diálogo da Regra do Retorno antes de persistir
    - _Requirements: RF-02.12, RF-02.13, RF-02.14, RF-02.15, RF-02.21, RF-05.15_

  - [x]* 8.5 Escrever teste de propriedade da recorrência
    - **Propriedade 12: Recorrência de dispensa segue o modelo de referência**
    - **Valida: Requisitos RF-02.12, RF-02.13, RF-02.14, RF-02.15, RF-02.21**

  - [x] 8.6 Implementar `revokeForCompletion` transacional
    - Confirmação neutra, `revoked_at` preenchido, pilar concluído e efeito sobre selo/recorrência removido na mesma transação; rejeição em dia encerrado; dispensa revogada permanece auditável
    - _Requirements: RF-02.23, RF-02.24, RF-02.25, RF-02.26, RF-02.27, RF-02.28, RD-26_

- [x] 9. Métricas
  - [x] 9.1 Implementar `MetricsCalculator` e providers derivados
    - Taxa = dias úteis elegíveis encerrados e selados / dias úteis elegíveis encerrados; exclusão de dias abertos, `mute` e anteriores a `activation_date`; nenhuma leitura de `NightKind`; nenhum streak, ponto ou contador
    - _Requirements: RF-02.16, RF-02.17, RF-02.18, RF-02.19, RF-02.20, RF-04.3, RF-04.5, RF-05.8, RF-05.15_

  - [x]* 9.2 Escrever teste de propriedade da fórmula da taxa
    - **Propriedade 13: Fórmula da taxa**
    - **Valida: Requisitos RF-02.16, RF-02.17, RF-02.18, RF-02.20, RF-05.8, RF-05.15**

  - [x]* 9.3 Escrever teste de propriedade da equivalência Estudo/Recuperação
    - **Propriedade 14: Estudo e Recuperação são equivalentes na métrica**
    - **Valida: Requisitos RF-04.3, RF-04.5**

- [x] 10. Sequências de falha e Alarme de Protocolo
  - [x] 10.1 Implementar `FailureSequenceDetector`
    - Detecção pura e determinística com `generationId = "seq:" + startDate`, ignorando dias `mute` e datas anteriores a `activation_date`; dia selado parte a sequência
    - _Requirements: RF-03.3, RF-03.5, RF-03.6, RF-03.7, RF-02.16_

  - [x]* 10.2 Escrever teste de propriedade da consecutividade
    - **Propriedade 16: Consecutividade ignora dias `mute` e o período pré-ativação**
    - **Valida: Requisitos RF-03.5, RF-03.6, RF-03.7, RF-02.16**

  - [x] 10.3 Implementar `ProtocolReconciler`
    - Reconciliação transacional com expansão até o início da sequência, `INSERT ... ON CONFLICT DO NOTHING`, mutex de processo, atualização de `sequence_length`/`end_date` e invalidação preservando `previous_state` e dados
    - _Requirements: RF-03.3, RF-03.4, RF-03.8, RF-03.16, RF-03.17, RF-03.18, RF-03.19, RF-03.20, RF-03.22, RD-14, RD-15, RNF-04.10_

  - [x]* 10.4 Escrever teste de propriedade da unicidade por geração
    - **Propriedade 17: Um protocolo vivo por geração, idempotente sob repetição**
    - **Valida: Requisitos RF-03.3, RF-03.4, RF-03.8, RF-03.22, RD-14**

  - [x]* 10.5 Escrever teste de propriedade da invalidação absorvente
    - **Propriedade 18: A invalidação é absorvente e o histórico nunca encolhe**
    - **Valida: Requisitos RF-03.16, RF-03.17, RF-03.18, RF-03.19, RF-03.20, RF-03.24, RF-05.25, RD-15, RNF-04.10**

  - [x] 10.6 Implementar `ProtocolSessionGate` e a persistência das respostas
    - Um protocolo por abertura a frio, o de menor `start_date`; responder persiste data de disparo, causa, `plan|execution` e ajuste e muda para `answered`; nenhum push
    - _Requirements: RF-03.9, RF-03.10, RF-03.11, RF-03.12, RF-03.14, RF-03.15, RF-03.21, RF-03.23, RD-12, RD-13_

  - [x]* 10.7 Escrever teste de propriedade da apresentação por abertura
    - **Propriedade 19: Um protocolo por abertura, o mais antigo primeiro**
    - **Valida: Requisitos RF-03.9, RF-03.10, RF-03.11, RF-03.12, RF-03.23**

  - [x] 10.8 Implementar a derivação da copy de dia único
    - Disponibilizar a copy literal quando a sequência corrente tem exatamente um dia útil não selado, em cinza neutro
    - _Requirements: RF-03.1, RF-03.2_

  - [x]* 10.9 Escrever teste de propriedade da copy de dia único
    - **Propriedade 20: Copy de dia único**
    - **Valida: Requisitos RF-03.2**

- [x] 11. Feriados manuais e recálculo
  - [x] 11.1 Implementar `HolidayRecalculation`
    - `preview` neutro antes da confirmação; `apply`/`remove` em uma transação com upsert de `Holiday`, reclassificação de `Day` e `reconcileProtocols(from:)`; `reason_text` opcional auditável; nada é apagado
    - Invalidar providers derivados e publicar um evento interno de alteração para que o scheduler da Fase 2 possa reconciliar planos, sem criar dependência de notificações no MVP
    - _Requirements: RF-05.13, RF-05.16, RF-05.17, RF-05.18, RF-05.25, RF-05.26, RF-05.27, RF-05.28, RF-05.36, RD-16, RD-26, RNF-04.10_

  - [x]* 11.2 Escrever teste de propriedade do round trip de feriado
    - **Propriedade 21: Round trip de feriado restaura o resultado anterior**
    - **Valida: Requisitos RF-05.13, RF-05.17, RF-05.18, RF-05.27, RF-05.28, RD-16**

  - [x]* 11.3 Escrever teste de propriedade do recálculo idempotente
    - **Propriedade 22: Recálculo idempotente e não destrutivo**
    - **Valida: Requisitos RF-05.16, RF-05.36, RNF-04.10, RNF-05.5**

- [x] 12. Checkpoint — dispensa, métricas, protocolo e feriados
  - Ensure all tests pass, ask the user if questions arise.

- [x] 13. Fronteira operacional em foreground
  - [x] 13.1 Implementar `BoundaryObserver` e o registro de edições pendentes
    - Timer até `operationalClose`, `onResumed` reconciliando fronteiras perdidas em ordem crescente, `EditorRegistry` com snapshot do estado presente
    - _Requirements: RF-05.29, RF-05.30, RF-05.33, RNF-04.4, RNF-04.11, RNF-04.13_

  - [x] 13.2 Implementar `BoundaryCrossingService`
    - Executar em uma transação o snapshot/autosave na data original, `closed_at` somente quando nulo, fechamento de blocos órfãos e `reconcileProtocols`; após o commit, publicar o evento de fronteira por uma porta `ScheduleReconciler`, com implementação no-op no MVP e adaptador real somente na Fase 2
    - Emitir estado de UI read-only com aviso neutro, sem notificação e sem reatribuir dados à nova data operacional
    - _Requirements: RF-05.5, RF-05.31, RF-05.32, RF-05.34, RF-05.35, RD-26, RD-38, RNF-04.12, RNF-05.8_

  - [x]* 13.3 Escrever teste de propriedade da atomicidade da fronteira
    - **Propriedade 23: Atomicidade da fronteira em foreground**
    - **Valida: Requisitos RF-05.29, RF-05.30, RF-05.31, RF-05.32, RF-05.34, RF-05.35, RNF-04.11, RNF-04.12**

  - [x]* 13.4 Escrever teste de propriedade dos fluxos não diários
    - **Propriedade 24: Fluxos não diários atravessam a fronteira intactos**
    - **Valida: Requisitos RF-05.33, RNF-04.13**

  - [x]* 13.5 Escrever teste de propriedade da atomicidade das transações
    - **Propriedade 25: Transações são tudo ou nada**
    - **Valida: Requisitos RD-26, RNF-05.5, RNF-05.8**

  - [x]* 13.6 Escrever teste de propriedade da unicidade por chave lógica
    - **Propriedade 26: Unicidade por chave lógica sob mudança de fuso e relógio**
    - **Valida: Requisitos RNF-04.3, RNF-04.4, RD-2**

  - [x]* 13.7 Escrever teste de propriedade da imutabilidade da `operational_date`
    - **Propriedade 27: `operational_date` nunca é reclassificada**
    - **Valida: Requisitos RF-01.20, RF-05.32, RD-38**

  - [x]* 13.8 Escrever teste de integração de fronteiras perdidas
    - App fechado durante várias fronteiras: materialização em ordem, um `closed_at` por dia, bloco órfão fechado no deadline
    - _Requirements: RNF-04.4, RNF-04.5_

- [x] 14. Ciclos: seed e estados derivados do MVP
  - [x] 14.1 Implementar `CyclePolicy`
    - `nextFutureCheckpoint`, `countdownDays` em dias corridos no fuso oficial, `awaitingClosure` derivado sem arquivamento ou criação automática
    - _Requirements: RF-06.3, RF-06.4, RF-06.8, RF-06.15, RF-06.18, RF-06.19, RF-06.21, RD-20_

  - [x]* 14.2 Escrever teste de propriedade do próximo checkpoint
    - **Propriedade 32: Próximo checkpoint e contagem regressiva**
    - **Valida: Requisitos RF-06.4, RF-06.15, RF-06.18**

  - [x]* 14.3 Escrever teste de propriedade do estado "aguardando encerramento"
    - **Propriedade 33: “Aguardando encerramento” é derivado e não bloqueia**
    - **Valida: Requisitos RF-06.8, RF-06.19, RF-06.21**

  - [x]* 14.4 Escrever teste de exemplo do seed do ciclo
    - Verificar a finalidade literal e as três datas/competências exatas do ciclo seed
    - _Requirements: RF-06.1, RF-06.2, RF-06.16_

- [x] 15. Pedra, manifesto e parser do Juramento
  - [x] 15.1 Empacotar o asset do manifesto e validar o limite
    - Incluir `assets/manifesto/manifesto.md` integral e a verificação de build de ≤ 1 MiB em UTF-8
    - _Requirements: RF-09.1, RNF-05.7_

  - [x] 15.2 Implementar `ManifestService`
    - `ensureLocalCopy` que só insere quando ausente, `readForDisplay` com fallback pelo asset sem sobrescrever e `save` rejeitando acima de 1 MiB
    - _Requirements: RF-09.2, RF-09.3, RF-09.4, RF-09.5, RF-09.13, RD-24, RD-34_

  - [x]* 15.3 Escrever teste de propriedade da cópia local
    - **Propriedade 44: A cópia local do manifesto é idempotente e nunca sobrescrita**
    - **Valida: Requisitos RF-09.2, RF-09.3, RF-09.5, RF-09.13**

  - [x]* 15.4 Escrever teste de propriedade do limite em bytes UTF-8
    - **Propriedade 48: Limite do manifesto em bytes UTF-8**
    - **Valida: Requisitos RD-34, RNF-05.7, RF-09.4**

  - [x] 15.5 Implementar `OathParser`
    - Normalização de terminadores, heading exato após trim, salto de linhas em branco e coleta do primeiro bloco contíguo de blockquote; `null` nos demais casos
    - _Requirements: RF-09.7, RF-09.8, RF-09.10_

  - [x]* 15.6 Escrever teste de propriedade do parser do Juramento
    - **Propriedade 45: Parser do Juramento**
    - **Valida: Requisitos RF-09.7, RF-09.8, RF-09.9, RF-09.10, RF-09.12**

  - [x] 15.7 Implementar o renderizador Markdown seguro
    - `flutter_markdown` com HTML bruto desabilitado, manifesto sempre renderizado integralmente e destaque serifado itálico apenas no intervalo do Juramento
    - _Requirements: RF-09.6, RF-09.9, RF-09.10, RNF-02.5_

  - [x]* 15.8 Escrever teste de propriedade da renderização sem HTML executável
    - **Propriedade 46: Renderização de Markdown não executa HTML**
    - **Valida: Requisitos RF-09.6, RNF-02.5**

- [x] 16. Contrato de exportação (MVP sem execução)
  - [x] 16.1 Implementar o modelo versionado do envelope de exportação
    - Criar DTOs Dart e schema/fixture JSON canônico com identificadores, datas operacionais, instantes no fuso oficial, estados, `mute_cause`, `previous_result`, estados derivados e referências de áudio
    - Implementar somente serialização/desserialização pura para validar o contrato; não criar serviço, rota, comando, upload ou qualquer caminho invocável de exportação/sync no MVP
    - _Requirements: RA-01.9, RA-01.10, RD-27, RD-37_

  - [x]* 16.2 Escrever teste de propriedade do round trip do contrato
    - **Propriedade 49: Round trip do contrato de exportação**
    - **Valida: Requisitos RA-01.9, RD-27, RD-37**

- [x] 17. UI do MVP
  - [x] 17.1 Montar navegação por fase com `go_router`
    - Habilitar no MVP somente Hoje, Ritmo, Pedra e Configurações, além do fluxo de Protocolo sobre o shell; manter Pessoas, Revisão, editor/Encerramento de Ciclo e exportação sem rota invocável até suas fases
    - Garantir que o fluxo de Protocolo apresente Pedra antes do formulário sem transformar fluxos futuros em destinos do MVP
    - _Requirements: RF-03.13, RF-06.13, RF-09.11, RA-01.10_

  - [x] 17.2 Implementar e conectar a tela Hoje do MVP
    - Projetar a tela por `todayViewProvider` e data operacional: finalidade/countdown ou “aguardando encerramento”, edição em `open/unsealed`, leitura com “Reabrir o Dia” em `open/sealed`, read-only em dia encerrado, somente a frase literal em dia `mute` e indicador discreto de fuso divergente
    - Conectar os controles de Manhã (treino, MP3 local, conclusão automática e manual), Dia (toggle literal, iniciativa única visível e nota textual opcional) e Noite (Estudo/Recuperação segundo `NightWindow`, cancelamento, remoção e substituição), sem voz no MVP
    - Conectar criação/recorrência/revogação de dispensa, confirmações neutras, indicação do que falta, selo e reabertura aos controllers transacionais; nunca editar dia fechado nem reatribuir registro
    - _Requirements: RF-01.1, RF-01.2, RF-01.4, RF-01.5, RF-01.6, RF-01.7, RF-01.8, RF-01.10, RF-01.11, RF-01.17, RF-01.18, RF-01.23, RF-01.24, RF-01.25, RF-01.26, RF-01.27, RF-02.1, RF-02.4, RF-02.8, RF-02.9, RF-02.14, RF-02.23, RF-05.2, RF-05.9, RF-05.14, RF-06.3, RF-06.4, RF-06.18, RNF-01.2_

  - [x]* 17.3 Escrever teste de propriedade da projeção do dia `mute`
    - **Propriedade 31: Projeção do dia `mute`**
    - **Valida: Requisitos RF-05.12, RF-05.14**

  - [x]* 17.4 Escrever teste de propriedade da indistinguibilidade da Recuperação
    - **Propriedade 15: Recuperação é indistinguível na apresentação**
    - **Valida: Requisitos RF-04.4**

  - [x] 17.5 Implementar a tela Ritmo
    - Taxa sem gamificação, heatmap mensal (destaque para `sealed`, cinza neutro para `unsealed` encerrado, vazio para `mute`), detalhe do dia e histórico de protocolos
    - _Requirements: RF-02.19, RF-03.1, RF-03.20, RA-01.5, RA-01.6, RA-01.7, RA-01.8_

  - [x]* 17.6 Escrever teste de propriedade do detalhe do dia
    - **Propriedade 50: O detalhe do dia reflete o que está persistido**
    - **Valida: Requisitos RA-01.5, RA-01.6, RA-01.8**

  - [x] 17.7 Implementar o fluxo do Protocolo
    - Abertura selecionada pelo `ProtocolSessionGate`, Pedra antes do formulário e as três perguntas literais; persistir a resposta e encerrar a sessão sem revelar outro protocolo pendente
    - _Requirements: RF-03.10, RF-03.11, RF-03.13, RF-03.14, RF-03.15, RF-09.11_

  - [x] 17.8 Implementar a tela Pedra e o modo de edição
    - Leitura integral offline com destaque do Juramento e edição/salvamento da cópia local com mensagem neutra no limite
    - _Requirements: RF-09.4, RF-09.6, RF-09.9, RNF-05.1_

  - [x] 17.9 Implementar a tela Configurações do MVP
    - Persistir `day_close_time` e `night_end_time` validados, aplicando mudança de fechamento somente a fronteiras ainda abertas e sem reabrir, renomear ou duplicar dias encerrados
    - Conectar feriados manuais à prévia/confirmação neutra e manter a flag de sync desligada; publicar eventos internos de mudança para integração posterior do scheduler sem habilitar notificações no MVP
    - _Requirements: RF-05.3, RF-05.23, RF-05.26, RF-05.28, RA-01.1, RA-01.3, RA-01.4_

  - [x]* 17.10 Escrever teste de propriedade da escalabilidade tipográfica
    - **Propriedade 54: Escalabilidade tipográfica sem perda de ações**
    - **Valida: Requisitos RNF-03.1**

  - [x]* 17.11 Escrever testes de exemplo, edge case e integração da UI do MVP
    - Copies literais; taxa `3/4`; sábado 01h mostra sexta aberta e segunda 01h mostra domingo `mute`; briefing manual com duração zero e fim do MP3 local com rede indisponível; cancelamento/substituição noturna; revogação de dispensa; dois protocolos pendentes com o segundo só em nova abertura; protocolo invalidado por feriado com novo `pending`; indicador de fuso divergente; manifesto com dois blockquotes
    - _Requirements: RF-01.4, RF-01.5, RF-01.6, RF-01.29, RF-02.20, RF-02.28, RF-03.23, RF-03.24, RF-05.2, RF-05.10, RF-05.11, RF-05.25, RF-09.12, RNF-03.4_

- [x] 18. Verificações estáticas e smoke do MVP
  - [x] 18.1 Criar o lint customizado do relógio
    - Proibir `DateTime.now()` fora de `OperationalClock`
    - _Requirements: RNF-04.1, RNF-04.2_

  - [x]* 18.2 Escrever testes de smoke e verificações estáticas do escopo MVP
    - Varredura antigamificação; ausência de rotas/serviços invocáveis de Pessoas, Revisão, editor/Encerramento de Ciclo e exportação; flags padrão; ausência de telemetria, cliente HTTP, backend, login e permissões de rede desnecessárias; ausência de estado/duração/reconciliação manual de timer; contraste automatizado dos pares de tokens
    - _Requirements: RF-02.19, RF-03.21, RF-06.13, RA-01.4, RA-01.10, RD-10, RNF-02.1, RNF-02.2, RNF-02.3, RNF-03.2, Restrições 6.1, 6.5, 6.6_

  - [x]* 18.3 Escrever benchmark instrumentado da tela Hoje
    - Criar teste de desempenho reproduzível para cold start até a tela utilizável, com consulta somente da data operacional corrente e orçamento de menos de 2 segundos no Motorola Edge 70 Pro; registrar falha automática quando o orçamento for excedido
    - _Requirements: RNF-01.2_

- [x] 19. Checkpoint — MVP completo
  - Ensure all tests pass, ask the user if questions arise.

- [x] 20. Fase 2 — Pessoas
  - [x] 20.1 Implementar Mentoria
    - Três cartões fixos (ST, IN, CA) com nome e data do último encontro editáveis e badge visual suave após mais de 30 dias, sem push
    - _Requirements: RF-07.1, RF-07.2, RF-07.3, RF-07.21, RD-17_

  - [x]* 20.2 Escrever teste de propriedade do badge de recência
    - **Propriedade 41: Badge de recência de mentoria**
    - **Valida: Requisitos RF-07.3, RF-07.21**

  - [x] 20.3 Implementar contatos e `ContactOrdering`
    - Cadastro com nome, contexto, `last_touch_date` opcional e `created_at`; ordem semanal com nulos primeiro, data mais antiga, empate por `created_at` e desempate estável por `id`; nenhuma inferência a partir de `Mentorship`
    - _Requirements: RF-07.4, RF-07.5, RF-07.6, RF-07.18, RF-07.19, RF-07.20, RF-07.22, RD-18_

  - [x]* 20.4 Escrever teste de propriedade da ordem semanal
    - **Propriedade 37: Ordem semanal é uma ordem total determinística**
    - **Valida: Requisitos RF-07.5, RF-07.6, RF-07.16, RD-18**

  - [x]* 20.5 Escrever teste de propriedade da separação Mentoria/Contatos
    - **Propriedade 40: Mentoria e Contatos permanecem separados**
    - **Valida: Requisitos RF-07.18, RF-07.19, RF-07.20, RF-07.22, RD-17, RD-18**

  - [x] 20.6 Implementar `WeeklyContactSuggestion`
    - Criação na abertura operacional de segunda, reuso durante a semana, `done` atualizando `last_touch_date`, `skipped` avançando sem penalidade, esgotamento com copy literal e sem reinício, escolha manual permitida
    - _Requirements: RF-07.7, RF-07.8, RF-07.9, RF-07.10, RF-07.11, RF-07.12, RF-07.15, RD-19_

  - [x]* 20.7 Escrever teste de propriedade da estabilidade da sugestão
    - **Propriedade 38: A sugestão persistida é estável na semana**
    - **Valida: Requisitos RF-07.7, RF-07.8, RF-07.17**

  - [x]* 20.8 Escrever teste de propriedade da progressão semanal
    - **Propriedade 39: Progressão semanal sem reinício nem penalidade**
    - **Valida: Requisitos RF-07.9, RF-07.10, RF-07.11, RF-07.12, RF-07.15, RD-19**

  - [x] 20.9 Implementar e habilitar a tela Pessoas
    - Habilitar o destino Pessoas somente na Fase 2 e conectar cartões de mentoria, lista de contatos, sugestão da semana com a copy literal "sem pedir nada" e convite único quando a lista está vazia
    - _Requirements: RF-07.13, RF-07.14, RF-07.15_

- [x] 21. Fase 2 — Revisão Semanal em texto
  - [x] 21.1 Implementar e habilitar o fluxo de Revisão Semanal
    - Habilitar a rota manual na Fase 2, inclusive durante a home dominical `mute`; apresentar as três perguntas literais sem timer nem permanência mínima
    - Criar a revisão em `draft`, realizar autosave por campo e exigir finalização explícita para torná-la read-only
    - _Requirements: RF-08.1, RF-08.2, RF-08.4, RF-08.10, RF-08.22, RF-08.23, RD-23_

  - [x]* 21.2 Escrever teste de propriedade do autosave
    - **Propriedade 42: Autosave sem finalização implícita**
    - **Valida: Requisitos RF-08.22, RF-08.25**

  - [x] 21.3 Implementar e habilitar o histórico de revisões
    - Habilitar na Fase 2 a lista cronológica por semana operacional e o detalhe com respostas, áudio quando futuramente houver e avaliações associadas quando houver; estado vazio neutro, sem busca nem filtro e sem edição de finalizadas
    - _Requirements: RF-08.19, RF-08.20, RF-08.21, RF-08.24, RF-08.26_

  - [x]* 21.4 Escrever teste de propriedade do histórico
    - **Propriedade 43: Histórico de revisões cronológico e completo**
    - **Valida: Requisitos RF-08.19, RF-08.20, RF-08.24, RF-08.26**

- [x] 22. Fase 2 — Notificações com blackout
  - [x] 22.1 Implementar `BlackoutPolicy` e `ReviewScheduleValidator`
    - Bloqueio em `[sábado 00:00 civil, operationalOpen(segunda))`, sem `max(03h, fechamento)`; configuração da revisão em domingo 20:00–22:00 ou segunda após a abertura operacional
    - _Requirements: RF-05.19, RF-05.22, RF-08.5, RF-08.7, RF-08.14, RA-01.2_

  - [x] 22.2 Implementar `NotificationScheduler` e o gateway local
    - Planos com chave idempotente semanal, blackout aplicado antes de persistir e antes de entregar, `zonedSchedule` com `TZDateTime`, revalidação na entrega, exceção dominical opt-in desligada por padrão com disparo único e sem follow-up, notificação de segunda somente após a abertura operacional; permissão negada mantém o app funcional
    - Conectar o scheduler aos eventos internos de configurações, feriados e fronteira criados no MVP, sem introduzir dependência reversa da Fase 1 sobre a Fase 2
    - _Requirements: RF-05.20, RF-05.21, RF-05.24, RF-08.6, RF-08.8, RF-08.9, RF-08.11, RF-08.13, RF-08.15, RNF-04.7, RNF-04.8, RNF-04.9_

  - [x]* 22.3 Escrever teste de propriedade do blackout
    - **Propriedade 28: Nenhum plano persistido viola o blackout**
    - **Valida: Requisitos RF-05.19, RF-05.22, RF-05.24, RF-08.7, RF-08.15, RNF-04.7**

  - [x]* 22.4 Escrever teste de propriedade da unicidade semanal das notificações
    - **Propriedade 29: Unicidade semanal e janela de entrega das notificações**
    - **Valida: Requisitos RF-05.20, RF-05.21, RF-08.8, RF-08.11, RF-08.13, RF-08.14, RF-08.17, RF-08.18, RNF-04.8, RNF-04.9**

  - [x]* 22.5 Escrever teste de propriedade da home dominical
    - **Propriedade 30: A exceção dominical não altera a home**
    - **Valida: Requisitos RF-05.20, RF-08.9, RF-08.12**

  - [x]* 22.6 Escrever testes de integração, exemplo e allow-list das notificações
    - `zonedSchedule` no fuso oficial; configuração padrão sem entrega no domingo 20h–22h; opt-in 21h com disparo único e home permanecendo `mute`; revisão de segunda não entregue enquanto a data operacional for domingo
    - Verificar estaticamente que `NotificationKind` contém somente revisão dominical e revisão de segunda, sem protocolo, Encerramento de Ciclo ou mentoria
    - _Requirements: RF-03.21, RF-05.20, RF-06.10, RF-07.21, RF-08.16, RF-08.17, RF-08.18, RNF-04.7, RNF-04.8, Restrição 6.5_

- [x] 23. Checkpoint — Fase 2
  - Ensure all tests pass, ask the user if questions arise.

- [x] 24. Fase 3 — Ciclos, avaliações, voz e exportação
  - [x] 24.1 Implementar o editor de ciclos e o convite de encerramento
    - Habilitar somente na Fase 3 o editor de finalidade, período e checkpoints; implementar `CycleClosureInvite` com no máximo um convite adiável por semana operacional junto à Revisão, sem push
    - _Requirements: RF-06.9, RF-06.10, RF-06.13, RF-06.17, RF-06.20, RD-20, RD-21_

  - [x]* 24.2 Escrever teste de propriedade do convite de encerramento
    - **Propriedade 35: Convite de encerramento no máximo uma vez por semana**
    - **Valida: Requisitos RF-06.9, RF-06.10, RF-06.17**

  - [x] 24.3 Implementar o fluxo de Encerramento de Ciclo
    - Releitura do manifesto, avaliação final e campos do novo ciclo; conclusão arquiva o anterior como read-only e ativa o novo preservando avaliações por identificador
    - _Requirements: RF-06.11, RF-06.12, RF-06.14, RD-20_

  - [x]* 24.4 Escrever teste de propriedade do rollover de ciclo
    - **Propriedade 34: Rollover de ciclo preserva histórico**
    - **Valida: Requisitos RF-06.11, RF-06.12, RF-06.14, RD-20**

  - [x] 24.5 Implementar autoavaliações e evolução por competência
    - Incluir na Revisão Semanal a autoavaliação quando ocorrer no mês civil do checkpoint, aceitando somente `BD|B|I|A|E` e notas opcionais; habilitar na Fase 3 a evolução/gráfico por competência sem gamificação
    - _Requirements: RF-06.5, RF-06.6, RF-06.7, RD-22_

  - [x]* 24.6 Escrever teste de propriedade da autoavaliação
    - **Propriedade 36: Autoavaliação no mês civil do checkpoint**
    - **Valida: Requisitos RF-06.5, RF-06.6, RD-22**

  - [x] 24.7 Implementar áudio local opcional
    - Nota de voz do Pilar do Dia (≤ 5 min) e áudio da Revisão (≤ 30 min), sem transcrição, com encerramento gracioso no limite, verificação prévia de espaço e mensagem neutra
    - Persistir referência, tipo, duração e tamanho em diretório privado; falha não pode substituir arquivo ou metadado anteriormente válido
    - _Requirements: RF-01.10, RF-08.3, RD-35, RD-37, RNF-02.2, RNF-05.2, RNF-05.3, RNF-05.5_

  - [x] 24.8 Implementar a execução da exportação local
    - Habilitar somente na Fase 3 a exportação iniciada explicitamente pelo usuário, gerando JSON e áudios conforme o contrato da tarefa 16.1, com verificação prévia de espaço e publicação atômica do pacote completo
    - Não habilitar upload ou sync e nunca apresentar pacote parcial como válido
    - _Requirements: RA-01.11, RD-27, RNF-02.2, RNF-05.4, RNF-05.5_

  - [x]* 24.9 Escrever teste de propriedade do espaço insuficiente
    - **Propriedade 51: Espaço insuficiente impede gravação e exportação**
    - **Valida: Requisitos RNF-05.3, RNF-05.4**

  - [x]* 24.10 Escrever testes de integração de áudio
    - Gravação até 5 min e 30 min com arquivo válido, duração e `byte_size` persistidos; falha injetada preserva o último arquivo e metadado válidos
    - _Requirements: RNF-05.2, RNF-05.5, RD-35, RD-37_

  - [x]* 24.11 Escrever testes de integração da exportação local
    - Validar pacote JSON + áudios contra o contrato versionado e injetar falhas em cada etapa para confirmar que nenhum pacote parcial é publicado e que dados anteriores permanecem intactos
    - _Requirements: RA-01.11, RD-27, RNF-05.4, RNF-05.5_

- [x] 25. Checkpoint final
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tarefas marcadas com `*` são opcionais e podem ser adiadas para uma entrega mais rápida; tarefas de implementação nunca são opcionais
- Cada tarefa referencia requisitos específicos para rastreabilidade
- Cada teste de propriedade implementa exatamente uma propriedade do design, com no mínimo 100 iterações e comentário no formato `// Feature: ritmo, Property N: ...`
- Todas as 54 propriedades do design têm uma sub-tarefa correspondente
- Testes de exemplo, edge case, integração, benchmark e smoke cobrem os critérios não adequados a PBT (copies isoladas, seed, gating de fase, permissões, I/O de áudio, desempenho e verificações estáticas)
- O DAG conclui todas as folhas do MVP antes de iniciar a Fase 2 e conclui todas as folhas da Fase 2 antes de iniciar a Fase 3; schema e portas de extensão antecipados no MVP não habilitam UI nem fluxo de fase futura
- A Fase 4 (`RA-01.12`, `RNF-02.4`: sync GCS criptografado, preparação Neo4j e iOS) está explicitamente fora deste plano, que termina na Fase 3
- A entrega da Fase 3 antes de `2027-06-30` é uma restrição de cronograma do produto, não uma tarefa de código; deve ser tratada no planejamento de entrega sem antecipar editor ou Encerramento de Ciclo no MVP

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3", "1.4", "15.1", "18.1"] },
    { "id": 2, "tasks": ["1.5", "1.6", "2.1"] },
    { "id": 3, "tasks": ["2.2", "2.4"] },
    { "id": 4, "tasks": ["2.3", "2.5", "2.6"] },
    { "id": 5, "tasks": ["2.7", "4.1"] },
    { "id": 6, "tasks": ["4.2", "15.5"] },
    { "id": 7, "tasks": ["4.3", "15.6"] },
    { "id": 8, "tasks": ["4.4", "4.5", "4.6", "15.2", "16.1"] },
    { "id": 9, "tasks": ["5.1", "15.3", "15.4", "15.7", "16.2"] },
    { "id": 10, "tasks": ["5.2", "5.3", "6.1", "15.8"] },
    { "id": 11, "tasks": ["5.4", "6.2", "6.3"] },
    { "id": 12, "tasks": ["5.5", "5.6", "6.4", "6.7"] },
    { "id": 13, "tasks": ["6.5", "6.8", "8.1", "9.1"] },
    { "id": 14, "tasks": ["6.6", "8.2", "8.3", "9.2", "9.3", "10.1"] },
    { "id": 15, "tasks": ["8.4", "10.2", "10.3"] },
    { "id": 16, "tasks": ["8.5", "8.6", "10.4", "10.6"] },
    { "id": 17, "tasks": ["10.5", "10.7", "10.8", "11.1"] },
    { "id": 18, "tasks": ["10.9", "11.2", "11.3", "13.1"] },
    { "id": 19, "tasks": ["13.2", "14.1"] },
    { "id": 20, "tasks": ["13.3", "13.4", "13.5", "13.6", "13.7", "13.8", "14.2", "14.3", "14.4"] },
    { "id": 21, "tasks": ["17.1"] },
    { "id": 22, "tasks": ["17.2", "17.5", "17.8", "17.9"] },
    { "id": 23, "tasks": ["17.3", "17.4", "17.6", "17.7", "17.10"] },
    { "id": 24, "tasks": ["17.11", "18.2", "18.3"] },
    { "id": 25, "tasks": ["20.1", "20.3", "21.1", "22.1"] },
    { "id": 26, "tasks": ["20.2", "20.4", "20.5", "20.6", "21.2", "21.3", "22.2"] },
    { "id": 27, "tasks": ["20.7", "20.8", "20.9", "21.4", "22.3", "22.4", "22.5", "22.6"] },
    { "id": 28, "tasks": ["24.1", "24.5", "24.8"] },
    { "id": 29, "tasks": ["24.2", "24.3", "24.6", "24.7", "24.11"] },
    { "id": 30, "tasks": ["24.4", "24.9", "24.10"] }
  ]
}
```

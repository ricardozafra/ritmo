# Requirements Document

## Introduction

**Produto: Ritmo**

O Ritmo é um aplicativo mobile pessoal, local-first e privado para responder a uma única pergunta: **“cumpri o que planejei hoje?”**. O produto não usa gamificação, streaks, pontuação, punição, culpa ou mecanismos de engajamento compulsivo.

O usuário é único. Android é a primeira plataforma; iOS pertence à Fase 4. O aplicativo funciona integralmente offline e não possui backend obrigatório. O tempo de negócio usa exclusivamente `America/Sao_Paulo`; a home é governada pela data operacional, enquanto o blackout de fim de semana também observa limites de hora civil.

## Glossary

- **Fuso oficial:** `America/Sao_Paulo`, usado em todas as regras de negócio, independentemente do fuso do aparelho.
- **Data civil:** data do calendário no fuso oficial.
- **Fechamento operacional (`day_close_time`):** limite configurável entre 00h00 e 04h00, inclusive, com padrão 03h00, no qual uma data operacional termina e a seguinte abre.
- **Data operacional:** antes de `day_close_time`, corresponde à data civil anterior; a partir de `day_close_time`, corresponde à data civil corrente.
- **Limite da noite (`night_end_time`):** último instante em que Estudo pode ser iniciado ou permanecer ativo; na linha temporal da data operacional, `night_end_time <= day_close_time`, ainda que ambos cruzem a meia-noite civil.
- **Data de ativação (`activation_date`):** primeira data operacional do uso do produto.
- **Dia útil:** data operacional de segunda a sexta-feira que não seja feriado manual ativo.
- **Dia mudo:** sábado, domingo ou feriado manual ativo; tem resultado efetivo `mute` e não participa de métricas, sequências de falha ou recorrência de dispensa.
- **Dia aberto:** dia com `closed_at` nulo; pode alternar entre resultado `unsealed` e `sealed`.
- **Dia encerrado:** dia com `closed_at` preenchido; seus registros ordinários são imutáveis, ressalvada a reclassificação não destrutiva por feriado.
- **Pilar:** uma das dimensões diárias Manhã/Corpo, Dia/Presente e Noite/Futuro.
- **Dispensa de pilar (`PillarWaiver`):** exceção autodeclarada e motivada para, no máximo, um pilar de um dia útil; é ativa quando `revoked_at` é nulo e permanece auditável, sem efeito, quando revogada.
- **Sequência de falha:** dois ou mais dias úteis elegíveis, encerrados e não selados consecutivos, ignorando dias `mute`.
- **Alarme de Protocolo:** reflexão interna vinculada a uma sequência de falha, com estado `pending`, `answered` ou `invalidated`.
- **Semana operacional:** período renovado na abertura operacional da segunda-feira no fuso oficial.
- **Ciclo:** finalidade nomeada, com período, checkpoints e estado `active` ou `archived`.
- **Checkpoint:** marco com data exata para avaliação de uma competência do ciclo.
- **Níveis Gartner:** `BD`, `B`, `I`, `A` e `E`.
- **Blackout de fim de semana:** intervalo sem notificações diárias entre sábado 00h00 civil e a abertura operacional de segunda-feira, ressalvada exclusivamente a revisão dominical opt-in.

## Requirements

### RF-01 — Três Pilares (RN-01)

1. ENQUANTO a data operacional vigente for um dia útil aberto, o sistema DEVE apresentar na tela Hoje os pilares Manhã/Corpo, Dia/Presente e Noite/Futuro.
2. QUANDO o usuário registrar o Pilar da Manhã, o sistema DEVE permitir registrar separadamente treino de musculação e audição do briefing de metas do ciclo.
3. O sistema DEVE considerar o Pilar da Manhã concluído somente quando treino e briefing estiverem concluídos, salvo dispensa ativa do Pilar da Manhã.
4. QUANDO o MP3 local do briefing chegar ao fim, o sistema DEVE concluir o briefing automaticamente.
5. QUANDO o usuário optar pela conclusão manual do briefing, o sistema DEVE concluí-lo imediatamente, inclusive com duração zero.
6. O sistema DEVE reproduzir o briefing a partir de MP3 local, sem depender de rede.
7. O sistema DEVE permitir exatamente uma iniciativa de mudança visível ativa por vez.
8. O sistema DEVE exibir no Pilar do Dia o toggle com a copy literal “Presença e execução honradas hoje”.
9. QUANDO o usuário ativar esse toggle, o sistema DEVE considerar o Pilar do Dia concluído.
10. O sistema DEVE permitir uma nota curta sobre problema complexo, em texto ou voz conforme a fase disponível, sempre opcional e nunca necessária para concluir o Pilar do Dia.
11. QUANDO o usuário registrar o Pilar da Noite antes de `night_end_time`, o sistema DEVE oferecer Estudo e Recuperação deliberada como alternativas.
12. QUANDO o usuário iniciar Estudo, o sistema DEVE persistir o instante de início e `block_deadline`, cujo valor DEVE ser `night_end_time` aplicável àquela data operacional.
13. O sistema NÃO DEVE permitir iniciar Estudo em instante posterior a `night_end_time`.
14. QUANDO um Estudo ativo alcançar `block_deadline`, o sistema DEVE encerrá-lo nesse limite.
15. SE um bloco de Estudo permanecer órfão, ENTÃO, na próxima abertura, o sistema DEVE fechá-lo retroativamente no `block_deadline` persistido, sem solicitar reconciliação ao usuário.
16. QUANDO um Estudo for encerrado normalmente ou no deadline, o sistema DEVE concluir o Pilar da Noite sem duração mínima.
17. ENQUANTO o instante vigente estiver entre `night_end_time` e `day_close_time`, o sistema DEVE oferecer somente Recuperação e exibir a copy literal “O expediente de estudo encerrou. Resta a noite.”
18. QUANDO Recuperação for escolhida, o sistema DEVE permitir confirmação simples, sem timer ou duração mínima, e uma nota opcional.
19. ENQUANTO o dia estiver aberto, Recuperação e sua nota opcional DEVEM permanecer disponíveis até `day_close_time`.
20. O sistema DEVE persistir cada registro de pilar na data operacional correspondente e NÃO DEVE atribuí-lo silenciosamente a outra data.
21. Critério de aceite crítico: DADO `night_end_time` anterior a `day_close_time`, QUANDO o primeiro limite já tiver passado e o dia ainda estiver aberto, ENTÃO Estudo NÃO DEVE estar disponível, Recuperação DEVE estar disponível e a copy literal do item 17 DEVE ser exibida.
22. Critério de aceite crítico: DADO um bloco órfão, QUANDO ocorrer a próxima abertura, ENTÃO seu fim DEVE ser `block_deadline` sem diálogo de reconciliação.
23. ENQUANTO o dia estiver `open/unsealed`, o sistema DEVE permitir marcar e desmarcar treino e briefing, ligar e desligar o toggle do Pilar do Dia e editar ou remover sua nota opcional.
24. ENQUANTO o dia estiver `open/unsealed` e houver Estudo ativo, o sistema DEVE permitir cancelá-lo; QUANDO o usuário cancelar, o sistema DEVE deixar o Pilar da Noite incompleto e descartar o bloco-rascunho usado para cumprimento, sem reatribuir seus dados a outra data.
25. APÓS o cancelamento de Estudo e ENQUANTO o dia permanecer `open/unsealed`, o sistema DEVE permitir iniciar novo Estudo antes de `night_end_time` ou escolher Recuperação conforme os limites temporais vigentes.
26. ENQUANTO o dia estiver `open/unsealed`, o sistema DEVE permitir remover ou substituir Estudo concluído por Recuperação e Recuperação concluída por Estudo, desde que um novo Estudo seja iniciado até `night_end_time`; a remoção DEVE tornar o Pilar da Noite incompleto até nova conclusão.
27. QUANDO `closed_at` estiver preenchido, o sistema NÃO DEVE permitir marcar, desmarcar, editar, remover, cancelar ou substituir registros ordinários dos pilares.
28. O texto “Treino de musculação” DEVE ser o rótulo literal do ciclo atual e NÃO DEVE representar categoria configurável no MVP; qualquer mudança futura desse conceito DEVE exigir decisão explícita de produto, sem generalização automática.
29. Critério de aceite crítico: DADO um Estudo ativo em dia aberto, QUANDO ele for cancelado, ENTÃO o Pilar da Noite DEVE ficar incompleto, o bloco-rascunho de cumprimento DEVE ser descartado e o usuário DEVE poder escolher novamente uma alternativa válida para a mesma data operacional.

### RF-02 — Selo e dispensa (RN-02)

1. ENQUANTO um dia útil estiver aberto, o sistema DEVE permitir os estados `open/unsealed` e `open/sealed`.
2. QUANDO os três pilares estiverem concluídos e o usuário acionar “Selar o Dia”, o sistema DEVE mudar o estado para `open/sealed` e registrar `seal_timestamp`.
3. QUANDO exatamente um pilar incompleto possuir uma `PillarWaiver` ativa, o sistema DEVE permitir selar o dia.
4. ENQUANTO o dia estiver `open/sealed`, o sistema NÃO DEVE permitir alteração de registros ordinários antes da ação explícita “Reabrir o Dia”; QUANDO o usuário confirmar essa ação, o sistema DEVE mudar o estado para `open/unsealed`, limpar `seal_timestamp` e permitir edição e novo selo.
5. QUANDO o usuário selar novamente, o sistema DEVE registrar um novo `seal_timestamp`, preservando somente o timestamp do último selo válido.
6. QUANDO `closed_at` for preenchido, o sistema DEVE tornar o dia e seus registros ordinários imutáveis, salvo a classificação efetiva decorrente de feriado.
7. QUANDO mais de um pilar estiver incompleto, o sistema NÃO DEVE permitir selo nem segunda dispensa ativa no mesmo dia.
8. QUANDO algum pilar incompleto não estiver coberto pela única dispensa ativa, o sistema NÃO DEVE selar o dia e DEVE indicar de forma neutra o que falta.
9. QUANDO o usuário criar uma dispensa, o sistema DEVE exigir o pilar dispensado e um motivo não vazio.
10. O sistema DEVE permitir no máximo uma `PillarWaiver` ativa por data operacional mediante unicidade parcial lógica; dispensas revogadas NÃO DEVEM impedir nova dispensa ativa no mesmo dia.
11. QUANDO a dispensa se aplicar ao Pilar da Manhã, o sistema DEVE dispensar conjuntamente treino e briefing.
12. AO calcular recorrência de dispensa, o sistema DEVE considerar somente dispensas ativas do mesmo pilar em dias úteis consecutivos, ignorando dias `mute` e dispensas revogadas.
13. QUANDO a dispensa for a primeira da recorrência daquele pilar, o sistema DEVE aceitá-la sem diálogo adicional.
14. QUANDO a dispensa for a segunda ou posterior da recorrência daquele mesmo pilar, o sistema DEVE exigir, antes de persistir, diálogo explícito que cite a Regra do Retorno.
15. QUANDO houver entre duas dispensas ativas uma dispensa ativa de outro pilar, um dia útil sem dispensa ativa daquele pilar ou um dia útil selado sem essa dispensa, o sistema DEVE encerrar a recorrência daquele pilar.
16. QUANDO um dia com dispensa ativa for selado, o sistema DEVE contá-lo integralmente no numerador e usá-lo para quebrar qualquer sequência de dias não selados.
17. O sistema DEVE calcular a taxa como `dias úteis elegíveis encerrados e selados / dias úteis elegíveis encerrados`.
18. O sistema NÃO DEVE incluir dias anteriores a `activation_date`, dias abertos ou dias `mute` no numerador ou denominador.
19. O sistema NÃO DEVE exibir streaks, recordes, pontos, recompensas, penalidades ou contadores reiniciáveis.
20. Critério de aceite crítico: DADOS quatro dias úteis encerrados, três selados e um não selado, além de um quinto dia aberto, QUANDO a taxa for calculada, ENTÃO o resultado DEVE ser `3/4`.
21. Critério de aceite crítico: DADAS dispensas ativas do mesmo pilar em dois dias úteis consecutivos, ainda que separadas por dias `mute`, QUANDO a segunda for solicitada, ENTÃO o diálogo DEVE citar a Regra do Retorno.
22. ENQUANTO o dia estiver `open/unsealed`, o pilar dispensado DEVE continuar editável segundo as mesmas regras de reversibilidade dos demais pilares.
23. QUANDO o usuário tentar concluir um pilar com dispensa ativa, o sistema DEVE exibir confirmação neutra para retirar a dispensa antes de concluir o pilar.
24. QUANDO o usuário confirmar a retirada, o sistema DEVE preencher `revoked_at` da dispensa, concluir o pilar normalmente e retirar imediatamente o efeito da dispensa sobre selo e recorrência.
25. QUANDO uma dispensa possuir `revoked_at`, o sistema DEVE preservá-la para auditoria, NÃO DEVE tratá-la como dispensa ativa e NÃO DEVE incluí-la na recorrência.
26. ENQUANTO o dia estiver `open/unsealed` e não houver outra dispensa ativa, o sistema DEVE permitir criar nova dispensa, inclusive de outro pilar, preservando no histórico todas as dispensas revogadas daquele dia.
27. QUANDO `closed_at` estiver preenchido, o sistema NÃO DEVE permitir revogar uma dispensa.
28. Critério de aceite crítico: DADO um dia aberto com uma dispensa revogada, QUANDO outra dispensa for criada, ENTÃO ambas DEVEM permanecer auditáveis e somente a nova DEVE produzir efeito sobre selo e recorrência.

### RF-03 — Regra do Retorno e protocolo — CRÍTICO (RN-03)

1. QUANDO um dia útil elegível for encerrado sem selo, o sistema DEVE representá-lo em cinza neutro no calendário e NUNCA em vermelho.
2. QUANDO houver exatamente um dia útil não selado na sequência corrente, o sistema DEVE disponibilizar a copy literal “Um dia perdido não é derrota; é dado.”
3. QUANDO uma sequência de falha alcançar dois dias úteis elegíveis encerrados e não selados, o sistema DEVE criar exatamente um Alarme de Protocolo `pending` para essa sequência.
4. ENQUANTO a mesma sequência crescer para três ou mais dias, o sistema DEVE atualizar `sequence_length` no mesmo protocolo e NÃO DEVE criar outro protocolo.
5. AO determinar consecutividade, o sistema DEVE ignorar dias `mute` e dias anteriores a `activation_date`.
6. QUANDO um dia útil elegível selado ocorrer, inclusive com dispensa ativa, o sistema DEVE encerrar a sequência de falha anterior.
7. QUANDO sexta-feira e a segunda-feira útil seguinte forem encerradas sem selo, com apenas dias `mute` entre elas, o sistema DEVE tratá-las como parte da mesma sequência.
8. O sistema DEVE impedir atomicamente a criação duplicada de protocolo para a mesma sequência.
9. O sistema DEVE permitir que protocolos de sequências distintas permaneçam simultaneamente `pending`.
10. QUANDO houver protocolos pendentes na abertura do aplicativo, o sistema DEVE selecionar o mais antigo e exibir somente esse protocolo durante essa abertura.
11. QUANDO o usuário responder ao protocolo exibido, o sistema DEVE manter qualquer outro protocolo pendente sem exibi-lo na mesma sessão.
12. SOMENTE EM nova abertura do aplicativo, o sistema DEVE poder exibir o próximo protocolo pendente.
13. QUANDO um protocolo for exibido, o sistema DEVE abrir primeiro a tela Pedra e depois o formulário correspondente.
14. O formulário DEVE solicitar: “o que causou?”, “o problema é o plano ou a execução?” e “qual o ajuste?”.
15. QUANDO o usuário concluir o formulário, o sistema DEVE persistir data de disparo, causa, classificação `plan` ou `execution` e ajuste, e mudar o estado para `answered`.
16. QUANDO um feriado fizer um protocolo `pending` ou `answered` perder seu critério, o sistema DEVE mudá-lo para `invalidated`, preservar o estado anterior e todos os seus dados.
17. O sistema NUNCA DEVE reutilizar, restaurar ou reativar um protocolo `invalidated`.
18. QUANDO um feriado for removido e os critérios voltarem a existir, o sistema DEVE criar um NOVO protocolo `pending` para a sequência recalculada.
19. QUANDO a remoção ou inclusão de feriado fundir sequências antes distintas, o sistema DEVE invalidar os protocolos que perderem critério e criar um NOVO protocolo `pending` para a sequência fundida.
20. O sistema DEVE manter histórico consultável de protocolos `pending`, `answered` e `invalidated`, sem apagar registros.
21. O sistema NÃO DEVE enviar push, cobrança ou alerta externo em decorrência de dias não selados.
22. Critério de aceite crítico: DADA uma sequência de quatro dias úteis não selados, QUANDO o detector for executado concorrentemente, ENTÃO DEVE existir um protocolo para a sequência com `sequence_length = 4`.
23. Critério de aceite crítico: DADOS dois protocolos pendentes, QUANDO o usuário responder ao mais antigo, ENTÃO o segundo DEVE aparecer somente em nova abertura.
24. Critério de aceite crítico: DADO um protocolo invalidado por feriado, QUANDO o feriado for removido e a sequência voltar a satisfazer o critério, ENTÃO o protocolo antigo DEVE permanecer `invalidated` e um novo `pending` DEVE ser criado.

### RF-04 — Descanso é cumprimento — CRÍTICO (RN-04)

1. QUANDO o usuário registrar o Pilar da Noite, o sistema DEVE oferecer Estudo e Recuperação deliberada conforme os limites do RF-01.
2. QUANDO Recuperação for confirmada, o sistema DEVE considerar o Pilar da Noite concluído sem Estudo, timer ou duração mínima.
3. QUANDO um dia com Recuperação for selado, o sistema DEVE contabilizá-lo de forma idêntica a um dia selado com Estudo.
4. O sistema NÃO DEVE aplicar cor, ícone, rótulo, peso de métrica, ordenação ou copy que represente Recuperação como inferior.
5. Critério de aceite crítico: DADOS dois dias idênticos exceto pelo tipo noturno, `study` e `recovery`, QUANDO ambos forem selados, ENTÃO cada dia DEVE acrescentar exatamente uma unidade ao numerador.

### RF-05 — Fim de semana, tempo operacional e feriados — CRÍTICO (RN-05)

1. O sistema DEVE aplicar o fuso fixo `America/Sao_Paulo` a todas as decisões de data e hora de negócio.
2. QUANDO o fuso do aparelho divergir do fuso oficial, o sistema DEVE exibir na interface um indicador discreto de que datas e horários seguem `America/Sao_Paulo`.
3. O sistema DEVE usar `day_close_time` padrão 03h00 e permitir configurá-lo entre 00h00 e 04h00, inclusive.
4. QUANDO a hora no fuso oficial for anterior a `day_close_time`, o sistema DEVE atribuir eventos à data operacional civil anterior.
5. QUANDO a hora alcançar `day_close_time`, o sistema DEVE preencher `closed_at` da data operacional anterior e abrir a nova data operacional.
6. O sistema DEVE representar lifecycle por `closed_at` separadamente do resultado `sealed`, `unsealed` ou `mute`.
7. QUANDO ocorrer o primeiro uso, o sistema DEVE persistir a data operacional vigente como `activation_date` e NÃO DEVE criar dias elegíveis anteriores.
8. ENQUANTO um dia útil estiver aberto, o sistema NÃO DEVE incluí-lo no denominador nem classificá-lo como falha.
9. ENQUANTO a home estiver aberta, o sistema DEVE escolher conteúdo e estado pela data operacional vigente, não pela data civil isolada.
10. DADO `day_close_time` padrão 03h00, QUANDO a home for aberta no sábado civil à 01h00, ENTÃO ela DEVE mostrar a sexta-feira operacional ainda aberta.
11. DADO `day_close_time` padrão 03h00, QUANDO a home for aberta na segunda-feira civil à 01h00, ENTÃO ela DEVE mostrar o domingo operacional `mute`.
12. ENQUANTO a data operacional for sábado ou domingo, o sistema DEVE atribuir resultado efetivo `mute` com `mute_cause = weekend`.
13. QUANDO o usuário marcar uma data como feriado, o sistema DEVE atribuir resultado efetivo `mute` com `mute_cause = holiday` e preservar o resultado anterior em `previous_result`.
14. ENQUANTO a home estiver em dia `mute`, o sistema DEVE ocultar pilares e ações diárias e exibir apenas a frase literal “Território sagrado. Presença integral.”
15. O sistema NÃO DEVE incluir dias `mute` em métrica, sequência de falha ou recorrência de dispensa.
16. QUANDO um feriado for adicionado ou removido, o sistema DEVE recalcular métricas, sequências e protocolos desde a data afetada segundo as regras de invalidação do RF-03.
17. QUANDO um feriado for removido, o sistema DEVE recuperar `previous_result` como resultado efetivo aplicável, sem apagar o registro do feriado, o dia, pilares, selo, dispensa ou qualquer histórico.
18. O sistema DEVE manter `mute_cause`, `previous_result`, criação e remoção de feriado de forma auditável e não destrutiva.
19. ENQUANTO transcorrer o intervalo entre sábado 00h00 civil e a abertura operacional de segunda-feira, o sistema NÃO DEVE agendar nem entregar notificações diárias.
20. A única exceção ao blackout DEVE ser a notificação opt-in da revisão dominical definida no RF-08; essa exceção NÃO DEVE alterar a data operacional nem a home.
21. QUANDO houver notificação diária configurada para segunda-feira, o sistema DEVE entregá-la somente após a abertura operacional de segunda-feira, no horário configurado.
22. O sistema NÃO DEVE calcular o fim do blackout por `max(03h, fechamento)`; DEVE usar a abertura operacional de segunda-feira, sendo 03h00 apenas o padrão de `day_close_time`.
23. QUANDO `day_close_time` for alterado, o sistema DEVE aplicar o novo limite somente às fronteiras ainda não encerradas e NÃO DEVE reabrir, renomear ou duplicar dias encerrados.
24. Critério de aceite crítico: DADO sábado 00h00 civil, QUANDO uma notificação diária for avaliada, ENTÃO ela DEVE ser bloqueada até a abertura operacional de segunda-feira.
25. Critério de aceite crítico: DADO um dia selado posteriormente marcado como feriado, QUANDO o feriado for removido, ENTÃO o selo e os registros DEVEM permanecer, mas qualquer protocolo invalidado NÃO DEVE ser restaurado.
26. QUANDO o usuário solicitar aplicação ou remoção retroativa de feriado, o sistema DEVE exibir antes uma confirmação neutra que informe os efeitos esperados em métricas e protocolos.
27. QUANDO um feriado for aplicado ou removido, o sistema DEVE permitir `reason_text` opcional e preservá-lo de forma auditável com a alteração correspondente.
28. O sistema NÃO DEVE tratar aplicação ou remoção retroativa de feriado como fraude, punição ou motivo de bloqueio; a autodeclaração do usuário DEVE prevalecer.
29. ENQUANTO o aplicativo estiver em foreground, o sistema DEVE observar a fronteira de `day_close_time` sem depender de reabertura, navegação ou notificação.
30. QUANDO a fronteira ocorrer e a home estiver ociosa, o sistema DEVE fechar a data operacional anterior e atualizar a home para a nova data operacional.
31. QUANDO a fronteira ocorrer enquanto o usuário estiver editando dado vinculado ao dia, o sistema DEVE realizar snapshot e autosave transacional do estado presente naquele instante, fechar o dia sem perda nem reclassificação de dados, tornar a tela do dia anterior read-only e exibir aviso neutro.
32. APÓS o fechamento observado em foreground, o sistema NÃO DEVE permitir que edições posteriores modifiquem o dia encerrado nem DEVE reatribuir dados à nova data operacional.
33. QUANDO a fronteira ocorrer durante fluxo não vinculado ao dia, inclusive Revisão ou Pedra, o sistema NÃO DEVE interromper o fluxo e DEVE atualizar somente o contexto de data operacional aplicável.
34. O fechamento em foreground NÃO DEVE emitir notificação.
35. Critério de aceite crítico: DADO o aplicativo aberto com edição diária não salva no instante de `day_close_time`, QUANDO a fronteira for observada, ENTÃO o estado presente DEVE ser salvo atomicamente na data original, essa data DEVE ser encerrada, a tela DEVE ficar read-only com aviso neutro e nenhuma edição posterior DEVE alterá-la.
36. Critério de aceite crítico: DADO um feriado retroativo, QUANDO sua aplicação ou remoção for confirmada com ou sem `reason_text`, ENTÃO o sistema DEVE recalcular os efeitos sem bloquear a autodeclaração e DEVE preservar a operação para auditoria.

### RF-06 — Finalidade, ciclos e checkpoints (RN-06)

1. O sistema DEVE fornecer no MVP um ciclo seed ativo com a finalidade “Nível Avançado em Strategic Thinking, Innovative e Change Advocate até Junho/2027 + consolidação de Business Acumen”.
2. O ciclo seed DEVE conter exatamente os checkpoints `2026-12-31` — Innovative; `2027-02-28` — Strategic Thinking; `2027-06-30` — Change Advocate.
3. ENQUANTO a home estiver em dia útil, o sistema DEVE exibir no topo a finalidade do ciclo ativo.
4. O sistema DEVE exibir contagem regressiva em dias corridos, no fuso oficial, para o próximo checkpoint futuro.
5. ENQUANTO a Revisão Semanal ocorrer no mês civil de um checkpoint, o sistema DEVE incluir a autoavaliação da competência correspondente.
6. QUANDO uma autoavaliação for preenchida, o sistema DEVE aceitar nível Gartner `BD`, `B`, `I`, `A` ou `E` e notas opcionais.
7. QUANDO houver avaliações, o sistema DEVE permitir visualizar a evolução por competência sem gamificação.
8. APÓS o último checkpoint sem Encerramento de Ciclo concluído, o sistema DEVE manter o ciclo `active` e exibir o estado visual derivado “aguardando encerramento”, sem arquivá-lo automaticamente.
9. ENQUANTO um ciclo estiver visualmente aguardando encerramento, o sistema DEVE apresentar o convite para Encerramento de Ciclo somente junto à Revisão Semanal, no máximo uma vez por semana.
10. O sistema DEVE permitir adiar o convite e NÃO DEVE enviar push de Encerramento de Ciclo.
11. QUANDO o usuário iniciar o Encerramento de Ciclo, o sistema DEVE incluir releitura do manifesto, avaliação final e campos para a finalidade e os checkpoints do novo ciclo.
12. QUANDO o Encerramento de Ciclo for concluído, o sistema DEVE arquivar o ciclo anterior como read-only e ativar o novo ciclo com sua finalidade e checkpoints.
13. SOMENTE NA Fase 3, o sistema DEVE disponibilizar o editor de ciclos, finalidade, período e checkpoints, bem como o fluxo de Encerramento de Ciclo.
14. QUANDO o usuário editar ou encerrar um ciclo, o sistema DEVE preservar avaliações e histórico associados por identificador.
15. O sistema NÃO DEVE fabricar nova data ou novo ciclo quando não houver checkpoint futuro.
16. Critério de aceite crítico: DADO o seed inalterado, QUANDO consultado no MVP, ENTÃO a finalidade e as três datas e competências dos itens 1 e 2 DEVEM ser exatas.
17. Critério de aceite crítico: DADO um ciclo após seu último checkpoint, QUANDO a revisão semanal for aberta, ENTÃO o convite poderá aparecer uma vez naquela semana, será adiável e não terá push.
18. APÓS o último checkpoint e antes da disponibilidade do Encerramento de Ciclo, o sistema DEVE ocultar a contagem regressiva vencida, manter visível a finalidade e exibir somente o estado “aguardando encerramento” no lugar do countdown.
19. ENQUANTO o ciclo seed estiver “aguardando encerramento”, o aplicativo e suas métricas DEVEM permanecer integralmente funcionais, sem bloqueio, criação automática de ciclo ou exigência de edição.
20. A Fase 3 DEVE estar disponível antes de `2027-06-30` como dependência de entrega para permitir o rollover pelo Encerramento de Ciclo, sem antecipar o editor ou ampliar o escopo do MVP.
21. Critério de aceite crítico: DADO o MVP após o último checkpoint sem Fase 3 disponível, QUANDO o usuário acessar a home ou as métricas, ENTÃO NÃO DEVE haver countdown vencido nem bloqueio, a finalidade DEVE permanecer visível e o estado exibido DEVE ser somente “aguardando encerramento”.

### RF-07 — Pessoas e sugestão semanal (RN-07)

1. O sistema DEVE manter exatamente três cartões fixos de mentoria para Strategic Thinking, Innovative e Change Advocate.
2. O sistema DEVE permitir editar nome do mentor e data do último encontro em cada cartão.
3. QUANDO tiverem transcorrido mais de 30 dias desde o último encontro, o sistema DEVE exibir alerta visual suave, sem push.
4. O sistema DEVE permitir cadastrar contatos com nome, nota de contexto, `last_touch_date` opcional e `created_at`.
5. QUANDO a semana operacional for renovada na abertura operacional de segunda-feira, o sistema DEVE ordenar contatos pela maior carência: `last_touch_date` nula primeiro e, depois, a data mais antiga primeiro.
6. QUANDO houver empate de `last_touch_date`, o sistema DEVE priorizar o menor `created_at`, isto é, o contato criado há mais tempo.
7. QUANDO a sugestão da semana for criada, o sistema DEVE persistir `WeeklyContactSuggestion(week_start, contact FK, status: pending|done|skipped)` e reutilizá-la durante a semana.
8. QUANDO um contato novo for cadastrado no meio da semana, o sistema NÃO DEVE substituir a sugestão persistida.
9. QUANDO o usuário marcar a ponte como realizada, o sistema DEVE alterar o status da sugestão para `done` e atualizar `last_touch_date` do contato para a data operacional vigente.
10. QUANDO o usuário pular uma sugestão, o sistema DEVE alterar seu status para `skipped` e avançar ao próximo contato da ordem semanal sem penalidade.
11. QUANDO todos os contatos da ordem semanal tiverem sido pulados, o sistema DEVE exibir a copy literal “Pontes visitadas ou adiadas esta semana” e NÃO DEVE reiniciar a ordem naquela semana.
12. O sistema DEVE permitir escolha manual de contato sem penalidade.
13. QUANDO a lista de contatos estiver vazia, o sistema DEVE exibir um único convite para cadastrar contato e NÃO DEVE manter badge persistente.
14. O sistema DEVE exibir junto à sugestão a copy literal “sem pedir nada”.
15. O sistema NÃO DEVE premiar, pontuar ou penalizar a sugestão, a escolha manual ou o ato de pular.
16. Critério de aceite crítico: DADOS dois contatos com a mesma `last_touch_date`, QUANDO a semana for renovada, ENTÃO o contato com `created_at` mais antigo DEVE ser sugerido primeiro.
17. Critério de aceite crítico: DADA uma sugestão persistida, QUANDO um contato mais carente for criado na quarta-feira, ENTÃO a sugestão vigente NÃO DEVE mudar antes da próxima abertura operacional de segunda-feira.
18. O sistema DEVE manter Mentoria e Contatos como módulos e entidades separados.
19. QUANDO uma pessoa existir como `Mentorship`, o sistema NÃO DEVE incluí-la automaticamente no cadastro, na ordenação nem no rodízio de `Contact`.
20. SOMENTE QUANDO a mesma pessoa for cadastrada explicitamente como `Contact`, o sistema DEVE permitir sua participação no rodízio, sem inferir vínculo ou sincronizar os registros automaticamente.
21. O badge visual suave após mais de 30 dias DEVE ser o único lembrete automático de mentor; o sistema NÃO DEVE enviar push nem incluir mentor automaticamente em sugestão semanal.
22. Critério de aceite crítico: DADO um mentor não cadastrado como contato, QUANDO a ordem semanal for calculada, ENTÃO essa pessoa NÃO DEVE participar da lista nem gerar sugestão.

### RF-08 — Revisão semanal e notificações (RN-08)

1. O sistema DEVE oferecer fluxo semanal guiado com as perguntas “o que foi cumprido?”, “o que falhou?” e “o que a falha ensina?”.
2. QUANDO a fase suportar texto, o sistema DEVE permitir respostas em texto e persistir a revisão localmente.
3. QUANDO a fase suportar voz, o sistema DEVE permitir áudio local associado à revisão, sem exigir transcrição.
4. O fluxo DEVE ser projetado para cerca de 20 minutos, sem permanência mínima.
5. O sistema DEVE permitir configurar a revisão para domingo entre 20h00 e 22h00 ou para segunda-feira em horário posterior à abertura operacional, no fuso oficial.
6. O sistema DEVE manter desligada por padrão a notificação dominical.
7. ENQUANTO transcorrer o blackout do RF-05, o sistema NÃO DEVE agendar nem entregar notificação, salvo a exceção dominical explícita.
8. QUANDO o usuário habilitar a exceção dominical, o sistema DEVE permitir exatamente um disparo da revisão no domingo entre 20h00 e 22h00.
9. QUANDO a notificação dominical for acionada, o sistema DEVE abrir diretamente o fluxo de Revisão sem alterar a home.
10. ENQUANTO a home dominical permanecer muda, o sistema DEVE manter o fluxo de Revisão acessível manualmente.
11. QUANDO a notificação dominical for entregue, dispensada ou ignorada, o sistema NÃO DEVE repetir, reagendar, aplicar snooze automático ou enviar follow-up naquela semana.
12. QUANDO a exceção dominical estiver habilitada, o sistema NÃO DEVE alterar a home, retirar o estado `mute`, exibir pilares ou criar expectativa de registro diário.
13. QUANDO a revisão estiver configurada para segunda-feira, o sistema DEVE notificá-la uma única vez no horário configurado, somente depois que a data operacional de segunda-feira tiver aberto.
14. O sistema NÃO DEVE substituir a regra do item 13 por um cálculo de `max(03h, fechamento)`; 03h00 é somente o horário padrão de abertura operacional.
15. QUANDO configurações, feriados ou horários mudarem, o sistema DEVE recalcular agendamentos futuros sem violar o blackout.
16. Critério de aceite crítico: DADA a configuração padrão, QUANDO chegar domingo entre 20h00 e 22h00, ENTÃO nenhuma notificação DEVE ser entregue.
17. Critério de aceite crítico: DADO opt-in dominical para 21h00, QUANDO chegar domingo 21h00, ENTÃO um único disparo DEVE ser permitido, sem repetição ou follow-up, e a home DEVE permanecer muda.
18. Critério de aceite crítico: DADA revisão configurada para segunda-feira, QUANDO a data operacional ainda for domingo, ENTÃO nenhuma notificação de segunda-feira DEVE ser entregue.
19. A PARTIR DA Fase 2, o sistema DEVE exibir histórico de Revisões Semanais em lista cronológica por semana operacional.
20. QUANDO o usuário abrir uma revisão no histórico, o sistema DEVE exibir as três respostas, o áudio quando houver e as avaliações de checkpoint associadas.
21. QUANDO não houver revisões no histórico, o sistema DEVE exibir estado vazio neutro.
22. QUANDO uma Revisão Semanal for iniciada, o sistema DEVE mantê-la em estado `draft` com autosave local até finalização explícita pelo usuário.
23. QUANDO o usuário finalizar explicitamente uma Revisão Semanal, o sistema DEVE mudar seu estado para `finalized` e torná-la read-only.
24. O histórico de Revisões Semanais NÃO DEVE oferecer busca nem filtro.
25. Critério de aceite crítico: DADA uma revisão em `draft`, QUANDO o fluxo for interrompido e reaberto, ENTÃO as respostas salvas automaticamente DEVEM ser restauradas e a revisão NÃO DEVE ser finalizada implicitamente.
26. Critério de aceite crítico: DADA uma revisão `finalized`, QUANDO acessada pelo histórico, ENTÃO seus conteúdos e avaliações associadas DEVEM ser exibidos sem ação de edição.

### RF-09 — Pedra, manifesto e Juramento (RN-09)

1. O sistema DEVE empacotar o conteúdo integral do manifesto em asset Markdown local antes da entrega do MVP.
2. QUANDO ocorrer o primeiro uso e não existir cópia local, o sistema DEVE copiar o asset para uma cópia local editável.
3. QUANDO existir cópia local, o sistema NÃO DEVE sobrescrevê-la em reaberturas ou atualizações, ainda que tenha sido editada.
4. QUANDO o usuário acessar o modo de edição da tela Pedra, o sistema DEVE permitir editar e salvar localmente a cópia do manifesto.
5. QUANDO a cópia local estiver ausente ou indisponível, o sistema DEVE usar o asset como fallback de leitura sem sobrescrever edição existente.
6. O sistema DEVE renderizar o manifesto integral offline e NUNCA DEVE executar HTML bruto contido no Markdown.
7. O parser DEVE procurar uma linha cujo conteúdo, após trim externo, seja exatamente `## IV. O JURAMENTO INTERNO`.
8. QUANDO encontrar esse heading, o parser DEVE ignorar linhas em branco imediatamente posteriores e identificar como Juramento o PRIMEIRO bloco contíguo de linhas blockquote iniciadas por `>` que vier imediatamente depois delas.
9. QUANDO identificar o Juramento, o sistema DEVE renderizar somente esse bloco em fonte serifada itálica com destaque, sem alterar seu texto.
10. SE o heading exato não existir ou o primeiro conteúdo não vazio posterior não for um bloco blockquote, ENTÃO o sistema DEVE renderizar todo o manifesto normalmente, sem erro e sem destaque.
11. QUANDO houver Alarme de Protocolo pendente selecionado, o sistema DEVE apresentar a Pedra antes do formulário correspondente.
12. Critério de aceite crítico: DADO manifesto com linhas em branco após o heading exato e depois dois blocos blockquote separados, QUANDO renderizado, ENTÃO somente o primeiro bloco contíguo DEVE receber destaque.
13. Critério de aceite crítico: DADA cópia local editada, QUANDO o aplicativo for atualizado, ENTÃO a edição NÃO DEVE ser substituída pelo asset.

### RA-01 — Configurações, histórico e interoperabilidade

1. O sistema DEVE permitir configurar `day_close_time` entre 00h00 e 04h00 e `night_end_time` de modo que `night_end_time <= day_close_time` na linha temporal operacional.
2. O sistema DEVE permitir configurar a Revisão Semanal somente nos limites do RF-08.
3. O sistema DEVE permitir adicionar e remover feriados manuais conforme o RF-05.
4. O sistema DEVE manter o sync desligado por feature flag no MVP.
5. O sistema DEVE exibir heatmap mensal em que `sealed` usa destaque, dia útil encerrado `unsealed` usa cinza neutro e `mute` é vazio.
6. QUANDO o usuário selecionar um dia no heatmap, o sistema DEVE exibir detalhes persistidos, inclusive classificação efetiva, `mute_cause` e `previous_result` quando aplicáveis.
7. O sistema DEVE oferecer acesso ao histórico de Alarmes de Protocolo a partir da tela Ritmo.
8. O heatmap NÃO DEVE sugerir streak, cadeia, recorde ou perda de progresso.
9. O sistema DEVE manter contrato local de exportação em JSON estruturado e versionado conforme a fase definida, preservando identificadores, datas, estados e referências a áudio.
10. No MVP, o sistema DEVE definir e documentar o contrato do schema de exportação, mas NÃO DEVE executar exportação, upload ou sync.
11. SOMENTE NA Fase 3, o sistema DEVE permitir executar a exportação local de JSON e áudios.
12. Na Fase 4, QUANDO o sync GCS for habilitado explicitamente, o sistema DEVE criptografar o backup antes do envio.

## 4. Requisitos de dados

1. O sistema DEVE persistir localmente, no mínimo: `Day`, `PillarEntry`, `PillarWaiver`, `StudyBlock`, `ProtocolAlarm`, `Holiday`, `Mentorship`, `Contact`, `WeeklyContactSuggestion`, `WeeklyReview`, `Cycle`, `Checkpoint`, `CheckpointEval`, `Manifest`, `Settings` e `ChangeInitiative`.
2. `Day` DEVE possuir `operational_date` única, resultado base, resultado efetivo `sealed|unsealed|mute`, `closed_at`, `seal_timestamp`, `mute_cause: weekend|holiday` opcional e `previous_result` opcional.
3. `Day.closed_at` DEVE representar lifecycle independentemente do resultado diário.
4. `Settings` DEVE possuir `activation_date`, fuso imutável `America/Sao_Paulo`, `day_close_time` padrão 03h00, `night_end_time`, configuração da revisão e feature flag de sync.
5. `PillarEntry` DEVE referenciar um `Day` e representar exatamente um pilar `morning`, `day` ou `night`.
6. O registro `morning` DEVE preservar treino, briefing, modo de conclusão `automatic|manual` e instantes disponíveis.
7. O registro `day` DEVE preservar o estado do toggle literal, a iniciativa ativa referenciada e a nota opcional.
8. O registro `night` DEVE aceitar `study`, `recovery` ou nulo; Recuperação DEVE aceitar nota opcional e NÃO DEVE exigir campos de timer.
9. `StudyBlock` DEVE preservar início, `block_deadline` e fim; o fim NÃO DEVE ultrapassar `block_deadline`, e bloco órfão DEVE receber fim igual ao deadline persistido.
10. O modelo NÃO DEVE possuir estado, duração ou fluxo de reconciliação manual de timer.
11. `PillarWaiver` DEVE possuir `id`, `date` como chave estrangeira para `Day`, `pillar`, `reason_text`, `recurrence_confirmed` e `revoked_at` opcional; uma restrição de unicidade parcial lógica DEVE impedir mais de uma dispensa com `revoked_at` nulo por dia e permitir múltiplas dispensas revogadas auditáveis.
12. `ProtocolAlarm` DEVE possuir identificador próprio, identificador da geração da sequência, datas inicial e final, `sequence_length`, estado `pending|answered|invalidated`, estado anterior preservado, data de disparo, causa, `plan_or_execution` e ajuste.
13. `ProtocolAlarm.plan_or_execution` DEVE aceitar somente `plan|execution`.
14. Uma restrição lógica DEVE garantir um único protocolo não invalidado por geração de sequência, sem impedir vários pendentes de sequências distintas nem um novo protocolo após invalidação.
15. `ProtocolAlarm` invalidado DEVE permanecer imutavelmente invalidado e nunca ser reutilizado por sequência restaurada ou fundida.
16. `Holiday` DEVE preservar data operacional, estado ativo/inativo, instantes de criação e remoção e `reason_text` opcional por operação; sua aplicação NÃO DEVE apagar registros.
17. `Mentorship.competency` DEVE aceitar somente `ST|IN|CA`; `Mentorship` DEVE permanecer entidade separada de `Contact`, sem inclusão ou vínculo implícito.
18. `Contact` DEVE preservar `last_touch_date` opcional e `created_at` para ordenação determinística e NÃO DEVE ser criado implicitamente a partir de `Mentorship`.
19. `WeeklyContactSuggestion` DEVE possuir `week_start`, `contact` como chave estrangeira e `status: pending|done|skipped`; os registros DEVEM preservar a progressão da semana sem reinício.
20. `Cycle` DEVE preservar `name`, `purpose_text`, período e estado `active|archived`; o marcador “aguardando encerramento” DEVE ser derivado de ciclo ativo após seu último checkpoint, e ciclos `archived` DEVEM ser read-only.
21. `Checkpoint` DEVE referenciar um ciclo e preservar competência, data exata e status.
22. `CheckpointEval.gartner_level` DEVE aceitar somente `BD|B|I|A|E`, preservar notas opcionais e permitir associação à `WeeklyReview` correspondente.
23. `WeeklyReview` DEVE preservar a semana operacional, as três respostas, referência opcional a áudio, associações com `CheckpointEval`, estado `draft|finalized` e instantes de criação, autosave e finalização; `finalized` DEVE ser read-only.
24. `Manifest` DEVE preservar conteúdo Markdown local, versão originária do asset, instante da primeira cópia e instante da última edição.
25. `ChangeInitiative` DEVE permitir no máximo uma iniciativa ativa.
26. O sistema DEVE executar atomicamente fechamento diário, snapshot/autosave na fronteira, selo, criação de protocolo e recálculos retroativos.
27. O contrato de exportação DEVE preservar dados base, classificações efetivas, `mute_cause`, `previous_result` e estados derivados; sua execução DEVE permanecer indisponível antes da Fase 3.
28. Todo campo de nome editável, inclusive nomes de mentor, contato, ciclo e iniciativa, DEVE aceitar no máximo 120 caracteres Unicode; `Cycle.name` DEVE respeitar explicitamente esse limite.
29. A nota curta de pilar, a nota de Recuperação, `PillarWaiver.reason_text` e o contexto de `Contact` DEVEM aceitar no máximo 500 caracteres Unicode cada.
30. A causa e o ajuste de `ProtocolAlarm` DEVEM aceitar no máximo 2000 caracteres Unicode cada.
31. Cada uma das três respostas de `WeeklyReview` DEVE aceitar no máximo 5000 caracteres Unicode.
32. As notas de `CheckpointEval` DEVEM aceitar no máximo 2000 caracteres Unicode.
33. `Cycle.purpose_text` DEVE aceitar no máximo 1000 caracteres Unicode.
34. A cópia editável de `Manifest` e o asset final do manifesto DEVEM possuir no máximo 1 MiB quando codificados em UTF-8.
35. O áudio da nota do Pilar do Dia DEVE possuir duração máxima de 5 minutos, e o áudio de `WeeklyReview` DEVE possuir duração máxima de 30 minutos.
36. Os limites textuais DEVEM ser medidos em caracteres Unicode, exceto o limite do manifesto, medido em bytes UTF-8; o sistema NÃO DEVE impor limite mínimo não declarado.
37. Todo áudio persistido DEVE preservar referência, tipo, duração e integridade do arquivo válido até o limite aplicável.
38. Registros diários, blocos, áudios e snapshots DEVEM preservar a `operational_date` original e NÃO DEVEM ser reclassificados para outra data em fechamento, cancelamento, substituição ou falha de persistência.

## 5. Requisitos não funcionais

### RNF-01 — Offline, desempenho e plataforma

1. O sistema DEVE executar todas as funções previstas para cada fase sem conexão com a internet, exceto o sync opt-in da Fase 4.
2. A tela Hoje DEVE ficar utilizável em menos de 2 segundos após a abertura em condições normais no dispositivo Android de referência, Motorola Edge 70 Pro.
3. O Android DEVE ser a plataforma inicial; suporte a iOS NÃO DEVE bloquear o MVP.

### RNF-02 — Privacidade e segurança

1. O sistema NÃO DEVE incluir telemetria, analytics de terceiros ou coleta remota implícita.
2. Dados pessoais e áudios DEVEM permanecer locais, salvo exportação ou sync iniciado explicitamente pelo usuário.
3. O sistema NÃO DEVE exigir conta, login ou backend.
4. Backups da Fase 4 DEVEM ser criptografados sem armazenar a chave em texto puro junto ao backup.
5. O renderizador Markdown DEVE tratar conteúdo local como dado não confiável e impedir execução de HTML bruto ou script.

### RNF-03 — Acessibilidade e linguagem

1. A interface DEVE suportar fontes escaláveis sem ocultar ações essenciais.
2. Texto e componentes interativos DEVEM atingir contraste mínimo WCAG AA.
3. Toda copy DEVE usar português brasileiro, tom sóbrio e direto, sem emojis ou linguagem de coach motivacional.
4. As copies declaradas literais nesta especificação NÃO DEVEM ser parafraseadas.

### RNF-04 — Confiabilidade temporal

1. O sistema DEVE calcular data civil, data operacional, `day_close_time`, `night_end_time`, `block_deadline`, dias úteis, checkpoints e notificações no fuso oficial.
2. O sistema NÃO DEVE usar o fuso do aparelho como substituto do fuso oficial.
3. QUANDO o fuso ou relógio do aparelho mudar, o sistema NÃO DEVE duplicar dias, selos, dispensas, protocolos, sugestões ou revisões para a mesma chave lógica.
4. QUANDO o aplicativo permanecer fechado durante uma fronteira operacional, o sistema DEVE materializar deterministicamente o fechamento ao retornar, com um único `closed_at` lógico por dia.
5. QUANDO o aplicativo permanecer fechado após `block_deadline`, o sistema DEVE encerrar bloco órfão exatamente no deadline persistido e NÃO DEVE solicitar ação do usuário.
6. O sistema DEVE impedir duração negativa, fim posterior a `block_deadline` e atribuição de bloco a data operacional diferente da iniciada.
7. O scheduler DEVE aplicar o blackout antes de persistir e antes de entregar qualquer notificação.
8. A exceção dominical DEVE ser validada no agendamento e na entrega e possuir chave idempotente semanal.
9. Notificações de segunda-feira DEVEM possuir chave idempotente semanal e ocorrer somente após a abertura operacional de segunda-feira.
10. Recálculos de feriado DEVEM ser determinísticos, idempotentes e não destrutivos, sem reativar protocolos invalidados.
11. ENQUANTO o aplicativo estiver em foreground, o observador temporal DEVE detectar `day_close_time` e executar um único fechamento lógico mesmo sem interação do usuário.
12. QUANDO houver edição diária na fronteira, snapshot, autosave e fechamento DEVEM ocorrer na mesma transação, preservando o último estado presente no instante observado e impedindo escrita posterior no dia encerrado.
13. QUANDO a fronteira ocorrer em fluxo não diário, a atualização do contexto operacional NÃO DEVE interromper nem descartar o estado desse fluxo.

### RNF-05 — Integridade, limites e armazenamento

1. QUANDO uma entrada textual atingir seu limite, o sistema DEVE impedir somente caracteres excedentes, preservar integralmente o conteúdo válido e exibir mensagem neutra.
2. QUANDO uma gravação atingir 5 minutos no Pilar do Dia ou 30 minutos na Revisão Semanal, o sistema DEVE encerrá-la graciosamente e preservar um arquivo válido até o limite.
3. ANTES DE iniciar uma gravação de áudio, o sistema DEVE verificar espaço local suficiente; QUANDO não houver espaço suficiente, NÃO DEVE iniciar a gravação e DEVE exibir mensagem neutra.
4. ANTES DE executar exportação na Fase 3 ou posterior, o sistema DEVE verificar espaço local suficiente; QUANDO não houver espaço suficiente, NÃO DEVE iniciar nem deixar pacote parcial apresentado como válido e DEVE exibir mensagem neutra.
5. QUANDO gravação, autosave, fechamento ou exportação falhar, o sistema NÃO DEVE corromper textos, metadados ou arquivos anteriormente válidos.
6. O sistema DEVE aplicar de forma determinística os limites em caracteres Unicode e em bytes UTF-8 definidos nos Requisitos de dados, sem truncamento silencioso ou limite mínimo implícito.
7. O asset final do manifesto DEVE ser validado antes da entrega para não exceder 1 MiB em UTF-8, e a cópia editável NÃO DEVE aceitar salvamento acima desse limite.
8. Operações transacionais de fronteira e persistência DEVEM ser recuperáveis após interrupção sem duplicar, perder ou reclassificar dados entre datas operacionais.

## 6. Restrições de produto

1. Qualquer proposta de streak, pontos, badges de recompensa, ranking, punição, vergonha ou engajamento compulsivo DEVE ser recusada.
2. O alerta de mentoria é apenas sinalização de recência e NÃO DEVE ser reutilizado como recompensa.
3. Nenhuma feature além das descritas neste documento DEVE ser adicionada sem decisão explícita do proprietário.
4. Em conflito entre convenção de UX e regra de negócio, a regra de negócio DEVE prevalecer.
5. Protocolos por falha e Encerramento de Ciclo DEVEM permanecer internos e NÃO DEVEM gerar notificações.
6. O sistema NÃO DEVE adicionar reconciliação manual de timer.

## 7. Fases e cobertura

- **Fase 1 — MVP:** tempo operacional; RF-01 a RF-05; RF-09; configurações e histórico mínimos; seed do RF-06 com finalidade e datas exatas, inclusive fallback funcional “aguardando encerramento” sem countdown vencido; contrato de exportação sem execução; telas Hoje, Pedra e Ritmo; briefing local; Estudo com `block_deadline`; Recuperação; `PillarWaiver`; protocolos; feriados; asset integral do manifesto, cópia local e modo de edição da Pedra. Sem voz, gráfico, editor de ciclos, Encerramento de Ciclo, exportação executável ou sync.
- **Fase 2:** RF-07; RF-08 em texto; histórico cronológico de Revisões Semanais com draft, autosave, finalização explícita, detalhe read-only e avaliações associadas quando houver; sugestão semanal persistida; notificação opcional da revisão sob o blackout. Sem busca ou filtro no histórico.
- **Fase 3:** voz na revisão e na nota sempre opcional do Pilar do Dia; editor e Encerramento de Ciclo do RF-06; avaliações e gráfico; execução da exportação local de JSON e áudios. Esta fase DEVE estar disponível antes de `2027-06-30` para permitir rollover do ciclo seed, sem mover qualquer editor ou Encerramento de Ciclo para o MVP.
- **Fase 4:** sync GCS criptografado; preparação operacional para Neo4j; iOS.

Requisitos de fases futuras fazem parte do contrato do produto, mas NÃO DEVEM ampliar o escopo das fases anteriores. O ciclo seed e seus checkpoints DEVEM existir no MVP; o conteúdo integral do manifesto DEVE estar no asset antes da entrega do MVP. O MVP DEVE conter apenas o contrato da exportação, cuja execução começa exclusivamente na Fase 3.

## 8. Matriz de rastreabilidade

| Regra de negócio original | Decisão consolidada | Requisito principal | Criticidade | Fase inicial |
|---|---|---|---|---|
| RN-01 | Três Pilares reversíveis enquanto abertos; Manhã com treino e briefing; toggle literal; nota opcional; Noite cancelável/substituível até o fechamento e limitada por `night_end_time`; musculação como rótulo literal do ciclo atual | RF-01 | Normal | Fase 1 |
| RN-02 | Selo reversível enquanto aberto; último `seal_timestamp`; no máximo uma dispensa ativa por dia; revogação positiva auditável e recorrência somente de dispensas ativas do mesmo pilar | RF-02 | Normal | Fase 1 |
| RN-03 | Regra do Retorno; um protocolo por sequência; um pendente por abertura; invalidação definitiva | RF-03 | Crítica | Fase 1 |
| RN-04 | Estudo e Recuperação com valor idêntico | RF-04 | Crítica | Fase 1 |
| RN-05 | Fim de Semana; data operacional na home; fechamento observado em foreground; blackout; feriados retroativos autodeclarados e não destrutivos | RF-05 | Crítica | Fase 1 |
| RN-06 | Finalidade, checkpoints e seed no MVP com fallback pós-checkpoint; editor e Encerramento de Ciclo somente na Fase 3 | RF-06 | Normal | Fase 1 (seed e fallback); Fase 3 (editor e encerramento) |
| RN-07 | Mentoria e Contatos separados; maior carência; desempate por `created_at`; sugestão semanal persistida somente para contatos explícitos | RF-07 | Normal | Fase 2 |
| RN-08 | Revisão semanal em draft/finalizada; histórico cronológico; exceção dominical opt-in; segunda após abertura operacional | RF-08 | Normal | Fase 2 |
| RN-09 | Pedra; manifesto local limitado a 1 MiB UTF-8; parser do Juramento pelo heading e primeiro blockquote | RF-09 | Normal | Fase 1 |

Os requisitos auxiliares RA-01 e RNF-01 a RNF-05 apoiam as nove regras originais e NÃO constituem novas regras de negócio numeradas.

## 9. Decisões consolidadas e gate de aprovação

### 9.1 Registro conciso de decisões consolidadas

1. As regras de negócio originais são somente RN-01 Três Pilares, RN-02 Selo, RN-03 Regra do Retorno, RN-04 Descanso, RN-05 Fim de Semana, RN-06 Finalidade/checkpoints, RN-07 Pessoas, RN-08 Revisão e RN-09 Pedra.
2. A home usa a data operacional; `day_close_time` padrão é 03h00 e `night_end_time` limita Estudo sem eliminar Recuperação antes do fechamento.
3. O toggle literal é “Presença e execução honradas hoje”; a nota de problema complexo é sempre opcional; “Treino de musculação” é rótulo literal do ciclo atual, não categoria configurável no MVP.
4. Bloco órfão fecha em `block_deadline` na próxima abertura, sem reconciliação manual; Estudo ativo cancelado em dia aberto descarta seu bloco-rascunho de cumprimento e permite nova escolha válida na mesma data.
5. Registros diários são reversíveis somente em `open/unsealed`; um dia `open/sealed` exige a ação explícita “Reabrir o Dia”, que limpa `seal_timestamp`, antes de qualquer edição. Na fronteira em foreground, o estado presente é salvo atomicamente na data original e a tela encerrada fica read-only; depois, registros ordinários são imutáveis.
6. Existe no máximo uma dispensa ativa por dia; concluir o pilar dispensado exige confirmação neutra, revoga a dispensa de forma auditável e remove seu efeito sobre selo e recorrência. Dispensas revogadas permitem nova dispensa ativa no mesmo dia.
7. Cada sequência possui um protocolo; vários podem ficar pendentes, mas somente um aparece por abertura. Protocolos invalidados nunca são restaurados ou reutilizados.
8. Feriados retroativos são autodeclarados, precedidos por confirmação neutra de efeitos, aceitam motivo opcional auditável e recalculam sem punição ou bloqueio.
9. O blackout começa sábado 00h00 civil e termina na abertura operacional de segunda-feira; sua única exceção é a revisão dominical opt-in, uma vez entre 20h00 e 22h00.
10. O ciclo seed existe no MVP com as datas exatas e fallback “aguardando encerramento” sem bloqueio após o último checkpoint; editor e Encerramento de Ciclo pertencem somente à Fase 3, cuja entrega deve anteceder `2027-06-30`.
11. Mentoria e Contatos são entidades e módulos separados; mentor só entra no rodízio por cadastro explícito como contato, e seu único lembrete automático é o badge suave após 30 dias.
12. A sugestão semanal usa `last_touch_date` mais antiga, nulos primeiro, e `created_at` mais antigo no empate; pular não penaliza nem reinicia a ordem.
13. A partir da Fase 2, Revisão Semanal usa draft com autosave e finalização explícita read-only, com histórico cronológico sem busca ou filtro; voz permanece na Fase 3.
14. O MVP define somente o contrato de exportação; a execução local de JSON e áudios pertence exclusivamente à Fase 3.
15. O manifesto local nunca é sobrescrito e, assim como o asset final, respeita 1 MiB UTF-8; o Juramento é o primeiro bloco blockquote após o heading exato `## IV. O JURAMENTO INTERNO`; HTML bruto nunca é executado.
16. Limites de texto são medidos em caracteres Unicode, gravações param graciosamente no limite e falhas de espaço ou persistência preservam textos, metadados e arquivos válidos com mensagens neutras.

### 9.2 Gate de aprovação

Este documento DEVE ser revisado e aprovado antes da criação de `design.md` ou `tasks.md`. Durante este gate, nenhum código de aplicação ou teste DEVE ser criado. Qualquer mudança posterior DEVE retornar a este documento antes de avançar para design.
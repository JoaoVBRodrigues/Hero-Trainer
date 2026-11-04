# HERO TRAINER — Especificação de Game Design e Arquitetura — Fase 4C.1

**Versão:** decisões consolidadas 0.2
**Data:** 2026-11-04  
**Status:** baseline de design consolidada; implementação autorizada em etapas; estado e limites de validação registrados em [14_IMPLEMENTACAO_FASE_4C.md](./14_IMPLEMENTACAO_FASE_4C.md)
**Método:** inspeção estática de documentos, GDScript, JSON e testes. Não foram executados Godot, testes, simulações, builds ou verificações visuais.

> **Convenção:** **[REQUISITO DO AUTOR]** identifica uma decisão autoral inviolável. **[DECISÃO 4C.1]** identifica uma escolha de design consolidada após revisão sequencial dos quatro perfis. **[PROPOSTA HISTÓRICA]** identifica alternativas registradas antes da consolidação; não prevalecem sobre as decisões atuais. Este documento descreve a baseline anterior à implementação; o registro 14 informa o que foi aplicado e o que permanece sem validação de runtime.

## Registro de consolidação da Fase 4C.1

A auditoria e o histórico de propostas das seções seguintes foram preservados. Onde o texto antigo disser “proposta pendente” ou divergir deste registro, prevalecem os documentos de decisão e detalhamento:

- [`12_DECISOES_GAME_DESIGN_FASE_4C1.md`](./12_DECISOES_GAME_DESIGN_FASE_4C1.md) — decisões consolidadas, conciliação dos perfis, justificativas, valores de MVP, riscos e critérios de conclusão.
- [`13_ESPECIFICACAO_GAME_DESIGN_FASE_4C2.md`](./13_ESPECIFICACAO_GAME_DESIGN_FASE_4C2.md) — regras detalhadas do sistema de treinamento e desenvolvimento, fórmulas, exemplos e critérios de aceitação.

Decisões consolidadas: a missão só expira na transição da semana 8 para a 9, após as três ações e chance de resolução; tentativa, conclusão e prazo são estados distintos. O Pulso só fica disponível quando estabilidade `>=55` **e** TEC `>=30`, que também são ambos necessários para sucesso. Motivação usa as faixas `0–33: 0,90`, `34–66: 1,00`, `67–100: 1,10`; aptidões válidas ficam em `0,85–1,15`; mentoria compatível requer vínculo com instrutor `>=30` e reduz risco em 5 pontos percentuais. A loja MVP usa preços `80/120/160`, itens opcionais de conveniência e um espaço de equipamento ativo. Save/load usa um snapshot JSON versionado com cópia de recuperação e autosave.

As seções abaixo foram originalmente redigidas como proposta 0.1. Seu conteúdo técnico e as recomendações antigas permanecem para rastreabilidade; valores alternativos, inclusive disponibilidade OR do Pulso, itens com `+1` atributo, preços `80/100/120`, fórmulas de risco antigas e alternativas de save mais complexas, estão substituídos quando conflitam com os documentos 12 e 13.

### Histórico

- **0.1:** proposta inicial para revisão; todas as regras operacionais eram recomendações.
- **0.2:** decisões de 4C.1 consolidadas após revisão sequencial de Game Designer, Economy Designer, Godot Gameplay Scripter e Narrative Designer; especificação 4C.2 iniciada em documento próprio.

## 1. Resumo executivo

A Fase 4C.1 transforma requisitos já aprovados em contratos que possam orientar implementação futura sem implementar os sistemas. O projeto atual tem uma campanha em memória, atividades declarativas, atributos/recursos com limites, resultados narrativos determinísticos e estado de RNG reproduzível durante uma sessão. Não há save/load em disco, inventário, loja, aplicação de aptidões ou mentoria.

As propostas centrais deste documento são:

1. Encerrar a oportunidade da missão ao sair da semana 8; distinguir tentativa iniciada, missão concluída e falha por prazo.
2. Preservar o Pulso determinístico: sucesso somente com estabilidade do núcleo `>=55` **e** TEC `>=30`, sem usar RNG.
3. Usar motivação e aptidão somente nos ganhos de atributo; motivação baixa não aumenta risco nem bloqueia progresso.
4. Usar no máximo uma mentoria compatível por treino; sua contribuição proposta é reduzir o risco em 5 pontos percentuais, sem acumular bônus.
5. Introduzir uma loja pequena, itens opcionais e uma única vaga de equipamento ativo; valores de exemplo são apenas pilotos.
6. Salvar um snapshot validado e versionado após cada transição confirmada, persistindo também o RNG, missão, escolhas, inventário e equipamento.

O principal risco de continuidade é a combinação entre a nova expiração da missão e os finais atuais: hoje `resolve_ending` não retorna final sem `final_mission_attempted`, e dois finais exigem sucesso. A falha por prazo não pode ser registrada como tentativa fictícia. A proposta acrescenta um estado terminal explícito e ajusta o fallback para que a campanha ainda possa encerrar sem atribuir um resultado de sucesso.

## 2. Auditoria do estado atual

### 2.1 Classificação das evidências

| Sistema | Implementado e confirmado | Parcial ou apenas documentado | Ausente / dependência |
|---|---|---|---|
| Campanha | `TrainingState` guarda semana, ações restantes, atributos, recursos, vínculos, eixos, flags, estado de rota e seed/estado do RNG. `TrainingService` configura 16 semanas e 3 ações por semana a partir de `activities.json`. | Dados e textos de campanha são protótipos/rascunhos, não fatos canônicos. | Save/load em disco; política de prazo da missão; estado explícito de missão encerrada. |
| Atividades | O JSON tem 8 atividades. O serviço valida IDs/campos, cria preview sem avançar RNG, aplica a atividade em estado duplicado e só consome ação numa confirmação válida. | `aptitudes` e `mentor_affinity` são carregados/validados, mas não aplicados. | Efeito mecânico de aptidão, motivação ou mentoria; novas categorias/atividades. |
| Falha de treinamento | Fórmula atual: `clamp(0, 60, round(max(0, 35-energy) * 0.9 + stress * 0.2 + injury_level * 12 - mentor_bonus))`. O código fixa lesão e mentoria em zero. Falha omite ganhos de atributos, mas aplica custos/deltas e consome a ação. | O GDD v0.1 propõe fatores de aptidão, humor, mentoria e instalação, com máximo de 12 pontos por ação, mas isso não é comportamento implementado. | Definição aprovada de injury/facility; multiplicadores operacionais; proteção/recuperação após falhas. |
| Motivação | `TrainingState.motivation` mapeia o campo JSON `mood`; começa em 65 para Hori e pode mudar por descanso/eventos. | A UI apresenta o recurso, mas motivação não altera treino, risco, evento elegível ou final examinado. | Regra mecânica, feedback da prévia e regras de persistência. |
| Aptidões/mentoria | Aptidões individuais em `characters.json`; `mentor_affinity` em atividades; vínculo `instructor` em estado inicial. | São metadados. O cálculo usa `PLACEHOLDER_MENTOR_BONUS = 0`; não existe seleção/disponibilidade de mentora no serviço. | Uma regra única de aplicação, eligibility e preview. |
| Economia | Hori começa com 50 créditos. Estágio concede +25 créditos e +1 reputação, custa 8 energia e 1 ação. Créditos não podem ficar negativos ao aplicar deltas; não têm cap de gameplay. | Valores são de demonstração e a auditoria 4B identifica estágio como fonte repetível. | Loja, gastos, catálogo de itens, inventário, equipagem e regra de compra. |
| Missão | Uma missão de 3 etapas é carregada de `Hori Draft/missions_hori_draft.json`. Etapas têm escolhas e resultados determinísticos; falhas intermediárias são recuperáveis. Pulso verifica estabilidade e TEC. | JSON declara janela semana 8–8 e falhas recuperáveis; descrição do Pulso diz “alto risco”, embora sua resolução aprovada seja determinística. | Falha automática por prazo, estado terminal sem tentativa, fechamento de final quando expirada. |
| Finais | Há 4 finais. Dois exigem `final_mission_success`; autonomia e fallback exigem `final_mission_attempted`. O serviço escolhe o final elegível de maior prioridade. | Textos continuam rascunhos. O fallback e sua nota merecem revisão de tom para não culpabilizar sofrimento ou traços canônicos. | Fallback explícito para expiração sem tentativa; variantes de epílogo coerentes com os estados terminais. |
| Eventos | Serviço carrega 8 eventos ativos e valida estritamente schema e efeitos. Escolhas são aplicadas sobre cópia de estado; o preview não consome ação nem RNG. | `data/events.json` contém conteúdo legado/de exemplo e não é a fonte carregada pelo serviço atual. | Histórico persistente de escolhas e política de migração do conteúdo. |
| Save/load | Não foi localizado código de gravação em disco nos scripts examinados. O Dashboard cria novo estado inicial em `_ready`. | O GDD recomenda `user://` e versão de save; isso é apenas documentação. | Serviço de save, envelope versionado, validação, recuperação e integração no ciclo de sessão. |

### 2.2 Arquivos consultados

- Instruções e perspectivas: `.github/agents/game-designer.agent.md`, `economy-designer.agent.md`, `godot-gameplay-scripter.agent.md`, `narrative-designer.agent.md`, `Hero_Trainer_Kit_v02/docs/AI_WORK_POLICY.md`. Não foi localizado `AGENTS.md` nem outro arquivo de instrução raiz.
- Documentação: `docs/01_GDD.md`, `docs/07_CICLO_JOGAVEL.md`, `docs/10_AUDITORIA_CAMPANHA_E_BALANCEAMENTO.md`, `docs/05_CANONE_PERSONAGENS.md`, `docs/12_ESPECIFICACAO_EXPANSAO_FASE_5.md`.
- Código: `scripts/training_state.gd`, `training_service.gd`, `training_preview.gd`, `narrative_service.gd`, `training_dashboard.gd`.
- Dados: `data/activities.json`, `data/characters.json`, `Hori Draft/events_hori_draft.json`, `missions_hori_draft.json`, `endings_hori_draft.json`, e `data/events.json` para comparar o conjunto legado.
- Testes lidos estaticamente: `tests/test_training_service.gd`, `tests/test_narrative_campaign.gd`.
- Não há documento específico anterior da Fase 4C no projeto. A especificação da Fase 5.0 registra as decisões do autor como dependências, não como prova de implementação.

### 2.3 Perfil atual da campanha e valores confirmados no protótipo

`activities.json` define 16 semanas × 3 blocos = 48 blocos. Hori inicia com POT 30, RES 34, TEC 28, TEO 38, SIN 40; energia 75, estresse 12, motivação 65, créditos 50 e reputação 20. Caps de atributos e recursos são 100. Essas estatísticas são dados de protótipo, não cânone.

| Atividade atual | Ganhos nominais de atributo | Custo/recursos atuais | Falha atual |
|---|---|---|---|
| Combate | POT +5, TEC +2 | energia −15, estresse +6 | Sim |
| Laboratório | TEO +5, SIN +2 | energia −10, estresse +4 | Sim |
| Controle de energia | SIN +5, TEC +2 | energia −13, estresse +5 | Sim |
| Condicionamento | RES +5, POT +1 | energia −13, estresse +3 | Sim |
| Descanso e lazer | — | energia +25, estresse −12, motivação +8 | Não |
| Estágio de apoio | — | créditos +25, reputação +1, energia −8, estresse +4 | Não |
| Conversa com Ray | — | vínculo Ray +8, estresse −4 | Não |
| Tempo com Luppi | — | vínculo Luppi +8, estresse −4 | Não |

Atividades usam um bloco. Descanso e as duas atividades de vínculo não custam energia, portanto não foi encontrado bloqueio inevitável por energia zero. Energia persiste entre semanas; não há recuperação automática ao avançar.

### 2.4 Contratos estruturais observados

- `TrainingState.duplicate_state()` e `copy_from()` copiam os campos existentes, incluindo RNG. Campos futuros precisam ser adicionados aos dois caminhos ou os previews/cópias perdem estado.
- A validação de atividades usa allowlist de chaves; novos campos para preço, equipamento, mentoria ou dupla exigem atualização coordenada do schema e dos testes.
- `NarrativeService` exige exatamente 8 eventos, 1 missão e 4 finais. Testes também esperam 8 eventos e 4 finais.
- `is_mission_due()` verifica `week >= week_min`, mas não aplica `week_max`. O JSON declara semana 8–8.
- `apply_mission_choice()` avança `mission_stage`; ao chegar à terceira etapa, marca `final_mission_attempted`. A escolha final também marca `final_mission_success` no sucesso. A resolução de finais exige `final_mission_attempted`.
- O Pulso fica disponível no draft quando estabilidade `>=55` **ou** protocolo de equipe; o seu resultado em código é sucesso somente quando estabilidade `>=55` **e** TEC `>=30`. A disponibilidade e o resultado são contratos diferentes e devem ser apresentados claramente.
- O Dashboard inicializa uma campanha nova em `_ready`, processa eventos antes da missão e verifica o final quando a semana 16 termina. Introduzir save exige mudar a fronteira de inicialização para carregar/retomar explicitamente, sem sobrescrever o save ao abrir a cena.
- Os testes existentes registram o comportamento atual; suas expectativas precisam ser alteradas junto com futuras decisões aprovadas, não interpretadas como requisitos imutáveis.

## 3. Decisões já aprovadas pelo autor

| ID | Requisito | Limite desta especificação |
|---|---|---|
| A1 | A missão principal falha automaticamente quando a campanha ultrapassa a semana 8 sem conclusão. | Definir o instante da transição e o registro da falha; não manter uma missão vencida disponível indefinidamente. |
| A2 | Pulso determinístico: estabilidade do núcleo `>=55` **e** TEC `>=30` são ambas necessárias para sucesso. | Não adicionar probabilidade/RNG ao Pulso. |
| A3 | Motivação afeta mecanicamente o treinamento. | Propor uma regra transparente, sem converter motivação em moralidade. |
| A4 | Aptidões individuais afetam mecanicamente o treinamento. | Reutilizar os multiplicadores existentes como dados de protótipo; não tratar seus números como cânone. |
| A5 | Mentoria tem efeito mecânico, não apenas decorativo. | Definir uma contribuição delimitada e não acumulável. |
| A6 | Economia inclui compras, equipamentos e gastos. | Modelo pequeno, com compras opcionais e sem bloqueio da campanha. |
| A7 | Save/load em disco faz parte do MVP. | Definir formato, ciclo, validação, migração e continuidade do RNG; não implementar. |

## 4. Especificação operacional da missão

### 4.1 Estados e transições propostos

**[PROPOSTA]** A janela atual permanece semana 8. “Ultrapassar semana 8” significa a transição de calendário para semana 9, depois de concluídas as ações da semana 8 e antes de abrir qualquer escolha na semana 9. A resolução e a flag de prazo são aplicadas uma única vez nesse limite.

| Estado derivado | Condição | É possível escolher etapa? | Transição |
|---|---|---:|---|
| `locked` | semana < 8 e missão não resolvida | Não | Ao entrar na semana 8: `available`. |
| `available` | semana = 8, etapa 0, missão não resolvida | Sim | Primeira escolha válida: `in_progress`; ao terminar etapa 3: sucesso ou falha concluída. |
| `in_progress` | semana = 8, etapa 1 ou 2 | Sim | Cada escolha válida avança uma etapa. Falha das etapas 1–2 é recuperável e não encerra a missão. |
| `succeeded` | etapa 3 concluída e `final_mission_success=true` | Não | Terminal; não pode ser reaberta. |
| `failed_after_attempt` | etapa 3 concluída e `final_mission_success` ausente/falsa | Não | Terminal; representa conclusão da operação sem sucesso total, não falha automática por prazo. |
| `failed_by_deadline` | calendário entra na semana 9 sem etapa 3 concluída | Não | Terminal; a missão não pode ser reaberta nessa campanha. |

O estado `locked` é derivado do calendário, não precisa ser gravado. Estado terminal é persistente. O campo `mission_stage` preserva o progresso das três etapas.

### 4.2 Flags e semântica

**[PROPOSTA]** Usar flags explícitas, validadas e mutuamente consistentes:

| Flag | Significado |
|---|---|
| `final_mission_attempted` | O jogador confirmou ao menos uma escolha válida de missão. Definir na primeira escolha aplicada; não inferir a partir de mera elegibilidade. |
| `final_mission_completed` | A escolha da etapa 3 foi aplicada. Falso para qualquer expiração, inclusive após etapas parciais. |
| `final_mission_success` | A etapa 3 terminou com sucesso. Só pode ser verdadeiro quando `final_mission_completed=true`. |
| `final_mission_failed_by_deadline` | A janela acabou antes da conclusão. Verdadeiro apenas ao transitar para semana 9 com etapa 3 pendente. |
| `final_mission_resolved` | A campanha não aceita novas escolhas desta missão: conclusão na etapa 3 ou prazo vencido. Deve ser verdadeiro para `completed` ou `failed_by_deadline`. |

Uma falha recuperável na etapa 1 ou 2 **não** define falha terminal. Ao término da etapa 3, `attempted=true`, `completed=true`, `resolved=true`; `success` é verdadeiro somente se a escolha final tiver resultado de sucesso. Ao vencer o prazo, `resolved=true`, `failed_by_deadline=true`, `completed=false`; `attempted` reflete se houve ao menos uma escolha válida antes do prazo.

**Regra de consistência:** `success => completed => resolved`; `failed_by_deadline => resolved && !completed && !success`; nunca permitir simultaneamente sucesso e falha por prazo. O carregador de save rejeita combinações contraditórias.

### 4.3 Pulso de Contenção

- **[REQUISITO] Resultado:** determinístico, sem sorteio, com sucesso somente se `core_stability >= 55 AND tec >= 30` no instante de confirmação.
- **[PROPOSTA] Disponibilidade:** preservar o unlock atual (estabilidade `>=55` **ou** flag do protocolo de equipe), mas mostrar as duas condições de sucesso no preview e indicar qual está faltando. Isso permite a escolha consciente de um resultado de falha recuperável, se o autor quiser manter esse risco tático.
- Se o autor preferir que não seja possível selecionar uma opção com sucesso impossível, a alternativa é tornar a disponibilidade também `stability >=55 AND TEC >=30`; isso mudaria o papel do protocolo de equipe e requer aprovação explícita.
- Pulso não consome RNG. A consulta/preview e a escolha não avançam o estado do gerador.
- Alinhar a descrição “alto risco/alto ganho” do JSON ao determinismo: explicar que o resultado é uma checagem de limiar, sem linguagem que sugira probabilidade aleatória.

### 4.4 Efeito nos finais atuais

| Resultado da missão | Finais de sucesso | Final independente | Fallback e encerramento |
|---|---|---|---|
| Sucesso na etapa 3 | Continuam elegíveis pelas condições atuais de vínculos/equipe ou atributos/carreira. | Elegível se cumprir autonomia e missão completa. | Fallback se nenhum final de maior prioridade se aplicar. |
| Etapa 3 concluída sem sucesso | Finais que exigem `final_mission_success` não elegíveis. | Pode ser elegível se cumprir autonomia e a missão foi completada. | Fallback garantido caso nenhum outro se aplique. |
| Prazo vencido sem qualquer escolha | Finais de sucesso não elegíveis; não definir sucesso retroativo. | Não elegível, pois não houve tentativa/conclusão. | Fallback fica elegível por `final_mission_resolved`, sem marcar tentativa. O epílogo deve reconhecer a expiração como circunstância/resultado institucional, não falha moral de Hori. |
| Prazo vencido após uma ou duas escolhas | Finais de sucesso não elegíveis e etapa 3 incompleta. | **[PROPOSTA]** Não elegível sem missão concluída, preservando o significado atual do final independente. | Fallback garantido; um texto/trecho condicional pode reconhecer que houve tentativa interrompida. |

**Mudança necessária na condição dos dados:** `resolve_ending()` deve ser habilitado por `final_mission_resolved`, não apenas `final_mission_attempted`. Os dois finais de sucesso mantêm a flag de sucesso. O final independente exige a missão completa, além da autonomia atual. O fallback exige resolução terminal. O ID dos quatro finais pode ser mantido; o texto do fallback deve ser revisto para a variante de prazo, evitando atribuir o resultado a sintomas, condição psicológica ou caráter de Hori.

## 5. Especificação de motivação

### 5.1 Regra proposta

**[PROPOSTA]** Motivação (`TrainingState.motivation`, JSON `mood`) modifica apenas ganhos positivos de atributos em atividades de treino. Não altera risco de falha, custo de energia/créditos, disponibilidade de atividades, elegibilidade da missão nem valor moral da personagem.

| Motivação antes da atividade | Multiplicador proposto | Interpretação |
|---:|---:|---|
| 0–33 | 0,90 | Ganhos um pouco menores, nunca zeroados por motivação sozinha. |
| 34–66 | 1,00 | Faixa neutra. |
| 67–100 | 1,10 | Ganhos um pouco maiores. |

Fórmula candidata por atributo:

```text
ganho_calculado = round(ganho_base × aptidão_da_atividade × fator_de_motivação)
ganho_aplicado = min(ganho_calculado, cap_do_atributo - atributo_atual)
```

Aplicar deltas somente quando a atividade for bem-sucedida; falhas continuam aplicando custos e recursos atuais, mas nenhum ganho de atributo. Arredondar por atributo, uma vez, depois dos multiplicadores. Valores finais sempre passam pelos caps de atividade/atributo.

**Recuperação:** descanso permanece disponível a energia zero e concede +8 motivação, limitado a 100; mudanças narrativas de motivação continuam limitadas a 0–100. Não introduzir atividade bloqueada por motivação baixa nem espiral de risco. O preview mostra valor atual/faixa, fator aplicado, ganho calculado e ganho efetivo após cap.

### 5.2 Exemplos manuais com dados atuais

Valores abaixo são propostas de fórmula aplicadas a dados de protótipo; não são resultados executados:

- Hori começa com motivação 65, portanto fator 1,00. Combate, aptidão 1,10: POT `round(5 × 1,10 × 1,00)=6`; TEC `round(2 × 1,10 × 1,00)=2`.
- Com motivação 33, o mesmo combate produziria POT `round(5 × 1,10 × 0,90)=5`; TEC `round(2 × 1,10 × 0,90)=2`.
- Com motivação 67, combate produziria POT `round(5 × 1,10 × 1,10)=6`; TEC `round(2 × 1,10 × 1,10)=2`.
- Hori começa em 65; uma atividade de descanso o levaria a 73 com o delta atual (+8), passando à faixa de 1,10. Por arredondamento, nem todo atributo ou treino mostrará diferença em cada uso; a prévia deve mostrar o multiplicador e não prometer um ponto adicional quando ele não se materializa.
- Em laboratório, aptidão 0,95 e motivação 65: TEO `round(5 × 0,95)=5`, SIN `round(2 × 0,95)=2`. Isso pode coincidir com o ganho nominal; a aptidão ainda é aplicada matematicamente, mas sua contribuição pode ser invisível após arredondamento nesse caso.

As fronteiras 33/34 e 66/67 geram mudanças discretas. A escolha de bandas é simples e auditável, mas precisa de aprovação e playtest localizado antes de ser fixada.

## 6. Especificação de aptidões

- Usar o multiplicador existente em `characters.json`, indexado pelo ID da atividade. Não criar árvore de especialização, XP de aptidão ou requisito para abrir rota.
- Aplicar somente a deltas positivos de atributos de atividades de treino; não multiplicar ganhos de créditos, reputação, vínculos, motivação, nem custos.
- Atividade sem aptidão declarada usa multiplicador neutro `1,00`. Aptidão ausente não bloqueia a atividade.
- Valores fora da faixa aprovada são erro de dados, não clamp silencioso. **[PROPOSTA]** Faixa de conteúdo inicial `0,85–1,15`, que abrange os dados atuais de protótipo.
- Combinar aptidão com motivação pela fórmula da seção 5; não combinar com fatores de instalação ou bônus de equipamento nesta fase sem regra aprovada.
- Aplicar primeiro os multiplicadores, arredondar cada atributo e só então aplicar cap do atributo. Mostrar no preview base, aptidão, motivação, delta calculado e cap efetivo.
- **[PROPOSTA]** Manter o teto de design de 12 pontos de atributo por ação mencionado no GDD, validando dados: nenhuma atividade pode exceder esse total no maior multiplicador permitido. Como os treinos atuais têm ganhos nominais totais de 6 ou 7, a regra não os reduz.
- Aptidão é uma afinidade de desempenho, não valor ou julgamento moral. Nenhuma rota ou final deve depender de “ser boa” numa aptidão.

**Exemplo de controle de faixa:** um ganho base de 5 com aptidão 0,85 e fator de motivação 1,00 dá `round(4,25)=4`; com aptidão 1,15 dá `round(5,75)=6`. São exemplos matemáticos da fórmula proposta, não estado de campanha testado.

## 7. Especificação de mentoria

- **[PROPOSTA] Seleção/availability MVP:** manter o vínculo já existente `instructor` e usar `mentor_affinity` para definir compatibilidade da atividade. Para o MVP 4C, a mentoria do instrutor genérico fica automaticamente disponível em atividade de treino com afinidade não nula quando `bonds.instructor >= 30`. Hori inicia com vínculo 30. Atividade sem afinidade ou abaixo do limiar é sem mentor; não deve falhar por isso.
- Não criar personagem canônico, professora nomeada, história ou vínculo novo nesta etapa. Mentoras individuais e sessões em dupla ficam para uma fase aprovada de conteúdo.
- **Efeito proposto:** reduzir a chance de falha em 5 pontos percentuais, após calcular/arredondar a chance base e antes do clamp final: `max(0, risco_base - 5)`. Não altera ganho de atributo, custo, energia, duração ou RNG.
- No preview, informar mentor/afinidade e risco antes/depois; se o risco base já for 0–5, apresentar o valor efetivo 0 sem sugerir bônus negativo.
- No máximo um mentor pode contribuir por sessão. Não acumular mentor, item e afinidade como reduções independentes de risco. A contribuição aplica-se a atividade com falha habilitada; atividades determinísticas continuam sem modificador.
- O vínculo de mentor qualifica a disponibilidade, não cria bônus crescente por ponto neste MVP. Não realizar grind relacional para aumentar repetidamente o bônus.
- A fórmula atual possui placeholders `injury_level` e `mentor_bonus`, ambos efetivamente zero. O valor de lesão permanece sem mecânica nesta especificação; o bônus de mentoria proposto substitui somente o placeholder de mentoria. Qualquer regra de lesão exige decisão própria.

**Exemplo:** em laboratório com energia 10 e estresse 100, a fórmula atual arredonda para 43%. Com mentoria elegível, a proposta resultaria em 38%. No estado inicial de Hori, o risco base é 2%; com mentor seria limitado a 0%. Cálculos manuais, não testes.

## 8. Economia e equipamentos

### 8.1 Fluxo de créditos observado

- Saldo inicial: 50.
- Fonte repetível atual: estágio, +25 créditos por ação, −8 energia e +4 estresse.
- A campanha tem 48 ações. O estágio não é obrigatório para os finais atuais.
- Não foi localizado nenhum sink monetário em atividade, missão ou efeito narrativo atual; logo, sem loja, o saldo só acumula.

Exemplos aritméticos pequenos:

| Perfil ilustrativo | Estágios em 16 semanas | Créditos ao final antes de compras | Energia/ações |
|---|---:|---:|---|
| 1 estágio por semana | 16 | `50 + 16×25 = 450` | 16 ações de estágio; até 32 ações para outras atividades. |
| 2 estágios e 1 descanso por semana | 32 | `50 + 32×25 = 850` | Usa os 48 blocos; por semana, −16 energia dos estágios e +25 do descanso, antes de caps. É um padrão de alto foco em renda, não uma previsão de jogadores. |

### 8.2 Modelo mínimo proposto

- Uma loja de catálogo fixo na interface do Hub; compras não consomem bloco de treinamento. Equipar/trocar não consome bloco.
- Créditos são inteiros não negativos, sem cap de jogo adicional nesta proposta. Não permitir saldo negativo, preço negativo, preço fracionário, item duplicado ou compra de ID desconhecido.
- Cada item é equipamento permanente, comprado uma vez por campanha, não consumível nem revendável no MVP. Inventário guarda até uma cópia de cada ID.
- Um único slot de equipamento ativo. Equipar outro substitui o anterior; itens inativos permanecem no inventário. Nenhum efeito de equipamento se acumula com cópia, item equivalente ou mentoria.
- Compra/equipagem só altera o estado após validação completa; compra rejeitada não debita créditos nem concede item. A compra deve ser persistida como uma transação única.
- Nenhum equipamento é requisito para concluir semana, missão, Pulso ou final. A rota sem compras mantém-se viável.
- A fonte de renda existente continua sendo o estágio. Uma fonte nova (bolsa, prêmio, doação ou renda narrativa) não é presumida; exige decisão narrativa/econômica.

### 8.3 Itens e preços-piloto

Os nomes/efeitos abaixo são propostas funcionais, sem canonização. O efeito de cada equipamento deve ser pequeno, único e visível; o seguinte modelo serve para estimativa e precisa de aprovação:

| Item candidato | Efeito candidato, não aprovado | Preço piloto, não aprovado |
|---|---|---:|
| Faixas de treino ajustáveis | +1 POT efetivo somente em combate bem-sucedido | 80 créditos |
| Tablet de análise de campo | +1 TEO efetivo somente em laboratório bem-sucedido | 100 créditos |
| Comunicador de equipe | +1 RES efetivo somente em uma atividade futura de treino em dupla; não afeta Pulso nem garante sucesso | 120 créditos |

**Ordem candidata de efeito:** calcular ganhos base × aptidão × motivação, arredondar, somar o bônus fixo do item compatível, limitar pela folga até o cap; continuar respeitando o teto total proposto de 12 pontos por ação. Item não muda chance de falha, requisito narrativo nem relação. Se o autor rejeitar o efeito do terceiro item, mantê-lo fora do catálogo até a atividade de dupla ser aprovada.

**Análise dos preços:** o conjunto custa 300. Com um estágio por semana, 450 disponíveis permitem comprar os três e deixar 150. Com dois estágios por semana, 850 permitem comprá-los e deixar 550. Partindo dos 50 iniciais, o saldo de 80/100/120 seria alcançado, respectivamente, após 2/2/3 estágios se não houver outros gastos. Esses exemplos não definem preço final nem perfil de jogador. A compra de todos é opcional; não exigir renda específica para obter qualquer final.

Antes de aprovar preços, revisar a frequência de estágio, custos de energia, acessibilidade do Hub, efeitos reais e se a loja deve permanecer utilizável após o encerramento. Não há necessidade de impor um sink adicional para “corrigir inflação” numa campanha finita se o saldo não tiver outro uso.

## 9. Arquitetura de salvamento e carregamento

### 9.1 Formato e campos

**[PROPOSTA]** Arquivo JSON em `user://hero_trainer_save_v1.json` (nome piloto), com envelope:

```json
{
  "save_schema_version": 1,
  "content_revision": "hori_route_v1",
  "campaign_id": "hori",
  "saved_at": "timestamp ISO-8601",
  "campaign": {}
}
```

`campaign` deve persistir todos os dados que alteram continuação ou resultado:

- `week`, `actions_remaining`, personagem/campanha ativa.
- `stats`, `axes`, `route_state`, `flags`, `bonds`.
- `energy`, `stress`, `motivation`, `credits`, `reputation`.
- `mission_stage` e flags de tentativa/conclusão/sucesso/prazo; `ending_id` e estado de encerramento.
- `rng_seed`, `rng_state` e identificador de versão do formato/algoritmo RNG suportado.
- IDs de escolhas/eventos/ações aplicadas, em histórico finito e ordenado, para auditoria e prevenção de reaplicação.
- Inventário, itens comprados e `equipped_item_id`.
- IDs e revisão de conteúdo necessários para mapear saves em migrações futuras.

Não persistir preview, botões em foco, modal aberto, textura ou outro estado transitório de UI. Estado futuro da Parte 5 (novos flags, dupla, mentor escolhido, itens) deve entrar no contrato versionado antes de integrar.

### 9.2 Salvamento, atomicidade e momentos

- Autosave após cada transação confirmada: atividade (incluindo resultado/RNG), escolha de evento, escolha de missão, mudança de semana, compra, equipagem e definição de final.
- Salvar somente após validação e em fronteira estável; preview e abertura/fechamento de diálogo sem escolha não gravam efeitos.
- Manter ação, custo, efeitos e RNG no mesmo snapshot. A UI só deve publicar o novo estado como confirmado após o save bem-sucedido, ou deve informar claramente que a alteração ainda não está salva e permitir retry sem aplicar o efeito novamente.
- Escrever primeiro em arquivo temporário, descarregar o buffer, reler/validar o JSON e então substituir o snapshot principal, mantendo ao menos um backup anterior. Confirmar a estratégia de substituição atômica nas plataformas-alvo antes de implementar; não presumir atomicidade de rename sem validação.
- Erro de espaço, permissão, serialização ou troca de arquivo deve ser mostrado explicitamente. Não reportar sucesso nem sobrescrever o último save válido com dados inválidos.
- Save manual pelo Hub pode coexistir como ação do jogador, mas usa o mesmo fluxo transacional. Não criar vários slots no MVP sem decisão.

### 9.3 Carregamento, validação e migração

- Ao iniciar, distinguir: save inexistente (oferecer campanha nova), save válido (retomar ou pedir escolha explícita) e save inválido/corrompido (informar erro e oferecer recuperar backup ou iniciar nova campanha sem apagar o original).
- Validar versão antes de desserializar; validar todos os campos/tipos, limites da campanha, caps, IDs existentes, unicidade de inventário/histórico e consistência das flags de missão. Não aceitar parcialmente um save e completar valores ausentes silenciosamente.
- Save com versão mais nova que a suportada deve ser preservado e não sobrescrito. Migração conhecida deve ser função pura `N -> N+1`, validada antes de gravar uma nova cópia.
- IDs de atividade, evento, escolha, personagem e item são estáveis. Remoção/renomeação exige mapa de migração de conteúdo. Flags antigas não podem mudar de significado sem migração.
- A campanha atual não possui formato de save anterior, portanto não há arquivo v0 identificado para migrar. A primeira versão persistente é a v1; as regras de migração são infraestrutura futura, não migração já realizada.
- RNG guarda seed e estado em cada transição aleatória confirmada. Preview, save e load não consomem número aleatório. Registrar compatibilidade do gerador/versão de runtime; se uma versão futura não puder reproduzir o stream, reportar a limitação e migrar de forma explícita, nunca reseed silenciosamente.

### 9.4 Como evitar dupla aplicação de efeitos

- Aplicar cada ação, escolha ou compra a uma cópia candidata do estado; validar efeito, saldo, histórico e RNG; persistir o snapshot completo; só então publicar o novo estado à sessão.
- Cada transação confirmada recebe sequência/ID estável. Se a mesma requisição for recebida novamente, rejeitá-la se já estiver no histórico.
- Salvar resultado e novo estado de RNG na mesma transação. Após carregar, não reaplicar escolhas a partir do log; o log é evidência/idempotência, enquanto o snapshot é o estado autoritativo.
- Flag de evento escolhido e registro de escolha devem ser gravados junto com seus efeitos. Flag de final e `ending_id` também são gravados antes de exibir “final salvo”.

## 10. Fórmulas propostas e exemplos

| Regra | Fórmula candidata | Estado |
|---|---|---|
| Ganho de atributo em sucesso | `round(base × aptitude(activity) × motivation_band)` | Proposta; aplicar cap do atributo. |
| Faixa de motivação | 0–33: 0,90; 34–66: 1,00; 67–100: 1,10 | Proposta; limites precisam de aprovação/playtest. |
| Aptidão ausente | `1,00` | Proposta; atividade continua acessível. |
| Teto de ganho | Total por ação `<=12`, validado também contra o pior caso de multiplicadores | Proposta baseada no GDD v0.1; não implementado. |
| Risco base de atividade arriscada | `clamp(round(max(0,35-energy)×0,9 + stress×0,2), 0, 60)` | Fórmula atual, com placeholders de lesão/mentoria omitidos até haver regra ativa. |
| Risco com mentor elegível | `clamp(risco_base - 5, 0, 60)` | Proposta de redução em pontos percentuais após arredondar risco base. |
| Pulso de Contenção | `success = core_stability >= 55 AND TEC >= 30` | Requisito do autor; determinístico e sem RNG. |
| Créditos por estágio | +25 | Valor atual do protótipo; sujeito a rebalanceamento futuro, não alterado nesta fase. |

**Exemplo de risco atual:** energia 75 e estresse 12: `round(0 + 2,4)=2%`; com mentor elegível, proposta: `max(0,2−5)=0%`. Laboratório com energia 10 e estresse 100: `round(22,5+20)=43%`; com mentor: 38%.

**Exemplo de economia:** 16 estágios geram 400, mais 50 iniciais = 450; três itens-piloto totalizam 300, restando 150. Nenhum item deve ser necessário a missão/final.

## 11. Impacto futuro em serviços, dados e interface

| Superfície | Mudança futura necessária | Princípio de compatibilidade |
|---|---|---|
| `TrainingState` | Acrescentar estado de missão explícito/flags, inventário, itens equipados e histórico transacional; incluir campos em `duplicate_state`/`copy_from`. | Não manter estado paralelo fora da campanha persistível. |
| `TrainingService` | Aplicar motivação/aptidão na fórmula central, mentoria em risco; incluir operações validadas de gasto/compra/equipagem ou delegá-las a serviço pequeno de economia. | Preview e resultado confirmado usam o mesmo cálculo; rejeições não alteram estado/RNG. |
| `NarrativeService` | Expiração idempotente na transição para semana 9, finalização por `final_mission_resolved`, critérios de missão/final coerentes. | Pulso determinístico; IDs e efeitos declarativos permanecem validados. |
| Serviço de save futuro | Serializar/validar/migrar snapshot e preservar backup. | Sem lógica de gameplay dentro do armazenamento. |
| `training_dashboard.gd` | Carregar/retomar estado sem iniciar campanha nova silenciosamente; apresentar expiração, preview dos fatores de treino, status de loja/inventário e erros de save. | Dados da UI derivam dos serviços/estado; não duplicar fórmulas. |
| `activities.json` | Manter atividade, categoria, ganhos, custo, afinidade e qualquer novo metadado sob schema/versionamento. | Extensões coordenadas; IDs existentes estáveis. |
| `characters.json` | Continuar como fonte de aptidões e dados iniciais; definir papel de mentoras sem criar personagem canônico novo. | Valores continuam prototípicos e dados de personagens não jogáveis não ativam campanhas automaticamente. |
| JSONs de missão/finais | Representar prazo e condições de final de modo validável; rever unlock/preview do Pulso e texto do fallback. | Quatro IDs de final podem ser preservados; nenhuma consequência canônica nova presumida. |
| Testes | Acrescentar regressões de fronteiras, duplicação, persistência e compatibilidade. | Alterar expectativas de 8 eventos/4 finais apenas quando conteúdo mudar; não remover cobertura atual sem substituição. |

## 12. Contratos que a Parte 5 precisa respeitar

1. Não anexar eventos sem rever o carregador que exige exatamente oito eventos; escolher previamente rota separada, composição explícita ou revisão versionada de contagem.
2. A missão expirada é terminal, mas não significa que Hori a tentou nem que teve sucesso; eventos/finais devem distinguir `attempted`, `completed` e `failed_by_deadline`.
3. A Parte 5 não deve alterar os limiares do Pulso nem adicionar RNG: estabilidade `>=55` e TEC `>=30` seguem necessários para sucesso.
4. Novas atividades usam a mesma fórmula central e o mesmo preview de custo/ganhos; não criar atalhos que ignorem motivação, aptidão, mentoria ou caps.
5. Atividades em dupla precisam declarar parceira/requisitos e efeito de vínculo sem tornar grind social obrigatório. Identidade e dados de novos secundários aguardam aprovação; não criar vínculos no estado antes de definir schema/UX.
6. Aptidão/mentoria não devem empilhar de modo invisível; cada contribuição precisa aparecer no preview. O treino em dupla não pode ativar múltiplas mentoras sem regra aprovada.
7. Itens da Parte 5 têm IDs/preços/efeitos estáveis, compra opcional, uma cópia por item e compatibilidade com um slot; jamais condicionam a campanha básica ou os finais atuais.
8. Toda flag/decisão, item, estado de missão e RNG que influencie resultado deve entrar no save. Novos campos/IDs precisam de migração versionada.
9. Não tratar motivação, neurodivergência ou experiências psicológicas como moralidade, “boa rota” ou condição de valor de personagem. Não inventar fatos de Ray, Luppi, Hori ou das crianças do orfanato.
10. Preservar a diferença entre dados ativos de `Hori Draft` e conteúdo legado/exemplo em `data/events.json`; não sobrescrever nem integrar automaticamente.

## 13. Casos de teste recomendados

**Nenhum caso abaixo foi executado.** São critérios para uma implementação futura, após autorização.

### Campanha e missão

- Semana 7 não apresenta missão; semana 8 apresenta etapa 1; transição semana 8→9 sem conclusão define prazo uma única vez; semana 9 não reabre missão.
- Prazo sem escolhas deixa `attempted=false`, `completed=false`, `success=false`, `failed_by_deadline=true`, `resolved=true`.
- Prazo após uma ou duas etapas marca tentativa, mas não conclusão nem sucesso; a campanha segue até semana 16.
- Etapa 3 com sucesso e com falha produz estados mutuamente exclusivos; efeitos repetidos/duplo clique não concluem nem premiam duas vezes.
- `resolve_ending` dá finais de sucesso somente com sucesso; final independente só quando sua condição de missão está completa; fallback resolve expiração e conclusão sem elegibilidade superior.
- Fronteiras do Pulso: stability 54/55/56 cruzada com TEC 29/30/31; sucesso ocorre apenas no quadrante em que ambos satisfazem. Preview e confirmação não avançam RNG.
- Migração/validação rejeita flags contraditórias, estágio fora de 0–3 ou campanha terminal reaberta.

### Motivação, aptidão e mentoria

- Testar motivação em 0, 33, 34, 66, 67 e 100; confirmar caps, arredondamento e que motivação baixa não bloqueia atividade nem aumenta risco.
- Testar aptidão 0,85, 1,00 e 1,15 em ganho base que mostre a diferença; verificar atividade sem aptidão usa 1,00 e não bloqueia.
- Comparar preview e confirmação de mesmo estado; falha não aplica atributo, mas aplica custos e consome ação conforme regra aprovada.
- Mentoria em vínculo imediatamente abaixo/no limiar, afinidade correspondente/inexistente, risco 0–5 e risco alto; confirmar redução limitada a 5 pontos e nenhum empilhamento.
- Conferir caps e teto proposto de ganho total; motivação, aptidão e mentor são apresentados de forma legível.
- Descanso em motivação 0 e 99 permanece acessível e não passa 100.

### Economia, itens e persistência

- Compra abaixo do preço, saldo exato, saldo insuficiente, item desconhecido, duplicata e compra válida; falha não deve alterar créditos/inventário.
- Equipar, substituir, reequipar o mesmo item e tentar combinar bônus equivalentes; confirmar uma vaga e efeito único.
- Caminho de campanha sem compra alcança as mesmas ações, missão e finais elegíveis.
- Round-trip save/load cobre estado inicial, meio da semana, missão em progresso/expirada, final, saldo, item, histórico e RNG; próximo resultado aleatório coincide no mesmo runtime suportado.
- Save inexistente, JSON truncado, versão desconhecida, campo extra/inválido, ID de conteúdo removido, falha de escrita e backup válido; arquivo original não deve ser silenciosamente apagado.
- Falha simulada entre preparação e commit da transação não deve duplicar crédito, item, evento, efeito de missão ou avanço do RNG.
- Migração pura de cada versão suportada preserva flags/efeitos e não modifica o save original até a nova cópia ser validada.

## 14. Revisão das quatro perspectivas especializadas

Os perfis foram consultados sequencialmente para revisão estática; suas respostas são recomendações, não decisões do autor.

### Game Designer

- Definir o instante exato do prazo e verificar o limite de tempo para as três etapas.
- Manter tentativa, conclusão e prazo como estados distintos para que expiração não habilite incorretamente finais ligados à participação.
- Rever saltos das faixas de motivação e mostrar fatores/ordem de cálculo na prévia.
- Definir seleção/desempate de mentor e deixar claro que redução de risco tem piso zero.
- Garantir recuperação após falha e regras de loja/inventário/preço sem softlock.

### Economy Designer

- Confirmou por aritmética que 1 estágio/semana produz saldo 450 e 2 estágios/semana, no padrão de 2 estágios + 1 descanso por semana, saldo 850.
- Preços-piloto 80/100/120 e custo total 300 são compatíveis com esses dois cenários, mas ainda não demonstram uma curva equilibrada.
- Pendências que afetam preço/utilidade: duração dos itens, efeito, fonte adicional de créditos, regras de equipagem, itens guardados e política de revenda. A proposta deste documento escolhe itens permanentes, sem revenda e um slot, mas aguarda aprovação.

### Godot Gameplay Scripter

- Preservar cópia completa de estado e preview sem mutação/RNG; incluir todos os novos campos em duplicação e persistência.
- Tornar missão, prazo e flags terminais coerentes; resolver o conflito entre `week_max` ignorado e `resolve_ending` exigir tentativa.
- Manter contratos tipados/validados de dados, aplicar compra atomicamente e não inicializar campanha nova sobre save existente.
- Testar fronteiras, round-trip, versão desconhecida, RNG, flags e transações; nenhuma dessas verificações foi executada nesta etapa.

### Narrative Designer

- Falha por prazo deve ser distinta de tentativa e não sugerir negligência, incapacidade ou falha moral de Hori.
- O fallback atual pode soar culpabilizante; criar texto/variante de prazo sem inventar mortes, ferimentos ou fatos canônicos.
- Manter a sociabilidade e o humor de Hori além de cenas de sofrimento; não tratar dificuldade facial ou voz como medidor moral.
- Preservar motivação financeira e vínculos de Ray, inclusive o orfanato/crianças; manter autonomia de Luppi e presença das professoras.
- O unlock OR do Pulso versus condição AND de sucesso precisa de preview claro; não prometer resultado não garantido.

## 15. Riscos e decisões ainda pendentes

| Prioridade | Risco/decisão | Efeito se não decidido | Proposta deste documento |
|---|---|---|---|
| Alta | Instante operacional de “ultrapassar semana 8”. | Prazo pode expirar cedo/tarde ou ser aplicado repetidamente. | Antes de avançar de 8 para 9, uma única vez. |
| Alta | Finais quando a missão expira sem tentativa. | `resolve_ending` retorna vazio ou inventa tentativa. | `final_mission_resolved` terminal habilita o fallback; tentativa permanece falsa se nenhuma escolha for feita. |
| Alta | Condição de disponibilidade do Pulso. | Atual unlock OR pode expor uma escolha cujo sucesso AND ainda é impossível. | Preservar unlock atual com preview explícito, ou exigir AND também para disponibilidade; autor decide. |
| Alta | Schema e política de save. | Perda/duplicação de campanha, recompensas ou sequência RNG. | JSON versionado, snapshots transacionais, validação estrita e backup. |
| Média | Bandas de motivação e tamanho dos bônus. | Saltos em fronteiras; fator pode ser pouco perceptível devido a arredondamento. | 0,90/1,00/1,10 em três bandas, apenas ganhos; requer playtest localizado. |
| Média | Limiar de vínculo/efeito de mentor. | Mentoria pode ser sempre ativa ou exigir grind. | Mentor único genérico, afinidade compatível, vínculo instructor >=30, −5 pp risco; requer aprovação. |
| Média | Preços e efeitos de itens. | Crédito pode permanecer redundante ou item parecer obrigatório. | 80/100/120 como piloto; todos opcionais, efeitos pequenos e locais. |
| Média | Compatibilidade de itens com atividades futuras. | Item de dupla não tem efeito antes da Parte 5. | Não ativar o comunicador até a atividade de dupla ser especificada; alternativa é adiar o item. |
| Média | Texto de finais e rascunhos. | Fim por prazo pode culpabilizar traços/sintomas ou inventar consequências. | Reescrever/condicionar epílogo após aprovação narrativa, preservando IDs de final. |
| Média | Dados ativos versus legado. | Eventos podem ser integrados ao arquivo que não é carregado e quebrar validação estrita. | Decidir composição de conteúdo antes de inserir novos eventos. |
| Baixa | Cap total de 12 pontos e arredondamento. | Novas atividades podem ultrapassar cap ou ocultar bônus de aptidão. | Validar dados pelo pior caso; aprovar fórmula junto com atividades da Parte 5. |

## 16. Ordem recomendada de implementação

Esta ordem é planejamento, **não autorização para implementar**:

1. Aprovar esta especificação e resolver os itens de missão/finais, Pulso e fórmula de treino.
2. Especificar casos de teste de fronteira; implementar estado e prazo de missão com regressões localizadas antes de mexer em narrativa extensa.
3. Implementar e testar fórmula central de motivação/aptidão/mentoria e previews; manter fórmulas num só serviço.
4. Definir catálogo mínimo de itens/preços, inventário/equipamento e compras transacionais; revisar análise econômica.
5. Definir envelope/schema de save e teste round-trip/erros/migração antes de integrar a Parte 5.
6. Integrar eventos/atividades futuras somente após resolver composição do loader e contratos de dados; manter cada subfase pequena.
7. Fazer revisão de continuidade/português brasileiro dos textos e só então produção visual.
8. Executar somente os testes localizados autorizados para cada mudança; executar Godot/testes nunca é pressuposto desta especificação.

## 17. Registro de validação e escopo

- Git inicial verificado: branch `main`, commit `fb7cdba`; `git status --short --untracked-files=all` estava limpo antes da documentação.
- Perfis Game Designer, Economy Designer, Godot Gameplay Scripter e Narrative Designer consultados um por vez, sem paralelismo; foram usados como perspectivas, não como autoridade para aprovar decisões do autor.
- **Execução:** não foi executado teste, comando Godot, simulação, build ou verificação visual. Foram feitas somente consultas Git de leitura para verificar status, branch e último commit, antes e depois da documentação.
- **Arquivos da entrega consolidada:** `docs/11_ESPECIFICACAO_GAME_DESIGN_FASE_4C.md` foi atualizado; `docs/12_DECISOES_GAME_DESIGN_FASE_4C1.md` e `docs/13_ESPECIFICACAO_GAME_DESIGN_FASE_4C2.md` foram criados. Nenhum código, dado, projeto, captura, `.import` ou `.uid` foi alterado.
- **Estado final:** as únicas alterações no worktree são esses três documentos; nenhuma alteração preexistente foi descartada ou revertida.
- **Próximo portão:** revisão do autor dos documentos de decisão 4C.1 e especificação 4C.2 antes de qualquer implementação ou avanço da Parte 5.

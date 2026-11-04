# HERO TRAINER — Decisões de Game Design — Fase 4C.1

**Versão:** 1.0  
**Data:** 2026-11-04  
**Status:** decisões consolidadas pela coordenação, prontas para revisão do autor; implementação não autorizada  
**Escopo:** missão da semana 8, Pulso de Contenção, princípios de treinamento, economia MVP e save/load MVP.

> **Certeza:** requisitos do autor são obrigatórios. As decisões abaixo foram escolhidas após as revisões sequenciais dos quatro perfis e são a baseline de design para detalhamento/implementação, não fatos de cânone. Valores de gameplay podem ser reavaliados após implementação e playtest autorizado.

## 1. Resumo das decisões finais

1. A missão da semana 8 só expira na transição para a semana 9, depois das três ações da semana 8 e da oportunidade de continuar/resolver a missão.
2. Tentativa, conclusão, sucesso e expiração são estados diferentes. Expiração nunca finge que Hori tentou a missão.
3. Pulso fica disponível e tem sucesso somente quando **ambos** os requisitos estão cumpridos: estabilidade `>=55` e TEC `>=30`. A falha em qualquer requisito impede a escolha, e a UI informa o valor atual e o limiar.
4. Motivação influencia ganhos de atributos, mas não consome energia, não eleva o risco e não bloqueia ações. As bandas base são `0–33: ×0,90`, `34–66: ×1,00`, `67–100: ×1,10`.
5. Aptidões alteram somente ganhos de atributo e ficam no intervalo validado `0,85–1,15`; aptidão ausente vale `1,00`.
6. Mentoria é fornecida pelo instrutor existente em atividades compatíveis quando o vínculo com `instructor` é pelo menos 30. Um mentor reduz o risco em 5 pontos percentuais; não há acúmulo.
7. O risco usa a fórmula detalhada na especificação 4C.2. Somente as quatro atividades de treino atuais podem falhar; custos e ação continuam sendo consumidos na falha, sem penalidade adicional.
8. A loja MVP tem três itens permanentes opcionais, uma cópia por ID, um espaço equipado, sem revenda/reembolso; preços base: 80, 120 e 160 créditos. Compra não usa ação; equipamento pode ser trocado antes da primeira ação de cada semana.
9. Créditos não têm teto adicional no MVP. A fonte continua sendo estágio (`+25`); nenhum item é requisito de campanha, missão ou final.
10. Save/load MVP usa um snapshot JSON versionado, um arquivo principal e uma cópia de recuperação, com autosave em cada alteração confirmada. Sem slots múltiplos, telemetria, journal ou sistema de replay.

## 2. Participação dos perfis especializados

Os perfis em `.github/agents/` foram consultados individualmente e sequencialmente. As respostas foram recomendações; as decisões finais são da coordenação e ficam sujeitas à revisão do autor.

### Game Designer

- Recomendou separar prazo, tentativa e conclusão, com fallback para expiração sem tentativa.
- Recomendou que a disponibilidade do Pulso use a mesma conjunção AND do sucesso, evitando opção de sucesso impossível.
- Defendeu motivação apenas nos ganhos, sem bloquear treino ou elevar risco; recuperação confiável via descanso.
- Propôs nova curva de risco focada em energia abaixo de 45 e estresse acima de 20, mentoria como desconto fixo, e feedback explícito.
- Indicou que falhas consecutivas podem desestimular; sem penalidade extra e com descanso sempre disponível.

### Economy Designer

- Observou que estágio é a única fonte atual e não existe gasto no código.
- Calculou que um estágio por semana gera 450 créditos ao final (50 iniciais + 16×25); dois estágios e um descanso por semana geram 850 (50 + 32×25).
- Recomendou itens permanentes de conveniência em vez de bônus genérico de atributo; propôs preços 80/120/160.
- Recomendou sem cap de créditos e sem revenda, preservando a compra opcional.
- Alertou que preços só podem ser reavaliados depois dos efeitos e do uso real da loja serem implementados.

### Godot Gameplay Scripter

- Recomendou que regras permaneçam em serviços separados e `TrainingState` seja a fonte única de estado.
- Destacou que expiração deve acontecer na transição de semana, não em consulta de elegibilidade; preview não pode mutar estado ou RNG.
- Recomendou estado serializado validado, cópia completa em `duplicate_state`/`copy_from`, compra atômica e carregamento que não inicialize uma campanha nova por cima do save.
- Alertou contra assumir atomicidade de substituição de arquivo sem verificar a plataforma e contra salvar objetos de serviço/RNG diretamente.
- Indicou testes de fronteira, estado copiado, RNG, compra, save/load e repetição de transação.

### Narrative Designer

- Recomendou vocabulário de prazo que não culpe Hori e preservação da distinção entre missão não iniciada, tentativa e expiração.
- Defendeu disponibilidade AND do Pulso e feedback dos dois limiares antes da ação.
- Alertou que o texto atual do final fallback pode soar como punição por sofrimento oculto; deve ser revisto sem patologizar.
- Reforçou o cânone de Hori, Ray e Luppi, inclusive a relevância emocional/mecânica do orfanato e das crianças, e a autonomia de Luppi e seu vínculo com as professoras.
- Recomendou que dinheiro não seja extraído do sofrimento das crianças e que mentoria/motivação não sejam medidas morais.

## 3. Divergências e conciliação

| Tema | Recomendações divergentes | Decisão consolidada | Justificativa / alternativa descartada |
|---|---|---|---|
| Pulso: disponibilidade | O draft atual desbloqueia com estabilidade `>=55` **ou** protocolo; narrativa e programação apontaram que isso pode oferecer sucesso impossível sem TEC `>=30`. | Disponível somente com estabilidade `>=55` **e** TEC `>=30`; mesmos limites que definem sucesso. | Clareza e confiança do jogador prevalecem. Protocolo de equipe pode manter efeito narrativo, mas não substitui atributo. Descartada disponibilidade OR com falha previsível. |
| `attempted` | Parte do código marca tentativa ao final; uma recomendação técnica sugeriu marcar apenas no último estágio. | Marcar tentativa na primeira escolha de missão confirmada. Conclusão só na etapa 3. | A palavra “tentativa” cobre o início de uma operação; `completed` registra encerramento. Descartado marcar tentativa fictícia por prazo ou ignorar que o jogador começou. |
| Falha por prazo e finais | O fallback atual exige tentativa; expiração sem tentativa não alcançaria final. | `resolved` habilita o fallback; finais de sucesso exigem sucesso e final independente exige missão concluída. | Mantém encerramento sem forçar uma escolha falsa. Descartado conceder final de missão tentada a quem não iniciou. |
| Risco de treino | A fórmula atual usa energia abaixo de 35 e estresse inteiro; o Game Designer propôs outra curva com limiares explícitos e teto menor. | Adotar na 4C.2 `round(max(0,45-energy)×0,7 + max(0,stress-20)×0,3)`, clamp 0–55%, menos 5 pp com mentor elegível. | Curva simples de entender: fadiga só eleva risco abaixo de 45 energia ou acima de 20 estresse. Valores podem ser ajustados após testes autorizados. Descartado somar motivação/aptidão ao risco para não criar punição em cascata. |
| Equipamentos | Uma proposta anterior dava `+1` atributo; Economia recomendou utilidade e recuperação em vez de inflação de atributo. | Três itens de conveniência: custo energético de treino, recuperação de descanso e estresse de treino; sem bônus direto de atributo. | Benefícios perceptíveis, não contornam limiares da missão e evitam crescer atributos por fora do preview. Descartado bônus genérico `+1`. |
| Preços | Proposta anterior 80/100/120; Economia propôs 80/120/160. | Baseline 80/120/160. | O pacote de 360 deixa 90 no padrão de 1 estágio/semana e 490 no padrão de 2 estágios + 1 descanso/semana. Alternativa 80/100/120 foi substituída como referência menos conservadora para uma loja pequena. |
| Save | Proposta anterior incluía histórico transacional longo, migrações e rotina de gravação/verificação detalhada. Godot recomendou validação, cópia anterior e cautela com atomicidade. | Um slot/snapshot JSON, versão, cópia `.bak`, temporário verificado e autosave; sem log de todas as ações. | Complexidade proporcional ao jogo single-player. Flags/estado já são autoritativos; duplicação de transações será evitada por confirmação no estado candidato, bloqueio de UI durante confirmação e operações idempotentes como compra única. |
| Equipar e trocar | Propostas anteriores deixavam troca livre a qualquer momento. | Troca permitida antes da primeira ação da semana, sem consumir ação; depois fica bloqueada até a semana seguinte. Compra não consome ação. | Dá significado ao slot único sem criar custo invisível nem troca estratégica após ver o resultado da ação. |

## 4. Decisões operacionais

### 4.1 Missão da semana 8

- **Estados:** `locked` (antes da semana 8), `available` (sem escolha confirmada), `in_progress` (ao menos uma escolha), `completed_success`, `completed_failure` e `failed_by_deadline`.
- `attempted` é verdadeiro depois da primeira escolha válida; `completed` somente depois da etapa 3; `success` somente se a etapa 3 for sucesso; `failed_by_deadline` somente na transição para semana 9 sem conclusão; `resolved` fica verdadeiro em ambos os resultados terminais.
- Enquanto não estiver resolvida, a missão pode ser adiada sem consumir ação. A UI volta a oferecê-la após a próxima mudança de estado. Eventos elegíveis da semana 8 são resolvidos antes de avançar o calendário.
- O botão de avanço da semana 8 exige as três ações consumidas e não pode fechar enquanto houver evento em andamento. Se missão não resolvida, apresentar aviso de que avançar para semana 9 a encerra por prazo. Confirmar o avanço aplica a expiração uma única vez.
- Ao expirar, `attempted` permanece com o valor real; `completed=false`, `success=false`, `failed_by_deadline=true`, `resolved=true`. Estado não pode reabrir a missão.
- O fallback de campanha fica elegível por `resolved`, não por tentativa. Finais de sucesso permanecem condicionados a `success`; final independente exige missão concluída. Nenhum final atribui tentativa à expiração.
- A prosa do fallback atual deve ser revista antes de integração para que prazo seja circunstância da campanha, não defeito moral, neurodivergência ou sofrimento de Hori.

### 4.2 Pulso de Contenção

- **Disponibilidade e sucesso:** estabilidade do núcleo `>=55` **e** TEC `>=30`.
- Limites são lidos no instante da escolha; igualdade satisfaz o requisito.
- Se qualquer requisito faltar, a opção não é oferecida; a interface informa qual limiar não foi alcançado e os valores atual/necessário.
- O protocolo de equipe deixa de ser desbloqueador alternativo do Pulso; pode continuar como contexto/flag narrativa, sem mudar os dois limiares.
- Resultado não usa RNG nem alterará a sequência de treino.

### 4.3 Treinamento: contratos de 4C.1

- Ganhos de atributo usam base × aptidão da atividade × fator de motivação; cada atributo é arredondado uma vez, depois limitado pelo cap 100.
- Ganho máximo total por ação: 12 pontos, validado no catálogo. Falha não concede ganhos de atributo; continua pagando custos de atividade e consumindo uma ação.
- Aptidão é de `0,85–1,15`; ausência equivale a `1,00`. Aptidão modifica ganho, não risco/custo/acesso.
- Motivação é 0–100; faixas e recuperação estão fixadas acima. Motivação baixa não bloqueia e não aumenta risco.
- Um único instrutor genérico existente é aplicável quando vínculo `instructor >=30` e a atividade declara afinidade compatível. A mentoria reduz 5 pontos percentuais de risco, sem acumular com outra mentoria.
- Nenhum sistema de lesão é adicionado neste ciclo. Mentoria e equipamento não alteram o Pulso nem qualquer limiar narrativo.
- Os detalhes completos e exemplos ficam em [`13_ESPECIFICACAO_GAME_DESIGN_FASE_4C2.md`](./13_ESPECIFICACAO_GAME_DESIGN_FASE_4C2.md).

### 4.4 Economia e equipamentos MVP

| Item permanente | Preço | Efeito quando equipado |
|---|---:|---|
| Caderno de treino | 80 créditos | Reduz em 2 o custo de energia das quatro atividades de treino; custo mínimo 8. |
| Kit de recuperação | 120 créditos | Descanso recupera +5 energia além dos +25 atuais; cap continua 100. |
| Auxílio de foco | 160 créditos | Reduz em 1 o aumento de estresse das quatro atividades de treino; delta mínimo 0. |

- Uma cópia de cada item por campanha; sem revenda ou reembolso.
- Um slot ativo. Pode-se trocar antes da primeira ação da semana sem consumir ação; a escolha fica fixa após a primeira ação.
- Loja, compra e equipagem são opcionais e não alteram os requisitos de Pulso, finais ou missão.
- Compra verifica ID, saldo, duplicata e validade antes de debitar/adicionar; operação inválida não altera nenhum campo.
- Estágio mantém o ganho de +25 créditos. Sem cap adicional de créditos no MVP; campanha finita e compras opcionais são sinks suficientes para a primeira versão.
- Projeção estática: um estágio por semana dá 450 créditos ao final; comprar os três (360) deixa 90. Dois estágios + um descanso por semana dão 850 e deixam 490 após todos os itens. Não é uma simulação nem previsão de uso.

### 4.5 Save/load MVP

- Um único arquivo `user://hero_trainer_save.json`, JSON com `save_schema_version: 1`, `campaign_id`, `content_version`, `engine_version` (Godot 4.5.1 no projeto atual) e snapshot do estado.
- Salvar campanha/semana/ações, atributos, eixos, estado de rota/flags, recursos, vínculos, estágio e resultado da missão, final, RNG (`seed` e `state`), créditos, itens possuídos e item equipado.
- Autosave depois de atividade, escolha narrativa/missão, transição semanal, compra, equipagem e resolução de final. Preview não salva.
- Primeiro calcular mudança em cópia candidata do `TrainingState`; validar e gravar/validar o snapshot; só então publicar o novo estado no painel.
- Manter um `.bak` do último save válido e um temporário de gravação. Se falhar gravação/verificação/troca, preservar a cópia anterior e informar erro. A plataforma-alvo deve validar a estratégia de substituição antes de afirmar atomicidade.
- Load valida versão, tipos, limites, IDs e invariantes. Save inexistente oferece campanha nova; save incompatível/corrompido não é sobrescrito; tentar recuperar backup com mensagem clara.
- `engine_version` é informativo e orienta compatibilidade do RNG. Só carregar automaticamente versões de engine declaradas suportadas; em versão não suportada, preservar o save, avisar e não reseedar nem sobrescrever silenciosamente.
- MVP tem autosave e retomada, sem slots múltiplos nem diário completo de ações. Flags, estado e RNG bastam às regras atuais; só adicionar histórico de escolhas se conteúdo futuro depender dele.

## 5. Pontos aprofundados na Fase 4C.2

A 4C.2 registra a especificação detalhada do sistema de treinamento e desenvolvimento: fórmula de risco atualizada, cálculo único de preview/aplicação, arredondamento, exemplos de ganho/riscos, efeitos de equipamento, recuperação, critérios de aceitação e compatibilidade com os serviços. Não haverá implementação nessa etapa.

## 6. Impactos esperados e riscos conhecidos

- `TrainingState` receberá campos/flags de missão, inventário/equipamento e save quando houver implementação. Novos campos precisam ser incluídos em `duplicate_state()` e `copy_from()`.
- `NarrativeService` precisará aplicar expiração na transição 8→9, separar elegibilidade de mutação de estado e rever condição de fallback.
- O Dashboard precisará permitir adiar a missão, confirmar o avanço que encerra o prazo e oferecer feedback de estado; não pode decidir as regras por callback de UI.
- `TrainingService` precisará compartilhar o mesmo cálculo de preview/resultado, aplicar aptidão/motivação/mentor/equipamento e manter rejeições atômicas.
- Conteúdo JSON tem allowlists estritas; ajustes de dados e validadores precisam ocorrer juntos. O serviço atual exige 8 eventos, 1 missão e 4 finais; a fonte ativa é `Hori Draft`.
- O Pulso será menos surpreendente, mas a opção aparece menos frequentemente que no draft atual. O jogador recebe requisitos e feedback antes da escolha.
- Motivação em bandas tem descontinuidades nas fronteiras. Aptidões podem não mudar um ganho após arredondamento em casos pequenos.
- Itens podem ser considerados de baixo valor se os custos de ação e caps tornarem seus efeitos raros; preços devem ser revisados depois de teste localizado autorizado.
- O autosave pode falhar por permissões/espaço; UI precisa preservar estado anterior e informar que a ação não foi confirmada.
- Erros de escrita/troca de arquivo, saves mais novos e RNG entre versões Godot exigem teste por plataforma; não se presume compatibilidade entre versões de engine.
- A expiração pode influenciar narrativa entre semana 9 e o final da semana 16. Eventos futuros devem checar `failed_by_deadline` explicitamente, sem transformar expiração em tentativa.

## 7. Critérios para concluir a 4C.1

- [x] Requisitos imutáveis do autor identificados.
- [x] Código/dados existentes classificados como implementados, parciais, documentados ou ausentes.
- [x] Quatro perspectivas consultadas individualmente e em sequência.
- [x] Divergências entre as recomendações registradas e resolvidas com justificativa.
- [x] Valores numéricos de baseline e contratos de missão/economia/save registrados.
- [x] Dependências arquiteturais e riscos da Parte 5 identificados.
- [x] Nenhuma implementação, teste runtime ou simulação executada.
- [ ] Revisão/aceite do autor — necessário antes de implementar qualquer sistema.

## 8. Verificações desta etapa

- Git inicial: branch `main`, commit `fb7cdba`; `git status --short --untracked-files=all` estava limpo.
- Documentação e código foram inspecionados estaticamente; respostas dos quatro perfis foram lidas sequencialmente.
- Não foram executados Godot, Play, testes, runner, simulação, build ou benchmark. Diante do histórico de reinicializações e BSOD, não foi iniciada execução de runtime.
- A verificação final de Git e dos arquivos documentais deve ser registrada no relatório da tarefa. Não foi descartada nem revertida qualquer alteração.

## 9. Alternativas importantes descartadas

- Abrir o Pulso com OR e revelar um requisito de sucesso impossível apenas depois da tentativa.
- Marcar expiração como tentativa para reutilizar o fallback atual.
- Aplicar motivação ao risco ou impedir treinos em motivação baixa.
- Dar bônus genérico de atributo aos equipamentos, que poderia contornar cap/preview e aumentar inflação.
- Permitir revenda/refund ou múltiplos slots no MVP.
- Requerer um log/journal completo, múltiplos slots de save, telemetria ou sistema de replay antes de existir necessidade funcional.
- Resolver prazo, fórmula e compra dentro do Dashboard, duplicando regra de serviço.

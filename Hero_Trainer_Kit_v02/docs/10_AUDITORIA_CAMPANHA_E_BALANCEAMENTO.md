# Auditoria estática da campanha e do balanceamento — Fase 4B

## Escopo e método

Esta auditoria examina estaticamente a implementação atual da campanha jogável de Hori. A referência para comportamento é o código e os dados atuais, não propostas antigas. Não foram executados Godot, testes, scripts auxiliares ou simulações. Portanto, este documento não declara resultados de execução.

Os valores de atributos e recursos em `characters.json` são dados de protótipo, explicitamente não canônicos. Os eventos, a missão e os finais examinados abaixo permanecem identificados como rascunhos narrativos; sua integração no serviço não os transforma em cânone.

## Arquivos examinados

- [`scripts/training_state.gd`](../../scripts/training_state.gd): estado de campanha, limites estáticos, cópia e duplicação.
- [`scripts/training_service.gd`](../../scripts/training_service.gd): carregamento, validação, prévia, aplicação de atividades, falha e avanço semanal.
- [`scripts/narrative_service.gd`](../../scripts/narrative_service.gd): elegibilidade e aplicação de eventos, missão, efeitos e finais.
- [`scripts/training_dashboard.gd`](../../scripts/training_dashboard.gd): criação inicial do estado, fluxo narrativo, conclusão semanal e encerramento.
- [`Hero_Trainer_Kit_v02/data/activities.json`](../data/activities.json): calendário, limites, fórmula e oito atividades.
- [`Hero_Trainer_Kit_v02/data/characters.json`](../data/characters.json): valores iniciais e notas de protótipo.
- [`Hero_Trainer_Kit_v02/Hori Draft/events_hori_draft.json`](../Hori%20Draft/events_hori_draft.json): oito eventos e escolhas.
- [`Hero_Trainer_Kit_v02/Hori Draft/missions_hori_draft.json`](../Hori%20Draft/missions_hori_draft.json): missão em três etapas.
- [`Hero_Trainer_Kit_v02/Hori Draft/endings_hori_draft.json`](../Hori%20Draft/endings_hori_draft.json): quatro finais e prioridades.
- [`Hero_Trainer_Kit_v02/docs/07_CICLO_JOGAVEL.md`](./07_CICLO_JOGAVEL.md): descrição existente do protótipo e suas regras.

## Campanha e ciclo de estado

### Confirmado no código e nos dados

- A campanha tem 16 semanas e três blocos por semana: 48 blocos no total se cada semana for concluída (`activities.json`, linhas 3–7).
- Uma atividade válida consome exatamente um bloco. Prévia, cancelamento e atividade inválida não aplicam o estado calculado; apenas `apply_activity` confirma a atividade (`training_service.gd`, linhas 425–588).
- `advance_week` só avança quando `actions_remaining == 0`, não ultrapassa a semana total e repõe três blocos. Não recupera energia nem ajusta os demais recursos (`training_service.gd`, linhas 587–602).
- A atividade valida energia suficiente antes de aplicar. O serviço rejeita atividades que custariam mais energia que a disponível, sem consumir o bloco. Descanso e atividades relacionais não têm custo energético e permanecem opções quando a energia é zero.
- A semana final não pode ser avançada. Depois da última ação da semana 16, o fluxo narrativo procura eventos, missão pendente e, então, um final (`training_dashboard.gd`, linhas 3624–3636).
- O painel cria um novo estado inicial em `_ready`; `TrainingState` fornece `duplicate_state` e `copy_from` para preservar/copiar estado em memória. Nos scripts de campanha examinados não foi encontrado mecanismo de gravação/carregamento em arquivo. Assim, há persistência durante a sessão e a navegação do painel, mas não há persistência em disco identificada nesta implementação (`training_dashboard.gd`, linhas 185–210; `training_state.gd`, linhas 55–101).

### Bloqueio de progresso

Não foi encontrado bloqueio por falta de energia: descanso custa zero energia e recupera energia; as duas atividades de vínculo também custam zero energia. O jogador ainda precisa gastar blocos para concluir uma semana, mas há ações disponíveis mesmo com energia zero. A missão também não consome blocos e cada etapa tem falha recuperável.

## Estado inicial, atributos e limites

Os valores iniciais de Hori vêm de `characters.json`: POT 30, RES 34, TEC 28, TEO 38, SIN 40; energia 75, estresse 12, motivação 65, créditos 50 e reputação 20. Os vínculos iniciais são Luppi 25, Ray 30 e instrutor 30. O estado também começa com estabilidade do núcleo 65, pressão da voz 20 e rede de confiança 30.

Limites carregados/validados pelo serviço:

- Atributos, energia, estresse e motivação: 0–100.
- Reputação e vínculos: 0–100.
- Eixos narrativos: −100 a 100.
- Campos numéricos de `route_state`: limites declarados em `training_state.gd`; identificação auxiliar vai de 0 a 2.
- Créditos: inteiro não negativo, sem teto de jogo.

Ganhos de atributos das atividades ocorrem somente em sucesso; recursos e custo do bloco continuam sendo aplicados em falha. Os efeitos são limitados pelos caps. Valores e estatísticas iniciais do arquivo são declarados como propostas do protótipo, não cânone.

## Oito atividades

Todos os números abaixo vêm de `activities.json`, linhas 11–18. “Delta de atributo” é o ganho nominal em caso de sucesso; ele pode ser menor perto do cap ou ser zeroado pela falha.

| Atividade | Custo de energia | Ganho nominal de atributo | Outros efeitos | Risco |
|---|---:|---|---|---|
| Treinamento de combate | 15 | POT +5, TEC +2 | Estresse +6 | Pode falhar |
| Estudo no laboratório | 10 | TEO +5, SIN +2 | Estresse +4 | Pode falhar |
| Controle de energia | 13 | SIN +5, TEC +2 | Estresse +5 | Pode falhar |
| Condicionamento físico | 13 | RES +5, POT +1 | Estresse +3 | Pode falhar |
| Descanso e lazer | 0 | — | Energia +25, estresse −12, motivação +8 | Determinístico |
| Estágio de apoio | 8 | — | Créditos +25, reputação +1, estresse +4 | Determinístico |
| Conversa com Ray | 0 | — | Vínculo Ray +8, estresse −4 | Determinístico |
| Tempo com Luppi | 0 | — | Vínculo Luppi +8, estresse −4 | Determinístico |

Não há custo de créditos em nenhuma destas atividades. Na rota narrativa atual, os efeitos financeiros encontrados também não gastam créditos. O estágio é, portanto, uma fonte repetível sem destino de gasto definido no escopo examinado.

## Fórmula de falha e cálculos verificáveis

A fórmula declarada e implementada é:

```text
clamp(0, 60, round(max(0, 35 - energia) * 0,9
                   + estresse * 0,2
                   + nível_de_lesão * 12
                   - bônus_de_mentoria))
```

O serviço arredonda para inteiro e limita a 0–60%. Usa energia e estresse antes da atividade. Só as quatro atividades de treinamento podem falhar. Em falha, os ganhos de atributos são omitidos, mas os custos/deltas de recursos e o bloco são aplicados. A prévia não sorteia; uma atividade arriscada confirmada usa o RNG mantido no estado (`training_service.gd`, linhas 545–585).

Na implementação atual, `PLACEHOLDER_INJURY_LEVEL` e `PLACEHOLDER_MENTOR_BONUS` são ambos zero. Embora `injury_level` exista nos dados iniciais e seja validado, não há campo correspondente no estado de campanha nem aplicação de lesão/mentoria pelo cálculo atual.

Exemplos manuais:

- Estado inicial: energia 75, estresse 12 → `round(0 + 2,4) = 2%`.
- Energia 10 e estresse 100, cenário extremo que ainda permite laboratório: `round(25 × 0,9 + 20) = round(42,5) = 43%`.
- O máximo teórico para combate válido é 20% (energia mínima 15, estresse 100); para controle/condicionamento é 40% (energia mínima 13, estresse 100). Assim, o teto declarado de 60% não é alcançável por uma atividade válida com os placeholders atuais.
- Com energia de pelo menos 35 e estresse zero, o risco calculado é 0%.

## Recursos, progressão e relações

### Energia, estresse e motivação

- A energia é persistente entre semanas e não se regenera ao avançar o calendário. Descanso é a única atividade que a recupera; como não custa energia, evita softlock.
- Treinos aumentam o estresse em 3–6; estágio aumenta em 4; descanso reduz em 12 e cada atividade relacional reduz em 4. Caps evitam ultrapassar 100 ou cair abaixo de zero.
- Motivação é chamada `mood` nos JSONs e mapeada para `TrainingState.motivation`. No conjunto atual, descanso é a fonte de motivação (+8) e há escolhas narrativas com ganhos pontuais. Não foi encontrado requisito de atividade, missão ou final que consulte motivação, nem efeito negativo de atividade sobre ela.

### Créditos e reputação

- Créditos começam em 50 e não têm teto de gameplay. O estágio concede +25 por ação, sem custo monetário. Não há uso de créditos nas oito atividades ou nos efeitos narrativos examinados.
- Reputação começa em 20 e tem cap 100. O estágio concede +1. Eventos podem conceder ou retirar reputação; a missão também pode modificá-la. Requisitos de missão usam patamares 15 e 20; o final de carreira exige 35.
- Reputação não bloqueia a missão inteira: opções abaixo do requisito ainda estão disponíveis e produzem falha recuperável, em vez de serem removidas.

### Vínculos

- Ray começa em 30 e Luppi em 25, com cap 100. As atividades sociais concedem +8 por bloco sem custo de energia e reduzem estresse em 4.
- O final de equipe requer ambos os vínculos em 45. A partir do estado inicial, isso requer nominalmente mais 15 pontos com Ray e 20 com Luppi; as atividades de vínculo podem cobrir esses deltas em duas e três confirmações, respectivamente, antes de considerar ganhos de eventos e caps.
- Não há vínculo com instrutor como atividade repetível; ele só muda em escolhas narrativas específicas. Isso não impede os finais atuais, cujas condições usam Ray e Luppi.

### Atributos e valor relativo das atividades

Os deltas são todos positivos e não há perda de atributos em falha; a diferença entre falha e sucesso é deixar de receber o ganho. A escolha de atividade depende da prioridade do jogador e dos requisitos narrativos:

- Laboratório dá nominalmente 7 pontos de atributos por 10 de energia; combate dá 7 por 15; controle dá 7 por 13; condicionamento dá 6 por 13 e aumenta menos estresse (3). Essa comparação é apenas aritmética dos deltas; não prova dominância, pois atributos servem a requisitos distintos e treinos têm risco.
- Os atributos POT e RES são exigidos pelo final de carreira; TEC é usado na resolução do Pulso; outros atributos não aparecem nas condições dos quatro finais examinados. TEO, SIN e os eixos ainda podem ter valor por escolhas/eventos e outros sistemas fora desses critérios.
- `characters.json` contém aptidões por atividade e `activities.json` contém `mentor_affinity`, mas `TrainingService` não consulta nenhum dos dois para modificar ganho, custo ou probabilidade. As aptidões atuais não alteram mecanicamente o treino da rota de Hori.

## Eventos, missão e finais

### Eventos

Há oito eventos não repetíveis por flags, em janelas semanais: semanas 1–2, 3–4, 5, 6–7, 9–10, 11–12, 12–13 e 14–15. O serviço filtra por janela e gatilho e escolhe o evento elegível de maior prioridade (`narrative_service.gd`, linhas 165–184). A ordem de prioridade de maior destaque é protocolo do núcleo (90) e confronto com a voz (95).

O evento da semana 11–12 requer pressão da voz ≥25 ou semana ≥12. Assim, se o primeiro gatilho não tiver sido alcançado, a condição de semana força sua elegibilidade na semana 12. O evento tem flag de visto e não se repete após uma escolha aplicada. As escolhas alteram combinações de atributos, recursos, vínculos, eixos, estado de rota e flags; não consomem ações nem treinamento RNG.

O fluxo do painel consulta eventos antes da missão e do final. Na operação normal do painel, o fluxo abre conteúdo elegível após atividade/avanço de semana. Eventos que não forem tratados dentro da janela não são selecionados pelo serviço depois que a semana máxima passou; essa observação é sobre a regra de elegibilidade, não uma reprodução de um caminho de navegação.

### Missão

A missão tem três etapas e janela declarada na semana 8. Cada escolha é avaliada deterministicamente: requisitos atendidos selecionam `effects_success`; caso contrário, são aplicados `effects_failure_recoverable`. A falha não é RNG nem bloqueio irrecuperável. O Pulso de Contenção é a única escolha de missão cuja disponibilidade é condicionada por desbloqueio.

Há caminhos de sucesso compatíveis com o estado inicial: por exemplo, POT inicial 30 satisfaz o requisito de avançar rápido; estabilidade inicial 65 satisfaz estabilizar com o núcleo; e RES 34 / rede confiável 30 satisfazem, respectivamente, retirada coberta / saída limpa. Isso confirma possibilidade estática nos requisitos, não uma execução de campanha.

O Pulso é desbloqueado quando estabilidade do núcleo ≥55 **ou** a flag de protocolo em equipe está definida. Seu resultado, porém, é sucesso apenas com estabilidade ≥55 **e** TEC ≥30; caso contrário, falha recuperável. A implementação não usa sorteio ou probabilidade variável para essa escolha.

### Finais

O serviço seleciona o final elegível de maior prioridade. Condições:

1. `hori_team_guardian` (50): solidariedade ≥15, vínculos com Luppi e Ray ≥45, missão final bem-sucedida.
2. `hori_guardian_command` (40): POT ≥55, RES ≥50, reputação ≥35, missão final bem-sucedida.
3. `hori_independent` (30): autonomia ≥15 e missão tentada.
4. `hori_overburdened` (10): missão tentada.

O final de equipe sobrepõe o final de carreira quando ambos são elegíveis, conforme prioridade maior. O fallback cobre qualquer tentativa da missão. A terceira etapa marca a missão como tentada tanto no sucesso como na falha recuperável, logo há uma condição de final após a conclusão dessa etapa.

## Diagnóstico e prioridades

Não foi identificado problema crítico nem bloqueio inevitável de campanha na análise estática. As observações abaixo não alteram dados nem propõem implementação nesta fase.

### Médio — o limite superior da janela da missão não é aplicado

1. **Local:** `scripts/narrative_service.gd`, linhas 220–228; janela em `Hori Draft/missions_hori_draft.json`, linha 9.
2. **Comportamento atual:** `is_mission_due` verifica `state.week >= week_min`, mas não compara com `week_max`, embora o JSON declare semana 8 como início e fim.
3. **Esperado documentado:** missão abre na janela declarada.
4. **Consequência:** caso o estado chegue a uma semana posterior sem processar a missão, o serviço continua considerando-a devida. O fluxo padrão do painel tenta apresentá-la assim que fica elegível, então não há evidência estática de que isso ocorra na navegação normal; é uma divergência real da regra de janela e risco de continuidade.
5. **Possível solução para avaliação futura:** respeitar o fim da janela ou definir explicitamente uma política de missão atrasada.
6. **Risco de regressão:** impedir que a missão ainda possa ser resolvida quando atrasada poderia deixar a campanha sem `final_mission_attempted` e, por consequência, sem final. Qualquer ajuste precisa conciliar calendário e garantia de encerramento.

### Médio — o Pulso é descrito como arriscado, mas resolvido por limiares determinísticos

1. **Local:** `Hori Draft/missions_hori_draft.json`, linhas 11–22 e 128–140; `scripts/narrative_service.gd`, linhas 341–355.
2. **Comportamento atual:** sucesso exige simultaneamente estabilidade ≥55 e TEC ≥30; o restante é falha recuperável. Não há sorteio.
3. **Esperado documentado:** o campo `effect` chama a habilidade de “Alto risco / alto ganho”, e `success_chance_note` sugere chance determinada pelo motor.
4. **Consequência:** a expectativa narrativa de risco probabilístico não corresponde à regra determinística. A decisão pode parecer previsível ou a explicação de risco pode ser enganosa.
5. **Possível solução para avaliação futura:** decidir se o desenho aprovado é limiar determinístico ou risco probabilístico e alinhar a descrição a essa decisão.
6. **Risco de regressão:** introduzir RNG mudaria a regra aprovada/documentada no ciclo jogável e tornaria os resultados dependentes da seed.

### Médio — créditos não têm destino de gasto

1. **Local:** `Hero_Trainer_Kit_v02/data/activities.json`, linha 16; `scripts/training_service.gd`, linhas 490–531.
2. **Comportamento atual:** estágio gera 25 créditos por ação; o serviço só impede saldo negativo, e nenhuma atividade/efeito narrativo examinado gasta créditos.
3. **Esperado documentado:** o JSON chama os dados de demonstração e não define custo monetário real; não há sink exigido nesta fase.
4. **Consequência:** créditos acumulam sem abrir escolhas ou progressão no escopo atual. A atividade funciona como fonte sem propósito mecânico conectado.
5. **Possível solução para avaliação futura:** decidir se créditos devem permanecer apenas cosméticos/de demonstração ou se terão sink em fase posterior.
6. **Risco de regressão:** introduzir gastos agora alteraria economia, dados de jogo e escopo; não é uma correção automática recomendada.

### Médio — estado da campanha não é salvo em disco

1. **Local:** `scripts/training_dashboard.gd`, linhas 185–210; `scripts/training_state.gd`, linhas 55–101.
2. **Comportamento atual:** `_ready` cria um estado inicial novo. O estado é duplicado/copiado em memória, sem serialização persistente nos scripts examinados.
3. **Esperado documentado:** o ciclo jogável descreve estado e RNG compatíveis com continuidade futura após serialização, não uma função de salvar já implementada.
4. **Consequência:** reiniciar a cena/processo não tem mecanismo identificado para retomar a campanha anterior.
5. **Possível solução para avaliação futura:** esclarecer se salvamento em disco faz parte do MVP; se sim, especificar formato e ciclo de vida separadamente.
6. **Risco de regressão:** persistir dados requer validação de versões e compatibilidade do RNG/flags; não deve ser inferido nesta auditoria.

### Baixo — motivação não participa de requisitos ou risco

1. **Local:** `activities.json`, linha 15; `TrainingService` mapeia `mood` para motivação (`training_service.gd`, linhas 8–14 e 296–308).
2. **Comportamento atual:** descanso aumenta motivação; algumas escolhas narrativas também podem aumentá-la. Nenhuma regra de atividade, missão ou final examinada consulta esse recurso.
3. **Consequência:** é um indicador sem efeito mecânico observado no ciclo atual.
4. **Possível solução para avaliação futura:** manter como indicador de apresentação ou definir seu propósito antes de atribuir consequências.
5. **Risco de regressão:** dar efeito a motivação mudaria a dificuldade e os resultados de gameplay.

### Baixo — aptidões e afinidades de mentoria não afetam treinamento

1. **Local:** `characters.json`, linhas 32–37; `activities.json`, linhas 11–14; `training_service.gd`, linhas 545–550 e 715–756.
2. **Comportamento atual:** aptidões iniciais e `mentor_affinity` são carregados/validados como dados, mas não entram nos deltas nem na fórmula de falha; o bônus de mentoria é constante zero.
3. **Consequência:** os valores configurados não diferenciam as atividades mecanicamente nesta implementação.
4. **Possível solução para avaliação futura:** esclarecer se são apenas metadados para uso futuro ou regras planejadas.
5. **Risco de regressão:** aplicar multiplicadores alteraria todos os ganhos/probabilidades e precisa de rebalanceamento.

## Recomendações e decisões pendentes

1. Decidir se o limite `week_max` da missão é uma janela rígida ou se a missão deve continuar disponível como conteúdo atrasado.
2. Confirmar se o Pulso é um teste determinístico por limiar ou deveria ter risco probabilístico; alinhar a redação de design à regra aprovada.
3. Definir o papel de créditos, motivação, aptidões e afinidades de mentoria no MVP, sem inferir mecânicas ausentes.
4. Decidir se salvamento em disco é requisito do MVP ou etapa futura.
5. Se o equilíbrio quantitativo precisar de validação estatística, planejar playtest manual autorizado em etapa futura; nenhum resultado estatístico é afirmado aqui.

## Limitações desta auditoria

- Não houve execução, teste, benchmark, renderização nem simulação.
- As comparações de eficiência são aritméticas nominais; não atribuem pesos subjetivos aos atributos.
- A possibilidade de alcançar os requisitos narrativos foi avaliada por comparação estática entre valores iniciais e condições/deltas, não por uma campanha executada.
- Conteúdo de Hori Draft continua sendo rascunho e valores de personagens continuam sendo dados de protótipo.
- Nenhuma correção de código, dado, configuração ou cânone foi realizada.

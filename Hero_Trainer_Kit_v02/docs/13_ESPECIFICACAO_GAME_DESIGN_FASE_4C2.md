# HERO TRAINER — Sistema de Treinamento e Desenvolvimento — Fase 4C.2

**Versão:** proposta operacional 1.0  
**Data:** 2026-11-04  
**Status:** especificação pronta para revisão; implementação não autorizada  
**Dependência:** decisões de baseline em [`12_DECISOES_GAME_DESIGN_FASE_4C1.md`](./12_DECISOES_GAME_DESIGN_FASE_4C1.md)  
**Método:** análise estática e cálculos manuais. Nenhum Godot, teste, campanha simulada ou build foi executado.

> **Certeza:** regras de calendário, limites e atividades descritas como atuais vêm do código/dados inspecionados. As novas fórmulas e números deste documento são decisões de design para a futura implementação e ajuste após testes localizados autorizados; não são cânone nem resultados de playtest.

## 1. Objetivo e escopo

Especificar como estado do personagem, aptidões, motivação, mentoria, energia e estresse afetam atividades. Preservar as oito atividades atuais e o ciclo de 16 semanas × 3 ações. Não adicionar lesões, árvores de especialização, novos personagens mentores ou atividades nesta fase.

### Fora de escopo

- Implementação GDScript, alterações no JSON, cenas ou interface.
- Redesign de atributos ou da duração da campanha.
- Novo conteúdo narrativo, personagem canônico ou diálogo.
- Habilidades especiais de missão, incluindo alteração dos limites do Pulso.
- Simulação integral de campanha, balanceamento por Monte Carlo ou teste de estresse.

## 2. Contrato atual e lacunas

| Superfície | Estado confirmado | Implicação para 4C.2 |
|---|---|---|
| `TrainingState` | Guarda semana, ações, atributos, eixos, estado de rota, flags, missão, recursos, vínculos e RNG. `duplicate_state()` e `copy_from()` copiam esses campos. | Preview e resultado candidato devem operar em cópia; todo campo novo persistente exige cópia e save/load futuros. |
| `TrainingService` | Carrega dados de Hori e atividades. Valida uma allowlist. Preview não avança RNG. Aplicação consome uma ação válida. | Um cálculo compartilhado deve servir para preview e aplicação; não duplicar fórmulas na UI. |
| Atividades | Quatro treinos têm atributos positivos, custo de energia e `can_fail=true`; descanso, estágio e sociais são determinísticos. | Só os quatro treinos atuais recebem risco e modificadores de treino. |
| Ganho de atributos | Atualmente o ganho JSON nominal é aplicado somente em sucesso; os caps limitam resultado. | Aptidão/motivação serão aplicadas ao ganho de treino antes do cap. |
| Motivação | `TrainingState.motivation` mapeia o JSON `mood`; começa em 65 para Hori. Descanso concede +8 e eventos podem alterar o recurso. Não afeta fórmula atual. | Tornar o recurso mecanicamente útil sem convertê-lo em custo, bloqueio ou risco. |
| Aptidões | `characters.json` contém fatores por tipo, mas o serviço não os aplica. Hori: combat 1,10; lab 0,95; control 1,00; conditioning 1,05. | Interpretar o fator por ID de atividade. Valores de personagens continuam dados de protótipo. |
| Mentoria | `mentor_affinity` existe nos quatro treinos; vínculo `instructor` começa em 30. O bônus de código é placeholder zero; seleção não está implementada. | MVP usa o instrutor existente, com limiar e afinidade explícitos, sem adicionar pessoa canônica. |
| Falha | Fórmula atual usa energia, estresse e placeholders de lesão/mentor; falha omite atributos, mas aplica custos e consome bloco. | Substituir a curva pelo risco definido aqui; não adicionar lesão nem penalidade extra. |
| UI | `training_dashboard.gd` constrói preview de treino e exibe recursos/resultado. | Valores e fatores devem vir do serviço; UI explica chance, modificadores e resultado. |

### 2.1 Dados numéricos de referência

Valores atuais de Hori são protótipo: atributos POT 30, RES 34, TEC 28, TEO 38, SIN 40; energia 75, estresse 12, motivação 65. Cap de atributos/recursos é 100. Treinos:

| ID | Ganhos base | Energia | Estresse | Risco atual |
|---|---|---:|---:|---|
| `combat` | POT +5, TEC +2 | 15 | +6 | Sim |
| `lab` | TEO +5, SIN +2 | 10 | +4 | Sim |
| `control` | SIN +5, TEC +2 | 13 | +5 | Sim |
| `conditioning` | RES +5, POT +1 | 13 | +3 | Sim |

Recuperação/social atual:

| ID | Efeito atual | Risco |
|---|---|---|
| `rest` | energia +25, estresse −12, motivação +8 | Não |
| `internship` | créditos +25, reputação +1, energia −8, estresse +4 | Não |
| `bond_ray`, `bond_luppi` | vínculo +8, estresse −4 | Não |

## 3. Motivação

### 3.1 Escala e efeitos

Motivação é um estado de disposição/ritmo para treinar, não energia, moralidade, diagnóstico ou requisito de acesso. É persistente, de 0 a 100, limitada pelo cap de recursos.

| Valor antes da atividade | Fator de ganho | Efeito |
|---:|---:|---|
| 0–33 | 0,90 | Ganhos de atributos de treino são ligeiramente menores. |
| 34–66 | 1,00 | Ganhos de treino sem ajuste. |
| 67–100 | 1,10 | Ganhos de atributos de treino são ligeiramente maiores. |

Aplicar o fator somente a atributos positivos de atividades de treino. Não afeta energia, custo monetário, custo em estresse, risco de falha, chance de eventos, requisitos de missão, Pulso, vínculo ou final. Motivação baixa nunca bloqueia atividade nem reduz ganho a zero por si só.

### 3.2 Mudanças e recuperação

- Descanso mantém o efeito atual de `+8` motivação, com cap 100.
- Efeitos narrativos declarados em `resources_delta.mood` podem aumentar ou diminuir motivação, limitados a 0–100.
- Nenhuma mudança passiva por semana, treino, falha ou tempo real. Falha de treinamento não reduz motivação automaticamente.
- Nenhum sistema de dívida de motivação nem recuperação fora das ações já disponíveis.
- Descanso permanece sem custo de energia e sem risco, inclusive com energia zero. Continua custando uma das três ações semanais.
- Outras fontes de motivação não são introduzidas sem decisão de conteúdo; valores de eventos existentes não são alterados por esta especificação.

### 3.3 Proteção contra espiral

- Motivação não altera risco nem disponibilidade.
- Descanso recupera motivação e energia enquanto reduz estresse.
- A faixa baixa retém 90% do ganho multiplicado por aptidão, portanto preserva progresso.
- Falhas não reduzem motivação nem adicionam estresse além do custo já declarado na atividade.
- Uma sequência de falhas consome ações/energia e não concede atributos, mas não cria estado permanente; descanso e atividades sociais continuam disponíveis.

## 4. Aptidões individuais

### 4.1 Representação de dados

- Manter `aptitudes` por personagem em `characters.json`, como objeto de ID de atividade para multiplicador positivo.
- A chave corresponde ao `id` da atividade (`combat`, `lab`, `control`, `conditioning`), não à categoria genérica.
- Intervalo válido: `0,85–1,15`, inclusive. Dados fora do intervalo são rejeitados com erro, não ajustados silenciosamente.
- Chave ausente significa multiplicador neutro `1,00`, sem bloquear a atividade.
- Aptidão é afinidade de desempenho contextual, não valor moral ou hierarquia de personagem.
- O serviço atual carrega Hori especificamente. Aptidões de Ray/Luppi em dados não significam que sejam personagens jogáveis nem que seus treinos estejam implementados.

### 4.2 Escopo do efeito

- Aptidão multiplica somente os ganhos positivos de atributo da atividade correspondente.
- Não altera custos, risco, energia, estresse, créditos, reputação, vínculos ou elegibilidade.
- Multiplicador não substitui atividade nem reduz ganhos de outra atividade; nenhuma aptidão pode tornar outra escolha obrigatória.
- Conteúdo de atividade precisa passar por validação para assegurar ganho total máximo de 12 atributos por ação sob `aptitude=1,15` e `motivation=1,10`.

## 5. Mentoria

### 5.1 Disponibilidade no MVP

- Reutilizar apenas o vínculo atual `instructor`, sem criar professor(a) nomeado(a) nem novo fato narrativo.
- Mentor está disponível para um treino se `bonds.instructor >= 30` e o treino tem `mentor_affinity` não nula/compatível.
- O estado inicial de Hori já atende ao limiar (30), conforme dados de protótipo.
- A afinidade é uma indicação de compatibilidade da atividade; os dados atuais não identificam mentores diferentes por modalidade. No MVP, o instrutor existente dá o suporte genérico compatível.
- Relação abaixo do limiar ou ausência de afinidade simplesmente não aplica o benefício; não bloqueia a atividade.

### 5.2 Efeito e limites

- Reduz o risco final de falha em **5 pontos percentuais**. Exemplo: 30% passa a 25%, não a 28,5%.
- A redução se aplica uma vez, depois do arredondamento do risco base e antes do clamp final.
- Não aumenta ganho de atributos, não altera custo, não acumula com mentores, equipamentos ou bônus futuros.
- Não há vínculo crescente por ação de treino no MVP. Atingir o limiar ativa um benefício estável, sem incentivo a farm.
- Preview nomeia “instrução disponível” e mostra risco base e risco final com mentoria. Não apresenta o benefício como correção de comportamento ou personalidade.

## 6. Fórmula de ganho

### 6.1 Ordem de aplicação

Para cada atributo positivo de uma atividade válida:

```text
fator_motivação =
    0,90 se motivation <= 33
    1,00 se 34 <= motivation <= 66
    1,10 se motivation >= 67

aptidão = characters.aptitudes[activity_id], ou 1,00 se ausente
ganho_calculado = round(ganho_base × aptidão × fator_motivação)
ganho_aplicado = min(ganho_calculado, cap_atributo - valor_atual)
```

- Multiplicar base × aptidão × motivação em precisão real; arredondar uma vez para o inteiro mais próximo, com valores exatamente no meio arredondados para cima.
- Aplicar o cap do atributo depois do arredondamento.
- Ganho máximo total por ação: 12 pontos, validado em conteúdo no maior fator permitido. A validação falha se uma atividade puder exceder o teto; não cortar silenciosamente o excesso em runtime.
- Equipamentos não acrescentam atributos: seus modificadores são de custos/recuperação e aplicam-se às mudanças de recursos descritas na seção 9.
- Somente sucesso concede ganhos. Falha concede zero atributos, independentemente do preview.

### 6.2 Exemplos numéricos

Exemplos manuais usando a atividade `lab` (TEO +5, SIN +2), sem equipamento. Os fatores 0,85 e 1,15 existem em dados prototípicos de personagens não jogáveis para essa atividade; são exemplos da fórmula, não evidência de que essas campanhas estejam implementadas. Não são resultados de teste.

| Caso | Aptidão | Motivação | Mentoria | TEO | SIN | Risco no estado indicado |
|---|---:|---:|---|---:|---:|---|
| Baixa disposição e aptidão desfavorável | 0,85 | 33 → ×0,90 | Não | `round(5×0,85×0,90)=4` | `round(2×0,85×0,90)=2` | Energia 20, estresse 60: 30%. |
| Condição mediana | 1,00 | 50 → ×1,00 | Não | 5 | 2 | Energia 35, estresse 30: `round(7+3)=10%`. |
| Motivação alta, aptidão favorável, mentor | 1,15 | 80 → ×1,10 | Sim | `round(5×1,15×1,10)=6` | `round(2×1,15×1,10)=3` | Energia 20, estresse 60: 30%−5 pp=25%. |

Os três cenários produzem 6, 7 e 9 pontos nominais no total, respectivamente. Isso mostra diferença limitada, não uma atividade obrigatória. Próximo ao cap, ganho efetivo pode ser menor; por exemplo, TEO 99 com ganho calculado 6 recebe apenas +1. Os dados ativos do serviço atual selecionam Hori; esses exemplos isolam fatores para orientar o futuro suporte a campanhas de outros personagens.

## 7. Fórmula e resolução de falha

### 7.1 Risco de base

Substituir a fórmula atual por esta baseline:

```text
risco_base = round(
    max(0, 45 - energia_atual) × 0,70
  + max(0, estresse_atual - 20) × 0,30
)

risco_final = clamp(risco_base - bônus_mentor, 0, 55)
bônus_mentor = 5 se elegível; caso contrário 0
```

- Energia e estresse são os valores antes da atividade e antes de qualquer custo.
- Motivação e aptidão não alteram risco.
- Equipamento de redução de energia/estresse muda o custo aplicado, não o risco da atividade que está sendo calculada.
- A fórmula só é consultada para atividades com `can_fail=true`. Descanso, estágio e atividades sociais seguem determinísticos.
- Valores iniciais de Hori (energia 75, estresse 12) produzem 0% de risco. O limite inferior é 0%, teto configurado 55%.
- Com custo mínimo de laboratório (energia 10) e estresse 100, a fórmula produz `round(24,5+24)=49%`; o teto 55% é uma salvaguarda geral e não é atingido pelos limites atuais das atividades válidas.
- A fórmula foi escolhida por deixar energia adequada e estresse até 20 sem penalidade, mas aumentar risco com fadiga cumulativa. Ela substitui a curva anterior; qualquer alteração posterior precisa de balanceamento explícito.

### 7.2 Momento e sorteio

- O serviço gera o preview com risco base/final no estado atual, sem sorteio nem mutação.
- A confirmação revalida estado, atividade, energia e ações; usa o mesmo cálculo de preview.
- Se a atividade puder falhar e o risco final for maior que 0%, avançar o RNG do `TrainingState` uma vez e comparar o resultado ao percentual. Seed e estado do RNG continuam reproduzíveis.
- Risco final 0% é sucesso determinístico e não avança RNG.
- Atividade determinística não avança RNG.
- Pulso de Contenção é resolvido por seus dois limiares fixos, fora desta fórmula de atividade e sem RNG.
- O preview apresenta sucesso/falha como cenários e percentuais; não pode antecipar o resultado sorteado.

### 7.3 Efeitos em sucesso e falha

**Sucesso em atividade de treino:**

- Consome um bloco e o custo efetivo de energia.
- Aplica a mudança efetiva de estresse.
- Concede ganhos de atributo depois dos fatores e caps.
- RNG avança uma vez se risco final > 0.

**Falha em atividade de treino:**

- Consome um bloco e os mesmos custos efetivos de energia/estresse do sucesso.
- Não concede atributos.
- Não acrescenta estresse, lesão, dívida ou outra punição além do custo configurado.
- RNG avança uma vez e seu novo estado é confirmado junto ao resultado.

**Rejeição:** atividade inválida, ação indisponível, energia insuficiente ou estado inválido não consome ação, recursos nem RNG.

### 7.4 Recuperação e sequência de falhas

- Descanso continua garantido, sem risco e sem requisito de energia; consome uma ação.
- Uma ação de descanso usa os efeitos atuais: energia +25, estresse −12, motivação +8, respeitando caps.
- Relações sociais atuais continuam disponíveis a energia zero e reduzem estresse em 4; não há ganho de motivação automático.
- Não existe penalidade crescente por número de falhas e nenhum estado de lesão é criado.
- Exemplo: energia 20/estresse 60 dá 30% de risco. Depois de descanso, energia 45/estresse 48, risco base passa a `round(0+8,4)=8%`; motivação sobe 8. Recuperação exige um bloco, mas reduz substancialmente a chance sem eliminar agência.

## 8. Equipamentos do MVP e interação com treino

Equipamentos foram escolhidos para mudar a gestão de recursos, não os atributos, condições do Pulso ou resultado garantido.

| ID conceitual | Preço | Efeito com o item equipado | Aplicação |
|---|---:|---|---|
| `training_notebook` — Caderno de treino | 80 créditos | Reduz custo energético de treino em 2, mínimo 8. | Energia descontada em sucesso e falha; risco usa energia antes do custo. |
| `recovery_kit` — Kit de recuperação | 120 créditos | Descanso recupera +5 energia (total +30). | Aplicar antes do cap de energia 100. |
| `focus_aid` — Auxílio de foco | 160 créditos | Reduz aumento de estresse de treino em 1, mínimo 0. | Delta de estresse aplicado tanto em sucesso quanto em falha. |

- Uma cópia de cada item; um slot equipado; sem revenda ou reembolso.
- Troca gratuita somente antes da primeira ação semanal (ações restantes iguais a 3); item fica fixo até a semana seguinte.
- Compra não consome bloco; comprar no meio da semana não permite equipar até a próxima semana.
- Item não modifica chance de falha diretamente, atributos, bonds, requisitos narrativos ou Pulso.
- Um item que não esteja equipado não tem efeito. Cada efeito é derivado do ID equipado, sem gravar bônus cumulativos no atributo/recurso-base.
- Novos equipamentos da Parte 5 exigem revisar faixa de preços, cap de recurso e validação de combinações; não podem somar mais de um efeito por ação no mesmo canal sem teste de balanço.

## 9. Prévia, feedback e acessibilidade

### Antes de confirmar treino

Mostrar:

- atividade, bloco consumido e custo de energia/estresse após equipamento;
- atributos base, aptidão usada (ou neutra), faixa/fator de motivação e ganho previsto;
- cap aplicável e valor efetivo limitado;
- risco base e risco final, incluindo instrutor/mentoria elegível;
- os dois cenários de sucesso/falha; informar claramente que falha ainda paga os custos;
- quando risco é 0%, apresentar “sem risco nesta atividade neste estado”, não uma porcentagem que sugira sorteio.

### Depois da confirmação

Mostrar resultado real, ganhos efetivos, custos cobrados, chance considerada e se mentoria/equipamento foi aplicado. Em falha, informar que os custos foram aplicados e os atributos não aumentaram, sem tom punitivo.

### Texto e tom

- Motivação representa um estado variável, não “bom” ou “mau” caráter.
- O texto pode dizer “ritmo atual de treino” ou “disposição para treinar”, não “preguiça”, “fraqueza” ou diagnóstico.
- Aptidão descreve compatibilidade de atividade, não inteligência/valor total do personagem.
- Mentoria representa orientação/técnica; não cura neurodivergência ou sofrimento.
- Preservar a voz e o cânone de Hori, Ray e Luppi; diálogos futuros devem ser revisados em português brasileiro, mas nenhum texto narrativo novo é escrito nesta especificação.

## 10. Compatibilidade técnica

| Arquivo/serviço | Integração necessária em implementação futura | Risco a controlar |
|---|---|---|
| `scripts/training_state.gd` | Preservar recursos, RNG e quaisquer IDs de equipamento; incluir no `duplicate_state()`/`copy_from()` o que for adicionado. | Preview ou save pode perder estado caso novo campo não seja copiado. |
| `scripts/training_service.gd` | Centralizar aptidão, motivação, mentoria, risco, equipamento, custos e ganhos; expor preview e confirmação baseados no mesmo avaliador. | Fórmula duplicada no Dashboard diverge do resultado real. |
| `scripts/training_preview.gd` | Expor fatores calculados, risco base/final, valores de cenário e resultado aplicado sem dados de UI. | Preview tornar-se “quase igual”, mas diferente do commit. |
| `scripts/narrative_service.gd` | Não ler motivação/aptidão como moralidade nem alterar Pulso. Regras de missão permanecem separadas da falha aleatória de atividade. | Confundir risco de treino com resolução determinística da missão. |
| `scripts/training_dashboard.gd` | Exibir fatores/resultado; chamar o serviço para preview e aplicação; controlar troca de item no início de semana. | Estado ou valores exibidos serem calculados independentemente na UI. |
| `data/activities.json` | Continuar declarando base, custos, `can_fail`, `mentor_affinity` e ID estável; validar teto de ganho. | Allowlist atual rejeita novos campos até o validador ser atualizado deliberadamente. |
| `data/characters.json` | Continuar declarando fatores por personagem/atividade; validar faixa e ausência neutra. | Serviço atual seleciona Hori; aptidões de Ray/Luppi não implicam campanhas jogáveis. |
| Dados de equipamentos/save | Definir catálogo estável e armazenar IDs/posse/slot; salvar versão e estado RNG com campanha. | Equipar/desquipar não pode adicionar/remover permanentemente atributo ou duplicar bônus. |

## 11. Critérios de aceitação da futura implementação

**Esta lista é conceitual e não foi executada.** Implementar e testar por partes, sem runner de campanha completa.

### Motivação

- Valores 0, 33, 34, 66, 67, 100 produzem respectivamente fatores 0,90 / 0,90 / 1,00 / 1,00 / 1,10 / 1,10.
- Mudança de motivação via descanso/evento respeita `[0,100]`; não há decaimento passivo.
- Motivação baixa não bloqueia atividade, não altera risco e não zera ganho.
- Descanso em energia zero é permitido; energia, estresse e motivação respeitam caps.

### Aptidões e fórmula de ganho

- Multiplicadores 0,85, 1,00, 1,15 são aplicados por ID de atividade; ausente usa 1,00; dados fora da faixa são rejeitados.
- Fatores multiplicam o ganho base antes de um arredondamento por atributo.
- Cap de atributo é aplicado depois do arredondamento e o valor efetivo é o exibido.
- Falha nunca concede atributos; sucesso aplica os mesmos números do cenário de sucesso do preview se estado/RNG não mudar.
- Dados cujo maior ganho total ultrapassa 12 são rejeitados na validação.

### Mentoria e risco

- Instrutor com vínculo 29 não concede bônus; vínculo 30 e afinidade compatível reduz 5 pontos percentuais; ausência de afinidade não concede bônus.
- Risco é calculado com energia/estresse pré-ação. Energia 75/estresse 12 resulta em 0%; energia 20/estresse 60 em 30%; energia 10/estresse 100 em 49%.
- Mentor reduz os exemplos 30%→25% e 49%→44%; risco nunca fica abaixo de zero nem acima de 55%.
- Apenas atividades com `can_fail` e risco >0 consomem um sorteio; preview, atividade determinística e treino com risco 0 não avançam RNG.
- Sucesso/falha consomem o mesmo custo e ação; falha não aplica atributos nem penalidade adicional.

### Equipamento

- Compra valida saldo, ID e posse; compra recusada não altera carteira/inventário.
- Bônus do item equipado aparece uma vez; troca do item não altera atributos permanentes.
- Equipamento só pode mudar com 3 ações restantes; após primeira ação, troca fica indisponível até próxima semana.
- Caderno reduz custo em 2 até o mínimo 8; kit eleva recuperação do descanso em 5 antes do cap; auxílio reduz estresse em 1 até mínimo zero.
- Itens não alteram Pulso, missão, finais ou disponibilidade de atividades.

### Recuperação e comportamento

- Uma sequência de falhas não cria lesão, dívida, perda adicional de motivação ou bloqueio de atividade.
- Descanso e atividade social continuam disponíveis com energia zero.
- Previews repetidos são idênticos e não mutam estado nem RNG.
- Se o estado de origem não mudar, confirmação usa a mesma fórmula/fatores do preview; a única diferença é o resultado aleatório efetivamente sorteado quando o risco é positivo.

## 12. Riscos e decisões de implementação

1. **Faixas discretas de motivação:** mudanças pequenas em 33→34 e 66→67 alteram o multiplicador. Verificar no playtest se os saltos são percebidos como aceitáveis.
2. **Arredondamento mascara aptidão:** ganhos base +2 podem permanecer iguais após multiplicadores. UI deve mostrar o fator, mas não prometer um ponto que o inteiro não entrega.
3. **Risco revisto:** a nova fórmula substitui dados de tuning anteriores. Validar risco em estados representativos e confirmar que descansar é uma decisão viável sem dominar os 48 blocos.
4. **Mentoria ampla:** vínculo inicial de Hori já cumpre o limiar; mentoria pode estar ativa desde o começo em todos os quatro treinos atuais. Isso é intencional para demonstrar o sistema, mas deve ser avaliado na experiência.
5. **Atividade determinística:** estágio pode não ser afetado por aptidão, motivação ou mentoria pois não concede atributos e não pode falhar. Não forçar um modificador só para usar as mecânicas.
6. **Equipamento limitado a uma vaga:** facilita balanceamento, mas exige texto de troca claro e estado de semana correto após carregar save.
7. **Campanhas futuras:** Ray/Luppi têm aptidões prototípicas, mas não treinam no serviço atual. Ativar seus dados requer contrato de personagem/campanha separado, sem inferência automática.
8. **RNG de engine:** guardar `rng_seed`/`rng_state` permite continuar no runtime suportado; não prometer a mesma sequência entre diferentes versões de Godot sem validação.

## 13. Ordem sugerida para implementação futura

1. Congelar os contratos de fórmula e ampliar testes unitários de `TrainingService`; não alterar conteúdo/GUI ainda.
2. Implementar motivação/aptidão e preview da fórmula de ganho; comparar ganho calculado, cap e valor efetivo.
3. Implementar a curva de risco/mentoria e testar sucesso/falha/RNG com seeds fixas e estados de fronteira.
4. Integrar os três efeitos de equipamento e as operações de compra/equipagem; testar sem loja visual completa.
5. Integrar apresentação do Dashboard somente depois que os valores do serviço forem estáveis.
6. Confirmar save/load de todos os campos antes de adicionar itens narrativos/atividades da Parte 5.
7. Fazer playtest curto e localizado com autorização e equipamento estável; revisar valores por evidência, sem campanhas automatizadas longas.

## 14. Registro de validação

- Fontes verificadas estaticamente: `training_state.gd`, `training_service.gd`, `training_preview.gd`, `narrative_service.gd`, `training_dashboard.gd`, `activities.json`, `characters.json`, testes existentes e documentos 4B/4C.1.
- Os exemplos e resultados de fórmulas foram calculados manualmente a partir dos valores declarados.
- Nenhum teste automatizado, Godot, Play, runner, simulação, build ou benchmark foi executado.
- A especificação não modifica código ou dados do jogo. Qualquer divergência com a implementação atual será resolvida somente em etapa de implementação aprovada.
- Dependente de revisão do autor antes de iniciar implementação 4C.2.

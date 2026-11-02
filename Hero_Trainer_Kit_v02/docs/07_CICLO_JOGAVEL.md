# Protótipo jogável — ciclo semanal da Hori

O projeto Godot existente inicia em `res://scenes/training_dashboard.tscn`. A primeira semana usa os valores de Hori em `data/characters.json`: POT 30, RES 34, TEC 28, TEO 38, SIN 40; energia 75, estresse 12, motivação 65, 50 créditos e reputação 20. Os cinco atributos e os três recursos ficam limitados a 0–100, conforme `stat_cap` e `resource_cap` em `data/activities.json`. O mesmo arquivo define 16 semanas e três ações por semana.

Os vínculos iniciais vêm de `characters.json`: Ray 30, Luppi 25 e instrutor 30. Reputação e vínculos têm limites de 0–100, configurados por `reputation_cap` e `bond_cap` em `activities.json`. Créditos não têm teto de jogo; são inteiros não negativos limitados apenas pela representação `int` do Godot.

As oito atividades, IDs, categorias, nomes e deltas vêm de `data/activities.json`, sem ajustes:

| Atividade | Efeitos |
|---|---|
| Combate | POT +5, TEC +2, energia -15, estresse +6 |
| Estudo no laboratório | TEO +5, SIN +2, energia -10, estresse +4 |
| Controle de energia | SIN +5, TEC +2, energia -13, estresse +5 |
| Condicionamento físico | RES +5, POT +1, energia -13, estresse +3 |
| Descanso e lazer | energia +25, estresse -12, motivação +8 |
| Estágio de apoio | créditos +25, reputação +1, energia -8, estresse +4 |
| Conversa com Ray | vínculo com Ray +8, estresse -4 |
| Tempo com Luppi | vínculo com Luppi +8, estresse -4 |

O campo `mood` existente no JSON é apresentado como “Motivação” na interface. Qualquer atividade com custo de energia exige, no mínimo, o valor do custo indicado no JSON. Abaixo desse mínimo, prévia e aplicação rejeitam a atividade, informam a energia que falta e preservam todo o estado, inclusive ações. Atividades sem custo de energia e descanso continuam disponíveis com energia zero.

Cada confirmação consome um bloco semanal. Prévia e resultado aplicado são idênticos nesta fase determinística. A UI apresenta categoria, custo de energia, todos os efeitos previstos e os recursos relacionais/financeiros.

O ciclo termina ao fim da semana 16. Limites de atributos, recursos, reputação e vínculos, número de semanas e ações semanais são carregados e validados pelo serviço a partir de `data/activities.json`; não há cópias desses valores na interface. Ao avançar a semana, todos os atributos e recursos atuais são preservados.

## Risco e falhas do treinamento

`TrainingService` implementa explicitamente a fórmula declarada em `data/activities.json`; a string nunca é avaliada como código:

```text
clamp(0,60,round(max(0,35-energy)*0.9+stress*0.2+injury_level*12-mentor_bonus))
```

O cálculo usa a energia e o estresse anteriores ao treino. Primeiro arredonda o resultado para inteiro; depois limita a chance entre 0% e 60%. Nesta fase, `injury_level` e `mentor_bonus` são placeholders fixos em zero. Não há sistema de lesões nem mentores ativos. Com os limites atuais de energia/estresse e o requisito de energia das atividades, o maior risco alcançável por uma atividade válida é 43% no laboratório (energia 10, estresse 100); o teto geral declarado continua em 60%.

Somente atividades com `can_fail: true` sorteiam um resultado. Em sucesso, aplicam os ganhos de atributos e os deltas de recursos. Em falha, os ganhos de atributos são omitidos, mas os deltas/custos de recursos e o bloco semanal são aplicados normalmente. Atividades sem falha possível permanecem determinísticas; atividade bloqueada é rejeitada antes do sorteio.

A prévia exibe as chances e os dois cenários, não consulta nem avança o RNG. A confirmação válida realiza exatamente uma chamada a `randf()` para atividades arriscadas. Cancelar uma prévia ou rejeitar uma ação não altera o RNG. A comparação usa o valor sorteado contra a chance de falha em percentual.

Cada `TrainingState` guarda `rng_seed` e `rng_state`. `TrainingService.set_random_seed(seed)` define a seed de novas campanhas para testes/reprodução. O estado atual do gerador acompanha a campanha nas cópias e avanços de semana, permitindo continuar futuramente a sequência após uma serialização. A seed padrão de runtime é inicializada aleatoriamente. O retorno estruturado de `apply_activity` inclui atividade, resultado (sucesso, falha ou determinístico), probabilidades, sorteio efetivamente realizado e estado aplicado.

## Pontos para playtest de balanceamento

- Estágio paga +25 créditos e +1 reputação por ação; compare o valor de dinheiro em usos futuros antes de introduzir compras/despesas.
- Descanso recupera energia sem custo e reduz estresse; monitore se ocupa os três blocos em semanas seguidas ou substitui escolhas estratégicas.
- Atividades sociais dão +8 de vínculo e -4 de estresse pelo custo de um bloco; o ganho pode ser repetido em todas as ações, portanto acompanhe o ritmo até o teto 100.
- Treinos com `can_fail: true` deixam de garantir ganhos de atributos. Acompanhe ritmo de progressão e frustração antes de alterar probabilidades, custos ou efeitos.

## Executar

- Abrir a pasta do projeto no Godot 4.5 e executar a cena principal.
- Executar os testes no PowerShell a partir da pasta do projeto: `& "C:\caminho\para\Godot.exe" --headless --path . --script "$((Resolve-Path .\tests\training_service_test.gd).Path)"`
- Executar a validação de importação: `godot --headless --path . --editor --quit-after 3`

Neste ambiente, o executável está em `C:\Users\João\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe`. Se `godot` não estiver no `PATH`, substitua o comando pelo caminho local do executável.

# Protótipo jogável — ciclo semanal da Hori

O projeto Godot existente inicia em `res://scenes/training_dashboard.tscn`. A primeira semana usa os valores de Hori em `data/characters.json`: POT 30, RES 34, TEC 28, TEO 38, SIN 40; energia 75, estresse 12 e motivação 65. Os cinco atributos e os três recursos ficam limitados a 0–100, conforme `stat_cap` e `resource_cap` em `data/activities.json`. O mesmo arquivo define 16 semanas e três ações por semana.

As atividades reutilizam os deltas de `data/activities.json`, sem ajustes:

| Atividade | Efeitos |
|---|---|
| Combate | POT +5, TEC +2, energia -15, estresse +6 |
| Controle | SIN +5, TEC +2, energia -13, estresse +5 |
| Descanso | energia +25, estresse -12, motivação +8 |

O campo `mood` existente no JSON é apresentado como “Motivação” na interface. Combate exige energia mínima 15 e Controle exige 13: os limites vêm diretamente do custo de energia de cada atividade em `data/activities.json`. Abaixo desse mínimo, prévia e aplicação rejeitam a atividade, informam a energia que falta e preservam todo o estado, inclusive ações. Descanso não exige energia mínima. Os deltas são determinísticos nesta etapa: o metadado `can_fail` e a fórmula de falha do JSON não são usados, pois o protótipo ainda não tem resolução de risco.

O ciclo termina ao fim da semana 16. Os limites de atributos/recursos, número de semanas e ações semanais são carregados e validados pelo serviço a partir de `data/activities.json`; não há cópias desses valores na interface.

## Executar

- Abrir a pasta do projeto no Godot 4.5 e executar a cena principal.
- Executar os testes: `godot --headless --path . --script res://tests/training_service_test.gd`
- Executar a validação de importação: `godot --headless --path . --editor --quit-after 3`

Neste ambiente, o executável está em `C:\Users\João\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe`. Se `godot` não estiver no `PATH`, substitua o comando pelo caminho local do executável.

# HERO TRAINER — Registro de Implementação — Fase 4C

**Status:** implementação integrada em código; revisão estática realizada. Godot, testes, runner, simulações, builds e benchmarks não foram executados. O comportamento em runtime permanece sem validação.

Este registro acompanha as baselines aprovadas em [11 — Especificação de Game Design da Fase 4C](./11_ESPECIFICACAO_GAME_DESIGN_FASE_4C.md), [12 — Decisões da Fase 4C.1](./12_DECISOES_GAME_DESIGN_FASE_4C1.md) e [13 — Especificação de Game Design da Fase 4C.2](./13_ESPECIFICACAO_GAME_DESIGN_FASE_4C2.md). Essas baselines continuam sendo a fonte das regras e decisões de design; este documento registra como elas foram traduzidas para o código e os limites de verificação.

## 1. Escopo implementado

### Estado e cópia de campanha

[`scripts/training_state.gd`](../../scripts/training_state.gd) agora mantém explicitamente os estados da missão (`attempted`, `completed`, `success`, `failed_by_deadline` e `resolved`), o inventário e o equipamento ativo. `duplicate_state()` e `copy_from()` incluem esses campos para que operações possam trabalhar em candidatos sem alterar prematuramente o estado publicado.

### Treinamento e prévia

[`scripts/training_service.gd`](../../scripts/training_service.gd) aplica as fórmulas aprovadas:

- Risco-base: `round(max(0, 45 − energia) × 0,7 + max(0, estresse − 20) × 0,3)`, limitado a 0–55%.
- Mentoria elegível reduz o risco em 5 pontos percentuais, sem acumular outras reduções de risco.
- Risco zero não consome nem avança o estado do gerador aleatório.
- Ganho de atributo: valor configurado × aptidão × motivação, arredondado uma vez e limitado pelo teto do atributo. Os multiplicadores de motivação são 0,90 até 33, 1,00 até 66 e 1,10 a partir de 67; aptidões permanecem limitadas a 0,85–1,15.
- A mentoria usa o vínculo existente com instrutor, o limiar configurado e a afinidade declarada na atividade.

[`scripts/training_preview.gd`](../../scripts/training_preview.gd) expõe componentes calculados e efetivos para a interface, incluindo custos, multiplicadores, ganhos, equipamento e chances. A interface consome a prévia do serviço em vez de duplicar as fórmulas.

### Economia e equipamentos

[`scripts/economy_service.gd`](../../scripts/economy_service.gd) implementa o catálogo aprovado:

| Item | Preço | Efeito |
|---|---:|---|
| Caderno de treino | 80 créditos | Reduz em 2 o custo de energia de treino, até o mínimo de 8. |
| Kit de recuperação | 120 créditos | Descanso recupera 5 de energia adicional. |
| Auxílio de foco | 160 créditos | Reduz em 1 o aumento de estresse em treino, até o mínimo de 0. |

Compra valida créditos e duplicidade. Troca de equipamento exige que ainda não tenha ocorrido ação na semana. O serviço valida inventário, item equipado e saldo antes de aplicar uma operação.

### Save e retomada

[`scripts/campaign_save_service.gd`](../../scripts/campaign_save_service.gd) adiciona um envelope versionado, snapshot de campanha validado pelos serviços, save principal, backup e arquivo temporário. A inicialização do dashboard oferece retomada, recuperação de backup ou início de nova campanha; dados corrompidos ou incompatíveis são preservados antes da substituição, conforme o fluxo implementado.

A gravação verifica o temporário e o arquivo principal após a cópia. **A substituição do arquivo principal é feita por cópia, não por uma operação atômica**; portanto, o código não garante imunidade a interrupção do sistema durante a gravação. Essa limitação não foi reproduzida nem avaliada em runtime.

### Missão, prazo e finais

[`scripts/narrative_service.gd`](../../scripts/narrative_service.gd) registra estados distintos de tentativa, conclusão e resolução. O Pulso só tem sucesso quando estabilidade do núcleo é pelo menos 55 **e** TEC é pelo menos 30. A primeira escolha válida registra uma tentativa; a terceira encerra a missão como concluída e resolvida, com sucesso ou falha recuperável.

A expiração só é registrada na transição confirmada da semana 8 para a 9, quando a missão não foi concluída. Não cria uma tentativa fictícia. A resolução da missão habilita a busca de final; finais de sucesso continuam exigindo sucesso, e o final independente mantém seus requisitos próprios. As alterações correspondentes nos dados estão em [`missions_hori_draft.json`](../Hori%20Draft/missions_hori_draft.json) e [`endings_hori_draft.json`](../Hori%20Draft/endings_hori_draft.json).

### Interface e transações

[`scripts/training_dashboard.gd`](../../scripts/training_dashboard.gd) conecta carregamento/retomada, treinamento, escolhas narrativas, loja, avanço semanal e encerramento. Operações persistentes são preparadas em estado candidato, gravadas e só então copiadas para o estado ativo. A loja e o preview apresentam os dados dos serviços, sem recalcular regras de gameplay.

O avanço que expira o prazo requer confirmação explícita. O aviso do Pulso apresenta os limiares e os valores relevantes.

## 2. Arquivos envolvidos

### Código

- [`scripts/training_state.gd`](../../scripts/training_state.gd)
- [`scripts/training_preview.gd`](../../scripts/training_preview.gd)
- [`scripts/training_service.gd`](../../scripts/training_service.gd)
- [`scripts/economy_service.gd`](../../scripts/economy_service.gd) — novo
- [`scripts/campaign_save_service.gd`](../../scripts/campaign_save_service.gd) — novo
- [`scripts/narrative_service.gd`](../../scripts/narrative_service.gd)
- [`scripts/training_dashboard.gd`](../../scripts/training_dashboard.gd)

### Dados

- [`activities.json`](../data/activities.json)
- [`missions_hori_draft.json`](../Hori%20Draft/missions_hori_draft.json)
- [`endings_hori_draft.json`](../Hori%20Draft/endings_hori_draft.json)

### Testes preparados

- [`test_training_service.gd`](../../tests/test_training_service.gd)
- [`test_narrative_campaign.gd`](../../tests/test_narrative_campaign.gd)
- [`test_campaign_economy_save.gd`](../../tests/test_campaign_economy_save.gd) — novo; cobre economia, validações e round-trip estrutural sem gravar arquivos.
- [`test_dashboard_presentation.gd`](../../tests/test_dashboard_presentation.gd) — os casos de dashboard desativam a persistência para evitar acesso a `user://` durante os testes.

### Documentação de baseline atualizada

- [11 — Especificação de Game Design da Fase 4C](./11_ESPECIFICACAO_GAME_DESIGN_FASE_4C.md)
- [12 — Decisões da Fase 4C.1](./12_DECISOES_GAME_DESIGN_FASE_4C1.md)
- [13 — Especificação de Game Design da Fase 4C.2](./13_ESPECIFICACAO_GAME_DESIGN_FASE_4C2.md)

Os testes foram preparados/atualizados, mas **não foram executados**. Isso não comprova compilação, carregamento de recursos, funcionamento de diálogos ou comportamento em runtime.

## 3. Verificações e limitações

- A revisão estática conferiu as fórmulas, validações de estado, transações por candidato, condições de prazo e os campos de inventário/equipamento no snapshot.
- A inicialização do dashboard em testes com persistência desativada não deve acessar o save. Instâncias de script criadas diretamente nos testes inicializam o serviço de economia ao construir a interface; a disponibilidade do estado narrativo é verificada antes do uso nessa atualização da tela do Hub.
- Não há resultado de teste, benchmark, simulação ou execução do Godot a registrar.
- Permanecem pendentes a validação de sintaxe e tipos pelo Godot, a execução dos testes focados e a validação manual do fluxo visual, todos sujeitos a autorização específica do autor.
- Qualquer discrepância observada somente em runtime deve ser tratada como hipótese até que uma execução localizada, autorizada e segura a confirme.

## 4. Próxima validação autorizável

Quando o autor considerar seguro, validar primeiro os testes focados de serviço, narrativa, save/economia e dashboard, em sessões pequenas e sem simulação de campanha. Até essa autorização, este registro descreve apenas o código inspecionado estaticamente.

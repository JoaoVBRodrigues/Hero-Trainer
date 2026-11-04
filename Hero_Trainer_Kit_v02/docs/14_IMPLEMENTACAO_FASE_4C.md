# HERO TRAINER — Registro de Implementação — Fase 4C

**Status:** implementação integrada e Save/Load validado funcionalmente no Godot 4.5.1. Os testes focados de persistência passaram; a suíte de apresentação do dashboard ainda tem duas falhas registradas na seção 3. Não foram executados runner, simulações, builds ou benchmarks.

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

A gravação valida o estado e o temporário antes de tocar no principal. Quando existe um principal válido, cria e valida o backup antes da substituição; se a gravação ou validação do novo principal falha, tenta restaurar e validar o backup. A operação continua baseada em cópias, não em substituição atômica; interrupção física do sistema durante a escrita e falhas forçadas de I/O não foram simuladas.

Durante a inicialização do editor foi reproduzida uma falha de resolução dos tipos globais `EconomyService` e `CampaignSaveService` no dashboard. O caminho de Save/Load agora usa aliases de scripts carregados por `preload` para esses tipos e para as dependências relacionadas (`TrainingState` e `NarrativeService`), evitando depender da resolução global intermitente nesse fluxo.

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
- [`test_campaign_economy_save.gd`](../../tests/test_campaign_economy_save.gd) — cobre economia, round-trip e recuperação por arquivos reais em diretórios temporários isolados.
- [`test_dashboard_presentation.gd`](../../tests/test_dashboard_presentation.gd) — os casos de dashboard desativam a persistência para evitar acesso a `user://` durante os testes.

### Documentação de baseline atualizada

- [11 — Especificação de Game Design da Fase 4C](./11_ESPECIFICACAO_GAME_DESIGN_FASE_4C.md)
- [12 — Decisões da Fase 4C.1](./12_DECISOES_GAME_DESIGN_FASE_4C1.md)
- [13 — Especificação de Game Design da Fase 4C.2](./13_ESPECIFICACAO_GAME_DESIGN_FASE_4C2.md)

## 3. Verificações e limitações

- A revisão estática conferiu as fórmulas, validações de estado, transações por candidato, condições de prazo e os campos de inventário/equipamento no snapshot.
- A suíte `Campaign Economy and Save` passou: 4/4 testes, incluindo gravação/leitura real em arquivos temporários, preservação do principal contra estado inválido, recuperação por backup, ausência de ambos os arquivos e preservação de JSON inválido.
- No jogo, foi confirmado o início sem save: a campanha começou na semana 1 e criou JSON válido com 3 ações. O arquivo gerado para esse cenário foi arquivado fora do caminho ativo.
- O fluxo real de progresso e retomada foi executado em duas reinicializações. Após atividade, descanso, avanço semanal e escolha narrativa, o save foi carregado com semana 3, 3 ações, 45 créditos, energia 100, estresse 0, motivação 89, reputação 23, vínculo do instrutor 34, estabilidade do núcleo 69, flags narrativas, inventário/equipamento `training_notebook` e estado do RNG persistidos. Foi possível continuar a campanha e salvar novamente.
- Após os testes, o save pessoal anterior foi restaurado a partir da cópia preventiva. A retomada no jogo confirmou semana 2, 3 ações, 20 créditos, energia 84, estresse 10, motivação 73, reputação 22, vínculos Ray 30/Luppi 25/instrutor 30 e `training_notebook` no inventário e equipado. Os hashes SHA-256 do principal e do backup permaneceram idênticos aos originais restaurados.
- A suíte `Dashboard Character Presentation` passou em 6/8 testes. `test_campaign_launch_shows_hub_before_narrative` falhou ao acessar `_hub_ui` nulo no harness de teste; `test_training_screen_previews_and_applies_service_results` falhou porque o estado RNG não avançou na atividade esperada. A causa dessas falhas não foi estabelecida e elas não foram alteradas como parte da correção de persistência. A inicialização e a retomada foram verificadas separadamente no jogo real.
- Não foi injetada uma falha de escrita para testar o rollback físico nem foi interrompida a gravação durante uma substituição. A garantia do rollback está coberta por inspeção do fluxo, não por uma falha real de I/O.
- Nenhuma simulação longa, benchmark ou bateria de testes não relacionada foi executada. A validação de Save/Load em runtime não elimina as limitações de atomicidade de cópia nem as duas falhas da suíte de apresentação acima.

## 4. Próximas validações

Investigar separadamente as duas falhas da suíte de apresentação. Em uma futura alteração do mecanismo de escrita, acrescentar uma forma controlada de exercitar rollback por falha de I/O sem tocar nos saves pessoais.

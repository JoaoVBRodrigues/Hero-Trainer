# Roadmap e critérios de aceite — Hero Trainer

Estimativas relativas, não prazos garantidos. O objetivo é produzir um **vertical slice jogável** antes de multiplicar personagens ou roteiros.

## Fase 0 — Preprodução e coleta (1 sprint)

- Criar repositório, `project.godot`, CI simples, decisões arquiteturais e escopo do MVP.
- Registrar 12 fichas de reverse engineering, diferenciando jogo/versão/fonte e confiança.
- Validar identidade e cânone de Hori, Luppi e Ray; personagens adultos na adaptação.
- Aprovar Bíblia Visual 0.1 e um sprite de Hori.

**Aceite:** documentos sem lacunas bloqueantes; protótipo Godot abre; todas as referências de IP identificadas.

## Fase 1 — Core loop sem narrativa (1–2 sprints)

- Painel semanal, cinco atividades, 16 semanas, atualização de energia/estresse/atributos.
- Previsão de ganhos/risco, RNG com seed, histórico de decisões, save/load.
- Testes determinísticos das regras puras, sem assets finais.

**Aceite:** completar 48 escolhas, salvar na semana 7 e continuar sem alterar resultado; não passar limites; nenhum softlock de energia.

## Fase 2 — Narrativa vertical slice (1–2 sprints)

- Hori: 8 eventos (2 principais, 4 de relação, 2 de mundo), escolhas com flags.
- Missão intermediária de 3 etapas com consequências, uma habilidade especial.
- 4 finais para Hori, com relatório de causas em linguagem natural.

**Aceite:** duas seeds + escolhas distintas resultam em dois finais justificáveis; não repetir evento único; prioridade de final definida.

## Fase 3 — Interface e arte (1–2 sprints)

- Painel visual, quatro expressões de Hori alinhadas, sala da academia, laboratório, área da missão.
- UI clara com números e previews, escala de texto, log de diálogo.

**Aceite:** interação teclado/mouse, nenhuma arte oscila entre expressões, sem overflow em 1366×768.

## Fase 4 — Conteúdo e expansão (após testes)

- Campanhas de Luppi e Ray; narrativas compartilhadas e reações especiais.
- Treinamento simultâneo de equipe com custos de coordenação e descanso.
- 2–3 missões extras, finais compostos de equipe, novas atividades.

**Aceite:** cada campanha oferece conflito e resolução próprios, nenhuma depende de stats inacessíveis, roteiros sem contradição cruzada.

## Backlog priorizado

**P0:** escolher treino, prever resultado, aplicar cálculo, passar semana, salvar/carregar, 1 missão, 1 final.

**P1:** sinergias, risco e consequências, diálogos, mais finais, acessibilidade.

**P2:** múltiplas protagonistas, arte final, áudio, conquistas, refinamento de balanceamento.

**P3:** sistema completo de equipe, replay avançado, cenários alternativos.

## Testes sugeridos

1. `test_clamp_all_resources()`
2. `test_energy_zero_never_softlocks()`
3. `test_same_seed_same_choices_same_result()`
4. `test_event_once_not_repeated()`
5. `test_activity_preview_matches_resolution()`
6. `test_ending_has_unique_priority()`
7. `test_all_endings_are_reachable()` (busca/checagem com seeds e roteiros controlados)
8. `test_save_v1_migration_preserves_flags()`
9. `test_no_actions_consumed_by_read_only_ui()`
10. `test_progress_48_actions_completes_campaign()`

## Ferramentas e cotas

- Copilot Free: autocomplete e pequenas tarefas por arquivo; não esgotar chats em construção integral.
- Codex: decisões arquiteturais e revisão de PRs pequenos; nunca um prompt 'crie o jogo todo'.
- Antigravity: revisão de UI/integrador quando existir build testável; desativar uso automático de créditos extras se não desejar cobrança.
- Gemini: brainstorming e conteúdo em lote com esquema de saída fixo.
- Claude Desktop gratuito: voz, continuidade e revisão de texto, em pequenas cenas; compartilhar apenas fichas necessárias.
- Autor humano: última palavra em cânone, estilo, direção ética, diversão e aprovação dos assets.

# Hero Trainer — Kit de planejamento v0.2

**Data:** 01/11/2026. **Status do kit:** documentação de planejamento v0.2. **Status do projeto Godot na raiz do repositório:** protótipo jogável com treinamento semanal e campanha narrativa de Hori integrada; não é um jogo finalizado.

**IMPORTANTE — CORREÇÃO DE CÂNONE:** leia `docs/05_CANONE_PERSONAGENS.md` **ANTES** do GDD anterior. A versão 0.1 continha suposições incorretas sobre Hori, Luppi e Ray. Todas as peças em v0.2 prevalecem sobre conflitos anteriores.

## Como começar

1. Leia `docs/05_CANONE_PERSONAGENS.md`, depois `docs/06_ROTAS_E_MECANICAS.md` e `docs/01_GDD.md`. Caracterizações da v0.1 não são cânone.
2. Leia `docs/02_REVERSE_ENGINEERING.md` para estudar os jogos de referência por observação e documentar evidências.
3. Para executar o protótipo existente, abra o `project.godot` na raiz do repositório com Godot 4.5.1. Não crie outro projeto para continuar a implementação.
4. Consulte `docs/07_CICLO_JOGAVEL.md` e `docs/09_IMPLEMENTACAO_VISUAL_FASE3.md` para o comportamento e a apresentação atualmente implementados.
5. Cole `prompts/01_CODEX_ARQUITETURA.md` no Codex ou no seu agente principal apenas ao iniciar uma implementação nova; peça uma tarefa pequena e revise a saída.
6. Use o Copilot Free no VS Code para implementar funções pequenas; use o Codex em auditorias e integração.
7. Use `prompts/06_CANONE_NARRATIVA_V02.md` com Gemini/Claude e `prompts/03_HUMANIZER.md` para revisar cada cena. A v0.2 prevalece sobre o prompt narrativo anterior.
8. Use `docs/03_BIBLIA_VISUAL.md` e `prompts/07_ARTE_PERSONAGENS_V02.md` como referência para novas artes originais; registre origem e licença dos assets.
9. Use `templates/HANDOFF.md` para transferir contexto mínimo entre IAs.

## Arquivos

- `docs/05_CANONE_PERSONAGENS.md` — fatos confirmados pelo autor separados de propostas (fonte de verdade para personagens).
- `docs/06_ROTAS_E_MECANICAS.md` — planejamento de três campanhas com mecânicas e fins corrigidos.
- `docs/07_CICLO_JOGAVEL.md` — regras do ciclo de treinamento e integração da campanha jogável de Hori.
- `docs/09_IMPLEMENTACAO_VISUAL_FASE3.md` — apresentação visual, cenas e limitações da vertical slice.
- `docs/10_ASSET_MANIFEST.md` — dimensões, formatos e estado dos assets de Fase 3.
- `prompts/06_CANONE_NARRATIVA_V02.md` — prompt narrativo corrigido, prioritário.
- `prompts/07_ARTE_PERSONAGENS_V02.md` — direção de arte atualizada respeitando anatomia e identidade.
- `prompts/08_ASSETS_FASE3.md` — proveniência dos prompts de arte e regras de consistência dos assets integrados.

- `docs/01_GDD.md` — visão, regras iniciais, loops, economia, missões, narrativa e critérios de pronto.
- `docs/02_REVERSE_ENGINEERING.md` — matriz de estudo: confirmado, observável, hipótese e não copiar.
- `docs/03_BIBLIA_VISUAL.md` — identidade visual própria e produção de expressões consistentes.
- `docs/04_ROADMAP.md` — prioridades, fases, testes e critérios de aceite.
- `prompts/01_CODEX_ARQUITETURA.md` — prompt mestre para arquitetura e implementação incremental.
- `prompts/02_NARRATIVA.md` — prompt de roteirista de personagem e planejamento de eventos.
- `prompts/03_HUMANIZER.md` — revisão de naturalidade em PT-BR com controle de continuidade.
- `prompts/04_ARTES.md` — prompts em inglês para personagens, fundos, expressões e UI.
- `prompts/05_QA_REVISOR.md` — auditoria independente.
- `data/characters.json`, `data/activities.json`, `data/events.json`, `data/endings.json` — dados de exemplo, para revisar antes de integrar.
- `templates/HANDOFF.md` — brief de uma página para economizar contexto.

## Fontes de estudo

- Uma Musume Career Mode: https://umamusu.wiki/Scenario
- Treinos de Uma Musume: https://umamusu.wiki/Game:Stat_Training
- Guia de treino comunitário: https://umamusume.gg/career-training-guide/
- Princess Maker 2 guia comunitário (cautela quanto às versões): https://steamcommunity.com/sharedfiles/filedetails/?id=771709910
- Princess Maker 2 elenco e atributos: https://princessmaker.nekoweb.org/pm2/daughter.html
- Godot Autoload: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
- Godot dados do usuário: https://docs.godotengine.org/pt-br/4.x/tutorials/io/data_paths.html

**Diretriz de propriedade intelectual:** estudar sistemas e experiências, criar código e conteúdo independentes. Não copiar artes, textos, nomes protegidos, vozes, músicas, interfaces pixel a pixel ou dados proprietários. Para publicação, transformar influências e personagens vinculados a franquias em um universo original.

# HERO TRAINER — Game Design Document v0.1

## 1. Visão

**Pitch:** treinador(a) de uma academia futurista orienta um(a) cadete adulto(a) durante um semestre, equilibrando estudos, treinamento físico, anomalias, relações pessoais e missões. Em 16 semanas, as escolhas determinam habilidade, autonomia, vínculos, consequências institucionais e finais. As histórias de Hori, Luppi e Ray são **hipóteses temporárias**, não o cânone da mesa original.

**Pilares:** (1) cada decisão custa tempo; (2) competência não é sinônimo de felicidade; (3) personagens têm agência e contradições; (4) sistemas transmitem a história; (5) escolhas têm resultados legíveis.

**Referências analisadas:** Uma Musume (carreira por turnos, aptidões, suporte, energia/humor, eventos, objetivos) e Princess Maker 2 (agenda, estudos, trabalhos, gastos, estresse, reputação, final calculado por prioridades). Não reutilizar implementações nem conteúdo proprietário.

**Escopo do protótipo:** Uma aluna treinável (Hori), Luppi e Ray como NPCs de apoio, 16 semanas de 3 blocos cada, cinco atributos, cinco atividades básicas, uma habilidade desbloqueável, oito eventos, uma missão intercalada em três fases, quatro finais, tela de resultados, save/load. Depois adicionar campanhas próprias de Luppi e Ray.

## 2. Mundo original provisório

Academia Nexo: instituição interplanetária que prepara agentes para controlar *Rupturas*, fenômenos que podem alterar a física local e corromper dados de sensores. O corpo docente tem conflitos sobre pesquisa, disciplina e dever de proteção. Seus procedimentos nem sempre protegem os estudantes. História-base: uma Ruptura atípica reage a cadetes da turma 7 e revela um protocolo oculto de contenção.

**Observação:** o mundo Honkai Star Rail é inspiração de campanha particular, não a base publicável. Nomear personagens, grupos, acontecimentos e visual de forma independente ao migrar para uma versão comercial.

## 3. Loop principal e ritmo

**Meta da campanha:** 16 semanas × 3 blocos de ação = **48 escolhas**. Não há ações obrigatórias invisíveis. Semana 4 = prova de aptidão; semana 8 = missão de resgate; semana 12 = investigação crítica; semana 16 = missão final e epílogo. Pausas/eventos ocupam um bloco apenas quando o jogador escolhe essa opção; eventos narrativos de marco são apresentados sem consumir ação, salvo quando explicitado.

1. Ver estado, objetivo, docentes disponíveis e previsões das atividades.
2. Selecionar atividade para o bloco (estudo, treino, estágio, lazer, social, preparação de missão).
3. Aplicar ganhos/custos, calcular falha determinística a partir da seed e processar evento possível.
4. Gravar flags e vínculos; atualizar diário e objetivos.
5. Quando 3 blocos acabam, encerrar semana (recuperação basal) e atualizar grade.
6. Em marcos, escolher plano da missão, resolver 2–3 desafios com resultados persistentes.
7. Semana 16: calcular conquista acadêmica, consequências de missão e eixo pessoal; selecionar epílogos por prioridade.

**Replay:** novas abordagens, epílogos e cenas condicionais; por enquanto **sem gacha**, grind infinito, microtransações ou genética/inheritance do jogo de referência.

## 4. Atributos, recursos e estados

### Atributos centrais (inteiros 0–100)
- POT: potência física / poder de impacto.
- RES: tolerância a pressão, dano e esforço.
- TEC: precisão, tática, dispositivos.
- TEO: análise científica, conhecimento, dedução.
- SIN: controle de habilidade especial e sincronização.

**Recursos:** Energia 0–100, Estresse 0–100, Motivação 0–100, Créditos >=0, Reputação 0–100; `injury_level` inteiro 0–2. **Vínculos:** relação com cada colega/professor 0–100.

**Eixos narrativos internos:** `autonomy`, `solidarity`, `ambition`, `integrity` de -100 a +100; são tendências, NÃO 'bondade' ou nota, devem ser influenciados por ações significativas, nunca por farm de treino. **Flags** marcam eventos; `choices_history` retém IDs e versão de conteúdo.

**Aptidão:** cada heroína recebe multiplicadores modestos por tipo de atividade (0.85–1.15), mas nenhuma rota é bloqueada: poder cruzar classes é valioso.

### Economia de treino v0.1 (proposta, sujeita a playtest)

| Ação | Ganho base | Custo | Risco |
|---|---|---|---|
| Combate | POT+5 TEC+2 | Energia -15, Estresse +6 | falha física |
| Laboratório | TEO+5 SIN+2 | Energia -10, Estresse +4 | acidente leve |
| Controle | SIN+5 TEC+2 | Energia -13, Estresse +5 | dispersão |
| Condicionamento | RES+5 POT+1 | Energia -13, Estresse +3 | lesão |
| Recuperação | Energia +25, Motivação +8, Estresse -12 | 1 bloco | sem falha |
| Estágio | Créditos +25, Reputação +1 | Energia -8, Estresse +4 | incidente narrativo |
| Tempo com colega | vínculo +8, Estresse -4 | 1 bloco | cenas/flags |

**Limites:** caps aplicados por campo. Se falta Energia para atividade (abaixo de 10), a UI deve avisar e oferecer recuperação; ações nunca podem gerar números negativos. Evitar opção dominante: Laboratório não substitui permanentemente lazer; fim de semestre exige teoria, relações e efeitos narrativos.

**Proposta inicial de probabilidade de falha do treino:** `clamp(0, 60, round(max(0, 35 - energy) * 0.9 + stress * 0.2 + injury_level * 12 - mentor_bonus))` em percentual. Energia alta permite risco baixo; esta função deve ser ajustada após teste. Em falha: apenas 25% do ganho principal, +5 de estresse e evento de resposta; nunca travar a campanha. Prévia da chance deve ser mostrada antes da confirmação.

**Ganho efetivo:** `round(base_gain * aptitude * mood_factor * mentor_factor * facility_factor)`, com multiplicadores inicialmente entre 0.85 e 1.20 e teto máximo de ganho por ação de 12 pontos. Atualizar vínculos com mentores que participaram de ação bem-sucedida, sem exceder 100.

**Sinergias:** cada semana, 1–2 colegas/mentores ficam disponíveis em atividades específicas, definidos pela seed; vínculo >=60 habilita treino cooperativo. Cooperar gera bônus de atributos e pode abrir uma cena. Qualquer personagem de suporte é desbloqueável pelo progresso narrativo normal, sem sistema comercial.

## 5. Estudos e habilidades especiais

Estruture habilidades como objetos declarativos: id, nome, condição de desbloqueio, custo de foco, usos por missão, predicados de ativação, efeitos, tooltip e texto contextual. Exemplo Hori: `Linha de Proteção` melhora defesa do grupo quando confiança com colegas >=50; uma versão agressiva (POT alto) sacrifica resistência, uma colaborativa (solidarity alto) protege civis. Habilidades não precisam de combos em tempo real.

## 6. Missões

**MVP, não RPG tático em grid:** missões episódicas em três etapas: reconhecimento, ação central e extração. Cada etapa apresenta duas opções estratégias e uma opção social, com preview qualitativa: 'seguro, lento', 'rápido, arriscado', 'tenta negociar'. Checagens usam atributos e eixos diferentes; resultado é `sucesso`, `sucesso com custo`, `falha recuperável`.

**Checagem inicial sugerida:** `chance = clamp(10, 95, 70 + 1.2*(atributo_relevante - dificuldade) - 0.30*estresse - 0.25*lesao_percentual + bonus_suporte)`; percentuais ajustáveis. `lesao_percentual = injury_level * 20`. Evitar que sorte sozinha decida final: flags decisivas e acumulação de escolhas têm peso maior. Seeds reproduzíveis para QA.

Missão da semana 8 — **O Observatório Silencioso**: resgatar pesquisadores presos na instalação sob Ruptura; salvar civis, coletar dados e evacuar com segurança são três objetivos parcialmente conflitantes. O jogador pode negociar com a direção por recursos ou agir com autonomia. As consequências alteram equipe, reputação e acesso a documentos no ato seguinte.

Missão final — **O Protocolo Zero**: a direção planeja sacrificar a instalação para ocultar o fenômeno; as personagens discordam sobre o que proteger. Três resoluções possíveis: obedecer mas exigir evacuação, desobedecer para salvar a instalação, divulgar protocolo para obter apoio externo. A resolução da crise depende de preparo, aliados e flags, não de um simples botão final.

## 7. Conteúdo narrativo

**Arcos compartilhados:** semanas 1–4 adaptação e amizade; 5–8 especialização e resgate; 9–12 descobrir ocultação; 13–16 decidir o que significa ser herói. Cada personagem tem 5 nós dramáticos, 2–4 cenas menores e 4 finais. Uma cena tem: objetivo dramático, gatilho testável, conflito, voz, escolhas, efeitos, aftermath e cooldown.

**CORREÇÃO v0.2 (canônica):** Hori é social/animada, tem núcleo perigoso, problemas de reconhecimento facial e voz de outra versão; Luppi é garota-rato autista oriunda de experimento, lutadora, com referências a jogos e vínculo com professoras; Ray é alta/forte/com chifres mutados e busca renda para o orfanato e amigas enfermas. Ver `docs/05_CANONE_PERSONAGENS.md` e `docs/06_ROTAS_E_MECANICAS.md`. Todas as caracterizações v0.1 divergentes estão REVOGADAS.

**Finais** não são apenas nota S/B/C: três dimensões são calculadas separadamente: carreira, destino pessoal, vínculo da equipe. `career_tag` depende de especialização/missões; `personal_tag` depende de eixos e flags; `team_tag` depende de relações e decisão coletiva. O resultado tem epílogo composto. Precedência explícita evita resultados impossíveis: consequencia fatal/afastamento (se houver) > decisão irreversível > carreira > vínculo; a versão MVP deve evitar morte arbitrária.

## 8. Diálogo e naturalidade

**Regra:** personagem fala por objetivo, não como porta-voz da moral. Cada voz possui gestos, metáforas, frases que evitaria, uso de humor e silêncios. Ao escrever, construir cenas em quatro passes:
1) fato/objetivo da cena e emoção escondida;
2) primeira versão da fala;
3) editor de continuidade e humanização, sem inventar novas informações;
4) leitura em voz alta e QA de gatilhos/efeitos.

**Exemplo ilustrativo** (não é diálogo canônico):
- Hori: 'A missão foi um sucesso.'
- Instrutor: 'Você passou a noite na enfermaria.'
- Hori: 'E ninguém ficou para trás.'
- Instrutor: 'Você também conta como alguém, Hori.'
- Hori: '(desvia o olhar) ...Eu sei. Só esqueço disso quando começa.'

**Evitar:** todos falam em mensagens de coaching, elogios artificiais, frases excessivamente líricas, exposição sem conflitos, três escolhas obviamente boa/neutra/má.

## 9. Telas e acessibilidade

1. Menu de campanha/personagem; 2. painel semanal; 3. detalhes do treino (prévia real); 4. diálogo com log e replay; 5. diário/objetivos; 6. missão; 7. status/relacionamentos; 8. relatório/epílogo. UI desktop 16:9, responsiva até 1366×768, suporte a teclado e controle futuramente. Texto escalável, contraste verificado, botões com descrição de ação, opção de reduzir movimentos, confirmação antes de ações irreversíveis.

## 10. Arquitetura recomendada

**Engine:** Godot 4.x + GDScript tipado. Por você já conhecer Godot, evita recomeçar em stack desnecessária; Godot permite exportar protótipo Windows e Web (testar limitações). Caminho do projeto: `res://`; saves versionados em `user://`.

**Cenas:** `MainMenu`, `CampaignSelect`, `AcademyDashboard`, `TrainingChoice`, `DialogueScene`, `MissionScene`, `EndingScene`.

**Serviços:** `GameState` autoload (estado e seed), `CalendarService` (turnos), `TrainingService` (regras puras), `EventDirector` (gatilhos sem efeito colateral ao consultar), `MissionResolver`, `EndingResolver`, `SaveService` (migração). Evite mega-script único.

**Dados JSON:** `characters`, `activities`, `events`, `endings`; colocar os diálogos em arquivo próprio por personagem quando crescer. Não interpretar texto como código. IDs estáveis, versionamento de save, schema validado por testes. Data separada de regras para IA roteirista não precisar tocar código.

## 11. Balanceamento e UX

Testes mínimos: nunca permitir 101/100 ou negativos; sem softlock quando dinheiro/energia zero; falha do treino recuperável; 100 simulações com seeds fixas devem produzir mais de uma trajetória viável; feedback sobre motivo de final; nenhum final preso a flag inacessível; troca de idioma não altera flags; salvar/carregar preserva seed e decisões; repetir mesma seed + escolhas produz mesmo resultado. Mensagens da UI devem explicar consequência observável, não expor spoilers de flag.

## 12. Não fazer no MVP

Sem gacha; sem batalhas em grid; sem três personagens simultaneamente sob controle completo; sem dublagem em massa; sem 3D; sem multiplayer; sem geração de diálogos pela API em runtime; sem engine customizada; sem banco SQL; sem integração de APIs pagas; sem copiar personagens ou elementos identificáveis das franquias.

## 13. Fontes e grau de certeza

- **Confirmado na documentação comunitária:** Uma Musume 72 turnos regulares + 6 finais para URA, cinco atributos, treinamento de suporte, energia, humor, condições, herança e corrida. https://umamusu.wiki/Scenario
- **Confirmado com ressalvas de versões:** Princess Maker 2 atributos múltiplos, agenda, trabalho e finais por precedência estatística; guias de comunidade podem divergir entre versões. https://steamcommunity.com/sharedfiles/filedetails/?id=771709910
- **Projeto original / hipótese:** todos os valores, nomes, personagens rascunhados, campanhas, scripts, fórmulas e quantitativos acima.

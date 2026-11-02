# HERO TRAINER — ROTA NARRATIVA DE HORI — v1.0
## "Sorrisos em Rosto Desconhecido"

**Status:** rascunho para revisão do autor. Não sobrescreve `05_CANONE_PERSONAGENS.md`, `06_ROTAS_E_MECANICAS.md` nem os JSONs existentes.
**Precedência seguida:** cânone confirmado (01/11/2026) > decisões aprovadas > propostas já documentadas > proposta nova desta entrega (marcada como **[PROPOSTA]**).

---

## 1. FICHA DE VOZ

**Hori** fala rápido, interrompe a si mesma, muda de assunto quando o assunto aperta. Gosta de dar apelidos, de exagerar histórias pequenas, de rir primeiro e pensar depois. Não é ingênua — ela sabe exatamente quando está desviando, e às vezes deixa isso transparecer de propósito, quase como uma piada interna que só ela entende. Não explica os próprios sentimentos em voz alta; mostra por ação (troca de assunto brusca, silêncio mais longo que o normal, um gesto de cuidado sem anúncio). Quando a guarda cai, cai rápido e sem aviso — uma frase seca no meio de uma piada — e ela recolhe de novo quase na mesma respiração.

Evitar: monólogos sobre o próprio sofrimento, metáforas poéticas sobre "máscaras" repetidas em toda cena, falas que soem como ela estivesse em terapia.

**Luppi [PROPOSTA — já canônica em personalidade, voz ainda sendo calibrada]:** frases curtas, diretas, às vezes literais demais. Referências a jogos como forma de traduzir uma situação complexa em algo que ela processa bem ("é tipo um chefe de fase que some quando você olha pro HUD"). Não ironiza; quando percebe sarcasmo alheio, costuma nomear isso em voz alta ("isso foi sarcasmo?"). Fiel à cadeia de comando, mas não muda: seu respeito à ordem é genuíno, não submissão vazia.

**Instrutor:** competente, sem tom de terapeuta. Dá espaço, mas cobra coerência. Não tem sempre a resposta certa — pode errar o tom, pode ser corrigido pela própria Hori.

**Ray [PROPOSTA mínima]:** aparece como NPC nesta rota só em falas curtas e funcionais; personalidade verbal não definida pelo autor, então nenhuma fala sua aqui tenta caracterizá-la além do estabelecido (força física, prioridade nas crianças do orfanato).

---

## 2. ESTRUTURA DE 16 SEMANAS (ROTA HORI)

| Semana | Conteúdo | Tipo |
|---|---|---|
| 1–2 | `hori_face_clues_w02` — Um rosto conhecido? | Relacional |
| 3–4 | `hori_core_protocol_w03` — Protocolo de contenção | Principal |
| 5 | `hori_dorm_party_w05` — A festa não parou | Relacional |
| 6–7 | `hori_academy_audit_w06` — Inspeção de protocolos | Mundo |
| 8 | Missão "Observatório Silencioso" (3 etapas) | Missão intermediária |
| 9–10 | `hori_luppi_strategy_w09` — Plano de duas | Relacional |
| 11 | `hori_echo_confrontation_w11` — A outra voz | Principal |
| 12–13 | `hori_rupture_investigation_w12` — O que a academia sabia | Mundo |
| 14–15 | `hori_ray_aftermath_w14` — O que ficou da missão | Relacional |
| 16 | Resolução — final atribuído por flags/eixos/relações | Encerramento |

---

## 3. OS OITO EVENTOS

### 3.1 `hori_face_clues_w02` — "Um rosto conhecido?" (Relacional)

1. **ID:** `hori_face_clues_w02`
2. **Título:** Um rosto conhecido?
3. **Semana mínima/máxima:** 1–2
4. **Categoria:** relacional
5. **Prioridade:** 50
6. **Condições de ativação:** `flags.hori_face_clues_w02_seen == false`
7. **Objetivo dramático:** mostrar, de leve, a dificuldade de Hori sem transformar a cena em diagnóstico — e deixar o jogador decidir o quanto insiste no assunto.
8. **Contexto anterior:** primeira semana de convivência; o jogador ainda não sabe quase nada sobre o núcleo ou a voz.
9. **Diálogo completo:**
   - HORI: "Pera, você mudou o cabelo? Ficou bom."
   - AMIGA (Tama, NPC genérica): "Hori... sou eu de ontem. Não mudei nada."
   - HORI: "Eu sei disso! Só tava... testando se você notava que eu notei."
   - AMIGA: "Isso nem faz sentido."
   - HORI: "Faz, sim. Só não pra você."
   - *(A amiga ri, meio sem jeito, e muda de assunto. Hori relaxa visivelmente quando o assunto muda.)*
10. **Escolhas (3):**
    - **A — "Perguntar, com cuidado, que sinais ajudam Hori a reconhecer as pessoas."**
      Vantagem: abre caminho para ferramentas práticas (voz, roupa, gestos combinados). Custo: Hori fica levemente desconfortável por ser confrontada diretamente, mesmo gentilmente.
      Mecânica: `axes_delta.solidarity +6`; `route_state_delta.identification_aids_progress +1` (ver seção de schema); `resources_delta.stress +2`.
      Flags: `hori_face_clues_w02_seen=true`, `hori_identification_aid_offered=true`.
    - **B — "Deixar passar e conversar sobre outra coisa."**
      Vantagem: preserva a leveza do momento, Hori sente que não precisa se explicar o tempo todo. Custo: nenhum avanço prático nessa semana.
      Mecânica: `axes_delta.integrity +4`; `resources_delta.mood +3`.
      Flags: `hori_face_clues_w02_seen=true`, `hori_subject_dropped=true`.
    - **C — "Comentar em particular depois, sem plateia."**
      Vantagem: Hori fala mais solta sem a amiga por perto; abre a porta sem pressioná-la na hora. Custo: a amiga nunca fica sabendo o motivo da trapalhada, o que pode gerar um mal-entendido pequeno mais à frente.
      Mecânica: `axes_delta.autonomy +6`; `bonds_delta.instructor +3`.
      Flags: `hori_face_clues_w02_seen=true`, `hori_private_conversation=true`.
11. **Consequências mecânicas:** detalhadas acima por escolha.
12. **Consequências narrativas:** a escolha aqui define o tom das referências futuras à dificuldade de reconhecimento (mais aberta/combinada vs. mais velada) e influencia falas em `hori_dorm_party_w05`.
13. **Flags ativadas:** ver acima.
14. **Eventos posteriores possíveis:** se `hori_identification_aid_offered=true`, uma linha extra de diálogo aparece em `hori_dorm_party_w05` (Hori usa um gesto combinado com uma amiga).
15. **Aftermath:** nenhuma cena extra obrigatória; efeito é apenas registrado em flag/eixo.
16. **Teste de continuidade:** não contradiz cânone (dificuldade de reconhecimento facial, não revela origem nem natureza do núcleo).

---

### 3.2 `hori_core_protocol_w03` — "Protocolo de contenção" (Principal)

1. **ID:** `hori_core_protocol_w03`
2. **Semana:** 3–4
3. **Categoria:** principal
4. **Prioridade:** 90
5. **Condições:** `flags.hori_core_protocol_w03_seen == false`
6. **Objetivo dramático:** primeira menção direta e concreta ao núcleo, sem dramatizar excessivamente — tratado como procedimento, não como tragédia iminente.
7. **Contexto anterior:** Hori já demonstrou ser sociável e evasiva; esta é a primeira vez que o jogador vê o lado técnico/perigoso de frente.
8. **Diálogo completo:**
   - INSTRUTOR: "Hoje revisamos seu protocolo de contenção. É rotina."
   - HORI: "Rotina assustadora, mas tudo bem, eu topo."
   - INSTRUTOR: "Se alguma coisa parecer instável, você avisa, não segura sozinha."
   - HORI: "Último lugar que eu seguro sozinha é justamente esse. Juro."
   - *(pausa)*
   - HORI: "...Tá, eu seguro às vezes. Mas eu aviso depois. Quase sempre."
   - INSTRUTOR: "Isso não é a mesma coisa."
   - HORI: "É parecido o suficiente pra mim dormir à noite."
9. **Escolhas (3):**
    - **A — "Treino intensivo de contenção com equipe de confiança por perto."**
      Vantagem: ganho técnico maior, rede de apoio reforçada. Custo: estresse sobe, exposição da dificuldade de Hori a mais pessoas.
      Mecânica: `stats_delta.tec +4`, `route_state_delta.core_stability +8`, `route_state_delta.trusted_network +5`, `resources_delta.stress +6`.
      Flags: `hori_core_protocol_w03_seen=true`, `hori_core_team_protocol=true`.
    - **B — "Prática controlada só com especialistas, em ambiente fechado."**
      Vantagem: ganho técnico sólido e mais discrição. Custo: menos gente sabe o que fazer se algo falhar fora do laboratório.
      Mecânica: `stats_delta.sin +4`, `route_state_delta.core_stability +10`, `axes_delta.integrity +4`, `route_state_delta.trusted_network -2`.
      Flags: `hori_core_protocol_w03_seen=true`, `hori_core_lab_protocol=true`.
    - **C — "Apresentar as opções e deixar Hori decidir o ritmo."**
      Vantagem: reforça autonomia, Hori se sente ouvida. Custo: progresso técnico menor nesta semana (ela escolhe ir com calma).
      Mecânica: `axes_delta.autonomy +8`, `route_state_delta.core_stability +4`, `bonds_delta.instructor +4`.
      Flags: `hori_core_protocol_w03_seen=true`, `hori_core_agency=true`.
10. **Consequências narrativas:** define o "estilo" do protocolo de Hori para a missão da semana 8 (equipe vs. laboratório vs. ritmo próprio) e para o evento de contenção que pode citar essa escolha.
11. **Flags:** ver acima.
12. **Eventos posteriores possíveis:** `hori_core_team_protocol` facilita requisito de equipe na Etapa 2 da missão; `hori_core_lab_protocol` melhora chance técnica na mesma etapa; `hori_core_agency` concede opção de diálogo extra na Etapa 1.
13. **Aftermath:** linha curta na semana seguinte (não é evento separado): Hori comenta de passagem como foi o treino, reforçando o tom escolhido.
14. **Teste de continuidade:** não define a natureza do núcleo nem da voz; trata estabilidade física como sistema isolado, conforme `06_ROTAS_E_MECANICAS.md`.

---

### 3.3 `hori_dorm_party_w05` — "A festa não parou" (Relacional)

1. **ID:** `hori_dorm_party_w05`
2. **Semana:** 5
3. **Categoria:** relacional
4. **Prioridade:** 40
5. **Condições:** `flags.hori_dorm_party_w05_seen == false`
6. **Objetivo dramático:** cena genuinamente leve — Hori brincalhona, social, no seu ambiente — com uma rachadura pequena no fim, sem virar o foco da cena inteira.
7. **Contexto anterior:** depois do primeiro treino de contenção, Hori volta à rotina social normal.
8. **Diálogo completo:**
   - HORI: "Eu disse que ia trazer o jogo de cartas e eu trouxe o jogo de cartas."
   - AMIGA 2: "Você trouxe o jogo errado de novo."
   - HORI: "É o mesmo conceito! Cartas! Números! Decepção coletiva!"
   - *(risos; o grupo joga por um tempo; Hori ganha, comemora alto demais, erra o nome de alguém no meio da comemoração e corrige sozinha rápido, sem drama, como quem já tem um método pra isso)*
   - HORI (baixo, só pro instrutor, se ele estiver por perto): "Peguei rápido dessa vez, né?"
   - INSTRUTOR: "Peguei."
   - HORI: "Não conta pra ninguém que eu tava contando os pontos pra saber quem tava on."
9. **Escolhas (3):**
    - **A — "Comentar com uma amiga próxima sobre a dificuldade de Hori, com a permissão dela."**
      Vantagem: rede de apoio cresce de forma combinada. Custo: Hori precisa topar antes — se `hori_subject_dropped=true` do evento 1, esta opção vem com um diálogo extra de hesitação dela.
      Mecânica: `route_state_delta.trusted_network +8`, `axes_delta.solidarity +5`.
      Flags: `hori_dorm_party_w05_seen=true`, `hori_friend_informed=true`.
    - **B — "Preservar a privacidade de Hori e deixar o momento ser só diversão."**
      Vantagem: a noite continua leve, sem peso extra. Custo: nenhuma ferramenta nova de apoio nessa semana.
      Mecânica: `resources_delta.mood +6`, `resources_delta.stress -4`.
      Flags: `hori_dorm_party_w05_seen=true`, `hori_privacy_preserved=true`.
    - **C — "Sugerir, de leve, um sistema combinado entre as amigas (apelidos, acessório, gesto)."**
      Vantagem: avança `identification_aids` de forma prática e integrada à vida social. Custo: exige que o grupo todo esteja combinado, o que pode falhar se ninguém levar a sério.
      Mecânica: `route_state_set.identification_aids = true` (se `hori_identification_aid_offered=true` do evento 1; caso contrário, apenas `route_state_delta.identification_aids_progress +1`), `axes_delta.integrity +4`.
      Flags: `hori_dorm_party_w05_seen=true`, `hori_group_system_proposed=true`.
10. **Consequências narrativas:** reforça (ou não) a existência de uma rede combinada; alimenta diálogo em `hori_luppi_strategy_w09` se `hori_friend_informed=true`.
11. **Aftermath:** nenhuma cena extra obrigatória.
12. **Teste de continuidade:** a cena é majoritariamente leve, conforme pedido no brief (momento de alegria genuína, erro social tratado sem peso dramático).

---

### 3.4 `hori_academy_audit_w06` — "Inspeção de protocolos" (Mundo)

1. **ID:** `hori_academy_audit_w06`
2. **Semana:** 6–7
3. **Categoria:** mundo
4. **Prioridade:** 60
5. **Condições:** `flags.hori_academy_audit_w06_seen == false`
6. **Objetivo dramático:** mostrar a instituição como força com interesses próprios (não vilã automática, não aliada incondicional); Hori reage como "caso de estudo" e isso a incomoda sem virar discurso.
7. **Contexto anterior:** depois do primeiro treino formal de contenção, a academia revisa os protocolos de segurança de todos os cadetes com anomalias registradas.
8. **Diálogo completo:**
   - OFICIAL DE AVALIAÇÃO (NPC genérico): "Precisamos atualizar o arquivo de risco da cadete Hori."
   - HORI: "'Arquivo de risco.' Adoro meu título de trabalho."
   - OFICIAL: "É procedimento padrão."
   - HORI: "Padrão pra quem tem um negócio perigoso dentro do peito, você quer dizer."
   - INSTRUTOR: "Ninguém aqui te chamou de perigosa."
   - HORI: "Não precisaram. Tem uma pasta com meu nome que já fala por eles."
   - *(silêncio curto; Hori força um sorriso e muda de assunto rápido demais pra ser natural)*
9. **Escolhas (3):**
    - **A — "Exigir que Hori participe da reunião de avaliação, com voz ativa."**
      Vantagem: reputação institucional de Hori melhora, ela ganha controle sobre a própria narrativa oficial. Custo: expõe mais detalhes dela ao sistema formal da academia.
      Mecânica: `resources_delta.reputation +6`, `axes_delta.autonomy +6`, `route_state_delta.echo_pressure +3` (expor-se é desgastante).
      Flags: `hori_academy_audit_w06_seen=true`, `hori_had_voice_in_review=true`.
    - **B — "Negociar discrição, mantendo o arquivo mínimo necessário."**
      Vantagem: menos exposição institucional. Custo: menos recursos formais disponíveis depois (ex.: suporte oficial em crises).
      Mecânica: `route_state_delta.trusted_network +4`, `resources_delta.reputation -2`, `axes_delta.integrity +4`.
      Flags: `hori_academy_audit_w06_seen=true`, `hori_review_minimized=true`.
    - **C — "Questionar formalmente o tom do processo, em nome da cadete."**
      Vantagem: reforça solidariedade institucional, pode render aliados na administração. Custo: atrito direto com a cadeia de comando, pode gerar consequência política mais tarde.
      Mecânica: `axes_delta.solidarity +6`, `resources_delta.reputation -4`, `bonds_delta.instructor +4`.
      Flags: `hori_academy_audit_w06_seen=true`, `hori_review_challenged=true`.
10. **Consequências narrativas:** alimenta `hori_rupture_investigation_w12` (o jogador descobre mais ou menos sobre o que a academia já sabia, dependendo da escolha aqui).
11. **Aftermath:** nenhuma cena obrigatória extra; impacto fica registrado em flags/reputação.
12. **Teste de continuidade:** a academia não é tratada como vilã automática nem como protetora perfeita, conforme diretriz de balanceamento.

---

### 3.5 `hori_luppi_strategy_w09` — "Plano de duas" (Relacional)

1. **ID:** `hori_luppi_strategy_w09`
2. **Semana:** 9–10
3. **Categoria:** relacional
4. **Prioridade:** 45
5. **Condições:** `flags.hori_luppi_strategy_w09_seen == false`
6. **Objetivo dramático:** mostrar a amizade Hori–Luppi funcionando de um jeito prático e específico (não genérico), cada uma com seu jeito de processar as coisas, sem conflito artificial.
7. **Contexto anterior:** preparo para a continuação da missão do Observatório (resultado da semana 8 já definido).
8. **Diálogo completo:**
   - LUPPI: "Se a Ruptura reagir como da última vez, seu núcleo vai ficar instável de novo. Isso é um problema de nível difícil."
   - HORI: "Obrigada por reduzir meu trauma a um nível de dificuldade."
   - LUPPI: "Não foi isso que eu quis dizer. Foi mais fácil de explicar assim."
   - HORI: "Relaxa, eu entendi. E tipo... obrigada. Sério."
   - LUPPI: "Eu só preciso saber o seu HP real antes de entrar lá de novo."
   - HORI: "Meu HP real é 'aceitável com reservas'. Pode anotar isso."
9. **Escolhas (3):**
    - **A — "Compartilhar com Luppi, em detalhe, o estado atual do núcleo."**
      Vantagem: Luppi planeja com dados reais, aumenta eficiência futura da equipe. Custo: Hori precisa se abrir mais do que de costume.
      Mecânica: `bonds_delta.luppi +10`, `route_state_delta.honesty_to_friends +6`, `resources_delta.stress +3`.
      Flags: `hori_luppi_strategy_w09_seen=true`, `hori_opened_up_to_luppi=true`.
    - **B — "Resumir o essencial e manter o resto em privado."**
      Vantagem: equilíbrio entre informação e privacidade. Custo: Luppi planeja com margem de segurança maior (menos otimizado).
      Mecânica: `bonds_delta.luppi +5`, `axes_delta.integrity +3`.
      Flags: `hori_luppi_strategy_w09_seen=true`, `hori_summarized_for_luppi=true`.
    - **C — "Deixar Luppi liderar o planejamento tático sem entrar em detalhes pessoais."**
      Vantagem: reforça a competência de Luppi, Hori mantém controle sobre o que revela. Custo: vínculo cresce menos nesta cena.
      Mecânica: `bonds_delta.luppi +3`, `axes_delta.autonomy +5`, `stats_delta.sin +2` (coordenação tática).
      Flags: `hori_luppi_strategy_w09_seen=true`, `hori_kept_distance_tactical=true`.
10. **Consequências narrativas:** `hori_opened_up_to_luppi=true` melhora uma condição de apoio na Etapa 2/3 se ainda houver missão ativa, e reforça requisito do final `hori_team_guardian`.
11. **Aftermath:** nenhuma cena extra obrigatória.
12. **Teste de continuidade:** Luppi mantém sua voz referencial a jogos sem virar piada única; não resolve nem explica o autismo dela, apenas mostra seu jeito de processar.

---

### 3.6 `hori_echo_confrontation_w11` — "A outra voz" (Principal)

1. **ID:** `hori_echo_confrontation_w11`
2. **Semana:** 11
3. **Categoria:** principal
4. **Prioridade:** 95
5. **Condições:** `flags.hori_echo_confrontation_w11_seen == false` **E** `route_state.echo_pressure >= 25` (se a pressão estiver baixa, o evento é adiado automaticamente para a janela 11–12 via `trigger` alternativo — documentado na seção de lacunas).
6. **Objetivo dramático:** primeiro confronto narrativo direto com a voz. Não revela a natureza definitiva dela — apresenta uma proposta tentadora e deixa a cena ambígua, como pedido no cânone.
7. **Contexto anterior:** acúmulo de pressão (`echo_pressure`) ao longo das semanas anteriores, especialmente se `hori_had_voice_in_review=true` (mais exposição = mais pressão).
8. **Diálogo completo:**
   - *(Hori está sozinha, tarde da noite, terminando um relatório. A voz aparece — não como narração onisciente, mas como uma fala que Hori ouve e responde, ambiguamente real.)*
   - VOZ: "Você podia simplesmente parar de fingir que está tudo bem."
   - HORI: "Eu não tô fingindo. Eu tô... administrando."
   - VOZ: "Seria mais fácil se você parasse de administrar."
   - HORI: "Mais fácil pra quem?"
   - *(pausa longa)*
   - VOZ: "Pra nós duas."
   - HORI: "Você fala como se a gente fosse time. A gente não é time."
   - VOZ: "Ainda não."
   - *(Hori ri, mas não é um riso de verdade.)*
   - HORI: "Isso foi dramático até pros seus padrões."
9. **Escolhas (3):**
    - **A — "Recusar o diálogo com a voz e pedir apoio imediato (instrutor/equipe)."**
      Vantagem: reduz pressão imediata, reforça rede de confiança. Custo: a questão fica sem resposta, pode voltar com mais força depois.
      Mecânica: `route_state_delta.echo_pressure -10`, `route_state_delta.trusted_network +6`, `axes_delta.solidarity +4`.
      Flags: `hori_echo_confrontation_w11_seen=true`, `hori_refused_echo=true`.
    - **B — "Engajar com a voz, tentando entender o que ela realmente propõe."**
      Vantagem: Hori ganha mais clareza interna (mecânica: leve ganho de `sin`), avança o mistério sem resolvê-lo. Custo: pressão aumenta no curto prazo.
      Mecânica: `route_state_delta.echo_pressure +8`, `stats_delta.sin +3`, `axes_delta.ambition +3`.
      Flags: `hori_echo_confrontation_w11_seen=true`, `hori_engaged_echo=true`.
    - **C — "Cortar a conversa e não contar a ninguém o que aconteceu."**
      Vantagem: controle total da narrativa pessoal nesse momento. Custo: honestidade com as amigas cai, isolamento aumenta levemente.
      Mecânica: `route_state_delta.honesty_to_friends -8`, `route_state_delta.echo_pressure +4`, `axes_delta.autonomy +4`.
      Flags: `hori_echo_confrontation_w11_seen=true`, `hori_hid_echo_event=true`.
10. **Consequências narrativas:** esta escolha pesa diretamente nos finais — `hori_hid_echo_event=true` favorece `hori_overburdened`; `hori_refused_echo=true` favorece `hori_team_guardian`; `hori_engaged_echo=true` favorece `hori_independent`.
11. **Aftermath:** linha curta na cena seguinte (`hori_rupture_investigation_w12`) referenciando o estado emocional de Hori, sem repetir a cena.
12. **Teste de continuidade:** a voz não é confirmada como vilã, consciência independente ou origem energética — mantém-se ambígua, conforme cânone.

---

### 3.7 `hori_rupture_investigation_w12` — "O que a academia sabia" (Mundo)

1. **ID:** `hori_rupture_investigation_w12`
2. **Semana:** 12–13
3. **Categoria:** mundo
4. **Prioridade:** 55
5. **Condições:** `flags.hori_rupture_investigation_w12_seen == false`
6. **Objetivo dramático:** expandir o mundo (Rupturas, decisões institucionais) sem resolver o mistério pessoal de Hori; mostrar que a academia tinha informação parcial e decisões imperfeitas, não uma conspiração clara.
7. **Contexto anterior:** resultado da missão do Observatório já conhecido; tensão da cena anterior (echo) ainda ecoando.
8. **Diálogo completo:**
   - PESQUISADORA (NPC): "Os registros da Ruptura do Observatório batem parcialmente com o perfil do seu núcleo."
   - HORI: "'Parcialmente' é uma palavra generosa pra 'a gente não sabe'."
   - PESQUISADORA: "É uma palavra honesta pra 'ainda estamos analisando'."
   - HORI: "Analisando há quanto tempo?"
   - *(a pesquisadora não responde imediatamente — e isso diz mais do que qualquer resposta diria)*
9. **Escolhas (3):**
    - **A — "Pressionar por acesso completo aos registros."**
      Vantagem: mais informação de mundo, ganho de `teo`. Custo: atrito institucional, reputação cai um pouco.
      Mecânica: `stats_delta.teo +5`, `resources_delta.reputation -3`, `axes_delta.ambition +4`.
      Flags: `hori_rupture_investigation_w12_seen=true`, `hori_pressed_for_records=true`.
    - **B — "Aceitar o que for compartilhado voluntariamente, sem forçar."**
      Vantagem: mantém relação institucional estável. Custo: menos informação de mundo revelada agora.
      Mecânica: `resources_delta.reputation +2`, `axes_delta.integrity +3`.
      Flags: `hori_rupture_investigation_w12_seen=true`, `hori_accepted_partial_info=true`.
    - **C — "Compartilhar a própria experiência da Ruptura para ajudar a pesquisa, em troca de transparência."**
      Vantagem: fortalece `trusted_network` com a própria instituição, reforça agência de Hori sobre sua narrativa. Custo: mais exposição pessoal registrada oficialmente.
      Mecânica: `route_state_delta.trusted_network +6`, `route_state_delta.honesty_to_friends +4`, `resources_delta.reputation +4`.
      Flags: `hori_rupture_investigation_w12_seen=true`, `hori_traded_info_for_transparency=true`.
10. **Consequências narrativas:** alimenta o epílogo do final (quanto a academia "sabe" oficialmente sobre Hori no fim da campanha).
11. **Aftermath:** nenhuma cena extra obrigatória.
12. **Teste de continuidade:** não resolve a origem do núcleo nem da Ruptura original; mantém lacuna identificada no cânone.

---

### 3.8 `hori_ray_aftermath_w14` — "O que ficou da missão" (Relacional)

1. **ID:** `hori_ray_aftermath_w14`
2. **Semana:** 14–15
3. **Categoria:** relacional
4. **Prioridade:** 45
5. **Condições:** `flags.hori_ray_aftermath_w14_seen == false`
6. **Objetivo dramático:** fechar o arco relacional com Ray antes do final, mostrando consequência concreta da missão (sucesso, custo ou fracasso recuperável) sobre a amizade.
7. **Contexto anterior:** depende do resultado da missão (`flags.final_mission_success` ou variantes de etapa).
8. **Diálogo completo (base, varia por flag de missão):**
   - RAY: "Você carregou peso demais lá dentro."
   - HORI: "Eu carrego peso o tempo todo, Ray. Isso foi terça-feira."
   - RAY: "Não brinca com isso."
   - HORI: "Eu brinco com tudo. É assim que eu seguro."
   - *(Ray não responde de imediato — só fica ali, o que de alguma forma funciona melhor do que uma resposta.)*
   - HORI: "...Obrigada por ficar por perto, lá dentro."
   - RAY: "Sempre vou ficar."
9. **Escolhas (3):**
    - **A — "Reconhecer abertamente o esforço de Ray na missão, em público."**
      Vantagem: reputação de Ray cresce dentro da equipe, vínculo fortalece. Custo: nenhum relevante.
      Mecânica: `bonds_delta.ray +10`, `axes_delta.solidarity +4`.
      Flags: `hori_ray_aftermath_w14_seen=true`, `hori_credited_ray_publicly=true`.
    - **B — "Conversar em particular sobre o que cada uma sentiu durante a missão."**
      Vantagem: aprofunda honestidade mútua. Custo: expõe vulnerabilidade de Hori a mais uma pessoa.
      Mecânica: `bonds_delta.ray +7`, `route_state_delta.honesty_to_friends +6`.
      Flags: `hori_ray_aftermath_w14_seen=true`, `hori_opened_up_to_ray=true`.
    - **C — "Focar em seguir em frente, sem reabrir a missão em detalhes."**
      Vantagem: menos desgaste emocional nesta semana. Custo: vínculo cresce menos, Ray pode sentir que o assunto ficou pela metade.
      Mecânica: `bonds_delta.ray +3`, `resources_delta.stress -5`.
      Flags: `hori_ray_aftermath_w14_seen=true`, `hori_moved_on_quickly=true`.
10. **Consequências narrativas:** peso direto no final `hori_team_guardian` (exige `bonds.ray >= 45`).
11. **Aftermath:** leva direto à resolução da semana 16.
12. **Teste de continuidade:** Ray não ganha personalidade verbal fixa além do estabelecido (força, presença, prioridade nas crianças do orfanato, implícita aqui sem detalhar).

---

## 4. MISSÃO INTERMEDIÁRIA — "OBSERVATÓRIO SILENCIOSO" (3 ETAPAS)

Ver arquivo `missions_hori_draft.json` para a estrutura mecânica completa. Resumo narrativo:

**Contexto:** uma Ruptura isolada se abre perto de um posto de observação da academia, com pesquisadores presos dentro. Hori, Luppi e Ray (NPCs na rota de Hori) são destacadas.

- **Etapa 1 — Reconhecimento:** avaliar o perímetro, decidir entre avançar rápido, avançar com cautela, ou pedir reforço institucional antes de entrar.
- **Etapa 2 — Ação central:** decisão sobre como lidar com a Ruptura — estabilizar o núcleo de Hori para conter a energia de perto, apoiar a extração dos pesquisadores primeiro, ou dividir a equipe entre as duas tarefas.
- **Etapa 3 — Extração:** proteger os envolvidos e sair; a forma como as etapas anteriores foram resolvidas determina o custo da saída (ninguém ferido / ferimento leve recuperável / custo relacional).

**Habilidade especial de Hori — "Pulso de Contenção" [PROPOSTA]:**
- **Condição de desbloqueio:** `route_state.core_stability >= 55` OU `hori_core_team_protocol=true` (do evento 3.2).
- **Efeito:** na Etapa 2, Hori pode usar o núcleo de forma controlada para estabilizar a Ruptura por conta própria — opção de alto risco/alto ganho: sucesso reduz drasticamente o dano à equipe e aumenta `trusted_network`; falha reduz `core_stability` temporariamente e aumenta `echo_pressure`.
- Não é uma árvore de habilidades — é uma única opção condicional disponível na Etapa 2.

---

## 5. OS QUATRO FINAIS

Ver `endings_hori_draft.json` para condições exatas em formato de schema. Resumo narrativo abaixo.

### 5.1 `hori_guardian_command` — "Comando sob controle"
**Como alcançar:** atributos técnicos/físicos altos (`pot>=55`, `res>=50`), reputação alta (`reputation>=35`) e missão bem-sucedida.
**Epílogo (resumo):** Hori assume um papel formal de comando em protocolos de contenção. É competente, reconhecida oficialmente — mas o epílogo nota, sem punir, que boa parte do crescimento veio do lado técnico/institucional, deixando o lado social um pouco em segundo plano.
**Consequências:** Luppi se torna parceira tática recorrente de missões formais; Ray segue carreira própria, contato mantido mas mais espaçado.

### 5.2 `hori_team_guardian` — "Ninguém sozinha"
**Como alcançar:** `solidarity>=15`, vínculos altos com Luppi e Ray (`>=45` cada), missão bem-sucedida.
**Epílogo (resumo):** Hori continua na linha de frente, mas nunca sozinha — o protocolo dela é, por definição, um protocolo de equipe. É o final mais "quente": amizades sólidas, rede de apoio ativa, núcleo estável por causa da rede, não apesar dela.
**Consequências:** Luppi e Ray seguem como parceiras fixas de missão; a amizade das três se torna conhecida informalmente na academia.

### 5.3 `hori_independent` — "Com as próprias regras"
**Como alcançar:** `autonomy>=15` e missão ao menos tentada (`final_mission_attempted=true`, sucesso não obrigatório).
**Epílogo (resumo):** Hori negocia um caminho próprio — menos vinculado à estrutura de comando tradicional, mais vinculado às próprias decisões sobre quando se expor, quando pedir ajuda, quando trabalhar sozinha. Não é isolamento: é controle.
**Consequências:** relação com a academia fica mais distante mas respeitosa; vínculos pessoais variam conforme escolhas anteriores, sem exigência fixa.

### 5.4 `hori_overburdened` — "O peso que ela carrega sorrindo"
**Como alcançar:** fallback — missão tentada, mas sem atingir os limiares dos outros três finais (ex.: `hori_hid_echo_event=true` e vínculos/eixos baixos).
**Epílogo (resumo):** agridoce, não trágico. Hori segue adiante, ainda sorridente, ainda competente — mas boa parte do peso continua invisível pra quem está ao redor, porque ela nunca deixou aparecer. O jogo termina sugerindo que isso é sustentável por enquanto, não necessariamente para sempre. **Não é punição por ouvir a voz ou por ter dificuldade de reconhecimento facial** — é consequência específica de ter escondido informação repetidamente, reversível em uma eventual continuação.
**Consequências:** Luppi e Ray seguem presentes, mas com menos acesso real ao que Hori sente; o epílogo deixa a porta aberta, não fechada.

---

## 6. CONTINUIDADE E LACUNAS DE CÂNONE

**Não inventado nesta entrega (fica para o autor confirmar):**
- Natureza definitiva da voz (origem energética / consciência própria / experiência subjetiva) — tratada como ambígua em `hori_echo_confrontation_w11`.
- Identidade e nome de "Tama" (amiga genérica usada no evento 3.1) — nome provisório, substituível.
- Detalhes do acidente anterior em que Hori feriu amigas — não mencionado em diálogo, só referenciado indiretamente via cânone existente.
- Limite exato de `echo_pressure` para forçar o evento 3.6 antes da semana 11, caso o jogador não acumule pressão suficiente — proposta de trigger alternativo sinalizada na ficha do evento, não implementada em detalhe.

**Verificação da auditoria de qualidade (seção 14 do prompt):**

| # | Pergunta | Resultado |
|---|---|---|
| 1 | Todas as 8 cenas têm consequências? | Sim — mecânicas e flags documentadas por escolha. |
| 2 | Todas as escolhas têm efeitos coerentes? | Sim — vantagem/custo explícitos em cada uma. |
| 3 | Referências a flags inexistentes? | Nenhuma identificada; flags novas documentadas no schema (seção 7). |
| 4 | Algum evento depende de algo impossível? | Não — o gatilho condicional de `echo_pressure` no evento 6 tem fallback descrito. |
| 5 | Algum final impossível? | Não — todos os quatro são alcançáveis com combinações distintas de escolhas; `hori_overburdened` é fallback garantido. |
| 6 | Algum evento contradiz o cânone? | Não — natureza da voz e do núcleo seguem não confirmadas. |
| 7 | Personagem mudou de personalidade sem justificativa? | Não — Luppi mantém voz referencial a jogos; Ray permanece sem personalidade verbal fixa. |
| 8 | Diálogos soam naturais? | Revisados para cortar explicações artificiais e metáforas repetidas. |
| 9 | Existem momentos leves? | Sim — eventos 3.1, 3.3, 3.5 e partes do 3.8 são predominantemente leves. |
| 10 | A missão considera decisões anteriores? | Sim — habilidade especial e bônus de etapa dependem de flags dos eventos 3.2 e 3.5. |
| 11 | A dificuldade de Hori é tratada com respeito? | Sim — nunca associada a maldade, nunca é causa direta de punição no final. |
| 12 | Os quatro finais têm diferenças narrativas relevantes? | Sim — tom, relações finais e grau de exposição institucional variam claramente entre eles. |

---

## 7. MUDANÇAS DE SCHEMA PROPOSTAS

Os eventos existentes em `data/events.json` usam `axes_delta`, `bonds_delta`, `resources_delta`, `flags_set`. Esta entrega adiciona, quando necessário:

- `route_state_delta` — ajuste incremental em campos de `route_state` (ex.: `core_stability`, `echo_pressure`, `trusted_network`, `honesty_to_friends`, `identification_aids_progress`).
- `route_state_set` — define um valor absoluto em `route_state` (usado apenas para `identification_aids`, que é booleano).
- `stats_delta` — ajuste incremental em atributos (`pot`, `res`, `tec`, `teo`, `sin`), já presente implicitamente no projeto via atividades, agora formalizado também para eventos narrativos.

Nenhum campo usa código executável. Todas as condições de gatilho usam apenas comparações (`==`, `>=`) sobre caminhos de dado, conforme já praticado em `endings.json`.

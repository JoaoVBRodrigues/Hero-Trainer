# HERO TRAINER — TRÊS ROTAS, SISTEMAS E DESFECHOS — v0.2

**Escopo:** proposta de game design, não canon já existente. Campanha curta de 16 semanas / 3 atividades por semana; primeiro vertical slice utiliza Hori jogável e Ray + Luppi como NPCs com seus próprios eventos. As três rotas só depois de validar o loop.

## 1. ACADEMIA: CONFLITO COMPARTILHADO
A academia prepara cadetes para surtos de energia anômala. A direção distribui recursos, bolsas, missões e ordens. O jogador é um instrutor com limites de autoridade; as protagonistas podem recusar e discordar. A história compartilhada é 'O Semestre da Ruptura'. Na adaptação original, substituir todos os nomes, facções e eventos protegidos por componentes inteiramente autorais.

- Semanas 1–4: adaptação, rotina e apresentação de obrigações pessoais.
- Semanas 5–8: escolha de especialização; crise das instalações; missão conjunta.
- Semanas 9–12: quebra de confiança na instituição; consequências sociais e financeiras.
- Semanas 13–16: prova final; escolhas irreversíveis; epílogo composto.
- Cada personagem deve ter ao menos 1 cena leve para cada cena muito pesada.

## 2. RAY — 'CARTAS QUE ATRAVESSAM O OCEANO'
**Desejo externo:** pagar cuidados e preservar bem-estar das amigas/crianças ligadas ao orfanato.
**Necessidade pessoal proposta:** negociar limites, descanso, apoio e um futuro próprio, sem abandonar os afetos.
**Mecânica:** créditos, remessa, fundo assistencial, bolsas e convênios, custo de oportunidade das missões remuneradas. O suporte ao orfanato não deve ser uma contagem simplória de vida/morte.
**Recursos propostos:** `personal_credits`, `orphanage_fund`, `support_network`, `physical_fatigue`, `ray_self_care`, `ray_honesty_to_friends`.
**Questões:** o trabalho militar é a única fonte viável? A instituição oferece bolsas? As amigas querem um sacrifício tão grande?

| Semana | Evento | Dilema | Consequência |
|---|---|---|---|
| 1 | Primeiro pagamento | mandar tudo ou fazer reserva | liquidez, apoio e disposição |
| 3 | Carta atrasada | procurar notícia ou respeitar limites | informação e relações |
| 6 | Contrato de escolta | pagamento alto e preparo insuficiente | risco, estudo, bolsa |
| 8 | Missão compartilhada | salvar civis e proteger suprimentos | confiança e prova de competência |
| 11 | 'Você também precisa viver' | discussão franca com amiga do orfanato | autonomia e vínculo |
| 15 | Oferta de contrato | carreira, retorno ou rede de apoio | decisão de futuro |

**Finais:** contrato de protetora com estabilidade e apoio; organizadora de rede de assistência; retorno consciente às pessoas queridas; reconhecimento com vínculos negligenciados (agridoce). Não matar as crianças por um limiar arbitrário de dinheiro.

## 3. LUPPI — 'MAIS DO QUE UMA ORDEM'
**Desejo externo:** lutar bem, melhorar e cumprir tarefas de modo competente.
**Necessidade proposta:** desenvolver espaço para decidir, discordar e negociar com mentoras que respeita.
**Mecânica:** suporte de professora em treinos, previsibilidade de agenda, exercícios de ordens incompletas, estratégia com referências a jogos, autonomia de decisão. Sensibilidade sensorial deve ser perfilada com o autor e não ter associação automática com desempenho inferior.
**Recursos propostos:** `mentor_trust`, `command_clarity`, `self_advocacy`, `mission_familiarity`, `sensory_preferences` (opções de contexto, não doença redutível a HP).

| Semana | Evento | Dilema | Consequência |
|---|---|---|---|
| 1 | Simulação de combate | cumprir ordem ou pedir esclarecimento | conhecimento da professora |
| 3 | Jogo de estratégia | proposta tática baseada em referência de jogo | habilidade singular |
| 6 | Treino inesperado | informar mudança / negociar alternativas | suporte respeitoso |
| 8 | Ordem conflitante | proteger objetivo vs socorrer colega | juízo próprio e cadeia de comando |
| 11 | Arquivo experimental | perguntar sobre origem e consentimento | agência e acesso à verdade |
| 15 | Seleção de carreira | escolher especialização com liberdade | destino pessoal |

**Finais:** instrutora de combate; especialista que seleciona missões; defensora de outras cobaias/experimentados; excelente agente cujo reconhecimento institucional não trouxe clareza sobre o que ela própria deseja. NUNCA 'final curada do autismo'.

## 4. HORI — 'SORRISOS EM ROSTO DESCONHECIDO'
**Desejo externo:** proteger amigas, continuar próxima delas, sentir-se normal/alegre.
**Necessidade proposta:** construir protocolos de segurança e relações em que ela possa ser honesta sem precisar abandonar sua alegria.
**Mecânica:** `core_stability` (físico), `echo_pressure` (fantasia/lore), `trusted_network` (relacional), `identification_aids` (ferramentas acessíveis), `honesty_to_friends` (escolhas). Atributos independentes! O evento de crise física depende de `core_stability` e contexto da missão, NÃO do diagnóstico de reconhecimento facial nem da existência da voz.

| Semana | Evento | Dilema | Consequência |
|---|---|---|---|
| 1 | Corredor e confusão de nomes | pedir apoio / disfarçar | vínculo e convenções |
| 3 | Protocolo de contenção | treino intensivo / alternativas seguras | habilidade técnica e estabilidade |
| 5 | Festa no dormitório | compartilhar uma dificuldade ou preservar privacidade | confiança e autonomia |
| 8 | Descontrole sob Ruptura | estabilizar núcleo e coordenar proteção | consequência de treino + escolhas |
| 11 | Debate com a outra Hori | lidar com proposta tentadora | revelação canônica, agência |
| 15 | Decisão sobre a própria vida | continuar, transferir-se, especializar-se | destino pessoal |

**Finais:** controladora de anomalias que preserva sua vida social; heroína especializada em contenção; vida fora da linha de frente com relações fortes; fama com isolamento por ter ocultado necessidades. Não pressupor maldade decorrente das vozes.

## 5. PROTOCOLO DE EVENTO (todas as rotas)
Uma cena precisa registrar: ID estável; `week_min/max`; precondições verificáveis; foco dramático; conhecimento presente de cada personagem; 2–3 escolhas honestamente defensáveis; `effects` determinísticos; feedback; cena subsequente (aftermath); teste de continuidade; revisão de representação.

**Eventos duplos:** mesma missão vista por 3 perspectivas, com 1 objetivo compartilhado e 1 objetivo exclusivo por personagem. Ao treinar Hori, Ray e Luppi aparecem como NPCs cujos vínculos mudam. Evitar escrever 3x a mesma cena.

## 6. DIRETRIZES DE BALANCEAMENTO
- Não criar punição impossível de evitar por apenas uma escolha de descanso.
- Separar `character_state` (capacidade e condição) de `narrative_flags` (história), de `accessibility_preferences` (configuração do jogador).
- Não modelar autismo, prosopagnosia ou vozes como pontuações de moralidade.
- Ter ao menos um evento leve por ato e uma alternativa de apoio institucional para dilemas extremos.
- Finais resultam de fatores múltiplos e flags narrativas, não só de atributo alto.

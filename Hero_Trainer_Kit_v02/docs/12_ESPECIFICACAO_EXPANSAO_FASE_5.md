# HERO TRAINER — Especificação de expansão de conteúdo — Fase 5.0

**Tipo:** planejamento de game design, conteúdo e arquitetura  
**Status:** proposta para aprovação; não implementar  
**Escopo proposto:** seis eventos, dois conceitos de personagem secundário, duas atividades e até três itens/equipamentos  
**Projeto:** Hero Trainer  
**Método:** inspeção estática de código, dados, testes existentes e documentação. Nenhum jogo, teste, simulação ou geração de arte foi executado.

## 1. Resumo executivo

A expansão pode reutilizar o ciclo semanal, os serviços, o estado de campanha, a navegação e os dados declarativos existentes. O projeto já tem relações, recursos, flags narrativas, prévia de atividade, eventos com escolhas e efeitos, além de uma interface programática que cria cartões a partir do catálogo de atividades.

Ainda não há infraestrutura pronta para a expansão completa pretendida:

- `TrainingService` valida um esquema estrito de atividade e não aplica aptidões nem mentoria.
- `NarrativeService` carrega uma rota de rascunho e exige exatamente oito eventos, uma missão e quatro finais.
- `TrainingState` não contém inventário/equipamento, mentor selecionado ou dados de loja.
- Não foi localizado serviço de salvamento em disco.
- A interface de diálogo troca retrato apenas para Hori; falas de outras pessoas não têm retrato próprio.
- Os conceitos atuais de Ray/Luppi em `data/events.json` não são a fonte que `NarrativeService` carrega.

Portanto, seis novos eventos, duas novas atividades, mentores, motivação mecânica, loja/equipamentos e salvamento são compatíveis com o produto, mas exigem decisões de dados e integração antes da implementação. A Fase 5.0 não toma essas decisões nem altera o código.

## 2. Premissas, cânone e dependência da Fase 4C

### 2.1 Precedência

1. Cânone confirmado pelo autor em `05_CANONE_PERSONAGENS.md`.
2. Decisões de sistema explicitamente fornecidas pelo autor.
3. Propostas desta especificação, sempre não canônicas até aprovação.
4. Nenhum improviso da implementação deve ser tratado como novo fato de personagem.

Os valores de atributos, recursos e aptidões em `characters.json` continuam sendo dados de protótipo, não cânone. A pasta `Hori Draft` continua identificada como rascunho; sua integração atual não converte os textos em cânone.

### 2.2 Decisões 4C fornecidas como restrições, não como comportamento já implementado

O briefing da Fase 5.0 lista como direções aprovadas:

- Falha automática da missão após a semana 8.
- Pulso de Contenção determinístico: estabilidade `>= 55` e TEC `>= 30`.
- Influência mecânica da motivação.
- Influência mecânica de aptidões e mentoria.
- Loja, equipamentos e gastos.
- Salvamento em disco no MVP.

Estas direções são tratadas aqui como restrições de produto informadas pelo autor. **Não foi localizado, na documentação atual examinada, um registro específico da Fase 4C que defina todos os contratos de implementação.** A auditoria estática da Fase 4B também descreve motivação, aptidões/mentoria, economia e save como sistemas ainda ausentes e aponta que `is_mission_due` não respeita `week_max`.

Antes das Fases 5.1–5.5, as decisões da Fase 4C precisam ter especificação operacional aprovada: condições exatas, dados gravados, momentos de aplicação, precedência e migração de saves. Esta especificação não tenta preencher essas lacunas.

## 3. Inventário do projeto e reutilização

| Sistema/arquivo | O que existe hoje | Reutilização na Fase 5 | Limitação ou dependência |
|---|---|---|---|
| `scripts/training_state.gd` | Semana, ações, atributos, eixos, estado narrativo, flags, missão, recursos, vínculos e RNG; operações de duplicação/cópia | Manter uma única fonte de verdade para novas escolhas e efeitos | Sem inventário, equipamento, aquisição, mentores ativos ou versão de save |
| `scripts/training_service.gd` | Carrega Hori e catálogo de atividades; prévia, energia, efeitos, risco, caps, RNG e avanço semanal | Reutilizar o fluxo de catálogo, prévia e aplicação | O esquema de atividade é estrito; aptidões e `mentor_affinity` não afetam resultados; bônus de mentoria é placeholder zero |
| `scripts/narrative_service.gd` | Janelas, prioridade, condições, escolhas atômicas, deltas de atributos/recursos/vínculos/eixos/estado de rota e flags; missão e finais | Reutilizar eventos declarativos, flags, efeitos e resultados estruturados | Carrega os arquivos `Hori Draft`; exige exatamente 8 eventos, 1 missão e 4 finais; listas de efeitos e IDs válidos são estritas |
| `scripts/training_dashboard.gd` | Hub, Treinamento, Status, Relações e diálogo construídos principalmente em código; cartões percorrem os IDs do serviço | Acrescentar conteúdo na interface existente, sem criar um segundo estado | Layout atual categoriza quatro tipos conhecidos; integração de loja/inventário e participantes novos precisa de decisão de UX |
| `scripts/training_theme.gd` | Paleta centralizada índigo, azul-petróleo, menta, coral, dourado e creme | Aplicar a componentes de novas telas/cartões | Não é necessário criar nova identidade visual |
| `scenes/training_dashboard.tscn` | Cena principal única | Preservar a inicialização e a navegação | A apresentação de diálogo/caracteres novos é atualmente especializada em Hori |
| `data/activities.json` | 8 atividades, calendário de 16 semanas × 3 blocos e limites | Fonte declarativa para novas atividades | Novas propriedades exigirão atualização coordenada do validador/serviço |
| `data/characters.json` | Hori jogável; Ray e Luppi NPC; aptidões e valores prototípicos | Reutilizar dados de Hori e relações existentes | O serviço seleciona Hori explicitamente; os valores/aptidões de outros personagens não os tornam jogáveis |
| `Hori Draft/events_hori_draft.json` | 8 eventos da rota jogável atual | Referência de formato e efeitos; continuidade de Hori | Validação de contagem fixa impede apenas anexar eventos sem alterar a estratégia de carregamento |
| `data/events.json` | 6 eventos demonstrativos, incluindo conceitos de Ray, Luppi e uma missão compartilhada | Material candidato para revisão e reaproveitamento | `NarrativeService` não lê este arquivo; não mesclar automaticamente com os rascunhos ativos |
| `Hori Draft/missions_hori_draft.json` e `endings_hori_draft.json` | Uma missão de 3 etapas e 4 finais de Hori | Preservar como fonte da campanha atual | Os efeitos e as condições continuam sujeitos aos contratos da Fase 4C |
| `data/endings.json` | Exemplos de finais de mais de uma personagem | Referência de ideias, não implementação ativa comprovada | Não é a fonte de finais carregada pelo `NarrativeService` atual |
| Testes | `test_training_service.gd`, `test_narrative_campaign.gd`, `test_dashboard_presentation.gd` | Expandir regressões de serviço, narrativa e interface quando a implementação for autorizada | Foram lidos estaticamente; nenhum foi executado nesta fase |

### 3.1 Divergência entre fontes narrativas

O projeto contém dois conjuntos de conteúdo que não devem ser confundidos:

- O serviço narrativo atual aponta para `Hori Draft/events_hori_draft.json`, `missions_hori_draft.json` e `endings_hori_draft.json`.
- `data/events.json` contém conteúdo mais amplo/de exemplo, inclusive remessa do orfanato de Ray e ordem de treinamento de Luppi, mas não é o arquivo indicado pelo serviço.

**Decisão necessária antes da Fase 5.1:** escolher se os novos eventos serão incorporados ao conjunto ativo de Hori, se os dados serão separados por rota/campanha ou se haverá uma composição explícita de arquivos. Não copiar nem sobrescrever dados existentes durante a especificação.

## 4. Escopo de conteúdo proposto

As quantidades abaixo são metas de planejamento. Não são limites técnicos nem conteúdo aprovado.

- **6 eventos novos**, em adição aos oito atuais apenas se o autor confirmar esse sentido da meta (o resultado seria 14 eventos na rota de Hori).
- **2 personagens secundários** em fichas conceituais não canônicas.
- **2 atividades novas**, sem valores finais de custo, ganho ou chance.
- **Até 3 equipamentos/itens**, com efeitos conceituais e sem preços finais.
- Nenhuma nova campanha jogável, árvore extensa de habilidades, missão adicional, final novo ou mudança da duração atual é incluída nesta proposta.

### 4.1 Proposta de seis eventos

Os títulos, IDs e efeitos são rascunhos de planejamento. As janelas finais dependem do fechamento da missão na semana 8 e da cadência aprovada.

| ID provisório | Foco e participantes | Cena e função | Requisitos candidatos | Consequências candidatas | Repetição e assets |
|---|---|---|---|---|---|
| `p5_hori_quiet_day` | Hori, Ray, Luppi e amigas/colegas já aprovadas | Momento cotidiano leve após pressão de missão; mostrar Hori sociável e bem-humorada, não apenas em crise | Janela pós-missão; estado da missão definido pela Fase 4C | Flag de cena vista; vínculo/solidariedade apenas se o autor aprovar efeito mecânico | Uma vez; reutilizar sala da academia, com possível ilustração especial se aprovada |
| `p5_hori_support_terms` | Hori e uma colega próxima | Hori define, com agência, que sinais/contexto prefere usar em uma situação social; não transformar reconhecimento facial em falha moral ou penalidade automática | Janela posterior ao evento existente de pistas faciais; não duplicar a mesma revelação | Flag de preferência/contexto escolhida; só usar campo novo se a persistência for especificada | Uma vez; retrato Hori existente; ilustração opcional |
| `p5_ray_orphanage_contact` | Ray, Hori e/ou Luppi | Ray recebe notícia ou contato das amigas/crianças e decide entre renda, apoio compartilhado ou contato; manter o orfanato emocionalmente significativo, sem quantificar a saúde das crianças | Janela e condição de contato a decidir; aproveitar para revisar `ray_orphanage_remittance_w02` de `data/events.json` | Escolha com consequências de vínculo/tempo/finanças somente após modelo econômico 4C; sem nome, diagnóstico ou detalhe não confirmado das crianças | Uma vez; fundo atual pode bastar; retrato de Ray ausente |
| `p5_luppi_command_review` | Luppi e professora/instrutora já aprovada | Situação de estratégia/comando em treino: Luppi segue uma ordem, pede esclarecimento ou propõe alternativa dentro da cadeia de comando; preservar referências originais a jogos | Janela em torno de atividade estratégica; adaptar, não duplicar, `luppi_training_order_w03` de `data/events.json` | Flag e consequência relacional; sem “corrigir” autismo, negar emoções ou atribuir intenção hostil às professoras | Uma vez; retrato de Luppi ausente; cenário de treino existente |
| `p5_pair_training_debrief` | Hori com Ray ou Luppi, conforme escolha/eligibilidade | Debrief de treino em dupla que dá contexto à nova atividade e evidencia formas distintas de colaborar | Atividade de dupla desbloqueada ou janela aprovada; pré-requisito depende do modelo de vínculo/aptidão | Flag de participação e vínculo apenas se houver regra explícita; não duplicar o ganho da atividade | Uma vez por personagem ou uma vez total — decisão pendente; possível CG única |
| `p5_academy_open_day` | Hori, Ray, Luppi e os dois novos conceitos secundários | Evento coletivo de apresentação dos secundários por sua função, não por exposição biográfica | Personagens aprovados e sistema de mentoria/atividades disponível, se a cena o exigir | Apresentar mentora e colega; desbloqueios mecânicos somente depois de aprovados os contratos de 4C | Uma vez; cenário de academia existente; novos retratos necessários |

**Cadência:** os eventos atuais cobrem janelas ao longo das semanas 1–15, a missão está na 8 e a campanha termina na 16. Como o fluxo abre eventos elegíveis automaticamente e não há uma fila de adiamento configurável, seis novas cenas podem causar várias cenas em sequência na mesma semana. Antes de fixar janelas, aprovar uma destas políticas: (a) máximo de um evento de personagem por semana; (b) cenas adicionais substituem/expandem cenas existentes; ou (c) cenas consecutivas são parte intencional da experiência. A opção técnica depende da semântica de evento/adiamento que vier a ser aprovada.

### 4.2 Fichas conceituais de personagens secundários

As fichas abaixo são **propostas inteiramente não canônicas**, sem inclusão em `characters.json`. Nome, idade, aparência e história precisam de aprovação do autor antes de qualquer roteiro ou asset.

#### Personagem A — instrutora especializada

- **Nome provisório:** Lia Moura.
- **Faixa etária proposta:** adulta, 30–36 anos; não é uma idade estabelecida no universo.
- **Aparência conceitual:** uniforme funcional de academia, cabelo preso e detalhes visuais de equipamento de campo; silhueta e cores ainda dependem da Bíblia Visual e do autor.
- **Personalidade proposta:** objetiva, paciente ao explicar procedimentos e capaz de rever uma instrução quando recebe informação nova; não infalível nem antagonista por padrão.
- **História proposta:** entrou na docência depois de experiência em treinamento de campo. Nenhum vínculo com incidentes ou personagens canônicos é presumido.
- **Motivação proposta:** reduzir erros de coordenação sem tratar cadetes como recursos descartáveis.
- **Relações propostas:** mentora técnica acessível a Hori, Ray e Luppi, com consentimento/limites próprios para cada relação; não substituir as professoras canônicas que cuidam de Luppi.
- **Função narrativa:** introduzir discussão de comunicação, preparo e limites institucionais sem resolver o cânone do núcleo ou da mutação.
- **Possível função mecânica:** oferecer a atividade “Aula especializada” se a mecânica de mentoria da Fase 4C for aprovada.
- **Aprovações pendentes:** nome, design, histórico, maneira de falar, escopo de autoridade e se o papel deve ser um indivíduo nomeado ou uma instrutora genérica.

#### Personagem B — colega de academia

- **Nome provisório:** Nara Vale.
- **Faixa etária proposta:** adulta, 20–24 anos; não é uma idade estabelecida no universo.
- **Aparência conceitual:** vestimenta de cadete com itens de organização de campo; aparência completa, paleta e silhueta pendentes de aprovação.
- **Personalidade proposta:** curiosa, organizada e franca; pode errar uma leitura social e corrigir-se sem que a narrativa a converta em representante de um diagnóstico.
- **História proposta:** colega que se especializa em logística e comunicação de equipe. Não possui relação preexistente com o orfanato, o núcleo ou o experimento de Luppi.
- **Motivação proposta:** provar que preparação e coordenação também são competências de campo.
- **Relações propostas:** amizade gradual com as três protagonistas, baseada em cenas e escolhas, sem substituir vínculos já estabelecidos.
- **Função narrativa:** ponto de vista externo para atividades compartilhadas e vida cotidiana da academia.
- **Possível função mecânica:** auxiliar de atividade em dupla ou desbloqueio de uma interação cotidiana, somente se o sistema suportar suporte sem novo medidor obrigatório.
- **Aprovações pendentes:** nome, idade, aparência, personalidade, história e se a colega deve influenciar atributos ou apenas narrativa.

### 4.3 Duas atividades novas

Os IDs são rascunhos. Os campos são requisitos de design; valores e fórmulas ficam em aberto até a auditoria de balanceamento e o fechamento da Fase 4C.

#### Treinamento em dupla — `pair_training` (ID provisório)

- **Categoria candidata:** treinamento em equipe.
- **Função:** trocar parte do foco individual por coordenação com Ray ou Luppi; deve ter identidade distinta dos treinos solo.
- **Requisitos:** uma parceira elegível e um nível mínimo de relação, se a regra de vínculo for aprovada; não exigir relação máxima.
- **Custo de energia/créditos:** pendente de análise; não definir neste documento.
- **Ganhos:** foco em um ou dois atributos coerentes com a sessão; possível vínculo somente se não duplicar ou explorar ganhos sociais repetíveis.
- **Risco:** usar apenas o cálculo aprovado pela Fase 4C; não criar segunda fórmula de falha.
- **Motivação/aptidão/mentora:** integrar pelos contratos comuns aprovados, sem bônus paralelos exclusivos.
- **Feedback:** mostrar parceira, custo total, cenário de sucesso/falha e consequência relacional antes da confirmação.
- **Desbloqueios:** evento de debrief opcional, sem tornar a atividade obrigatória para completar a campanha.
- **Dados/arquitetura:** pode reaproveitar o catálogo de atividade e a prévia; exige suporte explícito a participante/parceira e validação no serviço.

#### Aula especializada — `specialized_lesson` (ID provisório)

- **Categoria candidata:** treinamento/mentoria.
- **Função:** especializar uma sessão em TEC, TEO ou SIN, por uma escolha clara do jogador.
- **Requisitos:** mentora disponível/desbloqueada, caso o modelo da Fase 4C use disponibilidade; não presumir um atributo mínimo.
- **Custo de energia/créditos:** pendente de análise; nenhum valor é fixado.
- **Ganhos:** progressão especializada, limitada pelos caps e pelo modelo de aptidões aprovado.
- **Risco:** herdar o fluxo comum de prévia/resultado; não esconder chance ou efeito no texto narrativo.
- **Motivação/aptidão/mentora:** usar uma única fórmula compartilhada com as demais atividades.
- **Feedback:** identificação da mentora, habilidade/aptidão pertinente, custo, mudança esperada e disponibilidade.
- **Desbloqueios:** pode abrir cenas ou opções de treino, mas não requisito obrigatório para os quatro finais existentes.
- **Dados/arquitetura:** estender o esquema de atividade de forma tipada; `mentor_affinity` atual é metadado e não é modificador funcional.

## 5. Progressão, equipamentos e economia

### 5.1 Aptidões, mentoria e motivação

| Elemento | Estado atual | Especificação proposta | Dependência |
|---|---|---|---|
| Aptidões | `characters.json` contém multiplicadores por atividade; `TrainingService` não os lê para calcular ganhos | Uma única contribuição por atividade, exibida no preview; preservar aptidões como preferência/modificador, não como bloqueio de rota | Fase 4C precisa aprovar intervalo, arredondamento, ordem com caps, persistência de personagem e experiência de balanço |
| Mentoria | Campo `mentor_affinity` existe; bônus da fórmula é placeholder zero; há vínculo `instructor`, mas nenhuma seleção ativa de mentora | Mentora identificada, efeito delimitado e relação sem requisito de grind alto; definir se mentor é fixo na atividade, personagem disponível ou escolha do jogador | Fase 4C precisa definir fórmula, disponibilidade, stack com aptidão e efeito de vínculos |
| Motivação | `TrainingState.motivation` existe, começa como `mood`; descanso e algumas escolhas a alteram; não afeta treino hoje | Um fator legível, com preview, comportamento neutro dentro de faixa e sem tratar emoção como moralidade | Fase 4C precisa aprovar curva, limites e se motivação altera ganho, chance ou ambos; esta proposta não escolhe |
| Especialização | Não há árvore nem escolha de especialização implementada | **Recomendação:** adiar especialização para depois do protótipo das atividades; considerar no máximo uma escolha curta de foco, não uma árvore | Decidir após playtest e não bloquear campanha/atividades básicas |

Não duplicar esses fatores dentro das atividades novas. O motor deve calcular uma vez e apresentar o resultado final em um formato consistente.

### 5.2 Equipamentos — três conceitos, efeitos ainda sujeitos a aprovação

Itens são conceitos não canônicos, não adicionados à economia atual. Não há preços, requisitos numéricos ou slots aprovados.

| Nome provisório | Categoria | Função/efeito conceitual | Custo e requisitos | Limite de uso | Asset |
|---|---|---|---|---|---|
| Faixas de treino ajustáveis | Equipamento de treino | Ajudar uma sessão física específica; bônus exato precisa respeitar a fórmula comum e não anular custo/risco | Créditos e requisito pendentes | Um efeito equipado por sessão; evitar empilhamento com itens equivalentes | Ícone de item |
| Tablet de análise de campo | Ferramenta tática | Melhorar informação/previsão em atividade técnica ou de missão, sem conceder sucesso automático | Créditos e requisito pendentes | Uso ou carga limitada a definir; não contornar falha recuperável | Ícone de tablet |
| Comunicador de equipe | Equipamento de equipe | Dar suporte a coordenação de atividade dupla/missão; não conceder vínculo automaticamente | Créditos e requisito pendentes | Um item ativo; compatibilidade com atividade de equipe a definir | Ícone de comunicador |

**Modelo mínimo recomendado para avaliação:** catálogo pequeno, compra opcional, efeito explícito e sem árvore de melhoria. Antes de implementar, decidir se cada item é consumível, desbloqueio permanente ou equipamento equipado. Não misturar compra permanente e bônus consumível sem limites claros.

### 5.3 Economia

| Fluxo atual/proposto | Fonte ou destino | Situação |
|---|---|---|
| Saldo inicial | 50 créditos em dados de Hori | Protótipo atual |
| Trabalho/estágio | +25 créditos e +1 reputação por ação de estágio | Fonte atual repetível; até 48 usos cabem no calendário, mas não há sink atual |
| Recompensa narrativa | bolsa/apoio ou remuneração como hipótese | Só planejar depois de validar a história de Ray e o modelo da Fase 4C |
| Loja | aquisição dos até três itens conceituais | Sink proposto; preços não definidos |
| Gastos de missão | ferramenta/preparação opcional | Alternativa de sink, não criar sem aprovação de custo e sem caminho sem gasto |

**Recomendação econômica:** toda compra deve ser opcional para completar a campanha e não tornar a atividade essencial inacessível. Projetar a curva de custos a partir do saldo inicial e do número máximo plausível de estágios, não de uma estimativa de sessões ilimitadas. Evitar transformar as necessidades do orfanato em punição financeira ou em barra de vida das crianças.

**Decisão pendente:** definir quais fontes continuam existindo, se a renda excedente é útil dentro de uma campanha finita e se haverá opção de ajuda/bolsa que preserve agência sem apagar o objetivo financeiro de Ray. Não fixar preços antes dessa decisão.

## 6. Assets e direção de arte

### 6.1 Inventário estático disponível

`assets/phase3/` contém sete assets de jogo catalogados em `10_ASSET_MANIFEST.md`:

- **Cenários (3):** sala da academia, laboratório e observatório.
- **Retratos (4):** Hori neutra, feliz, preocupada e determinada.
- **Retratos ausentes:** Ray, Luppi e personagens secundários.
- **Ícones de atividades/equipamentos e ilustrações especiais de evento:** não constam no manifesto existente.

As capturas de `captures/phase4a/`, inclusive propostas e resoluções, são referência de composição/interface; não devem ser tratadas automaticamente como arte reutilizável de jogo. A licença/proveniência dos arquivos existentes precisa ser confirmada antes de publicação, conforme o manifesto.

O diálogo só atualiza a textura para `speaker_id == "hori"`; hoje os demais falantes mantêm a textura anterior. Para uma expansão com falas de Ray, Luppi e novos secundários, especificar resolução de speaker e retrato/placeholder antes de produzir cenas ilustradas.

### 6.2 Plano visual sem geração nesta fase

1. Aprovar as fichas e a Bíblia Visual antes de criar rostos/roupas finais.
2. Reutilizar primeiro os três cenários e expressões de Hori já existentes.
3. Definir proporção, resolução, transparência, enquadramento, paleta e destino de importação por categoria.
4. Criar prompts mestres originais e nomenclatura versionada na Fase 5.4.
5. Priorizar: retratos expressivos de Ray/Luppi; retratos/poses dos dois secundários se aprovados; ícones das atividades; ícones dos três itens.
6. Limitar ilustrações especiais a até três e cenários novos a até dois, gerando apenas para lacunas confirmadas.

**Nenhuma imagem ou prompt de geração é produzido nesta Fase 5.0.**

## 7. Dependências e compatibilidade técnica

| Dependência | Evidência atual | Consequência para a expansão | Portão antes da implementação |
|---|---|---|---|
| Falha automática da missão após semana 8 | Dados declaram janela 8–8; o método atual verifica apenas `week >= week_min`; painel processa missão quando fica devida | Novos eventos e finais pós-missão precisam saber se houve sucesso, falha automática ou tentativa incompleta | Especificar o resultado automático, flags e interação com `final_mission_attempted`; não definir aqui |
| Pulso determinístico | Código resolve sucesso com estabilidade `>=55` **e** TEC `>=30`; desbloqueio atual aceita estabilidade `>=55` **ou** flag de protocolo em equipe | Atividades/itens não devem introduzir uma segunda rolagem ou prometer sucesso por bônus sem rever o contrato | Confirmar contrato completo de disponibilidade e resultado da Fase 4C; manter o teste determinístico aprovado |
| Motivação mecânica | Campo e UI existem; fórmula de falha não consulta motivação | Preview/atividade nova precisa apresentar a influência sem criar regra paralela | Aprovar fórmula, bandas, caps e dados de regressão |
| Aptidões e mentoria | Multiplicadores no JSON e `mentor_affinity` nos dados, não aplicados; mentor bonus zero | Atividades propostas dependem de uma regra comum e seus efeitos atuais podem mudar | Aprovar fórmula, resolução de conflito/stacking e papel do vínculo |
| Loja/equipamentos | Créditos existem e estágio é faucet; não há inventário/loja | Compra e equipamento exigem estado novo, aplicação de efeitos e UI | Aprovar modelo de item, preços, fontes, sinks, limites e save fields |
| Save em disco | Nenhum serviço de serialização/carregamento foi localizado nos scripts examinados | Novas flags, itens, mentoria e conteúdo podem perder-se ou falhar em migração | Definir schema/versionamento, validação, migração e continuidade de seed antes de conteúdo persistente |
| Seis novos eventos | Serviço valida exatamente 8 eventos ativos | Acrescentar eventos ao arquivo atual sem alteração coordenada causa rejeição pelo loader | Escolher composição de arquivos e validação por versão/quantidade; proteger IDs e eventos existentes |
| Novas personagens falantes | Retratos só são definidos para Hori; `BOND_IDS` é limitado a Hori/Ray/Luppi/instrutor | Secundários podem participar como fala sem relação mecânica, mas retrato e vínculo exigem extensão explícita | Aprovar se terão vínculos próprios; definir fallback e retratos |
| Novas atividades | UI itera IDs; validador de atividades possui allowlist estrita; categorias e layouts têm estilos próprios | É possível reutilizar cartões e preview, mas campos novos não entram sem mudança coordenada do serviço e apresentação | Fixar o contrato de dados após Fase 4C e mapear categorias/efeitos |

## 8. Plano das subfases

### Fase 5.0 — Especificação (esta entrega)

- Mapear reuso e lacunas.
- Aprovar escopo, conceitos e portões.
- Nenhuma mudança de gameplay, dados, UI, testes ou arte.

### Fase 5.1 — Conteúdo narrativo

- Resolver fonte ativa versus dados legado.
- Confirmar quais dos seis eventos são adições e obter aprovação de outlines, janelas, flags, consequências e voz.
- Redigir/revisar diálogos em português brasileiro e verificar continuidade/cânone.
- Dependências: política de missão semana 8, pacing de eventos e aprovação dos secundários.

### Fase 5.2 — Atividades

- Especificar efeitos e requisitos após a fórmula unificada da Fase 4C.
- Implementar apenas uma atividade por execução de trabalho, com dados/serviço/UI alinhados.
- Dependências: contratos de motivação, aptidão, mentoria, energia e créditos.

### Fase 5.3 — Progressão e economia

- Definir o menor modelo de aptidões, mentores, motivação, inventário, loja e gastos.
- Fazer avaliação manual de ganhos/sinks a partir dos valores atuais antes de propor números finais.
- Dependências: decisões 4C; salvamento versionado; escopo aprovado para equipamento opcional.

### Fase 5.4 — Produção de assets

- Gerar arte original somente depois da aprovação de fichas, direção de arte, resolução e prompts mestres.
- Revisar cada imagem e seu uso/licença/proveniência antes de integração.
- Dependências: elenco/personagens e necessidades visuais confirmados.

### Fase 5.5 — Integração

- Integrar em serviços/dados/UI existentes, sem criar segunda fonte de verdade.
- Preservar Hub inicial, navegação e prioridade narrativa.
- Dependências: esquema de conteúdo, inventário/save e eventos aprovados.

### Fase 5.6 — Validação

- Plano de testes localizados de serviço, narrativa, save/migração, compra, compatibilidade e interface.
- Avaliar balanceamento em passagens pequenas, com autorização explícita e limites operacionais definidos.
- Nenhum teste foi executado como parte desta especificação.

## 9. Decisões que exigem aprovação do autor

1. “Seis eventos” significa seis adicionais aos oito atuais (14 no total) ou seis eventos na expansão incluindo revisão/substituição de conteúdo existente?
2. Qual fonte narrativa é oficial para Hori: o conjunto de `Hori Draft`, `data/events.json` ou um carregamento composto por rota?
3. Qual política de cadência é desejada quando mais de um evento fica elegível na mesma semana?
4. A missão que falha automaticamente depois da semana 8 deve marcar `final_mission_attempted`, criar flag própria ou seguir outro resultado? A integração deve respeitar a decisão final da 4C.
5. Os conceitos “Lia Moura” e “Nara Vale” são úteis como ponto de partida ou devem ser substituídos? Aprovar nomes, idades, aparência, personalidade e história antes de canonizar.
6. Ray e Luppi terão vínculos mecânicos próprios com os novos secundários, ou os secundários serão participantes sem barras de relação?
7. Qual comportamento aprovado de motivação, aptidões e mentoria será a única fórmula de treinamento? Confirmar contrato 4C, não reabrir por esta proposta.
8. Equipamentos serão permanentes, consumíveis ou equipados? Haverá limite de slots? Qual fonte/sink de créditos atende a campanha sem exigir compras?
9. A especialização deve permanecer adiada, como recomendado, ou entrar como uma única escolha simples?
10. Qual formato/versionamento de save aprovado deve conter itens, novas flags e dados da Fase 4C?
11. Quais retratos/CGs são obrigatórios e quais podem usar os cenários/expressões atuais?

## 10. Critérios de aceite para a Fase 5.0

- [x] Inventário estático de sistemas e arquivos relevantes.
- [x] Reuso, ausências e incompatibilidades de arquitetura identificados.
- [x] Dependências da Fase 4C explicitadas sem tentar resolvê-las.
- [x] Seis conceitos de evento, duas fichas secundárias, duas atividades e três itens propostos como material não canônico.
- [x] Recursos, fontes/sinks e necessidades de assets planejados sem definir balanceamento final.
- [x] Subfases pequenas e seus portões descritos.
- [x] Nenhuma implementação, alteração de gameplay, alteração de dados ou geração de arte executada.

**Validação:** inspeção estática somente. Nenhum teste, simulação, execução do projeto ou geração de imagem foi realizado.

# Implementação visual — Fase 3

## Escopo

Esta entrega aprimora a apresentação do protótipo Godot existente. Treinamento, valores, condições de eventos, escolhas, efeitos, flags, RNG, missão e finais não foram alterados. A campanha e seus rascunhos continuam sob as regras de cânone e aprovação existentes.

## Fase 4A.4 — Status e entrada da campanha

A tela de Status é uma área independente do dashboard, com os cinco atributos, três recursos, créditos, reputação, semana e blocos de ação lidos de `TrainingState` e dos limites de `TrainingService`. O perfil exibe somente os fatos de personalidade existentes para Hori em `characters.json`. O retrato usa o sprite já carregado, sem duplicar o personagem ou alterar os arquivos de arte.

A campanha abre primeiro no Hub da Academia. Um evento narrativo elegível não cobre o HUD durante a inicialização; o fluxo narrativo continua sendo avaliado após uma atividade confirmada e ao avançar a semana, preservando a prioridade dos eventos nesses momentos. A navegação pelo Status não consome ações, altera estado ou avança o RNG.

## Fase 4A.5 — Relações e vínculos

A tela de Relações é independente do painel administrativo antigo e apresenta os vínculos existentes com Ray, Luppi e Instrutor. Os valores e o limite vêm de `TrainingState` e `TrainingService`; os cartões usam cores próprias da paleta e mostram progresso atual e distância restante. Os resumos de Ray e Luppi se limitam a fatos já confirmados na Bíblia Canônica. Como não há perfil narrativo do Instrutor nem histórico de evolução dos vínculos, a interface declara essas ausências em vez de preencher lacunas.

Os atalhos “Conversa com Ray” e “Tempo com Luppi” apenas abrem Treinamento. A aplicação continua sob responsabilidade de `TrainingService`; consultar Relações não altera o estado nem avança o RNG. Os controles existentes de navegação, o Hub inicial e a prioridade narrativa foram preservados.

## Interface

O dashboard preserva cabeçalho, progresso do semestre, painel da personagem, atividades e prévia. Um fundo contextual fica atrás dos painéis, com tint índigo para manter contraste. O painel da personagem e o modal aceitam retrato com proporção preservada; a falta de retrato de outro personagem continua visível como placeholder, sem gerar ou reutilizar a arte da Hori.

O modal narrativo apresenta a arte da Hori à esquerda e o diálogo, opções e resultados à direita. Cada fala da cena atual é acumulada em um histórico consultável e recolhível. O histórico é reiniciado ao abrir outro evento e não é persistido entre sessões. Falas longas e listas de escolhas usam regiões com rolagem própria; o foco do teclado acompanha as escolhas.

A missão apresenta as três etapas com estado concluído/atual/pendente e destaca o objetivo atual. Na etapa 2, a interface explica o Pulso de Contenção usando os limites públicos de `NarrativeService`: sucesso se estabilidade do núcleo for pelo menos 55 **e** Técnica pelo menos 30; senão, o resultado é falha recuperável. A implementação visual não altera o cálculo nem introduz RNG.

## Cenários e expressões

Os três cenários são selecionados somente na apresentação:

| Contexto | Cenário |
|---|---|
| Inicial, treino físico, combate, estágio e conversas de rotina | Academia |
| Estudo/controle no laboratório, protocolo do núcleo e investigação da Ruptura | Laboratório |
| Conversas com Ray/Luppi, confronto com a voz, aftermath de Ray, missão e epílogo | Observatório |

O mapeamento é local ao dashboard e não modifica eventos ou triggers. O fundo usa `TextureRect` em modo *keep aspect covered*, com o centro da composição preservado por recorte proporcional.

As quatro expressões da Hori são carregadas sem alterar arquivos de arte. As falas usam este mapeamento local: Hori começa feliz no evento de reconhecimento de rostos; o protocolo do núcleo usa worried; o confronto com a voz passa de worried para determined; a investigação da Ruptura usa determined; os demais contextos usam neutral. A missão usa determined, e uma falha recuperável do Pulso usa worried. Falas de Ray, Luppi e outros personagens continuam com placeholder, pois não foram fornecidos retratos deles.

## Assets e decodificação

Os PNGs de retrato são carregados por `Image.load_png_from_buffer`, preservando a transparência indexada. O fundo da academia é PNG. Os arquivos chamados `laboratory_bg.png` e `observatory_bg.png` contêm dados WebP (`RIFF/WEBP`); o carregador identifica o cabeçalho e usa `Image.load_webp_from_buffer`, sem renomear ou regravar os originais. A `ImageTexture` resultante é mantida na camada de apresentação.

Dimensões, formato real, transparência, uso e situação por arquivo estão em [10_ASSET_MANIFEST.md](./10_ASSET_MANIFEST.md). A origem visual e o status de prompts estão em [08_ASSETS_FASE3.md](../prompts/08_ASSETS_FASE3.md).

## Arquivos

- `scripts/training_dashboard.gd`: carregamento visual, fundo contextual, retratos, histórico da cena, painel da missão e seleção de expressão.
- `Hero_Trainer_Kit_v02/README.md`: status atualizado do protótipo e referência à documentação visual.
- `Hero_Trainer_Kit_v02/docs/09_IMPLEMENTACAO_VISUAL_FASE3.md`: este registro.
- `Hero_Trainer_Kit_v02/docs/10_ASSET_MANIFEST.md`: inventário técnico dos assets.
- `Hero_Trainer_Kit_v02/prompts/08_ASSETS_FASE3.md`: proveniência de prompts e regras de consistência.

## Capturas e validação visual

As capturas foram renderizadas pela cena Godot em runtime com Godot 4.5.1 e renderer Compatibility/OpenGL. O script auxiliar de captura foi removido após o uso.

| Estado | Captura |
|---|---|
| Dashboard padrão, resolução do projeto | [1024×768](../../captures/phase3/dashboard-1024x768.png) |
| Dashboard completo | [1280×720](../../captures/phase3/dashboard-runtime.png) |
| Dashboard em janela compacta | [800×600](../../captures/phase3/dashboard-800x600.png) |
| Dashboard em janela ampla | [1366×768](../../captures/phase3/dashboard-1366x768.png) |
| Diálogo com retrato | [Diálogo](../../captures/phase3/dialogue-runtime.png) |
| Seleção de atividade e prévia de risco | [Atividade selecionada](../../captures/phase3/training-selected-runtime.png) |
| Bloqueio por energia insuficiente | [Atividade bloqueada](../../captures/phase3/training-blocked-runtime.png) |
| Escolhas narrativas | [Escolhas](../../captures/phase3/dialogue-choices-runtime.png) |
| Etapa 2 da missão e requisito do Pulso | [Missão](../../captures/phase3/mission-runtime.png) |

Nas resoluções avaliadas, o cabeçalho, a prévia e os controles de ação permanecem acessíveis. Em 800×600, atributos e atividades usam rolagem localizada; em 1024×768, 1280×720 e 1366×768, o conteúdo principal aparece sem sobreposição. As escolhas longas da cena e da missão também ficam em áreas roláveis. Não foi observada arte cortada fora dos painéis, e o estado de bloqueio inclui texto explícito com a energia que falta, não apenas indicação por cor.

As telas de Status e Relações foram renderizadas em 800×600, 1024×768, 1280×720 e 1366×768. As capturas de Status estão em `captures/phase4a/status/`; as 16 capturas de Relações — quatro estados controlados em cada resolução — estão em `captures/phase4a/relationships/`. Relações usa rolagem vertical localizada, sem rolagem horizontal.

A apresentação segue os valores centralizados em `training_theme.gd` e usa as cores índigo, azul-petróleo, menta, coral, dourado e creme definidas pela Bíblia Visual. O resultado é uma interface funcional com placeholder substituível, sem novos assets externos. Os cenários e expressões mantêm o papel de apoio da narrativa e não alteram condições, resultados ou estado da campanha.

## Validação automatizada e limites

Com Godot 4.5.1 local, passaram:

- Verificação headless do editor (`--headless --editor --quit`), código de saída 0.
- Smoke test da cena principal (`--headless --quit-after 3`), código de saída 0.

O polimento de navegação, feedback de controles e atualização animada dos indicadores está registrado em [11_POLIMENTO_TRANSICOES_FASE4A6.md](./11_POLIMENTO_TRANSICOES_FASE4A6.md).
- Suítes `Training Service` e `Hori Narrative Campaign`: 8 métodos de teste, 385 asserções, 0 falhas.

Os testes de dados inválidos emitem diagnósticos `push_error` esperados para chaves desconhecidas; as asserções confirmam que a rejeição é segura. O Godot AI MCP não iniciou: o processo do servidor falhou no handshake ao tentar buscar o pacote do servidor no PyPI, devido a erro de conexão. Portanto, nenhuma suíte nem captura foi executada pelo MCP; as capturas acima vieram do runtime local do Godot.

A resolução padrão do projeto continua 1024×768. Em 800×600, a rolagem interna é necessária para conteúdo secundário do perfil e da lista de atividades, enquanto o painel de prévia e os botões permanecem visíveis. Não foram adicionados sprites de Ray ou Luppi, animações, save/load, áudio ou persistência do histórico. Os assets recebidos não incluem autoria/licença; confirmar esses dados antes de publicar ou redistribuir o projeto.

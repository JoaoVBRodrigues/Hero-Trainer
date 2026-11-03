# Auditoria visual e de resoluções — Fase 4A.7

## Escopo

O problema relatado era a impressão de que a janela não aceitava resoluções maiores e de que elementos do Hub desapareciam após o redimensionamento. A auditoria confirmou que a janela nativa já era redimensionável; o viewport inicial 1024×768, em proporção 4:3, e a falta de um controle de tela cheia no jogo contribuíam para a impressão de limite. Também faltava centralizar a atualização responsiva quando a raiz do dashboard mudava de tamanho.

Esta fase altera apenas a apresentação da janela e o recálculo de layout. `TrainingState`, `TrainingService`, `NarrativeService`, os dados, o RNG, os custos, a campanha e as regras de navegação não foram modificados.

## Alterações

- Viewport inicial de 1280×720, em janela nativa redimensionável.
- Botão `F11` nos cabeçalhos do Hub, Treinamento, Status e Relações. O teclado aceita `F11` e `Alt+Enter`; a saída da tela cheia restaura o modo e o tamanho de janela anteriores.
- O redimensionamento da raiz aciona uma atualização comum dos layouts de Hub, Treinamento, Status, apresentação da Hori e painel narrativo.
- A atualização do painel narrativo ignora o recálculo enquanto seus nós ainda não foram inicializados.
- A configuração existente de movimento reduzido foi preservada.

## Auditoria visual

As capturas foram renderizadas em runtime, com viewport verificado por dimensão, para as quatro áreas:

| Resolução | Hub | Treinamento | Status | Relações |
|---|---|---|---|---|
| 800×600 | [Captura](../../captures/phase4a/resolution-audit/hub/hub-800x600.png) | [Captura](../../captures/phase4a/resolution-audit/training/training-800x600.png) | [Captura](../../captures/phase4a/resolution-audit/status/status-800x600.png) | [Captura](../../captures/phase4a/resolution-audit/relationships/relationships-800x600.png) |
| 1024×768 | [Captura](../../captures/phase4a/resolution-audit/hub/hub-1024x768.png) | [Captura](../../captures/phase4a/resolution-audit/training/training-1024x768.png) | [Captura](../../captures/phase4a/resolution-audit/status/status-1024x768.png) | [Captura](../../captures/phase4a/resolution-audit/relationships/relationships-1024x768.png) |
| 1280×720 | [Captura](../../captures/phase4a/resolution-audit/hub/hub-1280x720.png) | [Captura](../../captures/phase4a/resolution-audit/training/training-1280x720.png) | [Captura](../../captures/phase4a/resolution-audit/status/status-1280x720.png) | [Captura](../../captures/phase4a/resolution-audit/relationships/relationships-1280x720.png) |
| 1366×768 | [Captura](../../captures/phase4a/resolution-audit/hub/hub-1366x768.png) | [Captura](../../captures/phase4a/resolution-audit/training/training-1366x768.png) | [Captura](../../captures/phase4a/resolution-audit/status/status-1366x768.png) | [Captura](../../captures/phase4a/resolution-audit/relationships/relationships-1366x768.png) |

As quatro áreas mantêm a Hori visível, a navegação acessível e os dados essenciais dentro da janela. Em 800×600, Status e o painel de perfil usam rolagem localizada para conteúdo secundário; o texto e os cartões ficam mais compactos. Não foi observada sobreposição que impeça a navegação ou o uso das atividades. Os demais tamanhos oferecem mais espaço para conteúdo simultâneo.

QHD (2560×1440) não foi validado: o monitor disponível tem resolução máxima de 1920×1080. As capturas e os testes cobrem somente as quatro dimensões listadas acima.

## Testes

- Godot 4.5.1, smoke test headless da cena principal: código de saída 0.
- Suítes locais: 16 métodos, 893 asserções, 0 falhas, distribuídos entre `Training Service`, `Hori Narrative Campaign` e `Dashboard Character Presentation`.
- O teste novo verifica o tamanho inicial, os controles F11, o reconhecimento de F11/Alt+Enter, a conexão do redimensionamento e a invariância de ações, RNG, atributos e vínculos.
- A execução visual em janela real confirmou a entrada em tela cheia, o retorno ao modo anterior e a restauração do tamanho anterior.
- As 16 imagens foram verificadas em runtime e têm as dimensões nominais indicadas.
- `git diff --check`: sem erros de whitespace.

O servidor Godot AI MCP não iniciou porque não conseguiu baixar seu pacote do PyPI; os testes e as capturas foram executados pelo runtime local. Os diagnósticos de chaves desconhecidas emitidos por testes negativos são esperados e não representam falhas.

## Arquivos

- `project.godot`
- `scripts/training_dashboard.gd`
- `tests/test_dashboard_presentation.gd`
- `captures/phase4a/resolution-audit/`
- `Hero_Trainer_Kit_v02/docs/09_IMPLEMENTACAO_VISUAL_FASE3.md`
- `Hero_Trainer_Kit_v02/docs/12_AUDITORIA_VISUAL_E_RESOLUCOES_FASE4A7.md`

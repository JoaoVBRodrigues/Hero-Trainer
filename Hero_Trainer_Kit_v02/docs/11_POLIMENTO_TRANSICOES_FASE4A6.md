# Fase 4A.6 — Transições, animações e feedback visual

## Escopo

O polimento usa a interface e os serviços existentes. Não altera regras da campanha, custos, valores, RNG, dados, narrativa ou progressão.

## Implementação

- A navegação entre Hub, Treinamento, Status e Relações usa uma camada índigo semitransparente que escurece e revela a tela selecionada. O fade-out e o fade-in duram 0,07 s e 0,13 s; o bloqueio de entrada existe somente durante os 0,20 s da transição. Uma nova navegação cancela a transição anterior e normaliza a camada, evitando estados presos.
- Botões compartilham um único registro de feedback para hover, foco e pressão. A `Theme` existente fornece os estilos de normal, hover, pressionado, desabilitado e foco de teclado; o Tween reutilizável acrescenta uma alteração breve de tonalidade em 0,10 s, sem deslocar controles.
- O cartão de treinamento selecionado usa o estado pressionado da própria `Button`. A prévia destaca separadamente os painéis de sucesso e falha, sem tocar no estado nem sortear resultado.
- Após a confirmação, valores numéricos e recursos continuam vindo do resultado aplicado pelo `TrainingService`. As barras interpolam dos valores anteriores até os valores reais em 0,28 s; atributos alterados e vínculos afetados recebem um destaque breve. Sem alteração real, não há animação de ganho ou perda.
- A atualização de vínculo usa `TrainingState.bonds` e o limite do serviço. Não são criados histórico, reações ou eventos de personagem.
- O overlay narrativo entra e sai com fade curto. A camada continua bloqueando a navegação e os controles encobertos até concluir o fechamento. O fluxo narrativo é retomado depois do fade, mantendo sua prioridade.

## Redução de movimento

O projeto não tinha preferência de movimento. Foi adicionada a configuração simples `accessibility/reduce_motion` em `project.godot`, inicialmente `false`. Quando ativada, navegação e overlay aparecem sem fades, indicadores atualizam imediatamente e os destaques animados são omitidos.

## Validação

Com Godot 4.5.1:

- Verificação do editor/imports e inicialização do projeto.
- Suítes de treinamento, campanha narrativa e apresentação: **15 testes aprovados, 0 falhas**.
- Testes de transição interrompida, prioridade/fechamento de overlay, estado de foco e navegação rápida; seleção e prévia sem mutação; indicadores direcionados ao estado aplicado; e preferência de redução de movimento.
- Inspeção das capturas em 1280×720 e do Hub em 800×600, 1024×768 e 1366×768. Os painéis permaneceram dentro da viewport; não foi observado corte ou sobreposição.

## Capturas

As capturas foram renderizadas pela cena Godot com o renderer Compatibility. A ação arriscada e o diálogo retratam o fluxo e o conteúdo existentes; o resultado de descanso vem de `TrainingService.apply_activity`.

Em `captures/phase4a/transitions/`:

- `hub-1280x720.png` e `hub-hover-1280x720.png`
- `training-selected-1280x720.png` e `training-preview-1280x720.png`
- `training-result-1280x720.png`
- `status-1280x720.png`, `relations-1280x720.png` e `dialogue-1280x720.png`
- `hub-800x600.png`, `hub-1024x768.png` e `hub-1366x768.png`

## Limites e integridade

As animações são locais à apresentação; nenhuma chamada de Tween aplica uma atividade ou modifica a campanha. O histórico de vínculos continua indisponível. O runner MCP do Godot não inicializou neste ambiente por falha de conexão com o índice de pacotes, então as suítes foram executadas pelo runner local do repositório, e as capturas pelo executável Godot 4.5.1 instalado. As mensagens de rejeição de JSON inválido emitidas por testes existentes são esperadas.

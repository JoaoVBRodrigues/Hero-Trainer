# Especificação de Expansão — Fase 5.0

**Versão:** 1.0
**Status:** baseline de conteúdo pronta para aprovação; não implementada
**Escopo aprovado:** todas as áreas, conteúdo focado em Ray e Luppi, escala pequena, assets planejados para geração por IA.

> Esta especificação descreve propostas de implementação, não novos fatos canônicos. A Fase 5 não deve começar antes da aprovação das escolhas narrativas e do fechamento da validação de retomada do Save/Load.

## 1. Objetivos e limites

Expandir a campanha atual com duas atividades e quatro eventos curtos que aproveitem calendário, treinamento, relações, narrativa, recursos e interface existentes. A experiência continua sendo a campanha atual, com Hori como protagonista jogável e Ray e Luppi como personagens de apoio.

### Incluído

- Duas atividades desbloqueadas por acontecimentos narrativos: uma ligada ao apoio de Ray e outra ao treino tático de Luppi.
- Quatro eventos curtos: dois focados em Ray, um em Luppi e um compartilhado pelas três personagens.
- Uso dos atributos, energia, estresse, motivação, aptidões, mentoria, vínculos, créditos, reputação, flags e sistema de eventos já existentes.
- Retratos de diálogo e ícones simples, planejados como assets originais gerados por IA.
- Mudança pequena no serviço de treinamento para reconhecer um `unlock_flag` opcional nas atividades.

### Fora de escopo

- Novas personagens jogáveis, rotas completas, semanas, recursos, atributos, sistemas de relacionamento ou finais.
- Medidores de saúde, moralidade, empatia, autonomia, estabilidade psicológica ou condição neurológica.
- Uma economia separada para o orfanato, saldos pertencentes às crianças, ou novas lojas e equipamentos.
- Reestruturação do serviço narrativo, do formato de save, da campanha ou das telas principais.
- Geração de imagens ou implementação nesta tarefa.

## 2. O que existe e pode ser reutilizado

O documento anterior listava como ausentes sistemas já implementados na Fase 4C. A baseline real a preservar é:

| Sistema | Estado atual e uso previsto na Fase 5 |
|---|---|
| Atividades | Há oito atividades carregadas pelo `TrainingService`. Novas atividades devem usar o mesmo formato e fluxo de preview/aplicação, sem criar um segundo sistema. |
| Atributos e recursos | Treino já altera atributos e recursos como energia, estresse, motivação, créditos e reputação. Os efeitos propostos abaixo são incrementais e não adicionam campos ao estado. |
| Motivação e aptidões | Ganho de treino é ajustado por faixas de motivação (0,90 / 1,00 / 1,10) e aptidões (0,85–1,15); os novos treinos devem passar pelo mesmo cálculo. |
| Mentoria e risco | Mentoria elegível reduz o risco em 5 pontos percentuais. A Fase 5 não cria uma regra paralela de sucesso. |
| Relações | Há vínculos para Ray, Luppi e instrutor. Eventos e atividades devem atualizar esses vínculos existentes, sem criar um vínculo para cada criança ou professora. |
| Economia | Há loja opcional e itens existentes com preços de 80, 120 e 160 créditos. A contribuição narrativa proposta para Ray usa créditos da campanha, não uma carteira nova. |
| Equipamentos | Inventário e equipamento já são parte do estado persistido; a Fase 5 não adiciona equipamentos. |
| Missão e finais | A missão e seus finais já existem. A expiração ocorre na transição da semana 8 para a 9. A expansão não modifica as condições dos finais. |
| Save/Load | Existe save JSON versionado com arquivo principal, temporário e cópia de recuperação. Flags booleanas de eventos podem ser persistidas sem adicionar campos ao `route_state`. A retomada após reiniciar ainda precisa de validação funcional concluída. |
| Eventos | A fonte ativa é `Hori Draft/events_hori_draft.json`; o serviço narrativo atualmente valida uma lista de exatamente oito eventos. A expansão propõe doze eventos no total, portanto o limite precisa ser atualizado junto com os dados. `data/events.json` não deve ser tratado como fonte ativa sem confirmação no código. |

O risco de atividade continua usando a fórmula existente, com energia, estresse, teto atual e ajuste de mentoria. Os valores de atributos e recursos abaixo são propostas iniciais para playtest e não alteram a fórmula compartilhada.

## 3. Cânone confirmado e propostas

### Fatos canônicos a preservar

- **Ray:** mulher alta e fisicamente forte, com chifres decorrentes de mutação. Separou-se de amigas na América para estudar e obter dinheiro para sustentá-las e custear cuidados relacionados à doença do Honkai. O orfanato e as crianças têm relevância emocional e mecânica.
- **Luppi:** garota-rato, resultado de experimento e autista. Tem dificuldade para compreender certos sentimentos, mas sente e demonstra emoções e empatia. Gosta de combate, faz referências frequentes a jogos, concentra-se intensamente em seus interesses, respeita a cadeia de comando e tem vínculos próximos com professoras que cuidam dela. O experimento não deve ser apresentado como causa do autismo.
- **Hori:** jovem animada e sociável, com muitas amigas. Carrega um núcleo perigoso que já feriu pessoas próximas, tem dificuldade para reconhecer rostos e ouve a voz de uma versão mais malvada de si. Esconde sofrimento atrás do sorriso.

### Propostas desta especificação (não canônicas até aprovação)

- Os quatro eventos, suas escolhas, textos, flags, semanas e efeitos.
- Os nomes técnicos dos eventos/atividades e os valores mecânicos sugeridos.
- A forma visual específica dos retratos e ícones, que ainda requer aprovação autoral.

Não inventar nomes, idades, aparência, diagnósticos, falas, relações ou destinos para as amigas de Ray, as crianças do orfanato ou as professoras de Luppi. Referências de Luppi a jogos devem ser genéricas ou originais, sem reproduzir jogos, personagens, diálogos, códigos ou artes proprietárias.

## 4. Atividades propostas

As duas atividades aparecem na lista existente e usam o preview e a aplicação de `TrainingService`. `unlock_flag` é uma extensão pequena proposta: quando presente, a atividade fica indisponível até a flag correspondente ser verdadeira; atividades sem essa propriedade mantêm o comportamento atual. A tela deve explicar o requisito sem consumir ação, energia, RNG ou recursos.

| ID proposto | Nome exibido | Desbloqueio | Efeitos-base propostos | Regras |
|---|---|---|---|---|
| `ray_orphanage_logistics` | Apoiar a remessa | `ray_support_activity_unlocked`, definido pelo primeiro evento de Ray | Créditos +20, energia −8, estresse +4, vínculo Ray +3 | Atividade de trabalho determinística. A recompensa é menor que a do estágio existente; o vínculo é o diferencial. Não cria saldo ou medidor para o orfanato. |
| `luppi_tactical_drill` | Treino tático com Luppi | `luppi_tactics_activity_unlocked`, definido pelo evento de Luppi | POT +2, TEC +3, energia −12, estresse +4 | Treino sujeito ao cálculo atual de aptidão, motivação, risco e mentoria. Não altera um medidor de autonomia, empatia ou condição neurológica. |

Os valores são baseline para uma revisão de balanceamento focada após a implementação. Não devem ser aumentados para tornar as novas atividades universalmente melhores que as oito existentes. A atividade de Ray não paga “por criança” e não transforma o cuidado do orfanato em recompensa escalável.

## 5. Eventos e conteúdo narrativo proposto

Adicionar os eventos à fonte ativa existente, preservando a sequência e os finais de Hori. A ordem abaixo usa acontecimentos atuais como âncoras; as flags exatas devem ser confirmadas no JSON durante a tarefa de implementação. As cenas novas são curtas e não devem interromper ou substituir uma escolha já disponível.

| ID proposto | Janela | Conteúdo e escolhas | Efeitos/flags |
|---|---:|---|---|
| `ray_orphanage_remittance_w08` | Semana 8 | Ray explica como concilia estudo e trabalho para apoiar as amigas e custear cuidados ligados à doença do Honkai. A conversa conecta essa motivação ao orfanato e às crianças, sem inventar nomes ou detalhes médicos. Hori pode contribuir com 20 créditos da campanha para a remessa ou ajudar Ray a organizar um plano sem custo. | Ambas as escolhas definem `ray_support_activity_unlocked`. Contribuir exige créditos ≥20, desconta 20 e aumenta vínculo Ray em 5; planejar não custa créditos e aumenta vínculo Ray em 3. Registar uma flag distinta para cada escolha. |
| `luppi_tactical_briefing_w10` | Semana 10, após o evento estratégico de Hori na janela 9–10 | Luppi propõe uma solução de combate com referências genéricas a jogos. A professora responsável define objetivo e limites; Hori pode pedir um plano tático próprio dentro da ordem recebida ou confirmar instruções diretas e claras. A cena demonstra que respeitar a cadeia de comando não elimina a iniciativa de Luppi. | Ambas as escolhas definem `luppi_tactics_activity_unlocked`; vínculo Luppi +3. Guardar a abordagem escolhida como flag, sem converter escolha em avaliação de empatia ou obediência moral. |
| `shared_training_coordination_w13` | Semana 13, após o evento de investigação de Hori na janela 12–13 e após os dois eventos de personagem | Exercício curto de equipe: Ray oferece apoio físico, Luppi trabalha a tática sob a orientação combinada e Hori coordena a comunicação. A escolha de Hori pode priorizar um plano conjunto ou delegar a parte tática dentro dos limites acordados. | Vínculo Ray +2 e Luppi +2; definir `shared_training_coordination_seen`. Sem mudança nos eixos de final, estabilidade do núcleo ou atributos. |
| `ray_orphanage_followup_w15` | Semana 15, após o evento de Ray existente na janela 14–15 | Retorno breve à remessa e às crianças. O texto reconhece a continuidade do estudo e do apoio de Ray; a resposta de Hori varia conforme a contribuição ou o plano escolhido na semana 8. Não introduzir crise, cura ou resultado definitivo para o orfanato. | Definir `ray_orphanage_followup_seen`; vínculo Ray +2. Sem novos recursos, medidores ou finais. |

O agendamento deliberadamente coloca no máximo um evento novo na mesma semana de um evento existente. Nessas semanas, o evento novo só fica elegível depois da âncora indicada, formando uma sequência curta e intencional de até duas cenas; não permitir que flags incompletas façam eventos novos repetirem ou dispararem antes da âncora. O serviço atual pode processar eventos elegíveis em sequência, portanto essa ordem precisa ser testada com a campanha real.

## 6. Efeitos mecânicos e integração

- Vínculos alterados usam somente as chaves já existentes `ray` e `luppi`.
- O custo opcional de 20 créditos sai do saldo atual da campanha; a escolha deve ser indisponível ou validada com mensagem clara quando o saldo for insuficiente. Não permitir saldo negativo.
- Flags novas são booleanas e ficam no mapa de flags já persistido. Não adicionar uma carteira para o orfanato, um eixo narrativo, campo a `route_state` ou versão de save apenas para esta expansão.
- As atividades usam o mesmo custo de ação, preview de consequências, consumo de recursos e cálculo de treino já existentes.
- Uma atividade bloqueada não pode ser aplicada por chamada direta do serviço, mesmo que a interface esteja contornada.
- Não modificar as condições de missão, estabilidade do núcleo, reconhecimento facial, confiança ou finais de Hori.
- Condições neurológicas e experiências psicológicas são fatos narrativos, nunca pontuações de caráter ou condições de vitória/fracasso.

## 7. Progressão e desbloqueios

1. A campanha começa sem as duas atividades novas disponíveis.
2. O evento de Ray da semana 8 habilita `ray_orphanage_logistics` em qualquer uma das duas escolhas; apenas a escolha de contribuição gasta créditos.
3. O evento de Luppi da semana 10 habilita `luppi_tactical_drill` em qualquer uma das duas escolhas.
4. O evento compartilhado só fica elegível depois dos eventos de Ray e Luppi e de sua âncora narrativa de Hori.
5. O retorno de Ray só fica elegível depois do evento de Ray da semana 8 e da âncora existente de Ray na janela 14–15.
6. Os eventos novos não criam nem alteram finais, não alteram o desbloqueio da missão e não exigem completar uma atividade para continuar a campanha.

Usar flags específicas e estáveis, por exemplo: `ray_support_activity_unlocked`, `ray_remittance_contributed`, `ray_remittance_plan`, `luppi_tactics_activity_unlocked`, `luppi_tactics_approach`, `shared_training_coordination_seen` e `ray_orphanage_followup_seen`. Antes da implementação, confirmar que os nomes não colidem com flags atuais.

## 8. Interface e assets

### Interface

- Inserir as atividades nas categorias existentes; usar os cards, preview e estados de seleção atuais.
- Exibir o motivo de bloqueio e a condição de desbloqueio. Não apresentar botão visualmente disponível quando o serviço rejeitar a atividade.
- Eventos continuam na interface de diálogo existente. Resolver retrato pelo personagem que fala; manter o retrato atual de Hori como fallback e nunca exibir um retrato incorreto para Ray ou Luppi.
- Mostrar claramente o custo de 20 créditos na escolha de contribuição e o saldo insuficiente, sem confirmar a escolha.
- Reutilizar fundos, painéis, loja e telas de relações existentes. Não criar uma tela de orfanato ou tela de combate.

### Assets planejados para geração por IA

| Asset | Quantidade/formato | Função e direção visual |
|---|---|---|
| Retrato de Ray | 1 PNG com transparência, RGBA, base de 1024×1536 | Retrato de diálogo em busto. Mulher alta e fisicamente forte; incluir chifres decorrentes de mutação de acordo com o desenho aprovado. Expressão acolhedora e determinada, sem associar a personagem a um diagnóstico ou a uma aparência de criança. |
| Retrato de Luppi | 1 PNG com transparência, RGBA, base de 1024×1536 | Retrato de diálogo em busto. Garota-rato com aparência e silhueta a aprovar pelo autor; expressão concentrada e viva, sem representar autismo como frieza, falta de empatia ou caricatura. |
| Ícone da remessa | 1 PNG quadrado, RGBA, 512×512 | Ícone legível em tamanho pequeno, representando materiais/caixas organizadas para apoio comunitário. Sem texto, símbolos médicos ou rostos de crianças. |
| Ícone de treino tático | 1 PNG quadrado, RGBA, 512×512 | Ícone legível para a atividade de Luppi, representando planejamento de treino sem armas realistas ou marcas/jogos identificáveis. |

Reutilizar os fundos existentes para todas as cenas; não produzir CGs ou cenários novos nesta escala. Usar apenas prompts e composições originais. Revisar recorte, silhueta, contraste, consistência com a arte atual e representações estigmatizantes antes de integrar. Não usar imagens, códigos, nomes, interfaces ou personagens proprietários dos jogos de inspiração.

## 9. Critérios de aceitação

- A fonte ativa carrega os oito eventos existentes e os quatro novos, com IDs únicos e validação atualizada de forma explícita.
- Cada evento novo ocorre no máximo uma vez, depois de sua âncora e dentro da janela definida; nenhuma sequência pula ou bloqueia a missão/finais.
- As duas atividades respeitam bloqueio no serviço e na interface; indisponibilidade não consome ação, recursos ou RNG.
- Preview e resolução aplicam os mesmos modificadores já existentes de motivação, aptidão, risco e mentoria. O custo de Ray nunca deixa créditos negativos.
- Vínculos e flags persistem no formato de save existente, incluindo inventário e equipamento; nenhuma chave nova é adicionada ao `route_state`.
- Retomar uma campanha salva preserva semana, ações, atributos, energia, estresse, motivação, créditos, reputação, vínculos, flags e equipamentos. **Este critério é bloqueador para declarar a integração da Fase 5 pronta**, pois a validação de retomada desta tarefa não foi concluída.
- Retratos de Ray e Luppi são resolvidos pelo diálogo correto; Hori continua usando o retrato existente.
- Nenhum teste ou texto atribui moralidade, empatia ou valor a autismo, dificuldade de reconhecer rostos ou sofrimento psicológico.
- As quatro imagens são originais, aprovadas pelo autor e exportadas nos formatos/tamanhos definidos; não gerar nem integrar assets antes da aprovação.

## 10. Resultado da validação de Save/Load que informa esta especificação

**Resultado: parcial; Save/Load não pode ser declarado funcional ainda.**

- Na primeira inicialização, o snapshot inicial foi rejeitado porque a validação esperava a chave de vínculo `hori`, enquanto o estado inicial contém `ray`, `luppi` e `instructor`. Foi corrigida a lista de chaves em `scripts/campaign_save_service.gd`; depois disso, o autosave inicial e saves após ações foram observados.
- Pela interface foram observados treino, descanso, avanço para a semana 2, compra e equipamento do Caderno de treino, além de uma escolha narrativa da Hori. Um snapshot persistido continha recursos, semana, ações, vínculos, flags, inventário e equipamento.
- Após reiniciar para verificar a retomada, o editor apresentou erros de reload/resolução de tipos de serviços; a cena voltou sem campanha carregada. Não foi possível confirmar o carregamento do snapshot nem uma segunda rodada de salvar/carregar. A causa exata dos erros não foi estabelecida.
- Não foram testados arquivo ausente em uma segunda sessão controlada, recuperação por backup nem arquivo corrompido.
- Não executar novas tentativas do Godot sem autorização e sem primeiro definir uma forma controlada de investigar os erros de carregamento. Os arquivos de save gerados pelo teste devem ser tratados como dados do usuário; não apagá-los como parte da implementação da Fase 5.

## 11. Plano de implementação em tarefas pequenas

Cada etapa deve ser autorizada e validada separadamente; não antecipar etapas:

1. **Fechar a retomada do Save/Load:** investigar estaticamente os erros de carregamento e preparar uma reprodução funcional controlada, preservando os saves existentes. Não iniciar conteúdo novo até confirmar a retomada.
2. **Integrar a estrutura dos eventos:** confirmar flags-âncora, acrescentar somente os quatro eventos e ajustar a validação de oito para doze; testar unicidade, ordem, janelas e continuidade da missão.
3. **Adicionar o bloqueio por `unlock_flag`:** implementar suporte opcional no serviço e na UI, mantendo inalteradas as atividades atuais; adicionar testes focados de bloqueio e consumo de recursos.
4. **Adicionar a atividade de Ray:** inserir dados e validar crédito, energia, estresse, vínculo e bloqueio, sem introduzir saldo do orfanato.
5. **Adicionar a atividade de Luppi:** inserir dados e validar modificadores existentes de treino, mentoria e falha.
6. **Integrar retratos e ícones aprovados:** importar apenas assets originais revisados e verificar enquadramento/fallback nos diálogos e cards existentes.
7. **Revisão integrada curta:** percorrer manualmente a sequência nova uma vez e executar apenas os testes focados aprovados; conferir saves, custos, relações, ordem narrativa e critérios de aceitação.

Não iniciar uma etapa posterior para contornar uma falha da anterior. Não incluir conteúdo adicional ou refatoração geral no mesmo lote.

# Plano de estudo comparativo — engenharia reversa por observação

**Método:** usar jogo adquirido legitimamente, documentação pública e gravações próprias. Medir entradas e saídas, sem extrair assets, sem contornar DRM/anti-cheat e sem copiar scripts proprietários. Distinguir hipótese de fato observado. As tabelas abaixo são ponto de partida, não prova das fórmulas exatas.

## Uma Musume: Pretty Derby — o que estudar

| Tema | Mecânica documentada | O que observar e registrar | Tradução original para Hero Trainer |
|---|---|---|---|
| Cenário de carreira | URA 72 turnos normais + 6 finais | duração por fase, tela de metas, condição de fim | 16 semanas × 3 blocos, 3 avaliações e final |
| Atributos | Speed, Stamina, Power, Guts, Wit | o que cada stat realmente altera | POT, RES, TEC, TEO, SIN com funções distintas |
| Ações | treino, descanso, recreação, enfermaria, corrida; compra de habilidade sem turno | qual tela revela ganhos, custo de energia e risco | atividade com ganho previsto e custo explícito |
| Estado | energia, humor em cinco níveis, condições | como falha/recuperação se relacionam | Energia, motivação, estresse, lesão |
| Treino de suporte | cartas aparecem em instalações, vínculo permite bonus de amizade | distribuição, sinergia, tooltip e pistas | mentores e colegas em atividade semanal |
| Aptidões | categoria de distância, superfície, estilo | especialização, condição de habilidades | aptidão de classe e perícias de missão |
| Eventos | cartões, gatilhos, randomização, escolhas | momento de disparo, consequência, repetição | cenas condicionais à agenda/estado |
| Objetivos | metas de classificação e competição | quando aviso aparece e pressão do prazo | exames e missões obrigatórias com preparação |
| Progressão entre runs | veteran, legacies, sparks | por que repetir carreira compensa | desbloqueios narrativos e novos começos sem gacha |

**Notas verificadas:** 72+6 aplicam-se ao cenário URA citado, NÃO a todos os cenários. Guia de treino inclui instalações que sobem de nível com repetição, Wit com recuperação de energia e Friendship Training, que não precisa ser copiado numericamente.

**Páginas:** https://umamusu.wiki/Scenario ; https://umamusu.wiki/Game:Stat_Training ; https://umamusume.gg/career-training-guide/ ; https://umamusu.wiki/Game:Skills

## Princess Maker 2 — o que estudar

| Tema | Mecânica documentada | O que observar e registrar | Tradução original |
|---|---|---|---|
| Tempo | oito anos, meses divididos em três segmentos | duração real, ações disponíveis e interrupções | semestre acadêmico em blocos |
| Atividades | escola, trabalho, descanso, viagem | combinações de ganhos, custo, qualificação | treino, estudo, estágio, lazer e missão |
| Recursos | ouro, estresse, atributos, reputações | déficits, custos de recuperação | créditos acadêmicos, estresse, energia |
| Habilidades | combate e magia, habilidades sociais | uso fora da batalha e em finais | missão e narrativa com checks mistos |
| Vida social | reputação, moralidade, sensibilidade, eloquência | requisitos de cena, comportamentos | eixos de valor + confiança com colegas |
| Consequências | estados negativos e variações | impacto do sobretrabalho e descanso | alerta de carga, lesões e isolamento |
| Finais | precedência de rotas, profissão, resultado | quantos critérios e ordem de desempate | final composto: carreira + pessoa + equipe |

**Nota sobre 'exato':** há diferenças entre versões do jogo; fórmulas de guias são versões comunitárias, não extraídas do projeto oficial. Registrar plataforma/versão/data de cada teste. Um guia Steam avisa que mescla fontes antigas; portanto, use como hipótese a confirmar no jogo.

**Páginas:** https://steamcommunity.com/sharedfiles/filedetails/?id=771709910 ; https://princessmaker.nekoweb.org/pm2/daughter.html

## Protocolo de coleta

Para cada mecânica, preencher:

```text
ID: UM-TR-004
Fonte: [URL, captura própria ou sessão observada]
Versão/plataforma: [PC/Steam/global/etc.]
Hipótese: [o que se espera]
Entrada: [turno, atributos, energia, ação]
Saída: [ganhos, custo, evento, falha, objetivo]
Repetições: [n, mesma condição de início?]
Confiança: [confirmada / observada uma vez / inferida]
Decisão de design: [incorporar / simplificar / descartar]
Risco de IP: [mecânica abstrata OK; texto/arte/áudio/interface não copiar]
```

## Matriz de decisão

**Copiar o princípio de design:** oportunidade estratégica, custo de oportunidade, risco calculado, arco pessoal, ramificações.

**Não copiar:** textos e arquivos dos jogos, designs de personagens, localização específica de controles e layouts idênticos, músicas/vozes, nomes de habilidades inconfundíveis, imagens de UI, valores proprietários que dependam de acesso indevido.

**Critério de entrega da pesquisa:** 12 fichas registradas, 3 capturas próprias de cada interface essencial, 3 exemplos de escolhas com custo, 2 observações de condição negativa, comparação de pelo menos 2 finais, matriz 'adotar/adaptar/rejeitar'.

# Bíblia visual original — Hero Trainer

## Identidade

**Gênero visual:** visual novel 2D / fantasia científica acadêmica. Anime ilustrado de alta legibilidade, contornos precisos sem rascunhos, cel shading suave em dois níveis, materiais ligeiramente pintados, cores vivas com neutros frios, arquitetura futurista acolhedora. A paleta é uma sugestão **original**, não cópia de uma franquia: índigo escuro #232944, azul-petróleo #2C7387, verde-menta #7AC8C5, coral #E98D79, dourado discreto #E6BD68, creme #F5F0E8.

**Contorno:** uniforme, cor grafite #25273B, espessura óptica equivalente a 2–3 px em canvas 1024, ligeiramente mais grosso no contorno externo. **Luz:** key light suave superior esquerda, sombra fria baixa-saturação à direita, reflexo secundário ciano mínimo. **Volume:** duas bandas de cel shading, 1 faixa de brilho nos cabelos, materiais sem 3D/fotorrealismo. **Rostos:** feições adultas 18+, olhos expressivos, nariz e boca sutis, proporções coerentes entre personagens. **Roupas:** academia própria, sem logotipos, emblemas ou códigos de vestuário de Honkai.

## Tamanhos e composição

- Sprite principal: canvas 1024×1536 PNG RGBA; personagem 75–85% da altura; rosto ancorado na mesma posição para todas as expressões; plano médio coxa/joelho, sem cenário.
- Retrato de diálogo: corte gerado **do mesmo arquivo-base**, não reinterpretação; 768×768 ou proporção escolhida conforme layout.
- Expressões: neutral, happy, sad, angry, surprised, embarrassed, determined, tired. Prioridade MVP: neutral, happy, worried, determined.
- Backgrounds: 1920×1080 (16:9) sem pessoas, áreas menos detalhadas onde sprites/UI irão aparecer.
- UI: fundo escuro azulado com painéis levemente translúcidos e bordas de 1 px; hierarquia tipográfica legível, números monoespaçados para atributos; efeitos pequenos e consistentes.

## Fluxo de consistência

1. Fechar **silhueta e aparência** antes de pedir expressões. Criar uma folha de modelo com rosto frontal, 3/4, corpo, roupa, acessórios e paleta.
2. Gerar **uma única imagem-base** aprovada por personagem. Fixar seed/configuração se a ferramenta permitir; salvar o PNG e o prompt de produção.
3. Para expressões, usar modo **EDITAR IMAGEM** com base original e máscara limitada ao rosto/olhos/boca/sobrancelhas. Não pedir novas gerações completas. Preservar cabelos, tecido, composição, iluminação e proporção.
4. Comparar base e 4 variantes sobrepostas a 50% de opacidade. Testar landmarks: olhos, ombros, gola, mãos, bordo inferior. Diferença fora de área editada é defeito.
5. Se a ferramenta não oferece travamento preciso de pixels, adotar sprites em camadas (base corpo + camadas de sobrancelhas/olhos/boca em Godot ou editor raster). **Prompt sozinho não garante identidade pixel-perfect**.
6. Exportar RGBA, conferir transparência sem halo, revisar escala de todos os sprites na UI.

## Negative prompt (quando o gerador aceitar)

`3d render, photorealistic, rough sketch, excessive bloom, airbrushed plastic skin, heavy gradients, mismatched eye placement, extra fingers, malformed anatomy, cropped head, duplicated accessories, uneven lighting, watermark, text, logo, game franchise symbols, different outfit, inconsistent facial proportions`

## Checklist de arte

- [ ] Rosto adulto coerente; aparência aprovada pelo autor.
- [ ] Mesmo canvas, posição da cabeça e linha dos ombros entre expressões.
- [ ] Mesma direção de luz, sombra, saturation e contorno em todos os sprites.
- [ ] Sem itens de franquias; todos os materiais e acessórios são originais.
- [ ] Transparência e margem de segurança uniformes.
- [ ] Leitura em 1366×768 sem poluição visual.
- [ ] Arquivos de fonte/asset têm licença documentada; não redistribuir fontes proprietárias.

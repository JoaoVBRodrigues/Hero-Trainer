# Assets da Fase 3 — prompts e consistência

## Proveniência dos prompts

Os sete arquivos listados em [10_ASSET_MANIFEST.md](../docs/10_ASSET_MANIFEST.md) foram fornecidos pelo usuário. O material recebido nesta tarefa não incluiu os prompts originais nem identificou ferramenta, autoria ou seed de geração. Nenhum prompt de geração foi inventado ou executado durante a integração; as imagens originais foram preservadas sem edição.

Se o autor fornecer os prompts de produção, anexá-los abaixo com a ferramenta/versão e parâmetros realmente usados. Não inferir nem reconstruir prompts a partir dos pixels.

| Asset | Prompt de produção original | Ferramenta/versão | Seed/parâmetros | Registro |
|---|---|---|---|---|
| Cenários e expressões da Hori fornecidos | Não informado | Não informado | Não informado | Pendente de metadados do autor |

## Regras de consistência usadas na integração

- A Bíblia Visual em `docs/03_BIBLIA_VISUAL.md` e o cânone em `docs/05_CANONE_PERSONAGENS.md` prevalecem sobre qualquer inferência visual.
- As expressões usam a mesma caixa, alinhamento e modo de escala `KEEP_ASPECT_CENTERED`; a arte original e o canal alfa não são alterados.
- A escolha entre neutral, happy, worried e determined é um mapeamento local de apresentação. Não muda diálogo, flags, resultados ou interpretação canônica.
- Os fundos são cortados proporcionalmente com `KEEP_ASPECT_COVERED` e recebem tint índigo para preservar contraste; os arquivos-fonte continuam intactos.
- Não há retratos de Ray ou Luppi nesta entrega. A interface mantém placeholders identificados em vez de gerar ou reutilizar arte.
- Novas expressões devem partir da arte-base aprovada, manter posição facial, roupa, proporção e iluminação, e registrar o prompt e a proveniência reais no manifesto.

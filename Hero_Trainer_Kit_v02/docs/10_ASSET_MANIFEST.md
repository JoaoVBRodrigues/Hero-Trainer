# Manifesto de assets — Fase 3

Arquivos encontrados em `assets/phase3/`. Os arquivos de origem permanecem inalterados. “Transparência” descreve os dados da imagem, não o fundo contextual aplicado pela interface.

| Asset | Caminho | Dimensões | Formato real | Transparência | Uso | Status |
|---|---|---:|---|---|---|---|
| Sala da academia | `assets/phase3/backgrounds/academy_room_bg.png` | 1672×941 | PNG RGB, 8 bits | Não | Dashboard inicial e atividades gerais | Integrado |
| Laboratório | `assets/phase3/backgrounds/laboratory_bg.png` | 1280×721 | WebP lossless | Não | Estudo/controle e eventos de núcleo/Ruptura | Integrado; extensão `.png` não corresponde ao conteúdo WebP |
| Observatório | `assets/phase3/backgrounds/observatory_bg.png` | 1280×721 | WebP lossless | Não | Relações, missão e epílogo | Integrado; extensão `.png` não corresponde ao conteúdo WebP |
| Hori — neutral | `assets/phase3/characters/hori/hori_neutral.png` | 765×1024 | PNG indexado, 8 bits, tabela `tRNS` | Sim | Painel da personagem, diálogo e epílogo | Integrado |
| Hori — happy | `assets/phase3/characters/hori/hori_happy.png` | 765×1024 | PNG indexado, 8 bits, tabela `tRNS` | Sim | Evento de reconhecimento e escolhas | Integrado |
| Hori — worried | `assets/phase3/characters/hori/hori_worried.png` | 765×1024 | PNG indexado, 8 bits, tabela `tRNS` | Sim | Protocolo, confronto e falha recuperável do Pulso | Integrado |
| Hori — determined | `assets/phase3/characters/hori/hori_determined.png` | 765×1024 | PNG indexado, 8 bits, tabela `tRNS` | Sim | Investigação e missão | Integrado |

## Decodificação e proveniência

O dashboard detecta o formato pelos bytes iniciais. PNG é decodificado por `Image.load_png_from_buffer`; WebP por `Image.load_webp_from_buffer`. Assim, os dois originais WebP mantêm o nome e os bytes recebidos, embora a extensão `.png` seja incorreta.

Os arquivos foram fornecidos no workspace pelo usuário. Nenhum asset externo foi baixado ou adicionado, e nenhuma arte foi gerada nesta tarefa. Autor, licença e condições de redistribuição não foram incluídos com os arquivos; confirmar esses dados antes de publicar ou redistribuir o projeto.

Retratos de Ray e Luppi: ausentes nesta fase; placeholders nativos são usados. Não foram gerados nem substituídos por outras imagens.

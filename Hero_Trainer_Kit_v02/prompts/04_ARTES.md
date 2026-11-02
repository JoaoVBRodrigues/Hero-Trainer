> **ATENÇÃO v0.2:** este é um prompt antigo. Use também os prompts 06/07 e a bíblia de cânone; em caso de conflito, eles prevalecem.

# PROMPTS VISUAIS — sem nomes de jogos, estilos ou franquias

## A. MASTER STYLE (prefixo fixo em TODOS os prompts)

`Original 2D Japanese-inspired science-fantasy visual novel illustration, professional hand-drawn animation character design, clean precise graphite-indigo line art, consistent medium-weight silhouette outlines, polished two-step soft cel shading, subtle hand-painted material accents, expressive adult anime facial features, balanced character proportions, warm ivory skin highlights, gentle upper-left key light, faint cool cyan bounce light from lower right, controlled saturated accents on muted navy and teal foundation, crisp readable silhouette, cohesive academy science-fiction art direction, no logos, no text, no watermark.`

**Produção:** salve esta string como `STYLE_LOCK_V01`; não remova/adapte entre personagens a menos que a Bíblia Visual mude. Não confundir 'mesmo estilo' com copiar design de uma franquia. A qualidade exata depende do modelo, base e edição; prompt não garante consistência.

## B. PERSONAGEM — modelo neutro

`[MASTER STYLE]. A unique adult academy cadet, age 20, [CHARACTER APPEARANCE: exact eye shape, hairstyle, color, scars, accessories, body build], wearing an original tailored navy and ivory academy field uniform with restrained teal seams and coral/gold role accents, no existing franchise insignia. Neutral attentive expression, front-facing three-quarter torso position, centered composition, camera at chest level, consistent eye-line, shoulders fully visible, full upper-body sprite down to mid-thigh, arms relaxed, no props blocking the face, transparent background, 1024 x 1536 canvas, soft shadow to character right, polished production character sprite.`

**Negativo:** `no 3D, no photorealism, no messy sketch, no extreme bloom, no heavy gradients, no logo, no texts, no fan franchise uniform, no extra fingers, no cropped head, no dynamic action pose`.

## C. EXPRESSION EDIT — usar com a IMAGEM-BASE ANEXADA

`EDIT THE ATTACHED APPROVED MASTER SPRITE ONLY. Change ONLY the facial expression to [EXPRESSION], adjusting eyebrows, eyelids, pupils, mouth and the smallest necessary cheek features. Preserve IDENTICAL canvas size, camera, body posture, eye positions, face outline, hair strands and color, outfit, accessories, hands, silhouette, shadows, line thickness, color palette, highlights, lighting direction, image crop and background transparency. Pixel alignment of all untouched areas is essential. Do not redraw the whole character, do not change hairstyle, clothing or chest/shoulder silhouette. Use face-local edits only.`

Expressões recomendadas: `gentle restrained smile`; `tense worried, lips slightly parted`; `determined, eyes narrowed, jaw set`; `exhausted, half-lidded, subtle under-eye shadow`.

**Aviso:** Se o modelo mudar peças do corpo, substitua pela base e faça edição por máscara/camadas. Compare em overlay, não aceite variantes desalinhadas.

## D. FUNDO — sala de aula

`[MASTER STYLE, ENVIRONMENT APPLICATION]. Empty futuristic academy classroom, 16:9 wide composition, original clean geometry, restrained navy-ivory-teal palette, warm daylight entering from upper left, rows of modular desks and holographic diagrams with NO legible writing, delicate plants, believable perspective and architecture, clear central foreground reserved for character sprites, calmer lower quarter reserved for dialogue UI, controlled midground detail, gentle painted surfaces, no people, no logos, no text, 1920 x 1080.`

## E. FUNDO — laboratório

`[MASTER STYLE, ENVIRONMENT APPLICATION]. Empty advanced anomaly-research laboratory in a humane science-fantasy academy, safe luminous containment chamber, glass partitions and teal illumination, subtle orange emergency markers, foreground clean for superimposed character sprites, consistent upper-left key light, 16:9 1920 x 1080, no people, no text, no franchise iconography.`

## F. FUNDO — campo de treinamento

`[MASTER STYLE, ENVIRONMENT APPLICATION]. Empty academy combat simulation arena with modular surfaces, geometric training barriers, elevated observation deck, soft sunset lighting from upper left, muted navy and cream architecture with restrained coral accents, a wide uncluttered central space, anime background painting with clean perspective, no people, no text, 1920 x 1080.`

## G. UI — dashboard original

`Original sci-fi academic management game dashboard, refined 2D visual novel interface, accessible hierarchy, deep navy #232944 panels, cream #F5F0E8 typography, turquoise #7AC8C5 highlights, coral #E98D79 warnings, five legible stat modules, week progress timeline, portrait focal panel and action cards with concise gain/cost/risk previews, mature elegant anime game UX, designed for desktop 16:9 with minimum 1366x768, no copyrighted logo or icons, no photorealism, no clutter. Note: this is only a visual concept; real interface elements must be recreated as editable Godot controls.`

## Registro obrigatório para cada imagem

`asset_id / prompt_version / image_model / input_master_sprite / source_dimensions / render_dimensions / palette / lighting / approved_by / license_status / notes`. Salvar imagem-base como fonte canônica. Jamais alegar que expressão está alinhada sem comparação efetiva.

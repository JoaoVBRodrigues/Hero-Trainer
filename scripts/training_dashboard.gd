extends Control

signal week_completed(week_number: int)

const TrainingServiceScript = preload("res://scripts/training_service.gd")
const TrainingThemeScript = preload("res://scripts/training_theme.gd")
const NarrativeServiceScript = preload("res://scripts/narrative_service.gd")
const SCENE_ASSET_PATHS: Dictionary[StringName, String] = {
	&"academy": "res://assets/phase3/backgrounds/academy_room_bg.png",
	&"laboratory": "res://assets/phase3/backgrounds/laboratory_bg.png",
	&"observatory": "res://assets/phase3/backgrounds/observatory_bg.png",
}
const HORI_EXPRESSION_PATHS: Dictionary[StringName, String] = {
	&"neutral": "res://assets/phase3/characters/hori/hori_neutral.png",
	&"happy": "res://assets/phase3/characters/hori/hori_happy.png",
	&"worried": "res://assets/phase3/characters/hori/hori_worried.png",
	&"determined": "res://assets/phase3/characters/hori/hori_determined.png",
}
const EVENT_SCENE_PRESENTATION: Dictionary[StringName, StringName] = {
	&"hori_core_protocol_w03": &"laboratory",
	&"hori_echo_confrontation_w11": &"observatory",
	&"hori_rupture_investigation_w12": &"laboratory",
	&"hori_ray_aftermath_w14": &"observatory",
}
const STAT_LABELS: Dictionary[StringName, String] = {
	&"pot": "Potência",
	&"res": "Resistência",
	&"tec": "Técnica",
	&"teo": "Teoria",
	&"sin": "Sincronia",
}

enum HoriPresentation { RIGHT_SIDE, CENTER_STAGE }

var _service: TrainingService
var _narrative_service: NarrativeService
var _state: TrainingState
var _selected_activity: StringName = &""
var _hori_presentation: HoriPresentation = HoriPresentation.RIGHT_SIDE
var _scene_textures: Dictionary[StringName, Texture2D] = {}
var _hori_expression_textures: Dictionary[StringName, Texture2D] = {}
var _background: TextureRect
var _character_stage: Control
var _management_ui: Control
var _character_name_label: Label
var _profile_name_label: Label
var _week_label: Label
var _actions_label: Label
var _semester_progress: ProgressBar
var _portrait: TextureRect
var _portrait_placeholder: Control
var _portrait_placeholder_label: Label
var _stat_labels: Dictionary[StringName, Label] = {}
var _stat_bars: Dictionary[StringName, ProgressBar] = {}
var _resource_bars: Dictionary[StringName, ProgressBar] = {}
var _resource_values: Dictionary[StringName, Label] = {}
var _bond_values: Dictionary[StringName, Label] = {}
var _credits_value: Label
var _activity_buttons: Dictionary[StringName, Button] = {}
var _activity_status_labels: Dictionary[StringName, Label] = {}
var _preview_title: Label
var _preview_status: Label
var _preview_body: Label
var _feedback_label: Label
var _confirm_button: Button
var _cancel_button: Button
var _advance_button: Button
var _narrative_panel: PanelContainer
var _narrative_overlay: Control
var _narrative_title: Label
var _narrative_meta: Label
var _narrative_speaker: Label
var _narrative_body: Label
var _narrative_result: Label
var _dialogue_history_toggle: Button
var _dialogue_history_scroll: ScrollContainer
var _dialogue_history_content: VBoxContainer
var _narrative_choice_scroll: ScrollContainer
var _mission_steps: HBoxContainer
var _mission_step_labels: Array[Label] = []
var _mission_requirement_note: Label
var _narrative_choices: VBoxContainer
var _narrative_continue: Button
var _active_event: Dictionary = {}
var _active_dialogue: Array = []
var _dialogue_index: int = 0
var _narrative_mode: StringName = &""
var _active_mission_stage: Dictionary = {}
var _active_event_id: StringName = &""
var _dialogue_history_open: bool = false


func _ready() -> void:
	_service = TrainingServiceScript.new()
	var project_data_loaded: bool = _service.load_project_data()
	_narrative_service = NarrativeServiceScript.new()
	var narrative_data_loaded: bool = false
	if project_data_loaded:
		_narrative_service.set_limits(
			_service.get_attribute_cap(),
			_service.get_resource_cap(),
			_service.get_reputation_cap(),
			_service.get_bond_cap()
		)
		narrative_data_loaded = _narrative_service.load_project_data()
	_load_phase3_assets()
	_build_interface()
	if not project_data_loaded:
		_feedback_label.text = "Não foi possível carregar os dados de treinamento."
		_set_activity_buttons_enabled(false)
		return
	if not narrative_data_loaded:
		_feedback_label.text = "Não foi possível carregar os dados da campanha narrativa."
		_set_activity_buttons_enabled(false)
		return
	_state = _service.create_initial_state()
	_refresh_state()
	_process_narrative_flow()


func set_character_presentation(
	display_name: String,
	portrait_texture: Texture2D = null
) -> void:
	if _character_name_label != null:
		_character_name_label.text = display_name
	if _profile_name_label != null:
		_profile_name_label.text = display_name
	if _portrait != null:
		var selected_texture: Texture2D = portrait_texture
		if selected_texture == null and display_name.to_lower() == "hori":
			selected_texture = _hori_expression_textures.get(&"neutral")
		_portrait.texture = selected_texture
		_portrait_placeholder.visible = selected_texture == null
		_portrait_placeholder_label.text = (
			"RETRATO NÃO DISPONÍVEL"
			if selected_texture == null
			else ""
		)
		_update_hori_presentation()


func _load_phase3_assets() -> void:
	for scene_id: StringName in SCENE_ASSET_PATHS:
		var texture: Texture2D = _load_phase3_texture(SCENE_ASSET_PATHS[scene_id])
		if texture != null:
			_scene_textures[scene_id] = texture
	for expression_id: StringName in HORI_EXPRESSION_PATHS:
		var texture: Texture2D = _load_phase3_texture(
			HORI_EXPRESSION_PATHS[expression_id]
		)
		if texture != null:
			_hori_expression_textures[expression_id] = texture


func _load_phase3_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		push_warning("Asset visual ausente; placeholder será usado: %s" % path)
		return null
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	var load_error: Error
	if bytes.slice(0, 8) == PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]):
		load_error = image.load_png_from_buffer(bytes)
	elif (
		bytes.slice(0, 4).get_string_from_ascii() == "RIFF"
		and bytes.slice(8, 12).get_string_from_ascii() == "WEBP"
	):
		load_error = image.load_webp_from_buffer(bytes)
	else:
		push_error("Formato de imagem não reconhecido: %s" % path)
		return null
	if load_error != OK:
		push_error(
			"Falha ao decodificar %s: %s"
			% [path, error_string(load_error)]
		)
		return null
	return ImageTexture.create_from_image(image)


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = TrainingThemeScript.create_theme()

	var background := ColorRect.new()
	background.color = TrainingThemeScript.INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_background = TextureRect.new()
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.texture = _scene_textures.get(&"academy")
	_background.modulate = Color(1.0, 1.0, 1.0, 0.74)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.visible = _background.texture != null
	add_child(_background)

	var backdrop_tint := ColorRect.new()
	backdrop_tint.color = Color(TrainingThemeScript.INK, 0.4)
	backdrop_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop_tint)

	_build_character_stage()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	_management_ui = margin

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	layout.add_child(_build_header())
	layout.add_child(_build_main_panels())
	layout.add_child(_build_preview_dock())
	_build_narrative_overlay()


func _build_header() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.96),
			Color(TrainingThemeScript.GOLD, 0.62),
			12,
			1
		)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 1)
	row.add_child(identity)
	var eyebrow := _make_label("HERO TRAINER  /  ACADEMIA", 11)
	eyebrow.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	identity.add_child(eyebrow)
	_character_name_label = _make_label("Hori", 24)
	identity.add_child(_character_name_label)

	var progress_column := VBoxContainer.new()
	progress_column.custom_minimum_size.x = 200
	progress_column.add_theme_constant_override("separation", 3)
	row.add_child(progress_column)
	var progress_header := HBoxContainer.new()
	progress_header.add_theme_constant_override("separation", 8)
	progress_column.add_child(progress_header)
	var progress_title := _make_label("PROGRESSO DO SEMESTRE", 10)
	progress_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_title.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	progress_header.add_child(progress_title)
	_week_label = _make_label("", 13)
	progress_header.add_child(_week_label)
	_semester_progress = ProgressBar.new()
	_semester_progress.min_value = 0
	_semester_progress.max_value = maxi(1, _service.get_total_weeks())
	_semester_progress.show_percentage = false
	_semester_progress.custom_minimum_size.y = 12
	progress_column.add_child(_semester_progress)
	_actions_label = _make_label("", 12)
	_actions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_column.add_child(_actions_label)
	return panel


func _build_main_panels() -> HBoxContainer:
	var panels := HBoxContainer.new()
	panels.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panels.add_theme_constant_override("separation", 10)
	panels.add_child(_build_character_panel())
	panels.add_child(_build_activity_panel())
	return panels


func _build_character_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.88
	panel.custom_minimum_size.x = 270
	var panel_style := TrainingThemeScript.make_panel_style(
		Color(TrainingThemeScript.PANEL, 0.91),
		Color(TrainingThemeScript.MINT, 0.48),
		12,
		1
	)
	panel_style.content_margin_top = 4
	panel_style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", panel_style)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 7)
	scroll.add_child(content)
	content.add_child(_make_section_title("CADETE  /  PERFIL"))
	_profile_name_label = _make_label("Hori", 16)
	_profile_name_label.add_theme_color_override("font_color", TrainingThemeScript.CREAM)
	content.add_child(_profile_name_label)
	var profile_detail := _make_label("ACADEMIA  ·  TREINAMENTO", 9)
	profile_detail.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	content.add_child(profile_detail)
	content.add_child(_make_section_title("ATRIBUTOS"))
	content.add_child(_build_stat_grid())
	content.add_child(_make_section_title("CONDIÇÃO"))
	_add_resource_row(content, &"energy", "Energia", TrainingThemeScript.MINT)
	_add_resource_row(content, &"stress", "Estresse", TrainingThemeScript.CORAL)
	_add_resource_row(content, &"motivation", "Motivação", TrainingThemeScript.GOLD)
	content.add_child(_build_economy_row())
	content.add_child(_make_section_title("VÍNCULOS"))
	content.add_child(_build_bond_row())
	return panel


func _build_character_stage() -> void:
	_character_stage = Control.new()
	_character_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_character_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_character_stage.resized.connect(_update_hori_presentation)
	add_child(_character_stage)

	_portrait = TextureRect.new()
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture = _hori_expression_textures.get(&"neutral")
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_character_stage.add_child(_portrait)

	var placeholder := CenterContainer.new()
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_character_stage.add_child(placeholder)
	var placeholder_text := _make_label("◈\nRETRATO PROVISÓRIO", 12)
	placeholder_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_text.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	placeholder.add_child(placeholder_text)
	_portrait_placeholder = placeholder
	_portrait_placeholder_label = placeholder_text
	_portrait_placeholder.visible = _portrait.texture == null
	_set_hori_presentation(HoriPresentation.RIGHT_SIDE)
	call_deferred("_update_hori_presentation")


func _build_stat_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 5)
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var card := PanelContainer.new()
		var card_style := TrainingThemeScript.make_panel_style(
			TrainingThemeScript.PANEL_MUTED,
			Color(TrainingThemeScript.MINT, 0.20),
			8,
			1
		)
		card_style.content_margin_top = 4
		card_style.content_margin_bottom = 4
		card.add_theme_stylebox_override(
			"panel",
			card_style
		)
		var stat_content := VBoxContainer.new()
		stat_content.add_theme_constant_override("separation", 3)
		card.add_child(stat_content)
		var heading := HBoxContainer.new()
		stat_content.add_child(heading)
		var name_label := _make_label(STAT_LABELS[stat_id], 11)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(name_label)
		var value_label := _make_label("", 12)
		value_label.add_theme_color_override("font_color", TrainingThemeScript.CREAM)
		heading.add_child(value_label)
		var bar := _make_progress_bar(_service.get_attribute_cap(), TrainingThemeScript.MINT)
		bar.custom_minimum_size.y = 7
		stat_content.add_child(bar)
		grid.add_child(card)
		_stat_labels[stat_id] = value_label
		_stat_bars[stat_id] = bar
	return grid


func _add_resource_row(
	parent: VBoxContainer,
	resource_id: StringName,
	label_text: String,
	bar_color: Color
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var name_label := _make_label(label_text, 11)
	name_label.custom_minimum_size.x = 66
	row.add_child(name_label)
	var bar := _make_progress_bar(_service.get_resource_cap(), bar_color)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 9
	row.add_child(bar)
	var value_label := _make_label("", 11)
	value_label.custom_minimum_size.x = 48
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	_resource_bars[resource_id] = bar
	_resource_values[resource_id] = value_label


func _build_economy_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var credits_card := _make_metric_card("CRÉDITOS")
	row.add_child(credits_card)
	var reputation_card := _make_metric_card("REPUTAÇÃO")
	row.add_child(reputation_card)
	return row


func _make_metric_card(title: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style := TrainingThemeScript.make_panel_style(
		TrainingThemeScript.PANEL_MUTED,
		Color(TrainingThemeScript.GOLD, 0.26),
		8,
		1
	)
	card_style.content_margin_top = 4
	card_style.content_margin_bottom = 4
	card.add_theme_stylebox_override(
		"panel",
		card_style
	)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	card.add_child(content)
	var title_label := _make_label(title, 9)
	title_label.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	content.add_child(title_label)
	var value_label := _make_label("", 12)
	content.add_child(value_label)
	if title == "CRÉDITOS":
		_credits_value = value_label
	elif title == "REPUTAÇÃO":
		var bar := _make_progress_bar(_service.get_reputation_cap(), TrainingThemeScript.GOLD)
		bar.custom_minimum_size.y = 7
		content.add_child(bar)
		_resource_bars[&"reputation"] = bar
		_resource_values[&"reputation"] = value_label
	return card


func _build_bond_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	for bond_id: StringName in _service.get_bond_ids():
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_style := TrainingThemeScript.make_panel_style(
			TrainingThemeScript.PANEL_MUTED,
			Color(TrainingThemeScript.PETROL.lightened(0.35), 0.56),
			8,
			1
		)
		card_style.content_margin_top = 4
		card_style.content_margin_bottom = 4
		card.add_theme_stylebox_override(
			"panel",
			card_style
		)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 2)
		card.add_child(content)
		var name_label := _make_label(_display_bond_name(bond_id), 9)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(name_label)
		var value_label := _make_label("", 11)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(value_label)
		row.add_child(card)
		_bond_values[bond_id] = value_label
	return row


func _build_activity_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.45
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.91),
			Color(TrainingThemeScript.MINT, 0.48),
			12,
			1
		)
	)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)

	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title := _make_section_title("ROTINA  /  ATIVIDADES")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var block_hint := _make_label("1 atividade = 1 bloco", 10)
	block_hint.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	heading.add_child(block_hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var activity_groups := VBoxContainer.new()
	activity_groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	activity_groups.add_theme_constant_override("separation", 5)
	scroll.add_child(activity_groups)

	var group_ids: Array[String] = []
	var grouped_activities: Dictionary = {}
	for activity_id: StringName in _service.get_activity_ids():
		var category: String = _service.get_activity_category(activity_id)
		if not grouped_activities.has(category):
			group_ids.append(category)
			grouped_activities[category] = []
		grouped_activities[category].append(activity_id)

	for category: String in group_ids:
		var category_label := _make_section_title(
			_category_label(category).to_upper()
		)
		activity_groups.add_child(category_label)
		var cards := GridContainer.new()
		cards.columns = 2
		cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards.add_theme_constant_override("h_separation", 7)
		cards.add_theme_constant_override("v_separation", 6)
		activity_groups.add_child(cards)
		for activity_id: StringName in grouped_activities[category]:
			cards.add_child(_make_activity_button(activity_id))
	return panel


func _make_activity_button(activity_id: StringName) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 76)
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_activity_selected.bind(activity_id))

	var inset := MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.add_theme_constant_override("margin_left", 5)
	inset.add_theme_constant_override("margin_top", 3)
	inset.add_theme_constant_override("margin_right", 5)
	inset.add_theme_constant_override("margin_bottom", 3)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inset)
	var labels := VBoxContainer.new()
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_theme_constant_override("separation", 1)
	inset.add_child(labels)
	var name_label := _make_label(_service.get_activity_label(activity_id), 12)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(name_label)
	var meta_label := _make_label(
		"%s  ·  Custo %d EN"
		% [
			_category_label(_service.get_activity_category(activity_id)),
			_service.get_activity_energy_cost(activity_id),
		],
		10
	)
	meta_label.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(meta_label)
	var status_label := _make_label("", 10)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(status_label)

	_activity_buttons[activity_id] = button
	_activity_status_labels[activity_id] = status_label
	return button


func _build_preview_dock() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 132
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.93),
			Color(TrainingThemeScript.MINT, 0.62),
			12,
			1
		)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var preview_column := VBoxContainer.new()
	preview_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_column.add_theme_constant_override("separation", 3)
	row.add_child(preview_column)
	_preview_title = _make_label("PRÉVIA DO PLANO", 14)
	_preview_title.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	preview_column.add_child(_preview_title)
	_preview_status = _make_label("Escolha uma atividade para ver seus efeitos.", 11)
	preview_column.add_child(_preview_status)
	_preview_body = _make_label(
		"A prévia não altera o estado. A confirmação consome um bloco de ação.",
		12
	)
	_preview_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_column.add_child(_preview_body)
	_feedback_label = _make_label("", 10)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_column.add_child(_feedback_label)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 176
	actions.add_theme_constant_override("separation", 5)
	row.add_child(actions)
	_confirm_button = Button.new()
	_confirm_button.text = "Confirmar"
	_confirm_button.custom_minimum_size.y = 36
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm_pressed)
	actions.add_child(_confirm_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancelar prévia"
	_cancel_button.custom_minimum_size.y = 32
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_on_cancel_pressed)
	actions.add_child(_cancel_button)
	_advance_button = Button.new()
	_advance_button.text = "Avançar semana"
	_advance_button.custom_minimum_size.y = 32
	_advance_button.disabled = true
	_advance_button.pressed.connect(_on_advance_week_pressed)
	actions.add_child(_advance_button)
	return panel


func _build_narrative_overlay() -> void:
	_narrative_overlay = Control.new()
	_narrative_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_narrative_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_narrative_overlay.visible = false
	_narrative_overlay.z_index = 10
	add_child(_narrative_overlay)

	var shade := ColorRect.new()
	shade.color = Color(TrainingThemeScript.INK, 0.20)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narrative_overlay.add_child(shade)

	_narrative_panel = PanelContainer.new()
	_narrative_panel.anchor_left = 0.025
	_narrative_panel.anchor_top = 0.54
	_narrative_panel.anchor_right = 0.975
	_narrative_panel.anchor_bottom = 0.98
	_narrative_panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.96),
			TrainingThemeScript.GOLD,
			18,
			1
		)
	)
	_narrative_overlay.add_child(_narrative_panel)
	_narrative_overlay.resized.connect(_update_narrative_panel_layout)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	_narrative_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	_narrative_meta = _make_label("", 10)
	_narrative_meta.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	content.add_child(_narrative_meta)
	_narrative_title = _make_label("", 22)
	_narrative_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_narrative_title)
	_mission_steps = HBoxContainer.new()
	_mission_steps.add_theme_constant_override("separation", 5)
	_mission_steps.visible = false
	for step_number: int in range(1, 4):
		var step_card := PanelContainer.new()
		step_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step_card.add_theme_stylebox_override(
			"panel",
			TrainingThemeScript.make_panel_style(
				TrainingThemeScript.PANEL_MUTED,
				TrainingThemeScript.LINE,
				7,
				1
			)
		)
		var step_label := _make_label("ETAPA %d" % step_number, 9)
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_card.add_child(step_label)
		_mission_steps.add_child(step_card)
		_mission_step_labels.append(step_label)
	content.add_child(_mission_steps)
	_mission_requirement_note = _make_label("", 10)
	_mission_requirement_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_requirement_note.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	_mission_requirement_note.visible = false
	content.add_child(_mission_requirement_note)
	_narrative_speaker = _make_label("", 12)
	_narrative_speaker.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	content.add_child(_narrative_speaker)
	_narrative_body = _make_label("", 15)
	_narrative_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narrative_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_narrative_body.custom_minimum_size.y = 96
	content.add_child(_narrative_body)
	_dialogue_history_toggle = Button.new()
	_dialogue_history_toggle.custom_minimum_size.y = 30
	_dialogue_history_toggle.text = "Histórico da cena"
	_dialogue_history_toggle.visible = false
	_dialogue_history_toggle.pressed.connect(_on_dialogue_history_toggled)
	content.add_child(_dialogue_history_toggle)
	_dialogue_history_scroll = ScrollContainer.new()
	_dialogue_history_scroll.custom_minimum_size.y = 94
	_dialogue_history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_dialogue_history_scroll.visible = false
	content.add_child(_dialogue_history_scroll)
	_dialogue_history_content = VBoxContainer.new()
	_dialogue_history_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_history_content.add_theme_constant_override("separation", 4)
	_dialogue_history_scroll.add_child(_dialogue_history_content)
	_narrative_result = _make_label("", 11)
	_narrative_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narrative_result.add_theme_color_override("font_color", TrainingThemeScript.CORAL)
	content.add_child(_narrative_result)
	_narrative_choice_scroll = ScrollContainer.new()
	_narrative_choice_scroll.custom_minimum_size.y = 110
	_narrative_choice_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_narrative_choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_narrative_choice_scroll.follow_focus = true
	_narrative_choice_scroll.visible = false
	content.add_child(_narrative_choice_scroll)
	_narrative_choices = VBoxContainer.new()
	_narrative_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_narrative_choices.add_theme_constant_override("separation", 6)
	_narrative_choice_scroll.add_child(_narrative_choices)
	_narrative_continue = Button.new()
	_narrative_continue.text = "Continuar"
	_narrative_continue.custom_minimum_size.y = 38
	_narrative_continue.focus_mode = Control.FOCUS_ALL
	_narrative_continue.pressed.connect(_on_narrative_continue_pressed)
	content.add_child(_narrative_continue)


func _make_progress_bar(maximum: int, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(1, maximum)
	bar.show_percentage = false
	bar.add_theme_stylebox_override(
		"fill",
		TrainingThemeScript.make_panel_style(fill_color, fill_color, 5, 0)
	)
	return bar


func _make_section_title(text: String) -> Label:
	var label := _make_label(text, 11)
	label.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	return label


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _set_scene_context(scene_id: StringName) -> void:
	if _background == null:
		return
	var texture: Texture2D = _scene_textures.get(
		scene_id,
		_scene_textures.get(&"academy")
	)
	_background.texture = texture
	_background.visible = texture != null


func _set_hori_presentation(presentation: HoriPresentation) -> void:
	_hori_presentation = presentation
	_update_hori_presentation()


func _update_hori_presentation() -> void:
	if _portrait == null or _portrait.texture == null or _character_stage == null:
		return
	var source_size: Vector2i = _portrait.texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return
	var aspect_ratio: float = float(source_size.x) / float(source_size.y)
	var stage_size: Vector2 = _character_stage.size
	var max_height: float = stage_size.y * (
		0.96
		if _hori_presentation == HoriPresentation.CENTER_STAGE
		else 0.94
	)
	var max_width: float = stage_size.x * (
		0.58
		if _hori_presentation == HoriPresentation.CENTER_STAGE
		else 0.50
	)
	var portrait_width: float = minf(max_width, max_height * aspect_ratio)
	var portrait_height: float = portrait_width / aspect_ratio
	_portrait.size = Vector2(portrait_width, portrait_height)
	_portrait.position = Vector2(
		(stage_size.x - portrait_width) * 0.5
		if _hori_presentation == HoriPresentation.CENTER_STAGE
		else stage_size.x - portrait_width,
		stage_size.y - portrait_height
	)


func _show_narrative_overlay() -> void:
	_set_hori_presentation(HoriPresentation.CENTER_STAGE)
	_update_narrative_panel_layout()
	_management_ui.visible = false
	_narrative_overlay.visible = true


func _hide_narrative_overlay() -> void:
	_narrative_overlay.visible = false
	_management_ui.visible = true
	_set_hori_presentation(HoriPresentation.RIGHT_SIDE)


func _update_narrative_panel_layout() -> void:
	match _narrative_mode:
		&"event_choices", &"mission_choices", &"ending":
			_narrative_panel.anchor_top = (
				0.34
				if _narrative_overlay.size.y < 660.0
				else 0.39
			)
		&"event_result", &"mission_result":
			_narrative_panel.anchor_top = 0.48
		_:
			_narrative_panel.anchor_top = (
				0.46
				if _narrative_overlay.size.y < 660.0
				else 0.54
			)


func _set_scene_for_activity(activity_id: StringName) -> void:
	match activity_id:
		&"lab", &"control":
			_set_scene_context(&"laboratory")
		&"bond_ray", &"bond_luppi":
			_set_scene_context(&"observatory")
		_:
			_set_scene_context(&"academy")


func _set_scene_for_event(event_id: StringName) -> void:
	_set_scene_context(
		EVENT_SCENE_PRESENTATION.get(event_id, &"academy")
	)


func _set_dialogue_portrait(speaker_id: String, expression_id: StringName) -> void:
	if speaker_id != "hori":
		return
	var texture: Texture2D = _hori_expression_textures.get(expression_id)
	if texture == null:
		texture = _hori_expression_textures.get(&"neutral")
	_portrait.texture = texture
	_portrait_placeholder.visible = texture == null
	_portrait_placeholder_label.text = (
		"RETRATO DA HORI PENDENTE"
		if texture == null
		else ""
	)
	_update_hori_presentation()


func _hori_expression_for_line(event_id: StringName, line_index: int) -> StringName:
	match event_id:
		&"hori_face_clues_w02":
			return &"happy" if line_index == 0 else &"neutral"
		&"hori_core_protocol_w03":
			return &"worried"
		&"hori_echo_confrontation_w11":
			return &"worried" if line_index < 2 else &"determined"
		&"hori_rupture_investigation_w12":
			return &"determined"
		_:
			return &"neutral"


func _clear_dialogue_history() -> void:
	for child: Node in _dialogue_history_content.get_children():
		_dialogue_history_content.remove_child(child)
		child.queue_free()
	_dialogue_history_open = false
	_dialogue_history_scroll.visible = false
	_dialogue_history_toggle.text = "Ver histórico da cena (0 falas)"


func _append_dialogue_history(speaker_id: String, line_text: String) -> void:
	var entry := _make_label(
		"%s  ·  %s" % [_display_speaker(speaker_id), line_text],
		11
	)
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_history_content.add_child(entry)
	var count: int = _dialogue_history_content.get_child_count()
	_dialogue_history_toggle.text = (
		"Ocultar histórico (%d falas)"
		if _dialogue_history_open
		else "Ver histórico da cena (%d falas)"
	) % count
	_dialogue_history_scroll.visible = _dialogue_history_open
	if _dialogue_history_open:
		_dialogue_history_scroll.scroll_vertical = (
			int(_dialogue_history_scroll.get_v_scroll_bar().max_value)
		)


func _on_dialogue_history_toggled() -> void:
	_dialogue_history_open = not _dialogue_history_open
	var count: int = _dialogue_history_content.get_child_count()
	_dialogue_history_toggle.text = (
		"Ocultar histórico (%d falas)"
		if _dialogue_history_open
		else "Ver histórico da cena (%d falas)"
	) % count
	_dialogue_history_scroll.visible = _dialogue_history_open
	if _dialogue_history_open:
		_dialogue_history_scroll.scroll_vertical = (
			int(_dialogue_history_scroll.get_v_scroll_bar().max_value)
		)


func _update_mission_progress(completed_count: int) -> void:
	for index: int in range(_mission_step_labels.size()):
		var number: int = index + 1
		if index < completed_count:
			_mission_step_labels[index].text = "ETAPA %d  ·  CONCLUÍDA" % number
			_mission_step_labels[index].add_theme_color_override(
				"font_color",
				TrainingThemeScript.MINT
			)
		elif index == completed_count:
			_mission_step_labels[index].text = "ETAPA %d  ·  ATUAL" % number
			_mission_step_labels[index].add_theme_color_override(
				"font_color",
				TrainingThemeScript.GOLD
			)
		else:
			_mission_step_labels[index].text = "ETAPA %d" % number
			_mission_step_labels[index].add_theme_color_override(
				"font_color",
				TrainingThemeScript.CREAM
			)


func _process_narrative_flow() -> void:
	if _state == null or _narrative_overlay == null or _narrative_overlay.visible:
		return
	var next_event: Dictionary = _narrative_service.get_next_event(_state)
	if not next_event.is_empty():
		_open_narrative_event(next_event)
		return
	if _narrative_service.is_mission_due(_state):
		_open_mission_stage()
		return
	if (
		_state.week == _service.get_total_weeks()
		and _state.actions_remaining == 0
		and _state.ending_id == &""
	):
		_show_campaign_ending()


func _open_narrative_event(event: Dictionary) -> void:
	_active_event = event
	_active_event_id = StringName(event["id"])
	_active_dialogue = event["dialogue"]
	_dialogue_index = 0
	_narrative_body.custom_minimum_size.y = 64
	_narrative_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_mission_steps.visible = false
	_mission_requirement_note.visible = false
	_dialogue_history_toggle.visible = true
	_narrative_choice_scroll.visible = false
	_clear_dialogue_history()
	_set_scene_for_event(_active_event_id)
	_set_dialogue_portrait("hori", &"neutral")
	_narrative_mode = &"event_dialogue"
	_narrative_title.text = String(event["title"])
	_narrative_meta.text = (
		"CENA  ·  SEMANA %02d  ·  %s"
		% [
			_state.week,
			_category_label(String(event["category"])).to_upper(),
		]
	)
	_narrative_result.text = ""
	_show_narrative_overlay()
	_show_event_dialogue_line()


func _show_event_dialogue_line() -> void:
	if _dialogue_index < 0 or _dialogue_index >= _active_dialogue.size():
		return
	var line: Dictionary = _active_dialogue[_dialogue_index]
	var speaker_id: String = String(line["speaker"])
	var line_text: String = String(line["text"])
	_narrative_speaker.text = _display_speaker(speaker_id)
	_narrative_body.text = line_text
	var expression_id: StringName = _hori_expression_for_line(
		_active_event_id,
		_dialogue_index
	)
	_set_dialogue_portrait(speaker_id, expression_id)
	_append_dialogue_history(speaker_id, line_text)
	_narrative_continue.text = (
		"Continuar fala"
		if _dialogue_index < _active_dialogue.size() - 1
		else "Ver escolhas"
	)
	_narrative_continue.visible = true
	_clear_narrative_choices()


func _show_event_choices() -> void:
	_narrative_mode = &"event_choices"
	_narrative_speaker.text = ""
	_narrative_body.text = "Escolha como responder. A decisão não consome um bloco de treinamento."
	_narrative_body.custom_minimum_size.y = 48
	_narrative_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_narrative_result.text = ""
	_mission_steps.visible = false
	_mission_requirement_note.visible = false
	_dialogue_history_toggle.visible = true
	_narrative_choice_scroll.visible = true
	_set_dialogue_portrait("hori", &"happy")
	_narrative_continue.visible = false
	_clear_narrative_choices()
	for choice: Dictionary in _active_event["choices"]:
		_add_narrative_choice_button(
			String(choice["label"]),
			StringName(choice["id"])
		)
	_update_narrative_panel_layout()


func _open_mission_stage() -> void:
	_active_mission_stage = _narrative_service.get_current_mission_stage(_state)
	if _active_mission_stage.is_empty():
		return
	_narrative_mode = &"mission_choices"
	_narrative_body.custom_minimum_size.y = 0
	_narrative_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_set_scene_context(&"observatory")
	_set_dialogue_portrait("hori", &"determined")
	_narrative_speaker.text = "HORI"
	_mission_steps.visible = true
	_update_mission_progress(int(_active_mission_stage["stage"]) - 1)
	_mission_requirement_note.visible = int(_active_mission_stage["stage"]) == 2
	if _mission_requirement_note.visible:
		_mission_requirement_note.text = (
			"PULSO DE CONTENÇÃO  ·  sucesso se estabilidade ≥ %d e Técnica ≥ %d; "
			+ "caso contrário, falha recuperável."
		) % [
			NarrativeService.PULSE_MIN_CORE_STABILITY,
			NarrativeService.PULSE_MIN_TECHNIQUE,
		]
	_dialogue_history_toggle.visible = false
	_dialogue_history_scroll.visible = false
	_narrative_choice_scroll.visible = true
	_narrative_title.text = String(_narrative_service.get_mission_title())
	_narrative_meta.text = (
		"MISSÃO  ·  ETAPA %d DE 3  ·  SEMANA %02d"
		% [int(_active_mission_stage["stage"]), _state.week]
	)
	var context: String = ""
	if int(_active_mission_stage["stage"]) == 1:
		context = String(_narrative_service.get_mission_context()) + "\n\n"
	_narrative_speaker.text = ""
	_narrative_body.text = context + String(_active_mission_stage["objective"])
	_narrative_result.text = (
		"Os requisitos determinam resultados recuperáveis; nenhuma rolagem aleatória."
	)
	_narrative_continue.visible = false
	_clear_narrative_choices()
	for choice_id: StringName in _narrative_service.get_mission_choice_ids(_state):
		var choice: Dictionary = _narrative_service.get_mission_choice(
			_active_mission_stage,
			choice_id
		)
		var preview: NarrativeResult = _narrative_service.preview_mission_choice(
			_state,
			choice_id
		)
		var choice_text: String = String(choice["label"])
		choice_text += "\n" + preview.message
		_add_narrative_choice_button(choice_text, choice_id)
	_show_narrative_overlay()


func _show_campaign_ending() -> void:
	var ending: Dictionary = _narrative_service.resolve_ending(_state)
	if ending.is_empty():
		_feedback_label.text = "A campanha terminou, mas nenhum final elegível foi encontrado."
		return
	_state.ending_id = StringName(ending["id"])
	_set_scene_context(&"observatory")
	_set_dialogue_portrait("hori", &"neutral")
	_narrative_body.custom_minimum_size.y = 96
	_narrative_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_narrative_mode = &"ending"
	_mission_steps.visible = true
	_update_mission_progress(3)
	_mission_requirement_note.visible = false
	_dialogue_history_toggle.visible = false
	_dialogue_history_scroll.visible = false
	_narrative_choice_scroll.visible = false
	_narrative_title.text = String(ending["title"])
	_narrative_meta.text = "FIM DO SEMESTRE  ·  FINAL %s" % String(ending["tag"]).to_upper()
	_narrative_speaker.text = "EPÍLOGO"
	var ending_text := String(ending.get("epilogue_text", ""))
	var consequences: Dictionary = ending.get("consequences", {})
	for character_id: String in consequences:
		ending_text += "\n\n%s — %s" % [
			_display_speaker(character_id),
			String(consequences[character_id]),
		]
	_narrative_body.text = ending_text
	_narrative_result.text = String(ending.get("epilogue_note", ""))
	_narrative_continue.text = "Fechar final"
	_narrative_continue.visible = true
	_clear_narrative_choices()
	_show_narrative_overlay()


func _add_narrative_choice_button(label_text: String, choice_id: StringName) -> void:
	var button := Button.new()
	button.custom_minimum_size.y = 46
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	var inset := MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.add_theme_constant_override("margin_left", 8)
	inset.add_theme_constant_override("margin_top", 4)
	inset.add_theme_constant_override("margin_right", 8)
	inset.add_theme_constant_override("margin_bottom", 4)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inset)
	var label := _make_label(label_text, 11)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_child(label)
	button.pressed.connect(_on_narrative_choice_pressed.bind(choice_id))
	_narrative_choices.add_child(button)


func _clear_narrative_choices() -> void:
	for child: Node in _narrative_choices.get_children():
		_narrative_choices.remove_child(child)
		child.queue_free()


func _on_narrative_choice_pressed(choice_id: StringName) -> void:
	if _state == null:
		return
	var was_mission_choice: bool = _narrative_mode == &"mission_choices"
	var state_before: TrainingState = _state.duplicate_state()
	var result: NarrativeResult
	if _narrative_mode == &"event_choices":
		result = _narrative_service.apply_event_choice(
			_state,
			StringName(_active_event["id"]),
			choice_id
		)
	elif _narrative_mode == &"mission_choices":
		result = _narrative_service.apply_mission_choice(_state, choice_id)
	else:
		return
	if not result.is_valid:
		_narrative_result.text = result.message
		return
	_narrative_mode = (
		&"event_result"
		if _narrative_mode == &"event_choices"
		else &"mission_result"
	)
	_narrative_body.custom_minimum_size.y = 64
	_narrative_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_narrative_speaker.text = "RESULTADO"
	_narrative_body.text = result.message
	_narrative_choice_scroll.visible = false
	if was_mission_choice:
		_set_scene_context(&"observatory")
		_set_dialogue_portrait(
			"hori",
			&"worried"
			if result.outcome == &"failure_recoverable"
			else &"determined"
		)
		_update_mission_progress(result.stage_number)
		_mission_steps.visible = true
		_mission_requirement_note.visible = result.stage_number == 2
	else:
		_dialogue_history_toggle.visible = true
	var changes: PackedStringArray = _format_narrative_changes(state_before, _state)
	_narrative_result.text = (
		"\n".join(changes)
		if not changes.is_empty()
		else "Nenhum atributo ou recurso mudou."
	)
	_clear_narrative_choices()
	_narrative_continue.text = (
		"Continuar"
		if _narrative_mode == &"event_result"
		else "Próxima etapa"
	)
	_narrative_continue.visible = true
	_update_narrative_panel_layout()
	_refresh_state()


func _on_narrative_continue_pressed() -> void:
	match _narrative_mode:
		&"event_dialogue":
			if _dialogue_index < _active_dialogue.size() - 1:
				_dialogue_index += 1
				_show_event_dialogue_line()
			else:
				_show_event_choices()
		&"event_result":
			_hide_narrative_overlay()
			_narrative_mode = &""
			_active_event.clear()
			_active_event_id = &""
			_active_dialogue.clear()
			_set_scene_context(&"academy")
			_refresh_state()
			_process_narrative_flow()
		&"mission_result":
			if _narrative_service.is_mission_due(_state):
				_open_mission_stage()
			else:
				_hide_narrative_overlay()
				_narrative_mode = &""
				_active_mission_stage.clear()
				_set_scene_context(&"academy")
				_refresh_state()
				_process_narrative_flow()
		&"ending":
			_hide_narrative_overlay()
			_narrative_mode = &""
			_set_scene_context(&"academy")


func _format_narrative_changes(
	before: TrainingState,
	after: TrainingState
) -> PackedStringArray:
	var changes := PackedStringArray()
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		_append_change(
			changes,
			STAT_LABELS[stat_id],
			before.stats[stat_id],
			after.stats[stat_id]
		)
	for axis_id: StringName in TrainingState.AXIS_IDS:
		_append_change(
			changes,
			"[%s]" % String(axis_id),
			before.axes[axis_id],
			after.axes[axis_id]
		)
	_append_change(changes, "Energia", before.energy, after.energy)
	_append_change(changes, "Estresse", before.stress, after.stress)
	_append_change(changes, "Motivação", before.motivation, after.motivation)
	_append_change(changes, "Créditos", before.credits, after.credits)
	_append_change(changes, "Reputação", before.reputation, after.reputation)
	for bond_id: StringName in before.bonds:
		_append_change(
			changes,
			"Vínculo — %s" % _display_bond_name(bond_id),
			before.bonds[bond_id],
			after.bonds[bond_id]
		)
	for route_id: StringName in before.route_state:
		var old_value: Variant = before.route_state[route_id]
		var new_value: Variant = after.route_state[route_id]
		if old_value != new_value:
			changes.append("%s: %s → %s" % [
				_route_state_label(route_id),
				str(old_value),
				str(new_value),
			])
	return changes


func _route_state_label(route_id: StringName) -> String:
	match route_id:
		&"core_stability":
			return "Estabilidade do núcleo"
		&"echo_pressure":
			return "Pressão da voz"
		&"trusted_network":
			return "Rede de confiança"
		&"identification_aids":
			return "Sistema de reconhecimento"
		&"identification_aids_progress":
			return "Progresso de reconhecimento"
		&"honesty_to_friends":
			return "Honestidade com amigas"
		_:
			return String(route_id)


func _display_speaker(speaker_id: String) -> String:
	match speaker_id:
		"hori":
			return "HORI"
		"luppi":
			return "LUPPI"
		"ray":
			return "RAY"
		"instructor":
			return "INSTRUTOR"
		"echo":
			return "VOZ"
		"tama":
			return "TAMA"
		"friend2":
			return "AMIGA"
		"auditor":
			return "AVALIADOR"
		"researcher":
			return "PESQUISADORA"
		_:
			return speaker_id.to_upper()


func _on_activity_selected(activity_id: StringName) -> void:
	if _state == null or _state.actions_remaining <= 0:
		return
	_selected_activity = activity_id
	_set_scene_for_activity(activity_id)
	_update_activity_buttons()
	_cancel_button.disabled = false
	var preview: TrainingPreview = _service.preview_activity(_state, activity_id)
	_preview_title.text = _service.get_activity_label(activity_id)
	if not preview.is_valid:
		_preview_status.text = "INDISPONÍVEL"
		_preview_status.add_theme_color_override(
			"font_color",
			TrainingThemeScript.CORAL
		)
		_preview_body.text = (
			"Categoria: %s  ·  Energia necessária: %d\n%s"
			% [
				_category_label(_service.get_activity_category(activity_id)),
				_service.get_activity_energy_cost(activity_id),
				preview.message,
			]
		)
		_confirm_button.disabled = true
		_feedback_label.text = "Escolha outra atividade ou cancele a prévia."
		return

	if preview.can_fail:
		_preview_status.text = (
			"RISCO  ·  sucesso %d%%  ·  falha %d%%  ·  1 bloco ao confirmar"
			% [
				preview.success_chance_percent,
				preview.failure_chance_percent,
			]
		)
		_preview_status.add_theme_color_override(
			"font_color",
			TrainingThemeScript.GOLD
		)
	else:
		_preview_status.text = "DISPONÍVEL  ·  consome 1 bloco semanal ao confirmar"
		_preview_status.add_theme_color_override(
			"font_color",
			TrainingThemeScript.MINT
		)
	_preview_body.text = _format_preview(activity_id, preview)
	_confirm_button.disabled = false
	if preview.can_fail:
		_feedback_label.text = (
			"A prévia não sorteia nem consome ação. O resultado só será definido ao confirmar."
		)
	else:
		_feedback_label.text = "A prévia não consome ação."


func _on_confirm_pressed() -> void:
	if _state == null or _selected_activity == &"":
		return
	var activity_id: StringName = _selected_activity
	var state_before: TrainingState = _state.duplicate_state()
	var applied: TrainingPreview = _service.apply_activity(_state, activity_id)
	if not applied.is_valid:
		_preview_status.text = "INDISPONÍVEL"
		_preview_status.add_theme_color_override(
			"font_color",
			TrainingThemeScript.CORAL
		)
		_preview_body.text = applied.message
		_confirm_button.disabled = true
		_feedback_label.text = "Nenhum recurso ou bloco foi consumido."
		return

	_selected_activity = &""
	_refresh_state()
	if applied.can_fail:
		_preview_title.text = _service.get_activity_label(activity_id)
		if applied.outcome == TrainingPreview.OUTCOME_FAILURE:
			_preview_status.text = "FALHA  ·  custos aplicados  ·  1 bloco consumido"
			_preview_status.add_theme_color_override(
				"font_color",
				TrainingThemeScript.CORAL
			)
		else:
			_preview_status.text = "SUCESSO  ·  ganhos aplicados  ·  1 bloco consumido"
			_preview_status.add_theme_color_override(
				"font_color",
				TrainingThemeScript.MINT
			)
		_preview_body.text = _format_applied_result(state_before, applied)
	if _state.actions_remaining == 0:
		if _state.week < _service.get_total_weeks():
			week_completed.emit(_state.week)
			_feedback_label.text = "Semana concluída. Avance quando estiver pronto."
		else:
			_feedback_label.text = "Ciclo de %d semanas concluído." % _service.get_total_weeks()
	elif applied.can_fail:
		_feedback_label.text = applied.message
	else:
		_feedback_label.text = "Treinamento aplicado. Foi consumido 1 bloco."
	_process_narrative_flow()


func _on_cancel_pressed() -> void:
	_selected_activity = &""
	_set_scene_context(&"academy")
	_preview_title.text = "PRÉVIA DO PLANO"
	_preview_status.text = "Escolha uma atividade para ver seus efeitos."
	_preview_status.add_theme_color_override(
		"font_color",
		TrainingThemeScript.CREAM
	)
	_preview_body.text = (
		"A prévia foi cancelada; nenhum recurso ou bloco foi alterado."
	)
	_feedback_label.text = ""
	_confirm_button.disabled = true
	_cancel_button.disabled = true
	_update_activity_buttons()


func _on_advance_week_pressed() -> void:
	if _state == null or not _service.advance_week(_state):
		return
	_selected_activity = &""
	_set_scene_context(&"academy")
	_preview_title.text = "NOVA SEMANA"
	_preview_status.text = "Semana %d iniciada." % _state.week
	_preview_body.text = "Escolha uma atividade para planejar o próximo bloco."
	_feedback_label.text = ""
	_confirm_button.disabled = true
	_cancel_button.disabled = true
	_refresh_state()
	_process_narrative_flow()


func _refresh_state() -> void:
	if _state == null:
		return
	_week_label.text = "SEMANA %02d / %02d" % [
		_state.week,
		_service.get_total_weeks(),
	]
	_semester_progress.max_value = maxi(1, _service.get_total_weeks())
	_semester_progress.value = _state.week
	_actions_label.text = "BLOCOS  %d / %d" % [
		_state.actions_remaining,
		_service.get_actions_per_week(),
	]
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var stat_value: int = _state.stats[stat_id]
		_stat_labels[stat_id].text = str(stat_value)
		_stat_bars[stat_id].value = stat_value
	_set_resource_display(&"energy", _state.energy)
	_set_resource_display(&"stress", _state.stress)
	_set_resource_display(&"motivation", _state.motivation)
	_credits_value.text = str(_state.credits)
	_set_resource_display(&"reputation", _state.reputation)
	for bond_id: StringName in _state.bonds:
		if _bond_values.has(bond_id):
			_bond_values[bond_id].text = "%d / %d" % [
				_state.bonds[bond_id],
				_service.get_bond_cap(),
			]

	var week_finished: bool = _state.actions_remaining == 0
	_set_activity_buttons_enabled(not week_finished)
	_advance_button.disabled = (
		not week_finished
		or _state.week >= _service.get_total_weeks()
	)
	_confirm_button.disabled = true
	_cancel_button.disabled = _selected_activity == &""
	if _state.week >= _service.get_total_weeks() and week_finished:
		_advance_button.text = "Semestre encerrado"
	else:
		_advance_button.text = "Avançar semana"


func _set_resource_display(resource_id: StringName, value: int) -> void:
	if not _resource_bars.has(resource_id):
		return
	_resource_bars[resource_id].value = value
	_resource_values[resource_id].text = "%d / %d" % [
		value,
		int(_resource_bars[resource_id].max_value),
	]


func _set_activity_buttons_enabled(enabled: bool) -> void:
	for activity_id: StringName in _activity_buttons:
		_activity_buttons[activity_id].disabled = not enabled
	_update_activity_buttons()


func _update_activity_buttons() -> void:
	if _state == null:
		return
	for activity_id: StringName in _activity_buttons:
		var button: Button = _activity_buttons[activity_id]
		button.button_pressed = activity_id == _selected_activity
		var status: String
		var status_color: Color
		if _state.actions_remaining <= 0:
			status = "Semana concluída"
			status_color = TrainingThemeScript.CORAL
		else:
			var cost: int = _service.get_activity_energy_cost(activity_id)
			var missing: int = maxi(0, cost - _state.energy)
			if missing > 0:
				status = "Bloqueada · faltam %d EN" % missing
				status_color = TrainingThemeScript.CORAL
				button.tooltip_text = (
					"Requer %d de energia; faltam %d."
					% [cost, missing]
				)
			else:
				status = "Disponível"
				status_color = TrainingThemeScript.MINT
				button.tooltip_text = "Custo de energia: %d." % cost
		_activity_status_labels[activity_id].text = status
		_activity_status_labels[activity_id].add_theme_color_override(
			"font_color",
			status_color
		)


func _format_preview(activity_id: StringName, preview: TrainingPreview) -> String:
	var lines := PackedStringArray()
	lines.append(
		"Categoria: %s  ·  Energia necessária: %d"
		% [
			_category_label(_service.get_activity_category(activity_id)),
			_service.get_activity_energy_cost(activity_id),
		]
	)
	if preview.can_fail:
		var success_changes: PackedStringArray = _format_state_changes(
			_state,
			preview.success_result,
			true,
			false
		)
		var guaranteed_costs: PackedStringArray = _format_state_changes(
			_state,
			preview.failure_result,
			false,
			true
		)
		lines.append(
			"Sucesso (%d%%): %s"
			% [
				preview.success_chance_percent,
				", ".join(success_changes) if not success_changes.is_empty() else "sem ganhos",
			]
		)
		lines.append(
			"Falha (%d%%): ganhos de atributos não são aplicados."
			% preview.failure_chance_percent
		)
		lines.append(
			"Custos/efeitos garantidos: %s"
			% [
				", ".join(guaranteed_costs)
				if not guaranteed_costs.is_empty()
				else "nenhum recurso alterado"
			]
		)
		lines.append("Ações consumidas ao confirmar: 1.")
	else:
		var effect_changes: PackedStringArray = _format_state_changes(
			_state,
			preview.result,
			true,
			true
		)
		if effect_changes.is_empty():
			effect_changes.append("Sem alteração direta nos atributos ou recursos.")
		lines.append("  ·  ".join(effect_changes))
		lines.append(
			"Ações: %d → %d (1 bloco será consumido ao confirmar)."
			% [_state.actions_remaining, preview.result.actions_remaining]
		)
	return "\n".join(lines)


func _format_applied_result(
	state_before: TrainingState,
	applied: TrainingPreview
) -> String:
	var lines := PackedStringArray()
	lines.append(applied.message)
	var changes: PackedStringArray = _format_state_changes(
		state_before,
		applied.result,
		true,
		true
	)
	if changes.is_empty():
		lines.append("Nenhum atributo ou recurso mudou.")
	else:
		lines.append(", ".join(changes))
	lines.append("Ações restantes: %d." % applied.result.actions_remaining)
	return "\n".join(lines)


func _format_state_changes(
	before: TrainingState,
	after: TrainingState,
	include_stats: bool,
	include_resources: bool
) -> PackedStringArray:
	var changes := PackedStringArray()
	if include_stats:
		for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
			_append_change(
				changes,
				STAT_LABELS[stat_id],
				before.stats[stat_id],
				after.stats[stat_id]
			)
	if include_resources:
		_append_change(changes, "Energia", before.energy, after.energy)
		_append_change(changes, "Estresse", before.stress, after.stress)
		_append_change(changes, "Motivação", before.motivation, after.motivation)
		_append_change(changes, "Créditos", before.credits, after.credits)
		_append_change(changes, "Reputação", before.reputation, after.reputation)
		for bond_id: StringName in before.bonds:
			_append_change(
				changes,
				"Vínculo — %s" % _display_bond_name(bond_id),
				before.bonds[bond_id],
				after.bonds[bond_id]
			)
	return changes


func _append_change(
	lines: PackedStringArray,
	label: String,
	old_value: int,
	new_value: int
) -> void:
	if old_value != new_value:
		lines.append("%s: %d → %d" % [label, old_value, new_value])


func _category_label(category: String) -> String:
	match category:
		"training":
			return "Treino"
		"recovery":
			return "Recuperação"
		"work":
			return "Trabalho"
		"relationship":
			return "Relacionamento"
		_:
			return category


func _display_bond_name(bond_id: StringName) -> String:
	match bond_id:
		&"ray":
			return "Ray"
		&"luppi":
			return "Luppi"
		&"instructor":
			return "Instrutor"
		_:
			return String(bond_id)

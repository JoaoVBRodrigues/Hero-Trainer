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
const STAT_SHORT_LABELS: Dictionary[StringName, String] = {
	&"pot": "POT",
	&"res": "RES",
	&"tec": "TEC",
	&"teo": "TEO",
	&"sin": "SIN",
}

enum HoriPresentation { RIGHT_SIDE, CENTER_STAGE, STATUS_SIDE }

var _service: TrainingService
var _narrative_service: NarrativeService
var _state: TrainingState
var _selected_activity: StringName = &""
var _hori_presentation: HoriPresentation = HoriPresentation.RIGHT_SIDE
var _current_area: StringName = &"hub"
var _scene_textures: Dictionary[StringName, Texture2D] = {}
var _hori_expression_textures: Dictionary[StringName, Texture2D] = {}
var _background: TextureRect
var _character_stage: Control
var _management_ui: Control
var _hub_ui: Control
var _training_ui: Control
var _status_ui: Control
var _hub_profile_panel: PanelContainer
var _status_profile_label: Label
var _status_name_label: Label
var _status_week_label: Label
var _status_actions_label: Label
var _status_semester_progress: ProgressBar
var _status_scroll: ScrollContainer
var _status_attribute_grid: GridContainer
var _status_stat_values: Dictionary[StringName, Label] = {}
var _status_stat_bars: Dictionary[StringName, ProgressBar] = {}
var _status_resource_values: Dictionary[StringName, Label] = {}
var _status_resource_bars: Dictionary[StringName, ProgressBar] = {}
var _status_credits_value: Label
var _status_reputation_value: Label
var _status_nav_buttons: Dictionary[StringName, Button] = {}
var _status_back_button: Button
var _character_panel_scroll: ScrollContainer
var _activity_scroll: ScrollContainer
var _status_section: Control
var _bonds_section: Control
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
var _hub_back_button: Button
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
var _hub_name_label: Label
var _hub_week_label: Label
var _hub_actions_label: Label
var _hub_credits_label: Label
var _hub_objective_label: Label
var _hub_semester_progress: ProgressBar
var _hub_action_slots: Array[PanelContainer] = []
var _hub_stat_values: Dictionary[StringName, Label] = {}
var _hub_resource_bars: Dictionary[StringName, ProgressBar] = {}
var _hub_resource_values: Dictionary[StringName, Label] = {}
var _hub_bond_values: Dictionary[StringName, Label] = {}
var _hub_nav_buttons: Dictionary[StringName, Button] = {}
var _training_week_label: Label
var _training_actions_label: Label
var _training_credits_label: Label
var _training_progress: ProgressBar
var _training_resource_bars: Dictionary[StringName, ProgressBar] = {}
var _training_resource_values: Dictionary[StringName, Label] = {}
var _training_cards: Dictionary[StringName, Button] = {}
var _training_card_effects: Dictionary[StringName, Label] = {}
var _training_card_status: Dictionary[StringName, Label] = {}
var _training_preview_title: Label
var _training_preview_status: Label
var _training_preview_detail: Label
var _training_planning_panel: PanelContainer
var _training_success_panel: PanelContainer
var _training_success_title: Label
var _training_success_body: Label
var _training_failure_panel: PanelContainer
var _training_failure_title: Label
var _training_failure_body: Label
var _training_result_label: Label
var _training_hint_label: Label
var _training_confirm_button: Button
var _training_cancel_button: Button
var _training_advance_button: Button
var _training_nav_buttons: Dictionary[StringName, Button] = {}


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


func set_character_presentation(
	display_name: String,
	portrait_texture: Texture2D = null
) -> void:
	if _character_name_label != null:
		_character_name_label.text = display_name
	if _profile_name_label != null:
		_profile_name_label.text = display_name
	if _hub_name_label != null:
		_hub_name_label.text = display_name
	if _status_name_label != null:
		_status_name_label.text = display_name
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
	_build_hub_screen()
	_build_training_screen()
	_build_status_screen()
	_build_narrative_overlay()
	_management_ui.visible = false


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

	_hub_back_button = Button.new()
	_hub_back_button.text = "← HUB"
	_hub_back_button.custom_minimum_size = Vector2(76, 38)
	_hub_back_button.pressed.connect(_show_hub)
	row.add_child(_hub_back_button)

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
	_character_panel_scroll = scroll
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
	_status_section = content.get_child(content.get_child_count() - 1)
	content.add_child(_build_stat_grid())
	content.add_child(_make_section_title("CONDIÇÃO"))
	_add_resource_row(content, &"energy", "Energia", TrainingThemeScript.MINT)
	_add_resource_row(content, &"stress", "Estresse", TrainingThemeScript.CORAL)
	_add_resource_row(content, &"motivation", "Motivação", TrainingThemeScript.GOLD)
	content.add_child(_build_economy_row())
	_bonds_section = _make_section_title("VÍNCULOS")
	content.add_child(_bonds_section)
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
	_activity_scroll = scroll
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


func _build_training_screen() -> void:
	_training_ui = Control.new()
	_training_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_training_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	_training_ui.visible = false
	_training_ui.resized.connect(_update_training_layout)
	add_child(_training_ui)
	_training_ui.add_child(_build_training_header())
	_training_ui.add_child(_build_training_activity_panel())
	_training_planning_panel = _build_training_planning_panel()
	_training_ui.add_child(_training_planning_panel)
	_training_ui.add_child(_build_training_navigation())
	_update_training_layout()


func _build_training_header() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.02
	panel.anchor_top = 0.02
	panel.anchor_right = 0.98
	panel.anchor_bottom = 0.17
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.94),
			Color(TrainingThemeScript.GOLD, 0.72),
			12,
			1
		)
	)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	panel.add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	content.add_child(heading)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	heading.add_child(identity)
	var eyebrow := _make_label("HERO TRAINER  /  ACADEMIA NEXO", 9)
	eyebrow.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	identity.add_child(eyebrow)
	var title := _make_label("TREINAMENTO", 16)
	title.add_theme_color_override("font_color", TrainingThemeScript.CREAM)
	identity.add_child(title)
	_training_week_label = _make_label("", 10)
	_training_week_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.add_child(_training_week_label)
	_training_actions_label = _make_label("", 10)
	_training_actions_label.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	heading.add_child(_training_actions_label)
	_training_credits_label = _make_label("", 10)
	_training_credits_label.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	heading.add_child(_training_credits_label)
	_training_progress = ProgressBar.new()
	_training_progress.min_value = 0
	_training_progress.max_value = maxi(1, _service.get_total_weeks())
	_training_progress.show_percentage = false
	_training_progress.custom_minimum_size.y = 5
	_training_progress.add_theme_stylebox_override(
		"fill",
		TrainingThemeScript.make_panel_style(
			TrainingThemeScript.MINT,
			TrainingThemeScript.MINT,
			4,
			0
		)
	)
	content.add_child(_training_progress)
	var condition_row := HBoxContainer.new()
	condition_row.add_theme_constant_override("separation", 10)
	content.add_child(condition_row)
	condition_row.add_child(
		_make_training_resource_meter(
			&"energy",
			"ENERGIA",
			TrainingThemeScript.MINT
		)
	)
	condition_row.add_child(
		_make_training_resource_meter(
			&"stress",
			"ESTRESSE",
			TrainingThemeScript.CORAL
		)
	)
	condition_row.add_child(
		_make_training_resource_meter(
			&"motivation",
			"MOTIVAÇÃO",
			TrainingThemeScript.GOLD
		)
	)
	return panel


func _make_training_resource_meter(
	resource_id: StringName,
	title: String,
	bar_color: Color
) -> Control:
	var meter := HBoxContainer.new()
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.add_theme_constant_override("separation", 5)
	var name_label := _make_label(title, 8)
	name_label.custom_minimum_size.x = 53
	name_label.add_theme_color_override("font_color", bar_color)
	meter.add_child(name_label)
	var bar := _make_progress_bar(_service.get_resource_cap(), bar_color)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 8
	meter.add_child(bar)
	var value_label := _make_label("", 8)
	value_label.custom_minimum_size.x = 42
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meter.add_child(value_label)
	_training_resource_bars[resource_id] = bar
	_training_resource_values[resource_id] = value_label
	return meter


func _build_training_activity_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.02
	panel.anchor_top = 0.18
	panel.anchor_right = 0.72
	panel.anchor_bottom = 0.61
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.91),
			Color(TrainingThemeScript.MINT, 0.5),
			12,
			1
		)
	)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title := _make_section_title("ESCOLHA SEU PLANO")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var block_hint := _make_label("1 atividade = 1 bloco", 8)
	block_hint.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	heading.add_child(block_hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	for activity_id: StringName in _service.get_activity_ids():
		grid.add_child(_make_training_activity_card(activity_id))
	return panel


func _make_training_activity_card(activity_id: StringName) -> Button:
	var category: String = _service.get_activity_category(activity_id)
	var category_color: Color = _training_category_color(category)
	var button := Button.new()
	button.set_meta("activity_id", activity_id)
	button.set_meta("category", category)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 56)
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	button.tooltip_text = (
		"%s · %s · custo %d de energia"
		% [
			_service.get_activity_label(activity_id),
			_category_label(category),
			_service.get_activity_energy_cost(activity_id),
		]
	)
	button.add_theme_stylebox_override(
		"normal",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.97),
			Color(category_color, 0.72),
			9,
			2
		)
	)
	button.add_theme_stylebox_override(
		"hover",
		TrainingThemeScript.make_panel_style(
			Color(category_color, 0.42),
			category_color,
			9,
			2
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		TrainingThemeScript.make_panel_style(
			Color(category_color, 0.7),
			TrainingThemeScript.CREAM,
			9,
			2
		)
	)
	button.add_theme_stylebox_override(
		"hover_pressed",
		TrainingThemeScript.make_panel_style(
			Color(category_color, 0.82),
			TrainingThemeScript.CREAM,
			9,
			2
		)
	)
	button.add_theme_stylebox_override(
		"disabled",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL_MUTED, 0.9),
			Color(category_color, 0.42),
			9,
			1
		)
	)
	var inset := MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.add_theme_constant_override("margin_left", 5)
	inset.add_theme_constant_override("margin_top", 3)
	inset.add_theme_constant_override("margin_right", 5)
	inset.add_theme_constant_override("margin_bottom", 3)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inset)
	var labels := VBoxContainer.new()
	labels.add_theme_constant_override("separation", 0)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_child(labels)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 4)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(title_row)
	var name_label := _make_label(_service.get_activity_label(activity_id), 11)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(name_label)
	var category_label := _make_label(_category_label(category).to_upper(), 8)
	category_label.add_theme_color_override("font_color", category_color)
	category_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(category_label)
	var effects_label := _make_label("", 9)
	effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effects_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(effects_label)
	var status_label := _make_label("", 8)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(status_label)
	button.pressed.connect(_on_activity_selected.bind(activity_id))
	_training_cards[activity_id] = button
	_training_card_effects[activity_id] = effects_label
	_training_card_status[activity_id] = status_label
	return button


func _training_category_color(category: String) -> Color:
	match category:
		"training":
			return TrainingThemeScript.PETROL
		"recovery":
			return TrainingThemeScript.MINT
		"work":
			return TrainingThemeScript.GOLD
		"relationship":
			return TrainingThemeScript.CORAL
		_:
			return TrainingThemeScript.CREAM


func _build_training_planning_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.02
	panel.anchor_top = 0.63
	panel.anchor_right = 0.98
	panel.anchor_bottom = 0.90
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.95),
			Color(TrainingThemeScript.GOLD, 0.64),
			12,
			1
		)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 2)
	row.add_child(details)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	details.add_child(heading)
	_training_preview_title = _make_label("PLANEJAMENTO", 11)
	_training_preview_title.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	_training_preview_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(_training_preview_title)
	_training_preview_status = _make_label("Selecione uma atividade.", 9)
	_training_preview_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.add_child(_training_preview_status)
	_training_preview_detail = _make_label(
		"A prévia usa apenas os dados atuais de treinamento.",
		8
	)
	_training_preview_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_training_preview_detail)
	var scenarios := HBoxContainer.new()
	scenarios.add_theme_constant_override("separation", 6)
	details.add_child(scenarios)
	_training_success_panel = _build_training_scenario_panel(
		"SUCESSO",
		TrainingThemeScript.MINT
	)
	scenarios.add_child(_training_success_panel)
	_training_failure_panel = _build_training_scenario_panel(
		"FALHA",
		TrainingThemeScript.CORAL
	)
	scenarios.add_child(_training_failure_panel)
	_training_result_label = _make_label("", 9)
	_training_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_training_result_label.add_theme_color_override("font_color", TrainingThemeScript.CREAM)
	_training_result_label.visible = false
	details.add_child(_training_result_label)
	_training_hint_label = _make_label(
		"A prévia não consome bloco nem realiza sorteio.",
		8
	)
	_training_hint_label.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	details.add_child(_training_hint_label)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 126
	actions.add_theme_constant_override("separation", 3)
	row.add_child(actions)
	_training_confirm_button = Button.new()
	_training_confirm_button.text = "Confirmar"
	_training_confirm_button.custom_minimum_size.y = 30
	_training_confirm_button.disabled = true
	_training_confirm_button.pressed.connect(_on_confirm_pressed)
	actions.add_child(_training_confirm_button)
	_training_cancel_button = Button.new()
	_training_cancel_button.text = "Cancelar"
	_training_cancel_button.custom_minimum_size.y = 27
	_training_cancel_button.disabled = true
	_training_cancel_button.pressed.connect(_on_cancel_pressed)
	actions.add_child(_training_cancel_button)
	_training_advance_button = Button.new()
	_training_advance_button.text = "Avançar semana"
	_training_advance_button.custom_minimum_size.y = 27
	_training_advance_button.visible = false
	_training_advance_button.disabled = true
	_training_advance_button.pressed.connect(_on_advance_week_pressed)
	actions.add_child(_training_advance_button)
	return panel


func _build_training_scenario_panel(
	title_text: String,
	accent: Color
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 58
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL_MUTED, 0.94),
			Color(accent, 0.64),
			8,
			1
		)
	)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 1)
	panel.add_child(content)
	var title_label := _make_label(title_text, 9)
	title_label.add_theme_color_override("font_color", accent)
	content.add_child(title_label)
	var body_label := _make_label("Os efeitos aparecerão ao selecionar.", 9)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body_label)
	if title_text == "SUCESSO":
		_training_success_title = title_label
		_training_success_body = body_label
	else:
		_training_failure_title = title_label
		_training_failure_body = body_label
	return panel


func _build_training_navigation() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.02
	panel.anchor_top = 0.92
	panel.anchor_right = 0.98
	panel.anchor_bottom = 0.985
	var style := TrainingThemeScript.make_panel_style(
		Color(TrainingThemeScript.INK, 0.97),
		Color(TrainingThemeScript.GOLD, 0.72),
		12,
		1
	)
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.content_margin_left = 6
	style.content_margin_right = 6
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	panel.add_child(row)
	for area: StringName in [&"hub", &"training", &"status", &"relationships"]:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.text = _hub_area_label(area)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_on_hub_navigation_pressed.bind(area))
		row.add_child(button)
		_training_nav_buttons[area] = button
	_update_training_navigation()
	return panel


func _update_training_layout() -> void:
	if _training_ui == null:
		return
	var short_viewport: bool = _training_ui.size.y <= 640.0
	var activity_bottom: float = 0.61 if short_viewport else 0.62
	var preview_top: float = 0.63 if short_viewport else 0.64
	var has_preview: bool = (
		_selected_activity != &""
		or (_training_result_label != null and _training_result_label.visible)
	)
	var preview_bottom: float
	if short_viewport:
		preview_bottom = 0.85 if has_preview else 0.82
	else:
		preview_bottom = 0.84 if has_preview else 0.81
	for activity_id: StringName in _training_cards:
		_training_cards[activity_id].custom_minimum_size.y = (
			50.0 if short_viewport else 56.0
		)
	for child: Node in _training_ui.get_children():
		if child is PanelContainer:
			var panel := child as PanelContainer
			if panel == _training_ui.get_child(1):
				panel.anchor_bottom = activity_bottom
			elif panel == _training_planning_panel:
				panel.anchor_top = preview_top
				panel.anchor_bottom = preview_bottom


func _build_status_screen() -> void:
	_status_ui = Control.new()
	_status_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	_status_ui.resized.connect(_update_status_layout)
	add_child(_status_ui)

	var header := PanelContainer.new()
	header.anchor_left = 0.315
	header.anchor_top = 0.018
	header.anchor_right = 0.982
	header.anchor_bottom = 0.145
	header.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.93),
			Color(TrainingThemeScript.GOLD, 0.62),
			14,
			1
		)
	)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header.add_child(header_row)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	header_row.add_child(identity)
	var eyebrow := _make_label("HERO TRAINER  /  STATUS DA PERSONAGEM", 9)
	eyebrow.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	identity.add_child(eyebrow)
	_status_name_label = _make_label("Hori", 21)
	identity.add_child(_status_name_label)

	var progress_column := VBoxContainer.new()
	progress_column.custom_minimum_size.x = 150
	progress_column.add_theme_constant_override("separation", 2)
	header_row.add_child(progress_column)
	var progress_labels := HBoxContainer.new()
	progress_labels.add_theme_constant_override("separation", 5)
	progress_column.add_child(progress_labels)
	_status_week_label = _make_label("", 10)
	_status_week_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_labels.add_child(_status_week_label)
	_status_actions_label = _make_label("", 9)
	_status_actions_label.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	progress_labels.add_child(_status_actions_label)
	_status_semester_progress = _make_progress_bar(
		_service.get_total_weeks(),
		TrainingThemeScript.MINT
	)
	_status_semester_progress.custom_minimum_size.y = 8
	progress_column.add_child(_status_semester_progress)

	_status_back_button = Button.new()
	_status_back_button.text = "← HUB"
	_status_back_button.custom_minimum_size = Vector2(70, 36)
	_status_back_button.pressed.connect(_show_hub)
	header_row.add_child(_status_back_button)
	_status_ui.add_child(header)

	var profile_panel := PanelContainer.new()
	profile_panel.anchor_left = 0.315
	profile_panel.anchor_top = 0.16
	profile_panel.anchor_right = 0.982
	profile_panel.anchor_bottom = 0.265
	profile_panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.INK, 0.88),
			Color(TrainingThemeScript.MINT, 0.44),
			12,
			1
		)
	)
	var profile_content := VBoxContainer.new()
	profile_content.add_theme_constant_override("separation", 2)
	profile_panel.add_child(profile_content)
	var profile_title := _make_label("PERFIL  /  PERSONALIDADE CANÔNICA", 8)
	profile_title.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	profile_content.add_child(profile_title)
	_status_profile_label = _make_label(_load_hori_canonical_summary(), 10)
	_status_profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_content.add_child(_status_profile_label)
	_status_ui.add_child(profile_panel)

	var scroll := ScrollContainer.new()
	_status_scroll = scroll
	scroll.anchor_left = 0.315
	scroll.anchor_top = 0.285
	scroll.anchor_right = 0.982
	scroll.anchor_bottom = 0.885
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_status_ui.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	content.add_child(_make_section_title("ATRIBUTOS  /  VALOR ATUAL E LIMITE"))
	_status_attribute_grid = GridContainer.new()
	_status_attribute_grid.add_theme_constant_override("h_separation", 7)
	_status_attribute_grid.add_theme_constant_override("v_separation", 6)
	content.add_child(_status_attribute_grid)
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(120, 66)
		card.add_theme_stylebox_override(
			"panel",
			TrainingThemeScript.make_panel_style(
				Color(TrainingThemeScript.PANEL, 0.94),
				Color(TrainingThemeScript.MINT, 0.26),
				10,
				1
			)
		)
		var card_content := VBoxContainer.new()
		card_content.add_theme_constant_override("separation", 2)
		card.add_child(card_content)
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation", 5)
		card_content.add_child(heading)
		var name_label := _make_label(STAT_LABELS[stat_id], 9)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(name_label)
		var value_label := _make_label("", 12)
		value_label.add_theme_color_override("font_color", TrainingThemeScript.CREAM)
		heading.add_child(value_label)
		var bar := _make_progress_bar(
			_service.get_attribute_cap(),
			TrainingThemeScript.MINT
		)
		bar.custom_minimum_size.y = 7
		card_content.add_child(bar)
		_status_attribute_grid.add_child(card)
		_status_stat_values[stat_id] = value_label
		_status_stat_bars[stat_id] = bar

	content.add_child(_make_section_title("CONDIÇÃO ATUAL"))
	var resource_grid := GridContainer.new()
	resource_grid.columns = 3
	resource_grid.add_theme_constant_override("h_separation", 7)
	resource_grid.add_theme_constant_override("v_separation", 6)
	content.add_child(resource_grid)
	_add_status_resource_card(
		resource_grid,
		&"energy",
		"ENERGIA",
		TrainingThemeScript.MINT
	)
	_add_status_resource_card(
		resource_grid,
		&"stress",
		"ESTRESSE",
		TrainingThemeScript.CORAL
	)
	_add_status_resource_card(
		resource_grid,
		&"motivation",
		"MOTIVAÇÃO",
		TrainingThemeScript.GOLD
	)

	content.add_child(_make_section_title("ECONOMIA E PRESTÍGIO"))
	var economy_row := HBoxContainer.new()
	economy_row.add_theme_constant_override("separation", 7)
	content.add_child(economy_row)
	_status_credits_value = _add_status_economy_card(
		economy_row,
		"CRÉDITOS",
		TrainingThemeScript.GOLD
	)
	_status_reputation_value = _add_status_economy_card(
		economy_row,
		"REPUTAÇÃO",
		TrainingThemeScript.MINT
	)
	_status_ui.add_child(_build_status_navigation())
	_status_ui.visible = false
	_update_status_layout()
	_update_status_state()


func _load_hori_canonical_summary() -> String:
	const CHARACTER_DATA_PATH: String = (
		"res://Hero_Trainer_Kit_v02/data/characters.json"
	)
	var file := FileAccess.open(CHARACTER_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error(
			"Não foi possível abrir os dados de personagem: %s."
			% CHARACTER_DATA_PATH
		)
		return ""
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error(
			"Falha ao interpretar %s: %s."
			% [CHARACTER_DATA_PATH, parser.get_error_message()]
		)
		return ""
	var root: Variant = parser.data
	if not root is Dictionary:
		push_error("A raiz de characters.json precisa ser um objeto.")
		return ""
	var characters: Variant = root.get("characters", [])
	if not characters is Array:
		push_error("characters.json precisa conter a lista 'characters'.")
		return ""
	for character: Variant in characters:
		if not character is Dictionary or character.get("id", "") != "hori":
			continue
		var canon: Variant = character.get("canon", {})
		if not canon is Dictionary:
			push_error("A entrada canônica da Hori precisa ser um objeto.")
			return ""
		var personality: Variant = canon.get("personality", [])
		if not personality is Array:
			push_error("A personalidade canônica da Hori precisa ser uma lista.")
			return ""
		var facts := PackedStringArray()
		for fact: Variant in personality:
			if fact is String and not String(fact).is_empty():
				facts.append(String(fact))
		if facts.is_empty():
			push_error("Não há informações canônicas de personalidade da Hori.")
			return ""
		var summary: String = "  ·  ".join(facts)
		return summary.left(1).to_upper() + summary.substr(1)
	push_error("Hori não foi encontrada em characters.json.")
	return ""


func _add_status_resource_card(
	parent: GridContainer,
	resource_id: StringName,
	title: String,
	accent: Color
) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 54)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.92),
			Color(accent, 0.32),
			9,
			1
		)
	)
	var card_content := VBoxContainer.new()
	card_content.add_theme_constant_override("separation", 2)
	card.add_child(card_content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	card_content.add_child(heading)
	var name_label := _make_label(title, 8)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", accent)
	heading.add_child(name_label)
	var value_label := _make_label("", 10)
	heading.add_child(value_label)
	var bar := _make_progress_bar(_service.get_resource_cap(), accent)
	bar.custom_minimum_size.y = 6
	card_content.add_child(bar)
	parent.add_child(card)
	_status_resource_values[resource_id] = value_label
	_status_resource_bars[resource_id] = bar


func _add_status_economy_card(
	parent: HBoxContainer,
	title: String,
	accent: Color
) -> Label:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 42
	card.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.92),
			Color(accent, 0.34),
			9,
			1
		)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var title_label := _make_label(title, 9)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", accent)
	row.add_child(title_label)
	var value_label := _make_label("", 13)
	row.add_child(value_label)
	parent.add_child(card)
	return value_label


func _build_status_navigation() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.315
	panel.anchor_top = 0.91
	panel.anchor_right = 0.982
	panel.anchor_bottom = 0.985
	var style := TrainingThemeScript.make_panel_style(
		Color(TrainingThemeScript.INK, 0.97),
		Color(TrainingThemeScript.GOLD, 0.72),
		12,
		1
	)
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.content_margin_left = 6
	style.content_margin_right = 6
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	panel.add_child(row)
	for area: StringName in [&"hub", &"training", &"status", &"relationships"]:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.text = _hub_area_label(area)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_on_hub_navigation_pressed.bind(area))
		row.add_child(button)
		_status_nav_buttons[area] = button
	_update_status_navigation()
	return panel


func _update_status_layout() -> void:
	if _status_ui == null or _status_attribute_grid == null:
		return
	_status_attribute_grid.columns = 2 if _status_ui.size.x < 1000.0 else 3


func _update_status_navigation() -> void:
	for area: StringName in _status_nav_buttons:
		var active: bool = area == _current_area
		var button: Button = _status_nav_buttons[area]
		button.add_theme_stylebox_override(
			"normal",
			TrainingThemeScript.make_panel_style(
				Color(TrainingThemeScript.PETROL, 0.88)
				if active
				else Color(TrainingThemeScript.PANEL, 0.52),
				TrainingThemeScript.GOLD
				if active
				else Color(TrainingThemeScript.MINT, 0.38),
				9,
				1
			)
		)
		button.add_theme_stylebox_override(
			"hover",
			TrainingThemeScript.make_panel_style(
				Color(TrainingThemeScript.PETROL, 0.95),
				TrainingThemeScript.MINT,
				9,
				1
			)
		)


func _update_status_state() -> void:
	if _state == null or _status_ui == null:
		return
	_status_week_label.text = "SEMANA %02d / %02d" % [
		_state.week,
		_service.get_total_weeks(),
	]
	_status_actions_label.text = "%d / %d AÇÕES" % [
		_state.actions_remaining,
		_service.get_actions_per_week(),
	]
	_status_semester_progress.max_value = maxi(1, _service.get_total_weeks())
	_status_semester_progress.value = _state.week
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var value: int = int(_state.stats[stat_id])
		_status_stat_values[stat_id].text = "%d / %d" % [
			value,
			_service.get_attribute_cap(),
		]
		_status_stat_bars[stat_id].value = value
	for resource_id: StringName in _status_resource_bars:
		var value: int = _training_resource_value(_state, resource_id)
		_status_resource_values[resource_id].text = "%d / %d" % [
			value,
			_service.get_resource_cap(),
		]
		_status_resource_bars[resource_id].value = value
	_status_credits_value.text = str(_state.credits)
	_status_reputation_value.text = "%d / %d" % [
		_state.reputation,
		_service.get_reputation_cap(),
	]
	_update_status_navigation()


func _update_training_navigation() -> void:
	for area: StringName in _training_nav_buttons:
		var active: bool = area == _current_area
		var button: Button = _training_nav_buttons[area]
		button.add_theme_stylebox_override(
			"normal",
			TrainingThemeScript.make_panel_style(
				Color(TrainingThemeScript.PETROL, 0.88)
				if active
				else Color(TrainingThemeScript.PANEL, 0.52),
				TrainingThemeScript.GOLD
				if active
				else Color(TrainingThemeScript.MINT, 0.38),
				9,
				1
			)
		)
		button.add_theme_stylebox_override(
			"hover",
			TrainingThemeScript.make_panel_style(
				Color(TrainingThemeScript.PETROL, 0.95),
				TrainingThemeScript.MINT,
				9,
				1
			)
		)


func _update_training_state() -> void:
	if _state == null or _training_ui == null:
		return
	_training_week_label.text = "SEMANA %02d / %02d" % [
		_state.week,
		_service.get_total_weeks(),
	]
	_training_actions_label.text = "BLOCOS %d / %d" % [
		_state.actions_remaining,
		_service.get_actions_per_week(),
	]
	_training_credits_label.text = "CR  %d" % _state.credits
	_training_progress.max_value = maxi(1, _service.get_total_weeks())
	_training_progress.value = _state.week
	for resource_id: StringName in _training_resource_bars:
		var value: int = _training_resource_value(_state, resource_id)
		_training_resource_bars[resource_id].value = value
		_training_resource_values[resource_id].text = "%d / %d" % [
			value,
			_service.get_resource_cap(),
		]
	_training_confirm_button.disabled = (
		_selected_activity == &"" or _state.actions_remaining <= 0
	)
	_training_confirm_button.visible = _selected_activity != &""
	_training_cancel_button.disabled = _selected_activity == &""
	_training_cancel_button.visible = _selected_activity != &""
	_training_advance_button.visible = _state.actions_remaining <= 0
	_training_advance_button.disabled = (
		_state.actions_remaining > 0
		or _state.week >= _service.get_total_weeks()
	)
	if _state.week >= _service.get_total_weeks() and _state.actions_remaining == 0:
		_training_advance_button.text = "Semestre encerrado"
	else:
		_training_advance_button.text = "Avançar semana"
	_update_training_cards()
	_update_training_navigation()


func _update_training_cards() -> void:
	if _state == null or _service == null:
		return
	for activity_id: StringName in _training_cards:
		var button: Button = _training_cards[activity_id]
		var category: String = _service.get_activity_category(activity_id)
		var category_color: Color = _training_category_color(category)
		var cost: int = _service.get_activity_energy_cost(activity_id)
		var cost_label: String = "CUSTO %d EN" % cost
		var preview_state: TrainingState = _state
		var preview: TrainingPreview = _service.preview_activity(preview_state, activity_id)
		var is_hypothetical: bool = false
		if (
			not preview.is_valid
			and _state.actions_remaining > 0
			and cost > _state.energy
		):
			preview_state = _state.duplicate_state()
			preview_state.energy = cost
			preview = _service.preview_activity(preview_state, activity_id)
			is_hypothetical = preview.is_valid
		var effects_label: Label = _training_card_effects[activity_id]
		var status_label: Label = _training_card_status[activity_id]
		button.button_pressed = activity_id == _selected_activity
		button.disabled = _state.actions_remaining <= 0
		if not preview.is_valid:
			effects_label.text = "Efeitos indisponíveis nesta condição."
		else:
			var after: TrainingState = (
				preview.success_result
				if preview.can_fail
				else preview.result
			)
			var changes: PackedStringArray = _format_compact_state_changes(
				preview_state,
				after,
				true,
				true
			)
			var effect_summary: String = (
				"  ·  ".join(changes)
				if not changes.is_empty()
				else "Sem alteração direta de atributos ou recursos."
			)
			effects_label.text = (
				"SE DISPONÍVEL · %s" % effect_summary
				if is_hypothetical
				else effect_summary
			)

		if _state.actions_remaining <= 0:
			status_label.text = "%s · SEM BLOCOS" % cost_label
			status_label.add_theme_color_override(
				"font_color",
				TrainingThemeScript.CORAL
			)
		elif cost > _state.energy:
			status_label.text = "%s · BLOQUEADA · FALTAM %d EN" % [
				cost_label,
				cost - _state.energy,
			]
			status_label.add_theme_color_override(
				"font_color",
				TrainingThemeScript.CORAL
			)
		elif preview.can_fail:
			status_label.text = (
				"%s · %d%% SUCESSO / %d%% FALHA · DISPONÍVEL"
				% [
					cost_label,
					preview.success_chance_percent,
					preview.failure_chance_percent,
				]
			)
			status_label.add_theme_color_override(
				"font_color",
				TrainingThemeScript.GOLD
			)
		else:
			status_label.text = "%s · DETERMINÍSTICA · DISPONÍVEL" % cost_label
			status_label.add_theme_color_override(
				"font_color",
				category_color
			)


func _training_resource_value(state: TrainingState, resource_id: StringName) -> int:
	match resource_id:
		&"energy":
			return state.energy
		&"stress":
			return state.stress
		&"motivation":
			return state.motivation
		_:
			return 0


func _format_compact_state_changes(
	before: TrainingState,
	after: TrainingState,
	include_stats: bool,
	include_resources: bool
) -> PackedStringArray:
	var changes := PackedStringArray()
	if before == null or after == null:
		return changes
	if include_stats:
		for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
			var delta: int = int(after.stats[stat_id]) - int(before.stats[stat_id])
			if delta != 0:
				changes.append(
					"%s %s%d"
					% [
						STAT_SHORT_LABELS[stat_id],
						"+" if delta > 0 else "",
						delta,
					]
				)
	if include_resources:
		for resource_id: StringName in [
			&"energy",
			&"stress",
			&"motivation",
			&"credits",
			&"reputation",
		]:
			var delta: int = _training_resource_value_full(after, resource_id) \
				- _training_resource_value_full(before, resource_id)
			if delta != 0:
				changes.append(
					"%s %s%d"
					% [
						_training_resource_short_label(resource_id),
						"+" if delta > 0 else "",
						delta,
					]
				)
		for bond_id: StringName in before.bonds:
			var delta: int = int(after.bonds.get(bond_id, 0)) - int(before.bonds[bond_id])
			if delta != 0:
				changes.append(
					"%s %s%d"
					% [
						_display_bond_name(bond_id),
						"+" if delta > 0 else "",
						delta,
					]
				)
	return changes


func _training_resource_value_full(state: TrainingState, resource_id: StringName) -> int:
	match resource_id:
		&"energy":
			return state.energy
		&"stress":
			return state.stress
		&"motivation":
			return state.motivation
		&"credits":
			return state.credits
		&"reputation":
			return state.reputation
		_:
			return 0


func _training_resource_short_label(resource_id: StringName) -> String:
	match resource_id:
		&"energy":
			return "EN"
		&"stress":
			return "EST"
		&"motivation":
			return "MOT"
		&"credits":
			return "CR"
		&"reputation":
			return "REP"
		_:
			return String(resource_id).to_upper()


func _update_training_preview(
	activity_id: StringName,
	preview: TrainingPreview
) -> void:
	_training_preview_title.text = _service.get_activity_label(activity_id)
	_training_result_label.visible = false
	_training_success_panel.visible = false
	_training_failure_panel.visible = false
	_training_cancel_button.disabled = false
	if not preview.is_valid:
		_training_preview_status.text = "INDISPONÍVEL"
		_training_preview_status.add_theme_color_override(
			"font_color",
			TrainingThemeScript.CORAL
		)
		_training_preview_detail.text = (
			"%s · custo %d EN. Nenhum bloco foi consumido."
			% [
				preview.message,
				_service.get_activity_energy_cost(activity_id),
			]
		)
		_training_hint_label.text = "Escolha outra atividade ou cancele a seleção."
		_training_hint_label.add_theme_color_override(
			"font_color",
			TrainingThemeScript.CORAL
		)
		_training_confirm_button.disabled = true
		_update_training_layout()
		return

	_training_preview_detail.text = "%s · custo %d EN." % [
		_category_label(_service.get_activity_category(activity_id)),
		_service.get_activity_energy_cost(activity_id),
	]
	var success_changes: PackedStringArray = _format_compact_state_changes(
		_state,
		preview.success_result if preview.can_fail else preview.result,
		true,
		true
	)
	_training_success_panel.visible = true
	_training_success_title.text = (
		"SUCESSO · %d%%" % preview.success_chance_percent
		if preview.can_fail
		else "EFEITOS · DETERMINÍSTICOS"
	)
	_training_success_body.text = (
		"  ·  ".join(success_changes)
		if not success_changes.is_empty()
		else "Sem alteração direta de atributos ou recursos."
	)
	if preview.can_fail:
		_training_preview_status.text = (
			"RISCO · %d%% falha · 1 bloco ao confirmar"
			% preview.failure_chance_percent
		)
		_training_preview_status.add_theme_color_override(
			"font_color",
			TrainingThemeScript.GOLD
		)
		_training_failure_panel.visible = true
		_training_failure_title.text = "FALHA · %d%%" % preview.failure_chance_percent
		var failure_changes: PackedStringArray = _format_compact_state_changes(
			_state,
			preview.failure_result,
			true,
			true
		)
		_training_failure_body.text = (
			"Sem ganhos de atributos; custos garantidos: %s"
			% (
				"  ·  ".join(failure_changes)
				if not failure_changes.is_empty()
				else "nenhum recurso alterado"
			)
		)
		_training_hint_label.text = (
			"A prévia não consome bloco nem realiza sorteio; confirme para aplicar."
		)
		_training_hint_label.add_theme_color_override(
			"font_color",
			TrainingThemeScript.MINT
		)
	else:
		_training_preview_status.text = "DISPONÍVEL · 1 bloco ao confirmar"
		_training_preview_status.add_theme_color_override(
			"font_color",
			TrainingThemeScript.MINT
		)
		_training_hint_label.text = (
			"A prévia não consome bloco; confirmar aplica os efeitos."
		)
		_training_hint_label.add_theme_color_override(
			"font_color",
			TrainingThemeScript.MINT
		)
	_training_confirm_button.disabled = _state.actions_remaining <= 0
	_update_training_layout()


func _show_training_result(
	activity_id: StringName,
	state_before: TrainingState,
	applied: TrainingPreview
) -> void:
	_training_preview_title.text = _service.get_activity_label(activity_id)
	_training_success_panel.visible = false
	_training_failure_panel.visible = false
	_training_result_label.visible = true
	var result_color: Color = TrainingThemeScript.MINT
	var result_title: String = "RESULTADO · ATIVIDADE CONCLUÍDA"
	if applied.outcome == TrainingPreview.OUTCOME_FAILURE:
		result_color = TrainingThemeScript.CORAL
		result_title = "RESULTADO · FALHA"
	elif applied.outcome == TrainingPreview.OUTCOME_SUCCESS:
		result_title = "RESULTADO · SUCESSO"
	elif applied.outcome == TrainingPreview.OUTCOME_DETERMINISTIC:
		result_title = "RESULTADO · DETERMINÍSTICO"
	_training_preview_status.text = result_title
	_training_preview_status.add_theme_color_override("font_color", result_color)
	var changes: PackedStringArray = _format_compact_state_changes(
		state_before,
		applied.result,
		true,
		true
	)
	var changes_text: String = (
		"  ·  ".join(changes)
		if not changes.is_empty()
		else "Nenhum atributo ou recurso mudou."
	)
	_training_result_label.text = (
		"%s\nBlocos restantes: %d / %d"
		% [
			changes_text,
			applied.result.actions_remaining,
			_service.get_actions_per_week(),
		]
	)
	_training_hint_label.text = applied.message
	_training_hint_label.add_theme_color_override("font_color", result_color)
	_training_preview_detail.text = (
		"Alterações aplicadas · custo de energia e demais efeitos já refletidos."
	)
	_update_training_layout()


func _reset_training_selection(
	title_text: String,
	status_text: String,
	detail_text: String
) -> void:
	_selected_activity = &""
	if _confirm_button != null:
		_confirm_button.disabled = true
		_cancel_button.disabled = true
		_preview_title.text = title_text
		_preview_status.text = status_text
		_preview_body.text = detail_text
		_feedback_label.text = ""
	if _training_confirm_button == null:
		return
	_training_preview_title.text = title_text
	_training_preview_status.text = status_text
	_training_preview_status.add_theme_color_override(
		"font_color",
		TrainingThemeScript.CREAM
	)
	_training_preview_detail.text = detail_text
	_training_success_panel.visible = false
	_training_failure_panel.visible = false
	_training_result_label.visible = false
	_training_hint_label.text = detail_text
	if title_text == "PLANEJAMENTO":
		_training_hint_label.text = "A prévia não consome bloco nem realiza sorteio."
	_training_hint_label.add_theme_color_override(
		"font_color",
		TrainingThemeScript.MINT
	)
	_training_confirm_button.disabled = true
	_training_confirm_button.visible = false
	_training_cancel_button.disabled = true
	_training_cancel_button.visible = false
	_update_training_layout()
	if _state != null:
		_update_activity_buttons()


func _build_hub_screen() -> void:
	_hub_ui = Control.new()
	_hub_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hub_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	_hub_ui.resized.connect(_update_hub_layout)
	add_child(_hub_ui)
	_hub_ui.add_child(_build_hub_header())
	_hub_profile_panel = _build_hub_profile_panel()
	_hub_ui.add_child(_hub_profile_panel)
	_hub_ui.add_child(_build_hub_navigation())
	_update_hub_layout()


func _update_hub_layout() -> void:
	if _hub_profile_panel == null:
		return
	_hub_profile_panel.anchor_bottom = (
		0.885
		if _hub_ui.size.y <= 640.0
		else 0.75
	)


func _build_hub_header() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.018
	panel.anchor_top = 0.018
	panel.anchor_right = 0.982
	panel.anchor_bottom = 0.125
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.88),
			Color(TrainingThemeScript.GOLD, 0.58),
			14,
			1
		)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	row.add_child(identity)
	var eyebrow := _make_label("HERO TRAINER  /  ACADEMIA", 10)
	eyebrow.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	identity.add_child(eyebrow)
	var title := _make_label("HUB DA ACADEMIA", 20)
	identity.add_child(title)

	var progress_column := VBoxContainer.new()
	progress_column.custom_minimum_size.x = 275
	progress_column.add_theme_constant_override("separation", 3)
	row.add_child(progress_column)
	var progress_header := HBoxContainer.new()
	progress_header.add_theme_constant_override("separation", 8)
	progress_column.add_child(progress_header)
	_hub_week_label = _make_label("", 12)
	_hub_week_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_header.add_child(_hub_week_label)
	_hub_actions_label = _make_label("", 11)
	_hub_actions_label.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	progress_header.add_child(_hub_actions_label)
	_hub_semester_progress = _make_progress_bar(
		_service.get_total_weeks(),
		TrainingThemeScript.MINT
	)
	_hub_semester_progress.custom_minimum_size.y = 9
	progress_column.add_child(_hub_semester_progress)
	_hub_credits_label = _make_label("", 11)
	_hub_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hub_credits_label.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
	progress_column.add_child(_hub_credits_label)
	return panel


func _build_hub_profile_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.025
	panel.anchor_top = 0.155
	panel.anchor_right = 0.365
	panel.anchor_bottom = 0.885
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.84),
			Color(TrainingThemeScript.MINT, 0.55),
			18,
			1
		)
	)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	scroll.add_child(content)

	var eyebrow := _make_section_title("CADETE  /  PERFIL")
	content.add_child(eyebrow)
	_hub_name_label = _make_label("Hori", 27)
	content.add_child(_hub_name_label)
	var subtitle := _make_label("SEMANA DE TREINAMENTO", 10)
	subtitle.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	content.add_child(subtitle)

	var actions_heading := HBoxContainer.new()
	content.add_child(actions_heading)
	var actions_title := _make_section_title("BLOCOS DISPONÍVEIS")
	actions_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_heading.add_child(actions_title)
	var action_slots := HBoxContainer.new()
	action_slots.add_theme_constant_override("separation", 5)
	for slot_index: int in range(_service.get_actions_per_week()):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(30, 25)
		slot_panel.add_theme_stylebox_override(
			"panel",
			TrainingThemeScript.make_panel_style(
				TrainingThemeScript.PETROL,
				Color(TrainingThemeScript.MINT, 0.5),
				12,
				1
			)
		)
		var slot := _make_label("%d" % (slot_index + 1), 11)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_panel.add_child(slot)
		action_slots.add_child(slot_panel)
		_hub_action_slots.append(slot_panel)
	content.add_child(action_slots)

	content.add_child(_make_section_title("CONDIÇÃO"))
	_add_hub_resource_row(content, &"energy", "Energia", TrainingThemeScript.MINT)
	_add_hub_resource_row(content, &"stress", "Estresse", TrainingThemeScript.CORAL)
	_add_hub_resource_row(content, &"motivation", "Motivação", TrainingThemeScript.GOLD)

	content.add_child(_make_section_title("ATRIBUTOS"))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 4)
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var stat_card := PanelContainer.new()
		stat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_style := TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL_MUTED, 0.88),
			Color(TrainingThemeScript.MINT, 0.25),
			8,
			1
		)
		card_style.content_margin_left = 3
		card_style.content_margin_right = 3
		card_style.content_margin_top = 3
		card_style.content_margin_bottom = 3
		stat_card.add_theme_stylebox_override("panel", card_style)
		var stat_content := VBoxContainer.new()
		stat_content.add_theme_constant_override("separation", 0)
		stat_card.add_child(stat_content)
		var stat_name := _make_label(STAT_SHORT_LABELS[stat_id], 8)
		stat_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_content.add_child(stat_name)
		var stat_value := _make_label("", 11)
		stat_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_value.add_theme_color_override("font_color", TrainingThemeScript.GOLD)
		stat_content.add_child(stat_value)
		stats.add_child(stat_card)
		_hub_stat_values[stat_id] = stat_value
	content.add_child(stats)

	content.add_child(_make_section_title("VÍNCULOS"))
	var bonds := HBoxContainer.new()
	bonds.add_theme_constant_override("separation", 4)
	for bond_id: StringName in _service.get_bond_ids():
		var bond_value := _make_label("", 9)
		bond_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bond_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonds.add_child(bond_value)
		_hub_bond_values[bond_id] = bond_value
	content.add_child(bonds)

	content.add_child(_make_section_title("PRÓXIMO MARCO"))
	_hub_objective_label = _make_label("", 11)
	_hub_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hub_objective_label.add_theme_color_override("font_color", TrainingThemeScript.CREAM)
	content.add_child(_hub_objective_label)

	var training_button := Button.new()
	training_button.text = "IR PARA TREINAMENTO  →"
	training_button.custom_minimum_size.y = 42
	training_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	training_button.add_theme_stylebox_override(
		"normal",
		TrainingThemeScript.make_panel_style(
			TrainingThemeScript.PETROL,
			TrainingThemeScript.MINT,
			14,
			1
		)
	)
	training_button.pressed.connect(_show_management_area.bind(&"training"))
	content.add_child(training_button)
	return panel


func _add_hub_resource_row(
	parent: VBoxContainer,
	resource_id: StringName,
	label_text: String,
	bar_color: Color
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var name_label := _make_label(label_text, 10)
	name_label.custom_minimum_size.x = 61
	row.add_child(name_label)
	var bar := _make_progress_bar(_service.get_resource_cap(), bar_color)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 8
	row.add_child(bar)
	var value_label := _make_label("", 9)
	value_label.custom_minimum_size.x = 45
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	parent.add_child(row)
	_hub_resource_bars[resource_id] = bar
	_hub_resource_values[resource_id] = value_label


func _build_hub_navigation() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.265
	panel.anchor_top = 0.91
	panel.anchor_right = 0.982
	panel.anchor_bottom = 0.985
	panel.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PANEL, 0.92),
			Color(TrainingThemeScript.GOLD, 0.62),
			16,
			1
		)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	panel.add_child(row)
	for area: StringName in [&"hub", &"training", &"status", &"relationships"]:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.text = _hub_area_label(area)
		button.add_theme_stylebox_override(
			"normal",
			TrainingThemeScript.make_panel_style(
				Color(TrainingThemeScript.PETROL, 0.82)
				if area == &"hub"
				else Color(TrainingThemeScript.PANEL, 0.45),
				Color(TrainingThemeScript.MINT, 0.38),
				12,
				1
			)
		)
		button.add_theme_stylebox_override(
			"hover",
			TrainingThemeScript.make_panel_style(
				Color(TrainingThemeScript.PETROL, 0.96),
				TrainingThemeScript.MINT,
				12,
				1
			)
		)
		button.pressed.connect(_on_hub_navigation_pressed.bind(area))
		row.add_child(button)
		_hub_nav_buttons[area] = button
	return panel


func _hub_area_label(area: StringName) -> String:
	match area:
		&"hub":
			return "⌂  HUB"
		&"training":
			return "✦  TREINO"
		&"status":
			return "◇  STATUS"
		&"relationships":
			return "♡  RELAÇÕES"
		_:
			return String(area).to_upper()


func _on_hub_navigation_pressed(area: StringName) -> void:
	if area == &"hub":
		_show_hub()
	else:
		_show_management_area(area)


func _show_management_area(area: StringName) -> void:
	if _narrative_overlay != null and _narrative_overlay.visible:
		return
	var previous_area: StringName = _current_area
	if previous_area == &"training" and area != &"training":
		_reset_training_selection(
			"PLANEJAMENTO",
			"Selecione uma atividade.",
			"Escolha uma atividade para comparar efeitos e disponibilidade."
		)
	elif area == &"training" and previous_area != &"training":
		_reset_training_selection(
			"PLANEJAMENTO",
			"Selecione uma atividade.",
			"Escolha uma atividade para comparar efeitos e disponibilidade."
		)
	_current_area = area
	_hub_ui.visible = false
	_training_ui.visible = area == &"training"
	_status_ui.visible = area == &"status"
	_management_ui.visible = area != &"training" and area != &"status"
	if area == &"status":
		_update_status_state()
	_update_training_navigation()
	_update_status_navigation()
	_set_hori_presentation(
		HoriPresentation.STATUS_SIDE
		if area == &"status"
		else HoriPresentation.RIGHT_SIDE
	)
	call_deferred("_focus_management_area", area)


func _focus_management_area(area: StringName) -> void:
	if area == &"status":
		return
	if _character_panel_scroll == null:
		return
	match area:
		&"status":
			_character_panel_scroll.scroll_vertical = int(_status_section.position.y)
		&"relationships":
			_character_panel_scroll.scroll_vertical = int(_bonds_section.position.y)
		_:
			_character_panel_scroll.scroll_vertical = 0
	if area == &"training" and _activity_scroll != null:
		_activity_scroll.scroll_vertical = 0


func _show_hub() -> void:
	if _narrative_overlay != null and _narrative_overlay.visible:
		return
	if _current_area == &"training":
		_reset_training_selection(
			"PLANEJAMENTO",
			"Selecione uma atividade.",
			"A prévia foi encerrada sem alterar a campanha."
		)
	_current_area = &"hub"
	_hub_ui.visible = true
	_management_ui.visible = false
	_training_ui.visible = false
	_status_ui.visible = false
	_set_scene_context(&"academy")
	_set_hori_presentation(HoriPresentation.RIGHT_SIDE)
	_update_hub_state()
	_update_training_navigation()
	_update_status_navigation()


func _update_hub_state() -> void:
	if _state == null or _hub_ui == null:
		return
	_hub_week_label.text = "SEMANA %02d / %02d" % [
		_state.week,
		_service.get_total_weeks(),
	]
	_hub_semester_progress.max_value = maxi(1, _service.get_total_weeks())
	_hub_semester_progress.value = _state.week
	_hub_actions_label.text = "BLOCOS %d / %d" % [
		_state.actions_remaining,
		_service.get_actions_per_week(),
	]
	_hub_credits_label.text = "CR  %d" % _state.credits
	for slot_index: int in range(_hub_action_slots.size()):
		_hub_action_slots[slot_index].modulate = (
			TrainingThemeScript.MINT
			if slot_index < _state.actions_remaining
			else Color(TrainingThemeScript.CREAM, 0.42)
		)
	for stat_id: StringName in _hub_stat_values:
		_hub_stat_values[stat_id].text = str(_state.stats[stat_id])
	for resource_id: StringName in _hub_resource_bars:
		var resource_value: int
		match resource_id:
			&"energy":
				resource_value = _state.energy
			&"stress":
				resource_value = _state.stress
			&"motivation":
				resource_value = _state.motivation
			_:
				continue
		_hub_resource_bars[resource_id].value = resource_value
		_hub_resource_values[resource_id].text = "%d / %d" % [
			resource_value,
			_service.get_resource_cap(),
		]
	for bond_id: StringName in _hub_bond_values:
		_hub_bond_values[bond_id].text = "%s  %d" % [
			_display_bond_name(bond_id),
			int(_state.bonds.get(bond_id, 0)),
		]
	_hub_objective_label.text = _get_hub_objective_text()


func _get_hub_objective_text() -> String:
	if _narrative_service == null:
		return ""
	if _narrative_service.is_mission_due(_state):
		var stage: Dictionary = _narrative_service.get_current_mission_stage(_state)
		if not stage.is_empty():
			return "%s  ·  %s" % [
				_narrative_service.get_mission_title(),
				String(stage.get("objective", "")),
			]
	var event: Dictionary = _narrative_service.get_next_event(_state)
	if not event.is_empty():
		return String(event.get("title", ""))
	if (
		_state.week == _service.get_total_weeks()
		and _state.actions_remaining == 0
	):
		return "Ciclo de treinamento concluído."
	return "Nenhum evento narrativo pendente."


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
		else 0.90
		if _hori_presentation == HoriPresentation.STATUS_SIDE
		else 0.94
	)
	var max_width: float = stage_size.x * (
		0.58
		if _hori_presentation == HoriPresentation.CENTER_STAGE
		else 0.30
		if _hori_presentation == HoriPresentation.STATUS_SIDE
		else 0.50
	)
	var portrait_width: float = minf(max_width, max_height * aspect_ratio)
	var portrait_height: float = portrait_width / aspect_ratio
	_portrait.size = Vector2(portrait_width, portrait_height)
	_portrait.position = Vector2(
		0.0
		if _hori_presentation == HoriPresentation.STATUS_SIDE
		else (
			(stage_size.x - portrait_width) * 0.5
			if _hori_presentation == HoriPresentation.CENTER_STAGE
			else stage_size.x - portrait_width
		),
		stage_size.y - portrait_height
	)


func _show_narrative_overlay() -> void:
	_set_hori_presentation(HoriPresentation.CENTER_STAGE)
	_update_narrative_panel_layout()
	_management_ui.visible = false
	_hub_ui.visible = false
	_training_ui.visible = false
	_status_ui.visible = false
	_narrative_overlay.visible = true


func _hide_narrative_overlay() -> void:
	_narrative_overlay.visible = false
	_current_area = &"hub"
	_management_ui.visible = false
	_training_ui.visible = false
	_status_ui.visible = false
	_hub_ui.visible = true
	_set_hori_presentation(HoriPresentation.RIGHT_SIDE)
	_update_hub_state()
	_update_training_navigation()
	_update_status_navigation()


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
	_training_cancel_button.disabled = false
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
		_update_training_preview(activity_id, preview)
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
	_update_training_preview(activity_id, preview)
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
		_training_confirm_button.disabled = true
		_training_preview_status.text = "INDISPONÍVEL"
		_training_preview_status.add_theme_color_override(
			"font_color",
			TrainingThemeScript.CORAL
		)
		_training_preview_detail.text = applied.message
		_training_hint_label.text = "Nenhum recurso ou bloco foi consumido."
		_training_hint_label.add_theme_color_override(
			"font_color",
			TrainingThemeScript.CORAL
		)
		_feedback_label.text = "Nenhum recurso ou bloco foi consumido."
		return

	_selected_activity = &""
	_refresh_state()
	_show_training_result(activity_id, state_before, applied)
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
	_reset_training_selection(
		"PLANEJAMENTO",
		"Selecione uma atividade.",
		"A prévia foi cancelada; nenhum recurso ou bloco foi alterado."
	)
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
	_reset_training_selection(
		"NOVA SEMANA",
		"Semana %d iniciada." % _state.week,
		"Escolha uma atividade para planejar o próximo bloco."
	)
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
	_update_hub_state()
	_update_status_state()


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
	_update_training_state()


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

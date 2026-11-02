extends Control

signal week_completed(week_number: int)

const TrainingServiceScript = preload("res://scripts/training_service.gd")
const TrainingThemeScript = preload("res://scripts/training_theme.gd")
const STAT_LABELS: Dictionary[StringName, String] = {
	&"pot": "Potência",
	&"res": "Resistência",
	&"tec": "Técnica",
	&"teo": "Teoria",
	&"sin": "Sincronia",
}

var _service: TrainingService
var _state: TrainingState
var _selected_activity: StringName = &""
var _character_name_label: Label
var _week_label: Label
var _actions_label: Label
var _semester_progress: ProgressBar
var _portrait: TextureRect
var _portrait_placeholder: Control
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


func _ready() -> void:
	_service = TrainingServiceScript.new()
	var project_data_loaded: bool = _service.load_project_data()
	_build_interface()
	if not project_data_loaded:
		_feedback_label.text = "Não foi possível carregar os dados de treinamento."
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
	if _portrait != null:
		_portrait.texture = portrait_texture
		_portrait_placeholder.visible = portrait_texture == null


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = TrainingThemeScript.create_theme()

	var background := ColorRect.new()
	background.color = TrainingThemeScript.INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	layout.add_child(_build_header())
	layout.add_child(_build_main_panels())
	layout.add_child(_build_preview_dock())


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
	var panel_style := TrainingThemeScript.make_panel_style()
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
	content.add_child(_build_portrait_slot())
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


func _build_portrait_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(0, 68)
	slot.add_theme_stylebox_override(
		"panel",
		TrainingThemeScript.make_panel_style(
			Color(TrainingThemeScript.PETROL, 0.38),
			Color(TrainingThemeScript.MINT, 0.52),
			10,
			1
		)
	)
	_portrait = TextureRect.new()
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(_portrait)

	var placeholder := CenterContainer.new()
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(placeholder)
	var placeholder_text := _make_label("◈\nRETRATO PROVISÓRIO", 12)
	placeholder_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_text.add_theme_color_override("font_color", TrainingThemeScript.MINT)
	placeholder.add_child(placeholder_text)
	_portrait_placeholder = placeholder
	return slot


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
			Color(TrainingThemeScript.PANEL, 0.98),
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


func _on_activity_selected(activity_id: StringName) -> void:
	if _state == null or _state.actions_remaining <= 0:
		return
	_selected_activity = activity_id
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

	_preview_status.text = "DISPONÍVEL  ·  consome 1 bloco semanal ao confirmar"
	_preview_status.add_theme_color_override(
		"font_color",
		TrainingThemeScript.MINT
	)
	_preview_body.text = _format_preview(activity_id, preview.result)
	_confirm_button.disabled = false
	_feedback_label.text = "A prévia não consome ação."


func _on_confirm_pressed() -> void:
	if _state == null or _selected_activity == &"":
		return
	var applied: TrainingPreview = _service.apply_activity(_state, _selected_activity)
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
	if _state.actions_remaining == 0:
		if _state.week < _service.get_total_weeks():
			week_completed.emit(_state.week)
			_feedback_label.text = "Semana concluída. Avance quando estiver pronto."
		else:
			_feedback_label.text = "Ciclo de %d semanas concluído." % _service.get_total_weeks()
	else:
		_feedback_label.text = "Treinamento aplicado. Foi consumido 1 bloco."


func _on_cancel_pressed() -> void:
	_selected_activity = &""
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
	_preview_title.text = "NOVA SEMANA"
	_preview_status.text = "Semana %d iniciada." % _state.week
	_preview_body.text = "Escolha uma atividade para planejar o próximo bloco."
	_feedback_label.text = ""
	_confirm_button.disabled = true
	_cancel_button.disabled = true
	_refresh_state()


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
	if _state.week >= _service.get_total_weeks() and week_finished:
		_advance_button.text = "Semestre encerrado"
	else:
		_advance_button.text = "Avançar semana"
	if _selected_activity != &"":
		_confirm_button.disabled = true


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


func _format_preview(activity_id: StringName, result: TrainingState) -> String:
	var effect_lines := PackedStringArray()
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		_append_change(
			effect_lines,
			STAT_LABELS[stat_id],
			_state.stats[stat_id],
			result.stats[stat_id]
		)
	_append_change(effect_lines, "Energia", _state.energy, result.energy)
	_append_change(effect_lines, "Estresse", _state.stress, result.stress)
	_append_change(effect_lines, "Motivação", _state.motivation, result.motivation)
	_append_change(effect_lines, "Créditos", _state.credits, result.credits)
	_append_change(effect_lines, "Reputação", _state.reputation, result.reputation)
	for bond_id: StringName in _state.bonds:
		_append_change(
			effect_lines,
			"Vínculo — %s" % _display_bond_name(bond_id),
			_state.bonds[bond_id],
			result.bonds[bond_id]
		)
	if effect_lines.is_empty():
		effect_lines.append("Sem alteração direta nos atributos ou recursos.")

	var lines := PackedStringArray()
	lines.append(
		"Categoria: %s  ·  Energia necessária: %d"
		% [
			_category_label(_service.get_activity_category(activity_id)),
			_service.get_activity_energy_cost(activity_id),
		]
	)
	lines.append("  ·  ".join(effect_lines))
	lines.append(
		"Ações: %d → %d (1 bloco será consumido ao confirmar)."
		% [_state.actions_remaining, result.actions_remaining]
	)
	return "\n".join(lines)


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

extends Control

signal week_completed(week_number: int)

const TrainingServiceScript = preload("res://scripts/training_service.gd")
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
var _week_label: Label
var _actions_label: Label
var _status_label: Label
var _preview_panel: PanelContainer
var _preview_label: Label
var _confirm_button: Button
var _activity_buttons: Dictionary[StringName, Button] = {}
var _stat_labels: Dictionary[StringName, Label] = {}
var _resource_bars: Dictionary[StringName, ProgressBar] = {}
var _resource_values: Dictionary[StringName, Label] = {}
var _credits_value: Label
var _advance_button: Button


func _ready() -> void:
	_service = TrainingServiceScript.new()
	var project_data_loaded: bool = _service.load_project_data()
	_build_interface()
	if not project_data_loaded:
		_status_label.text = "Não foi possível carregar os dados de treinamento."
		_set_activity_buttons_enabled(false)
		return
	_state = _service.create_initial_state()
	_refresh_state()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

	var header: HBoxContainer = HBoxContainer.new()
	content.add_child(header)
	var title: Label = _make_label("Hori — semana de treinamento", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_week_label = _make_label("", 22)
	header.add_child(_week_label)

	content.add_child(_make_label("Atributos", 18))
	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	content.add_child(stats_row)
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var stat_column: VBoxContainer = VBoxContainer.new()
		stat_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_row.add_child(stat_column)
		stat_column.add_child(_make_label(STAT_LABELS[stat_id], 14))
		var value_label: Label = _make_label("", 20)
		stat_column.add_child(value_label)
		_stat_labels[stat_id] = value_label

	content.add_child(_make_label("Condição", 18))
	_add_resource_row(content, &"energy", "Energia", Color(0.35, 0.72, 0.86))
	_add_resource_row(content, &"stress", "Estresse", Color(0.88, 0.55, 0.39))
	_add_resource_row(content, &"motivation", "Motivação", Color(0.55, 0.75, 0.48))
	_add_text_row(content, "Créditos")
	_add_progress_row(
		content,
		&"reputation",
		"Reputação",
		_service.get_reputation_cap(),
		Color(0.78, 0.68, 0.34)
	)
	for bond_id: StringName in _service.get_bond_ids():
		_add_progress_row(
			content,
			bond_id,
			"Vínculo — %s" % _display_bond_name(bond_id),
			_service.get_bond_cap(),
			Color(0.68, 0.55, 0.82)
		)

	content.add_child(_make_label("Escolha uma atividade", 18))
	var activities_grid: GridContainer = GridContainer.new()
	activities_grid.columns = 2
	activities_grid.add_theme_constant_override("h_separation", 12)
	activities_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(activities_grid)
	for activity_id: StringName in _service.get_activity_ids():
		var button: Button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 72)
		button.pressed.connect(_on_activity_selected.bind(activity_id))
		button.text = _format_activity_button(activity_id)
		button.tooltip_text = _service.get_activity_category(activity_id)
		activities_grid.add_child(button)
		_activity_buttons[activity_id] = button

	_actions_label = _make_label("", 16)
	content.add_child(_actions_label)

	_preview_panel = PanelContainer.new()
	_preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_preview_panel)
	var preview_content: VBoxContainer = VBoxContainer.new()
	preview_content.add_theme_constant_override("separation", 12)
	_preview_panel.add_child(preview_content)
	_preview_label = _make_label("", 16)
	_preview_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_content.add_child(_preview_label)

	var preview_buttons: HBoxContainer = HBoxContainer.new()
	preview_buttons.add_theme_constant_override("separation", 12)
	preview_content.add_child(preview_buttons)
	_confirm_button = Button.new()
	_confirm_button.text = "Confirmar treinamento"
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_button.pressed.connect(_on_confirm_pressed)
	preview_buttons.add_child(_confirm_button)
	var cancel_button: Button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.pressed.connect(_on_cancel_pressed)
	preview_buttons.add_child(cancel_button)
	_preview_panel.visible = false

	_status_label = _make_label("Selecione uma atividade para ver a prévia.", 14)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status_label)
	_advance_button = Button.new()
	_advance_button.text = "Avançar para a próxima semana"
	_advance_button.custom_minimum_size = Vector2(0, 48)
	_advance_button.pressed.connect(_on_advance_week_pressed)
	content.add_child(_advance_button)
	_advance_button.visible = false


func _add_resource_row(
	parent: VBoxContainer,
	resource_id: StringName,
	label_text: String,
	bar_color: Color
) -> void:
	_add_progress_row(
		parent,
		resource_id,
		label_text,
		_service.get_resource_cap(),
		bar_color
	)


func _add_progress_row(
	parent: VBoxContainer,
	resource_id: StringName,
	label_text: String,
	max_value: int,
	bar_color: Color
) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label: Label = _make_label(label_text, 14)
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	var bar: ProgressBar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_value
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", fill_style)
	row.add_child(bar)
	_resource_bars[resource_id] = bar

	var display_value: Label = _make_label("", 14)
	display_value.custom_minimum_size = Vector2(56, 0)
	display_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(display_value)
	_resource_values[resource_id] = display_value


func _add_text_row(parent: VBoxContainer, label_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label: Label = _make_label(label_text, 14)
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	_credits_value = _make_label("0", 14)
	_credits_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_credits_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_credits_value)


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


func _format_activity_button(activity_id: StringName) -> String:
	return "%s\n%s · Energia: %d" % [
		_service.get_activity_label(activity_id),
		_category_label(_service.get_activity_category(activity_id)),
		_service.get_activity_energy_cost(activity_id),
	]


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


func _make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _on_activity_selected(activity_id: StringName) -> void:
	if _state == null or _state.actions_remaining <= 0:
		return
	_selected_activity = activity_id
	var preview: TrainingPreview = _service.preview_activity(_state, activity_id)
	if not preview.is_valid:
		_preview_label.text = preview.message
		_preview_panel.visible = true
		_confirm_button.disabled = true
		_status_label.text = "Atividade bloqueada. Descanse ou escolha outra atividade."
		return
	_preview_label.text = _format_preview(activity_id, preview.result)
	_preview_panel.visible = true
	_confirm_button.disabled = false
	_status_label.text = "A prévia não consome uma ação. Confirme para aplicar."


func _on_confirm_pressed() -> void:
	if _state == null or _selected_activity == &"":
		return
	var applied: TrainingPreview = _service.apply_activity(_state, _selected_activity)
	if not applied.is_valid:
		_preview_label.text = applied.message
		_confirm_button.disabled = true
		_status_label.text = "Atividade bloqueada. Descanse ou escolha outra atividade."
		return
	_preview_panel.visible = false
	_selected_activity = &""
	_refresh_state()
	if _state.actions_remaining == 0:
		if _state.week < _service.get_total_weeks():
			week_completed.emit(_state.week)
			_status_label.text = "Semana concluída. Avance para iniciar outra."
		else:
			_status_label.text = "Ciclo de %d semanas concluído." % _service.get_total_weeks()
	else:
		_status_label.text = "Treinamento aplicado."


func _on_cancel_pressed() -> void:
	_selected_activity = &""
	_preview_panel.visible = false
	_status_label.text = "Prévia cancelada; nenhuma ação foi consumida."


func _on_advance_week_pressed() -> void:
	if _state == null or not _service.advance_week(_state):
		return
	_selected_activity = &""
	_preview_panel.visible = false
	_status_label.text = "Nova semana iniciada."
	_refresh_state()


func _refresh_state() -> void:
	if _state == null:
		return
	_week_label.text = "Semana %d" % _state.week
	_actions_label.text = "Ações restantes: %d de %d" % [
		_state.actions_remaining,
		_service.get_actions_per_week(),
	]
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		_stat_labels[stat_id].text = str(_state.stats[stat_id])
	_set_resource_display(&"energy", _state.energy)
	_set_resource_display(&"stress", _state.stress)
	_set_resource_display(&"motivation", _state.motivation)
	_credits_value.text = str(_state.credits)
	_set_resource_display(&"reputation", _state.reputation)
	for bond_id: StringName in _state.bonds:
		_set_resource_display(bond_id, _state.bonds[bond_id])
	var has_actions: bool = _state.actions_remaining > 0
	_set_activity_buttons_enabled(has_actions)
	_advance_button.visible = (
		not has_actions
		and _state.week < _service.get_total_weeks()
	)


func _set_resource_display(resource_id: StringName, value: int) -> void:
	if not _resource_bars.has(resource_id):
		return
	_resource_bars[resource_id].value = value
	var maximum: int = int(_resource_bars[resource_id].max_value)
	_resource_values[resource_id].text = "%d / %d" % [
		value,
		maximum,
	]


func _set_activity_buttons_enabled(enabled: bool) -> void:
	for activity_id: StringName in _service.get_activity_ids():
		var button: Button = _activity_buttons[activity_id]
		button.disabled = not enabled


func _format_preview(activity_id: StringName, result: TrainingState) -> String:
	var lines: PackedStringArray = [
		"Prévia — %s" % _service.get_activity_label(activity_id),
		"Categoria: %s · Energia necessária: %d"
		% [
			_category_label(_service.get_activity_category(activity_id)),
			_service.get_activity_energy_cost(activity_id),
		],
	]
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var old_value: int = _state.stats[stat_id]
		var new_value: int = result.stats[stat_id]
		if old_value != new_value:
			lines.append("%s: %d → %d" % [STAT_LABELS[stat_id], old_value, new_value])
	_append_resource_preview(lines, "Energia", _state.energy, result.energy)
	_append_resource_preview(lines, "Estresse", _state.stress, result.stress)
	_append_resource_preview(lines, "Motivação", _state.motivation, result.motivation)
	_append_resource_preview(lines, "Créditos", _state.credits, result.credits)
	_append_resource_preview(lines, "Reputação", _state.reputation, result.reputation)
	for bond_id: StringName in _state.bonds:
		_append_resource_preview(
			lines,
			"Vínculo — %s" % _display_bond_name(bond_id),
			_state.bonds[bond_id],
			result.bonds[bond_id]
		)
	lines.append("Ações restantes após confirmar: %d" % result.actions_remaining)
	return "\n".join(lines)


func _append_resource_preview(
	lines: PackedStringArray,
	label: String,
	old_value: int,
	new_value: int
) -> void:
	if old_value != new_value:
		lines.append("%s: %d → %d" % [label, old_value, new_value])

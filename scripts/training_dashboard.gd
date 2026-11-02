extends Control

signal week_completed(week_number: int)

const TrainingServiceScript = preload("res://scripts/training_service.gd")
const ACTIVITY_IDS: Array[StringName] = [
	&"combat",
	&"control",
	&"rest",
]
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
var _advance_button: Button


func _ready() -> void:
	_build_interface()
	_service = TrainingServiceScript.new()
	if not _service.load_project_data():
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

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)

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

	content.add_child(_make_label("Escolha uma atividade", 18))
	var activities_row: HBoxContainer = HBoxContainer.new()
	activities_row.add_theme_constant_override("separation", 12)
	content.add_child(activities_row)
	for activity_id: StringName in ACTIVITY_IDS:
		var button: Button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 64)
		button.pressed.connect(_on_activity_selected.bind(activity_id))
		activities_row.add_child(button)
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
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label: Label = _make_label(label_text, 14)
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	var bar: ProgressBar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = TrainingService.RESOURCE_CAP
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", fill_style)
	row.add_child(bar)
	_resource_bars[resource_id] = bar

	var value_label: Label = _make_label("", 14)
	value_label.custom_minimum_size = Vector2(56, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	_resource_values[resource_id] = value_label


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
		_status_label.text = preview.message
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
		_status_label.text = applied.message
		return
	_preview_panel.visible = false
	_selected_activity = &""
	_refresh_state()
	if _state.actions_remaining == 0:
		week_completed.emit(_state.week)
		_status_label.text = "Semana concluída. Avance para iniciar outra."
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
		TrainingService.ACTIONS_PER_WEEK,
	]
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		_stat_labels[stat_id].text = str(_state.stats[stat_id])
	_set_resource_display(&"energy", _state.energy)
	_set_resource_display(&"stress", _state.stress)
	_set_resource_display(&"motivation", _state.motivation)
	var has_actions: bool = _state.actions_remaining > 0
	_set_activity_buttons_enabled(has_actions)
	_advance_button.visible = not has_actions


func _set_resource_display(resource_id: StringName, value: int) -> void:
	_resource_bars[resource_id].value = value
	_resource_values[resource_id].text = "%d / %d" % [
		value,
		TrainingService.RESOURCE_CAP,
	]


func _set_activity_buttons_enabled(enabled: bool) -> void:
	for activity_id: StringName in ACTIVITY_IDS:
		var button: Button = _activity_buttons[activity_id]
		button.disabled = not enabled
		if _service != null:
			var label: String = _service.get_activity_label(activity_id)
			if not label.is_empty():
				button.text = label


func _format_preview(activity_id: StringName, result: TrainingState) -> String:
	var lines: PackedStringArray = [
		"Prévia — %s" % _service.get_activity_label(activity_id),
	]
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var old_value: int = _state.stats[stat_id]
		var new_value: int = result.stats[stat_id]
		if old_value != new_value:
			lines.append("%s: %d → %d" % [STAT_LABELS[stat_id], old_value, new_value])
	_append_resource_preview(lines, "Energia", _state.energy, result.energy)
	_append_resource_preview(lines, "Estresse", _state.stress, result.stress)
	_append_resource_preview(lines, "Motivação", _state.motivation, result.motivation)
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

class_name TrainingService
extends RefCounted

const CHARACTER_DATA_PATH: String = "res://Hero_Trainer_Kit_v02/data/characters.json"
const ACTIVITIES_DATA_PATH: String = "res://Hero_Trainer_Kit_v02/data/activities.json"
const REQUIRED_ACTIVITY_IDS: Array[StringName] = [
	&"combat",
	&"control",
	&"rest",
]
const RESOURCE_KEY_MAP: Dictionary[StringName, StringName] = {
	&"energy": &"energy",
	&"stress": &"stress",
	&"mood": &"motivation",
}

var _activities: Dictionary[StringName, Dictionary] = {}
var _activity_labels: Dictionary[StringName, String] = {}
var _initial_state: TrainingState
var _total_weeks: int = 0
var _actions_per_week: int = 0
var _attribute_cap: int = 0
var _resource_cap: int = 0


func get_total_weeks() -> int:
	return _total_weeks


func get_actions_per_week() -> int:
	return _actions_per_week


func get_attribute_cap() -> int:
	return _attribute_cap


func get_resource_cap() -> int:
	return _resource_cap


func get_activity_ids() -> Array[StringName]:
	return REQUIRED_ACTIVITY_IDS.duplicate()


func load_project_data() -> bool:
	var character_data: Variant = _read_json(CHARACTER_DATA_PATH)
	if character_data == null:
		return false
	if typeof(character_data) != TYPE_DICTIONARY:
		push_error("A raiz de characters.json precisa ser um objeto JSON.")
		return false

	var character_root: Dictionary = character_data
	var characters_value: Variant = character_root.get("characters")
	if typeof(characters_value) != TYPE_ARRAY:
		push_error("characters.json precisa conter a lista 'characters'.")
		return false

	var character: Dictionary
	var character_found: bool = false
	for character_value: Variant in characters_value:
		if typeof(character_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = character_value
		if candidate.get("id") == "hori":
			character = candidate
			character_found = true
			break
	if not character_found:
		push_error("A personagem Hori não foi encontrada em characters.json.")
		return false

	var stats_value: Variant = character.get("stats")
	var resources_value: Variant = character.get("resources")
	if typeof(stats_value) != TYPE_DICTIONARY:
		push_error("Os atributos iniciais de Hori estão ausentes ou inválidos.")
		return false
	if typeof(resources_value) != TYPE_DICTIONARY:
		push_error("Os recursos iniciais de Hori estão ausentes ou inválidos.")
		return false

	var stats_data: Dictionary = stats_value
	var resources_data: Dictionary = resources_value

	var activities_data: Variant = _read_json(ACTIVITIES_DATA_PATH)
	if activities_data == null:
		return false
	if typeof(activities_data) != TYPE_DICTIONARY:
		push_error("A raiz de activities.json precisa ser um objeto JSON.")
		return false

	var activities_root: Dictionary = activities_data
	var attribute_cap: int = _read_positive_integer(
		activities_root,
		"stat_cap",
		"activities.json"
	)
	var resource_cap: int = _read_positive_integer(
		activities_root,
		"resource_cap",
		"activities.json"
	)
	if attribute_cap < 1 or resource_cap < 1:
		return false
	var initial_state := TrainingState.new()
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var stat_key: String = String(stat_id)
		if not _has_integer(stats_data, stat_key, "stats de Hori"):
			return false
		initial_state.stats[stat_id] = clampi(
			int(stats_data[stat_key]),
			0,
			attribute_cap
		)

	for resource_key: StringName in [&"energy", &"stress", &"mood"]:
		var key: String = String(resource_key)
		if not _has_integer(resources_data, key, "resources de Hori"):
			return false

	initial_state.energy = clampi(int(resources_data["energy"]), 0, resource_cap)
	initial_state.stress = clampi(int(resources_data["stress"]), 0, resource_cap)
	initial_state.motivation = clampi(int(resources_data["mood"]), 0, resource_cap)

	var calendaring_value: Variant = activities_root.get("calendaring")
	if typeof(calendaring_value) != TYPE_DICTIONARY:
		push_error("activities.json precisa definir 'calendaring'.")
		return false
	var calendaring: Dictionary = calendaring_value
	var total_weeks: int = _read_positive_integer(
		calendaring,
		"total_weeks",
		"calendaring"
	)
	var actions_per_week: int = _read_positive_integer(
		calendaring,
		"action_blocks_per_week",
		"calendaring"
	)
	if total_weeks < 1 or actions_per_week < 1:
		return false

	var activities_value: Variant = activities_root.get("activities")
	if typeof(activities_value) != TYPE_ARRAY:
		push_error("activities.json precisa conter a lista 'activities'.")
		return false

	var loaded_activities: Dictionary[StringName, Dictionary] = {}
	var loaded_labels: Dictionary[StringName, String] = {}
	for required_id: StringName in REQUIRED_ACTIVITY_IDS:
		var found: bool = false
		for activity_value: Variant in activities_value:
			if typeof(activity_value) != TYPE_DICTIONARY:
				continue
			var activity: Dictionary = activity_value
			if activity.get("id") != String(required_id):
				continue
			if not _validate_activity(activity, required_id):
				return false
			loaded_activities[required_id] = activity
			loaded_labels[required_id] = String(activity["label"])
			found = true
			break
		if not found:
			push_error("A atividade '%s' não foi encontrada em activities.json." % required_id)
			return false

	for activity_id: StringName in [&"combat", &"control"]:
		var activity: Dictionary = loaded_activities[activity_id]
		var resource_delta: Dictionary = activity["resource_delta"]
		if not resource_delta.has("energy") or int(resource_delta["energy"]) >= 0:
			push_error(
				"A atividade '%s' precisa definir um custo de energia positivo."
				% activity_id
			)
			return false

	_activities = loaded_activities
	_activity_labels = loaded_labels
	_initial_state = initial_state
	_total_weeks = total_weeks
	_actions_per_week = actions_per_week
	_attribute_cap = attribute_cap
	_resource_cap = resource_cap
	_initial_state.actions_remaining = _actions_per_week
	return true


func create_initial_state() -> TrainingState:
	if _initial_state == null:
		push_error("Carregue os dados do projeto antes de criar o estado de treino.")
		return null
	return _initial_state.duplicate_state()


func get_activity_label(activity_id: StringName) -> String:
	if not _activity_labels.has(activity_id):
		push_error("Atividade desconhecida: %s." % activity_id)
		return ""
	return _activity_labels[activity_id]


func preview_activity(
	state: TrainingState,
	activity_id: StringName
) -> TrainingPreview:
	var preview := TrainingPreview.new()
	if state == null:
		preview.message = "O estado de treinamento não está disponível."
		return preview
	if state.actions_remaining <= 0:
		preview.message = "As %d ações da semana já foram usadas." % _actions_per_week
		return preview
	if not _activities.has(activity_id):
		preview.message = "Esta atividade não está disponível."
		return preview

	var activity: Dictionary = _activities[activity_id]
	var resource_delta: Dictionary = activity["resource_delta"]
	var energy_cost: int = maxi(0, -int(resource_delta.get("energy", 0)))
	if state.energy < energy_cost:
		var missing_energy: int = energy_cost - state.energy
		preview.message = (
			"Energia insuficiente para %s: precisa de %d, mas Hori tem %d. "
			+ "Faltam %d de energia."
		) % [
			_activity_labels[activity_id],
			energy_cost,
			state.energy,
			missing_energy,
		]
		return preview

	var next_state: TrainingState = state.duplicate_state()
	var stats_delta: Dictionary = activity["stats_delta"]
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var delta_key: String = String(stat_id)
		if stats_delta.has(delta_key):
			next_state.stats[stat_id] = clampi(
				next_state.stats[stat_id] + int(stats_delta[delta_key]),
				0,
				_attribute_cap
			)

	for data_key: StringName in RESOURCE_KEY_MAP:
		var json_key: String = String(data_key)
		if not resource_delta.has(json_key):
			continue
		var state_key: StringName = RESOURCE_KEY_MAP[data_key]
		var changed_value: int = _get_resource_value(next_state, state_key)
		changed_value += int(resource_delta[json_key])
		_set_resource_value(
			next_state,
			state_key,
			clampi(changed_value, 0, _resource_cap)
		)

	next_state.actions_remaining -= 1
	preview.is_valid = true
	preview.result = next_state
	return preview


func apply_activity(state: TrainingState, activity_id: StringName) -> TrainingPreview:
	var preview: TrainingPreview = preview_activity(state, activity_id)
	if preview.is_valid:
		state.copy_from(preview.result)
	return preview


func advance_week(state: TrainingState) -> bool:
	if state == null:
		push_error("Não é possível avançar sem um estado de treinamento.")
		return false
	if state.actions_remaining != 0:
		return false
	if state.week >= _total_weeks:
		return false
	state.week += 1
	state.actions_remaining = _actions_per_week
	return true


func _read_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error(
			"Não foi possível abrir %s: %s."
			% [path, error_string(FileAccess.get_open_error())]
		)
		return null

	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error(
			"JSON inválido em %s, linha %d: %s."
			% [path, parser.get_error_line(), parser.get_error_message()]
		)
		return null
	return parser.data


func _has_integer(data: Dictionary, key: String, description: String) -> bool:
	if not data.has(key) or not _is_integer_number(data[key]):
		push_error("O campo '%s' em %s precisa ser um inteiro." % [key, description])
		return false
	return true


func _read_positive_integer(data: Dictionary, key: String, description: String) -> int:
	if not _has_integer(data, key, description):
		return -1
	var value: int = int(data[key])
	if value < 1:
		push_error("O campo '%s' em %s precisa ser maior que zero." % [key, description])
		return -1
	return value


func _is_integer_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return (
		typeof(value) == TYPE_FLOAT
		and is_equal_approx(float(value), roundf(float(value)))
	)


func _validate_activity(activity: Dictionary, activity_id: StringName) -> bool:
	if typeof(activity.get("label")) != TYPE_STRING:
		push_error("A atividade '%s' precisa ter um rótulo textual." % activity_id)
		return false

	var stats_value: Variant = activity.get("stats_delta")
	var resources_value: Variant = activity.get("resource_delta")
	if typeof(stats_value) != TYPE_DICTIONARY:
		push_error("A atividade '%s' precisa ter 'stats_delta'." % activity_id)
		return false
	if typeof(resources_value) != TYPE_DICTIONARY:
		push_error("A atividade '%s' precisa ter 'resource_delta'." % activity_id)
		return false

	var stats_delta: Dictionary = stats_value
	for key: Variant in stats_delta:
		if typeof(key) != TYPE_STRING or not TrainingState.ATTRIBUTE_IDS.has(StringName(key)):
			push_error("A atividade '%s' contém um atributo desconhecido." % activity_id)
			return false
		if not _is_integer_number(stats_delta[key]):
			push_error("O delta '%s' da atividade '%s' precisa ser inteiro." % [key, activity_id])
			return false

	var resource_delta: Dictionary = resources_value
	for key: Variant in resource_delta:
		if typeof(key) != TYPE_STRING or not RESOURCE_KEY_MAP.has(StringName(key)):
			push_error("A atividade '%s' contém um recurso desconhecido." % activity_id)
			return false
		if not _is_integer_number(resource_delta[key]):
			push_error("O delta '%s' da atividade '%s' precisa ser inteiro." % [key, activity_id])
			return false
	return true


func _get_resource_value(state: TrainingState, resource_id: StringName) -> int:
	match resource_id:
		&"energy":
			return state.energy
		&"stress":
			return state.stress
		&"motivation":
			return state.motivation
	push_error("Recurso desconhecido: %s." % resource_id)
	return 0


func _set_resource_value(
	state: TrainingState,
	resource_id: StringName,
	value: int
) -> void:
	match resource_id:
		&"energy":
			state.energy = value
		&"stress":
			state.stress = value
		&"motivation":
			state.motivation = value
		_:
			push_error("Recurso desconhecido: %s." % resource_id)

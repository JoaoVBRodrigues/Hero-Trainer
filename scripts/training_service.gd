class_name TrainingService
extends RefCounted

const CHARACTER_DATA_PATH: String = "res://Hero_Trainer_Kit_v02/data/characters.json"
const ACTIVITIES_DATA_PATH: String = "res://Hero_Trainer_Kit_v02/data/activities.json"
const RESOURCE_KEY_MAP: Dictionary[StringName, StringName] = {
	&"energy": &"energy",
	&"stress": &"stress",
	&"mood": &"motivation",
	&"credits": &"credits",
	&"reputation": &"reputation",
}

var _activities: Dictionary[StringName, Dictionary] = {}
var _activity_labels: Dictionary[StringName, String] = {}
var _activity_ids: Array[StringName] = []
var _initial_state: TrainingState
var _total_weeks: int = 0
var _actions_per_week: int = 0
var _attribute_cap: int = 0
var _resource_cap: int = 0
var _reputation_cap: int = 0
var _bond_cap: int = 0


func get_total_weeks() -> int:
	return _total_weeks


func get_actions_per_week() -> int:
	return _actions_per_week


func get_attribute_cap() -> int:
	return _attribute_cap


func get_resource_cap() -> int:
	return _resource_cap


func get_reputation_cap() -> int:
	return _reputation_cap


func get_bond_cap() -> int:
	return _bond_cap


func get_activity_ids() -> Array[StringName]:
	return _activity_ids.duplicate()


func get_activity_category(activity_id: StringName) -> String:
	if not _activities.has(activity_id):
		push_error("Atividade desconhecida: %s." % activity_id)
		return ""
	return String(_activities[activity_id]["category"])


func get_activity_energy_cost(activity_id: StringName) -> int:
	if not _activities.has(activity_id):
		push_error("Atividade desconhecida: %s." % activity_id)
		return 0
	var resource_delta: Dictionary = _activities[activity_id]["resource_delta"]
	return maxi(0, -int(resource_delta.get("energy", 0)))


func get_bond_ids() -> Array[StringName]:
	if _initial_state == null:
		return []
	var bond_ids: Array[StringName] = []
	for bond_id: StringName in _initial_state.bonds:
		bond_ids.append(bond_id)
	return bond_ids


func load_project_data() -> bool:
	var character_data: Variant = _read_json(CHARACTER_DATA_PATH)
	if character_data == null:
		return false
	var activities_data: Variant = _read_json(ACTIVITIES_DATA_PATH)
	if activities_data == null:
		return false
	return load_data(character_data, activities_data)


func load_data(character_data: Variant, activities_data: Variant) -> bool:
	if typeof(character_data) != TYPE_DICTIONARY:
		push_error("A raiz de characters.json precisa ser um objeto JSON.")
		return false
	if typeof(activities_data) != TYPE_DICTIONARY:
		push_error("A raiz de activities.json precisa ser um objeto JSON.")
		return false

	var character_root: Dictionary = character_data
	if not _validate_allowed_keys(
		character_root,
		["schema_version", "disclaimer", "characters"],
		"characters.json"
	):
		return false
	var characters_value: Variant = character_root.get("characters")
	if typeof(characters_value) != TYPE_ARRAY:
		push_error("characters.json precisa conter a lista 'characters'.")
		return false

	var character: Dictionary
	var character_found: bool = false
	for character_value: Variant in characters_value:
		if typeof(character_value) != TYPE_DICTIONARY:
			push_error("Cada personagem em characters.json precisa ser um objeto.")
			return false
		var candidate: Dictionary = character_value
		if candidate.get("id") == "hori":
			character = candidate
			character_found = true
			break
	if not character_found:
		push_error("A personagem Hori não foi encontrada em characters.json.")
		return false
	if not _validate_allowed_keys(
		character,
		[
			"id", "display_name", "campaign_playable_in_mvp", "role", "arc_theme",
			"stats", "resources", "axes", "aptitudes", "bonds", "canon",
			"route_state", "design_assumptions",
		],
		"personagem Hori"
	):
		return false

	var stats_value: Variant = character.get("stats")
	var resources_value: Variant = character.get("resources")
	var bonds_value: Variant = character.get("bonds")
	if typeof(stats_value) != TYPE_DICTIONARY:
		push_error("Os atributos iniciais de Hori estão ausentes ou inválidos.")
		return false
	if typeof(resources_value) != TYPE_DICTIONARY:
		push_error("Os recursos iniciais de Hori estão ausentes ou inválidos.")
		return false
	if typeof(bonds_value) != TYPE_DICTIONARY:
		push_error("Os vínculos iniciais de Hori estão ausentes ou inválidos.")
		return false

	var stats_data: Dictionary = stats_value
	var resources_data: Dictionary = resources_value
	var bonds_data: Dictionary = bonds_value
	var activities_root: Dictionary = activities_data
	if not _validate_allowed_keys(
		activities_root,
		[
			"schema_version", "calendaring", "stat_cap", "resource_cap",
			"reputation_cap", "bond_cap", "training_failure_formula", "notes",
			"activities",
		],
		"activities.json"
	):
		return false
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
	var reputation_cap: int = _read_positive_integer(
		activities_root,
		"reputation_cap",
		"activities.json"
	)
	var bond_cap: int = _read_positive_integer(
		activities_root,
		"bond_cap",
		"activities.json"
	)
	if attribute_cap < 1 or resource_cap < 1 or reputation_cap < 1 or bond_cap < 1:
		return false
	if not _has_integer(character_root, "schema_version", "characters.json"):
		return false
	if int(character_root["schema_version"]) != 2:
		push_error("Versão de schema não suportada em characters.json.")
		return false
	if not _has_integer(activities_root, "schema_version", "activities.json"):
		return false
	if int(activities_root["schema_version"]) != 1:
		push_error("Versão de schema não suportada em activities.json.")
		return false

	var initial_state := TrainingState.new()
	if not _validate_allowed_keys(
		stats_data,
		["pot", "res", "tec", "teo", "sin"],
		"stats de Hori"
	):
		return false
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		var stat_key: String = String(stat_id)
		if not _has_integer(stats_data, stat_key, "stats de Hori"):
			return false
		var stat_value: int = int(stats_data[stat_key])
		if stat_value < 0 or stat_value > attribute_cap:
			push_error("O atributo '%s' de Hori está fora dos limites." % stat_key)
			return false
		initial_state.stats[stat_id] = stat_value

	if not _validate_allowed_keys(
		resources_data,
		["energy", "stress", "mood", "credits", "reputation", "injury_level"],
		"resources de Hori"
	):
		return false
	for resource_key: StringName in [&"energy", &"stress", &"mood", &"credits", &"reputation"]:
		var key: String = String(resource_key)
		if not _has_integer(resources_data, key, "resources de Hori"):
			return false
	for resource_key: StringName in [&"energy", &"stress", &"mood"]:
		var key: String = String(resource_key)
		var resource_value: int = int(resources_data[key])
		if resource_value < 0 or resource_value > resource_cap:
			push_error("O recurso '%s' de Hori está fora dos limites." % key)
			return false
	initial_state.energy = int(resources_data["energy"])
	initial_state.stress = int(resources_data["stress"])
	initial_state.motivation = int(resources_data["mood"])
	initial_state.credits = int(resources_data["credits"])
	if initial_state.credits < 0:
		push_error("Os créditos iniciais de Hori não podem ser negativos.")
		return false
	initial_state.reputation = int(resources_data["reputation"])
	if initial_state.reputation < 0 or initial_state.reputation > reputation_cap:
		push_error("A reputação inicial de Hori está fora dos limites.")
		return false
	if resources_data.has("injury_level"):
		if not _has_integer(resources_data, "injury_level", "resources de Hori"):
			return false
		if int(resources_data["injury_level"]) < 0 or int(resources_data["injury_level"]) > 2:
			push_error("O nível de lesão inicial de Hori deve estar entre 0 e 2.")
			return false

	for bond_key: Variant in bonds_data:
		if typeof(bond_key) != TYPE_STRING or String(bond_key).is_empty():
			push_error("Cada vínculo de Hori precisa de um identificador textual.")
			return false
		if not _has_integer(bonds_data, String(bond_key), "vínculos de Hori"):
			return false
		var bond_value: int = int(bonds_data[bond_key])
		if bond_value < 0 or bond_value > bond_cap:
			push_error("O vínculo '%s' de Hori está fora dos limites." % bond_key)
			return false
		initial_state.bonds[StringName(bond_key)] = bond_value
	for bond_id: StringName in [&"ray", &"luppi"]:
		if not initial_state.bonds.has(bond_id):
			push_error("O vínculo inicial '%s' de Hori está ausente." % bond_id)
			return false

	var calendaring_value: Variant = activities_root.get("calendaring")
	if typeof(calendaring_value) != TYPE_DICTIONARY:
		push_error("activities.json precisa definir 'calendaring'.")
		return false
	var calendaring: Dictionary = calendaring_value
	if not _validate_allowed_keys(
		calendaring,
		["total_weeks", "action_blocks_per_week"],
		"calendaring"
	):
		return false
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
	var loaded_ids: Array[StringName] = []
	for activity_value: Variant in activities_value:
		if typeof(activity_value) != TYPE_DICTIONARY:
			push_error("Cada atividade precisa ser um objeto JSON.")
			return false
		var activity: Dictionary = activity_value
		if not _validate_activity(activity, initial_state.bonds):
			return false
		var activity_id: StringName = StringName(activity["id"])
		if loaded_activities.has(activity_id):
			push_error(
				"ID de atividade duplicado em activities.json: %s."
				% activity_id
			)
			return false
		loaded_activities[activity_id] = activity
		loaded_labels[activity_id] = String(activity["label"])
		loaded_ids.append(activity_id)
	if loaded_ids.is_empty():
		push_error("activities.json precisa definir ao menos uma atividade.")
		return false

	_activities = loaded_activities
	_activity_labels = loaded_labels
	_activity_ids = loaded_ids
	_initial_state = initial_state
	_total_weeks = total_weeks
	_actions_per_week = actions_per_week
	_attribute_cap = attribute_cap
	_resource_cap = resource_cap
	_reputation_cap = reputation_cap
	_bond_cap = bond_cap
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
	var state_error: String = _validate_state(state)
	if not state_error.is_empty():
		preview.message = state_error
		return preview

	var activity: Dictionary = _activities[activity_id]
	var resource_delta: Dictionary = activity["resource_delta"]
	var energy_cost: int = get_activity_energy_cost(activity_id)
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

	for json_key: String in resource_delta:
		var data_key: StringName = StringName(json_key)
		if not resource_delta.has(json_key):
			continue
		var state_key: StringName = RESOURCE_KEY_MAP[data_key]
		var changed_value: int = _get_resource_value(next_state, state_key)
		changed_value += int(resource_delta[json_key])
		if state_key == &"credits":
			if changed_value < 0:
				preview.message = (
					"Créditos insuficientes para %s: saldo atual %d."
					% [_activity_labels[activity_id], state.credits]
				)
				return preview
			_set_resource_value(next_state, state_key, changed_value)
		elif state_key == &"reputation":
			_set_resource_value(
				next_state,
				state_key,
				clampi(changed_value, 0, _reputation_cap)
			)
		else:
			_set_resource_value(
				next_state,
				state_key,
				clampi(changed_value, 0, _resource_cap)
			)

	var bonds_delta: Dictionary = activity.get("bond_delta", {})
	for bond_key: String in bonds_delta:
		var bond_id: StringName = StringName(bond_key)
		var changed_bond: int = next_state.bonds[bond_id] + int(bonds_delta[bond_key])
		next_state.bonds[bond_id] = clampi(changed_bond, 0, _bond_cap)

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
	var state_error: String = _validate_state(state)
	if not state_error.is_empty():
		push_error(state_error)
		return false
	if state.actions_remaining != 0:
		return false
	if state.week >= _total_weeks:
		return false
	state.week += 1
	state.actions_remaining = _actions_per_week
	return true


func _validate_state(state: TrainingState) -> String:
	if state.week < 1 or state.week > _total_weeks:
		return "A semana atual está fora dos limites configurados."
	if (
		state.actions_remaining < 0
		or state.actions_remaining > _actions_per_week
	):
		return "A quantidade de ações restantes está fora dos limites."
	if state.stats.size() != TrainingState.ATTRIBUTE_IDS.size():
		return "O conjunto de atributos do estado está inválido."
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		if not state.stats.has(stat_id):
			return "O atributo '%s' está ausente no estado." % stat_id
		var stat_value: int = state.stats[stat_id]
		if stat_value < 0 or stat_value > _attribute_cap:
			return "O atributo '%s' está fora dos limites." % stat_id

	for resource_id: StringName in [&"energy", &"stress", &"motivation"]:
		var value: int = _get_resource_value(state, resource_id)
		if value < 0 or value > _resource_cap:
			return "O recurso '%s' está fora dos limites." % resource_id
	if state.credits < 0:
		return "Os créditos não podem ser negativos."
	if state.reputation < 0 or state.reputation > _reputation_cap:
		return "A reputação está fora dos limites."
	if state.bonds.size() != _initial_state.bonds.size():
		return "O conjunto de vínculos do estado está inválido."
	for bond_id: StringName in _initial_state.bonds:
		if not state.bonds.has(bond_id):
			return "O vínculo '%s' está ausente no estado." % bond_id
		var bond_value: int = state.bonds[bond_id]
		if bond_value < 0 or bond_value > _bond_cap:
			return "O vínculo '%s' está fora dos limites." % bond_id
	return ""


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


func _validate_activity(
	activity: Dictionary,
	known_bonds: Dictionary[StringName, int]
) -> bool:
	var activity_id: StringName = StringName(activity.get("id", "<sem-id>"))
	if not _validate_allowed_keys(
		activity,
		[
			"id", "label", "category", "stats_delta", "resource_delta",
			"bond_delta", "can_fail", "mentor_affinity",
		],
		"atividade %s" % activity_id
	):
		return false
	for required_key: String in [
		"id", "label", "category", "stats_delta", "resource_delta",
		"can_fail", "mentor_affinity",
	]:
		if not activity.has(required_key):
			push_error(
				"A atividade '%s' não contém o campo obrigatório '%s'."
				% [activity_id, required_key]
			)
			return false
	if typeof(activity.get("id")) != TYPE_STRING or String(activity["id"]).is_empty():
		push_error("Cada atividade precisa de um ID textual não vazio.")
		return false
	if typeof(activity.get("label")) != TYPE_STRING:
		push_error("A atividade '%s' precisa ter um rótulo textual." % activity_id)
		return false
	if String(activity["label"]).strip_edges().is_empty():
		push_error("A atividade '%s' precisa ter um rótulo não vazio." % activity_id)
		return false
	if typeof(activity.get("category")) != TYPE_STRING:
		push_error("A atividade '%s' precisa definir uma categoria textual." % activity_id)
		return false
	if String(activity["category"]).strip_edges().is_empty():
		push_error("A atividade '%s' precisa definir uma categoria não vazia." % activity_id)
		return false
	if typeof(activity.get("can_fail")) != TYPE_BOOL:
		push_error("O campo can_fail da atividade '%s' precisa ser booleano." % activity_id)
		return false
	if activity["mentor_affinity"] != null and typeof(activity["mentor_affinity"]) != TYPE_STRING:
		push_error("mentor_affinity da atividade '%s' deve ser texto ou null." % activity_id)
		return false

	var stats_value: Variant = activity.get("stats_delta")
	var resources_value: Variant = activity.get("resource_delta")
	var bonds_value: Variant = activity.get("bond_delta", {})
	if typeof(stats_value) != TYPE_DICTIONARY:
		push_error("A atividade '%s' precisa ter 'stats_delta'." % activity_id)
		return false
	if typeof(resources_value) != TYPE_DICTIONARY:
		push_error("A atividade '%s' precisa ter 'resource_delta'." % activity_id)
		return false
	if typeof(bonds_value) != TYPE_DICTIONARY:
		push_error("O campo bond_delta da atividade '%s' deve ser um objeto." % activity_id)
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
	var bonds_delta: Dictionary = bonds_value
	for key: Variant in bonds_delta:
		if typeof(key) != TYPE_STRING or not known_bonds.has(StringName(key)):
			push_error("A atividade '%s' contém um vínculo desconhecido." % activity_id)
			return false
		if not _is_integer_number(bonds_delta[key]):
			push_error("O delta de vínculo '%s' da atividade '%s' precisa ser inteiro." % [key, activity_id])
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
		&"credits":
			return state.credits
		&"reputation":
			return state.reputation
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
		&"credits":
			state.credits = value
		&"reputation":
			state.reputation = value
		_:
			push_error("Recurso desconhecido: %s." % resource_id)


func _validate_allowed_keys(
	data: Dictionary,
	allowed_keys: Array,
	description: String
) -> bool:
	for key: Variant in data:
		if typeof(key) != TYPE_STRING or not allowed_keys.has(key):
			push_error("Chave desconhecida em %s: %s." % [description, key])
			return false
	return true

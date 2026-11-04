class_name TrainingService
extends RefCounted

const CHARACTER_DATA_PATH: String = "res://Hero_Trainer_Kit_v02/data/characters.json"
const ACTIVITIES_DATA_PATH: String = "res://Hero_Trainer_Kit_v02/data/activities.json"
const TRAINING_FAILURE_FORMULA: String = (
	"clamp(0,55,round(max(0,45-energy)*0.7+max(0,stress-20)*0.3)-mentor_bonus)"
)
const RESOURCE_KEY_MAP: Dictionary[StringName, StringName] = {
	&"energy": &"energy",
	&"stress": &"stress",
	&"mood": &"motivation",
	&"credits": &"credits",
	&"reputation": &"reputation",
}
const MAX_FAILURE_CHANCE_PERCENT: int = 55
const MAX_ATTRIBUTE_GAIN_PER_ACTION: int = 12
const MOTIVATION_LOW_MAX: int = 33
const MOTIVATION_NEUTRAL_MAX: int = 66
const MENTOR_BOND_THRESHOLD: int = 30
const MENTOR_RISK_REDUCTION: int = 5
const TRAINING_ITEM_ENERGY_REDUCTION: int = 2
const TRAINING_ITEM_MIN_ENERGY_COST: int = 8
const FOCUS_ITEM_STRESS_REDUCTION: int = 1
const RECOVERY_ITEM_ENERGY_BONUS: int = 5

var _activities: Dictionary[StringName, Dictionary] = {}
var _aptitudes: Dictionary[StringName, float] = {}
var _activity_labels: Dictionary[StringName, String] = {}
var _activity_ids: Array[StringName] = []
var _initial_state: TrainingState
var _total_weeks: int = 0
var _actions_per_week: int = 0
var _attribute_cap: int = 0
var _resource_cap: int = 0
var _reputation_cap: int = 0
var _bond_cap: int = 0
var _default_rng_seed: int


func _init() -> void:
	var seed_generator := RandomNumberGenerator.new()
	seed_generator.randomize()
	_default_rng_seed = seed_generator.seed


func set_random_seed(seed_value: int) -> void:
	_default_rng_seed = seed_value


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


func get_activity_energy_cost(
	activity_id: StringName,
	state: TrainingState = null
) -> int:
	if not _activities.has(activity_id):
		push_error("Atividade desconhecida: %s." % activity_id)
		return 0
	var resource_delta: Dictionary = _activities[activity_id]["resource_delta"]
	var cost: int = maxi(0, -int(resource_delta.get("energy", 0)))
	if (
		state != null
		and _activities[activity_id]["category"] == "training"
		and state.equipped_item_id == &"training_notebook"
	):
		cost = maxi(TRAINING_ITEM_MIN_ENERGY_COST, cost - TRAINING_ITEM_ENERGY_REDUCTION)
	return cost


func get_motivation_multiplier(motivation: int) -> float:
	if motivation <= MOTIVATION_LOW_MAX:
		return 0.90
	if motivation <= MOTIVATION_NEUTRAL_MAX:
		return 1.0
	return 1.10


func get_aptitude_multiplier(activity_id: StringName) -> float:
	return _aptitudes.get(activity_id, 1.0)


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
	var axes_value: Variant = character.get("axes")
	var bonds_value: Variant = character.get("bonds")
	var route_state_value: Variant = character.get("route_state")
	if typeof(stats_value) != TYPE_DICTIONARY:
		push_error("Os atributos iniciais de Hori estão ausentes ou inválidos.")
		return false
	if typeof(resources_value) != TYPE_DICTIONARY:
		push_error("Os recursos iniciais de Hori estão ausentes ou inválidos.")
		return false
	if typeof(axes_value) != TYPE_DICTIONARY:
		push_error("Os eixos iniciais de Hori estão ausentes ou inválidos.")
		return false
	if typeof(bonds_value) != TYPE_DICTIONARY:
		push_error("Os vínculos iniciais de Hori estão ausentes ou inválidos.")
		return false
	if typeof(route_state_value) != TYPE_DICTIONARY:
		push_error("O estado narrativo inicial de Hori está ausente ou inválido.")
		return false

	var stats_data: Dictionary = stats_value
	var resources_data: Dictionary = resources_value
	var axes_data: Dictionary = axes_value
	var bonds_data: Dictionary = bonds_value
	var route_state_data: Dictionary = route_state_value
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
	if typeof(activities_root.get("training_failure_formula")) != TYPE_STRING:
		push_error("activities.json precisa definir training_failure_formula como texto.")
		return false
	if String(activities_root["training_failure_formula"]) != TRAINING_FAILURE_FORMULA:
		push_error("A fórmula de falha declarada em activities.json não é suportada.")
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
		axes_data,
		["autonomy", "solidarity", "ambition", "integrity"],
		"eixos de Hori"
	):
		return false
	for axis_id: StringName in TrainingState.AXIS_IDS:
		var axis_key: String = String(axis_id)
		if not _has_integer(axes_data, axis_key, "eixos de Hori"):
			return false
		var axis_value: int = int(axes_data[axis_key])
		if axis_value < TrainingState.AXIS_MIN or axis_value > TrainingState.AXIS_MAX:
			push_error("O eixo '%s' de Hori está fora dos limites." % axis_key)
			return false
		initial_state.axes[axis_id] = axis_value

	if not _validate_allowed_keys(
		route_state_data,
		[
			"core_stability", "echo_pressure", "trusted_network",
			"identification_aids", "identification_aids_progress",
			"honesty_to_friends",
		],
		"route_state de Hori"
	):
		return false
	for route_key: StringName in TrainingState.ROUTE_STATE_LIMITS:
		var key: String = String(route_key)
		if route_state_data.has(key):
			if not _has_integer(route_state_data, key, "route_state de Hori"):
				return false
			var bounds: Vector2i = TrainingState.ROUTE_STATE_LIMITS[route_key]
			var route_value: int = int(route_state_data[key])
			if route_value < bounds.x or route_value > bounds.y:
				push_error("O campo '%s' de route_state está fora dos limites." % key)
				return false
			initial_state.route_state[route_key] = route_value
		elif route_key != &"identification_aids_progress":
			push_error("O campo '%s' está ausente em route_state de Hori." % key)
			return false
	for route_key: StringName in TrainingState.ROUTE_STATE_BOOLEAN_IDS:
		var key: String = String(route_key)
		if not route_state_data.has(key) or typeof(route_state_data[key]) != TYPE_BOOL:
			push_error("O campo '%s' em route_state de Hori precisa ser booleano." % key)
			return false
		initial_state.route_state[route_key] = route_state_data[key]

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
	var aptitudes_value: Variant = character.get("aptitudes")
	if typeof(aptitudes_value) != TYPE_DICTIONARY:
		push_error("As aptidões de Hori precisam ser um objeto.")
		return false
	var aptitudes_data: Dictionary = aptitudes_value
	var loaded_aptitudes: Dictionary[StringName, float] = {}
	for aptitude_key: Variant in aptitudes_data:
		if typeof(aptitude_key) != TYPE_STRING:
			push_error("Cada aptidão de Hori precisa usar um ID textual.")
			return false
		var aptitude_id := StringName(aptitude_key)
		if (
			not loaded_activities.has(aptitude_id)
			or loaded_activities[aptitude_id]["category"] != "training"
		):
			push_error("Aptidão de Hori referencia uma atividade de treino desconhecida: %s." % aptitude_id)
			return false
		var aptitude_value: Variant = aptitudes_data[aptitude_key]
		if typeof(aptitude_value) not in [TYPE_INT, TYPE_FLOAT]:
			push_error("A aptidão '%s' precisa ser numérica." % aptitude_id)
			return false
		var aptitude: float = float(aptitude_value)
		if aptitude < 0.85 or aptitude > 1.15:
			push_error("A aptidão '%s' de Hori está fora do intervalo 0,85–1,15." % aptitude_id)
			return false
		loaded_aptitudes[aptitude_id] = aptitude
	for activity_id: StringName in loaded_ids:
		var activity: Dictionary = loaded_activities[activity_id]
		if activity["category"] != "training":
			continue
		var activity_maximum_gain: int = 0
		var stats_delta: Dictionary = activity["stats_delta"]
		for stat_key: String in stats_delta:
			var base_gain: int = int(stats_delta[stat_key])
			if base_gain <= 0:
				push_error("Treino '%s' deve conceder apenas ganhos positivos de atributo." % activity_id)
				return false
			var worst_case_gain: int = roundi(base_gain * 1.15 * 1.10)
			activity_maximum_gain += worst_case_gain
		if activity_maximum_gain > MAX_ATTRIBUTE_GAIN_PER_ACTION:
			push_error("Treino '%s' excede o limite de ganho de atributo por ação." % activity_id)
			return false
		if not loaded_aptitudes.has(activity_id):
			loaded_aptitudes[activity_id] = 1.0

	_activities = loaded_activities
	_aptitudes = loaded_aptitudes
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
	for mission_flag: StringName in TrainingState.MISSION_FLAG_IDS:
		initial_state.flags[mission_flag] = false
	return true


func create_initial_state() -> TrainingState:
	if _initial_state == null:
		push_error("Carregue os dados do projeto antes de criar o estado de treino.")
		return null
	var state: TrainingState = _initial_state.duplicate_state()
	var rng := RandomNumberGenerator.new()
	rng.seed = _default_rng_seed
	state.rng_seed = _default_rng_seed
	state.rng_state = rng.state
	return state


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
	preview.activity_id = activity_id
	preview.can_fail = bool(activity["can_fail"])
	preview.equipment_id = state.equipped_item_id
	preview.energy_cost = get_activity_energy_cost(activity_id, state)
	preview.stress_delta = int(activity["resource_delta"].get("stress", 0))
	if (
		activity["category"] == "training"
		and state.equipped_item_id == &"focus_aid"
	):
		preview.stress_delta = maxi(
			0,
			preview.stress_delta - FOCUS_ITEM_STRESS_REDUCTION
		)
	if activity["category"] == "training":
		preview.aptitude_multiplier = get_aptitude_multiplier(activity_id)
		preview.motivation_multiplier = get_motivation_multiplier(state.motivation)
		preview.mentor_available = (
			int(state.bonds.get(&"instructor", 0)) >= MENTOR_BOND_THRESHOLD
			and activity["mentor_affinity"] != null
			and not String(activity["mentor_affinity"]).is_empty()
		)
		var stats_delta: Dictionary = activity["stats_delta"]
		for stat_key: String in stats_delta:
			var stat_id := StringName(stat_key)
			var calculated_gain: int = roundi(
				int(stats_delta[stat_key])
				* preview.aptitude_multiplier
				* preview.motivation_multiplier
			)
			var effective_gain: int = mini(
				calculated_gain,
				_attribute_cap - int(state.stats[stat_id])
			)
			preview.calculated_attribute_gains[stat_id] = calculated_gain
			preview.attribute_gains[stat_id] = maxi(0, effective_gain)
	if preview.can_fail:
		preview.base_failure_chance_percent = _calculate_failure_chance(
			state.energy,
			state.stress,
			0
		)
		preview.failure_chance_percent = _calculate_failure_chance(
			state.energy,
			state.stress,
			MENTOR_RISK_REDUCTION if preview.mentor_available else 0
		)
		preview.success_chance_percent = (
			100 - preview.failure_chance_percent
		)
	var energy_cost: int = preview.energy_cost
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

	preview.success_result = _build_activity_result(state, activity, true, preview)
	if preview.success_result == null:
		return preview
	if preview.can_fail:
		preview.failure_result = _build_activity_result(
			state,
			activity,
			false,
			preview
		)
		if preview.failure_result == null:
			return preview
	else:
		preview.failure_result = preview.success_result.duplicate_state()
		preview.result = preview.success_result.duplicate_state()
		preview.outcome = TrainingPreview.OUTCOME_DETERMINISTIC

	preview.is_valid = true
	return preview


func _build_activity_result(
	state: TrainingState,
	activity: Dictionary,
	apply_attribute_gains: bool,
	preview: TrainingPreview
) -> TrainingState:
	var next_state: TrainingState = state.duplicate_state()
	if apply_attribute_gains:
		for stat_id: StringName in preview.attribute_gains:
			next_state.stats[stat_id] = clampi(
				next_state.stats[stat_id] + preview.attribute_gains[stat_id],
				0,
				_attribute_cap
			)

	var resource_delta: Dictionary = activity["resource_delta"]
	for json_key: String in resource_delta:
		var data_key: StringName = StringName(json_key)
		var state_key: StringName = RESOURCE_KEY_MAP[data_key]
		var changed_value: int = _get_resource_value(next_state, state_key)
		var effective_delta: int = int(resource_delta[json_key])
		if activity["category"] == "training" and data_key == &"energy":
			effective_delta = -preview.energy_cost
		elif activity["category"] == "training" and data_key == &"stress":
			effective_delta = preview.stress_delta
		elif (
			preview.activity_id == &"rest"
			and data_key == &"energy"
			and state.equipped_item_id == &"recovery_kit"
		):
			effective_delta += RECOVERY_ITEM_ENERGY_BONUS
		changed_value += effective_delta
		if state_key == &"credits":
			if changed_value < 0:
				preview.message = (
					"Créditos insuficientes para %s: saldo atual %d."
					% [_activity_labels[preview.activity_id], state.credits]
				)
				return null
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
	return next_state


func _calculate_failure_chance(
	energy: int,
	stress: int,
	mentor_bonus: int = 0
) -> int:
	var raw_chance: float = (
		maxf(0.0, 45.0 - float(energy)) * 0.7
		+ maxf(0.0, float(stress) - 20.0) * 0.3
	)
	return clampi(
		roundi(raw_chance) - mentor_bonus,
		0,
		MAX_FAILURE_CHANCE_PERCENT
	)


func apply_activity(state: TrainingState, activity_id: StringName) -> TrainingPreview:
	var preview: TrainingPreview = preview_activity(state, activity_id)
	if not preview.is_valid:
		return preview

	var applied_state: TrainingState
	if preview.can_fail and preview.failure_chance_percent > 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = state.rng_seed
		rng.state = state.rng_state
		preview.random_roll = rng.randf()
		preview.was_applied = true
		if preview.random_roll < float(preview.failure_chance_percent) / 100.0:
			preview.outcome = TrainingPreview.OUTCOME_FAILURE
			applied_state = preview.failure_result
			preview.message = "Treinamento falhou. Os custos foram aplicados."
		else:
			preview.outcome = TrainingPreview.OUTCOME_SUCCESS
			applied_state = preview.success_result
			preview.message = "Treinamento concluído com sucesso."
		applied_state.rng_state = rng.state
	else:
		preview.was_applied = true
		preview.outcome = (
			TrainingPreview.OUTCOME_SUCCESS
			if preview.can_fail
			else TrainingPreview.OUTCOME_DETERMINISTIC
		)
		applied_state = preview.success_result
		preview.message = "Atividade concluída."

	preview.result = applied_state.duplicate_state()
	state.copy_from(applied_state)
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
	if state.rng_state == 0:
		return "O estado do gerador aleatório está inválido."
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
	if state.axes.size() != TrainingState.AXIS_IDS.size():
		return "O conjunto de eixos do estado está inválido."
	for axis_id: StringName in TrainingState.AXIS_IDS:
		if not state.axes.has(axis_id):
			return "O eixo '%s' está ausente no estado." % axis_id
		var axis_value: int = state.axes[axis_id]
		if axis_value < TrainingState.AXIS_MIN or axis_value > TrainingState.AXIS_MAX:
			return "O eixo '%s' está fora dos limites." % axis_id
	if state.route_state.size() != TrainingState.ROUTE_STATE_LIMITS.size() + 1:
		return "O conjunto route_state do estado está inválido."
	for route_id: StringName in TrainingState.ROUTE_STATE_LIMITS:
		if not state.route_state.has(route_id):
			return "O campo '%s' está ausente em route_state." % route_id
		var route_value: Variant = state.route_state[route_id]
		if typeof(route_value) != TYPE_INT:
			return "O campo '%s' de route_state precisa ser inteiro." % route_id
		var bounds: Vector2i = TrainingState.ROUTE_STATE_LIMITS[route_id]
		if int(route_value) < bounds.x or int(route_value) > bounds.y:
			return "O campo '%s' de route_state está fora dos limites." % route_id
	for route_id: StringName in TrainingState.ROUTE_STATE_BOOLEAN_IDS:
		if (
			not state.route_state.has(route_id)
			or typeof(state.route_state[route_id]) != TYPE_BOOL
		):
			return "O campo '%s' de route_state precisa ser booleano." % route_id
	return ""


func validate_state(state: TrainingState) -> String:
	return _validate_state(state)


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

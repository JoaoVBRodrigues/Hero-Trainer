class_name NarrativeService
extends RefCounted

const EVENTS_DATA_PATH: String = (
	"res://Hero_Trainer_Kit_v02/Hori Draft/events_hori_draft.json"
)
const MISSION_DATA_PATH: String = (
	"res://Hero_Trainer_Kit_v02/Hori Draft/missions_hori_draft.json"
)
const ENDINGS_DATA_PATH: String = (
	"res://Hero_Trainer_Kit_v02/Hori Draft/endings_hori_draft.json"
)
const PULSE_MIN_CORE_STABILITY: int = 55
const PULSE_MIN_TECHNIQUE: int = 30
const EVENT_ROOT_KEYS: Array[String] = ["schema_version", "notes", "events"]
const MISSION_ROOT_KEYS: Array[String] = ["schema_version", "notes", "missions"]
const ENDING_ROOT_KEYS: Array[String] = ["schema_version", "notes", "endings"]
const AXIS_IDS: Array[StringName] = [
	&"autonomy", &"solidarity", &"ambition", &"integrity",
]
const RESOURCE_IDS: Array[StringName] = [
	&"energy", &"stress", &"mood", &"credits", &"reputation",
]
const BOND_IDS: Array[StringName] = [
	&"hori", &"ray", &"luppi", &"instructor",
]
const ROUTE_STATE_DELTA_IDS: Array[StringName] = [
	&"core_stability", &"echo_pressure", &"trusted_network",
	&"identification_aids_progress", &"honesty_to_friends",
]
const EFFECT_KEYS: Array[String] = [
	"stats_delta", "axes_delta", "route_state_delta",
	"route_state_delta_team", "route_state_set", "route_state_set_if",
	"resources_delta", "bonds_delta", "flags_set",
]
const CONDITION_OPERATORS: Array[String] = [
	"==", "!=", ">=", "<=", ">", "<",
]

var _events: Array[Dictionary] = []
var _event_by_id: Dictionary[StringName, Dictionary] = {}
var _mission: Dictionary = {}
var _endings: Array[Dictionary] = []
var _ending_by_id: Dictionary[StringName, Dictionary] = {}
var _attribute_cap: int = 100
var _resource_cap: int = 100
var _reputation_cap: int = 100
var _bond_cap: int = 100


func set_limits(
	attribute_cap: int,
	resource_cap: int,
	reputation_cap: int,
	bond_cap: int
) -> void:
	_attribute_cap = attribute_cap
	_resource_cap = resource_cap
	_reputation_cap = reputation_cap
	_bond_cap = bond_cap


func load_project_data() -> bool:
	var events_data: Variant = _read_json(EVENTS_DATA_PATH)
	if events_data == null:
		return false
	var mission_data: Variant = _read_json(MISSION_DATA_PATH)
	if mission_data == null:
		return false
	var endings_data: Variant = _read_json(ENDINGS_DATA_PATH)
	if endings_data == null:
		return false
	return load_data(events_data, mission_data, endings_data)


func load_data(
	events_data: Variant,
	mission_data: Variant,
	endings_data: Variant
) -> bool:
	if not _validate_root(events_data, EVENT_ROOT_KEYS, "events_hori_draft.json"):
		return false
	if not _validate_root(mission_data, MISSION_ROOT_KEYS, "missions_hori_draft.json"):
		return false
	if not _validate_root(endings_data, ENDING_ROOT_KEYS, "endings_hori_draft.json"):
		return false
	if (
		int(events_data["schema_version"]) != 3
		or int(mission_data["schema_version"]) != 1
		or int(endings_data["schema_version"]) != 3
	):
		push_error("A versão do schema narrativo não é suportada.")
		return false

	var event_values: Array = events_data["events"]
	if event_values.size() != 8:
		push_error("A rota de Hori precisa conter exatamente oito eventos.")
		return false
	var loaded_events: Array[Dictionary] = []
	var loaded_event_by_id: Dictionary[StringName, Dictionary] = {}
	for index: int in range(event_values.size()):
		if typeof(event_values[index]) != TYPE_DICTIONARY:
			push_error("Cada evento da rota de Hori precisa ser um objeto.")
			return false
		var event: Dictionary = event_values[index]
		if not _validate_event(event, index):
			return false
		var event_id := StringName(event["id"])
		if loaded_event_by_id.has(event_id):
			push_error("ID de evento duplicado: %s." % event_id)
			return false
		loaded_events.append(event)
		loaded_event_by_id[event_id] = event

	var mission_values: Array = mission_data["missions"]
	if mission_values.size() != 1 or typeof(mission_values[0]) != TYPE_DICTIONARY:
		push_error("A rota de Hori precisa definir uma missão jogável.")
		return false
	var loaded_mission: Dictionary = mission_values[0]
	if not _validate_mission(loaded_mission):
		return false

	var ending_values: Array = endings_data["endings"]
	if ending_values.size() != 4:
		push_error("A rota de Hori precisa definir exatamente quatro finais.")
		return false
	var loaded_endings: Array[Dictionary] = []
	var loaded_ending_by_id: Dictionary[StringName, Dictionary] = {}
	for ending_value: Variant in ending_values:
		if typeof(ending_value) != TYPE_DICTIONARY:
			push_error("Cada final da rota de Hori precisa ser um objeto.")
			return false
		var ending: Dictionary = ending_value
		if not _validate_ending(ending):
			return false
		var ending_id := StringName(ending["id"])
		if loaded_ending_by_id.has(ending_id):
			push_error("ID de final duplicado: %s." % ending_id)
			return false
		loaded_endings.append(ending)
		loaded_ending_by_id[ending_id] = ending

	_events = loaded_events
	_event_by_id = loaded_event_by_id
	_mission = loaded_mission
	_endings = loaded_endings
	_ending_by_id = loaded_ending_by_id
	return true


func get_event_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for event: Dictionary in _events:
		result.append(StringName(event["id"]))
	return result


func get_ending_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for ending: Dictionary in _endings:
		result.append(StringName(ending["id"]))
	return result


func get_next_event(state: TrainingState) -> Dictionary:
	if state == null:
		return {}
	var selected: Dictionary = {}
	var selected_priority: int = -2147483648
	for event: Dictionary in _events:
		var window: Dictionary = event["window"]
		if state.week < int(window["week_min"]) or state.week > int(window["week_max"]):
			continue
		if not _condition_matches(state, event["trigger"]):
			continue
		var priority: int = int(event["priority"])
		if selected.is_empty() or priority > selected_priority:
			selected = event
			selected_priority = priority
	return selected.duplicate(true)


func get_event(event_id: StringName) -> Dictionary:
	if not _event_by_id.has(event_id):
		return {}
	return _event_by_id[event_id].duplicate(true)


func apply_event_choice(
	state: TrainingState,
	event_id: StringName,
	choice_id: StringName
) -> NarrativeResult:
	var result := NarrativeResult.new()
	result.event_id = event_id
	result.choice_id = choice_id
	if not _is_state_valid(state, result):
		return result
	var event: Dictionary = _event_by_id.get(event_id, {})
	if event.is_empty():
		result.message = "O evento solicitado não está disponível."
		return result
	if get_next_event(state).get("id") != String(event_id):
		result.message = "Este evento não está ativo nesta semana."
		return result
	var choice: Dictionary = _find_choice(event["choices"], choice_id)
	if choice.is_empty():
		result.message = "A escolha solicitada não pertence a este evento."
		return result

	var next_state: TrainingState = state.duplicate_state()
	if not _apply_effects(next_state, choice["effects"], result):
		return result
	state.copy_from(next_state)
	result.is_valid = true
	result.message = "Escolha narrativa aplicada sem consumir uma ação de treino."
	return result


func is_mission_due(state: TrainingState) -> bool:
	if state == null or _mission.is_empty() or state.mission_stage >= 3:
		return false
	if bool(state.flags.get(&"final_mission_resolved", false)):
		return false
	var window: Dictionary = _mission["window"]
	return (
		state.week >= int(window["week_min"])
		and state.week <= int(window["week_max"])
	)


func expire_mission_by_deadline(state: TrainingState) -> bool:
	if (
		state == null
		or _mission.is_empty()
		or state.actions_remaining != 0
		or state.mission_stage >= 3
		or bool(state.flags.get(&"final_mission_resolved", false))
	):
		return false
	var window: Dictionary = _mission["window"]
	if state.week != int(window["week_max"]):
		return false
	state.flags[&"final_mission_success"] = false
	state.flags[&"final_mission_failed_by_deadline"] = true
	state.flags[&"final_mission_resolved"] = true
	return true


func pulse_requirement_message(state: TrainingState) -> String:
	var stability: int = int(state.route_state.get(&"core_stability", 0))
	var technique: int = int(state.stats.get(&"tec", 0))
	return (
		"Pulso de Contenção — estabilidade %d/%d; Técnica %d/%d."
		% [
			stability,
			PULSE_MIN_CORE_STABILITY,
			technique,
			PULSE_MIN_TECHNIQUE,
		]
	)


func get_current_mission_stage(state: TrainingState) -> Dictionary:
	if not is_mission_due(state):
		return {}
	var stages: Array = _mission["stages"]
	if state.mission_stage < 0 or state.mission_stage >= stages.size():
		return {}
	return stages[state.mission_stage].duplicate(true)


func get_mission_choice_ids(state: TrainingState) -> Array[StringName]:
	var stage: Dictionary = get_current_mission_stage(state)
	if stage.is_empty():
		return []
	var result: Array[StringName] = []
	for choice: Dictionary in stage["choices"]:
		if _is_mission_choice_available(state, choice):
			result.append(StringName(choice["id"]))
	return result


func get_mission_title() -> String:
	return String(_mission.get("title", ""))


func get_mission_context() -> String:
	return String(_mission.get("context", ""))


func get_mission_choice(stage: Dictionary, choice_id: StringName) -> Dictionary:
	if stage.is_empty():
		return {}
	return _find_choice(stage.get("choices", []), choice_id).duplicate(true)


func preview_mission_choice(
	state: TrainingState,
	choice_id: StringName
) -> NarrativeResult:
	var result := NarrativeResult.new()
	result.choice_id = choice_id
	if not _is_state_valid(state, result):
		return result
	var stage: Dictionary = get_current_mission_stage(state)
	if stage.is_empty():
		result.message = "Não há uma etapa de missão ativa."
		return result
	var choice: Dictionary = _find_choice(stage["choices"], choice_id)
	if choice.is_empty() or not _is_mission_choice_available(state, choice):
		result.message = "Esta opção de missão não está disponível."
		return result
	result.stage_number = int(stage["stage"])
	result.outcome = _mission_choice_outcome(state, choice)
	result.message = _mission_outcome_message(choice, result.outcome)
	result.is_valid = true
	return result


func apply_mission_choice(
	state: TrainingState,
	choice_id: StringName
) -> NarrativeResult:
	var result: NarrativeResult = preview_mission_choice(state, choice_id)
	if not result.is_valid:
		return result
	var stage: Dictionary = get_current_mission_stage(state)
	var choice: Dictionary = _find_choice(stage["choices"], choice_id)
	var effects_key: String = (
		"effects_success"
		if result.outcome == &"success"
		else "effects_failure_recoverable"
	)
	var next_state: TrainingState = state.duplicate_state()
	if not _apply_effects(next_state, choice[effects_key], result):
		result.is_valid = false
		return result
	next_state.flags[&"final_mission_attempted"] = true
	next_state.mission_stage += 1
	if next_state.mission_stage >= 3:
		next_state.flags[&"final_mission_completed"] = true
		next_state.flags[&"final_mission_success"] = (
			result.outcome == &"success"
		)
		next_state.flags[&"final_mission_failed_by_deadline"] = false
		next_state.flags[&"final_mission_resolved"] = true
	state.copy_from(next_state)
	result.message = _mission_outcome_message(choice, result.outcome)
	result.message += " Etapa %d de 3 concluída." % result.stage_number
	return result


func resolve_ending(state: TrainingState) -> Dictionary:
	if state == null or not bool(state.flags.get(&"final_mission_resolved", false)):
		return {}
	var selected: Dictionary = {}
	var selected_priority: int = -2147483648
	for ending: Dictionary in _endings:
		if not _condition_matches(state, ending["conditions"]):
			continue
		var priority: int = int(ending["priority"])
		if selected.is_empty() or priority > selected_priority:
			selected = ending
			selected_priority = priority
	return selected.duplicate(true)


func validate_campaign_state(state: TrainingState) -> String:
	var result := NarrativeResult.new()
	if not _is_state_valid(state, result):
		return result.message
	return ""


func get_ending(ending_id: StringName) -> Dictionary:
	if not _ending_by_id.has(ending_id):
		return {}
	return _ending_by_id[ending_id].duplicate(true)


func describe_mission_choice(state: TrainingState, choice_id: StringName) -> String:
	var preview: NarrativeResult = preview_mission_choice(state, choice_id)
	if not preview.is_valid:
		return preview.message
	return preview.message


func _mission_choice_outcome(
	state: TrainingState,
	choice: Dictionary
) -> StringName:
	if StringName(choice["id"]) == &"containment_pulse":
		var stability: int = int(state.route_state.get(&"core_stability", 0))
		var technique: int = int(state.stats.get(&"tec", 0))
		if (
			stability >= PULSE_MIN_CORE_STABILITY
			and technique >= PULSE_MIN_TECHNIQUE
		):
			return &"success"
		return &"failure_recoverable"
	if _condition_matches(state, choice["requirement"]):
		return &"success"
	return &"failure_recoverable"


func _mission_outcome_message(
	choice: Dictionary,
	outcome: StringName
) -> String:
	if StringName(choice["id"]) == &"containment_pulse":
		return (
			"Pulso: core_stability ≥ %d e tec ≥ %d — resultado: %s."
			% [
				PULSE_MIN_CORE_STABILITY,
				PULSE_MIN_TECHNIQUE,
				"sucesso" if outcome == &"success" else "falha recuperável",
			]
		)
	var requirement: Dictionary = choice["requirement"]
	var status: String = (
		"sucesso"
		if outcome == &"success"
		else "falha recuperável"
	)
	return (
		"Teste determinístico: %s — %s. %s"
		% [
			_format_condition(requirement),
			status,
			String(choice["expected_result"]),
		]
	)


func _is_mission_choice_available(
	state: TrainingState,
	choice: Dictionary
) -> bool:
	if StringName(choice["id"]) != &"containment_pulse":
		return true
	return _special_ability_unlocked(state)


func _special_ability_unlocked(state: TrainingState) -> bool:
	if _mission.is_empty():
		return false
	var special_ability: Dictionary = _mission["special_ability"]
	return _condition_matches(state, special_ability["unlock_condition"])


func _apply_effects(
	state: TrainingState,
	effects: Dictionary,
	result: NarrativeResult
) -> bool:
	for key: String in effects:
		match key:
			"stats_delta":
				for id: String in effects[key]:
					var stat_id := StringName(id)
					state.stats[stat_id] = clampi(
						state.stats[stat_id] + int(effects[key][id]),
						0,
						_attribute_cap
					)
			"axes_delta":
				for id: String in effects[key]:
					var axis_id := StringName(id)
					state.axes[axis_id] = clampi(
						state.axes[axis_id] + int(effects[key][id]),
						TrainingState.AXIS_MIN,
						TrainingState.AXIS_MAX
					)
			"route_state_delta", "route_state_delta_team":
				if not _apply_route_state_delta(state, effects[key], result):
					return false
			"route_state_set":
				for id: String in effects[key]:
					state.route_state[StringName(id)] = effects[key][id]
			"route_state_set_if":
				if _route_state_set_condition_is_met(state, effects[key]):
					var field_id := StringName(effects[key]["field"])
					state.route_state[field_id] = effects[key]["value"]
			"resources_delta":
				if not _apply_resource_delta(state, effects[key], result):
					return false
			"bonds_delta":
				for id: String in effects[key]:
					var bond_id := StringName(id)
					state.bonds[bond_id] = clampi(
						state.bonds[bond_id] + int(effects[key][id]),
						0,
						_bond_cap
					)
			"flags_set":
				for id: String in effects[key]:
					state.flags[StringName(id)] = bool(effects[key][id])
			_:
				result.message = "Efeito narrativo desconhecido: %s." % key
				return false
	return true


func _apply_route_state_delta(
	state: TrainingState,
	deltas: Dictionary,
	result: NarrativeResult
) -> bool:
	for id: String in deltas:
		var route_id := StringName(id)
		if TrainingState.ROUTE_STATE_BOOLEAN_IDS.has(route_id):
			result.message = "Não é permitido somar um delta ao campo booleano '%s'." % id
			return false
		var bounds: Vector2i = TrainingState.ROUTE_STATE_LIMITS[route_id]
		var current: int = int(state.route_state.get(route_id, 0))
		state.route_state[route_id] = clampi(
			current + int(deltas[id]),
			bounds.x,
			bounds.y
		)
	return true


func _apply_resource_delta(
	state: TrainingState,
	deltas: Dictionary,
	result: NarrativeResult
) -> bool:
	for id: String in deltas:
		var resource_id := StringName(id)
		var current: int
		match resource_id:
			&"energy":
				current = state.energy
			&"stress":
				current = state.stress
			&"mood":
				current = state.motivation
			&"credits":
				current = state.credits
			&"reputation":
				current = state.reputation
			_:
				result.message = "Recurso narrativo desconhecido: %s." % id
				return false
		var changed: int = current + int(deltas[id])
		match resource_id:
			&"credits":
				if changed < 0:
					result.message = "Créditos insuficientes para aplicar a escolha narrativa."
					return false
				state.credits = changed
			&"reputation":
				state.reputation = clampi(changed, 0, _reputation_cap)
			&"energy":
				state.energy = clampi(changed, 0, _resource_cap)
			&"stress":
				state.stress = clampi(changed, 0, _resource_cap)
			&"mood":
				state.motivation = clampi(changed, 0, _resource_cap)
	return true


func _route_state_set_condition_is_met(
	state: TrainingState,
	set_if: Dictionary
) -> bool:
	return bool(state.flags.get(StringName(set_if["condition_flag"]), false))


func _condition_matches(state: TrainingState, condition: Dictionary) -> bool:
	if condition.has("all"):
		for child: Dictionary in condition["all"]:
			if not _condition_matches(state, child):
				return false
		return true
	if condition.has("any"):
		for child: Dictionary in condition["any"]:
			if _condition_matches(state, child):
				return true
		return false

	var actual: Variant = _get_path_value(state, String(condition["path"]))
	var expected: Variant = condition["value"]
	var operator: String = String(condition["op"])
	if operator == "==" or operator == "!=":
		var equal: bool = actual == expected
		return equal if operator == "==" else not equal
	if not _is_numeric(actual) or not _is_numeric(expected):
		return false
	var actual_number: float = float(actual)
	var expected_number: float = float(expected)
	match operator:
		">=":
			return actual_number >= expected_number
		"<=":
			return actual_number <= expected_number
		">":
			return actual_number > expected_number
		"<":
			return actual_number < expected_number
	return false


func _get_path_value(state: TrainingState, path: String) -> Variant:
	var segments: PackedStringArray = path.split(".")
	if segments.size() == 1 and segments[0] == "week":
		return state.week
	if segments.size() != 2:
		return null
	var group: String = segments[0]
	var id := StringName(segments[1])
	match group:
		"week":
			if id == &"current":
				return state.week
			return null
		"stats":
			return state.stats.get(id)
		"resources":
			match id:
				&"energy":
					return state.energy
				&"stress":
					return state.stress
				&"mood":
					return state.motivation
				&"credits":
					return state.credits
				&"reputation":
					return state.reputation
		"axes":
			return state.axes.get(id)
		"bonds":
			return state.bonds.get(id)
		"route_state":
			return state.route_state.get(id)
		"flags":
			if id == &"hori_containment_pulse_unlocked":
				return _special_ability_unlocked(state)
			return state.flags.get(id, false)
	return null


func _find_choice(choices: Array, choice_id: StringName) -> Dictionary:
	for choice_value: Variant in choices:
		var choice: Dictionary = choice_value
		if StringName(choice["id"]) == choice_id:
			return choice
	return {}


func _format_condition(condition: Dictionary) -> String:
	if condition.has("all"):
		var parts := PackedStringArray()
		for child: Dictionary in condition["all"]:
			parts.append(_format_condition(child))
		return " e ".join(parts)
	if condition.has("any"):
		var parts := PackedStringArray()
		for child: Dictionary in condition["any"]:
			parts.append(_format_condition(child))
		return " ou ".join(parts)
	return "%s %s %s" % [
		String(condition["path"]),
		String(condition["op"]),
		str(condition["value"]),
	]


func _is_state_valid(state: TrainingState, result: NarrativeResult) -> bool:
	if state == null:
		result.message = "O estado da campanha não está disponível."
		return false
	if state.axes.size() != TrainingState.AXIS_IDS.size():
		result.message = "O conjunto de eixos da campanha está inválido."
		return false
	for axis_id: StringName in TrainingState.AXIS_IDS:
		if not state.axes.has(axis_id):
			result.message = "O eixo '%s' está ausente." % axis_id
			return false
		var axis_value: int = state.axes[axis_id]
		if axis_value < TrainingState.AXIS_MIN or axis_value > TrainingState.AXIS_MAX:
			result.message = "O eixo '%s' está fora dos limites." % axis_id
			return false
	for route_id: StringName in TrainingState.ROUTE_STATE_LIMITS:
		if not state.route_state.has(route_id):
			result.message = "O campo '%s' de route_state está ausente." % route_id
			return false
		var route_value: Variant = state.route_state[route_id]
		if typeof(route_value) != TYPE_INT:
			result.message = "O campo '%s' de route_state precisa ser inteiro." % route_id
			return false
		var bounds: Vector2i = TrainingState.ROUTE_STATE_LIMITS[route_id]
		if int(route_value) < bounds.x or int(route_value) > bounds.y:
			result.message = "O campo '%s' de route_state está fora dos limites." % route_id
			return false
	for route_id: StringName in TrainingState.ROUTE_STATE_BOOLEAN_IDS:
		if (
			not state.route_state.has(route_id)
			or typeof(state.route_state[route_id]) != TYPE_BOOL
		):
			result.message = "O campo '%s' de route_state precisa ser booleano." % route_id
			return false
	for flag_id: StringName in state.flags:
		if typeof(state.flags[flag_id]) != TYPE_BOOL:
			result.message = "A flag '%s' precisa ser booleana." % flag_id
			return false
	if state.mission_stage < 0 or state.mission_stage > 3:
		result.message = "A etapa de missão está fora dos limites."
		return false
	var mission_error: String = _mission_state_error(state)
	if not mission_error.is_empty():
		result.message = mission_error
		return false
	if state.stats.size() != TrainingState.ATTRIBUTE_IDS.size():
		result.message = "O conjunto de atributos da campanha está inválido."
		return false
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		if not state.stats.has(stat_id):
			result.message = "O atributo '%s' está ausente." % stat_id
			return false
		var stat_value: int = state.stats[stat_id]
		if stat_value < 0 or stat_value > _attribute_cap:
			result.message = "O atributo '%s' está fora dos limites." % stat_id
			return false
	for bond_id: StringName in state.bonds:
		if bond_id not in BOND_IDS:
			result.message = "Vínculo desconhecido na campanha: %s." % bond_id
			return false
		var bond_value: int = state.bonds[bond_id]
		if bond_value < 0 or bond_value > _bond_cap:
			result.message = "O vínculo '%s' está fora dos limites." % bond_id
			return false
	if state.energy < 0 or state.energy > _resource_cap:
		result.message = "A energia da campanha está fora dos limites."
		return false
	if state.stress < 0 or state.stress > _resource_cap:
		result.message = "O estresse da campanha está fora dos limites."
		return false
	if state.motivation < 0 or state.motivation > _resource_cap:
		result.message = "A motivação da campanha está fora dos limites."
		return false
	if state.credits < 0:
		result.message = "Os créditos da campanha não podem ser negativos."
		return false
	if state.reputation < 0 or state.reputation > _reputation_cap:
		result.message = "A reputação da campanha está fora dos limites."
		return false
	return true


func _mission_state_error(state: TrainingState) -> String:
	for flag_id: StringName in TrainingState.MISSION_FLAG_IDS:
		if typeof(state.flags.get(flag_id, false)) != TYPE_BOOL:
			return "A flag de missão '%s' precisa ser booleana." % flag_id
	var attempted: bool = bool(state.flags.get(&"final_mission_attempted", false))
	var completed: bool = bool(state.flags.get(&"final_mission_completed", false))
	var success: bool = bool(state.flags.get(&"final_mission_success", false))
	var deadline_failed: bool = bool(
		state.flags.get(&"final_mission_failed_by_deadline", false)
	)
	var resolved: bool = bool(state.flags.get(&"final_mission_resolved", false))
	if success and not completed:
		return "Sucesso da missão exige conclusão."
	if completed and not resolved:
		return "Conclusão da missão exige resolução."
	if completed and not attempted:
		return "Conclusão da missão exige uma tentativa real."
	if attempted and state.week < 8:
		return "A missão não pode ter sido tentada antes da semana 8."
	if completed and state.mission_stage != 3:
		return "Missão concluída precisa estar na terceira etapa."
	if completed and state.week < 8:
		return "A missão não pode ser concluída antes da semana 8."
	if state.mission_stage == 3 and not completed:
		return "A terceira etapa exige estado de missão concluído."
	if state.mission_stage > 0 and not attempted:
		return "Progresso de missão exige uma tentativa registrada."
	if attempted and state.mission_stage == 0:
		return "Tentativa registrada sem progresso de missão."
	if deadline_failed and (
		not resolved or completed or success or state.mission_stage >= 3
	):
		return "Falha por prazo exige missão resolvida e não concluída."
	if deadline_failed and state.week < 9:
		return "A falha por prazo só é válida após a transição para a semana 9."
	if resolved != (completed or deadline_failed):
		return "O estado resolvido da missão não corresponde ao resultado terminal."
	if state.week > 8 and not resolved:
		return "Uma campanha após a semana 8 precisa registrar o resultado do prazo."
	return ""


func _validate_root(value: Variant, allowed_keys: Array[String], description: String) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("A raiz de %s precisa ser um objeto JSON." % description)
		return false
	var root: Dictionary = value
	if not _validate_keys(root, allowed_keys, description):
		return false
	if not root.has("schema_version") or not _is_integer(root["schema_version"]):
		push_error("%s precisa definir schema_version inteiro." % description)
		return false
	if int(root["schema_version"]) < 1:
		push_error("schema_version inválido em %s." % description)
		return false
	if typeof(root.get("notes")) != TYPE_STRING:
		push_error("%s precisa definir notes como texto." % description)
		return false
	var collection_key: String = String(allowed_keys.back())
	if typeof(root.get(collection_key)) != TYPE_ARRAY:
		push_error("%s precisa conter '%s' como uma lista." % [description, collection_key])
		return false
	return true


func _validate_event(event: Dictionary, index: int) -> bool:
	const ALLOWED: Array[String] = [
		"id", "campaign", "title", "category", "window", "priority",
		"repeatable", "trigger", "dialogue", "choices", "aftermath",
		"continuity_check",
	]
	var description: String = "evento %d" % (index + 1)
	if not _validate_keys(event, ALLOWED, description):
		return false
	for key: String in [
		"id", "campaign", "title", "category", "window", "priority",
		"repeatable", "trigger", "dialogue", "choices",
	]:
		if not event.has(key):
			push_error("O %s não contém '%s'." % [description, key])
			return false
	if not _is_nonempty_string(event["id"]) or event["campaign"] != "hori":
		push_error("Identidade ou campanha inválida em %s." % description)
		return false
	if not _is_nonempty_string(event["title"]) or not _is_nonempty_string(event["category"]):
		push_error("Título ou categoria inválida em %s." % description)
		return false
	if not _is_integer(event["priority"]) or typeof(event["repeatable"]) != TYPE_BOOL:
		push_error("Prioridade ou repeatable inválido em %s." % description)
		return false
	if typeof(event["window"]) != TYPE_DICTIONARY:
		push_error("A janela de %s precisa ser um objeto." % description)
		return false
	var window: Dictionary = event["window"]
	if (
		not _validate_keys(window, ["week_min", "week_max"], "%s.window" % description)
		or not window.has("week_min")
		or not window.has("week_max")
		or not _is_integer(window["week_min"])
		or not _is_integer(window["week_max"])
		or int(window["week_min"]) < 1
		or int(window["week_max"]) < int(window["week_min"])
		or int(window["week_max"]) > 16
	):
		push_error("A janela semanal de %s é inválida." % description)
		return false
	if not _validate_condition(event["trigger"], "%s.trigger" % description):
		return false
	if typeof(event["dialogue"]) != TYPE_ARRAY or event["dialogue"].is_empty():
		push_error("O diálogo de %s precisa conter ao menos uma fala." % description)
		return false
	for line: Variant in event["dialogue"]:
		if typeof(line) != TYPE_DICTIONARY:
			push_error("Cada fala de %s precisa ser um objeto." % description)
			return false
		if (
			not _validate_keys(line, ["speaker", "text"], "%s.dialogue" % description)
			or not _is_nonempty_string(line.get("speaker"))
			or not _is_nonempty_string(line.get("text"))
		):
			push_error("Fala inválida em %s." % description)
			return false
	if typeof(event["choices"]) != TYPE_ARRAY or event["choices"].is_empty():
		push_error("O evento %s precisa conter escolhas." % event["id"])
		return false
	for choice: Variant in event["choices"]:
		if not _validate_event_choice(choice, description):
			return false
	return true


func _validate_event_choice(choice: Variant, description: String) -> bool:
	if typeof(choice) != TYPE_DICTIONARY:
		push_error("Cada escolha de %s precisa ser um objeto." % description)
		return false
	if not _validate_keys(choice, ["id", "label", "effects"], "%s.choice" % description):
		return false
	if (
		not _is_nonempty_string(choice.get("id"))
		or not _is_nonempty_string(choice.get("label"))
		or typeof(choice.get("effects")) != TYPE_DICTIONARY
	):
		push_error("Escolha inválida em %s." % description)
		return false
	return _validate_effects(choice["effects"], "%s.choice.effects" % description)


func _validate_mission(mission: Dictionary) -> bool:
	const ALLOWED: Array[String] = [
		"mission_id", "campaign", "title", "window", "context",
		"special_ability", "stages", "failure_policy", "continuity_check",
	]
	if not _validate_keys(mission, ALLOWED, "missão de Hori"):
		return false
	for key: String in [
		"mission_id", "campaign", "title", "window", "context",
		"special_ability", "stages",
	]:
		if not mission.has(key):
			push_error("A missão de Hori não contém '%s'." % key)
			return false
	if (
		not _is_nonempty_string(mission["mission_id"])
		or mission["campaign"] != "hori"
		or not _is_nonempty_string(mission["title"])
		or not _is_nonempty_string(mission["context"])
	):
		push_error("Identidade ou contexto inválido na missão de Hori.")
		return false
	if not _validate_window(mission["window"], "missão de Hori"):
		return false
	if typeof(mission["stages"]) != TYPE_ARRAY:
		push_error("As etapas da missão de Hori precisam ser uma lista.")
		return false
	if typeof(mission["special_ability"]) != TYPE_DICTIONARY:
		push_error("A habilidade especial da missão precisa ser um objeto.")
		return false
	var special: Dictionary = mission["special_ability"]
	if not _validate_keys(
		special,
		["id", "name", "owner", "unlock_condition", "effect", "success_chance_note"],
		"habilidade especial"
	):
		return false
	for key: String in ["id", "name", "owner", "unlock_condition", "effect"]:
		if not special.has(key):
			push_error("A habilidade especial não contém '%s'." % key)
			return false
	if (
		not _is_nonempty_string(special["id"])
		or not _is_nonempty_string(special["name"])
		or special["owner"] != "hori"
		or not _is_nonempty_string(special["effect"])
		or not _validate_condition(special["unlock_condition"], "special_ability.unlock_condition")
	):
		push_error("Habilidade especial inválida.")
		return false
	if mission["stages"].size() != 3:
		push_error("A missão de Hori precisa conter exatamente três etapas.")
		return false
	for index: int in range(mission["stages"].size()):
		var stage: Variant = mission["stages"][index]
		if not _validate_mission_stage(stage, index + 1):
			return false
	return true


func _validate_window(value: Variant, description: String) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("A janela semanal de %s precisa ser um objeto." % description)
		return false
	var window: Dictionary = value
	if (
		not _validate_keys(window, ["week_min", "week_max"], "%s.window" % description)
		or not window.has("week_min")
		or not window.has("week_max")
		or not _is_integer(window["week_min"])
		or not _is_integer(window["week_max"])
	):
		push_error("A janela semanal de %s é inválida." % description)
		return false
	return (
		int(window["week_min"]) >= 1
		and int(window["week_max"]) >= int(window["week_min"])
		and int(window["week_max"]) <= 16
	)


func _validate_mission_stage(value: Variant, expected_number: int) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("A etapa %d da missão precisa ser um objeto." % expected_number)
		return false
	var stage: Dictionary = value
	if not _validate_keys(
		stage,
		[
			"stage", "id", "title", "objective", "requirements_note",
			"choices", "flags_persistent",
		],
		"etapa %d" % expected_number
	):
		return false
	if (
		not _is_integer(stage.get("stage"))
		or int(stage.get("stage", -1)) != expected_number
		or not _is_nonempty_string(stage.get("id"))
		or not _is_nonempty_string(stage.get("title"))
		or not _is_nonempty_string(stage.get("objective"))
		or typeof(stage.get("choices")) != TYPE_ARRAY
		or stage["choices"].is_empty()
	):
		push_error("Campos inválidos na etapa %d da missão." % expected_number)
		return false
	for choice: Variant in stage["choices"]:
		if not _validate_mission_choice(choice, expected_number):
			return false
	if stage.has("flags_persistent"):
		if typeof(stage["flags_persistent"]) != TYPE_ARRAY:
			push_error("flags_persistent da etapa %d precisa ser uma lista." % expected_number)
			return false
		for flag: Variant in stage["flags_persistent"]:
			if not _is_nonempty_string(flag):
				push_error("Flag persistente inválida na etapa %d." % expected_number)
				return false
	return true


func _validate_mission_choice(value: Variant, stage_number: int) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("Cada escolha da etapa %d precisa ser um objeto." % stage_number)
		return false
	var choice: Dictionary = value
	if not _validate_keys(
		choice,
		[
			"id", "label", "requirement", "expected_result",
			"effects_success", "effects_failure_recoverable",
		],
		"mission.choice"
	):
		return false
	for key: String in [
		"id", "label", "requirement", "expected_result",
		"effects_success", "effects_failure_recoverable",
	]:
		if not choice.has(key):
			push_error("Escolha da etapa %d não contém '%s'." % [stage_number, key])
			return false
	if (
		not _is_nonempty_string(choice["id"])
		or not _is_nonempty_string(choice["label"])
		or not _is_nonempty_string(choice["expected_result"])
		or not _validate_condition(choice["requirement"], "mission.choice.requirement")
		or typeof(choice["effects_success"]) != TYPE_DICTIONARY
		or typeof(choice["effects_failure_recoverable"]) != TYPE_DICTIONARY
	):
		push_error("Escolha inválida na etapa %d." % stage_number)
		return false
	return (
		_validate_effects(choice["effects_success"], "mission.choice.effects_success")
		and _validate_effects(
			choice["effects_failure_recoverable"],
			"mission.choice.effects_failure_recoverable"
		)
	)


func _validate_ending(ending: Dictionary) -> bool:
	const ALLOWED: Array[String] = [
		"id", "character", "priority", "title", "conditions", "tag",
		"justification", "how_to_reach", "epilogue_text", "consequences",
		"epilogue_note",
	]
	if not _validate_keys(ending, ALLOWED, "final de Hori"):
		return false
	for key: String in ["id", "character", "priority", "title", "conditions", "tag"]:
		if not ending.has(key):
			push_error("Um final de Hori não contém '%s'." % key)
			return false
	if (
		not _is_nonempty_string(ending["id"])
		or ending["character"] != "hori"
		or not _is_integer(ending["priority"])
		or not _is_nonempty_string(ending["title"])
		or not _is_nonempty_string(ending["tag"])
		or not _validate_condition(ending["conditions"], "ending.conditions")
	):
		push_error("Condição ou metadado inválido em um final de Hori.")
		return false
	for text_key: String in ["epilogue_text", "justification", "how_to_reach", "epilogue_note"]:
		if ending.has(text_key) and typeof(ending[text_key]) != TYPE_STRING:
			push_error("O campo '%s' do final precisa ser texto." % text_key)
			return false
	if ending.has("consequences"):
		if typeof(ending["consequences"]) != TYPE_DICTIONARY:
			push_error("consequences do final precisa ser um objeto.")
			return false
		for character_id: Variant in ending["consequences"]:
			if (
				typeof(character_id) != TYPE_STRING
				or typeof(ending["consequences"][character_id]) != TYPE_STRING
			):
				push_error("Cada consequência de final precisa ser textual.")
				return false
	return true


func _validate_condition(value: Variant, description: String) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("%s precisa ser um objeto." % description)
		return false
	var condition: Dictionary = value
	if condition.has("all") or condition.has("any"):
		if condition.size() != 1:
			push_error("Condição composta inválida em %s." % description)
			return false
		var operator: String = "all" if condition.has("all") else "any"
		if typeof(condition[operator]) != TYPE_ARRAY or condition[operator].is_empty():
			push_error("A condição '%s' de %s precisa conter itens." % [operator, description])
			return false
		for child: Variant in condition[operator]:
			if not _validate_condition(child, description):
				return false
		return true
	if not _validate_keys(condition, ["path", "op", "value"], description):
		return false
	if (
		condition.size() != 3
		or not _is_nonempty_string(condition.get("path"))
		or not _is_nonempty_string(condition.get("op"))
		or not CONDITION_OPERATORS.has(String(condition["op"]))
		or not condition.has("value")
	):
		push_error("Condição folha inválida em %s." % description)
		return false
	if not _is_supported_path(String(condition["path"])):
		push_error("Caminho de condição desconhecido em %s: %s." % [
			description,
			condition["path"],
		])
		return false
	return true


func _is_supported_path(path: String) -> bool:
	if path == "week" or path == "week.current":
		return true
	var segments: PackedStringArray = path.split(".")
	if segments.size() != 2:
		return false
	var id := StringName(segments[1])
	match segments[0]:
		"stats":
			return TrainingState.ATTRIBUTE_IDS.has(id)
		"resources":
			return RESOURCE_IDS.has(id)
		"axes":
			return AXIS_IDS.has(id)
		"bonds":
			return BOND_IDS.has(id)
		"route_state":
			return (
				TrainingState.ROUTE_STATE_LIMITS.has(id)
				or TrainingState.ROUTE_STATE_BOOLEAN_IDS.has(id)
			)
		"flags":
			return not segments[1].is_empty()
	return false


func _validate_effects(effects: Dictionary, description: String) -> bool:
	if not _validate_keys(effects, EFFECT_KEYS, description):
		return false
	for key: String in effects:
		var value: Variant = effects[key]
		match key:
			"stats_delta":
				if not _validate_delta_map(value, TrainingState.ATTRIBUTE_IDS, "%s.%s" % [description, key]):
					return false
			"axes_delta":
				if not _validate_delta_map(value, AXIS_IDS, "%s.%s" % [description, key]):
					return false
			"route_state_delta", "route_state_delta_team":
				if not _validate_delta_map(value, ROUTE_STATE_DELTA_IDS, "%s.%s" % [description, key]):
					return false
			"resources_delta":
				if not _validate_delta_map(value, RESOURCE_IDS, "%s.%s" % [description, key]):
					return false
			"bonds_delta":
				if not _validate_delta_map(value, BOND_IDS, "%s.%s" % [description, key]):
					return false
			"route_state_set":
				if not _validate_route_state_values(value, "%s.%s" % [description, key]):
					return false
			"route_state_set_if":
				if not _validate_route_state_set_if(value, description):
					return false
			"flags_set":
				if not _validate_flag_map(value, "%s.%s" % [description, key]):
					return false
	return true


func _validate_delta_map(
	value: Variant,
	allowed_ids: Array[StringName],
	description: String
) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("%s precisa ser um objeto." % description)
		return false
	for id: Variant in value:
		if (
			typeof(id) != TYPE_STRING
			or not allowed_ids.has(StringName(id))
			or not _is_integer(value[id])
		):
			push_error("Delta inválido em %s: %s." % [description, id])
			return false
	return true


func _validate_route_state_values(value: Variant, description: String) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("%s precisa ser um objeto." % description)
		return false
	var allowed_ids: Array[StringName] = ROUTE_STATE_DELTA_IDS.duplicate()
	allowed_ids.append_array(TrainingState.ROUTE_STATE_BOOLEAN_IDS)
	for id: Variant in value:
		if typeof(id) != TYPE_STRING or not allowed_ids.has(StringName(id)):
			push_error("Campo route_state desconhecido em %s: %s." % [description, id])
			return false
		var route_id := StringName(id)
		if TrainingState.ROUTE_STATE_BOOLEAN_IDS.has(route_id):
			if typeof(value[id]) != TYPE_BOOL:
				push_error("O campo '%s' precisa ser booleano." % id)
				return false
		elif not _is_integer(value[id]):
			push_error("O campo '%s' precisa ser inteiro." % id)
			return false
		else:
			var bounds: Vector2i = TrainingState.ROUTE_STATE_LIMITS[route_id]
			var route_value: int = int(value[id])
			if route_value < bounds.x or route_value > bounds.y:
				push_error("O campo '%s' está fora dos limites em %s." % [id, description])
				return false
	return true


func _validate_route_state_set_if(value: Variant, description: String) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("%s.route_state_set_if precisa ser um objeto." % description)
		return false
	if not _validate_keys(
		value,
		["condition_flag", "field", "value"],
		"%s.route_state_set_if" % description
	):
		return false
	if (
		value.size() != 3
		or not _is_nonempty_string(value.get("condition_flag"))
		or value.get("field") != "identification_aids"
		or typeof(value.get("value")) != TYPE_BOOL
	):
		push_error("route_state_set_if inválido em %s." % description)
		return false
	return true


func _validate_flag_map(value: Variant, description: String) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_error("%s precisa ser um objeto." % description)
		return false
	for id: Variant in value:
		if (
			typeof(id) != TYPE_STRING
			or String(id).is_empty()
			or typeof(value[id]) != TYPE_BOOL
		):
			push_error("Flag inválida em %s: %s." % [description, id])
			return false
	return true


func _validate_keys(data: Dictionary, allowed_keys: Array, description: String) -> bool:
	for key: Variant in data:
		if typeof(key) != TYPE_STRING or not allowed_keys.has(key):
			push_error("Chave desconhecida em %s: %s." % [description, key])
			return false
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


func _is_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return (
		typeof(value) == TYPE_FLOAT
		and is_equal_approx(float(value), roundf(float(value)))
	)


func _is_numeric(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _is_nonempty_string(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not String(value).strip_edges().is_empty()

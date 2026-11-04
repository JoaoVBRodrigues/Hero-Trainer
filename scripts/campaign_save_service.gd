class_name CampaignSaveService
extends RefCounted

const SAVE_PATH: String = "user://hero_trainer_save.json"
const BACKUP_PATH: String = "user://hero_trainer_save.json.bak"
const TEMP_PATH: String = "user://hero_trainer_save.json.tmp"
const CORRUPT_ARCHIVE_PATH: String = "user://hero_trainer_save.json.corrupt"
const SAVE_SCHEMA_VERSION: int = 1
const CAMPAIGN_ID: String = "hori"
const CONTENT_VERSION: String = "hori_route_v1"
const SUPPORTED_ENGINE_VERSIONS: Array[String] = ["4.5.1"]
const SNAPSHOT_KEYS: Array[String] = [
	"week", "actions_remaining", "stats", "axes", "route_state", "flags",
	"mission_stage", "ending_id", "energy", "stress", "motivation", "credits",
	"reputation", "bonds", "rng_seed", "rng_state", "inventory",
	"equipped_item_id",
]
const STAT_KEYS: Array[String] = ["pot", "res", "tec", "teo", "sin"]
const AXIS_KEYS: Array[String] = ["autonomy", "solidarity", "ambition", "integrity"]
const BOND_KEYS: Array[String] = ["hori", "ray", "luppi", "instructor"]


func inspect_save(
	training_service: TrainingService,
	narrative_service: NarrativeService,
	economy_service: EconomyService
) -> Dictionary:
	var primary: Dictionary = _read_save(
		SAVE_PATH,
		training_service,
		narrative_service,
		economy_service
	)
	if primary["status"] == "valid":
		return primary
	if primary["status"] == "unsupported":
		return primary

	var backup: Dictionary = _read_save(
		BACKUP_PATH,
		training_service,
		narrative_service,
		economy_service
	)
	if backup["status"] == "valid":
		return {
			"status": "recoverable",
			"state": backup["state"],
			"message": (
				"Save principal inválido ou ausente. Foi encontrada uma cópia "
				+ "de recuperação válida."
			),
			"primary_status": primary["status"],
		}
	if primary["status"] == "missing" and backup["status"] == "missing":
		return primary
	return {
		"status": "corrupt",
		"state": null,
		"message": "%s Cópia de recuperação: %s" % [
			String(primary["message"]),
			String(backup["message"]),
		],
		"primary_status": primary["status"],
	}


func archive_primary_save() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""
	if FileAccess.file_exists(CORRUPT_ARCHIVE_PATH):
		return (
			"Já existe um arquivo de preservação em %s; nenhum save foi alterado."
			% CORRUPT_ARCHIVE_PATH
		)
	var copy_error: Error = DirAccess.copy_absolute(
		ProjectSettings.globalize_path(SAVE_PATH),
		ProjectSettings.globalize_path(CORRUPT_ARCHIVE_PATH)
	)
	if copy_error != OK:
		return "Não foi possível preservar o save atual: %s." % error_string(copy_error)
	var source_bytes: PackedByteArray = FileAccess.get_file_as_bytes(SAVE_PATH)
	var archive_bytes: PackedByteArray = FileAccess.get_file_as_bytes(
		CORRUPT_ARCHIVE_PATH
	)
	if source_bytes != archive_bytes:
		return "A cópia de preservação não corresponde ao save original."
	var remove_error: Error = DirAccess.remove_absolute(
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if remove_error != OK:
		return (
			"Save preservado em %s, mas não foi possível liberar o caminho principal: %s."
			% [CORRUPT_ARCHIVE_PATH, error_string(remove_error)]
		)
	return ""


func save(
	state: TrainingState,
	training_service: TrainingService,
	narrative_service: NarrativeService,
	economy_service: EconomyService
) -> String:
	var engine_version: String = _current_engine_version()
	if not SUPPORTED_ENGINE_VERSIONS.has(engine_version):
		return "Esta versão do Godot (%s) não é suportada pelo formato de save atual." % engine_version
	var validation_error: String = _validate_campaign(
		state,
		training_service,
		narrative_service,
		economy_service
	)
	if not validation_error.is_empty():
		return "Save recusado: %s" % validation_error

	var save_data: Dictionary = _encode_save(state, engine_version)
	var write_error: String = _write_temp_save(save_data)
	if not write_error.is_empty():
		return write_error
	var temp_result: Dictionary = _read_save(
		TEMP_PATH,
		training_service,
		narrative_service,
		economy_service
	)
	if temp_result["status"] != "valid":
		return "O arquivo temporário não passou na validação: %s" % temp_result["message"]

	var had_valid_primary: bool = false
	if FileAccess.file_exists(SAVE_PATH):
		var existing: Dictionary = _read_save(
			SAVE_PATH,
			training_service,
			narrative_service,
			economy_service
		)
		if existing["status"] != "valid":
			return (
				"Save principal inválido ou incompatível foi preservado; "
				+ "nenhum dado será sobrescrito. %s"
			) % String(existing["message"])
		var backup_error: Error = DirAccess.copy_absolute(
			ProjectSettings.globalize_path(SAVE_PATH),
			ProjectSettings.globalize_path(BACKUP_PATH)
		)
		if backup_error != OK:
			return "Não foi possível atualizar o backup do save: %s." % error_string(backup_error)
		had_valid_primary = true

	var replace_error: Error = DirAccess.copy_absolute(
		ProjectSettings.globalize_path(TEMP_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if replace_error != OK:
		return "Não foi possível gravar o save principal: %s." % error_string(replace_error)
	var verified_primary: Dictionary = _read_save(
		SAVE_PATH,
		training_service,
		narrative_service,
		economy_service
	)
	if verified_primary["status"] != "valid":
		var recovery_message: String = ""
		if had_valid_primary:
			var restore_error: Error = DirAccess.copy_absolute(
				ProjectSettings.globalize_path(BACKUP_PATH),
				ProjectSettings.globalize_path(SAVE_PATH)
			)
			recovery_message = (
				" O save anterior foi restaurado do backup."
				if restore_error == OK
				else " Falha ao restaurar o backup: %s." % error_string(restore_error)
			)
		return (
			"O save recém-gravado falhou na verificação: %s.%s"
			% [String(verified_primary["message"]), recovery_message]
		)

	var cleanup_error: Error = DirAccess.remove_absolute(
		ProjectSettings.globalize_path(TEMP_PATH)
	)
	if cleanup_error != OK and cleanup_error != ERR_FILE_NOT_FOUND:
		push_warning(
			"Save válido; não foi possível remover o temporário: %s."
			% error_string(cleanup_error)
		)
	return ""


func _validate_campaign(
	state: TrainingState,
	training_service: TrainingService,
	narrative_service: NarrativeService,
	economy_service: EconomyService
) -> String:
	var training_error: String = training_service.validate_state(state)
	if not training_error.is_empty():
		return training_error
	var narrative_error: String = narrative_service.validate_campaign_state(state)
	if not narrative_error.is_empty():
		return narrative_error
	if state.ending_id != &"":
		var resolved_ending: Dictionary = narrative_service.resolve_ending(state)
		if (
			resolved_ending.is_empty()
			or StringName(resolved_ending["id"]) != state.ending_id
		):
			return "O final salvo não corresponde a um final elegível da campanha."
	return economy_service.validate_state(state)


func _encode_save(state: TrainingState, engine_version: String) -> Dictionary:
	return {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"campaign_id": CAMPAIGN_ID,
		"content_version": CONTENT_VERSION,
		"engine_version": engine_version,
		"snapshot": {
			"week": state.week,
			"actions_remaining": state.actions_remaining,
			"stats": _string_keyed_dictionary(state.stats),
			"axes": _string_keyed_dictionary(state.axes),
			"route_state": _string_keyed_dictionary(state.route_state),
			"flags": _string_keyed_dictionary(state.flags),
			"mission_stage": state.mission_stage,
			"ending_id": String(state.ending_id),
			"energy": state.energy,
			"stress": state.stress,
			"motivation": state.motivation,
			"credits": state.credits,
			"reputation": state.reputation,
			"bonds": _string_keyed_dictionary(state.bonds),
			"rng_seed": state.rng_seed,
			"rng_state": state.rng_state,
			"inventory": _string_name_array(state.inventory),
			"equipped_item_id": String(state.equipped_item_id),
		},
	}


func _write_temp_save(save_data: Dictionary) -> String:
	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return "Não foi possível abrir o temporário do save: %s." % error_string(
			FileAccess.get_open_error()
		)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return "Falha ao escrever o save temporário: %s." % error_string(write_error)
	return ""


func _read_save(
	path: String,
	training_service: TrainingService,
	narrative_service: NarrativeService,
	economy_service: EconomyService
) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"status": "missing",
			"state": null,
			"message": "O arquivo de save não existe.",
		}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"status": "corrupt",
			"state": null,
			"message": "Não foi possível ler o save: %s." % error_string(
				FileAccess.get_open_error()
			),
		}
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {
			"status": "corrupt",
			"state": null,
			"message": "JSON inválido na linha %d: %s." % [
				parser.get_error_line(),
				parser.get_error_message(),
			],
		}
	return _decode_save(
		parser.data,
		training_service,
		narrative_service,
		economy_service
	)


func _decode_save(
	value: Variant,
	training_service: TrainingService,
	narrative_service: NarrativeService,
	economy_service: EconomyService
) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return _corrupt_result("A raiz do save precisa ser um objeto.")
	var data: Dictionary = value
	if not _has_exact_keys(
		data,
		[
			"save_schema_version", "campaign_id", "content_version",
			"engine_version", "snapshot",
		]
	):
		return _corrupt_result("O envelope do save contém campos ausentes ou desconhecidos.")
	if not _is_integer(data.get("save_schema_version")):
		return _corrupt_result("A versão do schema do save não é um inteiro.")
	var schema_version: int = int(data["save_schema_version"])
	if schema_version != SAVE_SCHEMA_VERSION:
		return _unsupported_result("Versão de schema não suportada: %d." % schema_version)
	if (
		data["campaign_id"] != CAMPAIGN_ID
		or data["content_version"] != CONTENT_VERSION
	):
		return _unsupported_result("O save pertence a outra campanha ou versão de conteúdo.")
	if typeof(data["engine_version"]) != TYPE_STRING:
		return _corrupt_result("A versão do Godot no save precisa ser texto.")
	var engine_version: String = String(data["engine_version"])
	if not SUPPORTED_ENGINE_VERSIONS.has(engine_version):
		return _unsupported_result(
			"Versão do Godot não suportada pelo save: %s." % engine_version
		)
	var decoded_state: Dictionary = _decode_snapshot(data["snapshot"])
	if not bool(decoded_state["valid"]):
		return _corrupt_result(String(decoded_state["message"]))
	var state: TrainingState = decoded_state["state"]
	var validation_error: String = _validate_campaign(
		state,
		training_service,
		narrative_service,
		economy_service
	)
	if not validation_error.is_empty():
		return _corrupt_result("Snapshot inválido: %s" % validation_error)
	return {
		"status": "valid",
		"state": state,
		"message": "Save válido.",
	}


func _decode_snapshot(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return _invalid_snapshot("O snapshot da campanha precisa ser um objeto.")
	var snapshot: Dictionary = value
	if not _has_exact_keys(snapshot, SNAPSHOT_KEYS):
		return _invalid_snapshot("O snapshot contém campos ausentes ou desconhecidos.")
	for key: String in [
		"week", "actions_remaining", "mission_stage", "energy", "stress",
		"motivation", "credits", "reputation", "rng_seed", "rng_state",
	]:
		if not _is_integer(snapshot.get(key)):
			return _invalid_snapshot("O campo '%s' precisa ser inteiro." % key)
	if (
		typeof(snapshot["ending_id"]) != TYPE_STRING
		or typeof(snapshot["inventory"]) != TYPE_ARRAY
		or typeof(snapshot["equipped_item_id"]) != TYPE_STRING
	):
		return _invalid_snapshot("Campos de identidade ou inventário inválidos.")
	var state := TrainingState.new()
	state.week = int(snapshot["week"])
	state.actions_remaining = int(snapshot["actions_remaining"])
	state.mission_stage = int(snapshot["mission_stage"])
	state.ending_id = StringName(snapshot["ending_id"])
	state.energy = int(snapshot["energy"])
	state.stress = int(snapshot["stress"])
	state.motivation = int(snapshot["motivation"])
	state.credits = int(snapshot["credits"])
	state.reputation = int(snapshot["reputation"])
	state.rng_seed = int(snapshot["rng_seed"])
	state.rng_state = int(snapshot["rng_state"])
	state.equipped_item_id = StringName(snapshot["equipped_item_id"])
	if not _load_integer_map(snapshot["stats"], STAT_KEYS, state.stats):
		return _invalid_snapshot("Atributos inválidos no snapshot.")
	if not _load_integer_map(snapshot["axes"], AXIS_KEYS, state.axes):
		return _invalid_snapshot("Eixos inválidos no snapshot.")
	if not _load_integer_map(snapshot["bonds"], BOND_KEYS, state.bonds):
		return _invalid_snapshot("Vínculos inválidos no snapshot.")
	if not _load_route_state(snapshot["route_state"], state):
		return _invalid_snapshot("Estado narrativo inválido no snapshot.")
	if not _load_flags(snapshot["flags"], state):
		return _invalid_snapshot("Flags inválidas no snapshot.")
	for item_value: Variant in snapshot["inventory"]:
		if typeof(item_value) != TYPE_STRING:
			return _invalid_snapshot("O inventário contém um identificador inválido.")
		state.inventory.append(StringName(item_value))
	return {"valid": true, "state": state, "message": ""}


func _load_integer_map(
	value: Variant,
	expected_keys: Array[String],
	target: Dictionary[StringName, int]
) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = value
	if not _has_exact_keys(data, expected_keys):
		return false
	for key: String in expected_keys:
		if not _is_integer(data[key]):
			return false
		target[StringName(key)] = int(data[key])
	return true


func _load_route_state(value: Variant, state: TrainingState) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = value
	var expected_keys: Array[String] = []
	for key: StringName in TrainingState.ROUTE_STATE_LIMITS:
		expected_keys.append(String(key))
	for key: StringName in TrainingState.ROUTE_STATE_BOOLEAN_IDS:
		expected_keys.append(String(key))
	if not _has_exact_keys(data, expected_keys):
		return false
	for key: StringName in TrainingState.ROUTE_STATE_LIMITS:
		var value_at_key: Variant = data[String(key)]
		if not _is_integer(value_at_key):
			return false
		state.route_state[key] = int(value_at_key)
	for key: StringName in TrainingState.ROUTE_STATE_BOOLEAN_IDS:
		if typeof(data[String(key)]) != TYPE_BOOL:
			return false
		state.route_state[key] = data[String(key)]
	return true


func _load_flags(value: Variant, state: TrainingState) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = value
	var flags: Dictionary[StringName, bool] = {}
	for key: Variant in data:
		if typeof(key) != TYPE_STRING or typeof(data[key]) != TYPE_BOOL:
			return false
		flags[StringName(key)] = data[key]
	for mission_flag: StringName in TrainingState.MISSION_FLAG_IDS:
		if not flags.has(mission_flag):
			return false
	state.flags = flags
	return true


func _string_keyed_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in source:
		result[String(key)] = source[key]
	return result


func _string_name_array(source: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for item_id: StringName in source:
		result.append(String(item_id))
	return result


func _has_exact_keys(data: Dictionary, expected_keys: Array[String]) -> bool:
	if data.size() != expected_keys.size():
		return false
	for key: Variant in data:
		if typeof(key) != TYPE_STRING or not expected_keys.has(String(key)):
			return false
	return true


func _is_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return (
		typeof(value) == TYPE_FLOAT
		and is_equal_approx(float(value), roundf(float(value)))
	)


func _current_engine_version() -> String:
	var version_info: Dictionary = Engine.get_version_info()
	return "%d.%d.%d" % [
		int(version_info["major"]),
		int(version_info["minor"]),
		int(version_info["patch"]),
	]


func _corrupt_result(message: String) -> Dictionary:
	return {"status": "corrupt", "state": null, "message": message}


func _unsupported_result(message: String) -> Dictionary:
	return {"status": "unsupported", "state": null, "message": message}


func _invalid_snapshot(message: String) -> Dictionary:
	return {"valid": false, "state": null, "message": message}

@tool
extends McpTestSuite

const TrainingServiceScript = preload("res://scripts/training_service.gd")
const NarrativeServiceScript = preload("res://scripts/narrative_service.gd")
const EconomyServiceScript = preload("res://scripts/economy_service.gd")
const CampaignSaveServiceScript = preload("res://scripts/campaign_save_service.gd")
const TrainingStateScript = preload("res://scripts/training_state.gd")


func suite_name() -> String:
	return "Campaign Economy and Save"


func test_economy_and_snapshot_round_trip() -> void:
	var training: TrainingServiceScript = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeServiceScript = NarrativeServiceScript.new()
	narrative.set_limits(
		training.get_attribute_cap(),
		training.get_resource_cap(),
		training.get_reputation_cap(),
		training.get_bond_cap()
	)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var economy: EconomyServiceScript = EconomyServiceScript.new()
	economy.set_actions_per_week(training.get_actions_per_week())
	var save_service: CampaignSaveServiceScript = CampaignSaveServiceScript.new()
	var state: TrainingStateScript = training.create_initial_state()
	state.credits = 500

	assert_true(
		economy.purchase_item(state, &"training_notebook").is_empty(),
		"notebook purchase succeeds"
	)
	assert_eq(state.credits, 420, "purchase deducts the catalog price")
	assert_true(
		economy.equip_item(state, &"training_notebook").is_empty(),
		"owned equipment can be equipped before the first action"
	)
	assert_eq(state.equipped_item_id, &"training_notebook", "equipped item is recorded")
	assert_false(
		economy.purchase_item(state, &"training_notebook").is_empty(),
		"duplicate item purchase is rejected"
	)
	assert_true(
		economy.purchase_item(state, &"recovery_kit").is_empty(),
		"recovery kit purchase succeeds"
	)
	state.actions_remaining -= 1
	assert_false(
		economy.equip_item(state, &"recovery_kit").is_empty(),
		"equipment cannot be changed after the first weekly action"
	)

	var encoded: Dictionary = save_service._encode_save(state, "4.5.1")
	var decoded_save: Dictionary = save_service._decode_save(
		encoded,
		training,
		narrative,
		economy
	)
	assert_eq(decoded_save["status"], "valid", "versioned save envelope passes validation")
	var decoded: Dictionary = save_service._decode_snapshot(encoded["snapshot"])
	assert_true(decoded["valid"], "encoded snapshot passes structural decoding")
	var restored: TrainingStateScript = decoded["state"]
	assert_eq(restored.week, state.week, "week survives snapshot round trip")
	assert_eq(restored.actions_remaining, state.actions_remaining, "actions survive snapshot round trip")
	assert_eq(restored.stats, state.stats, "attributes survive snapshot round trip")
	assert_eq(restored.flags, state.flags, "narrative flags survive snapshot round trip")
	assert_eq(restored.inventory, state.inventory, "inventory survives snapshot round trip")
	assert_eq(restored.equipped_item_id, state.equipped_item_id, "equipment survives snapshot round trip")
	assert_eq(restored.rng_state, state.rng_state, "RNG state survives snapshot round trip")
	assert_true(
		save_service._validate_campaign(
			restored,
			training,
			narrative,
			economy
		).is_empty(),
		"restored campaign passes service validation"
	)
	var invalid_envelope: Dictionary = encoded.duplicate(true)
	invalid_envelope["unexpected"] = true
	assert_eq(
		save_service._decode_save(
			invalid_envelope,
			training,
			narrative,
			economy
		)["status"],
		"corrupt",
		"unknown save-envelope fields are rejected"
	)


func test_real_file_save_load_preserves_campaign_state() -> void:
	var training: TrainingServiceScript = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeServiceScript = NarrativeServiceScript.new()
	narrative.set_limits(
		training.get_attribute_cap(),
		training.get_resource_cap(),
		training.get_reputation_cap(),
		training.get_bond_cap()
	)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var economy: EconomyServiceScript = EconomyServiceScript.new()
	economy.set_actions_per_week(training.get_actions_per_week())
	var save_service: CampaignSaveServiceScript = CampaignSaveServiceScript.new()
	var paths: Dictionary = _create_test_save_paths()

	assert_eq(
		save_service._inspect_save_at(
			paths["primary"],
			paths["backup"],
			training,
			narrative,
			economy
		)["status"],
		"missing",
		"isolated test paths start without a save"
	)

	var state: TrainingStateScript = training.create_initial_state()
	state.week = 2
	state.actions_remaining = 2
	state.stats[&"pot"] += 7
	state.route_state[&"core_stability"] = 65
	state.route_state[&"identification_aids_progress"] = 1
	state.flags[&"test_narrative_flag"] = true
	state.energy = 65
	state.stress = 22
	state.motivation = 74
	state.credits = 200
	state.reputation = 31
	state.bonds[&"ray"] += 3
	state.rng_seed = 12345
	state.rng_state = 67890
	state.inventory.append(&"training_notebook")
	state.equipped_item_id = &"training_notebook"
	var first_save_error: String = save_service._save_to_paths(
		state,
		training,
		narrative,
		economy,
		paths["primary"],
		paths["backup"],
		paths["temp"]
	)
	assert_true(first_save_error.is_empty(), "first save writes a valid JSON file")
	assert_true(FileAccess.file_exists(paths["primary"]), "primary save exists on disk")

	var first_json := JSON.new()
	assert_eq(
		first_json.parse(FileAccess.get_file_as_string(paths["primary"])),
		OK,
		"primary save is valid JSON"
	)
	var first_inspection: Dictionary = save_service._inspect_save_at(
		paths["primary"],
		paths["backup"],
		training,
		narrative,
		economy
	)
	assert_eq(first_inspection["status"], "valid", "written file loads from disk")
	var restored: TrainingStateScript = first_inspection["state"]
	assert_eq(restored.week, state.week, "week survives file save/load")
	assert_eq(restored.actions_remaining, state.actions_remaining, "actions survive file save/load")
	assert_eq(restored.stats, state.stats, "attributes survive file save/load")
	assert_eq(restored.axes, state.axes, "axes survive file save/load")
	assert_eq(restored.route_state, state.route_state, "narrative progress survives file save/load")
	assert_eq(restored.flags, state.flags, "narrative flags survive file save/load")
	assert_eq(restored.energy, state.energy, "energy survives file save/load")
	assert_eq(restored.stress, state.stress, "stress survives file save/load")
	assert_eq(restored.motivation, state.motivation, "motivation survives file save/load")
	assert_eq(restored.credits, state.credits, "credits survive file save/load")
	assert_eq(restored.reputation, state.reputation, "reputation survives file save/load")
	assert_eq(restored.bonds, state.bonds, "bonds survive file save/load")
	assert_eq(restored.rng_seed, state.rng_seed, "RNG seed survives file save/load")
	assert_eq(restored.rng_state, state.rng_state, "RNG state survives file save/load")
	assert_eq(restored.inventory, state.inventory, "inventory survives file save/load")
	assert_eq(restored.equipped_item_id, state.equipped_item_id, "equipment survives file save/load")

	var prior_primary_bytes: PackedByteArray = FileAccess.get_file_as_bytes(paths["primary"])
	var invalid_state: TrainingStateScript = state.duplicate_state()
	invalid_state.credits = -1
	assert_false(
		save_service._save_to_paths(
			invalid_state,
			training,
			narrative,
			economy,
			paths["primary"],
			paths["backup"],
			paths["temp"]
		).is_empty(),
		"invalid state is rejected"
	)
	assert_eq(
		FileAccess.get_file_as_bytes(paths["primary"]),
		prior_primary_bytes,
		"invalid state cannot overwrite the valid save"
	)
	_cleanup_test_save_paths(paths)


func test_real_file_save_recovery_and_corrupt_preservation() -> void:
	var training: TrainingServiceScript = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeServiceScript = NarrativeServiceScript.new()
	narrative.set_limits(
		training.get_attribute_cap(),
		training.get_resource_cap(),
		training.get_reputation_cap(),
		training.get_bond_cap()
	)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var economy: EconomyServiceScript = EconomyServiceScript.new()
	economy.set_actions_per_week(training.get_actions_per_week())
	var save_service: CampaignSaveServiceScript = CampaignSaveServiceScript.new()
	var paths: Dictionary = _create_test_save_paths()
	var state: TrainingStateScript = training.create_initial_state()
	assert_true(
		save_service._save_to_paths(
			state,
			training,
			narrative,
			economy,
			paths["primary"],
			paths["backup"],
			paths["temp"]
		).is_empty(),
		"initial test save succeeds"
	)
	var backup_credits: int = state.credits
	state.credits += 5
	assert_true(
		save_service._save_to_paths(
			state,
			training,
			narrative,
			economy,
			paths["primary"],
			paths["backup"],
			paths["temp"]
		).is_empty(),
		"updated test save succeeds"
	)
	assert_true(FileAccess.file_exists(paths["backup"]), "previous primary is backed up")

	var primary_file: FileAccess = FileAccess.open(paths["primary"], FileAccess.WRITE)
	assert_true(primary_file != null, "test primary can be replaced with malformed JSON")
	if primary_file == null:
		_cleanup_test_save_paths(paths)
		return
	primary_file.store_string("{invalid json")
	primary_file.close()
	var corrupt_primary_bytes: PackedByteArray = FileAccess.get_file_as_bytes(
		paths["primary"]
	)
	var recovery: Dictionary = save_service._inspect_save_at(
		paths["primary"],
		paths["backup"],
		training,
		narrative,
		economy
	)
	assert_eq(recovery["status"], "recoverable", "valid backup recovers malformed primary")
	assert_eq(
		(recovery["state"] as TrainingStateScript).credits,
		backup_credits,
		"recovery uses the previous primary snapshot"
	)
	assert_eq(
		FileAccess.get_file_as_bytes(paths["primary"]),
		corrupt_primary_bytes,
		"inspection preserves the malformed primary for recovery"
	)
	var preserved_backup_bytes: PackedByteArray = FileAccess.get_file_as_bytes(
		paths["backup"]
	)
	assert_false(
		save_service._save_to_paths(
			state,
			training,
			narrative,
			economy,
			paths["primary"],
			paths["backup"],
			paths["temp"]
		).is_empty(),
		"save refuses to overwrite a malformed primary"
	)
	assert_eq(
		FileAccess.get_file_as_bytes(paths["primary"]),
		corrupt_primary_bytes,
		"save rejection preserves malformed primary bytes"
	)
	assert_eq(
		FileAccess.get_file_as_bytes(paths["backup"]),
		preserved_backup_bytes,
		"save rejection preserves the valid backup"
	)

	assert_eq(
		DirAccess.remove_absolute(ProjectSettings.globalize_path(paths["primary"])),
		OK,
		"isolated primary can be removed for the missing-primary case"
	)
	recovery = save_service._inspect_save_at(
		paths["primary"],
		paths["backup"],
		training,
		narrative,
		economy
	)
	assert_eq(recovery["status"], "recoverable", "missing primary recovers valid backup")
	assert_eq(
		(recovery["state"] as TrainingStateScript).credits,
		backup_credits,
		"missing-primary recovery loads the backup snapshot"
	)

	assert_eq(
		DirAccess.remove_absolute(ProjectSettings.globalize_path(paths["backup"])),
		OK,
		"isolated backup can be removed for missing-save checks"
	)
	assert_eq(
		save_service._inspect_save_at(
			paths["primary"],
			paths["backup"],
			training,
			narrative,
			economy
		)["status"],
		"missing",
		"both missing files are reported without creating a campaign"
	)
	var invalid_file: FileAccess = FileAccess.open(paths["primary"], FileAccess.WRITE)
	assert_true(invalid_file != null, "isolated invalid JSON file can be created")
	if invalid_file == null:
		_cleanup_test_save_paths(paths)
		return
	invalid_file.store_string("{invalid JSON")
	invalid_file.close()
	var invalid_primary_bytes: PackedByteArray = FileAccess.get_file_as_bytes(
		paths["primary"]
	)
	assert_eq(
		save_service._inspect_save_at(
			paths["primary"],
			paths["backup"],
			training,
			narrative,
			economy
		)["status"],
		"corrupt",
		"invalid JSON without a backup is reported as corrupt"
	)
	assert_eq(
		FileAccess.get_file_as_bytes(paths["primary"]),
		invalid_primary_bytes,
		"invalid JSON is preserved when there is no recovery backup"
	)
	_cleanup_test_save_paths(paths)


func _create_test_save_paths() -> Dictionary:
	var directory_name: String = "campaign_save_test_%d" % Time.get_ticks_usec()
	var directory: String = "user://%s" % directory_name
	var user_directory: DirAccess = DirAccess.open("user://")
	assert_true(user_directory != null, "isolated save test directory is accessible")
	var directory_error: Error = user_directory.make_dir_recursive(directory_name)
	assert_true(directory_error == OK, "isolated save test directory is created")
	return {
		"directory": directory,
		"primary": "%s/save.json" % directory,
		"backup": "%s/save.json.bak" % directory,
		"temp": "%s/save.json.tmp" % directory,
	}


func _cleanup_test_save_paths(paths: Dictionary) -> void:
	for key: String in ["primary", "backup", "temp"]:
		var path: String = String(paths[key])
		if FileAccess.file_exists(path):
			var remove_error: Error = DirAccess.remove_absolute(
				ProjectSettings.globalize_path(path)
			)
			assert_eq(remove_error, OK, "isolated test file is cleaned up")
	var directory_error: Error = DirAccess.remove_absolute(
		ProjectSettings.globalize_path(paths["directory"])
	)
	assert_eq(directory_error, OK, "isolated save test directory is cleaned up")


func test_economy_rejections_preserve_state() -> void:
	var economy: EconomyServiceScript = EconomyServiceScript.new()
	economy.set_actions_per_week(3)
	var state := TrainingStateScript.new()
	state.credits = 79
	state.actions_remaining = 3
	var credits_before: int = state.credits
	assert_false(
		economy.purchase_item(state, &"training_notebook").is_empty(),
		"insufficient credits reject a purchase"
	)
	assert_eq(state.credits, credits_before, "rejected purchase preserves credits")
	assert_true(state.inventory.is_empty(), "rejected purchase preserves inventory")

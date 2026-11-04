@tool
extends McpTestSuite

const TrainingServiceScript = preload("res://scripts/training_service.gd")
const NarrativeServiceScript = preload("res://scripts/narrative_service.gd")
const EconomyServiceScript = preload("res://scripts/economy_service.gd")
const CampaignSaveServiceScript = preload("res://scripts/campaign_save_service.gd")


func suite_name() -> String:
	return "Campaign Economy and Save"


func test_economy_and_snapshot_round_trip() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeService = NarrativeServiceScript.new()
	narrative.set_limits(
		training.get_attribute_cap(),
		training.get_resource_cap(),
		training.get_reputation_cap(),
		training.get_bond_cap()
	)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var economy: EconomyService = EconomyServiceScript.new()
	economy.set_actions_per_week(training.get_actions_per_week())
	var save_service: CampaignSaveService = CampaignSaveServiceScript.new()
	var state: TrainingState = training.create_initial_state()
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
	var restored: TrainingState = decoded["state"]
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


func test_economy_rejections_preserve_state() -> void:
	var economy: EconomyService = EconomyServiceScript.new()
	economy.set_actions_per_week(3)
	var state := TrainingState.new()
	state.credits = 79
	state.actions_remaining = 3
	var credits_before: int = state.credits
	assert_false(
		economy.purchase_item(state, &"training_notebook").is_empty(),
		"insufficient credits reject a purchase"
	)
	assert_eq(state.credits, credits_before, "rejected purchase preserves credits")
	assert_true(state.inventory.is_empty(), "rejected purchase preserves inventory")

@tool
extends McpTestSuite

const TrainingServiceScript = preload("res://scripts/training_service.gd")


func suite_name() -> String:
	return "Training Service"


func test_training_regressions() -> void:
	var service: TrainingService = TrainingServiceScript.new()
	if not service.load_project_data():
		assert_true(false, "project JSON loads")
		return
	_check(true, "project JSON loads")

	service.set_random_seed(_seed_with_safe_training_draws())
	_test_configuration_comes_from_json(service)
	_test_activity_effects(service)
	_test_stat_and_resource_caps(service)
	_test_three_actions_and_fourth_action(service)
	_test_rest_recovers_energy(service)
	_test_preview_matches_applied_result(service)
	_test_insufficient_energy_rejection(service)
	_test_unavailable_activity_preview(service)
	_test_week_advancement(service)
	_test_eight_configured_activities(service)
	_test_new_activity_effects(service)
	_test_credits_reputation_and_bonds(service)
	_test_resource_persistence_between_weeks(service)
	_test_expanded_caps_and_invalid_data(service)
	_test_failure_chance_bounds(service)
	_test_failure_success_and_costs(service)
	_test_failure_probability_and_rng_advancement(service)
	_test_rng_is_unchanged_by_preview_and_rejection(service)
	_test_seeded_sequences_are_reproducible(service)
	_test_rng_state_continues_with_campaign(service)
	_test_non_failing_activities_do_not_draw(service)
	_test_phase4c_modifiers_and_equipment(service)


func _test_configuration_comes_from_json(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	_check(service.get_total_weeks() == 16, "campaign length comes from activities JSON")
	_check(service.get_actions_per_week() == 3, "weekly actions come from activities JSON")
	_check(service.get_attribute_cap() == 100, "attribute cap comes from activities JSON")
	_check(service.get_resource_cap() == 100, "resource cap comes from activities JSON")
	_check(state.actions_remaining == service.get_actions_per_week(), "initial action count uses JSON")
	_check(state.credits == 50, "initial credits come from character JSON")
	_check(state.reputation == 20, "initial reputation comes from character JSON")
	_check(state.bonds[&"ray"] == 30, "Ray bond comes from character JSON")
	_check(state.bonds[&"luppi"] == 25, "Luppi bond comes from character JSON")


func _test_activity_effects(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	var result: TrainingPreview = service.apply_activity(state, &"combat")
	_check(result.is_valid, "combat applies successfully")
	_check(state.stats[&"pot"] == 36, "combat applies aptitude and motivation to power gain")
	_check(state.stats[&"tec"] == 30, "combat increases technique by 2")
	_check(state.energy == 60, "combat consumes 15 energy")
	_check(state.stress == 18, "combat adds 6 stress")
	_check(state.actions_remaining == 2, "one activity consumes one action")


func _test_stat_and_resource_caps(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	state.stats[&"pot"] = 98
	state.stats[&"tec"] = 99
	state.energy = 15
	state.stress = 98
	var combat: TrainingPreview = service.apply_activity(state, &"combat")
	_check(combat.is_valid, "combat applies at exactly its minimum energy")
	_check(state.stats[&"pot"] == 100, "power is capped at 100")
	_check(state.stats[&"tec"] == 100, "technique is capped at 100")
	_check(state.energy == 0, "combat consumes exactly its minimum energy")
	_check(state.stress == 100, "stress is capped at 100")

	state.motivation = 99
	var rest: TrainingPreview = service.apply_activity(state, &"rest")
	_check(rest.is_valid, "rest near maximum applies")
	_check(state.energy == 25, "rest recovers energy from 0")
	_check(state.stress == 88, "rest reduces stress")
	_check(state.motivation == 100, "motivation is capped at 100")


func _test_three_actions_and_fourth_action(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	for action_index: int in range(3):
		var result: TrainingPreview = service.apply_activity(state, &"rest")
		_check(result.is_valid, "weekly action %d applies" % (action_index + 1))
	_check(state.actions_remaining == 0, "exactly three actions are consumed")
	var fourth: TrainingPreview = service.apply_activity(state, &"combat")
	_check(not fourth.is_valid, "a fourth action is rejected")
	_check(state.actions_remaining == 0, "rejected action does not change action count")


func _test_rest_recovers_energy(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	state.energy = 0
	state.stress = 30
	var result: TrainingPreview = service.apply_activity(state, &"rest")
	_check(result.is_valid, "rest remains available at zero energy")
	_check(state.energy == 25, "rest recovers 25 energy")
	_check(state.stress == 18, "rest reduces stress by 12")


func _test_preview_matches_applied_result(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	var preview: TrainingPreview = service.preview_activity(state, &"control")
	_check(preview.is_valid, "control preview is available")
	_check(preview.can_fail, "control preview reports probabilistic outcome")
	_check(preview.result == null, "risky preview does not promise an applied result")
	_check(
		preview.success_result.stats[&"sin"] == 45,
		"risky preview exposes gains only in its success scenario"
	)
	_check(
		preview.failure_result.stats[&"sin"] == state.stats[&"sin"],
		"risky preview omits attribute gains from its failure scenario"
	)
	_check(state.actions_remaining == 3, "preview does not consume an action")
	_check(state.stats[&"sin"] == 40, "preview does not mutate input state")
	var rng_state_before: int = state.rng_state

	var applied: TrainingPreview = service.apply_activity(state, &"control")
	_check(applied.is_valid, "previewed control activity applies")
	_check(applied.was_applied, "confirmed activity records that it was applied")
	_check(
		applied.outcome == TrainingPreview.OUTCOME_SUCCESS,
		"safe seeded control training succeeds"
	)
	_check(
		preview.success_result.stats == state.stats
		and preview.success_result.energy == state.energy
		and preview.success_result.stress == state.stress
		and preview.success_result.motivation == state.motivation
		and preview.success_result.credits == state.credits
		and preview.success_result.reputation == state.reputation
		and preview.success_result.bonds == state.bonds
		and preview.success_result.actions_remaining == state.actions_remaining,
		"successful application matches the preview success scenario"
	)
	_check(state.rng_state != rng_state_before, "confirmed risky training advances RNG state")


func _test_insufficient_energy_rejection(service: TrainingService) -> void:
	_test_rejected_activity_preserves_state(service, &"combat", 5, "combat")
	_test_rejected_activity_preserves_state(service, &"control", 12, "control")
	var control_boundary_state: TrainingState = service.create_initial_state()
	control_boundary_state.energy = 13
	var control_at_minimum: TrainingPreview = service.apply_activity(
		control_boundary_state,
		&"control"
	)
	_check(control_at_minimum.is_valid, "control applies at exactly its minimum energy")
	_check(control_boundary_state.energy == 0, "control consumes its minimum energy")


func _test_rejected_activity_preserves_state(
	service: TrainingService,
	activity_id: StringName,
	energy: int,
	label: String
) -> void:
	var state: TrainingState = service.create_initial_state()
	state.energy = energy
	state.stats[&"pot"] = 99
	state.stats[&"tec"] = 99
	state.stress = 99
	state.motivation = 99
	var before: Dictionary = _state_snapshot(state)

	var preview: TrainingPreview = service.preview_activity(state, activity_id)
	_check(not preview.is_valid, "%s preview rejects insufficient energy" % label)
	_check(
		preview.message.contains("Faltam"),
		"%s preview explains missing energy" % label
	)
	_check(
		state.actions_remaining == service.get_actions_per_week(),
		"%s preview rejection consumes no action" % label
	)
	_check(
		_state_snapshot(state) == before,
		"%s preview rejection preserves the whole state" % label
	)

	var applied: TrainingPreview = service.apply_activity(state, activity_id)
	_check(not applied.is_valid, "%s application rejects insufficient energy" % label)
	_check(
		state.actions_remaining == service.get_actions_per_week(),
		"%s application rejection consumes no action" % label
	)
	_check(
		_state_snapshot(state) == before,
		"%s application rejection preserves the whole state" % label
	)


func _test_unavailable_activity_preview(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	var before: Dictionary = _state_snapshot(state)
	var preview: TrainingPreview = service.preview_activity(state, &"missing_activity")
	_check(not preview.is_valid, "unknown activity preview is rejected")
	_check(
		preview.message.contains("não está disponível"),
		"unknown activity preview explains it is unavailable"
	)
	_check(
		_state_snapshot(state) == before,
		"unknown activity preview preserves the whole state"
	)
	var applied: TrainingPreview = service.apply_activity(state, &"missing_activity")
	_check(not applied.is_valid, "unknown activity cannot be applied")
	_check(
		_state_snapshot(state) == before,
		"unknown activity rejection preserves the whole state"
	)


func _state_snapshot(state: TrainingState) -> Dictionary:
	return {
		"week": state.week,
		"actions_remaining": state.actions_remaining,
		"stats": state.stats.duplicate(),
		"axes": state.axes.duplicate(),
		"route_state": state.route_state.duplicate(),
		"flags": state.flags.duplicate(),
		"mission_stage": state.mission_stage,
		"ending_id": state.ending_id,
		"energy": state.energy,
		"stress": state.stress,
		"motivation": state.motivation,
		"credits": state.credits,
		"reputation": state.reputation,
		"bonds": state.bonds.duplicate(),
		"rng_seed": state.rng_seed,
		"rng_state": state.rng_state,
	}


func _test_eight_configured_activities(service: TrainingService) -> void:
	var activity_ids: Array[StringName] = service.get_activity_ids()
	_check(activity_ids.size() == 8, "all eight JSON activities load")
	for activity_id: StringName in [
		&"combat", &"lab", &"control", &"conditioning", &"rest",
		&"internship", &"bond_ray", &"bond_luppi",
	]:
		_check(activity_ids.has(activity_id), "activity %s is configured" % activity_id)


func _test_new_activity_effects(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	var lab: TrainingPreview = service.apply_activity(state, &"lab")
	_check(lab.is_valid, "laboratory study applies")
	_check(state.stats[&"teo"] == 43 and state.stats[&"sin"] == 42, "laboratory deltas apply")
	_check(state.energy == 65 and state.stress == 16, "laboratory resource deltas apply")

	var conditioning: TrainingPreview = service.apply_activity(state, &"conditioning")
	_check(conditioning.is_valid, "conditioning applies")
	_check(
		state.stats[&"res"] == 39 and state.stats[&"pot"] == 31,
		"conditioning stat deltas apply"
	)
	_check(state.energy == 52 and state.stress == 19, "conditioning resource deltas apply")


func _test_credits_reputation_and_bonds(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	var internship: TrainingPreview = service.apply_activity(state, &"internship")
	_check(internship.is_valid, "internship applies")
	_check(state.credits == 75 and state.reputation == 21, "internship grants configured rewards")
	_check(state.energy == 67 and state.stress == 16, "internship energy and stress deltas apply")

	state.energy = 0
	var ray_result: TrainingPreview = service.apply_activity(state, &"bond_ray")
	_check(ray_result.is_valid, "Ray conversation is available at zero energy")
	_check(state.bonds[&"ray"] == 38, "Ray bond increases independently")
	_check(state.bonds[&"luppi"] == 25, "Ray conversation does not change Luppi bond")
	var luppi_result: TrainingPreview = service.apply_activity(state, &"bond_luppi")
	_check(luppi_result.is_valid, "time with Luppi is available at zero energy")
	_check(state.bonds[&"luppi"] == 33, "Luppi bond increases independently")
	_check(state.bonds[&"ray"] == 38, "Luppi time does not change Ray bond")


func _test_resource_persistence_between_weeks(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	state.credits = 1234
	state.reputation = 77
	state.bonds[&"ray"] = 58
	state.bonds[&"luppi"] = 63
	for action_index: int in range(service.get_actions_per_week()):
		_check(service.apply_activity(state, &"rest").is_valid, "week-closing rest applies")
	var credits_before: int = state.credits
	var reputation_before: int = state.reputation
	var bonds_before: Dictionary = state.bonds.duplicate()
	_check(service.advance_week(state), "advance week after all actions")
	_check(state.credits == credits_before, "credits persist after advancing week")
	_check(state.reputation == reputation_before, "reputation persists after advancing week")
	_check(state.bonds == bonds_before, "all bonds persist after advancing week")


func _test_expanded_caps_and_invalid_data(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	state.bonds[&"ray"] = service.get_bond_cap() - 1
	state.reputation = service.get_reputation_cap()
	var ray_preview: TrainingPreview = service.preview_activity(state, &"bond_ray")
	_check(ray_preview.is_valid, "relationship remains valid near its cap")
	_check(ray_preview.result.bonds[&"ray"] == service.get_bond_cap(), "bond gain respects cap")
	_check(ray_preview.result.reputation == service.get_reputation_cap(), "reputation respects cap")
	state.credits = 150
	var internship: TrainingPreview = service.apply_activity(state, &"internship")
	_check(internship.is_valid, "internship remains available with credits above 100")
	_check(state.credits == 175, "credits accumulate above the generic resource cap")

	var initial_character_data: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://Hero_Trainer_Kit_v02/data/characters.json")
	)
	var invalid_activities_data: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://Hero_Trainer_Kit_v02/data/activities.json")
	)
	invalid_activities_data["unexpected_key"] = true
	expect_script_error_containing("Chave desconhecida em activities.json")
	_check(
		not service.load_data(initial_character_data, invalid_activities_data),
		"unknown JSON keys are rejected"
	)
	var preserved_state: TrainingState = service.create_initial_state()
	_check(preserved_state.credits == 50, "invalid reload does not partially replace loaded state")
	_check(
		service.apply_activity(preserved_state, &"rest").is_valid,
		"valid loaded data remains usable after invalid reload"
	)


func _test_week_advancement(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	_check(not service.advance_week(state), "cannot advance before using all actions")
	for action_index: int in range(3):
		service.apply_activity(state, &"rest")
	_check(service.advance_week(state), "week advances after the third action")
	_check(state.week == 2, "week number increments")
	_check(
		state.actions_remaining == service.get_actions_per_week(),
		"new week restores the JSON action count"
	)

	var campaign: TrainingState = service.create_initial_state()
	for week_number: int in range(1, service.get_total_weeks() + 1):
		for action_index: int in range(service.get_actions_per_week()):
			_check(
				service.apply_activity(campaign, &"rest").is_valid,
				"week %d action %d applies" % [week_number, action_index + 1]
			)
		if week_number < service.get_total_weeks():
			_check(service.advance_week(campaign), "campaign advances after week %d" % week_number)
			_check(campaign.week == week_number + 1, "campaign enters week %d" % (week_number + 1))
		else:
			_check(campaign.week == 16, "campaign reaches the configured final week")
			_check(not service.advance_week(campaign), "campaign cannot advance beyond week 16")


func _test_failure_chance_bounds(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	state.energy = 100
	state.stress = 0
	var no_risk: TrainingPreview = service.preview_activity(state, &"lab")
	_check(no_risk.is_valid, "high energy and low stress training is available")
	_check(no_risk.failure_chance_percent == 0, "failure probability reaches its 0% minimum")
	_check(no_risk.success_chance_percent == 100, "success probability complements failure")

	state.energy = 10
	state.stress = 100
	var highest_valid_risk: TrainingPreview = service.preview_activity(state, &"lab")
	_check(
		highest_valid_risk.failure_chance_percent == 49,
		"low energy and high stress produce the approved 49% example"
	)
	_check(
		service._calculate_failure_chance(0, 200) == 55,
		"formula applies the declared 55% upper clamp"
	)
	_check(
		service._calculate_failure_chance(100, 20) == 0,
		"formula applies the declared 0% lower clamp"
	)


func _test_failure_success_and_costs(service: TrainingService) -> void:
	var success_state: TrainingState = service.create_initial_state()
	success_state.energy = 10
	success_state.stress = 40
	var success_probability: int = service.preview_activity(
		success_state,
		&"lab"
	).failure_chance_percent
	service.set_random_seed(_seed_with_roll_at_least(success_probability))
	success_state = service.create_initial_state()
	success_state.energy = 10
	success_state.stress = 40
	var success: TrainingPreview = service.apply_activity(success_state, &"lab")
	_check(success.outcome == TrainingPreview.OUTCOME_SUCCESS, "seeded roll produces success")
	_check(
		success_state.stats[&"teo"] == 43 and success_state.stats[&"sin"] == 42,
		"success applies configured attribute gains"
	)
	_check(
		success_state.energy == 0 and success_state.stress == 44,
		"success applies configured resource costs"
	)
	_check(success_state.actions_remaining == 2, "success consumes exactly one action")

	service.set_random_seed(_seed_with_roll_below(success_probability))
	var failure_state: TrainingState = service.create_initial_state()
	failure_state.energy = 10
	failure_state.stress = 40
	var failure: TrainingPreview = service.apply_activity(failure_state, &"lab")
	_check(failure.outcome == TrainingPreview.OUTCOME_FAILURE, "seeded roll produces failure")
	_check(
		failure_state.stats[&"teo"] == 38 and failure_state.stats[&"sin"] == 40,
		"failure withholds all configured attribute gains"
	)
	_check(
		failure_state.energy == 0 and failure_state.stress == 44,
		"failure still applies configured resource costs"
	)
	_check(failure_state.actions_remaining == 2, "failure consumes exactly one action")
	_check(failure.message.contains("falhou"), "failure returns a clear structured message")


func _test_failure_probability_and_rng_advancement(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	state.energy = 10
	state.stress = 100
	var preview: TrainingPreview = service.preview_activity(state, &"lab")
	_check(preview.failure_chance_percent == 49, "low energy and high stress raise failure risk")
	_check(preview.success_chance_percent == 51, "displayed probabilities total 100%")

	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = state.rng_seed
	expected_rng.state = state.rng_state
	expected_rng.randf()
	var expected_state: int = expected_rng.state
	var result: TrainingPreview = service.apply_activity(state, &"lab")
	_check(
		result.random_roll >= 0.0 and result.random_roll < 1.0,
		"confirmed risky result records its actual random roll"
	)
	_check(
		state.rng_state == expected_state,
		"one confirmed risky action advances the RNG by exactly one draw"
	)


func _test_rng_is_unchanged_by_preview_and_rejection(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	var initial_rng_state: int = state.rng_state
	var preview: TrainingPreview = service.preview_activity(state, &"combat")
	_check(preview.is_valid, "valid risky activity can be previewed")
	_check(state.rng_state == initial_rng_state, "preview does not consume RNG")
	_check(
		not preview.was_applied and preview.random_roll < 0.0,
		"preview does not reveal the next random draw"
	)
	# Cancelling a preview only discards this result object; it never touches the campaign state.
	preview = null
	_check(state.rng_state == initial_rng_state, "cancelling a preview leaves RNG unchanged")

	state.energy = 9
	var before_rejection: Dictionary = _state_snapshot(state)
	var rejected: TrainingPreview = service.apply_activity(state, &"lab")
	_check(not rejected.is_valid, "lab below its energy requirement is rejected")
	_check(
		_state_snapshot(state) == before_rejection,
		"energy rejection preserves state and RNG without a draw"
	)


func _test_seeded_sequences_are_reproducible(service: TrainingService) -> void:
	const TEST_SEED: int = 983472
	service.set_random_seed(TEST_SEED)
	var first_state: TrainingState = service.create_initial_state()
	service.set_random_seed(TEST_SEED)
	var second_state: TrainingState = service.create_initial_state()
	var outcomes_a := PackedStringArray()
	var outcomes_b := PackedStringArray()
	for activity_id: StringName in [&"lab", &"conditioning", &"control"]:
		var first_result: TrainingPreview = service.apply_activity(first_state, activity_id)
		var second_result: TrainingPreview = service.apply_activity(second_state, activity_id)
		outcomes_a.append(String(first_result.outcome))
		outcomes_b.append(String(second_result.outcome))
	_check(outcomes_a == outcomes_b, "same seed and action sequence reproduce outcomes")
	_check(
		_state_snapshot(first_state) == _state_snapshot(second_state),
		"same seed and action sequence reproduce campaign and RNG state"
	)


func _test_rng_state_continues_with_campaign(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	var training: TrainingPreview = service.apply_activity(state, &"lab")
	_check(training.is_valid, "risky activity applies before campaign-state copy")
	var saved_seed: int = state.rng_seed
	var saved_rng_state: int = state.rng_state
	var duplicated: TrainingState = state.duplicate_state()
	_check(duplicated.rng_seed == saved_seed, "campaign copy preserves RNG seed")
	_check(duplicated.rng_state == saved_rng_state, "campaign copy preserves RNG state")

	while state.actions_remaining > 0:
		_check(
			service.apply_activity(state, &"rest").is_valid,
			"deterministic recovery closes the week"
		)
	_check(service.advance_week(state), "campaign advances after risky training")
	_check(state.rng_seed == saved_seed, "week advancement preserves RNG seed")
	_check(state.rng_state == saved_rng_state, "week advancement preserves RNG sequence")


func _test_non_failing_activities_do_not_draw(service: TrainingService) -> void:
	for activity_id: StringName in [&"rest", &"internship", &"bond_ray", &"bond_luppi"]:
		var state: TrainingState = service.create_initial_state()
		var before_rng_state: int = state.rng_state
		var applied: TrainingPreview = service.apply_activity(state, activity_id)
		_check(applied.is_valid, "%s applies deterministically" % activity_id)
		_check(
			applied.outcome == TrainingPreview.OUTCOME_DETERMINISTIC,
			"%s records a deterministic outcome" % activity_id
		)
		_check(
			state.rng_state == before_rng_state,
			"%s does not consume a random draw" % activity_id
		)


func _test_phase4c_modifiers_and_equipment(service: TrainingService) -> void:
	var low_motivation_state: TrainingState = service.create_initial_state()
	low_motivation_state.motivation = 33
	var low_preview: TrainingPreview = service.preview_activity(
		low_motivation_state,
		&"combat"
	)
	_check(low_preview.motivation_multiplier == 0.9, "motivation 33 uses the low multiplier")
	_check(low_preview.attribute_gains[&"pot"] == 5, "low motivation affects calculated attribute gain")

	var high_motivation_state: TrainingState = service.create_initial_state()
	high_motivation_state.motivation = 67
	var high_preview: TrainingPreview = service.preview_activity(
		high_motivation_state,
		&"combat"
	)
	_check(high_preview.motivation_multiplier == 1.1, "motivation 67 uses the high multiplier")
	_check(high_preview.attribute_gains[&"pot"] == 6, "high motivation and aptitude round once")

	var mentor_state: TrainingState = service.create_initial_state()
	mentor_state.energy = 20
	mentor_state.stress = 60
	mentor_state.bonds[&"instructor"] = 30
	var mentored_preview: TrainingPreview = service.preview_activity(
		mentor_state,
		&"lab"
	)
	_check(mentored_preview.base_failure_chance_percent == 30, "base risk follows the new formula")
	_check(mentored_preview.failure_chance_percent == 25, "eligible mentor reduces risk by five points")

	var economy := EconomyService.new()
	economy.set_actions_per_week(service.get_actions_per_week())
	var notebook_state: TrainingState = service.create_initial_state()
	notebook_state.credits = 200
	_check(
		economy.purchase_item(notebook_state, &"training_notebook").is_empty(),
		"notebook purchase succeeds with sufficient credits"
	)
	_check(
		economy.equip_item(notebook_state, &"training_notebook").is_empty(),
		"notebook can be equipped before the first weekly action"
	)
	_check(
		service.get_activity_energy_cost(&"combat", notebook_state) == 13,
		"notebook reduces training energy cost by two"
	)
	notebook_state.actions_remaining -= 1
	_check(
		not economy.equip_item(notebook_state, &"").is_empty(),
		"equipment cannot be changed after the first weekly action"
	)

	var recovery_state: TrainingState = service.create_initial_state()
	recovery_state.equipped_item_id = &"recovery_kit"
	recovery_state.inventory.append(&"recovery_kit")
	var rest_result: TrainingPreview = service.apply_activity(recovery_state, &"rest")
	_check(rest_result.is_valid and recovery_state.energy == 100, "recovery kit adds five energy within cap")

	var focus_state: TrainingState = service.create_initial_state()
	focus_state.equipped_item_id = &"focus_aid"
	focus_state.inventory.append(&"focus_aid")
	var focus_preview: TrainingPreview = service.preview_activity(focus_state, &"combat")
	_check(focus_preview.stress_delta == 5, "focus aid reduces training stress by one")


func _seed_with_safe_training_draws() -> int:
	for candidate_seed: int in range(1, 100000):
		var rng := RandomNumberGenerator.new()
		rng.seed = candidate_seed
		var safe: bool = true
		for draw_index: int in range(8):
			if rng.randf() < 0.52:
				safe = false
				break
		if safe:
			return candidate_seed
	push_error("Não foi possível encontrar uma seed segura para os testes determinísticos.")
	return 1


func _seed_with_roll_at_least(chance_percent: int) -> int:
	for candidate_seed: int in range(1, 100000):
		var rng := RandomNumberGenerator.new()
		rng.seed = candidate_seed
		if rng.randf() >= float(chance_percent) / 100.0:
			return candidate_seed
	push_error("Não foi possível encontrar uma seed de sucesso para os testes.")
	return 1


func _seed_with_roll_below(chance_percent: int) -> int:
	for candidate_seed: int in range(1, 100000):
		var rng := RandomNumberGenerator.new()
		rng.seed = candidate_seed
		if rng.randf() < float(chance_percent) / 100.0:
			return candidate_seed
	push_error("Não foi possível encontrar uma seed de falha para os testes.")
	return 1


func _check(condition: bool, description: String) -> void:
	assert_true(condition, description)

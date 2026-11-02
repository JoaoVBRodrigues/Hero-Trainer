extends SceneTree

const TrainingServiceScript = preload("res://scripts/training_service.gd")

var _failures: int = 0
var _assertions: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var service: TrainingService = TrainingServiceScript.new()
	_check(service.load_project_data(), "project JSON loads")
	if _failures > 0:
		_finish()
		return

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
	_finish()


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
	_check(state.stats[&"pot"] == 35, "combat increases power by 5")
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
	_check(state.actions_remaining == 3, "preview does not consume an action")
	_check(state.stats[&"sin"] == 40, "preview does not mutate input state")

	var applied: TrainingPreview = service.apply_activity(state, &"control")
	_check(applied.is_valid, "previewed control activity applies")
	_check(
		preview.result.stats == state.stats
		and preview.result.energy == state.energy
		and preview.result.stress == state.stress
		and preview.result.motivation == state.motivation
		and preview.result.credits == state.credits
		and preview.result.reputation == state.reputation
		and preview.result.bonds == state.bonds
		and preview.result.actions_remaining == state.actions_remaining,
		"preview matches the applied result"
	)


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
		"energy": state.energy,
		"stress": state.stress,
		"motivation": state.motivation,
		"credits": state.credits,
		"reputation": state.reputation,
		"bonds": state.bonds.duplicate(),
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


func _check(condition: bool, description: String) -> void:
	_assertions += 1
	if not condition:
		_failures += 1
		push_error("FAIL: %s" % description)


func _finish() -> void:
	print("Testes do serviço: %d verificações, %d falhas." % [_assertions, _failures])
	quit(1 if _failures > 0 else 0)

extends SceneTree

const TrainingServiceScript = preload("res://scripts/training_service.gd")

var _failures: int = 0
var _assertions: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var service: TrainingService = TrainingServiceScript.new()
	_check(service.load_project_data(), "project JSON loads")
	if _failures > 0:
		_finish()
		return

	_test_activity_effects(service)
	_test_stat_and_resource_caps(service)
	_test_three_actions_and_fourth_action(service)
	_test_rest_recovers_energy(service)
	_test_preview_matches_applied_result(service)
	_test_week_advancement(service)
	_finish()


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
	state.energy = 5
	state.stress = 98
	var combat: TrainingPreview = service.apply_activity(state, &"combat")
	_check(combat.is_valid, "combat near limits applies")
	_check(state.stats[&"pot"] == 100, "power is capped at 100")
	_check(state.stats[&"tec"] == 100, "technique is capped at 100")
	_check(state.energy == 0, "energy is clamped at 0")
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
		and preview.result.actions_remaining == state.actions_remaining,
		"preview matches the applied result"
	)


func _test_week_advancement(service: TrainingService) -> void:
	var state: TrainingState = service.create_initial_state()
	_check(not service.advance_week(state), "cannot advance before using all actions")
	for action_index: int in range(3):
		service.apply_activity(state, &"rest")
	_check(service.advance_week(state), "week advances after the third action")
	_check(state.week == 2, "week number increments")
	_check(state.actions_remaining == 3, "new week restores three actions")


func _check(condition: bool, description: String) -> void:
	_assertions += 1
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)


func _finish() -> void:
	print("Testes do serviço: %d verificações, %d falhas." % [_assertions, _failures])
	quit(1 if _failures > 0 else 0)

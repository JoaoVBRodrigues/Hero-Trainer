@tool
extends McpTestSuite

const TrainingServiceScript = preload("res://scripts/training_service.gd")
const NarrativeServiceScript = preload("res://scripts/narrative_service.gd")


func suite_name() -> String:
	return "Hori Narrative Campaign"


func test_approved_data_and_initial_state() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeService = _new_narrative_service(training)
	assert_true(narrative.load_project_data(), "approved Hori route data should load")
	assert_eq(narrative.get_event_ids().size(), 8, "eight authored events should load")
	assert_eq(narrative.get_ending_ids().size(), 4, "four Hori endings should load")
	var state: TrainingState = training.create_initial_state()
	assert_eq(state.axes[&"solidarity"], 0, "axes should initialize from character JSON")
	assert_eq(state.route_state[&"core_stability"], 65, "route state should initialize from character JSON")
	assert_eq(state.route_state[&"identification_aids_progress"], 0, "new progress should default to zero")


func test_event_effects_do_not_consume_training_turn_or_rng() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeService = _new_narrative_service(training)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var state: TrainingState = training.create_initial_state()
	var actions_before: int = state.actions_remaining
	var rng_before: int = state.rng_state
	var event: Dictionary = narrative.get_next_event(state)
	assert_eq(event.get("id"), "hori_face_clues_w02", "week-one event should be selected")
	var result: NarrativeResult = narrative.apply_event_choice(
		state,
		&"hori_face_clues_w02",
		&"ask_signals"
	)
	assert_true(result.is_valid, "valid event choice should apply")
	assert_eq(state.axes[&"solidarity"], 6, "axis delta should apply")
	assert_eq(state.route_state[&"identification_aids_progress"], 1, "route delta should apply")
	assert_eq(state.stress, 14, "resource delta should apply")
	assert_true(state.flags[&"hori_face_clues_w02_seen"], "event should be marked seen")
	assert_eq(state.actions_remaining, actions_before, "event should not consume a training action")
	assert_eq(state.rng_state, rng_before, "event should not consume training RNG")

	var conditional_state: TrainingState = training.create_initial_state()
	conditional_state.week = 5
	conditional_state.flags[&"hori_identification_aid_offered"] = true
	var conditional: NarrativeResult = narrative.apply_event_choice(
		conditional_state,
		&"hori_dorm_party_w05",
		&"group_system"
	)
	assert_true(conditional.is_valid, "conditional group-system choice should apply")
	assert_true(
		conditional_state.route_state[&"identification_aids"],
		"conditional route-state setter should honor its prerequisite flag"
	)


func test_mission_outcomes_and_pulse_thresholds() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeService = _new_narrative_service(training)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var state: TrainingState = training.create_initial_state()
	state.week = 8
	assert_true(narrative.is_mission_due(state), "mission should open in week eight")
	var preview: NarrativeResult = narrative.preview_mission_choice(state, &"fast_advance")
	assert_true(
		preview.is_valid and preview.outcome == &"success",
		"meeting requirement should preview success"
	)
	assert_eq(state.mission_stage, 0, "preview should not advance mission")
	assert_true(narrative.apply_mission_choice(state, &"fast_advance").is_valid, "stage one should apply")
	assert_eq(state.mission_stage, 1, "stage one should advance")
	assert_true(state.flags[&"final_mission_attempted"], "first choice records a real attempt")
	assert_false(
		narrative.get_mission_choice_ids(state).has(&"containment_pulse"),
		"Pulse stays hidden until both approved thresholds are met"
	)
	assert_true(
		narrative.pulse_requirement_message(state).contains("28/30"),
		"Pulse preview reports the current Technique value"
	)
	state.stats[&"tec"] = NarrativeService.PULSE_MIN_TECHNIQUE
	assert_true(
		narrative.get_mission_choice_ids(state).has(&"containment_pulse"),
		"Pulse unlocks when both thresholds are met"
	)
	var pulse: NarrativeResult = narrative.apply_mission_choice(state, &"containment_pulse")
	assert_true(
		pulse.is_valid and pulse.outcome == &"success",
		"Pulse should succeed at approved thresholds"
	)
	assert_true(state.flags[&"stage2_pulse_success"], "Pulse success flag should be set")

	var recoverable_state: TrainingState = training.create_initial_state()
	recoverable_state.week = 8
	recoverable_state.mission_stage = 1
	recoverable_state.flags[&"final_mission_attempted"] = true
	recoverable_state.route_state[&"core_stability"] = 39
	recoverable_state.stats[&"tec"] = 29
	var recoverable: NarrativeResult = narrative.apply_mission_choice(
		recoverable_state,
		&"stabilize_with_core"
	)
	assert_true(
		recoverable.is_valid and recoverable.outcome == &"failure_recoverable",
		"unmet core-action requirement produces recoverable failure"
	)
	assert_eq(recoverable_state.mission_stage, 2, "recoverable failure advances the mission")

	var missed_deadline: TrainingState = training.create_initial_state()
	missed_deadline.week = 8
	missed_deadline.actions_remaining = 0
	assert_true(
		narrative.expire_mission_by_deadline(missed_deadline),
		"deadline is recorded at the end of week eight"
	)
	assert_false(
		missed_deadline.flags[&"final_mission_attempted"],
		"deadline does not fabricate a mission attempt"
	)
	assert_true(
		missed_deadline.flags[&"final_mission_failed_by_deadline"]
		and missed_deadline.flags[&"final_mission_resolved"],
		"deadline records a resolved non-completion"
	)
	assert_false(
		narrative.expire_mission_by_deadline(missed_deadline),
		"deadline resolution is idempotent"
	)
	assert_true(training.advance_week(missed_deadline), "campaign advances after the deadline is resolved")
	assert_true(
		narrative.validate_campaign_state(missed_deadline).is_empty(),
		"resolved campaign state remains valid in week nine"
	)
	assert_eq(
		narrative.resolve_ending(missed_deadline).get("id"),
		"hori_overburdened",
		"missed deadline resolves to the fallback ending"
	)


func test_event_windows_priority_and_limit_clamps() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeService = _new_narrative_service(training)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var state: TrainingState = training.create_initial_state()
	state.week = 3
	assert_eq(
		narrative.get_next_event(state).get("id"),
		"hori_core_protocol_w03",
		"event selection should follow week windows"
	)
	state.stats[&"tec"] = training.get_attribute_cap() - 1
	state.route_state[&"core_stability"] = 98
	state.route_state[&"trusted_network"] = 99
	state.stress = 98
	var result: NarrativeResult = narrative.apply_event_choice(
		state,
		&"hori_core_protocol_w03",
		&"team_training"
	)
	assert_true(result.is_valid, "core protocol event should apply near caps")
	assert_eq(state.stats[&"tec"], training.get_attribute_cap(), "stats should clamp to cap")
	assert_eq(state.route_state[&"core_stability"], 100, "route state should clamp to 100")
	assert_eq(state.route_state[&"trusted_network"], 100, "network should clamp to 100")
	assert_eq(state.stress, training.get_resource_cap(), "resources should clamp to cap")

	var priority_state: TrainingState = training.create_initial_state()
	priority_state.week = 12
	priority_state.flags[&"final_mission_failed_by_deadline"] = true
	priority_state.flags[&"final_mission_resolved"] = true
	priority_state.route_state[&"echo_pressure"] = 25
	assert_eq(
		narrative.get_next_event(priority_state).get("id"),
		"hori_echo_confrontation_w11",
		"higher-priority eligible event should be selected first"
	)
	var echo_result: NarrativeResult = narrative.apply_event_choice(
		priority_state,
		&"hori_echo_confrontation_w11",
		&"refuse_and_seek_support"
	)
	assert_true(echo_result.is_valid, "week 12 fallback trigger should apply")
	assert_eq(
		narrative.get_next_event(priority_state).get("id"),
		"hori_rupture_investigation_w12",
		"remaining eligible week 12 event should follow"
	)


func test_invalid_choices_and_data_are_atomic() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeService = _new_narrative_service(training)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var state: TrainingState = training.create_initial_state()
	state.week = 3
	var before: Dictionary = _state_snapshot(state)
	var rejected: NarrativeResult = narrative.apply_event_choice(
		state,
		&"hori_core_protocol_w03",
		&"missing_choice"
	)
	assert_false(rejected.is_valid, "unknown choice should be rejected")
	assert_eq(_state_snapshot(state), before, "rejected event should not mutate campaign state")

	var events: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(NarrativeService.EVENTS_DATA_PATH)
	)
	var mission: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(NarrativeService.MISSION_DATA_PATH)
	)
	var endings: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(NarrativeService.ENDINGS_DATA_PATH)
	)
	events["unknown_key"] = true
	expect_script_error_containing("Chave desconhecida em events_hori_draft.json")
	assert_false(
		narrative.load_data(events, mission, endings),
		"unknown narrative data fields should be rejected"
	)
	assert_eq(narrative.get_event_ids().size(), 8, "invalid reload should preserve loaded event data")


func test_all_endings_are_reachable() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeService = _new_narrative_service(training)
	assert_true(narrative.load_project_data(), "narrative data should load")

	var team_state: TrainingState = training.create_initial_state()
	team_state.week = 8
	team_state.flags[&"final_mission_attempted"] = true
	team_state.flags[&"final_mission_completed"] = true
	team_state.flags[&"final_mission_success"] = true
	team_state.flags[&"final_mission_resolved"] = true
	team_state.mission_stage = 3
	team_state.axes[&"solidarity"] = 15
	team_state.bonds[&"ray"] = 45
	team_state.bonds[&"luppi"] = 45
	assert_eq(
		narrative.resolve_ending(team_state).get("id"),
		"hori_team_guardian",
		"team ending should resolve at its thresholds"
	)

	var career_state: TrainingState = training.create_initial_state()
	career_state.week = 8
	career_state.flags[&"final_mission_attempted"] = true
	career_state.flags[&"final_mission_completed"] = true
	career_state.flags[&"final_mission_success"] = true
	career_state.flags[&"final_mission_resolved"] = true
	career_state.mission_stage = 3
	career_state.stats[&"pot"] = 55
	career_state.stats[&"res"] = 50
	career_state.reputation = 35
	assert_eq(
		narrative.resolve_ending(career_state).get("id"),
		"hori_guardian_command",
		"career ending should resolve independently of bonds"
	)

	var independent_state: TrainingState = training.create_initial_state()
	independent_state.week = 8
	independent_state.flags[&"final_mission_attempted"] = true
	independent_state.flags[&"final_mission_completed"] = true
	independent_state.flags[&"final_mission_resolved"] = true
	independent_state.mission_stage = 3
	independent_state.axes[&"autonomy"] = 15
	assert_eq(
		narrative.resolve_ending(independent_state).get("id"),
		"hori_independent",
		"independent ending should resolve from autonomy"
	)

	var fallback_state: TrainingState = training.create_initial_state()
	fallback_state.week = 9
	fallback_state.flags[&"final_mission_failed_by_deadline"] = true
	fallback_state.flags[&"final_mission_resolved"] = true
	assert_eq(
		narrative.resolve_ending(fallback_state).get("id"),
		"hori_overburdened",
		"fallback ending should resolve when no other condition matches"
	)


func test_endings_and_full_campaign_completion() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")
	var narrative: NarrativeService = _new_narrative_service(training)
	assert_true(narrative.load_project_data(), "narrative data should load")
	var team_state: TrainingState = training.create_initial_state()
	team_state.week = 8
	team_state.flags[&"final_mission_attempted"] = true
	team_state.flags[&"final_mission_completed"] = true
	team_state.flags[&"final_mission_success"] = true
	team_state.flags[&"final_mission_resolved"] = true
	team_state.mission_stage = 3
	team_state.axes[&"solidarity"] = 15
	team_state.bonds[&"ray"] = 45
	team_state.bonds[&"luppi"] = 45
	assert_true(
		narrative.resolve_ending(team_state).get("id") == "hori_team_guardian",
		"highest-priority eligible ending should resolve"
	)

	var state: TrainingState = training.create_initial_state()
	while state.week <= training.get_total_weeks():
		var event: Dictionary = narrative.get_next_event(state)
		while not event.is_empty():
			var choice_id := StringName(event["choices"][0]["id"])
			assert_true(
				narrative.apply_event_choice(
					state,
					StringName(event["id"]),
					choice_id
				).is_valid,
				"scheduled event choice should apply"
			)
			event = narrative.get_next_event(state)
		while narrative.is_mission_due(state):
			var available: Array[StringName] = narrative.get_mission_choice_ids(state)
			assert_true(not available.is_empty(), "mission should not softlock")
			assert_true(
				narrative.apply_mission_choice(state, available[0]).is_valid,
				"mission stage should apply"
			)
		while state.actions_remaining > 0:
			assert_true(training.apply_activity(state, &"rest").is_valid, "rest should close each week")
		if state.week == training.get_total_weeks():
			break
		assert_true(training.advance_week(state), "campaign should advance")
	assert_eq(state.week, 16, "campaign should complete all 16 weeks")
	assert_eq(state.mission_stage, 3, "campaign should complete all mission stages")
	assert_true(state.flags[&"final_mission_attempted"], "campaign should record mission attempt")
	assert_true(state.flags[&"final_mission_completed"], "campaign should record mission completion")
	assert_true(state.flags[&"final_mission_resolved"], "campaign should record mission resolution")
	assert_true(not narrative.resolve_ending(state).is_empty(), "campaign should resolve an ending")
	for event_id: StringName in narrative.get_event_ids():
		assert_true(
			state.flags.get(StringName("%s_seen" % event_id), false),
			"full campaign should resolve %s" % event_id
		)


func _new_narrative_service(training: TrainingService) -> NarrativeService:
	var narrative: NarrativeService = NarrativeServiceScript.new()
	narrative.set_limits(
		training.get_attribute_cap(),
		training.get_resource_cap(),
		training.get_reputation_cap(),
		training.get_bond_cap()
	)
	return narrative


func _state_snapshot(state: TrainingState) -> Dictionary:
	return {
		"week": state.week,
		"actions": state.actions_remaining,
		"stats": state.stats.duplicate(),
		"axes": state.axes.duplicate(),
		"route_state": state.route_state.duplicate(),
		"flags": state.flags.duplicate(),
		"mission_stage": state.mission_stage,
		"rng_seed": state.rng_seed,
		"rng_state": state.rng_state,
		"energy": state.energy,
		"stress": state.stress,
		"motivation": state.motivation,
		"credits": state.credits,
		"reputation": state.reputation,
		"bonds": state.bonds.duplicate(),
		"inventory": state.inventory.duplicate(),
		"equipped_item_id": state.equipped_item_id,
	}

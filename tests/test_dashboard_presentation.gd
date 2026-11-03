@tool
extends McpTestSuite

const DashboardScript = preload("res://scripts/training_dashboard.gd")
const TrainingServiceScript = preload("res://scripts/training_service.gd")
const NarrativeServiceScript = preload("res://scripts/narrative_service.gd")


func suite_name() -> String:
	return "Dashboard Character Presentation"


func test_hori_position_modes_preserve_aspect_and_campaign_state() -> void:
	var training: TrainingService = TrainingServiceScript.new()
	assert_true(training.load_project_data(), "training data should load")

	var dashboard: Control = DashboardScript.new()
	track(dashboard)
	dashboard.set("_service", training)
	dashboard.size = Vector2(1280, 720)
	dashboard.call("_load_phase3_assets")
	dashboard.call("_build_interface")

	var state: TrainingState = training.create_initial_state()
	dashboard.set("_state", state)
	var portrait: TextureRect = dashboard.get("_portrait")
	var stage: Control = dashboard.get("_character_stage")
	stage.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var overlay: Control = dashboard.get("_narrative_overlay")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var hub_ui: Control = dashboard.get("_hub_ui")
	hub_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var hub_profile: Control = dashboard.get("_hub_profile_panel")
	var narrative_panel: PanelContainer = dashboard.get("_narrative_panel")
	var management_ui: Control = dashboard.get("_management_ui")
	var portrait_aspect: float = (
		float(portrait.texture.get_width()) / float(portrait.texture.get_height())
	)
	var action_count: int = state.actions_remaining
	var rng_state: int = state.rng_state
	var stats_before: Dictionary = state.stats.duplicate(true)
	var bonds_before: Dictionary = state.bonds.duplicate(true)
	var viewport_sizes: Array[Vector2] = [
		Vector2(800, 600),
		Vector2(1024, 768),
		Vector2(1280, 720),
		Vector2(1366, 768),
	]

	assert_eq(overlay.z_index, 10, "dialogue UI should render above the character")
	assert_true(hub_ui.visible, "hub should be the initial management screen")
	assert_false(management_ui.visible, "legacy management panels should start hidden")
	for viewport_size: Vector2 in viewport_sizes:
		stage.size = viewport_size
		overlay.size = viewport_size
		hub_ui.size = viewport_size
		dashboard.call("_update_hub_layout")
		assert_true(
			is_equal_approx(
				hub_profile.anchor_bottom,
				0.885 if viewport_size.y <= 640.0 else 0.75
			),
			"hub profile panel should adapt to shorter viewports"
		)
		dashboard.set("_narrative_mode", &"event_dialogue")
		dashboard.call("_hide_narrative_overlay")
		dashboard.call("_update_hori_presentation")
		dashboard.call("_update_narrative_panel_layout")
		assert_true(hub_ui.visible, "hub should be visible outside narrative mode")
		assert_false(management_ui.visible, "legacy management should stay hidden on hub")
		assert_true(
			is_equal_approx(
				narrative_panel.anchor_top,
				0.46 if viewport_size.y < 660.0 else 0.54
			),
			"dialogue dock should adapt to viewport height"
		)
		_assert_character_layout(
			portrait,
			viewport_size,
			portrait_aspect,
			false
		)

		dashboard.call("_show_narrative_overlay")
		dashboard.call("_update_hori_presentation")
		assert_true(overlay.visible, "narrative overlay should be visible in scene mode")
		assert_false(hub_ui.visible, "hub should be hidden in narrative mode")
		assert_false(management_ui.visible, "management UI should be hidden in narrative mode")
		_assert_character_layout(
			portrait,
			viewport_size,
			portrait_aspect,
			true
		)
		dashboard.set("_narrative_mode", &"event_choices")
		dashboard.call("_update_narrative_panel_layout")
		assert_true(
			is_equal_approx(
				narrative_panel.anchor_top,
				0.34 if viewport_size.y < 660.0 else 0.39
			),
			"choice scenes should reserve enough space for decisions"
		)
		dashboard.set("_narrative_mode", &"event_dialogue")

		dashboard.call("_hide_narrative_overlay")
		dashboard.call("_update_hori_presentation")
		assert_false(overlay.visible, "narrative overlay should close")
		assert_true(hub_ui.visible, "hub should return after narrative mode")
		assert_false(management_ui.visible, "legacy management should remain hidden after narrative")
		_assert_character_layout(
			portrait,
			viewport_size,
			portrait_aspect,
			false
		)

	assert_eq(state.actions_remaining, action_count, "presentation should not consume actions")
	assert_eq(state.rng_state, rng_state, "presentation should not advance campaign RNG")
	assert_eq(state.stats, stats_before, "presentation should not change attributes")
	assert_eq(state.bonds, bonds_before, "presentation should not change relationships")
	var hori_sprite_count := 0
	for node: Node in dashboard.find_children("*", "TextureRect", true, false):
		if node is TextureRect and node.texture == portrait.texture:
			hori_sprite_count += 1
	assert_eq(
		hori_sprite_count,
		1,
		"Hori should use one shared sprite node"
	)


func test_hub_navigation_and_state_binding() -> void:
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

	var dashboard: Control = DashboardScript.new()
	track(dashboard)
	dashboard.set("_service", training)
	dashboard.set("_narrative_service", narrative)
	dashboard.size = Vector2(1280, 720)
	dashboard.call("_load_phase3_assets")
	dashboard.call("_build_interface")
	var state: TrainingState = training.create_initial_state()
	dashboard.set("_state", state)
	dashboard.call("_refresh_state")

	var hub_ui: Control = dashboard.get("_hub_ui")
	var management_ui: Control = dashboard.get("_management_ui")
	var nav_buttons: Dictionary[StringName, Button] = dashboard.get("_hub_nav_buttons")
	var hub_back_button: Button = dashboard.get("_hub_back_button")
	var hub_resources: Dictionary[StringName, Label] = dashboard.get("_hub_resource_values")
	var hub_stats: Dictionary[StringName, Label] = dashboard.get("_hub_stat_values")
	var hub_bonds: Dictionary[StringName, Label] = dashboard.get("_hub_bond_values")
	var hub_week_label: Label = dashboard.get("_hub_week_label")
	var hub_actions_label: Label = dashboard.get("_hub_actions_label")
	var hub_credits_label: Label = dashboard.get("_hub_credits_label")
	var hub_progress: ProgressBar = dashboard.get("_hub_semester_progress")
	assert_true(hub_ui.visible, "Hub should be shown initially")
	assert_false(management_ui.visible, "legacy management should not cover the Hub")
	assert_eq(hub_week_label.text, "SEMANA 01 / 16", "week header should come from TrainingState")
	assert_eq(hub_actions_label.text, "BLOCOS 3 / 3", "available actions should come from TrainingState")
	assert_eq(hub_credits_label.text, "CR  50", "credits should come from TrainingState")
	assert_eq(hub_progress.value, 1.0, "semester progress should use the current week")
	assert_eq(hub_resources[&"energy"].text, "75 / 100", "energy should come from TrainingState")
	assert_eq(hub_stats[&"pot"].text, "30", "attributes should come from TrainingState")
	assert_eq(hub_bonds[&"ray"].text, "Ray  30", "bonds should come from TrainingState")
	assert_eq(
		String(dashboard.get("_hub_objective_label").text),
		String(narrative.get_next_event(state).get("title", "Nenhum evento narrativo pendente.")),
		"Hub objective should come from narrative data"
	)

	var rest_result: TrainingPreview = training.apply_activity(state, &"rest")
	assert_true(rest_result.is_valid, "existing rest activity should still apply")
	dashboard.call("_refresh_state")
	assert_eq(
		hub_resources[&"energy"].text,
		"%d / %d" % [state.energy, training.get_resource_cap()],
		"Hub energy indicator should refresh from the updated state"
	)
	assert_eq(
		hub_resources[&"stress"].text,
		"%d / %d" % [state.stress, training.get_resource_cap()],
		"Hub stress indicator should refresh from the updated state"
	)
	assert_eq(
		hub_resources[&"motivation"].text,
		"%d / %d" % [state.motivation, training.get_resource_cap()],
		"Hub motivation indicator should refresh from the updated state"
	)
	assert_eq(
		hub_actions_label.text,
		"BLOCOS 2 / 3",
		"Hub should show the consumed block after training"
	)

	var actions_before: int = state.actions_remaining
	var rng_before: int = state.rng_state
	var stats_before: Dictionary = state.stats.duplicate(true)
	var bonds_before: Dictionary = state.bonds.duplicate(true)
	nav_buttons[&"training"].pressed.emit()
	assert_false(hub_ui.visible, "training navigation should leave the Hub")
	assert_true(management_ui.visible, "training navigation should show existing controls")
	assert_eq(dashboard.get("_current_area"), &"training", "training destination should be tracked")
	hub_back_button.pressed.emit()
	assert_true(hub_ui.visible, "existing management view should provide a return to the Hub")
	nav_buttons[&"status"].pressed.emit()
	assert_eq(dashboard.get("_current_area"), &"status", "status navigation should focus existing stats")
	assert_true(management_ui.visible, "status should reuse the existing management view")
	hub_back_button.pressed.emit()
	nav_buttons[&"relationships"].pressed.emit()
	assert_eq(
		dashboard.get("_current_area"),
		&"relationships",
		"relationships navigation should focus existing bonds"
	)
	hub_back_button.pressed.emit()
	assert_eq(state.actions_remaining, actions_before, "navigation should not consume actions")
	assert_eq(state.rng_state, rng_before, "navigation should not advance campaign RNG")
	assert_eq(state.stats, stats_before, "navigation should not alter attributes")
	assert_eq(state.bonds, bonds_before, "navigation should not alter relationships")

	var actions_before_event: int = state.actions_remaining
	dashboard.call("_process_narrative_flow")
	assert_true(
		(dashboard.get("_narrative_overlay") as Control).visible,
		"pending narrative should open above the Hub"
	)
	assert_false(hub_ui.visible, "narrative should hide the Hub")
	for dialogue_step: int in range(32):
		if dashboard.get("_narrative_mode") != &"event_dialogue":
			break
		dashboard.call("_on_narrative_continue_pressed")
	assert_eq(
		dashboard.get("_narrative_mode"),
		&"event_choices",
		"narrative dialogue should proceed to its existing choices"
	)
	var event: Dictionary = dashboard.get("_active_event")
	var choices: Array = event["choices"]
	dashboard.call(
		"_on_narrative_choice_pressed",
		StringName(choices[0]["id"])
	)
	assert_eq(
		dashboard.get("_narrative_mode"),
		&"event_result",
		"existing narrative choice should resolve normally"
	)
	dashboard.call("_on_narrative_continue_pressed")
	assert_true(hub_ui.visible, "completing an event should return to the Hub")
	assert_false(
		(dashboard.get("_narrative_overlay") as Control).visible,
		"event result should close after continuing"
	)
	assert_eq(
		state.actions_remaining,
		actions_before_event,
		"narrative flow should not consume training actions"
	)


func _assert_character_layout(
	portrait: TextureRect,
	viewport_size: Vector2,
	expected_aspect: float,
	centered: bool
) -> void:
	var sprite_rect := Rect2(portrait.position, portrait.size)
	var sprite_center: float = sprite_rect.position.x + sprite_rect.size.x * 0.5
	var expected_center: float = viewport_size.x * 0.5

	assert_true(sprite_rect.position.x >= 0.0, "sprite should remain inside the viewport")
	assert_true(sprite_rect.position.y >= 0.0, "sprite should not crop above the viewport")
	assert_true(sprite_rect.end.x <= viewport_size.x + 0.1, "sprite should not crop horizontally")
	assert_true(
		is_equal_approx(sprite_rect.end.y, viewport_size.y),
		"sprite should remain anchored to the bottom"
	)
	assert_true(
		is_equal_approx(sprite_rect.size.x / sprite_rect.size.y, expected_aspect),
		"sprite proportions should be preserved"
	)
	if centered:
		assert_true(
			is_equal_approx(sprite_center, expected_center),
			"sprite should be horizontally centered in narrative mode"
		)
	else:
		assert_true(
			sprite_rect.position.x >= expected_center - 0.1,
			"sprite should stay on the right in management mode"
		)

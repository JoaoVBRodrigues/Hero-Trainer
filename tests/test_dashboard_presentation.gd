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
	var training_ui: Control = dashboard.get("_training_ui")
	var management_ui: Control = dashboard.get("_management_ui")
	var nav_buttons: Dictionary[StringName, Button] = dashboard.get("_hub_nav_buttons")
	var training_nav: Dictionary[StringName, Button] = dashboard.get("_training_nav_buttons")
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
	assert_true(training_ui.visible, "training navigation should show the redesigned screen")
	assert_false(management_ui.visible, "training should not show the legacy dashboard")
	assert_eq(dashboard.get("_current_area"), &"training", "training destination should be tracked")
	training_nav[&"hub"].pressed.emit()
	assert_true(hub_ui.visible, "redesigned training should provide a return to the Hub")
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


func test_training_screen_previews_and_applies_service_results() -> void:
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
	training.set_random_seed(1)
	var state: TrainingState = training.create_initial_state()
	dashboard.set("_state", state)
	dashboard.call("_refresh_state")

	var hub_ui: Control = dashboard.get("_hub_ui")
	var training_ui: Control = dashboard.get("_training_ui")
	var management_ui: Control = dashboard.get("_management_ui")
	var activity_cards: Dictionary[StringName, Button] = dashboard.get("_training_cards")
	var effect_labels: Dictionary[StringName, Label] = dashboard.get("_training_card_effects")
	var status_labels: Dictionary[StringName, Label] = dashboard.get("_training_card_status")
	var training_nav: Dictionary[StringName, Button] = dashboard.get("_training_nav_buttons")
	var category_counts: Dictionary[String, int] = {}
	var rng_before: int = state.rng_state
	var actions_before: int = state.actions_remaining
	var stats_before: Dictionary = state.stats.duplicate(true)
	var bonds_before: Dictionary = state.bonds.duplicate(true)
	var energy_before: int = state.energy
	var stress_before: int = state.stress
	var motivation_before: int = state.motivation
	var credits_before: int = state.credits
	var viewport_sizes: Array[Vector2] = [
		Vector2(800, 600),
		Vector2(1024, 768),
		Vector2(1280, 720),
		Vector2(1366, 768),
	]
	var activity_panel: PanelContainer = training_ui.get_child(1)
	var planning_panel: PanelContainer = training_ui.get_child(2)
	var training_scrolls: Array[Node] = training_ui.find_children(
		"*",
		"ScrollContainer",
		true,
		false
	)
	assert_eq(training_scrolls.size(), 1, "training activities should use localized scrolling")
	assert_eq(
		(training_scrolls[0] as ScrollContainer).horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_DISABLED,
		"activity cards should not require horizontal scrolling"
	)

	assert_eq(activity_cards.size(), 8, "all configured activities should have a card")
	for activity_id: StringName in training.get_activity_ids():
		var category: String = training.get_activity_category(activity_id)
		category_counts[category] = int(category_counts.get(category, 0)) + 1
		assert_eq(
			activity_cards[activity_id].get_meta("category"),
			category,
			"activity cards should retain their configured category"
		)
		assert_true(
			not effect_labels[activity_id].text.is_empty(),
			"each available activity should expose its effects before selection"
		)
	assert_eq(category_counts["training"], 4, "four training cards should be grouped")
	assert_eq(category_counts["recovery"], 1, "the recovery activity should be grouped")
	assert_eq(category_counts["work"], 1, "the work activity should be grouped")
	assert_eq(category_counts["relationship"], 2, "relationship activities should be grouped")
	assert_eq(state.rng_state, rng_before, "building card previews should not advance RNG")

	training_nav[&"training"].pressed.emit()
	assert_true(training_ui.visible, "Hub navigation should open the redesigned training screen")
	assert_false(management_ui.visible, "legacy dashboard should not cover redesigned training")
	assert_false(hub_ui.visible, "the Hub should be hidden while training")
	assert_eq(dashboard.get("_current_area"), &"training", "training area should be tracked")
	training_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	for viewport_size: Vector2 in viewport_sizes:
		training_ui.size = viewport_size
		dashboard.call("_update_training_layout")
		assert_true(
			activity_panel.anchor_left >= 0.0
			and activity_panel.anchor_right <= 1.0
			and planning_panel.anchor_left >= 0.0
			and planning_panel.anchor_right <= 1.0,
			"training panels should remain within the viewport"
		)
		assert_true(
			activity_cards[&"combat"].custom_minimum_size.y >= 50.0,
			"activity cards should retain a readable minimum height"
		)
	assert_eq(state.rng_state, rng_before, "resizing the screen should not advance RNG")

	dashboard.call("_on_activity_selected", &"control")
	var preview_status: Label = dashboard.get("_training_preview_status")
	var success_panel: PanelContainer = dashboard.get("_training_success_panel")
	var failure_panel: PanelContainer = dashboard.get("_training_failure_panel")
	assert_true(success_panel.visible, "risky preview should show its success scenario")
	assert_true(failure_panel.visible, "risky preview should show its failure scenario")
	assert_true(preview_status.text.contains("RISCO"), "risky preview should identify its risk")
	assert_true(
		status_labels[&"control"].text.contains("SUCESSO")
		and status_labels[&"control"].text.contains("FALHA"),
		"risky activity cards should identify both success and failure chances"
	)
	assert_eq(state.actions_remaining, actions_before, "preview should not consume a block")
	assert_eq(state.rng_state, rng_before, "preview should not advance RNG")
	assert_eq(state.stats, stats_before, "preview should not change attributes")
	assert_eq(state.bonds, bonds_before, "preview should not change relationships")
	assert_eq(state.energy, energy_before, "preview should not consume energy")
	assert_eq(state.stress, stress_before, "preview should not change stress")
	assert_eq(state.motivation, motivation_before, "preview should not change motivation")
	assert_eq(state.credits, credits_before, "preview should not change credits")

	dashboard.call("_on_cancel_pressed")
	assert_eq(state.actions_remaining, actions_before, "cancel should preserve available blocks")
	assert_eq(state.rng_state, rng_before, "cancel should preserve RNG")
	assert_eq(state.stats, stats_before, "cancel should preserve attributes")

	state.energy = 5
	dashboard.call("_refresh_state")
	dashboard.call("_on_activity_selected", &"combat")
	var training_confirm: Button = dashboard.get("_training_confirm_button")
	assert_true(training_confirm.disabled, "insufficient energy should disable confirmation")
	assert_true(
		status_labels[&"combat"].text.contains("BLOQUEADA"),
		"blocked activity should be visibly identified on its card"
	)
	assert_true(
		effect_labels[&"combat"].text.begins_with("SE DISPONÍVEL"),
		"blocked activity should still expose its service-derived effects"
	)
	assert_eq(state.actions_remaining, actions_before, "blocked preview should preserve blocks")
	assert_eq(state.rng_state, rng_before, "blocked preview should preserve RNG")

	state.energy = 75
	dashboard.call("_refresh_state")
	dashboard.call("_on_activity_selected", &"rest")
	assert_true(
		preview_status.text.contains("DISPONÍVEL"),
		"deterministic recovery should be available without a risk roll"
	)
	assert_eq(state.rng_state, rng_before, "deterministic preview should not advance RNG")
	assert_eq(state.actions_remaining, actions_before, "deterministic preview should not consume a block")
	dashboard.call("_on_cancel_pressed")
	dashboard.call("_on_activity_selected", &"control")
	dashboard.call("_on_confirm_pressed")
	assert_eq(state.actions_remaining, actions_before - 1, "confirmation should consume one block")
	assert_ne(state.rng_state, rng_before, "confirmation should perform the risky activity roll")
	assert_true(
		preview_status.text == "RESULTADO · SUCESSO",
		"seeded confirmation should show its successful result"
	)
	assert_true(
		String(dashboard.get("_training_result_label").text).contains("Blocos restantes: 2 / 3"),
		"result should show the remaining action blocks"
	)
	assert_eq(
		String(dashboard.get("_training_actions_label").text),
		"BLOCOS 2 / 3",
		"header should synchronize from TrainingState after application"
	)
	var overlay: Control = dashboard.get("_narrative_overlay")
	assert_true(overlay.visible, "a due narrative event should take priority after training")
	assert_false(training_ui.visible, "narrative should cover the training screen")
	var actions_before_event: int = state.actions_remaining
	for dialogue_step: int in range(32):
		if dashboard.get("_narrative_mode") != &"event_dialogue":
			break
		dashboard.call("_on_narrative_continue_pressed")
	assert_eq(
		dashboard.get("_narrative_mode"),
		&"event_choices",
		"training should preserve the existing narrative dialogue flow"
	)
	var event: Dictionary = dashboard.get("_active_event")
	var choices: Array = event["choices"]
	dashboard.call("_on_narrative_choice_pressed", StringName(choices[0]["id"]))
	assert_eq(
		dashboard.get("_narrative_mode"),
		&"event_result",
		"narrative choices should still resolve after training"
	)
	dashboard.call("_on_narrative_continue_pressed")
	assert_true(hub_ui.visible, "closing the event should return to the Hub")
	assert_false(training_ui.visible, "training should remain hidden after the event")
	assert_eq(
		state.actions_remaining,
		actions_before_event,
		"narrative event should not consume another training block"
	)

	var nav_buttons: Dictionary[StringName, Button] = dashboard.get("_hub_nav_buttons")
	nav_buttons[&"training"].pressed.emit()
	training.set_random_seed(60)
	state = training.create_initial_state()
	dashboard.set("_state", state)
	dashboard.call("_refresh_state")
	dashboard.call("_on_activity_selected", &"control")
	var stats_before_failure: Dictionary = state.stats.duplicate(true)
	overlay.visible = true
	dashboard.call("_on_confirm_pressed")
	overlay.visible = false
	assert_eq(
		preview_status.text,
		"RESULTADO · FALHA",
		"seeded confirmation should show its failed result"
	)
	assert_eq(state.stats, stats_before_failure, "failure should not apply attribute gains")
	assert_eq(state.actions_remaining, 2, "failed activity should consume one action block")
	assert_true(
		String(dashboard.get("_training_result_label").text).contains("EN -13")
		and String(dashboard.get("_training_result_label").text).contains("EST +5"),
		"failure result should show costs that still apply"
	)

	var rng_before_deterministic: int = state.rng_state
	dashboard.call("_on_activity_selected", &"rest")
	overlay.visible = true
	dashboard.call("_on_confirm_pressed")
	overlay.visible = false
	assert_eq(
		preview_status.text,
		"RESULTADO · DETERMINÍSTICO",
		"deterministic confirmation should be identified separately"
	)
	assert_eq(state.actions_remaining, 1, "deterministic activity should consume one block")
	assert_eq(
		state.rng_state,
		rng_before_deterministic,
		"deterministic confirmation should not advance RNG"
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

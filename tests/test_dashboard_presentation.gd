@tool
extends McpTestSuite

const DashboardScript = preload("res://scripts/training_dashboard.gd")
const DashboardScene = preload("res://scenes/training_dashboard.tscn")
const TrainingServiceScript = preload("res://scripts/training_service.gd")
const NarrativeServiceScript = preload("res://scripts/narrative_service.gd")


func suite_name() -> String:
	return "Dashboard Character Presentation"


func test_campaign_launch_shows_hub_before_narrative() -> void:
	var dashboard: Control = DashboardScene.instantiate()
	track(dashboard)
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(dashboard)
	assert_true(
		(dashboard.get("_hub_ui") as Control).visible,
		"campaign launch should show the Hub as its initial screen"
	)
	assert_false(
		(dashboard.get("_narrative_overlay") as Control).visible,
		"campaign launch should not immediately cover the Hub with dialogue"
	)
	assert_eq(
		dashboard.get("_current_area"),
		&"hub",
		"campaign should start in the Hub area"
	)


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
		_finish_narrative_transition(dashboard, false)
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
	var status_ui: Control = dashboard.get("_status_ui")
	var relationships_ui: Control = dashboard.get("_relationships_ui")
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
	assert_eq(
		dashboard.get("_current_area"),
		&"status",
		"status navigation should open its independent screen"
	)
	assert_true(status_ui.visible, "status navigation should open the standalone Status")
	assert_false(management_ui.visible, "status should not reuse the legacy management view")
	hub_back_button.pressed.emit()
	nav_buttons[&"relationships"].pressed.emit()
	assert_eq(
		dashboard.get("_current_area"),
		&"relationships",
		"relationships navigation should open the independent relationships screen"
	)
	assert_true(relationships_ui.visible, "relationships should have its own screen")
	assert_false(management_ui.visible, "relationships should not show legacy management")
	assert_false(status_ui.visible, "relationships should replace the Status screen")
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
	_finish_narrative_transition(dashboard, false)
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


func test_status_screen_is_independent_and_reads_campaign_state() -> void:
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
	var status_ui: Control = dashboard.get("_status_ui")
	var management_ui: Control = dashboard.get("_management_ui")
	var nav_buttons: Dictionary[StringName, Button] = dashboard.get("_hub_nav_buttons")
	var status_nav: Dictionary[StringName, Button] = dashboard.get("_status_nav_buttons")
	var stat_values: Dictionary[StringName, Label] = dashboard.get("_status_stat_values")
	var stat_bars: Dictionary[StringName, ProgressBar] = dashboard.get("_status_stat_bars")
	var resource_values: Dictionary[StringName, Label] = dashboard.get(
		"_status_resource_values"
	)
	var resource_bars: Dictionary[StringName, ProgressBar] = dashboard.get(
		"_status_resource_bars"
	)
	var portrait: TextureRect = dashboard.get("_portrait")
	var stage: Control = dashboard.get("_character_stage")
	var status_scroll: ScrollContainer = dashboard.get("_status_scroll")
	var viewport_sizes: Array[Vector2] = [
		Vector2(800, 600),
		Vector2(1024, 768),
		Vector2(1280, 720),
		Vector2(1366, 768),
	]
	assert_false(status_ui.visible, "status should not replace the initial Hub")
	assert_false(management_ui.visible, "legacy management should remain hidden")

	nav_buttons[&"status"].pressed.emit()
	assert_true(status_ui.visible, "Hub navigation should open the standalone Status")
	assert_false(hub_ui.visible, "Status should replace the Hub")
	assert_false(training_ui.visible, "Status should replace the training screen")
	assert_false(management_ui.visible, "Status should not reveal legacy management panels")
	assert_eq(dashboard.get("_current_area"), &"status", "Status should track its navigation area")
	assert_eq(
		String(dashboard.get("_status_profile_label").text).split("  ·  ").size(),
		4,
		"profile summary should use the existing canonical character facts"
	)
	assert_eq(
		String(dashboard.get("_status_credits_value").text),
		str(state.credits),
		"credits should be presented from TrainingState without an invented cap"
	)
	assert_eq(
		String(dashboard.get("_status_reputation_value").text),
		"%d / %d" % [state.reputation, training.get_reputation_cap()],
		"reputation should include its service-provided cap"
	)
	assert_eq(
		String(dashboard.get("_status_week_label").text),
		"SEMANA %02d / %02d" % [state.week, training.get_total_weeks()],
		"current and total weeks should come from the campaign state and service"
	)
	assert_eq(
		int((dashboard.get("_status_semester_progress") as ProgressBar).value),
		state.week,
		"semester progress should track the campaign week"
	)
	assert_eq(
		String(dashboard.get("_status_actions_label").text),
		"%d / %d AÇÕES" % [state.actions_remaining, training.get_actions_per_week()],
		"remaining action blocks should come from TrainingState"
	)
	assert_eq(stat_values.size(), TrainingState.ATTRIBUTE_IDS.size())
	assert_eq(stat_bars.size(), TrainingState.ATTRIBUTE_IDS.size())
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		assert_eq(
			stat_values[stat_id].text,
			"%d / %d" % [state.stats[stat_id], training.get_attribute_cap()],
			"status attribute value should match TrainingState"
		)
		assert_eq(
			int(stat_bars[stat_id].value),
			state.stats[stat_id],
			"status attribute bar should match TrainingState"
		)
		assert_eq(
			int(stat_bars[stat_id].max_value),
			training.get_attribute_cap(),
			"status attribute bar should use the service cap"
		)
	for resource_id: StringName in [&"energy", &"stress", &"motivation"]:
		assert_eq(
			resource_values[resource_id].text,
			"%d / %d" % [
				dashboard.call("_training_resource_value", state, resource_id),
				training.get_resource_cap(),
			],
			"condition values should match TrainingState"
		)
		assert_eq(
			int(resource_bars[resource_id].value),
			dashboard.call("_training_resource_value", state, resource_id),
			"condition bars should match TrainingState"
		)
		assert_eq(
			int(resource_bars[resource_id].max_value),
			training.get_resource_cap(),
			"condition bars should use the service cap"
		)

	var rng_before: int = state.rng_state
	state.stats[&"pot"] = 77
	state.energy = 18
	state.stress = 88
	state.motivation = 23
	state.credits = 126
	state.reputation = 42
	state.week = 6
	state.actions_remaining = 1
	var state_after_mutation: TrainingState = state.duplicate_state()
	dashboard.call("_refresh_state")
	assert_eq(stat_values[&"pot"].text, "77 / 100", "updated attributes should refresh")
	assert_eq(int(stat_bars[&"pot"].value), 77, "updated attribute bars should refresh")
	assert_eq(resource_values[&"energy"].text, "18 / 100", "low energy should be visible")
	assert_eq(resource_values[&"stress"].text, "88 / 100", "high stress should be visible")
	assert_eq(resource_values[&"motivation"].text, "23 / 100", "motivation should refresh")
	assert_eq(int(resource_bars[&"energy"].value), 18)
	assert_eq(int(resource_bars[&"stress"].value), 88)
	assert_eq(int(resource_bars[&"motivation"].value), 23)
	assert_eq(String(dashboard.get("_status_credits_value").text), "126")
	assert_eq(String(dashboard.get("_status_reputation_value").text), "42 / 100")
	assert_eq(String(dashboard.get("_status_week_label").text), "SEMANA 06 / 16")
	assert_eq(
		String(dashboard.get("_status_actions_label").text),
		"1 / 3 AÇÕES"
	)

	status_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	stage.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	for viewport_size: Vector2 in viewport_sizes:
		status_ui.size = viewport_size
		stage.size = viewport_size
		dashboard.call("_update_status_layout")
		dashboard.call("_update_hori_presentation")
		assert_eq(
			_status_attribute_columns(dashboard),
			2 if viewport_size.x < 1000.0 else 3,
			"attribute cards should adapt their columns to the viewport width"
		)
		assert_eq(
			status_scroll.horizontal_scroll_mode,
			ScrollContainer.SCROLL_MODE_DISABLED,
			"Status should use localized vertical scrolling only"
		)
		assert_true(
			(status_ui.get_child(0) as Control).anchor_left >= 0.0
			and (status_ui.get_child(0) as Control).anchor_right <= 1.0,
			"status header should remain inside the viewport"
		)
		assert_true(
			(status_ui.get_child(status_ui.get_child_count() - 1) as Control).anchor_right
			<= 1.0,
			"status navigation should remain inside the viewport"
		)
		assert_true(
			is_zero_approx(portrait.position.x),
			"the shared Hori portrait should frame Status from the left"
		)
		assert_true(
			is_equal_approx(
				portrait.size.x / portrait.size.y,
				float(portrait.texture.get_width())
				/ float(portrait.texture.get_height())
			),
			"the Hori portrait should preserve its aspect ratio in Status"
		)

	assert_eq(state.stats, state_after_mutation.stats, "Status should not alter stats")
	assert_eq(state.axes, state_after_mutation.axes, "Status should not alter narrative axes")
	assert_eq(
		state.route_state,
		state_after_mutation.route_state,
		"Status should not alter route state"
	)
	assert_eq(state.bonds, state_after_mutation.bonds, "Status should not alter bonds")
	assert_eq(state.energy, state_after_mutation.energy)
	assert_eq(state.stress, state_after_mutation.stress)
	assert_eq(state.motivation, state_after_mutation.motivation)
	assert_eq(state.credits, state_after_mutation.credits)
	assert_eq(state.reputation, state_after_mutation.reputation)
	assert_eq(state.actions_remaining, state_after_mutation.actions_remaining)
	assert_eq(state.week, state_after_mutation.week)
	assert_eq(state.rng_state, rng_before, "Status should not advance campaign RNG")

	status_nav[&"hub"].pressed.emit()
	assert_true(hub_ui.visible, "Status navigation should return to the Hub")
	assert_false(status_ui.visible, "Status should hide after returning to the Hub")
	nav_buttons[&"status"].pressed.emit()
	assert_true(status_ui.visible, "the Hub should reopen the current Status view")
	dashboard.call("_show_narrative_overlay")
	assert_true(
		(dashboard.get("_narrative_overlay") as Control).visible,
		"narrative should retain priority over Status"
	)
	assert_false(status_ui.visible, "narrative presentation should hide Status")
	dashboard.call("_on_hub_navigation_pressed", &"training")
	assert_eq(
		dashboard.get("_current_area"),
		&"status",
		"navigation should not change areas while a narrative event is active"
	)
	dashboard.call("_hide_narrative_overlay")
	assert_true(hub_ui.visible, "closing the narrative should preserve its Hub return behavior")
	assert_false(status_ui.visible, "narrative close should not leave Status visible")


func test_relationships_screen_tracks_existing_bonds_and_shortcuts() -> void:
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
	var status_ui: Control = dashboard.get("_status_ui")
	var relationships_ui: Control = dashboard.get("_relationships_ui")
	var legacy_ui: Control = dashboard.get("_management_ui")
	var hub_navigation: Dictionary[StringName, Button] = dashboard.get("_hub_nav_buttons")
	var training_navigation: Dictionary[StringName, Button] = dashboard.get(
		"_training_nav_buttons"
	)
	var relationship_navigation: Dictionary[StringName, Button] = dashboard.get(
		"_relationship_nav_buttons"
	)
	var name_labels: Dictionary[StringName, Label] = dashboard.get(
		"_relationship_name_labels"
	)
	var cards: Dictionary[StringName, Dictionary] = dashboard.get("_relationship_cards")
	var shortcuts: Dictionary[StringName, Button] = dashboard.get(
		"_relationship_activity_buttons"
	)
	var viewport_sizes: Array[Vector2] = [
		Vector2(800, 600),
		Vector2(1024, 768),
		Vector2(1280, 720),
		Vector2(1366, 768),
	]
	assert_false(relationships_ui.visible, "the Hub should remain the initial screen")
	hub_navigation[&"relationships"].pressed.emit()
	assert_true(relationships_ui.visible, "Hub navigation should open Relationships")
	assert_false(legacy_ui.visible, "Relationships should be independent of legacy management")
	assert_false(hub_ui.visible, "Relationships should replace the Hub")
	assert_false(status_ui.visible, "Relationships should replace Status")
	assert_eq(dashboard.get("_current_area"), &"relationships")
	assert_eq(name_labels.size(), 3, "the three existing relationships should be shown")
	assert_eq(name_labels[&"ray"].text, "Ray")
	assert_eq(name_labels[&"luppi"].text, "Luppi")
	assert_eq(name_labels[&"instructor"].text, "Instrutor")
	assert_eq(cards.size(), training.get_bond_ids().size())
	for bond_id: StringName in training.get_bond_ids():
		var card: Dictionary = cards[bond_id]
		assert_eq(
			(card["value"] as Label).text,
			"%d / %d" % [state.bonds[bond_id], training.get_bond_cap()],
			"relationship values should come from TrainingState"
		)
		assert_eq(
			int((card["bar"] as ProgressBar).value),
			state.bonds[bond_id],
			"relationship bars should track TrainingState"
		)
		assert_eq(
			int((card["bar"] as ProgressBar).max_value),
			training.get_bond_cap(),
			"relationship bars should use the TrainingService limit"
		)
		assert_eq(
			(card["remaining"] as Label).text,
			"%d até o limite" % (training.get_bond_cap() - state.bonds[bond_id]),
			"cards should communicate the remaining distance to the limit"
		)
	var ray_style: StyleBoxFlat = (
		(cards[&"ray"]["panel"] as PanelContainer).get_theme_stylebox("panel")
		as StyleBoxFlat
	)
	var luppi_style: StyleBoxFlat = (
		(cards[&"luppi"]["panel"] as PanelContainer).get_theme_stylebox("panel")
		as StyleBoxFlat
	)
	var instructor_style: StyleBoxFlat = (
		(cards[&"instructor"]["panel"] as PanelContainer).get_theme_stylebox("panel")
		as StyleBoxFlat
	)
	assert_ne(ray_style.border_color, luppi_style.border_color)
	assert_ne(ray_style.border_color, instructor_style.border_color)
	assert_ne(luppi_style.border_color, instructor_style.border_color)
	assert_true(
		String(name_labels[&"ray"].get_parent().get_parent().get_child(1).text)
		.contains("chifres por mutação"),
		"Ray's profile should rely on approved character facts"
	)
	assert_true(
		String(name_labels[&"luppi"].get_parent().get_parent().get_child(1).text)
		.contains("Garota-rato"),
		"Luppi's profile should rely on approved character facts"
	)
	assert_true(
		String(name_labels[&"instructor"].get_parent().get_parent().get_child(1).text)
		.contains("não especificado"),
		"the UI should not invent an instructor profile"
	)
	assert_eq(shortcuts.size(), 2, "only the two configured social activities should be linked")
	assert_eq(
		String(shortcuts[&"bond_ray"].get_meta("activity_id")),
		"bond_ray"
	)
	assert_eq(
		String(shortcuts[&"bond_luppi"].get_meta("activity_id")),
		"bond_luppi"
	)

	var state_before_navigation: TrainingState = state.duplicate_state()
	var rng_before: int = state.rng_state
	for viewport_size: Vector2 in viewport_sizes:
		relationships_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		relationships_ui.size = viewport_size
		dashboard.call("_update_hori_presentation")
		assert_eq(
			(dashboard.get("_relationships_scroll") as ScrollContainer).horizontal_scroll_mode,
			ScrollContainer.SCROLL_MODE_DISABLED,
			"Relationships should not require horizontal scrolling"
		)
		assert_true(
			(relationships_ui.get_child(0) as Control).anchor_left >= 0.0
			and (relationships_ui.get_child(0) as Control).anchor_right <= 1.0,
			"relationship header should remain inside the viewport"
		)
		assert_true(
			is_zero_approx((dashboard.get("_portrait") as TextureRect).position.x),
			"the shared character portrait should remain left of the relationship cards"
		)
	assert_eq(state.actions_remaining, state_before_navigation.actions_remaining)
	assert_eq(state.week, state_before_navigation.week)
	assert_eq(state.stats, state_before_navigation.stats)
	assert_eq(state.energy, state_before_navigation.energy)
	assert_eq(state.stress, state_before_navigation.stress)
	assert_eq(state.motivation, state_before_navigation.motivation)
	assert_eq(state.credits, state_before_navigation.credits)
	assert_eq(state.reputation, state_before_navigation.reputation)
	assert_eq(state.bonds, state_before_navigation.bonds)
	assert_eq(state.rng_state, rng_before, "opening and resizing should not advance RNG")

	shortcuts[&"bond_ray"].pressed.emit()
	assert_true(training_ui.visible, "Ray shortcut should open the training screen")
	assert_false(relationships_ui.visible)
	assert_eq(dashboard.get("_selected_activity"), &"", "shortcut should not confirm or select an activity")
	assert_eq(
		state.actions_remaining,
		state_before_navigation.actions_remaining,
		"shortcut should not consume an action"
	)
	assert_true(
		training.apply_activity(state, &"bond_ray").is_valid,
		"the existing Ray social activity should remain service-owned"
	)
	dashboard.call("_refresh_state")
	relationship_navigation[&"relationships"].pressed.emit()
	assert_eq(
		(cards[&"ray"]["value"] as Label).text,
		"%d / %d" % [state.bonds[&"ray"], training.get_bond_cap()],
		"Ray's bond should refresh after the existing social activity"
	)
	assert_eq(
		state.bonds[&"ray"],
		int(state_before_navigation.bonds[&"ray"]) + 8,
		"Ray's increase should come from the configured activity"
	)

	shortcuts[&"bond_luppi"].pressed.emit()
	assert_true(training_ui.visible, "Luppi shortcut should open the training screen")
	assert_eq(dashboard.get("_selected_activity"), &"")
	assert_true(
		training.apply_activity(state, &"bond_luppi").is_valid,
		"the existing Luppi social activity should remain service-owned"
	)
	dashboard.call("_refresh_state")
	hub_navigation[&"relationships"].pressed.emit()
	assert_eq(
		(cards[&"luppi"]["value"] as Label).text,
		"%d / %d" % [state.bonds[&"luppi"], training.get_bond_cap()],
		"Luppi's bond should refresh from the current campaign state"
	)
	assert_eq(
		state.bonds[&"luppi"],
		int(state_before_navigation.bonds[&"luppi"]) + 8,
		"Luppi's increase should come from the configured activity"
	)

	var relationship_snapshot: TrainingState = state.duplicate_state()
	dashboard.call("_show_narrative_overlay")
	assert_false(relationships_ui.visible, "narrative should cover the relationships screen")
	hub_navigation[&"training"].pressed.emit()
	assert_eq(
		dashboard.get("_current_area"),
		&"relationships",
		"narrative should prevent relationship navigation"
	)
	dashboard.call("_hide_narrative_overlay")
	assert_true(hub_ui.visible, "narrative completion should retain its Hub return")
	assert_eq(state.stats, relationship_snapshot.stats)
	assert_eq(state.energy, relationship_snapshot.energy)
	assert_eq(state.stress, relationship_snapshot.stress)
	assert_eq(state.motivation, relationship_snapshot.motivation)
	assert_eq(state.credits, relationship_snapshot.credits)
	assert_eq(state.reputation, relationship_snapshot.reputation)
	assert_eq(state.actions_remaining, relationship_snapshot.actions_remaining)
	assert_eq(state.week, relationship_snapshot.week)
	assert_eq(state.bonds, relationship_snapshot.bonds)
	assert_eq(state.rng_state, relationship_snapshot.rng_state)


func _status_attribute_columns(dashboard: Control) -> int:
	var grid: GridContainer = dashboard.get("_status_attribute_grid")
	return grid.columns


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
	_finish_narrative_transition(dashboard, false)
	assert_true(hub_ui.visible, "closing the event should return to the Hub")
	assert_false(training_ui.visible, "training should remain hidden after the event")
	var status_bars: Dictionary[StringName, ProgressBar] = dashboard.get(
		"_status_stat_bars"
	)
	for stat_id: StringName in TrainingState.ATTRIBUTE_IDS:
		assert_eq(
			int(status_bars[stat_id].value),
			int(state.stats[stat_id]),
			"result animations should finish exactly at the service state"
		)
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


func test_ui_motion_feedback_and_navigation_preserve_campaign_state() -> void:
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

	var state_before: TrainingState = state.duplicate_state()
	var nav_buttons: Dictionary[StringName, Button] = dashboard.get("_hub_nav_buttons")
	var transition_overlay: Control = dashboard.get("_transition_overlay")
	var target_areas: Dictionary[StringName, Control] = {
		&"training": dashboard.get("_training_ui"),
		&"status": dashboard.get("_status_ui"),
		&"relationships": dashboard.get("_relationships_ui"),
		&"hub": dashboard.get("_hub_ui"),
	}
	for area: StringName in [
		&"training",
		&"status",
		&"relationships",
		&"hub",
	]:
		nav_buttons[area].pressed.emit()
		assert_eq(
			dashboard.get("_current_area"),
			area,
			"navigation should update the selected area immediately"
		)
		assert_true(
			(target_areas[area] as Control).visible,
			"the requested area should be visible during its transition"
		)
		var visible_area_count: int = 0
		for screen: Control in target_areas.values():
			if screen.visible:
				visible_area_count += 1
		assert_eq(
			visible_area_count,
			1,
			"rapid navigation should never leave multiple areas interactive"
		)
		assert_true(
			transition_overlay.visible,
			"area changes should show the short transition blocker"
		)

	_finish_area_transition(dashboard)
	assert_false(
		transition_overlay.visible,
		"the transition blocker should release the interface when the fade ends"
	)
	assert_eq(state.stats, state_before.stats)
	assert_eq(state.axes, state_before.axes)
	assert_eq(state.bonds, state_before.bonds)
	assert_eq(state.energy, state_before.energy)
	assert_eq(state.actions_remaining, state_before.actions_remaining)
	assert_eq(state.week, state_before.week)
	assert_eq(state.rng_state, state_before.rng_state)

	var activity_cards: Dictionary[StringName, Button] = dashboard.get("_training_cards")
	var button: Button = activity_cards[&"control"]
	assert_true(
		button.has_meta("ui_feedback_wired"),
		"training activity cards should use the shared button feedback"
	)
	var button_theme: Theme = dashboard.theme
	assert_true(
		button_theme.has_stylebox("focus", "Button"),
		"the shared theme should expose a keyboard focus style"
	)
	var focus_style: StyleBoxFlat = button_theme.get_stylebox(
		"focus",
		"Button"
	) as StyleBoxFlat
	assert_true(
		focus_style.get_border_width(SIDE_LEFT) > 0
		and focus_style.border_color.a > 0.9,
		"keyboard focus should retain a visible outline"
	)
	dashboard.call("_on_button_feedback_changed", button, &"hovered", true)
	assert_ne(
		button.get_meta("ui_feedback_hovered"),
		false,
		"hover feedback should track pointer focus"
	)
	assert_true(
		(button.get_meta("ui_feedback_tween") as Tween).is_running(),
		"hover feedback should use a short reusable Tween"
	)
	dashboard.call("_on_button_feedback_changed", button, &"hovered", false)

	nav_buttons[&"training"].pressed.emit()
	_finish_area_transition(dashboard)
	dashboard.call("_on_activity_selected", &"control")
	assert_true(button.button_pressed, "selected training should use its pressed card state")
	assert_eq(state.actions_remaining, state_before.actions_remaining)
	assert_eq(state.rng_state, state_before.rng_state)
	assert_eq(state.stats, state_before.stats)

	var bond_state_before: TrainingState = state.duplicate_state()
	var bond_result: TrainingPreview = training.apply_activity(state, &"bond_ray")
	assert_true(bond_result.is_valid, "the configured social activity should be applicable")
	dashboard.call("_refresh_state")
	dashboard.call(
		"_animate_result_indicators",
		bond_state_before,
		bond_result.result
	)
	var ray_card: Dictionary = (
		(dashboard.get("_relationship_cards") as Dictionary)[&"ray"]
	)
	var ray_bar: ProgressBar = ray_card["bar"]
	assert_eq(
		int(ray_bar.value),
		int(bond_state_before.bonds[&"ray"]),
		"relationship animation should begin at the pre-activity value"
	)
	assert_true(
		ray_bar.has_meta("result_bar_tween"),
		"changed bonds should create a visual Tween"
	)
	var ray_tween: Tween = ray_bar.get_meta("result_bar_tween")
	ray_tween.kill()
	dashboard.call("_finish_result_bar", ray_bar, int(state.bonds[&"ray"]))
	assert_eq(
		int(ray_bar.value),
		int(state.bonds[&"ray"]),
		"relationship animation should end at the real TrainingState value"
	)

	dashboard.call("_show_narrative_overlay")
	var overlay: Control = dashboard.get("_narrative_overlay")
	assert_true(overlay.visible, "narrative overlays should keep immediate priority")
	assert_eq(
		overlay.mouse_filter,
		Control.MOUSE_FILTER_STOP,
		"narrative overlays should prevent clicks reaching the underlying screen"
	)
	_finish_narrative_transition(dashboard, true)
	dashboard.call("_hide_narrative_overlay")
	assert_true(overlay.visible, "narrative close should fade before releasing the screen")
	_finish_narrative_transition(dashboard, false)
	assert_false(overlay.visible, "narrative close should finish its fade")
	assert_true((dashboard.get("_hub_ui") as Control).visible)

	var previous_reduce_motion: Variant = ProjectSettings.get_setting(
		"accessibility/reduce_motion",
		false
	)
	ProjectSettings.set_setting("accessibility/reduce_motion", true)
	nav_buttons[&"training"].pressed.emit()
	assert_false(
		transition_overlay.visible,
		"reduced motion should skip the navigation fade"
	)
	dashboard.call("_show_narrative_overlay")
	assert_false(
		dashboard.get("_narrative_transition") != null,
		"reduced motion should skip the narrative fade"
	)
	dashboard.call("_hide_narrative_overlay")
	assert_false(overlay.visible, "reduced motion should close overlays immediately")
	ProjectSettings.set_setting(
		"accessibility/reduce_motion",
		previous_reduce_motion
	)


func test_window_mode_controls_and_shortcuts_preserve_campaign_state() -> void:
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
	dashboard.call("_refresh_state")

	assert_eq(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		1280,
		"the default viewport should use a 16:9 HD window"
	)
	assert_eq(
		ProjectSettings.get_setting("display/window/size/viewport_height"),
		720,
		"the default viewport height should be 720"
	)
	var window_buttons: Array[Button] = dashboard.get("_window_mode_buttons")
	assert_eq(window_buttons.size(), 4, "every management screen should expose F11")
	for button: Button in window_buttons:
		assert_eq(button.text, "F11", "the fullscreen control should be visible")
		assert_true(button.focus_mode == Control.FOCUS_ALL, "F11 should support keyboard focus")
		assert_true(
			button.tooltip_text.contains("Alt+Enter"),
			"the button should explain its alternate shortcut"
		)

	var f11 := InputEventKey.new()
	f11.keycode = KEY_F11
	f11.pressed = true
	assert_true(
		dashboard.call("_is_window_mode_toggle_shortcut", f11),
		"F11 should toggle fullscreen"
	)
	var alt_enter := InputEventKey.new()
	alt_enter.keycode = KEY_ENTER
	alt_enter.alt_pressed = true
	alt_enter.pressed = true
	assert_true(
		dashboard.call("_is_window_mode_toggle_shortcut", alt_enter),
		"Alt+Enter should toggle fullscreen"
	)
	var ordinary_enter := InputEventKey.new()
	ordinary_enter.keycode = KEY_ENTER
	ordinary_enter.pressed = true
	assert_false(
		dashboard.call("_is_window_mode_toggle_shortcut", ordinary_enter),
		"ordinary Enter should not change the display mode"
	)
	ordinary_enter.keycode = KEY_F11
	ordinary_enter.pressed = false
	assert_false(
		dashboard.call("_is_window_mode_toggle_shortcut", ordinary_enter),
		"releasing F11 should not toggle fullscreen"
	)
	ordinary_enter.pressed = true
	ordinary_enter.echo = true
	assert_false(
		dashboard.call("_is_window_mode_toggle_shortcut", ordinary_enter),
		"key repeat should not toggle fullscreen"
	)

	assert_true(
		dashboard.is_connected("resized", Callable(dashboard, "_update_responsive_layout")),
		"root window resizing should refresh all responsive layouts"
	)
	var actions_before: int = state.actions_remaining
	var rng_before: int = state.rng_state
	var stats_before: Dictionary = state.stats.duplicate(true)
	var bonds_before: Dictionary = state.bonds.duplicate(true)
	for viewport_size: Vector2 in [
		Vector2(800, 600),
		Vector2(1280, 720),
		Vector2(1920, 1080),
	]:
		dashboard.size = viewport_size
		dashboard.call("_update_responsive_layout")
		assert_true(dashboard.size == viewport_size, "the resized viewport should be retained")
	assert_eq(state.actions_remaining, actions_before, "window resizing should not consume actions")
	assert_eq(state.rng_state, rng_before, "window resizing should not advance campaign RNG")
	assert_eq(state.stats, stats_before, "window resizing should not change attributes")
	assert_eq(state.bonds, bonds_before, "window resizing should not change relationships")


func _finish_area_transition(dashboard: Control) -> void:
	var tween: Tween = dashboard.get("_area_transition")
	if tween != null and tween.is_running():
		tween.kill()
	dashboard.call("_finish_area_transition", dashboard.get("_current_area"))


func _finish_narrative_transition(dashboard: Control, open: bool) -> void:
	var tween: Tween = dashboard.get("_narrative_transition")
	if tween != null and tween.is_running():
		tween.kill()
	dashboard.call("_finish_narrative_transition", open)


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

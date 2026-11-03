@tool
extends McpTestSuite

const DashboardScript = preload("res://scripts/training_dashboard.gd")
const TrainingServiceScript = preload("res://scripts/training_service.gd")


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
	for viewport_size: Vector2 in viewport_sizes:
		stage.size = viewport_size
		overlay.size = viewport_size
		dashboard.set("_narrative_mode", &"event_dialogue")
		dashboard.call("_hide_narrative_overlay")
		dashboard.call("_update_hori_presentation")
		dashboard.call("_update_narrative_panel_layout")
		assert_true(management_ui.visible, "management UI should be visible outside narrative mode")
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
		assert_true(management_ui.visible, "management UI should return after narrative mode")
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

class_name TrainingTheme
extends RefCounted

const INK: Color = Color("#232944")
const PETROL: Color = Color("#2C7387")
const MINT: Color = Color("#7AC8C5")
const CORAL: Color = Color("#E98D79")
const GOLD: Color = Color("#E6BD68")
const CREAM: Color = Color("#F5F0E8")
const PANEL: Color = Color("#303952")
const PANEL_RAISED: Color = Color("#39445F")
const PANEL_MUTED: Color = Color("#283149")
const LINE: Color = Color("#53617A")


static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 14
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", CREAM)
	theme.set_color("font_pressed_color", "Button", CREAM)
	theme.set_color("font_disabled_color", "Button", Color(CREAM, 0.55))
	theme.set_font_size("font_size", "Button", 14)

	theme.set_stylebox(
		"panel",
		"PanelContainer",
		_panel_style(PANEL, Color(MINT, 0.32), 12, 1)
	)
	theme.set_stylebox(
		"normal",
		"Button",
		_panel_style(PANEL_RAISED, LINE, 10, 1)
	)
	theme.set_stylebox(
		"hover",
		"Button",
		_panel_style(Color(PETROL, 0.88), MINT, 10, 1)
	)
	theme.set_stylebox(
		"pressed",
		"Button",
		_panel_style(Color(PETROL.darkened(0.18)), MINT, 10, 2)
	)
	theme.set_stylebox(
		"hover_pressed",
		"Button",
		_panel_style(Color(PETROL.darkened(0.08)), CREAM, 10, 2)
	)
	theme.set_stylebox(
		"disabled",
		"Button",
		_panel_style(PANEL_MUTED, Color(LINE, 0.65), 10, 1)
	)
	theme.set_stylebox(
		"focus",
		"Button",
		_panel_style(Color(0, 0, 0, 0), GOLD, 10, 2)
	)
	theme.set_stylebox(
		"background",
		"ProgressBar",
		_panel_style(Color(INK, 0.78), Color(LINE, 0.72), 5, 1)
	)
	theme.set_stylebox(
		"fill",
		"ProgressBar",
		_panel_style(MINT, MINT, 5, 0)
	)
	return theme


static func make_panel_style(
	background: Color = PANEL,
	border: Color = Color(MINT, 0.32),
	radius: int = 12,
	border_width: int = 1
) -> StyleBoxFlat:
	return _panel_style(background, border, radius, border_width)


static func _panel_style(
	background: Color,
	border: Color,
	radius: int,
	border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style

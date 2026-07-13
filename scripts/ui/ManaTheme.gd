class_name ManaTheme
extends RefCounted

# Sacred Journey, sistema visual extraido do projeto Stitch.
const BODY_FONT = preload("res://assets/fonts/Inter-Variable.ttf")
const SERIF_FONT = preload("res://assets/fonts/NotoSerif-Variable.ttf")
const SERIF_ITALIC_FONT = preload("res://assets/fonts/NotoSerif-Italic-Variable.ttf")

const BACKGROUND_TOP := Color("#10102e")
const BACKGROUND_BOTTOM := Color("#17183d")
const SURFACE_LOW := Color("#181837")
const SURFACE := Color("#1c1c3b")
const SURFACE_HIGH := Color("#272746")
const SURFACE_HIGHEST := Color("#323252")
const PARCHMENT := Color("#fdf6e3")
const PARCHMENT_MUTED := Color("#efe8d1")
const PARCHMENT_BORDER := Color("#d8c9a6")
const INK := Color("#29273a")
const INK_MUTED := Color("#6f675f")
const CREAM := Color("#f6efd9")
const CREAM_MUTED := Color("#d6c4ac")
const GOLD := Color("#f0a500")
const GOLD_LIGHT := Color("#ffc56c")
const GOLD_DARK := Color("#805600")
const SILVER := Color("#c4c3ec")
const GREEN := Color("#4f9f70")
const OUTLINE := Color("#514533")
const DISABLED := Color("#777083")

static var _serif_bold: FontVariation
static var _body_semibold: FontVariation

static func serif_bold() -> Font:
	if _serif_bold == null:
		_serif_bold = FontVariation.new()
		_serif_bold.base_font = SERIF_FONT
		_serif_bold.variation_opentype = {"wght": 700}
	return _serif_bold

static func body_semibold() -> Font:
	if _body_semibold == null:
		_body_semibold = FontVariation.new()
		_body_semibold.base_font = BODY_FONT
		_body_semibold.variation_opentype = {"wght": 650}
	return _body_semibold

static func make_theme(font_scale: float = 1.0) -> Theme:
	var safe_font_scale := maxf(0.1, font_scale)
	var result := Theme.new()
	result.default_font = BODY_FONT
	result.default_font_size = maxi(1, roundi(36.0 * safe_font_scale))

	result.set_font("font", "Label", BODY_FONT)
	result.set_font("font", "Button", body_semibold())
	result.set_font("title_font", "Window", serif_bold())
	result.set_font_size("font_size", "Button", maxi(1, roundi(35.0 * safe_font_scale)))
	result.set_color("font_color", "Label", CREAM)
	result.set_color("font_color", "Button", CREAM)
	result.set_color("font_hover_color", "Button", Color("#fff3cf"))
	result.set_color("font_pressed_color", "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("#a29caf"))
	result.set_color("font_focus_color", "Button", CREAM)

	result.set_stylebox("normal", "Button", button_style(SURFACE_HIGH, OUTLINE, 18))
	result.set_stylebox("hover", "Button", button_style(SURFACE_HIGHEST, GOLD_DARK, 18))
	result.set_stylebox("pressed", "Button", button_style(GOLD_LIGHT, GOLD, 18))
	result.set_stylebox("disabled", "Button", button_style(Color("#24243e"), Color("#3c394a"), 18))
	result.set_stylebox("focus", "Button", button_style(Color(0, 0, 0, 0), GOLD_LIGHT, 18, 2))

	result.set_stylebox("background", "ProgressBar", progress_style(PARCHMENT_MUTED))
	result.set_stylebox("fill", "ProgressBar", progress_style(GOLD))
	result.set_color("font_color", "ProgressBar", INK)
	result.set_stylebox("scroll", "VScrollBar", progress_style(Color(0, 0, 0, 0)))
	result.set_stylebox("grabber", "VScrollBar", progress_style(Color(0.94, 0.65, 0.0, 0.34)))
	result.set_stylebox("grabber_highlight", "VScrollBar", progress_style(Color(1.0, 0.77, 0.42, 0.62)))
	result.set_stylebox("grabber_pressed", "VScrollBar", progress_style(GOLD))

	result.set_stylebox("panel", "PopupPanel", panel_style(SURFACE, 24, OUTLINE, 2, 32))
	result.set_stylebox("panel", "PanelContainer", panel_style(SURFACE, 18, Color(0, 0, 0, 0), 0, 24))
	return result

# Scroll por arrasto no toque: o ScrollContainer so inicia o pan se o press
# chegar ate ele, entao nenhum filho da lista pode reter o evento (STOP).
# O deadzone evita que o arrasto cancele toques legitimos nos botoes.
static func enable_touch_scroll(scroll: ScrollContainer, list: Node, deadzone: int = 24) -> void:
	scroll.scroll_deadzone = deadzone
	_relax_mouse_filters(list)
	list.child_entered_tree.connect(func(node: Node): _relax_mouse_filters.call_deferred(node))

static func _relax_mouse_filters(node: Node) -> void:
	if node is Control and node.mouse_filter == Control.MOUSE_FILTER_STOP:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.get_children():
		_relax_mouse_filters(child)

static func panel_style(
	bg: Color,
	radius: int = 18,
	border: Color = Color(0, 0, 0, 0),
	border_width: int = 0,
	padding: int = 24,
	shadow: bool = false
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	if border_width > 0:
		style.set_border_width_all(border_width)
		style.border_color = border
	if shadow:
		style.shadow_color = Color(0.02, 0.02, 0.08, 0.28)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 6)
	return style

static func button_style(
	bg: Color,
	border: Color,
	radius: int = 18,
	border_width: int = 1,
	padding_x: int = 24,
	padding_y: int = 16
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	style.content_margin_left = padding_x
	style.content_margin_right = padding_x
	style.content_margin_top = padding_y
	style.content_margin_bottom = padding_y
	return style

static func progress_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(999)
	return style

static func apply_primary_button(button: Button) -> void:
	button.add_theme_font_override("font", body_semibold())
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("#77716d"))
	button.add_theme_stylebox_override("normal", button_style(GOLD, GOLD_LIGHT, 24, 2, 26, 16))
	button.add_theme_stylebox_override("hover", button_style(GOLD_LIGHT, Color("#ffdda8"), 24, 2, 26, 16))
	button.add_theme_stylebox_override("pressed", button_style(Color("#d89200"), GOLD_DARK, 24, 2, 26, 16))
	button.add_theme_stylebox_override("disabled", button_style(Color("#c2bba8"), Color("#d4cbb4"), 24, 1, 26, 16))

static func apply_secondary_light_button(button: Button) -> void:
	button.add_theme_font_override("font", body_semibold())
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("#8a837a"))
	button.add_theme_stylebox_override("normal", button_style(Color("#f4ecd8"), PARCHMENT_BORDER, 16, 2, 22, 12))
	button.add_theme_stylebox_override("hover", button_style(Color("#fff9e9"), GOLD, 16, 2, 22, 12))
	button.add_theme_stylebox_override("pressed", button_style(Color("#eadcbf"), GOLD_DARK, 16, 2, 22, 12))
	button.add_theme_stylebox_override("disabled", button_style(Color("#ded8cc"), Color("#c7c0b3"), 16, 1, 22, 12))

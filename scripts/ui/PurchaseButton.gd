class_name PurchaseButton
extends Button

const CHAMFER := 13.0
var _base_color := Color("#17213b")
var _outer_color := Color("#b98e38")
var _inner_color := Color("#f0cd78")
var _hover_color := Color("#25345a")
var _show_divider := true

func _ready() -> void:
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	queue_redraw()

func refresh_visual() -> void:
	queue_redraw()

func set_frame_style(base: Color, outer: Color, inner: Color, hover: Color, show_divider: bool = false) -> void:
	_base_color = base
	_outer_color = outer
	_inner_color = inner
	_hover_color = hover
	_show_divider = show_divider
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var outer := _chamfered_points(rect)
	var inner := _chamfered_points(rect.grow(-2.0))
	var inset := _chamfered_points(rect.grow(-6.0))
	var bg := _base_color
	var outer_color := _outer_color
	var inner_color := _inner_color
	if disabled:
		bg = Color("#46474d")
		outer_color = Color("#77777c")
		inner_color = Color("#9a9995")
	elif is_hovered():
		bg = _hover_color
		outer_color = _outer_color.lightened(0.16)
		inner_color = _inner_color.lightened(0.12)
	draw_colored_polygon(outer, outer_color)
	draw_colored_polygon(inner, Color("#0d1428"))
	draw_colored_polygon(inset, bg)
	var closed_inset := inset.duplicate()
	closed_inset.append(inset[0])
	draw_polyline(closed_inset, inner_color, 1.0, true)
	if _show_divider:
		var divider_y := roundf(size.y * 0.51)
		draw_line(Vector2(23, divider_y), Vector2(size.x - 23, divider_y), _inner_color if not disabled else Color("#77777c"), 1.0)

func _chamfered_points(rect: Rect2) -> PackedVector2Array:
	var c := minf(CHAMFER, minf(rect.size.x, rect.size.y) * 0.25)
	return PackedVector2Array([
		Vector2(rect.position.x + c, rect.position.y),
		Vector2(rect.end.x - c, rect.position.y),
		Vector2(rect.end.x, rect.position.y + c),
		Vector2(rect.end.x, rect.end.y - c),
		Vector2(rect.end.x - c, rect.end.y),
		Vector2(rect.position.x + c, rect.end.y),
		Vector2(rect.position.x, rect.end.y - c),
		Vector2(rect.position.x, rect.position.y + c),
	])

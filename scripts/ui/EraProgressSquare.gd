class_name EraProgressSquare
extends Control

var _fill: float = 0.0
var _complete: bool = false

func set_state(fill: float, complete: bool, tooltip: String) -> void:
	_fill = clampf(fill, 0.0, 1.0)
	_complete = complete
	tooltip_text = tooltip
	queue_redraw()

func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	var border := Color("#d7ad4d")
	var fill_color := Color("#dca932")
	if _complete:
		border = Color("#55c984")
		fill_color = Color("#45b975")
	if _fill > 0.0:
		var fill_width := box.size.x * _fill
		draw_rect(Rect2(0, 0, fill_width, box.size.y), fill_color)
	draw_rect(box.grow(-1.0), Color("#171b34"), false, 1.0)
	draw_rect(box.grow(-0.5), border, false, 2.0)

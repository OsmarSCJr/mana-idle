class_name SacredBackground
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	# Gradiente noturno com um horizonte dourado muito discreto.
	var strips := 72
	for i in range(strips):
		var t := float(i) / float(strips - 1)
		var color := ManaTheme.BACKGROUND_TOP.lerp(ManaTheme.BACKGROUND_BOTTOM, t)
		draw_rect(Rect2(0.0, size.y * t, size.x, size.y / strips + 2.0), color)

	draw_circle(Vector2(size.x * 0.5, size.y * 1.08), size.x * 0.82, Color(0.94, 0.65, 0.0, 0.045))
	draw_circle(Vector2(size.x * 0.5, size.y * 1.08), size.x * 0.55, Color(1.0, 0.77, 0.35, 0.035))

	# Campo de estrelas deterministico para evitar cintilacao entre frames.
	for i in range(44):
		var x_ratio := fmod(float(i * 47 + 13), 101.0) / 101.0
		var y_ratio := fmod(float(i * 71 + 29), 113.0) / 113.0
		var radius := 1.4 + float(i % 3) * 0.8
		var alpha := 0.18 + float(i % 5) * 0.055
		draw_circle(Vector2(size.x * x_ratio, size.y * y_ratio), radius, Color(1.0, 0.93, 0.72, alpha))

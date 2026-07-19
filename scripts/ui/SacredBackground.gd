class_name SacredBackground
extends Control

# Fundo procedural do santuario. A paleta padrao vem do ManaTheme; os Temas do
# Santuario (cosmeticos comprados com Reliquias) trocam as quatro cores.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	EventBus.cosmetic_changed.connect(queue_redraw)
	EventBus.adventure_context_changed.connect(func(_id: String): queue_redraw())
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var has_cosmetic_theme := not str(GameState.cosmeticos_ativos.get("tema_fundo", "")).is_empty()
	var palette: Dictionary = Cosmeticos.active_background_palette() if has_cosmetic_theme else GameState.get_adventure_palette()
	var top_color: Color = palette.get("top", ManaTheme.BACKGROUND_TOP)
	var bottom_color: Color = palette.get("bottom", ManaTheme.BACKGROUND_BOTTOM)
	var glow_color: Color = palette.get("glow", Color(0.94, 0.65, 0.0, 0.045))
	var star_color: Color = palette.get("star", Color(1.0, 0.93, 0.72))

	# Gradiente noturno com um horizonte dourado muito discreto.
	var strips := 72
	for i in range(strips):
		var t := float(i) / float(strips - 1)
		var color := top_color.lerp(bottom_color, t)
		draw_rect(Rect2(0.0, size.y * t, size.x, size.y / strips + 2.0), color)

	draw_circle(Vector2(size.x * 0.5, size.y * 1.08), size.x * 0.82, glow_color)
	var glow_inner := glow_color
	glow_inner.a *= 0.8
	draw_circle(Vector2(size.x * 0.5, size.y * 1.08), size.x * 0.55, glow_inner)

	# Cada campanha ganha uma silhueta propria sem imagens fixas, preservando a
	# leitura em qualquer proporcao de tela. Temas cosmeticos continuam soberanos.
	if not has_cosmetic_theme:
		_draw_adventure_motif(star_color)

	# Campo de estrelas deterministico para evitar cintilacao entre frames.
	for i in range(44):
		var x_ratio := fmod(float(i * 47 + 13), 101.0) / 101.0
		var y_ratio := fmod(float(i * 71 + 29), 113.0) / 113.0
		var radius := 1.4 + float(i % 3) * 0.8
		var alpha := 0.18 + float(i % 5) * 0.055
		draw_circle(Vector2(size.x * x_ratio, size.y * y_ratio), radius, Color(star_color.r, star_color.g, star_color.b, alpha))


func _draw_adventure_motif(accent: Color) -> void:
	var line := Color(accent.r, accent.g, accent.b, 0.075)
	match GameState.active_adventure:
		"vida_cristo":
			var sun_center := Vector2(size.x * 0.5, size.y * 0.70)
			draw_circle(sun_center, minf(size.x, size.y) * 0.12, Color(accent.r, accent.g, accent.b, 0.055))
			for i in range(5):
				var y := size.y * (0.76 + float(i) * 0.035)
				draw_arc(Vector2(size.x * 0.5, y), size.x * (0.32 + float(i) * 0.08), PI, TAU, 48, line, 2.0)
		"igreja_apocalipse":
			var pane_width := size.x / 5.0
			for i in range(5):
				var center_x := pane_width * (float(i) + 0.5)
				var rect := Rect2(center_x - pane_width * 0.38, size.y * 0.10, pane_width * 0.76, size.y * 0.88)
				draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.018), true)
				draw_arc(Vector2(center_x, size.y * 0.20), pane_width * 0.38, PI, TAU, 24, line, 2.0)
				draw_line(Vector2(rect.position.x, size.y * 0.20), Vector2(rect.position.x, rect.end.y), line, 2.0)
				draw_line(Vector2(rect.end.x, size.y * 0.20), Vector2(rect.end.x, rect.end.y), line, 2.0)
		_:
			var orbit_center := Vector2(size.x * 0.5, size.y * 0.42)
			for ratio in [0.18, 0.31, 0.46]:
				draw_arc(orbit_center, size.x * float(ratio), 0.0, TAU, 64, line, 2.0)

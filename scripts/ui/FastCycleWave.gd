extends Control

## Indicador discreto para ciclos ultrarrápidos. Em vez de redesenhar uma
## barra que reinicia várias vezes por segundo, mantém o preenchimento estável
## e move apenas três ondas suaves em baixa velocidade.

var _phase: float = 0.0
var _active: bool = false


func _init() -> void:
	visible = false
	set_process(false)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	visible = _active
	set_process(_active)
	resized.connect(queue_redraw)


func set_active(active: bool) -> void:
	_active = active
	visible = active
	set_process(active)
	if active:
		queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_phase = fposmod(_phase + delta * 1.15, TAU)
	queue_redraw()


func _draw() -> void:
	if size.x <= 18.0 or size.y <= 4.0:
		return
	var usable_width := size.x - 16.0
	var sample_count := maxi(18, ceili(usable_width / 12.0))
	var amplitude := maxf(1.2, size.y * 0.10)
	var wave_colors := [
		Color(0.86, 1.0, 0.90, 0.38),
		Color(0.63, 0.96, 0.75, 0.30),
		Color(1.0, 0.90, 0.55, 0.20),
	]
	for band in range(3):
		var points := PackedVector2Array()
		var center_y := size.y * (0.30 + float(band) * 0.20)
		for sample in range(sample_count + 1):
			var ratio := float(sample) / float(sample_count)
			var x := 8.0 + usable_width * ratio
			var y := center_y + sin(ratio * TAU * 2.15 + _phase + float(band) * 1.35) * amplitude
			points.append(Vector2(x, y))
		draw_polyline(points, wave_colors[band], 2.0, true)

class_name NovaStar
extends Control

## Estrela Nova: micro-conteudo de sessao. Uma estrela cadente cruza a tela em
## intervalos aleatorios (LiveOps); o toque premia minutos de producao da
## aventura em foco e, 1x ao dia, algumas gemas. Desenho 100% procedural —
## quando a arte final existir, basta trocar o _draw da StarSprite.

const STAR_SIZE: float = 108.0
const CROSS_SECONDS: float = 8.0

var current_adventure_provider: Callable = Callable()

var _spawn_timer: Timer
var _star: Control
var _travelling: bool = false
var _travel_elapsed: float = 0.0
var _start_pos: Vector2 = Vector2.ZERO
var _end_pos: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_star = _build_star()
	add_child(_star)
	_star.visible = false
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_launch_star)
	add_child(_spawn_timer)
	_schedule_next()
	EventBus.cosmetic_changed.connect(func(): _star.queue_redraw())


func _schedule_next() -> void:
	var minimum := LiveOps.nova_star_min_seconds()
	var maximum := maxf(minimum + 1.0, LiveOps.nova_star_max_seconds())
	_spawn_timer.start(_rng.randf_range(minimum, maximum))


func _launch_star() -> void:
	if _travelling or not is_visible_in_tree():
		_schedule_next()
		return
	var viewport_size := get_viewport_rect().size
	var from_left := _rng.randf() < 0.5
	var y_start := viewport_size.y * _rng.randf_range(0.12, 0.45)
	var y_end := y_start + viewport_size.y * _rng.randf_range(0.05, 0.22)
	_start_pos = Vector2(-STAR_SIZE if from_left else viewport_size.x + STAR_SIZE, y_start)
	_end_pos = Vector2(viewport_size.x + STAR_SIZE if from_left else -STAR_SIZE, y_end)
	_travel_elapsed = 0.0
	_travelling = true
	_star.position = _start_pos
	_star.visible = true


func _process(delta: float) -> void:
	if not _travelling:
		return
	_travel_elapsed += delta
	var progress := _travel_elapsed / CROSS_SECONDS
	if progress >= 1.0:
		_travelling = false
		_star.visible = false
		_schedule_next()
		return
	var base := _start_pos.lerp(_end_pos, progress)
	base.y += sin(progress * TAU * 1.5) * 14.0
	_star.position = base


func _on_star_clicked() -> void:
	if not _travelling:
		return
	_travelling = false
	_star.visible = false
	var adventure := "jornada"
	if current_adventure_provider.is_valid():
		adventure = str(current_adventure_provider.call())
	var resultado: Dictionary = GameState.claim_nova_star(adventure)
	var moeda := GameState.get_currency_name(str(resultado.currency))
	var texto := "Estrela Nova! +" + NumberFormat.format(float(resultado.amount)) + " " + moeda
	if int(resultado.gems) > 0:
		texto += "  ·  +" + str(int(resultado.gems)) + " Gemas"
	EventBus.toast_requested.emit(texto)
	_schedule_next()


func _build_star() -> Control:
	var star := StarSprite.new()
	star.custom_minimum_size = Vector2(STAR_SIZE, STAR_SIZE)
	star.size = Vector2(STAR_SIZE, STAR_SIZE)
	star.mouse_filter = Control.MOUSE_FILTER_STOP
	star.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	star.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed \
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_on_star_clicked()
	)
	return star


class StarSprite extends Control:
	var art: TextureRect

	func _ready() -> void:
		art = TextureRect.new()
		art.texture = GameArt.NOVA_STAR_ICON
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)

	func _draw() -> void:
		var colors: Dictionary = Cosmeticos.active_star_colors()
		var star_color: Color = colors.star
		var trail_color: Color = colors.trail
		var center := size * 0.5
		if art != null:
			art.modulate = star_color
		# Rastro: tres riscos decrescentes atras da estrela.
		for i in range(3):
			var offset := Vector2(-18.0 - 22.0 * i, 4.0 * i)
			var trail_faded := trail_color
			trail_faded.a *= 1.0 - 0.28 * i
			draw_line(center + offset, center + offset + Vector2(-26.0 + 6.0 * i, 2.0), trail_faded, 4.0 - i)
		# Halo suave por baixo da arte final.
		draw_circle(center, 26.0, Color(star_color.r, star_color.g, star_color.b, 0.16))

class_name GeradorItem
extends PanelContainer

const FastCycleWaveScript = preload("res://scripts/ui/FastCycleWave.gd")

signal buy_pressed(gen_id: int, amount: int)
signal prophet_pressed(gen_id: int)
signal cycle_started(gen_id: int)

const BG_COLOR: Color = ManaTheme.PARCHMENT
const BG_COLOR_LOCKED: Color = ManaTheme.SURFACE
const BORDER_COLOR: Color = ManaTheme.PARCHMENT_BORDER
const TEXT_COLOR: Color = ManaTheme.INK
const TEXT_DIM: Color = ManaTheme.INK_MUTED
const GOLD: Color = ManaTheme.GOLD
const GREEN: Color = ManaTheme.GREEN

const MAX_FLOATS: int = 3  # limite de labels "+Fe" simultaneas
const CARD_MIN_HEIGHT: float = 252.0
const ICON_SIZE: float = 94.0
const FAST_CYCLE_THRESHOLD: float = 1.1

var gen_id: int = 0
var data: Dictionary = {}
var is_locked: bool = false
var _modo_compra: String = "x1"

var _icon_panel: PanelContainer
var _icon_texture_rect: TextureRect
var _icon_label: Label
var _name_label: Label
var _qty_label: Label
var _rev_label: Label
var _flavor_label: Label
var _status_chip: PanelContainer
var _status_label: Label
var _prophet_badge: TextureRect
var _cycle_state_label: Label
var _cycle_time_label: Label
var _progress_bar: ProgressBar
var _hint_label: Label
var _fast_cycle_wave: Control
var _buy_btn: Button
var _prophet_btn: Button
var _pulse_tween: Tween
var _completion_tween: Tween
var _float_count: int = 0
var _icon_texture: Texture2D
var _prophet_texture: Texture2D
var _visual_state: String = ""
var _card_style_state: String = ""
var _prophet_button_ready: bool = false
var _progress_target: float = 0.0
var _progress_display: float = 0.0
var _progress_initialized: bool = false
var _fast_cycle_active: bool = false

# Cache do ultimo texto aplicado (evita relayout desnecessario a cada tick).
var _last_qty_text: String = ""
var _last_rev_text: String = ""
var _last_buy_text: String = ""
var _last_prophet_text: String = ""
var _last_cycle_state_text: String = ""
var _last_cycle_time_text: String = ""
var _last_progress_text: String = ""

func setup(id: int) -> void:
	gen_id = id
	data = Geradores.get_data(id)
	if data.is_empty():
		return
	_build_ui()
	_check_locked()
	EventBus.generator_cycle_complete.connect(_on_cycle_complete)

func set_modo(modo: String) -> void:
	_modo_compra = modo
	update()

# API de apresentacao: permite integrar os assets finais sem acoplar o card
# a caminhos de arquivos ou regras de carregamento.
func set_icon_texture(texture: Texture2D) -> void:
	_icon_texture = texture
	_apply_icon_texture()

func set_prophet_texture(texture: Texture2D) -> void:
	_prophet_texture = texture
	_apply_prophet_texture()

func _process(delta: float) -> void:
	if _progress_bar == null or not is_visible_in_tree():
		return
	if not _progress_initialized:
		_progress_display = _progress_target
		_progress_initialized = true
	var response := 22.0 if _progress_target < _progress_display else 12.0
	var weight := 1.0 - exp(-response * delta)
	_progress_display = lerpf(_progress_display, _progress_target, weight)
	if absf(_progress_display - _progress_target) < 0.0005:
		_progress_display = _progress_target
		set_process(false)
	_progress_bar.value = _progress_display

func _check_locked() -> void:
	is_locked = not GameState.is_unlocked(gen_id)

func _build_ui() -> void:
	custom_minimum_size = Vector2(0, CARD_MIN_HEIGHT)
	_apply_card_style("unlocked")
	# O painel inteiro (area do icone/nome) inicia o ciclo ao toque.
	gui_input.connect(_on_panel_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	# Secao superior: selo + informacoes + acao principal.
	var top_hbox: HBoxContainer = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 14)
	top_hbox.custom_minimum_size = Vector2(0, 104)
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_hbox)

	_icon_panel = PanelContainer.new()
	_icon_panel.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	_icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_icon_style(data.get("cor", GOLD))
	top_hbox.add_child(_icon_panel)
	_icon_texture_rect = TextureRect.new()
	_icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_texture_rect.visible = false
	_icon_panel.add_child(_icon_texture_rect)
	_icon_label = Label.new()
	_icon_label.text = "%02d" % gen_id
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_icon_label.add_theme_font_size_override("font_size", 41)
	_icon_label.add_theme_color_override("font_color", TEXT_COLOR)
	_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_panel.add_child(_icon_label)
	_apply_icon_texture()

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(info_vbox)

	_name_label = Label.new()
	_name_label.text = data.get("nome", "???")
	_name_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_name_label.add_theme_font_size_override("font_size", 33)
	_name_label.add_theme_color_override("font_color", TEXT_COLOR)
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.tooltip_text = _name_label.text
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_child(_name_label)

	var sub_hbox: HBoxContainer = HBoxContainer.new()
	sub_hbox.add_theme_constant_override("separation", 9)
	sub_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_child(sub_hbox)

	_qty_label = Label.new()
	_qty_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_qty_label.add_theme_font_size_override("font_size", 23)
	_qty_label.add_theme_color_override("font_color", ManaTheme.GOLD_DARK)
	_qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(_qty_label)

	_status_chip = PanelContainer.new()
	_status_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(_status_chip)
	_status_label = Label.new()
	_status_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_chip.add_child(_status_label)

	_prophet_badge = TextureRect.new()
	_prophet_badge.custom_minimum_size = Vector2(34, 34)
	_prophet_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_prophet_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_prophet_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prophet_badge.visible = false
	sub_hbox.add_child(_prophet_badge)

	_rev_label = Label.new()
	_rev_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_rev_label.add_theme_font_size_override("font_size", 23)
	_rev_label.add_theme_color_override("font_color", GREEN)
	_rev_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rev_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(_rev_label)

	_flavor_label = Label.new()
	_flavor_label.text = data.get("flavor", "")
	_flavor_label.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT)
	_flavor_label.add_theme_font_size_override("font_size", 20)
	_flavor_label.add_theme_color_override("font_color", TEXT_DIM)
	_flavor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flavor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_child(_flavor_label)

	_buy_btn = Button.new()
	_buy_btn.text = "Comprar"
	_buy_btn.add_theme_font_size_override("font_size", 23)
	_buy_btn.custom_minimum_size = Vector2(184, 98)
	_buy_btn.pressed.connect(_on_buy_pressed)
	_buy_btn.tooltip_text = "Adquirir unidades deste gerador"
	ManaTheme.apply_primary_button(_buy_btn)
	top_hbox.add_child(_buy_btn)

	# Cabecalho operacional da barra: o estado nunca depende apenas de cor.
	var cycle_header: HBoxContainer = HBoxContainer.new()
	cycle_header.add_theme_constant_override("separation", 12)
	cycle_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cycle_header)
	_cycle_state_label = Label.new()
	_cycle_state_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_cycle_state_label.add_theme_font_size_override("font_size", 18)
	_cycle_state_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	_cycle_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cycle_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cycle_header.add_child(_cycle_state_label)
	_cycle_time_label = Label.new()
	_cycle_time_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_cycle_time_label.add_theme_font_size_override("font_size", 18)
	_cycle_time_label.add_theme_color_override("font_color", ManaTheme.GOLD_DARK)
	_cycle_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cycle_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cycle_header.add_child(_cycle_time_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 24)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.tooltip_text = "Progresso do ciclo de produção"
	vbox.add_child(_progress_bar)

	# Hint sobre a barra de progresso: ensina que o card e tocavel.
	_hint_label = Label.new()
	_hint_label.text = "AGUARDANDO"
	_hint_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_hint_label.add_theme_font_size_override("font_size", 18)
	_hint_label.add_theme_color_override("font_color", ManaTheme.INK)
	_hint_label.add_theme_color_override("font_outline_color", Color(1.0, 0.98, 0.91, 0.82))
	_hint_label.add_theme_constant_override("outline_size", 2)
	_hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.visible = false
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.add_child(_hint_label)

	_fast_cycle_wave = FastCycleWaveScript.new()
	_fast_cycle_wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fast_cycle_wave.z_index = 2
	_fast_cycle_wave.call("set_active", false)
	_progress_bar.add_child(_fast_cycle_wave)
	_fast_cycle_wave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_prophet_btn = Button.new()
	_prophet_btn.add_theme_font_size_override("font_size", 22)
	_prophet_btn.custom_minimum_size = Vector2(0, 58)
	_prophet_btn.visible = false
	_prophet_btn.pressed.connect(_on_prophet_pressed)
	_prophet_btn.tooltip_text = "Profetas automatizam a produção deste gerador"
	_apply_prophet_button_style(false)
	vbox.add_child(_prophet_btn)
	_apply_prophet_texture()

func _update_icon_style(accent: Color) -> void:
	if _icon_panel == null:
		return
	var bg := ManaTheme.PARCHMENT.lerp(accent, 0.22)
	_icon_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(bg, 47, accent.darkened(0.18), 3, 8))

func _apply_icon_texture() -> void:
	if _icon_texture_rect == null or _icon_label == null:
		return
	_icon_texture_rect.texture = _icon_texture
	_icon_texture_rect.visible = _icon_texture != null
	_icon_label.visible = _icon_texture == null

func _apply_prophet_texture() -> void:
	if _prophet_btn == null:
		return
	_prophet_btn.icon = _prophet_texture
	_prophet_btn.expand_icon = _prophet_texture != null
	_prophet_btn.add_theme_constant_override("icon_max_width", 38 if _prophet_texture != null else 0)
	if _prophet_badge != null:
		_prophet_badge.texture = _prophet_texture

func _apply_prophet_button_style(is_ready: bool) -> void:
	if _prophet_btn == null or _prophet_button_ready == is_ready and _prophet_btn.has_theme_stylebox_override("normal"):
		return
	_prophet_button_ready = is_ready
	var normal_bg := Color("#dff5e5")
	var normal_border := Color("#73b987")
	var normal_text := Color("#285c3b")
	if is_ready:
		normal_bg = Color("#35c96f")
		normal_border = Color("#1a8f4a")
		normal_text = Color("#092f1a")
	_prophet_btn.add_theme_color_override("font_color", normal_text)
	_prophet_btn.add_theme_color_override("font_hover_color", Color("#062715"))
	_prophet_btn.add_theme_color_override("font_pressed_color", Color("#062715"))
	_prophet_btn.add_theme_color_override("font_disabled_color", Color("#53745e"))
	_prophet_btn.add_theme_stylebox_override("normal", ManaTheme.button_style(normal_bg, normal_border, 16, 2, 18, 9))
	_prophet_btn.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#69df91"), Color("#178844"), 16, 2, 18, 9))
	_prophet_btn.add_theme_stylebox_override("pressed", ManaTheme.button_style(Color("#27aa5a"), Color("#126f39"), 16, 2, 18, 9))
	_prophet_btn.add_theme_stylebox_override("disabled", ManaTheme.button_style(Color("#dce9dc"), Color("#93ad97"), 16, 1, 18, 9))

func _apply_card_style(state: String) -> void:
	if state == _card_style_state:
		return
	_card_style_state = state
	if state == "locked":
		add_theme_stylebox_override("panel", ManaTheme.panel_style(BG_COLOR_LOCKED, 24, Color(1.0, 1.0, 1.0, 0.07), 2, 20))
	else:
		add_theme_stylebox_override("panel", ManaTheme.panel_style(BG_COLOR, 24, BORDER_COLOR, 2, 20, true))

func _apply_operating_state(state: String) -> void:
	if state == _visual_state:
		return
	_visual_state = state
	var accent: Color = data.get("cor", GOLD)
	var chip_bg := ManaTheme.PARCHMENT_MUTED
	var chip_border := ManaTheme.PARCHMENT_BORDER
	var chip_text := ManaTheme.INK_MUTED
	var chip_label := "INATIVO"
	var track := ManaTheme.PARCHMENT_MUTED
	var fill := ManaTheme.PARCHMENT.lerp(accent, 0.64)
	var overlay_text := ManaTheme.INK
	match state:
		"automatic":
			chip_bg = Color("#c9f6d7")
			chip_border = Color("#21b65b")
			chip_text = Color("#0b5a2a")
			chip_label = "AUTO"
			track = Color("#dcebdc")
			fill = Color("#42cc78")
		"manual_ready", "manual_running":
			chip_bg = Color("#fff0ce")
			chip_border = ManaTheme.GOLD
			chip_text = ManaTheme.GOLD_DARK
			chip_label = "MANUAL"
		"locked":
			chip_bg = ManaTheme.SURFACE_HIGH
			chip_border = Color(1.0, 1.0, 1.0, 0.10)
			chip_text = ManaTheme.DISABLED
			chip_label = "BLOQUEADO"
			track = Color("#24243e")
			fill = Color("#45445d")
			overlay_text = ManaTheme.DISABLED
		_:
			pass
	_status_label.text = chip_label
	_status_label.add_theme_color_override("font_color", chip_text)
	_status_chip.add_theme_stylebox_override("panel", ManaTheme.panel_style(chip_bg, 999, chip_border, 1, 7))
	var track_style := ManaTheme.progress_style(track)
	track_style.set_border_width_all(1)
	track_style.border_color = chip_border.darkened(0.06)
	_progress_bar.add_theme_stylebox_override("background", track_style)
	_progress_bar.add_theme_stylebox_override("fill", ManaTheme.progress_style(fill))
	_hint_label.add_theme_color_override("font_color", overlay_text)
	if _fast_cycle_active:
		_apply_fast_cycle_style()
	if state == "manual_ready":
		_start_pulse()
	else:
		_stop_pulse()

func _on_buy_pressed() -> void:
	var amount: int = _calc_amount()
	if amount <= 0:
		return
	buy_pressed.emit(gen_id, amount)

func _on_prophet_pressed() -> void:
	prophet_pressed.emit(gen_id)

func _on_panel_input(event: InputEvent) -> void:
	if is_locked or _visual_state != "manual_ready":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Toque real chega tambem como mouse emulado; trata so no ScreenTouch.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		cycle_started.emit(gen_id)
		_play_tap_feedback()
	elif event is InputEventScreenTouch and event.pressed:
		cycle_started.emit(gen_id)
		_play_tap_feedback()

func _on_cycle_complete(id: int, revenue: float) -> void:
	if id != gen_id or not is_visible_in_tree():
		return
	_spawn_float("+" + NumberFormat.format(revenue))
	_play_completion_feedback()

# Label "+Fe" dourada que sobe e some (feedback de producao).
func _spawn_float(texto: String) -> void:
	if _float_count >= MAX_FLOATS:
		return
	_float_count += 1
	var lbl: Label = Label.new()
	lbl.text = texto
	lbl.add_theme_font_override("font", ManaTheme.body_semibold())
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", ManaTheme.GOLD_DARK)
	lbl.add_theme_color_override("font_shadow_color", ManaTheme.PARCHMENT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 10
	lbl.position = Vector2(135, 44)
	add_child(lbl)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 44.0, 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		lbl.queue_free()
		_float_count -= 1
	)

func _start_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		return
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(_status_chip, "modulate:a", 0.72, 0.72).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_status_chip, "modulate:a", 1.0, 0.72).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	_status_chip.modulate.a = 1.0

func _play_tap_feedback() -> void:
	if _progress_bar == null:
		return
	var tween := create_tween()
	tween.tween_property(_progress_bar, "modulate", Color(1.12, 1.08, 0.94, 1.0), 0.08)
	tween.tween_property(_progress_bar, "modulate", Color.WHITE, 0.18)

func _play_completion_feedback() -> void:
	if _icon_panel == null:
		return
	if _completion_tween != null and _completion_tween.is_valid():
		_completion_tween.kill()
	_icon_panel.pivot_offset = _icon_panel.size * 0.5
	_icon_panel.scale = Vector2.ONE
	_completion_tween = create_tween()
	_completion_tween.tween_property(_icon_panel, "scale", Vector2(1.055, 1.055), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_completion_tween.tween_property(_icon_panel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _calc_amount() -> int:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	var qtd: int = state.get("qtd", 0)
	match _modo_compra:
		"x1": return 1
		"x10": return 10
		"x100": return 100
		"Next": return max(0, Economy.next_milestone(qtd) - qtd)
		"Max": return max(0, Economy.max_compravel(gen_id, GameState.fe, qtd))
		_: return 1

func _set_qty_text(t: String) -> void:
	if t != _last_qty_text:
		_last_qty_text = t
		_qty_label.text = t

func _set_rev_text(t: String) -> void:
	if t != _last_rev_text:
		_last_rev_text = t
		_rev_label.text = t

func _set_buy_text(t: String) -> void:
	if t != _last_buy_text:
		_last_buy_text = t
		_buy_btn.text = t

func _set_prophet_text(t: String) -> void:
	if t != _last_prophet_text:
		_last_prophet_text = t
		_prophet_btn.text = t

func _set_cycle_state_text(t: String) -> void:
	if t != _last_cycle_state_text:
		_last_cycle_state_text = t
		_cycle_state_label.text = t

func _set_cycle_time_text(t: String) -> void:
	if t != _last_cycle_time_text:
		_last_cycle_time_text = t
		_cycle_time_label.text = t

func _set_progress_text(t: String) -> void:
	if t != _last_progress_text:
		_last_progress_text = t
		_hint_label.text = t

func _set_progress_target(value: float, immediate: bool = false) -> void:
	_progress_target = clampf(value, 0.0, 1.0)
	if immediate or not _progress_initialized:
		_progress_display = _progress_target
		_progress_initialized = true
		if _progress_bar != null:
			_progress_bar.value = _progress_display
	if absf(_progress_display - _progress_target) < 0.0005:
		set_process(false)
	else:
		set_process(true)

func _apply_fast_cycle_style() -> void:
	if _progress_bar == null:
		return
	var track_style := ManaTheme.progress_style(Color("#209b53"))
	track_style.set_border_width_all(1)
	track_style.border_color = Color("#14713d")
	_progress_bar.add_theme_stylebox_override("background", track_style)
	_progress_bar.add_theme_stylebox_override("fill", ManaTheme.progress_style(Color("#35c96f")))
	_progress_bar.tooltip_text = "Ciclo ultrarrápido: indicador estabilizado"

func _set_fast_cycle_active(active: bool) -> void:
	if active == _fast_cycle_active:
		return
	_fast_cycle_active = active
	if _fast_cycle_wave != null:
		_fast_cycle_wave.call("set_active", active)
	if active:
		_set_progress_target(1.0, true)
		_apply_fast_cycle_style()
	else:
		_progress_bar.tooltip_text = "Progresso do ciclo de produção"
		# O estilo do estado operacional pode ter sido substituído pelo verde.
		var current_state := _visual_state
		_visual_state = ""
		_apply_operating_state(current_state)

func _format_duration(seconds: float) -> String:
	var total := maxi(0, ceili(seconds))
	if total < 60:
		return str(total) + "s"
	if total < 3600:
		return "%dm %02ds" % [total / 60, total % 60]
	return "%dh %02dm" % [total / 3600, (total % 3600) / 60]

func _refresh_cycle_display(state: Dictionary, qtd: int, tem_profeta: bool) -> void:
	var remaining := float(state.get("tempo_restante", -1.0))
	var cycle_time := Economy.get_tempo_ciclo(gen_id)
	var progress := GameState.get_progresso_ciclo(gen_id)
	if qtd <= 0:
		_set_fast_cycle_active(false)
		_set_progress_target(progress)
		_apply_operating_state("inactive")
		_set_cycle_state_text("Adquira uma unidade para iniciar")
		_set_cycle_time_text(_format_duration(cycle_time) + " / ciclo")
		_set_progress_text("")
		return
	var fast_cycle := cycle_time < FAST_CYCLE_THRESHOLD
	_set_progress_target(1.0 if fast_cycle else progress, fast_cycle)
	if tem_profeta:
		_apply_operating_state("automatic")
		_set_fast_cycle_active(fast_cycle)
		_set_cycle_state_text("")
		_set_cycle_time_text("" if fast_cycle else "restam " + _format_duration(maxf(remaining, 0.0)))
		_set_progress_text("")
		return
	if remaining < 0.0:
		_apply_operating_state("manual_ready")
		_set_fast_cycle_active(fast_cycle)
		_set_cycle_state_text("Pronto para produzir")
		_set_cycle_time_text("" if fast_cycle else _format_duration(cycle_time) + " / ciclo")
		_set_progress_text("")
		return
	_apply_operating_state("manual_running")
	_set_fast_cycle_active(fast_cycle)
	_set_cycle_state_text("Ciclo em andamento")
	_set_cycle_time_text("" if fast_cycle else "restam " + _format_duration(remaining))
	_set_progress_text("")

func update() -> void:
	_check_locked()
	if is_locked:
		_set_locked_state()
		return

	# Restaura o visual "desbloqueado" (revertendo o estado locked, se aplicavel).
	var was_locked := _card_style_state == "locked"
	_apply_card_style("unlocked")
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_name_label.add_theme_color_override("font_color", TEXT_COLOR)
	_flavor_label.add_theme_color_override("font_color", TEXT_DIM)
	_qty_label.add_theme_color_override("font_color", ManaTheme.GOLD_DARK)
	_rev_label.add_theme_color_override("font_color", GREEN)
	_cycle_state_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	_cycle_time_label.add_theme_color_override("font_color", ManaTheme.GOLD_DARK)
	if was_locked:
		_update_icon_style(data.get("cor", GOLD))
	_icon_label.add_theme_color_override("font_color", TEXT_COLOR)
	_icon_texture_rect.modulate = Color.WHITE

	var state: Dictionary = GameState.geradores.get(gen_id, {})
	var qtd: int = state.get("qtd", 0)
	var tem_profeta: bool = state.get("tem_profeta", false)
	var amount: int = _calc_amount()
	_prophet_badge.visible = tem_profeta and _prophet_texture != null
	if _prophet_badge.visible:
		_prophet_badge.tooltip_text = "Automação ativa: " + str(data.get("profeta_nome", "Profeta"))

	_set_qty_text("Nível " + str(qtd))

	var rev_s: float = GameState.get_receita_por_segundo_gerador(gen_id)
	if rev_s > 0:
		_set_rev_text("+" + NumberFormat.format(rev_s) + "/s")
	elif qtd > 0:
		var rev_ciclo: float = Economy.receita_ciclo(gen_id, qtd) * Economy.get_gerador_multiplicador(gen_id)
		_set_rev_text("+" + NumberFormat.format(rev_ciclo) + "/ciclo")
	else:
		_set_rev_text("Sem produção")

	_refresh_cycle_display(state, qtd, tem_profeta)

	var custo: float = 0.0
	if amount > 0:
		custo = Economy.custo_lote(gen_id, amount, qtd)
	var pode_comprar: bool = amount > 0 and GameState.fe >= custo

	if amount > 0:
		if qtd <= 0:
			_set_buy_text("COMPRAR\nx" + str(amount) + " · " + NumberFormat.format(custo) + " Fé")
		else:
			_set_buy_text("x" + str(amount) + "\n" + NumberFormat.format(custo) + " Fé")
	else:
		_set_buy_text("MAX\nFé insuficiente")

	_buy_btn.disabled = not pode_comprar

	# Botao de profeta: progresso visivel desde a 1a unidade, compra aos 25.
	if tem_profeta or qtd <= 0:
		_prophet_btn.visible = false
	else:
		_prophet_btn.visible = true
		var p_nome: String = data.get("profeta_nome", "?")
		if qtd >= 25:
			_apply_prophet_button_style(true)
			_set_prophet_text("CONTRATAR " + p_nome.to_upper() + "  ·  " + NumberFormat.format(data.profeta_custo) + " Fé")
			_prophet_btn.disabled = GameState.fe < data.profeta_custo
		else:
			_apply_prophet_button_style(false)
			_set_prophet_text("AUTOMAÇÃO  ·  " + p_nome + "  —  " + str(qtd) + "/25 unidades")
			_prophet_btn.disabled = true

func update_progress() -> void:
	# Atualizacao leve: barra, percentual e tempo restante, sem recalcular precos.
	if is_locked:
		return
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	_refresh_cycle_display(state, int(state.get("qtd", 0)), bool(state.get("tem_profeta", false)))

func _set_locked_state() -> void:
	_apply_card_style("locked")
	_set_fast_cycle_active(false)
	_apply_operating_state("locked")
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_buy_btn.disabled = true
	_set_buy_text("BLOQUEADO\nAvance")
	_prophet_btn.visible = false
	_prophet_badge.visible = false
	_set_progress_target(0.0, true)
	_set_progress_text("")
	_set_cycle_state_text("Requer gerador anterior")
	_set_cycle_time_text("")
	_set_qty_text("—")
	_set_rev_text("")
	_name_label.add_theme_color_override("font_color", ManaTheme.DISABLED)
	_flavor_label.add_theme_color_override("font_color", ManaTheme.DISABLED)
	_qty_label.add_theme_color_override("font_color", ManaTheme.DISABLED)
	_rev_label.add_theme_color_override("font_color", ManaTheme.DISABLED)
	_cycle_state_label.add_theme_color_override("font_color", ManaTheme.DISABLED)
	_cycle_time_label.add_theme_color_override("font_color", ManaTheme.DISABLED)
	_icon_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE_LOW, 47, Color(1.0, 1.0, 1.0, 0.09), 2, 8))
	_icon_label.add_theme_color_override("font_color", ManaTheme.DISABLED)
	_icon_texture_rect.modulate = Color(0.55, 0.54, 0.62, 0.72)

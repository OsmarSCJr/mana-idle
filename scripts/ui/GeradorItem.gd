class_name GeradorItem
extends PanelContainer

signal buy_pressed(gen_id: int, amount: int)
signal prophet_pressed(gen_id: int)
signal cycle_started(gen_id: int)

const BG_COLOR: Color = Color(0.087, 0.122, 0.235, 1.0)
const BG_COLOR_LOCKED: Color = Color(0.05, 0.07, 0.14, 1.0)
const BORDER_COLOR: Color = Color(0.15, 0.2, 0.35, 1.0)
const TEXT_COLOR: Color = Color(0.9, 0.9, 0.95, 1.0)
const TEXT_DIM: Color = Color(0.5, 0.5, 0.6, 1.0)
const GOLD: Color = Color(0.94, 0.65, 0.0, 1.0)
const GREEN: Color = Color(0.2, 0.7, 0.3, 1.0)

const MAX_FLOATS: int = 3  # limite de labels "+Fe" simultaneas

var gen_id: int = 0
var data: Dictionary = {}
var is_locked: bool = false
var _modo_compra: String = "x1"

var _icon_rect: ColorRect
var _name_label: Label
var _qty_label: Label
var _rev_label: Label
var _flavor_label: Label
var _progress_bar: ProgressBar
var _hint_label: Label
var _buy_btn: Button
var _prophet_btn: Button
var _pulse_tween: Tween
var _float_count: int = 0

# Cache do ultimo texto aplicado (evita relayout desnecessario a cada tick).
var _last_qty_text: String = ""
var _last_rev_text: String = ""
var _last_buy_text: String = ""
var _last_prophet_text: String = ""

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

func _check_locked() -> void:
	is_locked = not GameState.is_unlocked(gen_id)

func _build_ui() -> void:
	custom_minimum_size = Vector2(0, 180)
	add_theme_stylebox_override("panel", _make_stylebox(BG_COLOR, 1, BORDER_COLOR))
	# O painel inteiro (area do icone/nome) inicia o ciclo ao toque.
	gui_input.connect(_on_panel_input)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	# Secao superior: icone + info (clique aqui inicia o ciclo).
	var top_hbox: HBoxContainer = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	top_hbox.custom_minimum_size = Vector2(0, 80)
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_hbox)

	_icon_rect = ColorRect.new()
	_icon_rect.custom_minimum_size = Vector2(64, 64)
	_icon_rect.color = data.get("cor", Color.WHITE)
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(_icon_rect)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(info_vbox)

	_name_label = Label.new()
	_name_label.text = data.get("nome", "???")
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", TEXT_COLOR)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_child(_name_label)

	var sub_hbox: HBoxContainer = HBoxContainer.new()
	sub_hbox.add_theme_constant_override("separation", 8)
	sub_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_child(sub_hbox)

	_qty_label = Label.new()
	_qty_label.add_theme_font_size_override("font_size", 16)
	_qty_label.add_theme_color_override("font_color", GOLD)
	_qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(_qty_label)

	_rev_label = Label.new()
	_rev_label.add_theme_font_size_override("font_size", 16)
	_rev_label.add_theme_color_override("font_color", GREEN)
	_rev_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rev_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(_rev_label)

	_flavor_label = Label.new()
	_flavor_label.text = data.get("flavor", "")
	_flavor_label.add_theme_font_size_override("font_size", 13)
	_flavor_label.add_theme_color_override("font_color", TEXT_DIM)
	_flavor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flavor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_child(_flavor_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 22)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_progress_bar)

	# Hint sobre a barra de progresso: ensina que o card e tocavel.
	_hint_label = Label.new()
	_hint_label.text = "Toque para produzir"
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", GOLD)
	_hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.visible = false
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.add_child(_hint_label)

	var action_hbox: HBoxContainer = HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(action_hbox)

	_buy_btn = Button.new()
	_buy_btn.text = "Comprar"
	_buy_btn.add_theme_font_size_override("font_size", 18)
	_buy_btn.custom_minimum_size = Vector2(0, 52)
	_buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy_btn.pressed.connect(_on_buy_pressed)
	action_hbox.add_child(_buy_btn)

	_prophet_btn = Button.new()
	_prophet_btn.add_theme_font_size_override("font_size", 14)
	_prophet_btn.custom_minimum_size = Vector2(0, 44)
	_prophet_btn.visible = false
	_prophet_btn.pressed.connect(_on_prophet_pressed)
	vbox.add_child(_prophet_btn)

func _make_stylebox(bg: Color, border_w: int, border_c: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(border_w)
	sb.border_color = border_c
	sb.set_content_margin_all(10)
	sb.set_corner_radius_all(8)
	return sb

func _on_buy_pressed() -> void:
	var amount: int = _calc_amount()
	if amount <= 0:
		return
	buy_pressed.emit(gen_id, amount)

func _on_prophet_pressed() -> void:
	prophet_pressed.emit(gen_id)

func _on_panel_input(event: InputEvent) -> void:
	if is_locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cycle_started.emit(gen_id)

func _on_cycle_complete(id: int, revenue: float) -> void:
	if id != gen_id or not is_visible_in_tree():
		return
	_spawn_float("+" + NumberFormat.format(revenue))

# Label "+Fe" dourada que sobe e some (feedback de producao).
func _spawn_float(texto: String) -> void:
	if _float_count >= MAX_FLOATS:
		return
	_float_count += 1
	var lbl: Label = Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", GOLD)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 10
	lbl.position = Vector2(90, 30)
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
	_pulse_tween.tween_property(_icon_rect, "modulate:a", 0.55, 0.6).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_icon_rect, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	_icon_rect.modulate.a = 1.0

func _calc_amount() -> int:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	var qtd: int = state.get("qtd", 0)
	match _modo_compra:
		"x1": return 1
		"x10": return 10
		"x100": return 100
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

func update() -> void:
	_check_locked()
	if is_locked:
		_set_locked_state()
		return

	# Restaura o visual "desbloqueado" (revertendo o estado locked, se aplicavel).
	_name_label.add_theme_color_override("font_color", TEXT_COLOR)
	_icon_rect.color = data.get("cor", Color.WHITE)

	var state: Dictionary = GameState.geradores.get(gen_id, {})
	var qtd: int = state.get("qtd", 0)
	var tem_profeta: bool = state.get("tem_profeta", false)
	var idle: bool = state.get("tempo_restante", -1.0) < 0.0
	var amount: int = _calc_amount()

	_set_qty_text(str(qtd) + " unid" + (" · AUTO" if tem_profeta else ""))

	var rev_s: float = GameState.get_receita_por_segundo_gerador(gen_id)
	if rev_s > 0:
		_set_rev_text(NumberFormat.format(rev_s) + "/s")
	elif qtd > 0:
		var rev_ciclo: float = Economy.receita_ciclo(gen_id, qtd) * Economy.get_gerador_multiplicador(gen_id)
		_set_rev_text(NumberFormat.format(rev_ciclo) + "/ciclo")
	else:
		_set_rev_text("Compre para comecar")

	_progress_bar.value = GameState.get_progresso_ciclo(gen_id)

	# Hint de toque: tem unidades, sem profeta, ciclo parado.
	var mostrar_hint: bool = qtd > 0 and not tem_profeta and idle
	_hint_label.visible = mostrar_hint
	if mostrar_hint:
		_start_pulse()
	else:
		_stop_pulse()

	var custo: float = 0.0
	if amount > 0:
		custo = Economy.custo_lote(gen_id, amount, qtd)
	var pode_comprar: bool = amount > 0 and GameState.fe >= custo

	match _modo_compra:
		"x1":
			_set_buy_text("Comprar x1 (" + NumberFormat.format(custo) + ")")
		"x10":
			_set_buy_text("Comprar x10 (" + NumberFormat.format(custo) + ")")
		"x100":
			_set_buy_text("Comprar x100 (" + NumberFormat.format(custo) + ")")
		"Max":
			if amount > 0:
				_set_buy_text("Comprar Max (" + str(amount) + ": " + NumberFormat.format(custo) + ")")
			else:
				_set_buy_text("Comprar Max")

	_buy_btn.disabled = not pode_comprar

	# Botao de profeta: progresso visivel desde a 1a unidade, compra aos 25.
	if tem_profeta or qtd <= 0:
		_prophet_btn.visible = false
	else:
		_prophet_btn.visible = true
		var p_nome: String = data.get("profeta_nome", "?")
		if qtd >= 25:
			_set_prophet_text("Contratar " + p_nome + " (" + NumberFormat.format(data.profeta_custo) + ")")
			_prophet_btn.disabled = GameState.fe < data.profeta_custo
		else:
			_set_prophet_text("Profeta " + p_nome + ": " + str(qtd) + "/25 unid")
			_prophet_btn.disabled = true

func update_progress() -> void:
	# Atualizacao leve (so a barra de progresso), chamada a cada tick.
	if is_locked:
		return
	_progress_bar.value = GameState.get_progresso_ciclo(gen_id)

func _set_locked_state() -> void:
	_buy_btn.disabled = true
	_set_buy_text("Bloqueado")
	_prophet_btn.visible = false
	_progress_bar.value = 0
	_hint_label.visible = false
	_stop_pulse()
	_set_qty_text("Bloqueado")
	_set_rev_text("Compre o gerador anterior")
	_name_label.add_theme_color_override("font_color", TEXT_DIM)
	_icon_rect.color = Color(0.2, 0.2, 0.25)

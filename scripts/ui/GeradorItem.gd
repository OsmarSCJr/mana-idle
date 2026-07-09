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
var _buy_btn: Button
var _prophet_btn: Button
var _top_button: Button

func setup(id: int) -> void:
	gen_id = id
	data = Geradores.get_data(id)
	if data.is_empty():
		return
	_build_ui()
	_check_locked()

func set_modo(modo: String) -> void:
	_modo_compra = modo
	update()

func _check_locked() -> void:
	if gen_id == 1:
		is_locked = false
		return
	var prev_state: Dictionary = GameState.geradores.get(gen_id - 1, {})
	is_locked = prev_state.qtd == 0

func _build_ui() -> void:
	custom_minimum_size = Vector2(0, 180)
	add_theme_stylebox_override("panel", _make_stylebox(BG_COLOR, 1, BORDER_COLOR))

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# Top section: clickable area for starting cycle
	_top_button = Button.new()
	_top_button.flat = true
	_top_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_top_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_top_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_top_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	_top_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_top_button.pressed.connect(_on_top_clicked)
	vbox.add_child(_top_button)

	var top_hbox: HBoxContainer = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	_top_button.add_child(top_hbox)

	_icon_rect = ColorRect.new()
	_icon_rect.custom_minimum_size = Vector2(64, 64)
	_icon_rect.color = data.get("cor", Color.WHITE)
	top_hbox.add_child(_icon_rect)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(info_vbox)

	_name_label = Label.new()
	_name_label.text = data.get("nome", "???")
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", TEXT_COLOR)
	info_vbox.add_child(_name_label)

	var sub_hbox: HBoxContainer = HBoxContainer.new()
	sub_hbox.add_theme_constant_override("separation", 8)
	info_vbox.add_child(sub_hbox)

	_qty_label = Label.new()
	_qty_label.add_theme_font_size_override("font_size", 16)
	_qty_label.add_theme_color_override("font_color", GOLD)
	sub_hbox.add_child(_qty_label)

	_rev_label = Label.new()
	_rev_label.add_theme_font_size_override("font_size", 16)
	_rev_label.add_theme_color_override("font_color", GREEN)
	_rev_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_hbox.add_child(_rev_label)

	_flavor_label = Label.new()
	_flavor_label.text = data.get("flavor", "")
	_flavor_label.add_theme_font_size_override("font_size", 13)
	_flavor_label.add_theme_color_override("font_color", TEXT_DIM)
	_flavor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(_flavor_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 20)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	vbox.add_child(_progress_bar)

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

func _on_top_clicked() -> void:
	cycle_started.emit(gen_id)

func _calc_amount() -> int:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	var qtd: int = state.get("qtd", 0)
	match _modo_compra:
		"x1": return 1
		"x10": return 10
		"Max": return max(0, Economy.max_compravel(gen_id, GameState.fe, qtd))
		_: return 1

func _calc_cost() -> float:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	var qtd: int = state.get("qtd", 0)
	var amount: int = _calc_amount()
	if amount <= 0:
		return 0.0
	return Economy.custo_lote(gen_id, amount, qtd)

func update() -> void:
	_check_locked()
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	var qtd: int = state.get("qtd", 0)
	var tem_profeta: bool = state.get("tem_profeta", false)

	if is_locked:
		_set_locked_state()
		return

	_qty_label.text = str(qtd) + " unid"

	var rev_s: float = GameState.get_receita_por_segundo_gerador(gen_id)
	if rev_s > 0:
		_rev_label.text = NumberFormat.format(rev_s) + "/s"
	else:
		var rev_ciclo: float = Economy.receita_ciclo(gen_id, qtd) * Economy.get_gerador_multiplicador(gen_id)
		if qtd > 0:
			_rev_label.text = NumberFormat.format(rev_ciclo) + "/ciclo"
		else:
			_rev_label.text = "Compre para comecar"

	var progress: float = GameState.get_progresso_ciclo(gen_id)
	_progress_bar.value = progress

	var amount: int = _calc_amount()
	var custo: float = _calc_cost()
	var pode_comprar: bool = amount > 0 and GameState.fe >= custo

	match _modo_compra:
		"x1":
			_buy_btn.text = "Comprar x1 (" + NumberFormat.format(custo) + ")"
		"x10":
			_buy_btn.text = "Comprar x10 (" + NumberFormat.format(custo) + ")"
		"Max":
			if amount > 0:
				_buy_btn.text = "Comprar Max (" + str(amount) + ": " + NumberFormat.format(custo) + ")"
			else:
				_buy_btn.text = "Comprar Max"

	_buy_btn.disabled = not pode_comprar

	if Economy.profeta_disponivel(gen_id):
		_prophet_btn.visible = true
		var p_data: Dictionary = Geradores.get_data(gen_id)
		_prophet_btn.text = "Contratar " + p_data.profeta_nome + " (" + NumberFormat.format(p_data.profeta_custo) + ")"
		_prophet_btn.disabled = GameState.fe < p_data.profeta_custo
	else:
		_prophet_btn.visible = false

func _set_locked_state() -> void:
	_buy_btn.disabled = true
	_buy_btn.text = "Bloqueado"
	_prophet_btn.visible = false
	_progress_bar.value = 0
	_qty_label.text = "Bloqueado"
	_rev_label.text = "Compre o gerador anterior"
	_name_label.add_theme_color_override("font_color", TEXT_DIM)
	_icon_rect.color = Color(0.2, 0.2, 0.25)
	_top_button.disabled = true

extends Control

const TICK_RATE: float = 10.0
const BG_COLOR: Color = Color(0.063, 0.063, 0.118, 1.0)
const TOPBAR_COLOR: Color = Color(0.058, 0.102, 0.235, 1.0)
const TEXT_COLOR: Color = Color(0.95, 0.95, 1.0, 1.0)
const TEXT_DIM: Color = Color(0.55, 0.55, 0.65, 1.0)
const GOLD: Color = Color(0.94, 0.65, 0.0, 1.0)
const ACCENT: Color = Color(0.94, 0.29, 0.38, 1.0)
const GREEN: Color = Color(0.2, 0.7, 0.3, 1.0)

var _tick_timer: Timer
var _faith_label: Label
var _santos_label: Label
var _rev_label: Label
var _era_label: Label
var _scroll: ScrollContainer
var _gen_list: VBoxContainer
var _prestige_btn: Button
var _notification_label: Label
var _notification_timer: Timer
var _items: Dictionary = {}
var _game_loaded: bool = false
var _pause_time: float = 0.0
var _modo_compra: String = "x1"
var _modo_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_loaded = SaveSystem.load_game()
	_build_ui()
	_setup_timer()
	_setup_signals()
	_update_all()
	if not _game_loaded:
		EventBus.notification.emit("Bem-vindo a Mana Idle! Clique em Haja Luz para comecar.")

func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root: MarginContainer = MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 8)
	root.add_theme_constant_override("margin_right", 8)
	root.add_theme_constant_override("margin_top", 8)
	root.add_theme_constant_override("margin_bottom", 8)
	add_child(root)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	root.add_child(main_vbox)

	main_vbox.add_child(_build_topbar())
	main_vbox.add_child(_build_modo_selector())
	main_vbox.add_child(_build_era_indicator())
	main_vbox.add_child(_build_scroll())
	main_vbox.add_child(_build_bottombar())
	main_vbox.add_child(_build_notification())

func _build_topbar() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = TOPBAR_COLOR
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var fe_icon: Label = Label.new()
	fe_icon.text = "M"
	fe_icon.add_theme_font_size_override("font_size", 28)
	fe_icon.add_theme_color_override("font_color", GOLD)
	hbox.add_child(fe_icon)

	_faith_label = Label.new()
	_faith_label.add_theme_font_size_override("font_size", 24)
	_faith_label.add_theme_color_override("font_color", TEXT_COLOR)
	hbox.add_child(_faith_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var santos_icon: Label = Label.new()
	santos_icon.text = "S"
	santos_icon.add_theme_font_size_override("font_size", 28)
	santos_icon.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	hbox.add_child(santos_icon)

	_santos_label = Label.new()
	_santos_label.add_theme_font_size_override("font_size", 20)
	_santos_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	hbox.add_child(_santos_label)

	return panel

func _build_modo_selector() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.22, 1.0)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var label: Label = Label.new()
	label.text = "Comprar:"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", TEXT_DIM)
	hbox.add_child(label)

	for modo in ["x1", "x10", "Max"]:
		var btn: Button = Button.new()
		btn.text = modo
		btn.add_theme_font_size_override("font_size", 16)
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_modo_changed.bind(modo))
		_modo_buttons[modo] = btn
		hbox.add_child(btn)

	_update_modo_buttons()
	return panel

func _on_modo_changed(modo: String) -> void:
	_modo_compra = modo
	_update_modo_buttons()
	for item in _items.values():
		item.set_modo(modo)

func _update_modo_buttons() -> void:
	for modo in _modo_buttons:
		var btn: Button = _modo_buttons[modo]
		if modo == _modo_compra:
			btn.add_theme_color_override("font_color", GOLD)
			btn.modulate = Color(1.2, 1.2, 1.2)
		else:
			btn.remove_theme_color_override("font_color")
			btn.modulate = Color.WHITE

func _build_era_indicator() -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	_era_label = Label.new()
	_era_label.add_theme_font_size_override("font_size", 18)
	_era_label.add_theme_color_override("font_color", GOLD)
	_era_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_era_label)

	_rev_label = Label.new()
	_rev_label.add_theme_font_size_override("font_size", 16)
	_rev_label.add_theme_color_override("font_color", GREEN)
	hbox.add_child(_rev_label)

	return hbox

func _build_scroll() -> ScrollContainer:
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_gen_list = VBoxContainer.new()
	_gen_list.add_theme_constant_override("separation", 6)
	_gen_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_gen_list)

	for i in range(1, Geradores.count() + 1):
		var item: GeradorItem = GeradorItem.new()
		item.setup(i)
		item.set_modo(_modo_compra)
		item.buy_pressed.connect(_on_buy)
		item.prophet_pressed.connect(_on_prophet)
		item.cycle_started.connect(_on_cycle_start)
		_gen_list.add_child(item)
		_items[i] = item

	return _scroll

func _build_bottombar() -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	_prestige_btn = Button.new()
	_prestige_btn.text = "Ressurreicao"
	_prestige_btn.add_theme_font_size_override("font_size", 18)
	_prestige_btn.custom_minimum_size = Vector2(0, 56)
	_prestige_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prestige_btn.pressed.connect(_on_prestige)
	hbox.add_child(_prestige_btn)

	var legal_btn: Button = Button.new()
	legal_btn.text = "i"
	legal_btn.add_theme_font_size_override("font_size", 18)
	legal_btn.custom_minimum_size = Vector2(56, 56)
	legal_btn.pressed.connect(_show_legal)
	hbox.add_child(legal_btn)

	return hbox

func _build_notification() -> Control:
	var wrapper: Control = Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_notification_label = Label.new()
	_notification_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_notification_label.position = Vector2(0, -60)
	_notification_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_label.add_theme_font_size_override("font_size", 18)
	_notification_label.add_theme_color_override("font_color", TEXT_COLOR)
	_notification_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_notification_label.add_theme_constant_override("shadow_offset_x", 2)
	_notification_label.add_theme_constant_override("shadow_offset_y", 2)
	_notification_label.visible = false
	wrapper.add_child(_notification_label)

	_notification_timer = Timer.new()
	_notification_timer.wait_time = 3.0
	_notification_timer.one_shot = true
	_notification_timer.timeout.connect(func(): _notification_label.visible = false)
	add_child(_notification_timer)

	return wrapper

func _setup_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0 / TICK_RATE
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_tick_timer.start()

func _setup_signals() -> void:
	EventBus.faith_changed.connect(func(_a: float): _update_topbar())
	EventBus.generator_changed.connect(func(id: int): _update_item(id))
	EventBus.prophet_changed.connect(func(id: int): _update_item(id))
	EventBus.prestige_done.connect(_update_all)
	EventBus.notification.connect(_show_notification)
	EventBus.ui_needs_update.connect(_update_all)

func _on_tick() -> void:
	GameState.process_tick(1.0 / TICK_RATE)
	_update_topbar()
	for item in _items.values():
		item.update()

func _update_topbar() -> void:
	_faith_label.text = NumberFormat.format(GameState.fe)
	_santos_label.text = NumberFormat.format(GameState.santos)
	var rev: float = GameState.get_receita_por_segundo()
	if rev > 0:
		_rev_label.text = "+" + NumberFormat.format(rev) + "/s"
	else:
		_rev_label.text = ""

	var current_era: int = _get_current_era()
	_era_label.text = "Era " + str(current_era) + " - " + Geradores.get_era_name(current_era)

	var santos_prox: int = GameState.get_santos_proximo_prestige()
	if santos_prox > 0:
		_prestige_btn.text = "Ressurreicao (+" + str(santos_prox) + " Santos)"
		_prestige_btn.disabled = false
	else:
		_prestige_btn.text = "Ressurreicao"
		_prestige_btn.disabled = true

func _get_current_era() -> int:
	var highest: int = 1
	for gen_id in GameState.geradores:
		var state: Dictionary = GameState.geradores[gen_id]
		if state.qtd > 0:
			var data: Dictionary = Geradores.get_data(gen_id)
			if data.era > highest:
				highest = data.era
	return highest

func _update_item(gen_id: int) -> void:
	if _items.has(gen_id):
		_items[gen_id].update()
	if _items.has(gen_id + 1):
		_items[gen_id + 1].update()

func _update_all() -> void:
	_update_topbar()
	for item in _items.values():
		item.update()

func _on_buy(gen_id: int, amount: int) -> void:
	GameState.buy_generator(gen_id, amount)

func _on_prophet(gen_id: int) -> void:
	GameState.buy_prophet(gen_id)

func _on_cycle_start(gen_id: int) -> void:
	GameState.start_cycle(gen_id)

func _on_prestige() -> void:
	GameState.prestige()

func _show_notification(msg: String) -> void:
	_notification_label.text = msg
	_notification_label.visible = true
	_notification_label.modulate.a = 1.0
	_notification_timer.start()

	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_notification_label, "modulate:a", 0.0, 1.0)

func _show_legal() -> void:
	var popup: AcceptDialog = AcceptDialog.new()
	popup.title = "Aviso Legal"
	popup.dialog_text = "Mana Idle - Um jogo idle com tematica biblica.\n\nEste jogo e uma adaptacao ficcional inspirada em narrativas biblicas de dominio publico. Nao representa doutrina oficial de nenhuma igreja.\n\nVersiculos biblicos utilizam a versao Almeida Corrigida Fiel (ACF), de dominio publico.\n\nProjeto filantropo: veja a pagina de Transparencia no menu (em breve)."
	popup.get_ok_button().text = "Entendi"
	add_child(popup)
	popup.popup_centered()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveSystem.save_game()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		_pause_time = Time.get_unix_time_from_system()
		SaveSystem.save_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if _pause_time > 0:
			var away: float = Time.get_unix_time_from_system() - _pause_time
			if away > 60.0:
				var ganho: float = GameState.apply_offline_production(away)
				if ganho > 0:
					EventBus.notification.emit("Bem-vindo de volta! +" + NumberFormat.format(ganho) + " de Fe")
			_pause_time = 0.0
			_update_all()

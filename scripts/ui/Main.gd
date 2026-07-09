extends Control

const TICK_RATE: float = 10.0
const BG_COLOR: Color = Color(0.063, 0.063, 0.118, 1.0)
const TOPBAR_COLOR: Color = Color(0.058, 0.102, 0.235, 1.0)
const PANEL_COLOR: Color = Color(0.08, 0.12, 0.22, 1.0)
const CARD_COLOR: Color = Color(0.087, 0.122, 0.235, 1.0)
const BORDER_COLOR: Color = Color(0.15, 0.2, 0.35, 1.0)
const TEXT_COLOR: Color = Color(0.95, 0.95, 1.0, 1.0)
const TEXT_DIM: Color = Color(0.55, 0.55, 0.65, 1.0)
const GOLD: Color = Color(0.94, 0.65, 0.0, 1.0)
const ACCENT: Color = Color(0.94, 0.29, 0.38, 1.0)
const GREEN: Color = Color(0.2, 0.7, 0.3, 1.0)
const SANTO_COLOR: Color = Color(0.7, 0.8, 1.0)

var _tick_timer: Timer
var _faith_label: Label
var _santos_label: Label
var _rev_label: Label
var _era_label: Label
var _gen_list: VBoxContainer
var _prestige_btn: Button
var _notification_label: Label
var _notification_timer: Timer
var _items: Dictionary = {}
var _game_loaded: bool = false
var _pause_time: float = 0.0
var _modo_compra: String = "x1"
var _modo_buttons: Dictionary = {}
var _last_tick_msec: int = 0
var _full_update_counter: int = 0
const FULL_UPDATE_EVERY: int = 3  # atualiza precos/botoes a cada 3 ticks (~3Hz)

# Abas
var _tab_atual: String = "geradores"
var _tab_buttons: Dictionary = {}
var _panel_geradores: VBoxContainer
var _panel_milagres: VBoxContainer
var _panel_santos: VBoxContainer

# Painel Milagres
var _milagres_list: VBoxContainer
var _milagres_cards: Dictionary = {}  # id -> {"btn": Button, "custo": float}
var _milagres_empty_label: Label

# Painel Santos
var _santos_info_label: Label
var _santos_mult_label: Label
var _dadivas_list: VBoxContainer
var _dadivas_cards: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_loaded = SaveSystem.load_game()
	_build_ui()
	_setup_timer()
	_setup_signals()
	_update_all()
	if not _game_loaded:
		EventBus.toast_requested.emit("Bem-vindo a Mana Idle! Compre Haja Luz e toque nele para gerar Fe.")

# ============================================================ UI raiz

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

	# Area central: uma aba visivel por vez.
	var content: Control = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)

	_panel_geradores = _build_panel_geradores()
	_panel_milagres = _build_panel_milagres()
	_panel_santos = _build_panel_santos()
	for panel in [_panel_geradores, _panel_milagres, _panel_santos]:
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(panel)

	main_vbox.add_child(_build_tabbar())
	_build_notification()
	_show_tab("geradores")

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
	santos_icon.add_theme_color_override("font_color", SANTO_COLOR)
	hbox.add_child(santos_icon)

	_santos_label = Label.new()
	_santos_label.add_theme_font_size_override("font_size", 20)
	_santos_label.add_theme_color_override("font_color", SANTO_COLOR)
	hbox.add_child(_santos_label)

	return panel

# ============================================================ Aba Geradores

func _build_panel_geradores() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	vbox.add_child(_build_modo_selector())

	var era_hbox: HBoxContainer = HBoxContainer.new()
	era_hbox.add_theme_constant_override("separation", 8)
	_era_label = Label.new()
	_era_label.add_theme_font_size_override("font_size", 18)
	_era_label.add_theme_color_override("font_color", GOLD)
	_era_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	era_hbox.add_child(_era_label)
	_rev_label = Label.new()
	_rev_label.add_theme_font_size_override("font_size", 16)
	_rev_label.add_theme_color_override("font_color", GREEN)
	era_hbox.add_child(_rev_label)
	vbox.add_child(era_hbox)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_gen_list = VBoxContainer.new()
	_gen_list.add_theme_constant_override("separation", 6)
	_gen_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_gen_list)

	for i in range(1, Geradores.count() + 1):
		var item: GeradorItem = GeradorItem.new()
		item.setup(i)
		item.set_modo(_modo_compra)
		item.buy_pressed.connect(_on_buy)
		item.prophet_pressed.connect(_on_prophet)
		item.cycle_started.connect(_on_cycle_start)
		_gen_list.add_child(item)
		_items[i] = item

	vbox.add_child(scroll)
	return vbox

func _build_modo_selector() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = PANEL_COLOR
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

	for modo in ["x1", "x10", "x100", "Max"]:
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
	# x100 so aparece com o upgrade "Desbloqueio x100"; volta a x1 se travar.
	var x100_btn: Button = _modo_buttons.get("x100")
	if x100_btn != null:
		x100_btn.visible = Economy.is_x100_unlocked()
	if _modo_compra == "x100" and not Economy.is_x100_unlocked():
		_modo_compra = "x1"
		for item in _items.values():
			item.set_modo(_modo_compra)
	for modo in _modo_buttons:
		var btn: Button = _modo_buttons[modo]
		if modo == _modo_compra:
			btn.add_theme_color_override("font_color", GOLD)
			btn.modulate = Color(1.2, 1.2, 1.2)
		else:
			btn.remove_theme_color_override("font_color")
			btn.modulate = Color.WHITE

# ============================================================ Aba Milagres

func _build_panel_milagres() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var header: Label = Label.new()
	header.text = "Milagres & Profetas Especiais"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", GOLD)
	vbox.add_child(header)

	var sub: Label = Label.new()
	sub.text = "Multiplicadores comprados com Fe. Resetam na Ressurreicao."
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(sub)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_milagres_list = VBoxContainer.new()
	_milagres_list.add_theme_constant_override("separation", 6)
	_milagres_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_milagres_list)

	_milagres_empty_label = Label.new()
	_milagres_empty_label.text = "Nenhum milagre disponivel ainda.\nContinue comprando geradores para desbloquear!"
	_milagres_empty_label.add_theme_font_size_override("font_size", 15)
	_milagres_empty_label.add_theme_color_override("font_color", TEXT_DIM)
	_milagres_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_milagres_list.add_child(_milagres_empty_label)

	return vbox

func _refresh_milagres() -> void:
	var disponiveis: Array = Upgrades.disponiveis()
	var ids: Array = disponiveis.map(func(u): return u.id)
	var built_ids: Array = _milagres_cards.keys()
	built_ids.sort()
	var sorted_ids: Array = ids.duplicate()
	sorted_ids.sort()

	if built_ids != sorted_ids:
		# Conjunto mudou: reconstroi a lista.
		for card_id in _milagres_cards:
			_milagres_cards[card_id].panel.queue_free()
		_milagres_cards.clear()
		for u in disponiveis:
			var card: Dictionary = _build_upgrade_card(u, false)
			_milagres_list.add_child(card.panel)
			_milagres_cards[u.id] = card
	_milagres_empty_label.visible = disponiveis.is_empty()

	for card_id in _milagres_cards:
		var card: Dictionary = _milagres_cards[card_id]
		card.btn.disabled = GameState.fe < card.custo

# Card generico de compra: usado por Milagres (custo em Fe) e Dadivas (custo em Santos).
func _build_upgrade_card(u: Dictionary, custo_em_santos: bool) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = CARD_COLOR
	sb.set_border_width_all(1)
	sb.border_color = BORDER_COLOR
	sb.set_content_margin_all(10)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var info: VBoxContainer = VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var nome: Label = Label.new()
	var prefixo: String = "[Profeta] " if u.get("categoria", "") == "profeta" else ""
	nome.text = prefixo + u.nome
	nome.add_theme_font_size_override("font_size", 18)
	nome.add_theme_color_override("font_color", TEXT_COLOR)
	info.add_child(nome)

	var efeito: Label = Label.new()
	efeito.text = u.efeito
	efeito.add_theme_font_size_override("font_size", 14)
	efeito.add_theme_color_override("font_color", GREEN)
	efeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(efeito)

	var flavor: Label = Label.new()
	flavor.text = u.get("flavor", "")
	flavor.add_theme_font_size_override("font_size", 12)
	flavor.add_theme_color_override("font_color", TEXT_DIM)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(flavor)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(150, 52)
	btn.add_theme_font_size_override("font_size", 15)
	if custo_em_santos:
		btn.text = str(int(u.custo)) + " Santos"
		btn.pressed.connect(func(): GameState.buy_dadiva(u.id))
	else:
		btn.text = NumberFormat.format(u.custo) + " Fe"
		btn.pressed.connect(func(): GameState.buy_upgrade(u.id))
	hbox.add_child(btn)

	return {"panel": panel, "btn": btn, "custo": float(u.custo)}

# ============================================================ Aba Santos

func _build_panel_santos() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var header: Label = Label.new()
	header.text = "Santos & Ressurreicao"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", SANTO_COLOR)
	vbox.add_child(header)

	var info_panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = PANEL_COLOR
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	info_panel.add_theme_stylebox_override("panel", sb)
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_panel.add_child(info_vbox)

	_santos_info_label = Label.new()
	_santos_info_label.add_theme_font_size_override("font_size", 16)
	_santos_info_label.add_theme_color_override("font_color", TEXT_COLOR)
	info_vbox.add_child(_santos_info_label)

	_santos_mult_label = Label.new()
	_santos_mult_label.add_theme_font_size_override("font_size", 14)
	_santos_mult_label.add_theme_color_override("font_color", TEXT_DIM)
	info_vbox.add_child(_santos_mult_label)
	vbox.add_child(info_panel)

	_prestige_btn = Button.new()
	_prestige_btn.text = "Ressurreicao"
	_prestige_btn.add_theme_font_size_override("font_size", 18)
	_prestige_btn.custom_minimum_size = Vector2(0, 56)
	_prestige_btn.pressed.connect(_on_prestige)
	vbox.add_child(_prestige_btn)

	var dadivas_header: Label = Label.new()
	dadivas_header.text = "Dadivas (permanentes, custam Santos)"
	dadivas_header.add_theme_font_size_override("font_size", 16)
	dadivas_header.add_theme_color_override("font_color", GOLD)
	vbox.add_child(dadivas_header)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_dadivas_list = VBoxContainer.new()
	_dadivas_list.add_theme_constant_override("separation", 6)
	_dadivas_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_dadivas_list)

	var legal_btn: Button = Button.new()
	legal_btn.text = "Aviso Legal"
	legal_btn.add_theme_font_size_override("font_size", 14)
	legal_btn.custom_minimum_size = Vector2(0, 44)
	legal_btn.pressed.connect(_show_legal)
	vbox.add_child(legal_btn)

	return vbox

func _refresh_santos() -> void:
	var bonus_pct: float = (Economy.get_multiplicador_santos() - 1.0) * 100.0
	_santos_info_label.text = str(GameState.santos) + " Santos · +" + String.num(bonus_pct, 1) + "% producao global"
	_santos_mult_label.text = "Fe total nesta vida: " + NumberFormat.format(GameState.fe_total_vida) + " · Prestiges: " + str(GameState.estatisticas.prestiges)

	var santos_prox: int = GameState.get_santos_proximo_prestige()
	if santos_prox > 0:
		_prestige_btn.text = "Ressurreicao (+" + str(santos_prox) + " Santos)"
		_prestige_btn.disabled = false
	else:
		_prestige_btn.text = "Ressurreicao (requer " + NumberFormat.format(Economy.PRESTIGE_DIVISOR) + " de Fe total)"
		_prestige_btn.disabled = true

	var disponiveis: Array = Dadivas.disponiveis()
	var ids: Array = disponiveis.map(func(d): return d.id)
	var built_ids: Array = _dadivas_cards.keys()
	built_ids.sort()
	var sorted_ids: Array = ids.duplicate()
	sorted_ids.sort()
	if built_ids != sorted_ids:
		for card_id in _dadivas_cards:
			_dadivas_cards[card_id].panel.queue_free()
		_dadivas_cards.clear()
		for d in disponiveis:
			var card: Dictionary = _build_upgrade_card(d, true)
			_dadivas_list.add_child(card.panel)
			_dadivas_cards[d.id] = card
	for card_id in _dadivas_cards:
		var card: Dictionary = _dadivas_cards[card_id]
		card.btn.disabled = GameState.santos < int(card.custo)

# ============================================================ Abas

func _build_tabbar() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = PANEL_COLOR
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	for tab in [["geradores", "Geradores"], ["milagres", "Milagres"], ["santos", "Santos"]]:
		var btn: Button = Button.new()
		btn.text = tab[1]
		btn.add_theme_font_size_override("font_size", 17)
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_show_tab.bind(tab[0]))
		_tab_buttons[tab[0]] = btn
		hbox.add_child(btn)

	return panel

func _show_tab(tab: String) -> void:
	_tab_atual = tab
	_panel_geradores.visible = tab == "geradores"
	_panel_milagres.visible = tab == "milagres"
	_panel_santos.visible = tab == "santos"
	for t in _tab_buttons:
		var btn: Button = _tab_buttons[t]
		if t == tab:
			btn.add_theme_color_override("font_color", GOLD)
			btn.modulate = Color(1.2, 1.2, 1.2)
		else:
			btn.remove_theme_color_override("font_color")
			btn.modulate = Color.WHITE
	match tab:
		"milagres":
			_refresh_milagres()
		"santos":
			_refresh_santos()
		"geradores":
			for item in _items.values():
				item.update()

func _update_tab_badges() -> void:
	# Mostra quantos milagres estao disponiveis na aba.
	var n: int = Upgrades.disponiveis().size()
	var btn: Button = _tab_buttons.get("milagres")
	if btn != null:
		btn.text = "Milagres" + (" (" + str(n) + ")" if n > 0 else "")

# ============================================================ Notificacao (toast)

func _build_notification() -> void:
	_notification_label = Label.new()
	_notification_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_notification_label.position = Vector2(0, -100)
	_notification_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_label.add_theme_font_size_override("font_size", 18)
	_notification_label.add_theme_color_override("font_color", TEXT_COLOR)
	_notification_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_notification_label.add_theme_constant_override("shadow_offset_x", 2)
	_notification_label.add_theme_constant_override("shadow_offset_y", 2)
	_notification_label.visible = false
	_notification_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_label.z_index = 100
	add_child(_notification_label)

	_notification_timer = Timer.new()
	_notification_timer.wait_time = 3.0
	_notification_timer.one_shot = true
	_notification_timer.timeout.connect(func(): _notification_label.visible = false)
	add_child(_notification_timer)

func _show_notification(msg: String) -> void:
	_notification_label.text = msg
	_notification_label.visible = true
	_notification_label.modulate.a = 1.0
	_notification_timer.start()

	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_notification_label, "modulate:a", 0.0, 1.0)

# ============================================================ Loop / sinais

func _setup_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0 / TICK_RATE
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_tick_timer.start()
	_last_tick_msec = Time.get_ticks_msec()

func _setup_signals() -> void:
	EventBus.faith_changed.connect(func(_a: float): _update_topbar())
	EventBus.generator_changed.connect(func(id: int): _update_item(id))
	EventBus.prophet_changed.connect(func(id: int): _update_item(id))
	EventBus.prestige_done.connect(_on_prestige_done)
	EventBus.toast_requested.connect(_show_notification)
	EventBus.ui_needs_update.connect(_update_all)
	EventBus.upgrade_purchased.connect(func(_id: String): _on_economy_changed())
	EventBus.dadiva_purchased.connect(func(_id: String): _on_economy_changed())

func _on_economy_changed() -> void:
	# Descontos/velocidades mudam precos e taxas: atualiza tudo.
	_update_modo_buttons()
	_update_all()
	if _tab_atual == "milagres":
		_refresh_milagres()
	elif _tab_atual == "santos":
		_refresh_santos()

func _on_prestige_done() -> void:
	_update_modo_buttons()
	_update_all()
	if _tab_atual == "milagres":
		_refresh_milagres()
	elif _tab_atual == "santos":
		_refresh_santos()

func _on_tick() -> void:
	# Usa o tempo real decorrido em vez do nominal (imune a hitches/lag do Timer).
	var now: int = Time.get_ticks_msec()
	var delta: float = float(now - _last_tick_msec) / 1000.0
	_last_tick_msec = now
	if delta <= 0.0:
		delta = 1.0 / TICK_RATE
	GameState.process_tick(delta)
	_update_topbar()
	# Progresso dos ciclos anima a cada tick (barato); resto so a cada N ticks.
	_full_update_counter += 1
	var do_full: bool = _full_update_counter >= FULL_UPDATE_EVERY
	if do_full:
		_full_update_counter = 0
		_update_tab_badges()
	match _tab_atual:
		"geradores":
			for item in _items.values():
				if do_full:
					item.update()
				else:
					item.update_progress()
		"milagres":
			if do_full:
				_refresh_milagres()
		"santos":
			if do_full:
				_refresh_santos()

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
	_update_tab_badges()
	for item in _items.values():
		item.update()

func _on_buy(gen_id: int, amount: int) -> void:
	GameState.buy_generator(gen_id, amount)

func _on_prophet(gen_id: int) -> void:
	GameState.buy_prophet(gen_id)

func _on_cycle_start(gen_id: int) -> void:
	GameState.start_cycle(gen_id)

func _on_prestige() -> void:
	var ganhos: int = GameState.get_santos_proximo_prestige()
	if ganhos <= 0:
		return
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Ressurreicao"
	dialog.dialog_text = "Renascer agora reseta Fe, geradores, profetas e milagres.\n\nVoce ganhara +" + str(ganhos) + " Santos (bonus permanente de +" + str(ganhos * 2) + "% de producao).\nDadivas compradas permanecem.\n\nConfirmar?"
	dialog.get_ok_button().text = "Ressuscitar"
	dialog.get_cancel_button().text = "Ainda nao"
	dialog.confirmed.connect(func():
		GameState.prestige()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

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
			# Credita produzido durante a pausa (o cap fica em apply_offline_production).
			if away > 5.0:
				var ganho: float = GameState.apply_offline_production(away)
				if ganho > 0 and away > 60.0:
					EventBus.toast_requested.emit("Bem-vindo de volta! +" + NumberFormat.format(ganho) + " de Fe")
			_last_tick_msec = Time.get_ticks_msec()
			_pause_time = 0.0
			_update_all()

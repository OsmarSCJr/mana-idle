extends Control

const TICK_RATE: float = 10.0
const BG_COLOR: Color = ManaTheme.BACKGROUND_TOP
const TOPBAR_COLOR: Color = ManaTheme.SURFACE_LOW
const PANEL_COLOR: Color = ManaTheme.SURFACE
const CARD_COLOR: Color = ManaTheme.SURFACE_HIGH
const BORDER_COLOR: Color = ManaTheme.OUTLINE
const TEXT_COLOR: Color = ManaTheme.CREAM
const TEXT_DIM: Color = ManaTheme.CREAM_MUTED
const GOLD: Color = ManaTheme.GOLD
const ACCENT: Color = ManaTheme.GOLD_LIGHT
const GREEN: Color = ManaTheme.GREEN
const SANTO_COLOR: Color = ManaTheme.SILVER

var _tick_timer: Timer
var _faith_label: Label
var _santos_label: Label
var _rev_label: Label
var _era_label: Label
var _era_progress: ProgressBar
var _gen_list: VBoxContainer
var _generator_scroll: ScrollContainer
var _future_boost_space: Control
var _prestige_btn: Button
var _notification_label: Label
var _notification_timer: Timer
var _items: Dictionary = {}
var _game_loaded: bool = false
var _pause_time: float = 0.0
const MODO_ORDEM: Array[String] = ["x1", "x10", "x100", "Next", "Max"]
var _modo_compra: String = "x1"
var _modo_btn: Button = null
var _last_tick_msec: int = 0
var _full_update_counter: int = 0
const FULL_UPDATE_EVERY: int = 3  # atualiza precos/botoes a cada 3 ticks (~3Hz)

# Abas
var _tab_atual: String = "geradores"
var _tab_buttons: Dictionary = {}
var _panel_geradores: VBoxContainer
var _panel_milagres: VBoxContainer
var _panel_estudo: StudyPanel
var _panel_santos: VBoxContainer
var _current_adventure: String = "jornada"
var _adventure_buttons: Dictionary = {}

# Painel Milagres
var _milagres_list: VBoxContainer
var _milagres_cards: Dictionary = {}  # id -> {"btn": Button, "custo": float}
var _milagres_empty_label: Label

# Painel Santos
var _santos_info_label: Label
var _santos_mult_label: Label
var _relics_label: Label
var _dadivas_list: VBoxContainer
var _dadivas_cards: Dictionary = {}

# Painel Gemas
const VIDEO_COOLDOWN_S: int = 300
const VIDEO_GEMAS: int = 5
var _panel_gemas: VBoxContainer
var _gemas_label: Label
var _gemas_total_label: Label
var _video_btn: Button
var _video_status_label: Label
var _video_cooldown_until: float = 0.0
var _adventure_icons: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_ui_config()
	theme = ManaTheme.make_theme()
	_game_loaded = SaveSystem.load_game()
	_build_ui()
	_setup_timer()
	_setup_signals()
	_update_all()
	if not _game_loaded:
		EventBus.toast_requested.emit("Bem-vindo a Maná Idle! Compre Haja Luz e toque no cartão para gerar Fé.")
	if SaveSystem.pending_offline_gain > 0.0:
		_show_offline_modal(SaveSystem.pending_offline_gain)
		SaveSystem.pending_offline_gain = 0.0

# ============================================================ UI raiz

func _build_ui() -> void:
	var bg := SacredBackground.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root: MarginContainer = MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 18)
	root.add_child(main_vbox)

	main_vbox.add_child(_build_topbar())

	# Area central: uma aba visivel por vez.
	var content: Control = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)

	_panel_geradores = _build_panel_geradores()
	_panel_milagres = _build_panel_milagres()
	_panel_estudo = StudyPanel.new()
	_panel_santos = _build_panel_santos()
	_panel_gemas = _build_panel_gemas()
	for panel in [_panel_geradores, _panel_milagres, _panel_estudo, _panel_santos, _panel_gemas]:
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(panel)

	main_vbox.add_child(_build_tabbar())
	_build_notification()
	_show_tab("geradores")

func _build_topbar() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 116)
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color(0.055, 0.055, 0.16, 0.96), 28, Color(1.0, 0.77, 0.42, 0.18), 2, 20, true))

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)

	var brand: VBoxContainer = VBoxContainer.new()
	brand.add_theme_constant_override("separation", -4)
	brand.custom_minimum_size = Vector2(250, 0)
	hbox.add_child(brand)
	var brand_name := Label.new()
	brand_name.text = "✦  Maná Idle"
	brand_name.add_theme_font_override("font", ManaTheme.serif_bold())
	brand_name.add_theme_font_size_override("font_size", 48)
	brand_name.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	brand.add_child(brand_name)
	var brand_sub := Label.new()
	brand_sub.text = "BÍBLIA CLICKER"
	brand_sub.add_theme_font_override("font", ManaTheme.body_semibold())
	brand_sub.add_theme_font_size_override("font_size", 22)
	brand_sub.add_theme_color_override("font_color", TEXT_DIM)
	brand.add_child(brand_sub)

	var fe_pill := _build_resource_pill("FÉ", GOLD)
	_faith_label = fe_pill.value
	hbox.add_child(fe_pill.panel)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var santos_pill := _build_resource_pill("SANTOS", SANTO_COLOR)
	_santos_label = santos_pill.value
	hbox.add_child(santos_pill.panel)

	var settings := Button.new()
	settings.text = "⚙"
	settings.tooltip_text = "Configurações"
	settings.custom_minimum_size = Vector2(72, 72)
	settings.add_theme_font_size_override("font_size", 41)
	settings.pressed.connect(_show_settings)
	hbox.add_child(settings)

	return panel

func _build_resource_pill(caption: String, accent: Color) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(182, 72)
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color(0.11, 0.11, 0.24, 0.92), 28, Color(accent, 0.34), 2, 16))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	if caption == "SANTOS":
		var icon_texture := TextureRect.new()
		icon_texture.texture = GameArt.SANTOS_ICON
		icon_texture.custom_minimum_size = Vector2(38, 38)
		icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_texture)
	else:
		var icon := Label.new()
		icon.text = "✦"
		icon.add_theme_font_override("font", ManaTheme.serif_bold())
		icon.add_theme_font_size_override("font_size", 34)
		icon.add_theme_color_override("font_color", accent)
		row.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -5)
	row.add_child(text)
	var label := Label.new()
	label.text = caption
	label.add_theme_font_override("font", ManaTheme.body_semibold())
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", TEXT_DIM)
	text.add_child(label)
	var value := Label.new()
	value.add_theme_font_override("font", ManaTheme.body_semibold())
	value.add_theme_font_size_override("font_size", 34)
	value.add_theme_color_override("font_color", accent)
	text.add_child(value)
	return {"panel": panel, "value": value}

# ============================================================ Aba Geradores

func _build_panel_geradores() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	var journey_header := PanelContainer.new()
	journey_header.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color(0.08, 0.08, 0.20, 0.86), 20, Color(1.0, 0.77, 0.42, 0.16), 1, 18))
	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 10)
	journey_header.add_child(header_vbox)
	var era_hbox: HBoxContainer = HBoxContainer.new()
	era_hbox.add_theme_constant_override("separation", 12)
	_era_label = Label.new()
	_era_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_era_label.add_theme_font_size_override("font_size", 43)
	_era_label.add_theme_color_override("font_color", ManaTheme.CREAM)
	_era_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_era_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_era_label.clip_text = true
	era_hbox.add_child(_era_label)
	_rev_label = Label.new()
	_rev_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_rev_label.add_theme_font_size_override("font_size", 31)
	_rev_label.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	era_hbox.add_child(_rev_label)
	era_hbox.add_child(_build_modo_selector())
	header_vbox.add_child(era_hbox)
	_era_progress = ProgressBar.new()
	_era_progress.custom_minimum_size = Vector2(0, 18)
	_era_progress.min_value = 0.0
	_era_progress.max_value = 1.0
	_era_progress.show_percentage = false
	header_vbox.add_child(_era_progress)
	vbox.add_child(journey_header)

	# As aventuras funcionam como marcadores de capítulo presos ao volume que
	# contém seus geradores. A faixa vazia à direita fica fora do livro e será
	# ocupada pelos boosts em uma etapa futura.
	var journey_split := HBoxContainer.new()
	journey_split.add_theme_constant_override("separation", 16)
	journey_split.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var book_stack := VBoxContainer.new()
	book_stack.add_theme_constant_override("separation", -2)
	book_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book_stack.add_child(_build_adventure_selector())

	var book_panel := PanelContainer.new()
	book_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color(0.055, 0.055, 0.145, 0.97), 22, Color(1.0, 0.77, 0.42, 0.24), 2, 18, true))

	_generator_scroll = ScrollContainer.new()
	_generator_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_generator_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_generator_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_gen_list = VBoxContainer.new()
	_gen_list.add_theme_constant_override("separation", 16)
	_gen_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_generator_scroll.add_child(_gen_list)

	for i in range(1, Geradores.count() + 1):
		var item: GeradorItem = GeradorItem.new()
		item.setup(i)
		item.set_icon_texture(GameArt.generator_icon(i))
		item.set_prophet_texture(GameArt.automation_portrait(i))
		item.set_modo(_modo_compra)
		item.buy_pressed.connect(_on_buy)
		item.prophet_pressed.connect(_on_prophet)
		item.cycle_started.connect(_on_cycle_start)
		item.visible = Geradores.get_adventure_for_id(i) == _current_adventure
		_gen_list.add_child(item)
		_items[i] = item

	book_panel.add_child(_generator_scroll)
	book_stack.add_child(book_panel)
	journey_split.add_child(book_stack)
	_future_boost_space = _build_future_boost_space()
	journey_split.add_child(_future_boost_space)
	vbox.add_child(journey_split)
	ManaTheme.enable_touch_scroll(_generator_scroll, _gen_list)
	return vbox

func _build_adventure_selector() -> MarginContainer:
	var panel := MarginContainer.new()
	panel.custom_minimum_size = Vector2(0, 76)
	panel.add_theme_constant_override("margin_left", 18)
	panel.add_theme_constant_override("margin_right", 18)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for entry in [
		["jornada", "JORNADA"],
		["vida_cristo", "VIDA DE CRISTO"],
		["igreja_apocalipse", "IGREJA & APOC."],
	]:
		var button := Button.new()
		button.text = entry[1]
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_END
		button.add_theme_font_override("font", ManaTheme.body_semibold())
		button.add_theme_font_size_override("font_size", 21)
		button.pressed.connect(_on_adventure_pressed.bind(entry[0]))
		_adventure_buttons[entry[0]] = button
		row.add_child(button)
	_refresh_adventure_selector()
	return panel

func _adventure_tab_style(bg: Color, border: Color, active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2 if active else 1)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	if active:
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
		style.shadow_size = 7
		style.shadow_offset = Vector2(0, -2)
	return style

func _build_future_boost_space() -> Control:
	# Coluna lateral: icones de compra dos capitulos no topo; o espaco restante
	# fica reservado para os boosts (ver PLANO_GEMAS.md).
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(214, 0)
	column.add_theme_constant_override("separation", 12)

	var header := Label.new()
	header.text = "CAPÍTULOS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_override("font", ManaTheme.body_semibold())
	header.add_theme_font_size_override("font_size", 19)
	header.add_theme_color_override("font_color", TEXT_DIM)
	column.add_child(header)

	for adventure_id in ["vida_cristo", "igreja_apocalipse"]:
		var btn := Button.new()
		var first_gen := int(GameState.ADVENTURES[adventure_id]["first_generator"])
		btn.icon = GameArt.generator_icon(first_gen)
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", 92)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.custom_minimum_size = Vector2(0, 196)
		btn.add_theme_font_override("font", ManaTheme.body_semibold())
		btn.add_theme_font_size_override("font_size", 19)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_adventure_pressed.bind(adventure_id))
		_adventure_icons[adventure_id] = btn
		column.add_child(btn)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(filler)

	_refresh_adventure_icons()
	return column

func _refresh_adventure_icons() -> void:
	for adventure_id in _adventure_icons:
		var key := str(adventure_id)
		var btn: Button = _adventure_icons[key]
		var status := GameState.get_adventure_unlock_status(key)
		var chapter := "II" if key == "vida_cristo" else "III"
		var nome := "CRISTO" if key == "vida_cristo" else "APOC."
		if bool(status.get("unlocked", false)):
			btn.text = chapter + " · " + nome + "\nABERTO"
			btn.modulate = Color.WHITE
			btn.tooltip_text = "Abrir capítulo: " + _adventure_label(key)
		else:
			var custo_txt: String
			if str(status.get("currency", "fe")) == "gemas":
				custo_txt = str(int(status.get("entry_cost", 0.0))) + " Gemas"
			else:
				custo_txt = NumberFormat.format(float(status.get("entry_cost", 0.0))) + " Fé"
			btn.text = chapter + " · " + nome + "\n🔒 " + custo_txt
			btn.modulate = Color.WHITE if bool(status.get("can_unlock", false)) else Color(0.72, 0.72, 0.78)
			btn.tooltip_text = "Desbloquear " + _adventure_label(key) + " por " + custo_txt

func _on_adventure_pressed(adventure_id: String) -> void:
	if GameState.is_adventure_unlocked(adventure_id):
		_show_tab("geradores")
		_select_adventure(adventure_id)
		return
	var status := GameState.get_adventure_unlock_status(adventure_id)
	var em_gemas: bool = str(status.get("currency", "fe")) == "gemas"
	if not bool(status.get("can_unlock", false)):
		if em_gemas:
			EventBus.toast_requested.emit("Capítulo bloqueado: custa " + str(int(status.entry_cost)) + " Gemas. Veja a aba GEMAS para conseguir mais.")
			_show_tab("gemas")
		else:
			var requirement := NumberFormat.format(float(status.get("historical_requirement", 0.0)))
			EventBus.toast_requested.emit("Aventura bloqueada: alcance " + requirement + " de Fé histórica e reúna o custo de entrada.")
		return
	var custo_txt: String = (str(int(status.entry_cost)) + " Gemas") if em_gemas else (NumberFormat.format(float(status.entry_cost)) + " de Fé")
	var dialog := ConfirmationDialog.new()
	dialog.title = "Desbloquear aventura"
	dialog.dialog_text = "Desbloquear " + _adventure_label(adventure_id) + " por " + custo_txt + "?\n\nO acesso será permanente, inclusive após a Ressurreição."
	dialog.get_ok_button().text = "Desbloquear"
	dialog.get_cancel_button().text = "Agora não"
	dialog.confirmed.connect(func():
		if GameState.unlock_adventure(adventure_id):
			SaveSystem.save_game()
			_select_adventure(adventure_id)
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

func _adventure_label(adventure_id: String) -> String:
	match adventure_id:
		"vida_cristo": return "Vida de Cristo"
		"igreja_apocalipse": return "Igreja & Apocalipse"
		_: return "Jornada Principal"

func _select_adventure(adventure_id: String) -> void:
	_current_adventure = adventure_id
	for gen_id in _items:
		var item: GeradorItem = _items[gen_id]
		item.visible = Geradores.get_adventure_for_id(gen_id) == adventure_id
	_refresh_adventure_selector()
	if _generator_scroll != null:
		_generator_scroll.set_deferred("scroll_vertical", 0)
	_update_topbar()

func _refresh_adventure_selector() -> void:
	_refresh_adventure_icons()
	for adventure_id in _adventure_buttons:
		var adventure_key := str(adventure_id)
		var button: Button = _adventure_buttons[adventure_id]
		var unlocked: bool = GameState.is_adventure_unlocked(adventure_key)
		var active: bool = adventure_key == _current_adventure
		var chapter: String = "I"
		if adventure_key == "vida_cristo":
			chapter = "II"
		elif adventure_key == "igreja_apocalipse":
			chapter = "III"
		var tab_title: String = "JORNADA"
		if adventure_key == "vida_cristo":
			tab_title = "VIDA DE CRISTO"
		elif adventure_key == "igreja_apocalipse":
			tab_title = "IGREJA & APOC."
		var locked_title := tab_title
		if adventure_key == "vida_cristo":
			locked_title = "CRISTO"
		elif adventure_key == "igreja_apocalipse":
			locked_title = "APOC."
		button.text = chapter + " · " + tab_title if unlocked else chapter + " · " + locked_title + " · BLOQ."
		button.add_theme_font_size_override("font_size", 21 if unlocked else 17)
		if not unlocked:
			button.tooltip_text = "Capítulo bloqueado: " + _adventure_label(adventure_key)
		else:
			button.tooltip_text = ("Capítulo aberto: " if active else "Abrir capítulo: ") + _adventure_label(adventure_key)
		button.custom_minimum_size = Vector2(0, 74 if active else 56)
		if active:
			button.add_theme_color_override("font_color", ManaTheme.INK)
			button.add_theme_color_override("font_hover_color", ManaTheme.INK)
			button.add_theme_stylebox_override("normal", _adventure_tab_style(ManaTheme.GOLD, ManaTheme.GOLD_LIGHT, true))
			button.add_theme_stylebox_override("hover", _adventure_tab_style(ManaTheme.GOLD_LIGHT, Color("#ffdda8"), true))
			button.add_theme_stylebox_override("pressed", _adventure_tab_style(Color("#d89200"), ManaTheme.GOLD_DARK, true))
		else:
			button.add_theme_color_override("font_color", ManaTheme.CREAM if unlocked else ManaTheme.DISABLED)
			button.add_theme_color_override("font_hover_color", ManaTheme.GOLD_LIGHT if unlocked else ManaTheme.CREAM_MUTED)
			button.add_theme_stylebox_override("normal", _adventure_tab_style(ManaTheme.SURFACE_HIGH, Color(1.0, 0.77, 0.42, 0.16), false))
			button.add_theme_stylebox_override("hover", _adventure_tab_style(ManaTheme.SURFACE_HIGHEST, Color(1.0, 0.77, 0.42, 0.34), false))
			button.add_theme_stylebox_override("pressed", _adventure_tab_style(ManaTheme.SURFACE, ManaTheme.GOLD_DARK, false))

func _build_modo_selector() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(128, 0)
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, 0))

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	# Botao unico: cada toque avanca para o proximo modo da ordem.
	_modo_btn = Button.new()
	_modo_btn.add_theme_font_override("font", ManaTheme.body_semibold())
	_modo_btn.add_theme_font_size_override("font_size", 22)
	_modo_btn.custom_minimum_size = Vector2(128, 54)
	_modo_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_modo_btn.tooltip_text = "Alternar quantidade comprada por toque"
	_modo_btn.add_theme_color_override("font_color", ManaTheme.INK)
	_modo_btn.add_theme_color_override("font_hover_color", ManaTheme.INK)
	_modo_btn.add_theme_stylebox_override("normal", ManaTheme.button_style(ManaTheme.GOLD, ManaTheme.GOLD_LIGHT, 18, 2, 14, 8))
	_modo_btn.add_theme_stylebox_override("hover", ManaTheme.button_style(ManaTheme.GOLD_LIGHT, ManaTheme.GOLD_LIGHT, 18, 2, 14, 8))
	_modo_btn.pressed.connect(_on_modo_pressed)
	hbox.add_child(_modo_btn)

	_update_modo_buttons()
	return panel

func _on_modo_pressed() -> void:
	var idx: int = MODO_ORDEM.find(_modo_compra)
	idx = (idx + 1) % MODO_ORDEM.size()
	# x100 exige o upgrade "Desbloqueio x100"; pula direto para Next se travado.
	if MODO_ORDEM[idx] == "x100" and not Economy.is_x100_unlocked():
		idx = (idx + 1) % MODO_ORDEM.size()
	_modo_compra = MODO_ORDEM[idx]
	_update_modo_buttons()
	for item in _items.values():
		item.set_modo(_modo_compra)

func _update_modo_buttons() -> void:
	if _modo_compra == "x100" and not Economy.is_x100_unlocked():
		_modo_compra = "x1"
		for item in _items.values():
			item.set_modo(_modo_compra)
	if _modo_btn != null:
		_modo_btn.text = _modo_label(_modo_compra)

func _modo_label(modo: String) -> String:
	match modo:
		"Next": return "MARCO"
		"Max": return "MAX"
		_: return modo

# ============================================================ Aba Milagres

func _build_panel_milagres() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	var header: Label = Label.new()
	header.text = "Bênçãos & Upgrades"
	header.add_theme_font_override("font", ManaTheme.serif_bold())
	header.add_theme_font_size_override("font_size", 50)
	header.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	vbox.add_child(header)

	var sub: Label = Label.new()
	sub.text = "Fortaleça sua jornada com bênçãos, milagres e profetas especiais."
	sub.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT)
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(sub)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_milagres_list = VBoxContainer.new()
	_milagres_list.add_theme_constant_override("separation", 16)
	_milagres_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_milagres_list)
	ManaTheme.enable_touch_scroll(scroll, _milagres_list)

	_milagres_empty_label = Label.new()
	_milagres_empty_label.text = "Mistérios futuros aguardam.\nContinue sua jornada para revelar novas bênçãos."
	_milagres_empty_label.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT)
	_milagres_empty_label.add_theme_font_size_override("font_size", 30)
	_milagres_empty_label.add_theme_color_override("font_color", TEXT_DIM)
	_milagres_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_milagres_empty_label.custom_minimum_size = Vector2(0, 180)
	_milagres_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_milagres_empty_label.add_theme_stylebox_override("normal", ManaTheme.panel_style(Color(0.08, 0.08, 0.18, 0.75), 20, Color(1.0, 0.77, 0.42, 0.12), 1, 24))
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
	panel.custom_minimum_size = Vector2(0, 176)
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE_HIGH, 22, Color(1.0, 0.77, 0.42, 0.16), 2, 22, true))

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	var art_texture: Texture2D = null
	if custo_em_santos:
		art_texture = GameArt.gift_icon(str(u.get("id", "")))
	elif u.get("categoria", "") == "profeta":
		art_texture = GameArt.special_prophet_portrait(str(u.get("id", "")))

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(86, 86)
	if art_texture != null:
		icon_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color(0, 0, 0, 0), 43, Color(0, 0, 0, 0), 0, 4))
	else:
		icon_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE, 43, ManaTheme.GOLD_DARK, 2, 10))
	hbox.add_child(icon_panel)
	if art_texture != null:
		var art := TextureRect.new()
		art.texture = art_texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_panel.add_child(art)
	else:
		var icon := Label.new()
		icon.text = "P" if u.get("categoria", "") == "profeta" else "✦"
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_override("font", ManaTheme.serif_bold())
		icon.add_theme_font_size_override("font_size", 38)
		icon.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
		icon_panel.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var nome: Label = Label.new()
	var prefixo: String = "Profeta · " if u.get("categoria", "") == "profeta" else ""
	nome.text = prefixo + u.nome
	nome.add_theme_font_override("font", ManaTheme.serif_bold())
	nome.add_theme_font_size_override("font_size", 36)
	nome.add_theme_color_override("font_color", TEXT_COLOR)
	info.add_child(nome)

	var efeito: Label = Label.new()
	efeito.text = u.efeito
	efeito.add_theme_font_override("font", ManaTheme.body_semibold())
	efeito.add_theme_font_size_override("font_size", 26)
	efeito.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	efeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(efeito)

	var flavor: Label = Label.new()
	flavor.text = u.get("flavor", "")
	flavor.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT)
	flavor.add_theme_font_size_override("font_size", 23)
	flavor.add_theme_color_override("font_color", TEXT_DIM)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(flavor)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(214, 88)
	btn.add_theme_font_size_override("font_size", 29)
	ManaTheme.apply_primary_button(btn)
	if custo_em_santos:
		btn.text = str(int(u.custo)) + " Santos"
		btn.pressed.connect(func(): GameState.buy_dadiva(u.id))
	else:
		btn.text = NumberFormat.format(u.custo) + " Fé"
		btn.pressed.connect(func(): GameState.buy_upgrade(u.id))
	hbox.add_child(btn)

	return {"panel": panel, "btn": btn, "custo": float(u.custo)}

# ============================================================ Aba Santos

func _build_panel_santos() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)

	var header: Label = Label.new()
	header.text = "Santos & Ressurreição"
	header.add_theme_font_override("font", ManaTheme.serif_bold())
	header.add_theme_font_size_override("font_size", 50)
	header.add_theme_color_override("font_color", SANTO_COLOR)
	vbox.add_child(header)

	var info_panel: PanelContainer = PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE_HIGH, 22, Color(0.77, 0.76, 0.93, 0.22), 2, 26, true))
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 18)
	info_panel.add_child(info_row)
	var saint_medal := TextureRect.new()
	saint_medal.texture = GameArt.SANTOS_ICON
	saint_medal.custom_minimum_size = Vector2(76, 76)
	saint_medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	saint_medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	saint_medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_child(saint_medal)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(info_vbox)

	_santos_info_label = Label.new()
	_santos_info_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_santos_info_label.add_theme_font_size_override("font_size", 35)
	_santos_info_label.add_theme_color_override("font_color", TEXT_COLOR)
	info_vbox.add_child(_santos_info_label)

	_santos_mult_label = Label.new()
	_santos_mult_label.add_theme_font_size_override("font_size", 26)
	_santos_mult_label.add_theme_color_override("font_color", TEXT_DIM)
	info_vbox.add_child(_santos_mult_label)

	var relic_row := HBoxContainer.new()
	relic_row.add_theme_constant_override("separation", 8)
	info_vbox.add_child(relic_row)
	var relic_icon := TextureRect.new()
	relic_icon.texture = GameArt.RELIQUIAS_ICON
	relic_icon.custom_minimum_size = Vector2(26, 26)
	relic_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	relic_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	relic_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_row.add_child(relic_icon)
	_relics_label = Label.new()
	_relics_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_relics_label.add_theme_font_size_override("font_size", 24)
	_relics_label.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	relic_row.add_child(_relics_label)
	vbox.add_child(info_panel)

	_prestige_btn = Button.new()
	_prestige_btn.text = "Ressurreição"
	_prestige_btn.add_theme_font_size_override("font_size", 36)
	_prestige_btn.custom_minimum_size = Vector2(0, 92)
	ManaTheme.apply_primary_button(_prestige_btn)
	_prestige_btn.pressed.connect(_on_prestige)
	vbox.add_child(_prestige_btn)

	var dadivas_header: Label = Label.new()
	dadivas_header.text = "DÁDIVAS PERMANENTES"
	dadivas_header.add_theme_font_override("font", ManaTheme.body_semibold())
	dadivas_header.add_theme_font_size_override("font_size", 25)
	dadivas_header.add_theme_color_override("font_color", GOLD)
	vbox.add_child(dadivas_header)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_dadivas_list = VBoxContainer.new()
	_dadivas_list.add_theme_constant_override("separation", 16)
	_dadivas_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_dadivas_list)
	ManaTheme.enable_touch_scroll(scroll, _dadivas_list)

	var legal_btn: Button = Button.new()
	legal_btn.text = "Aviso legal e transparência"
	legal_btn.add_theme_font_size_override("font_size", 26)
	legal_btn.custom_minimum_size = Vector2(0, 64)
	legal_btn.pressed.connect(_show_legal)
	vbox.add_child(legal_btn)

	return vbox

# ============================================================ Aba Gemas

func _build_panel_gemas() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	# Carteira premium: icone e saldo formam uma unica leitura forte.
	var saldo_panel := PanelContainer.new()
	saldo_panel.custom_minimum_size = Vector2(0, 190)
	saldo_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#102b3c"), 24, Color("#79e6e8"), 2, 30, true))
	var saldo_row := HBoxContainer.new()
	saldo_row.add_theme_constant_override("separation", 26)
	saldo_panel.add_child(saldo_row)
	var gem_hero := TextureRect.new()
	gem_hero.texture = GameArt.GEM_ICON
	gem_hero.custom_minimum_size = Vector2(132, 132)
	gem_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gem_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	saldo_row.add_child(gem_hero)
	var saldo_vbox := VBoxContainer.new()
	saldo_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saldo_vbox.add_theme_constant_override("separation", -2)
	saldo_row.add_child(saldo_vbox)
	var carteira := Label.new()
	carteira.text = "SUA CARTEIRA"
	carteira.add_theme_font_override("font", ManaTheme.body_semibold())
	carteira.add_theme_font_size_override("font_size", 20)
	carteira.add_theme_color_override("font_color", Color("#9edcdf"))
	saldo_vbox.add_child(carteira)
	_gemas_label = Label.new()
	_gemas_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_gemas_label.add_theme_font_size_override("font_size", 62)
	_gemas_label.add_theme_color_override("font_color", Color("#e8ffff"))
	saldo_vbox.add_child(_gemas_label)
	_gemas_total_label = Label.new()
	_gemas_total_label.add_theme_font_size_override("font_size", 22)
	_gemas_total_label.add_theme_color_override("font_color", Color("#9edcdf"))
	saldo_vbox.add_child(_gemas_total_label)
	vbox.add_child(saldo_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 14)
	scroll.add_child(lista)
	ManaTheme.enable_touch_scroll(scroll, lista)

	lista.add_child(_build_gem_section_title("RECOMPENSA DIÁRIA", "Ganhe gemas sem gastar"))

	# Video recompensado (simulado ate integrar o SDK de anuncios).
	var reward_panel := PanelContainer.new()
	reward_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#f4edda"), 18, Color("#d8b65c"), 2, 20, true))
	var reward_row := HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 18)
	reward_panel.add_child(reward_row)
	var reward_icon := TextureRect.new()
	reward_icon.texture = GameArt.GEM_ICON
	reward_icon.custom_minimum_size = Vector2(76, 76)
	reward_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_row.add_child(reward_icon)
	var reward_copy := VBoxContainer.new()
	reward_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_copy.add_theme_constant_override("separation", 2)
	reward_row.add_child(reward_copy)
	var reward_title := Label.new()
	reward_title.text = "+" + str(VIDEO_GEMAS) + " Gemas"
	reward_title.add_theme_font_override("font", ManaTheme.serif_bold())
	reward_title.add_theme_font_size_override("font_size", 31)
	reward_title.add_theme_color_override("font_color", ManaTheme.INK)
	reward_copy.add_child(reward_title)
	_video_status_label = Label.new()
	_video_status_label.add_theme_font_size_override("font_size", 20)
	_video_status_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	reward_copy.add_child(_video_status_label)
	_video_btn = Button.new()
	_video_btn.text = "ASSISTIR"
	_video_btn.custom_minimum_size = Vector2(210, 74)
	_video_btn.add_theme_font_size_override("font_size", 23)
	ManaTheme.apply_primary_button(_video_btn)
	_video_btn.pressed.connect(_on_video_pressed)
	reward_row.add_child(_video_btn)
	lista.add_child(reward_panel)

	lista.add_child(_build_gem_section_title("ROTAS GRATUITAS", "Seu progresso tambem enche a carteira"))

	for fonte in [
		["RESSURREIÇÃO", "+10", "Depois, +2 por jornada"],
		["VIDA DE CRISTO", "+50", "Ao concluir o capítulo"],
		["IGREJA & APOCALIPSE", "+100", "Ao concluir o capítulo"],
	]:
		lista.add_child(_build_gem_source_row(str(fonte[0]), str(fonte[1]), str(fonte[2])))

	lista.add_child(_build_gem_section_title("LOJA DE GEMAS", "Pacotes planejados para o lançamento"))

	for pacote in [["Punhado", 80, "R$ 9,90", false], ["Bolsa", 500, "R$ 39,90", true], ["Baú", 1200, "R$ 79,90", false]]:
		lista.add_child(_build_gem_package(str(pacote[0]), int(pacote[1]), str(pacote[2]), bool(pacote[3])))

	# Cooldown do video atualizado a cada segundo.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_refresh_video_button)
	vbox.add_child(timer)
	timer.autostart = true

	_refresh_gemas()
	return vbox

func _build_gem_section_title(title: String, subtitle: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -2)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_override("font", ManaTheme.body_semibold())
	heading.add_theme_font_size_override("font_size", 23)
	heading.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	box.add_child(heading)
	var sub := Label.new()
	sub.text = subtitle
	sub.add_theme_font_size_override("font_size", 19)
	sub.add_theme_color_override("font_color", TEXT_DIM)
	box.add_child(sub)
	return box

func _build_gem_source_row(title: String, reward: String, detail: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#20203f"), 14, Color(1.0, 0.77, 0.42, 0.14), 1, 16))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var marker := Label.new()
	marker.text = "✦"
	marker.add_theme_font_size_override("font_size", 28)
	marker.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	row.add_child(marker)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", -3)
	row.add_child(copy)
	var source_name := Label.new()
	source_name.text = title
	source_name.add_theme_font_override("font", ManaTheme.body_semibold())
	source_name.add_theme_font_size_override("font_size", 21)
	copy.add_child(source_name)
	var desc := Label.new()
	desc.text = detail
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", TEXT_DIM)
	copy.add_child(desc)
	var amount := Label.new()
	amount.text = reward
	amount.add_theme_font_override("font", ManaTheme.serif_bold())
	amount.add_theme_font_size_override("font_size", 28)
	amount.add_theme_color_override("font_color", Color("#8fe8ed"))
	row.add_child(amount)
	return panel

func _build_gem_package(name: String, amount: int, price: String, featured: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var border := ManaTheme.GOLD if featured else Color("#497a86")
	var bg := Color("#18313e") if featured else Color("#1d2839")
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(bg, 18, border, 2 if featured else 1, 18, featured))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = GameArt.GEM_ICON
	icon.custom_minimum_size = Vector2(70, 70)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", -3)
	row.add_child(info)
	var package_name := Label.new()
	package_name.text = name.to_upper() + ("  ·  MELHOR VALOR" if featured else "")
	package_name.add_theme_font_override("font", ManaTheme.body_semibold())
	package_name.add_theme_font_size_override("font_size", 19)
	package_name.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT if featured else TEXT_DIM)
	info.add_child(package_name)
	var package_amount := Label.new()
	package_amount.text = str(amount) + " Gemas"
	package_amount.add_theme_font_override("font", ManaTheme.serif_bold())
	package_amount.add_theme_font_size_override("font_size", 31)
	package_amount.add_theme_color_override("font_color", Color("#d9fdff"))
	info.add_child(package_amount)
	var comprar := Button.new()
	comprar.text = price + "\nEM BREVE"
	comprar.disabled = true
	comprar.custom_minimum_size = Vector2(190, 76)
	comprar.add_theme_font_size_override("font_size", 19)
	row.add_child(comprar)
	return card

func _refresh_gemas() -> void:
	_gemas_label.text = str(GameState.gemas) + " Gemas"
	_gemas_total_label.text = str(GameState.gemas_total) + " conquistadas desde o início"
	_refresh_video_button()

func _refresh_video_button() -> void:
	if _video_btn == null or _panel_gemas == null or not _panel_gemas.visible:
		return
	var agora := Time.get_unix_time_from_system()
	if agora >= _video_cooldown_until:
		_video_btn.text = "▶  ASSISTIR"
		_video_status_label.text = "Recompensa pronta para coletar"
		_video_btn.disabled = false
	else:
		var restante := int(_video_cooldown_until - agora)
		_video_btn.text = "AGUARDE " + str(restante) + "s"
		_video_status_label.text = "Próxima recompensa em " + str(restante) + " segundos"
		_video_btn.disabled = true

# Modal de coleta offline: o ganho base ja foi creditado; as opcoes de
# video (x2) e gema (x3) somam o EXTRA por cima.
const OFFLINE_TRIPLO_GEMAS: int = 3

func _show_offline_modal(ganho: float) -> void:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE, 24, ManaTheme.GOLD_DARK, 2, 36))
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.custom_minimum_size = Vector2(minf(get_viewport_rect().size.x * 0.8, 760.0), 0)
	popup.add_child(vbox)

	var title := Label.new()
	title.text = "Enquanto você esteve fora..."
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	var ganho_label := Label.new()
	ganho_label.text = "Seus profetas coletaram\n+" + NumberFormat.format(ganho) + " Fé"
	ganho_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ganho_label.add_theme_font_size_override("font_size", 34)
	ganho_label.add_theme_color_override("font_color", GOLD)
	vbox.add_child(ganho_label)

	var video_btn := Button.new()
	video_btn.text = "▶  Dobrar com vídeo  ·  +" + NumberFormat.format(ganho)
	video_btn.custom_minimum_size = Vector2(0, 84)
	video_btn.add_theme_font_size_override("font_size", 26)
	video_btn.pressed.connect(func():
		video_btn.disabled = true
		video_btn.text = "Reproduzindo vídeo..."
		# Placeholder do rewarded ad (ver PLANO_GEMAS.md).
		await get_tree().create_timer(2.0).timeout
		GameState.add_fe_bonus(ganho)
		EventBus.toast_requested.emit("Ganho offline dobrado: +" + NumberFormat.format(ganho) + " Fé")
		popup.hide()
	)
	vbox.add_child(video_btn)

	var gema_btn := Button.new()
	gema_btn.text = "Triplicar por " + str(OFFLINE_TRIPLO_GEMAS) + " Gemas  ·  +" + NumberFormat.format(ganho * 2.0)
	gema_btn.custom_minimum_size = Vector2(0, 84)
	gema_btn.add_theme_font_size_override("font_size", 26)
	gema_btn.disabled = GameState.gemas < OFFLINE_TRIPLO_GEMAS
	gema_btn.pressed.connect(func():
		if GameState.spend_gemas(OFFLINE_TRIPLO_GEMAS):
			GameState.add_fe_bonus(ganho * 2.0)
			EventBus.toast_requested.emit("Ganho offline triplicado: +" + NumberFormat.format(ganho * 2.0) + " Fé")
		popup.hide()
	)
	vbox.add_child(gema_btn)

	var coletar_btn := Button.new()
	coletar_btn.text = "Coletar"
	coletar_btn.custom_minimum_size = Vector2(0, 84)
	ManaTheme.apply_primary_button(coletar_btn)
	coletar_btn.pressed.connect(popup.hide)
	vbox.add_child(coletar_btn)

	popup.popup_centered()

func _on_video_pressed() -> void:
	# Placeholder do rewarded ad: aqui entra o SDK (AdMob) no futuro.
	_video_cooldown_until = Time.get_unix_time_from_system() + VIDEO_COOLDOWN_S
	_video_btn.disabled = true
	_video_btn.text = "Reproduzindo vídeo..."
	await get_tree().create_timer(2.0).timeout
	GameState.add_gemas(VIDEO_GEMAS, "vídeo")
	_refresh_gemas()

func _refresh_santos() -> void:
	var bonus_pct: float = (Economy.get_multiplicador_santos() - 1.0) * 100.0
	_santos_info_label.text = str(GameState.santos) + " Santos  ·  +" + String.num(bonus_pct, 1) + "% de produção global"
	_relics_label.text = NumberFormat.format(GameState.reliquias) + " Relíquias"

	# Objetivo visivel: quanto falta de fe acumulada para o proximo Santo.
	# Espelha a formula cubica de Economy.santos_ganhos.
	var santos_prox: int = GameState.get_santos_proximo_prestige()
	var proximo_alvo: float = pow(float(santos_prox + 1), 3.0) * Economy.PRESTIGE_DIVISOR
	var falta: float = maxf(0.0, proximo_alvo - GameState.fe_total_vida)
	_santos_mult_label.text = "Fé nesta jornada: " + NumberFormat.format(GameState.fe_total_vida) \
		+ "  ·  faltam " + NumberFormat.format(falta) + " p/ " + ("+1 Santo" if santos_prox > 0 else "o 1º Santo") \
		+ "  ·  Ressurreições: " + str(GameState.estatisticas.prestiges)
	if santos_prox > 0:
		_prestige_btn.text = "Ressurreição  ·  +" + str(santos_prox) + " Santos"
		_prestige_btn.disabled = false
	else:
		_prestige_btn.text = "Ressurreição  ·  faltam " + NumberFormat.format(falta) + " de Fé"
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
	panel.custom_minimum_size = Vector2(0, 118)
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.PARCHMENT, 26, ManaTheme.PARCHMENT_BORDER, 2, 10, true))

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	for tab in [["geradores", "JORNADA"], ["milagres", "BÊNÇÃOS"], ["estudo", "ESTUDO"], ["santos", "SANTOS"], ["gemas", "GEMAS"]]:
		var btn: Button = Button.new()
		btn.text = tab[1]
		btn.add_theme_font_override("font", ManaTheme.body_semibold())
		btn.add_theme_font_size_override("font_size", 23)
		btn.custom_minimum_size = Vector2(0, 92)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_show_tab.bind(tab[0]))
		if tab[0] == "gemas":
			btn.icon = GameArt.GEM_ICON
			btn.add_theme_constant_override("icon_max_width", 34)
			btn.expand_icon = true
		_tab_buttons[tab[0]] = btn
		hbox.add_child(btn)

	return panel

func _show_tab(tab: String) -> void:
	_tab_atual = tab
	_panel_geradores.visible = tab == "geradores"
	_panel_milagres.visible = tab == "milagres"
	_panel_estudo.visible = tab == "estudo"
	_panel_santos.visible = tab == "santos"
	_panel_gemas.visible = tab == "gemas"
	for t in _tab_buttons:
		var btn: Button = _tab_buttons[t]
		if t == tab:
			btn.add_theme_color_override("font_color", ManaTheme.INK)
			btn.add_theme_color_override("font_hover_color", ManaTheme.INK)
			btn.add_theme_stylebox_override("normal", ManaTheme.button_style(Color("#f5dfac"), ManaTheme.GOLD, 20, 2, 18, 12))
			btn.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#ffe9b4"), ManaTheme.GOLD_LIGHT, 20, 2, 18, 12))
		else:
			btn.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
			btn.add_theme_color_override("font_hover_color", ManaTheme.INK)
			btn.add_theme_stylebox_override("normal", ManaTheme.button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 20, 0, 18, 12))
			btn.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#f2ead8"), ManaTheme.PARCHMENT_BORDER, 20, 1, 18, 12))
		btn.modulate = Color.WHITE
	match tab:
		"milagres":
			_refresh_milagres()
		"santos":
			_refresh_santos()
		"estudo":
			_panel_estudo.refresh()
		"gemas":
			_refresh_gemas()
		"geradores":
			for item in _items.values():
				item.update()

func _update_tab_badges() -> void:
	# Mostra quantos milagres estao disponiveis na aba.
	var n: int = Upgrades.disponiveis().size()
	var btn: Button = _tab_buttons.get("milagres")
	if btn != null:
		btn.text = "BÊNÇÃOS" + ("  ·  " + str(n) if n > 0 else "")
	var study_btn: Button = _tab_buttons.get("estudo")
	if study_btn != null:
		var unread := int(StudySystem.get_progress_summary().get("unread", 0))
		study_btn.text = "ESTUDO" + ("  ·  " + str(unread) if unread > 0 else "")
	var gems_btn: Button = _tab_buttons.get("gemas")
	if gems_btn != null:
		var reward_ready := Time.get_unix_time_from_system() >= _video_cooldown_until
		gems_btn.text = "GEMAS" + ("  ·  +" + str(VIDEO_GEMAS) if reward_ready else "")

# ============================================================ Notificacao (toast)

func _build_notification() -> void:
	_notification_label = Label.new()
	_notification_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_notification_label.offset_left = -420
	_notification_label.offset_right = 420
	_notification_label.offset_top = -188
	_notification_label.offset_bottom = -94
	_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notification_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_notification_label.add_theme_font_size_override("font_size", 30)
	_notification_label.add_theme_color_override("font_color", ManaTheme.INK)
	_notification_label.add_theme_stylebox_override("normal", ManaTheme.panel_style(ManaTheme.PARCHMENT, 26, ManaTheme.GOLD, 2, 24, true))
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
	EventBus.study_progress_changed.connect(func(_id: String): _on_study_changed())
	EventBus.study_unlocked.connect(func(_id: String): _on_study_changed())
	EventBus.wisdom_changed.connect(func(_amount: int): _on_study_changed())
	EventBus.knowledge_purchased.connect(func(_id: String): _on_economy_changed())
	EventBus.adventure_unlocked.connect(func(_id: String): _on_adventure_changed())
	EventBus.adventure_completed.connect(func(_id: String): _on_adventure_changed())
	EventBus.relics_changed.connect(func(_amount: int):
		if _tab_atual == "santos":
			_refresh_santos()
	)
	EventBus.gems_changed.connect(func(_amount: int):
		if _tab_atual == "gemas":
			_refresh_gemas()
		_refresh_adventure_icons()
	)

func _on_study_changed() -> void:
	_update_tab_badges()
	if _panel_estudo != null and _tab_atual == "estudo":
		_panel_estudo.refresh()

func _on_adventure_changed() -> void:
	_refresh_adventure_selector()
	_update_all()

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
				if not item.visible:
					continue
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
		"estudo":
			pass

func _update_topbar() -> void:
	_faith_label.text = NumberFormat.format(GameState.fe)
	_santos_label.text = NumberFormat.format(GameState.santos)
	var rev: float = GameState.get_receita_por_segundo()
	if rev > 0:
		_rev_label.text = "+" + NumberFormat.format(rev) + "/s"
	else:
		_rev_label.text = ""
	var current_era: int = _get_current_era()
	_era_label.text = "Era " + str(current_era) + "  ·  " + Geradores.get_era_name(current_era)
	if _era_progress != null:
		var total_era := 0
		var comprados_era := 0
		for gen_id in GameState.geradores:
			var data: Dictionary = Geradores.get_data(gen_id)
			if int(data.get("era", 0)) == current_era and Geradores.get_adventure_for_id(gen_id) == _current_adventure:
				total_era += 1
				if int(GameState.geradores[gen_id].get("qtd", 0)) > 0:
					comprados_era += 1
		_era_progress.value = float(comprados_era) / float(max(1, total_era))

func _get_current_era() -> int:
	var adventure_generators := Geradores.get_by_adventure(_current_adventure)
	var highest: int = int(adventure_generators[0].get("era", 1)) if not adventure_generators.is_empty() else 1
	for gen_id in GameState.geradores:
		if Geradores.get_adventure_for_id(gen_id) != _current_adventure:
			continue
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
	_refresh_adventure_selector()
	for item in _items.values():
		item.update()
	if _panel_estudo != null and _tab_atual == "estudo":
		_panel_estudo.refresh()

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
	dialog.title = "Ressurreição"
	dialog.dialog_text = "Renascer agora reinicia Fé, geradores, profetas e bênçãos.\n\nVocê receberá +" + str(ganhos) + " Santos, com bônus permanente de +" + str(ganhos * 2) + "% de produção.\nAs dádivas permanecem.\n\nConfirmar?"
	dialog.get_ok_button().text = "Ressuscitar"
	dialog.get_cancel_button().text = "Ainda não"
	dialog.confirmed.connect(func():
		GameState.prestige()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()

# ============================================================ Configurações

const CONFIG_PATH: String = "user://config.cfg"
const FONT_SCALES: Array = [0.85, 1.0, 1.15, 1.3]
var _font_scale: float = 1.0

func _load_ui_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		_font_scale = clampf(float(cfg.get_value("ui", "escala_fonte", 1.0)), 0.7, 1.6)
	_apply_font_scale()

func _apply_font_scale() -> void:
	get_window().content_scale_factor = _font_scale

func _set_font_scale(scale: float) -> void:
	_font_scale = scale
	_apply_font_scale()
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)
	cfg.set_value("ui", "escala_fonte", scale)
	cfg.save(CONFIG_PATH)

func _show_settings() -> void:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE, 24, ManaTheme.OUTLINE, 2, 36))
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.custom_minimum_size = Vector2(minf(get_viewport_rect().size.x * 0.8, 760.0), 0)
	popup.add_child(vbox)

	var title := Label.new()
	title.text = "Configurações"
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	vbox.add_child(title)

	var fonte_label := Label.new()
	fonte_label.text = "Tamanho da fonte"
	fonte_label.add_theme_font_override("font", ManaTheme.body_semibold())
	fonte_label.add_theme_font_size_override("font_size", 26)
	fonte_label.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(fonte_label)

	var fonte_row := HBoxContainer.new()
	fonte_row.add_theme_constant_override("separation", 10)
	vbox.add_child(fonte_row)
	for scale in FONT_SCALES:
		var btn := Button.new()
		btn.text = str(int(round(scale * 100.0))) + "%"
		btn.custom_minimum_size = Vector2(0, 70)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_equal_approx(scale, _font_scale):
			ManaTheme.apply_primary_button(btn)
			btn.disabled = true
		btn.pressed.connect(func():
			_set_font_scale(scale)
			popup.hide()
		)
		fonte_row.add_child(btn)

	var legal_btn := Button.new()
	legal_btn.text = "Aviso legal"
	legal_btn.custom_minimum_size = Vector2(0, 70)
	legal_btn.pressed.connect(func():
		popup.hide()
		_show_legal()
	)
	vbox.add_child(legal_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Apagar save e recomeçar"
	reset_btn.custom_minimum_size = Vector2(0, 70)
	reset_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5))
	reset_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.65, 0.6))
	reset_btn.pressed.connect(func():
		popup.hide()
		_confirm_reset_save()
	)
	vbox.add_child(reset_btn)

	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 70)
	ManaTheme.apply_primary_button(close_btn)
	close_btn.pressed.connect(popup.hide)
	vbox.add_child(close_btn)

	popup.popup_centered()

func _confirm_reset_save() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Apagar save"
	dialog.dialog_text = "Isto apaga TODO o progresso (Fé, geradores, Santos, estudos) e fecha o jogo.\n\nAo abrir de novo, você começa do zero.\n\nTem certeza?"
	dialog.get_ok_button().text = "Apagar tudo"
	dialog.get_cancel_button().text = "Cancelar"
	dialog.confirmed.connect(func():
		SaveSystem.set_persistence_enabled(false)
		SaveSystem.delete_save()
		get_tree().quit()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()

func _show_legal() -> void:
	var popup: AcceptDialog = AcceptDialog.new()
	popup.title = "Aviso Legal"
	popup.dialog_text = "Maná Idle é um jogo de progressão com temática bíblica.\n\nEsta é uma adaptação ficcional inspirada em narrativas bíblicas e não representa a doutrina oficial de nenhuma igreja.\n\nTodas as Escrituras em português citadas são da Bíblia Livre (BLIVRE), Copyright © 2018 Diego Santos, Mario Sérgio e Marco Teles, sob licença Creative Commons Atribuição 4.0. Fonte: ebible.org/porbr2018/.\n\nProjeto filantropo: a página de Transparência será disponibilizada em breve."
	popup.get_ok_button().text = "Entendi"
	add_child(popup)
	_fit_dialog_to_screen(popup)
	popup.popup_centered()

# Sem isto o texto do dialogo nao quebra linha e o painel estoura a tela.
func _fit_dialog_to_screen(dialog: AcceptDialog) -> void:
	var label: Label = dialog.get_label()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(minf(get_viewport_rect().size.x * 0.78, 820.0), 0)

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
					_show_offline_modal(ganho)
			_last_tick_msec = Time.get_ticks_msec()
			_pause_time = 0.0
			_update_all()

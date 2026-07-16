extends Control

const PurchaseButtonScript = preload("res://scripts/ui/PurchaseButton.gd")
const EraProgressSquareScript = preload("res://scripts/ui/EraProgressSquare.gd")
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
const TOP_SAFE_AREA_HEIGHT: float = 46.0
const RESOURCE_PILL_WIDTH: float = 190.0

var _tick_timer: Timer
var _faith_label: Label
var _santos_label: Label
var _rev_label: Label
var _era_label: Label
var _era_operator_grid: HBoxContainer
var _era_squares: Dictionary = {}
var _gen_list: VBoxContainer
var _generator_scroll: ScrollContainer
var _future_boost_space: Control
var _prestige_btn: Button
var _notification_label: Label
var _notification_timer: Timer
var _liveops_banner: Label
var _items: Dictionary = {}
var _game_loaded: bool = false
var _pause_time: float = 0.0
var _pending_resume_away: float = 0.0
var _resume_refresh_in_progress: bool = false
const MODO_ORDEM: Array[String] = ["x1", "x10", "x100", "Next", "Max"]
var _modo_compra: String = "x1"
var _modo_btn: Button = null
var _modo_display_label: Label = null
var _last_tick_msec: int = 0
var _full_update_counter: int = 0
const FULL_UPDATE_EVERY: int = 3  # atualiza precos/botoes a cada 3 ticks (~3Hz)
const OPERATOR_PROGRESS_TARGET: int = 100

# Abas
var _tab_atual: String = "geradores"
var _tab_buttons: Dictionary = {}
var _tab_attention_tags: Dictionary = {}
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
var _panel_gemas: VBoxContainer
var _gemas_label: Label
var _gemas_total_label: Label
var _video_btn: Button
var _video_status_label: Label
var _video_reward_title_label: Label
var _video_cooldown_until: float = 0.0
var _gem_wallet_panel: PanelContainer
var _gem_sources_button: Button
var _daily_boost_video_button: Button
var _daily_boost_video_status: Label
var _adventure_icons: Dictionary = {}
var _boost_buttons: Dictionary = {}
var _boost_timer_badges: Dictionary = {}
var _boost_inventory_badges: Dictionary = {}
var _boost_store_buttons: Dictionary = {}
var _boost_store_count_labels: Dictionary = {}
var _inactive_operator_panel: VBoxContainer
var _inactive_operator_button: Button
var _inactive_operator_layers: Array[TextureRect] = []
var _inactive_operator_count: Label
var _inactive_operator_queue: Array[int] = []
var _inactive_operator_motion: Tween
var _inactive_operator_bottom_gap: Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_ui_config()
	# A escala de acessibilidade e aplicada aos glifos, nunca ao canvas inteiro.
	# Assim, espacos e controles continuam dentro da largura visivel da janela.
	get_window().content_scale_factor = 1.0
	theme = ManaTheme.make_theme(_font_scale)
	get_tree().node_added.connect(_on_tree_node_added)
	var loading_label := Label.new()
	loading_label.text = "Consultando seu pergaminho..."
	loading_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_override("font", ManaTheme.serif_bold())
	loading_label.add_theme_font_size_override("font_size", 34)
	loading_label.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	add_child(loading_label)
	# Defaults/cache já estão ativos. A consulta recebe somente uma janela curta
	# para que LiveOps nunca impeça a abertura offline do jogo.
	await LiveOps.bootstrap(1.25)
	var bootstrap: Dictionary = await CloudSave.bootstrap(3.0)
	_game_loaded = bool(bootstrap.get("loaded", false))
	loading_label.queue_free()
	_build_ui()
	_apply_font_scale()
	get_viewport().size_changed.connect(_layout_tenda_wallet)
	call_deferred("_layout_tenda_wallet")
	_setup_timer()
	_setup_signals()
	_update_all()
	if CloudSave.has_conflict():
		call_deferred("_show_cloud_conflict_dialog", CloudSave.conflict_summary())
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

	main_vbox.add_child(_build_top_safe_area())
	main_vbox.add_child(_build_liveops_banner())
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
	_refresh_liveops_banner()
	_show_tab("geradores")


func _build_top_safe_area() -> Control:
	# Reserva fixa para recortes, sensores e a barra de status dos celulares.
	var safe_area := Control.new()
	safe_area.custom_minimum_size = Vector2(0, TOP_SAFE_AREA_HEIGHT)
	safe_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return safe_area


func _build_liveops_banner() -> Label:
	_liveops_banner = Label.new()
	_liveops_banner.visible = false
	_liveops_banner.custom_minimum_size = Vector2(0, 42)
	_liveops_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_liveops_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_liveops_banner.add_theme_font_override("font", ManaTheme.body_semibold())
	_liveops_banner.add_theme_font_size_override("font_size", 18)
	_liveops_banner.add_theme_color_override("font_color", Color("#fff0b3"))
	_liveops_banner.add_theme_stylebox_override(
		"normal",
		ManaTheme.button_style(Color("#443413"), Color("#d8b65c"), 14, 1, 12, 6)
	)
	_liveops_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return _liveops_banner


func _refresh_liveops_banner() -> void:
	if _liveops_banner == null:
		return
	var names := LiveOps.active_campaign_names()
	_liveops_banner.visible = not names.is_empty()
	_liveops_banner.text = "EVENTO ATIVO  ·  " + "  •  ".join(names) if not names.is_empty() else ""


func _build_topbar() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 116)
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color(0.055, 0.055, 0.16, 0.96), 28, Color(1.0, 0.77, 0.42, 0.18), 2, 20, true))

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var mana_icon := TextureRect.new()
	mana_icon.texture = GameArt.MANA_ICON
	mana_icon.custom_minimum_size = Vector2(60, 60)
	mana_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mana_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mana_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(mana_icon)

	var brand: VBoxContainer = VBoxContainer.new()
	brand.add_theme_constant_override("separation", -4)
	brand.custom_minimum_size = Vector2(210, 0)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(brand)
	var brand_name := Label.new()
	brand_name.text = "Maná Idle"
	brand_name.add_theme_font_override("font", ManaTheme.serif_bold())
	brand_name.add_theme_font_size_override("font_size", 48)
	brand_name.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	brand_name.clip_text = true
	brand_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	brand.add_child(brand_name)
	var brand_sub := Label.new()
	brand_sub.text = "BÍBLIA CLICKER"
	brand_sub.add_theme_font_override("font", ManaTheme.body_semibold())
	brand_sub.add_theme_font_size_override("font_size", 22)
	brand_sub.add_theme_color_override("font_color", TEXT_DIM)
	brand_sub.clip_text = true
	brand_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	brand.add_child(brand_sub)

	var bible_button := _build_framed_button(Color("#1b2841"), Color("#a88b46"), Color("#f2d58a"), Color("#2f4260"))
	bible_button.tooltip_text = "Leia a Bíblia"
	bible_button.custom_minimum_size = Vector2(106, 86)
	var bible_icon := TextureRect.new()
	bible_icon.texture = GameArt.OPEN_BIBLE_ICON
	bible_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	bible_icon.offset_left = 24
	bible_icon.offset_right = -24
	bible_icon.offset_top = 5
	bible_icon.offset_bottom = -31
	bible_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bible_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bible_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bible_button.add_child(bible_icon)
	var bible_caption := Label.new()
	bible_caption.text = "Leia a Bíblia"
	bible_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bible_caption.offset_top = -28
	bible_caption.offset_bottom = -5
	bible_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bible_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bible_caption.add_theme_font_override("font", ManaTheme.body_semibold())
	bible_caption.add_theme_font_size_override("font_size", 13)
	bible_caption.add_theme_color_override("font_color", ManaTheme.CREAM)
	bible_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bible_button.add_child(bible_caption)
	bible_button.pressed.connect(_open_bible)
	hbox.add_child(bible_button)

	var resources := HBoxContainer.new()
	resources.add_theme_constant_override("separation", 4)
	resources.size_flags_horizontal = Control.SIZE_SHRINK_END
	hbox.add_child(resources)
	var fe_pill := _build_resource_pill("FÉ", GOLD)
	_faith_label = fe_pill.value
	resources.add_child(fe_pill.panel)
	var santos_pill := _build_resource_pill("SANTOS", SANTO_COLOR)
	_santos_label = santos_pill.value
	resources.add_child(santos_pill.panel)

	var settings := _build_framed_button(Color("#242731"), Color("#858994"), Color("#d3d5dc"), Color("#363a47"))
	settings.text = ""
	settings.tooltip_text = "Configurações"
	settings.custom_minimum_size = Vector2(64, 64)
	var settings_icon := TextureRect.new()
	settings_icon.texture = GameArt.SETTINGS_ICON
	settings_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_icon.offset_left = 12
	settings_icon.offset_right = -12
	settings_icon.offset_top = 12
	settings_icon.offset_bottom = -12
	settings_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	settings_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings.add_child(settings_icon)
	settings.pressed.connect(_show_settings)
	hbox.add_child(settings)

	return panel


func _open_bible() -> void:
	_show_tab("estudo")
	_panel_estudo.show_section("bible")

func _build_resource_pill(caption: String, accent: Color) -> Dictionary:
	var palette: Array[Color] = [Color("#17213b"), Color("#b98e38"), Color("#f0cd78"), Color("#25345a")]
	if caption == "SANTOS":
		palette = [Color("#252836"), Color("#9298aa"), Color("#e2e5ef"), Color("#35394b")]
	var panel := _build_framed_button(palette[0], palette[1], palette[2], palette[3])
	panel.custom_minimum_size = Vector2(RESOURCE_PILL_WIDTH, 64)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -10
	row.offset_top = 8
	row.offset_bottom = -8
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	if caption == "SANTOS" or caption == "FÉ":
		var icon_texture := TextureRect.new()
		icon_texture.texture = GameArt.SANTOS_ICON if caption == "SANTOS" else GameArt.FAITH_ICON
		icon_texture.custom_minimum_size = Vector2(30, 30)
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
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var label := Label.new()
	label.text = caption
	label.add_theme_font_override("font", ManaTheme.body_semibold())
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", TEXT_DIM)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(label)
	var value := Label.new()
	value.custom_minimum_size = Vector2(132, 0)
	value.add_theme_font_override("font", ManaTheme.body_semibold())
	value.add_theme_font_size_override("font_size", 26)
	value.add_theme_color_override("font_color", accent)
	value.clip_text = true
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(value)
	return {"panel": panel, "value": value}

func _build_framed_button(base: Color, outer: Color, inner: Color, hover: Color) -> Button:
	var button: Button = PurchaseButtonScript.new()
	button.add_theme_stylebox_override("normal", ManaTheme.button_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0, 0))
	button.add_theme_stylebox_override("hover", ManaTheme.button_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0, 0))
	button.add_theme_stylebox_override("pressed", ManaTheme.button_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0, 0))
	button.add_theme_stylebox_override("disabled", ManaTheme.button_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0, 0))
	button.call("set_frame_style", base, outer, inner, hover, false)
	return button

func _build_avatar_slot() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 100)
	panel.tooltip_text = "Avatar do peregrino"
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#202944"), 16, Color("#d7ad4d"), 2, 5, true))
	var portrait := TextureRect.new()
	# Carregamento tardio permite ao editor importar o PNG novo sem interromper
	# a compilacao do catalogo de arte durante a primeira abertura.
	portrait.texture = load("res://assets/icons/avatar/avatar_pilgrim.png") as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait)
	return panel

# ============================================================ Aba Geradores

func _build_panel_geradores() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	var journey_header := PanelContainer.new()
	journey_header.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color(0.08, 0.08, 0.20, 0.86), 20, Color(1.0, 0.77, 0.42, 0.16), 1, 18))
	var header_vbox := VBoxContainer.new()
	journey_header.add_child(header_vbox)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header_vbox.add_child(header_row)
	header_row.add_child(_build_avatar_slot())
	var era_content := VBoxContainer.new()
	era_content.add_theme_constant_override("separation", 8)
	era_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(era_content)
	var era_hbox: HBoxContainer = HBoxContainer.new()
	era_hbox.add_theme_constant_override("separation", 12)
	_era_label = Label.new()
	_era_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_era_label.add_theme_font_size_override("font_size", 43)
	_era_label.add_theme_color_override("font_color", ManaTheme.CREAM)
	_era_label.custom_minimum_size = Vector2(240, 58)
	_era_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_era_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_era_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_era_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_era_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_era_label.clip_text = true
	era_hbox.add_child(_era_label)
	var era_actions := HBoxContainer.new()
	era_actions.add_theme_constant_override("separation", 12)
	_rev_label = Label.new()
	_rev_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_rev_label.add_theme_font_size_override("font_size", 31)
	_rev_label.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	era_actions.add_child(_rev_label)
	era_actions.add_child(_build_modo_selector())
	era_hbox.add_child(era_actions)
	era_content.add_child(era_hbox)
	_era_operator_grid = HBoxContainer.new()
	_era_operator_grid.add_theme_constant_override("separation", 5)
	_era_operator_grid.custom_minimum_size = Vector2(0, 30)
	_era_operator_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	era_content.add_child(_era_operator_grid)
	_refresh_era_operator_grid()
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
	# Coluna lateral sem moldura: capitulos e impulsos flutuam diretamente sobre
	# o fundo. A lista rola de forma independente para que os inativos nunca
	# avancem sobre a navegacao inferior.
	var side_column := VBoxContainer.new()
	side_column.custom_minimum_size = Vector2(238, 0)
	side_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_column.add_theme_constant_override("separation", 0)

	var icon_scroll := ScrollContainer.new()
	icon_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	icon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	side_column.add_child(icon_scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	icon_scroll.add_child(column)

	column.add_child(_build_side_section_label("JORNADAS", TEXT_DIM))
	for index in range(["vida_cristo", "igreja_apocalipse"].size()):
		var adventure_id: String = ["vida_cristo", "igreja_apocalipse"][index]
		var btn := Button.new()
		btn.icon = GameArt.sidebar_adventure_icon(adventure_id)
		btn.expand_icon = true
		btn.text = "CRISTO" if adventure_id == "vida_cristo" else "APOC."
		btn.add_theme_constant_override("icon_max_width", 134)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.custom_minimum_size = Vector2(0, 148)
		btn.add_theme_font_override("font", ManaTheme.body_semibold())
		btn.add_theme_font_size_override("font_size", 17)
		_apply_side_icon_style(btn)
		btn.pressed.connect(_on_adventure_pressed.bind(adventure_id))
		_adventure_icons[adventure_id] = btn
		column.add_child(btn)
		_start_side_icon_motion(btn, index)

	column.add_child(_build_side_section_divider())
	column.add_child(_build_side_section_label("BOOSTS", ManaTheme.GOLD_LIGHT))
	for index in range(GameState.BOOSTS.size()):
		var boost_id: String = GameState.BOOSTS.keys()[index]
		var btn := _build_boost_icon(boost_id)
		_boost_buttons[boost_id] = btn
		column.add_child(btn)
		_start_side_icon_motion(btn, index + 2)

	_inactive_operator_panel = _build_inactive_operator_stack()
	side_column.add_child(_inactive_operator_panel)
	_inactive_operator_bottom_gap = Control.new()
	_inactive_operator_bottom_gap.custom_minimum_size = Vector2(0, 34)
	_inactive_operator_bottom_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inactive_operator_bottom_gap.visible = false
	side_column.add_child(_inactive_operator_bottom_gap)

	ManaTheme.enable_touch_scroll(icon_scroll, column)
	_refresh_adventure_icons()
	_refresh_inactive_operator_stack()
	return side_column

func _build_inactive_operator_stack() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(0, 188)
	panel.add_theme_constant_override("separation", 4)
	panel.visible = false
	panel.add_child(_build_side_section_label("INATIVOS", ManaTheme.GOLD_LIGHT))

	var stack_area := Control.new()
	stack_area.custom_minimum_size = Vector2(0, 146)
	panel.add_child(stack_area)
	for depth in range(2, 0, -1):
		var layer := TextureRect.new()
		layer.set_anchors_preset(Control.PRESET_CENTER)
		var shift := float(depth * 8)
		layer.offset_left = -60 + shift
		layer.offset_right = 60 + shift
		layer.offset_top = -62 + shift
		layer.offset_bottom = 62 + shift
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer.modulate = Color(0.76, 0.76, 0.86, 0.72 - float(depth - 1) * 0.18)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.visible = false
		stack_area.add_child(layer)
		_inactive_operator_layers.append(layer)

	_inactive_operator_button = Button.new()
	_inactive_operator_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inactive_operator_button.expand_icon = true
	_inactive_operator_button.add_theme_constant_override("icon_max_width", 136)
	_inactive_operator_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inactive_operator_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	_inactive_operator_button.tooltip_text = "Ativar ciclo manual"
	_apply_side_icon_style(_inactive_operator_button)
	_inactive_operator_button.pressed.connect(_activate_next_inactive_operator)
	stack_area.add_child(_inactive_operator_button)

	_inactive_operator_count = Label.new()
	_inactive_operator_count.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_inactive_operator_count.offset_left = -42
	_inactive_operator_count.offset_right = -2
	_inactive_operator_count.offset_top = 2
	_inactive_operator_count.offset_bottom = 30
	_inactive_operator_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inactive_operator_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_inactive_operator_count.add_theme_font_override("font", ManaTheme.body_semibold())
	_inactive_operator_count.add_theme_font_size_override("font_size", 14)
	_inactive_operator_count.add_theme_color_override("font_color", ManaTheme.CREAM)
	_inactive_operator_count.add_theme_stylebox_override("normal", ManaTheme.panel_style(Color("#34415f"), 10, Color("#f0cd78"), 1, 4, true))
	_inactive_operator_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inactive_operator_count.visible = false
	stack_area.add_child(_inactive_operator_count)
	return panel

func _refresh_inactive_operator_stack() -> void:
	if _inactive_operator_panel == null or _inactive_operator_button == null:
		return
	if _inactive_operator_button.disabled:
		return
	var inactive_ids: Array[int] = []
	for gen_id in GameState.geradores:
		var id := int(gen_id)
		var state: Dictionary = GameState.geradores[id]
		if not GameState.is_unlocked(id):
			continue
		if int(state.get("qtd", 0)) <= 0:
			continue
		if bool(state.get("tem_profeta", false)):
			continue
		if float(state.get("tempo_restante", -1.0)) >= 0.0:
			continue
		inactive_ids.append(id)
	inactive_ids.sort()
	_inactive_operator_queue = inactive_ids
	_inactive_operator_panel.visible = not inactive_ids.is_empty()
	if _inactive_operator_bottom_gap != null:
		_inactive_operator_bottom_gap.visible = not inactive_ids.is_empty()
	if inactive_ids.is_empty():
		_stop_inactive_operator_motion()
		return
	_start_inactive_operator_motion()

	var current_id := inactive_ids[0]
	var current_data := Geradores.get_data(current_id)
	_inactive_operator_button.icon = GameArt.generator_icon(current_id)
	_inactive_operator_button.tooltip_text = "Ativar ciclo: " + str(current_data.get("nome", "Operador"))
	for index in range(_inactive_operator_layers.size()):
		var layer := _inactive_operator_layers[index]
		var queue_index := _inactive_operator_layers.size() - index
		layer.visible = queue_index < inactive_ids.size()
		if layer.visible:
			layer.texture = GameArt.generator_icon(inactive_ids[queue_index])
	_inactive_operator_count.visible = inactive_ids.size() > 1
	_inactive_operator_count.text = str(inactive_ids.size())


func _start_inactive_operator_motion() -> void:
	if _inactive_operator_button == null or is_instance_valid(_inactive_operator_motion):
		return
	_inactive_operator_button.call_deferred("set_pivot_offset", _inactive_operator_button.size * 0.5)
	_inactive_operator_motion = create_tween()
	_inactive_operator_motion.set_loops()
	_inactive_operator_motion.tween_interval(3.0)
	_inactive_operator_motion.tween_property(_inactive_operator_button, "rotation", -0.028, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_inactive_operator_motion.tween_property(_inactive_operator_button, "rotation", 0.028, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_inactive_operator_motion.tween_property(_inactive_operator_button, "rotation", -0.018, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_inactive_operator_motion.tween_property(_inactive_operator_button, "rotation", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _stop_inactive_operator_motion() -> void:
	if is_instance_valid(_inactive_operator_motion):
		_inactive_operator_motion.kill()
	_inactive_operator_motion = null
	if _inactive_operator_button != null:
		_inactive_operator_button.rotation = 0.0

func _activate_next_inactive_operator() -> void:
	if _inactive_operator_queue.is_empty() or _inactive_operator_button == null:
		return
	var gen_id := _inactive_operator_queue[0]
	if not GameState.start_cycle(gen_id):
		_refresh_inactive_operator_stack()
		return
	_inactive_operator_button.disabled = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_inactive_operator_button, "scale", Vector2(0.82, 0.82), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_inactive_operator_button, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.14)
	await tween.finished
	if _inactive_operator_button == null:
		return
	_inactive_operator_button.scale = Vector2.ONE
	_inactive_operator_button.modulate = Color.WHITE
	_inactive_operator_button.disabled = false
	_update_item(gen_id)
	_refresh_inactive_operator_stack()

func _build_boost_icon(boost_id: String) -> Button:
	var data: Dictionary = GameState.get_boost_data(boost_id)
	var button := Button.new()
	button.text = _side_icon_short_name(boost_id)
	button.icon = GameArt.sidebar_boost_icon(boost_id)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 130)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.custom_minimum_size = Vector2(0, 142)
	button.add_theme_font_override("font", ManaTheme.body_semibold())
	button.add_theme_font_size_override("font_size", 16)
	_apply_side_icon_style(button)
	var inventory_badge := Label.new()
	inventory_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# O contador fica sobre a arte, nao perdido no canto do cartao lateral.
	inventory_badge.offset_left = 44
	inventory_badge.offset_right = 82
	inventory_badge.offset_top = 4
	inventory_badge.offset_bottom = 30
	inventory_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inventory_badge.add_theme_font_override("font", ManaTheme.body_semibold())
	inventory_badge.add_theme_font_size_override("font_size", 13)
	inventory_badge.add_theme_color_override("font_color", ManaTheme.INK)
	inventory_badge.add_theme_stylebox_override("normal", ManaTheme.panel_style(Color("#f0cd78"), 10, Color("#fff0c4"), 1, 4, true))
	inventory_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_badge.visible = false
	button.add_child(inventory_badge)
	_boost_inventory_badges[boost_id] = inventory_badge
	var timer_badge := Label.new()
	timer_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	timer_badge.offset_left = -78
	timer_badge.offset_right = -4
	timer_badge.offset_top = 4
	timer_badge.offset_bottom = 30
	timer_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_badge.add_theme_font_override("font", ManaTheme.body_semibold())
	timer_badge.add_theme_font_size_override("font_size", 13)
	timer_badge.add_theme_color_override("font_color", ManaTheme.CREAM)
	timer_badge.add_theme_stylebox_override("normal", ManaTheme.panel_style(Color("#184f60"), 10, Color("#9bf6f3"), 1, 4, true))
	timer_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_badge.visible = false
	button.add_child(timer_badge)
	_boost_timer_badges[boost_id] = timer_badge
	button.pressed.connect(_show_boost_modal.bind(boost_id))
	return button

func _build_side_section_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ManaTheme.body_semibold())
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(0, 38)
	return label

func _build_side_section_divider() -> Label:
	var divider := Label.new()
	divider.text = "—"
	divider.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	divider.add_theme_font_override("font", ManaTheme.serif_bold())
	divider.add_theme_font_size_override("font_size", 28)
	divider.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45, 0.48))
	divider.custom_minimum_size = Vector2(0, 26)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return divider

func _side_icon_short_name(boost_id: String) -> String:
	match boost_id:
		"pentecoste": return "PENTECOSTE"
		"passo_ligeiro": return "PASSO"
		"maos_santas": return "MÃOS"
		_: return str(GameState.get_boost_data(boost_id).get("nome", "")).to_upper()

func _apply_side_icon_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", ManaTheme.button_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0, 0))
	button.add_theme_stylebox_override("hover", ManaTheme.button_style(Color(1.0, 1.0, 1.0, 0.08), Color.TRANSPARENT, 18, 0, 0, 0))
	button.add_theme_stylebox_override("pressed", ManaTheme.button_style(Color(1.0, 0.86, 0.52, 0.14), Color.TRANSPARENT, 18, 0, 0, 0))

func _start_side_icon_motion(button: Button, index: int) -> void:
	button.call_deferred("set_pivot_offset", button.size * 0.5)
	var tween := create_tween()
	tween.set_loops()
	tween.tween_interval(3.8 + float(index % 4) * 0.72)
	tween.tween_property(button, "scale", Vector2(1.055, 1.055), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button, "rotation", 0.018 if index % 2 == 0 else -0.018, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(button, "rotation", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _refresh_adventure_icons() -> void:
	for adventure_id in _adventure_icons:
		var key := str(adventure_id)
		var btn: Button = _adventure_icons[key]
		var status := GameState.get_adventure_unlock_status(key)
		var active := key == _current_adventure
		if bool(status.get("unlocked", false)):
			btn.text = "CRISTO" if key == "vida_cristo" else "APOC."
			if active and key == "vida_cristo":
				btn.modulate = Color("#ea8790")
			elif active and key == "igreja_apocalipse":
				btn.modulate = Color("#242329")
			else:
				btn.modulate = Color.WHITE
			btn.tooltip_text = "Abrir capítulo: " + _adventure_label(key)
		else:
			var custo_txt: String
			if str(status.get("currency", "fe")) == "gemas":
				custo_txt = str(int(status.get("entry_cost", 0.0))) + " Gemas"
			else:
				custo_txt = NumberFormat.format(float(status.get("entry_cost", 0.0))) + " Fé"
			btn.text = "CRISTO" if key == "vida_cristo" else "APOC."
			btn.modulate = Color.WHITE if bool(status.get("can_unlock", false)) else Color(0.72, 0.72, 0.78)
			btn.tooltip_text = "Desbloquear " + _adventure_label(key) + " por " + custo_txt
	_refresh_boost_icons()

func _refresh_boost_icons() -> void:
	for boost_id in _boost_buttons:
		var key := str(boost_id)
		var button: Button = _boost_buttons[key]
		var data := GameState.get_boost_data(key)
		var remaining := GameState.get_boost_remaining(key)
		var inventory := GameState.get_boost_inventory(key)
		button.modulate = Color.WHITE if remaining > 0 or inventory > 0 else Color(0.86, 0.86, 0.94, 1.0)
		button.tooltip_text = str(data.nome) + " · " + str(data.efeito) + (" · " + _format_duration(remaining) + " restante" if remaining > 0 else "")
		if inventory > 0:
			button.tooltip_text += "  ·  " + str(inventory) + " disponível"
		var inventory_badge: Label = _boost_inventory_badges.get(key)
		if inventory_badge != null:
			inventory_badge.visible = inventory > 0
			inventory_badge.text = str(inventory)
		var timer_badge: Label = _boost_timer_badges.get(key)
		if timer_badge != null:
			timer_badge.visible = remaining > 0
			timer_badge.text = _format_boost_timer(remaining)

func _on_adventure_pressed(adventure_id: String) -> void:
	var status := GameState.get_adventure_unlock_status(adventure_id)
	var unlocked := GameState.is_adventure_unlocked(adventure_id)
	var em_gemas: bool = str(status.get("currency", "fe")) == "gemas"
	var custo_txt: String = (str(int(status.entry_cost)) + " Gemas") if em_gemas else (NumberFormat.format(float(status.entry_cost)) + " de Fé")
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#171b3b"), 26, ManaTheme.GOLD_DARK, 2, 30, true))
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2.ZERO
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	popup.add_child(content)
	var icon := TextureRect.new()
	icon.texture = GameArt.sidebar_adventure_icon(adventure_id)
	icon.custom_minimum_size = Vector2(0, 170)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)
	var title := Label.new()
	title.text = _adventure_label(adventure_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", ManaTheme.CREAM)
	content.add_child(title)
	var copy := Label.new()
	copy.text = "Este capítulo amplia sua jornada com novos geradores, milagres e profetas." if unlocked else "Desbloqueie este capítulo permanentemente, inclusive após a Ressurreição."
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 22)
	copy.add_theme_color_override("font_color", TEXT_DIM)
	content.add_child(copy)
	var detail := Label.new()
	detail.text = "CAPÍTULO ABERTO" if unlocked else "CUSTO  " + custo_txt + ("\nREQUER  " + NumberFormat.format(float(status.get("historical_requirement", 0.0))) + " de Fé histórica" if not em_gemas else "")
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_override("font", ManaTheme.body_semibold())
	detail.add_theme_font_size_override("font_size", 20)
	detail.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	content.add_child(detail)
	var action := Button.new()
	action.text = "ABRIR JORNADA" if unlocked else "DESBLOQUEAR"
	action.custom_minimum_size = Vector2(0, 76)
	action.add_theme_font_size_override("font_size", 22)
	ManaTheme.apply_primary_button(action)
	action.disabled = not unlocked and not bool(status.get("can_unlock", false))
	action.pressed.connect(func():
		if unlocked or GameState.unlock_adventure(adventure_id):
			SaveSystem.save_game()
			_show_tab("geradores")
			_select_adventure(adventure_id)
			popup.hide()
	)
	content.add_child(action)
	var close := Button.new()
	close.text = "Agora não"
	close.custom_minimum_size = Vector2(0, 58)
	close.add_theme_font_size_override("font_size", 19)
	close.pressed.connect(popup.hide)
	content.add_child(close)
	_popup_center_compact(popup, Vector2(760, 700))

func _show_boost_modal(boost_id: String) -> void:
	var data: Dictionary = GameState.get_boost_data(boost_id)
	if data.is_empty():
		return
	var remaining := GameState.get_boost_remaining(boost_id)
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#171b3b"), 26, ManaTheme.GOLD_DARK, 2, 30, true))
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2.ZERO
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	popup.add_child(content)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 22)
	content.add_child(hero)
	var icon := TextureRect.new()
	icon.texture = GameArt.sidebar_boost_icon(boost_id)
	icon.custom_minimum_size = Vector2(138, 138)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.add_child(icon)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 2)
	hero.add_child(heading)
	var eyebrow := Label.new()
	eyebrow.text = "IMPULSO CELESTIAL"
	eyebrow.add_theme_font_override("font", ManaTheme.body_semibold())
	eyebrow.add_theme_font_size_override("font_size", 18)
	eyebrow.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	heading.add_child(eyebrow)
	var title := Label.new()
	title.text = str(data.nome)
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", ManaTheme.CREAM)
	heading.add_child(title)
	var effect := Label.new()
	effect.text = str(data.efeito)
	effect.add_theme_font_override("font", ManaTheme.body_semibold())
	effect.add_theme_font_size_override("font_size", 24)
	effect.add_theme_color_override("font_color", Color("#91e6d0"))
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(effect)

	var description := Label.new()
	description.text = str(data.descricao)
	description.add_theme_font_size_override("font_size", 22)
	description.add_theme_color_override("font_color", TEXT_DIM)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)

	var duration := "Imediato" if int(data.duracao) <= 0 else _format_duration(float(data.duracao))
	var details := PanelContainer.new()
	details.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#22264d"), 16, Color(1.0, 0.77, 0.42, 0.18), 1, 16))
	content.add_child(details)
	var detail_text := Label.new()
	detail_text.text = "DURAÇÃO  " + duration + "\nDISPONÍVEL  " + str(GameState.get_boost_inventory(boost_id)) + " carga" + ("" if GameState.get_boost_inventory(boost_id) == 1 else "s") + ("\nATIVO  " + _format_duration(remaining) + " restante" if remaining > 0 else "")
	detail_text.add_theme_font_override("font", ManaTheme.body_semibold())
	detail_text.add_theme_font_size_override("font_size", 20)
	detail_text.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	details.add_child(detail_text)

	var use_button := Button.new()
	var inventory := GameState.get_boost_inventory(boost_id)
	use_button.text = "USAR  ·  " + str(inventory) + (" CARGA" if inventory == 1 else " CARGAS")
	use_button.custom_minimum_size = Vector2(0, 76)
	use_button.add_theme_font_size_override("font_size", 22)
	ManaTheme.apply_primary_button(use_button)
	use_button.disabled = inventory <= 0
	use_button.pressed.connect(func():
		if GameState.use_boost_charge(boost_id):
			_refresh_boost_icons()
			_refresh_boost_store()
			_update_all()
			popup.hide()
	)
	content.add_child(use_button)

	if boost_id in ["fervor", "passo_ligeiro"]:
		var video_button := Button.new()
		var videos_left := GameState.get_reward_videos_remaining()
		video_button.text = "▶  VÍDEO  ·  +30 MIN  ·  " + str(videos_left) + "/" + str(GameState.REWARD_VIDEO_LIMIT)
		video_button.custom_minimum_size = Vector2(0, 72)
		video_button.add_theme_font_size_override("font_size", 20)
		video_button.add_theme_color_override("font_color", ManaTheme.CREAM)
		video_button.add_theme_color_override("font_hover_color", ManaTheme.CREAM)
		video_button.add_theme_stylebox_override("normal", ManaTheme.button_style(Color("#28536a"), Color("#71cbd0"), 18, 2, 20, 12))
		video_button.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#367287"), Color("#b0ffff"), 18, 2, 20, 12))
		video_button.disabled = videos_left <= 0
		video_button.pressed.connect(func():
			video_button.disabled = true
			video_button.text = "REPRODUZINDO VÍDEO..."
			await get_tree().create_timer(2.0).timeout
			if GameState.activate_boost_from_video(boost_id):
				_refresh_boost_icons()
				_update_all()
				popup.hide()
			else:
				video_button.text = "COTA DE VÍDEOS ESGOTADA"
		)
		content.add_child(video_button)

	var close := Button.new()
	close.text = "Agora não"
	close.custom_minimum_size = Vector2(0, 58)
	close.add_theme_font_size_override("font_size", 19)
	close.pressed.connect(popup.hide)
	content.add_child(close)
	_popup_center_compact(popup, Vector2(760, 730 if boost_id in ["fervor", "passo_ligeiro"] else 640))

func _popup_center_compact(popup: PopupPanel, preferred_size: Vector2) -> void:
	var viewport := get_viewport_rect().size
	var desired := Vector2i(
		int(minf(preferred_size.x, viewport.x * 0.86)),
		int(minf(preferred_size.y, viewport.y * 0.86))
	)
	# popup_centered trata o tamanho recebido como minimo e preserva o tamanho
	# expandido anterior. Travamos a janela no tamanho desejado antes de exibi-la.
	popup.min_size = desired
	popup.max_size = desired
	popup.size = desired
	# O PopupPanel conhece o espaco de coordenadas do viewport embutido; depois
	# de travar o tamanho, delegamos somente o posicionamento ao metodo nativo.
	popup.popup_centered()

func _format_duration(seconds: float) -> String:
	var total := maxi(0, ceili(seconds))
	if total < 60:
		return str(total) + "s"
	if total < 3600:
		return "%dm %02ds" % [total / 60, total % 60]
	return "%dh %02dm" % [total / 3600, (total % 3600) / 60]

func _format_boost_timer(seconds: int) -> String:
	var total := maxi(0, seconds)
	if total >= 3600:
		return "%d:%02d" % [total / 3600, (total % 3600) / 60]
	return "%02d:%02d" % [total / 60, total % 60]

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

	# Botao unico: cada toque avanca para o proximo modo da ordem.
	_modo_btn = _build_framed_button(Color("#3a1c35"), Color("#ca6f9e"), Color("#ffc1df"), Color("#542749"))
	_modo_btn.add_theme_font_override("font", ManaTheme.body_semibold())
	_modo_btn.text = ""
	_modo_btn.custom_minimum_size = Vector2(128, 54)
	_modo_btn.tooltip_text = "Alternar quantidade comprada por toque"
	_modo_display_label = Label.new()
	_modo_display_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modo_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modo_display_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_modo_display_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_modo_display_label.add_theme_font_size_override("font_size", 22)
	_modo_display_label.add_theme_color_override("font_color", Color("#ffd5e7"))
	_modo_display_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modo_btn.add_child(_modo_display_label)
	_modo_btn.pressed.connect(_on_modo_pressed)
	panel.add_child(_modo_btn)

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
		_modo_display_label.text = _modo_label(_modo_compra)

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
	vbox.add_child(_build_tenda_wallet_area())

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
	var reward_center := CenterContainer.new()
	reward_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_center.add_child(_build_daily_gem_reward())
	lista.add_child(reward_center)

	lista.add_child(_build_gem_section_title("IMPULSOS CELESTIAIS", "Compre cargas para usar na jornada"))
	var boost_grid := GridContainer.new()
	boost_grid.columns = 3
	boost_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boost_grid.add_theme_constant_override("h_separation", 12)
	boost_grid.add_theme_constant_override("v_separation", 12)
	for boost_id in ["fervor", "pentecoste", "colheita", "passo_ligeiro", "maos_santas"]:
		boost_grid.add_child(_build_boost_store_card(boost_id))
	boost_grid.add_child(_build_daily_boost_video_card())
	lista.add_child(boost_grid)

	lista.add_child(_build_gem_section_title("GEMAS", "Pacotes planejados para o lançamento"))
	var package_grid := GridContainer.new()
	package_grid.columns = 3
	package_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	package_grid.add_theme_constant_override("h_separation", 12)
	package_grid.add_theme_constant_override("v_separation", 12)
	for pacote in [["Punhado", 80, "R$ 9,90", false], ["Bolsa", 500, "R$ 39,90", true], ["Baú", 1200, "R$ 79,90", false]]:
		package_grid.add_child(_build_gem_package(str(pacote[0]), int(pacote[1]), str(pacote[2]), bool(pacote[3])))
	lista.add_child(package_grid)

	# Os dois videos possuem contadores independentes na interface.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_refresh_tenda_timers)
	vbox.add_child(timer)
	timer.autostart = true

	_refresh_gemas()
	return vbox

func _build_tenda_wallet_area() -> Control:
	var area := Control.new()
	area.custom_minimum_size = Vector2(0, 126)
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gem_wallet_panel = PanelContainer.new()
	_gem_wallet_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#102b3c"), 20, Color("#79e6e8"), 2, 20, true))
	area.add_child(_gem_wallet_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_gem_wallet_panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = GameArt.GEM_ICON
	icon.custom_minimum_size = Vector2(70, 70)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", -3)
	row.add_child(copy)
	var title := Label.new()
	title.text = "CARTEIRA"
	title.add_theme_font_override("font", ManaTheme.body_semibold())
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("#9edcdf"))
	copy.add_child(title)
	_gemas_label = Label.new()
	_gemas_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_gemas_label.add_theme_font_size_override("font_size", 42)
	_gemas_label.add_theme_color_override("font_color", Color("#e8ffff"))
	_gemas_label.clip_text = true
	_gemas_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_gemas_label)
	_gemas_total_label = Label.new()
	_gemas_total_label.add_theme_font_size_override("font_size", 16)
	_gemas_total_label.add_theme_color_override("font_color", Color("#9edcdf"))
	_gemas_total_label.clip_text = true
	_gemas_total_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_gemas_total_label)
	_gem_sources_button = Button.new()
	_gem_sources_button.text = "?"
	_gem_sources_button.tooltip_text = "Como conseguir Gemas"
	_gem_sources_button.add_theme_font_override("font", ManaTheme.serif_bold())
	_gem_sources_button.add_theme_font_size_override("font_size", 29)
	_gem_sources_button.add_theme_color_override("font_color", Color("#d9fdff"))
	_gem_sources_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_gem_sources_button.add_theme_stylebox_override("normal", ManaTheme.button_style(Color("#173447"), Color("#79e6e8"), 16, 2, 10, 6))
	_gem_sources_button.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#28536a"), Color("#c4ffff"), 16, 2, 10, 6))
	_gem_sources_button.pressed.connect(_show_gem_sources_modal)
	area.add_child(_gem_sources_button)
	return area

func _layout_tenda_wallet() -> void:
	if _gem_wallet_panel == null or _gem_sources_button == null:
		return
	var target_width := clampf(get_viewport_rect().size.x * 0.50, 350.0, 540.0)
	var half_width := target_width * 0.5
	_gem_wallet_panel.set_anchors_preset(Control.PRESET_CENTER)
	_gem_wallet_panel.offset_left = -half_width
	_gem_wallet_panel.offset_right = half_width
	_gem_wallet_panel.offset_top = -54
	_gem_wallet_panel.offset_bottom = 54
	_gem_sources_button.set_anchors_preset(Control.PRESET_CENTER)
	_gem_sources_button.offset_left = half_width + 12
	_gem_sources_button.offset_right = half_width + 64
	_gem_sources_button.offset_top = -26
	_gem_sources_button.offset_bottom = 26

func _build_daily_gem_reward() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 108)
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#f4edda"), 18, Color("#d8b65c"), 2, 20, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = GameArt.GEM_ICON
	icon.custom_minimum_size = Vector2(68, 68)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	_video_reward_title_label = Label.new()
	_video_reward_title_label.text = "+" + str(_video_gem_reward()) + " GEMAS"
	_video_reward_title_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_video_reward_title_label.add_theme_font_size_override("font_size", 28)
	_video_reward_title_label.add_theme_color_override("font_color", ManaTheme.INK)
	copy.add_child(_video_reward_title_label)
	_video_status_label = Label.new()
	_video_status_label.add_theme_font_size_override("font_size", 16)
	_video_status_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	copy.add_child(_video_status_label)
	_video_btn = Button.new()
	_video_btn.text = "ASSISTIR"
	_video_btn.custom_minimum_size = Vector2(166, 62)
	_video_btn.add_theme_font_size_override("font_size", 18)
	ManaTheme.apply_primary_button(_video_btn)
	_video_btn.pressed.connect(_on_video_pressed)
	row.add_child(_video_btn)
	return panel

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

func _build_boost_store_card(boost_id: String) -> PanelContainer:
	var data := GameState.get_boost_data(boost_id)
	var card := PanelContainer.new()
	# Tres colunas deixam cada oferta quase quadrada no painel de gemas.
	card.custom_minimum_size = Vector2(0, 300)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#1c2b46"), 16, Color("#4a7895"), 1, 14, true))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)
	var icon := TextureRect.new()
	icon.texture = GameArt.sidebar_boost_icon(boost_id)
	icon.custom_minimum_size = Vector2(0, 92)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var title := Label.new()
	title.text = str(data.get("nome", "Impulso")).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ManaTheme.body_semibold())
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", ManaTheme.CREAM)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(title)
	var effect := Label.new()
	effect.text = str(data.get("efeito", ""))
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.custom_minimum_size = Vector2(0, 38)
	effect.add_theme_font_size_override("font_size", 16)
	effect.add_theme_color_override("font_color", Color("#91e6d0"))
	content.add_child(effect)
	var stock := Label.new()
	stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock.add_theme_font_override("font", ManaTheme.body_semibold())
	stock.add_theme_font_size_override("font_size", 14)
	stock.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	content.add_child(stock)
	_boost_store_count_labels[boost_id] = stock
	var buy := Button.new()
	buy.text = "COMPRAR  ·  " + str(int(data.get("custo", 0)))
	buy.icon = GameArt.GEM_ICON
	buy.expand_icon = true
	buy.add_theme_constant_override("icon_max_width", 20)
	buy.custom_minimum_size = Vector2(0, 52)
	buy.add_theme_font_size_override("font_size", 16)
	ManaTheme.apply_primary_button(buy)
	buy.pressed.connect(func():
		if GameState.buy_boost_charge(boost_id):
			_refresh_gemas()
			_refresh_boost_icons()
			_update_all()
	)
	content.add_child(buy)
	_boost_store_buttons[boost_id] = buy
	return card

func _build_daily_boost_video_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 300)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#183849"), 16, Color("#79e6e8"), 2, 14, true))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)
	var blessing_icon := TextureRect.new()
	blessing_icon.texture = GameArt.DAILY_BLESSING_ICON
	blessing_icon.custom_minimum_size = Vector2(0, 92)
	blessing_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blessing_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	blessing_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(blessing_icon)
	var title := Label.new()
	title.text = "BÊNÇÃO DIÁRIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ManaTheme.body_semibold())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ManaTheme.CREAM)
	content.add_child(title)
	var effect := Label.new()
	effect.text = "Revela 1 impulso celestial"
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.custom_minimum_size = Vector2(0, 38)
	effect.add_theme_font_size_override("font_size", 16)
	effect.add_theme_color_override("font_color", Color("#91e6d0"))
	content.add_child(effect)
	_daily_boost_video_status = Label.new()
	_daily_boost_video_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_boost_video_status.add_theme_font_override("font", ManaTheme.body_semibold())
	_daily_boost_video_status.add_theme_font_size_override("font_size", 13)
	_daily_boost_video_status.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	content.add_child(_daily_boost_video_status)
	_daily_boost_video_button = Button.new()
	_daily_boost_video_button.text = "▶  RECEBER POR VÍDEO"
	_daily_boost_video_button.custom_minimum_size = Vector2(0, 52)
	_daily_boost_video_button.add_theme_font_size_override("font_size", 16)
	_daily_boost_video_button.add_theme_color_override("font_color", ManaTheme.CREAM)
	_daily_boost_video_button.add_theme_color_override("font_hover_color", ManaTheme.CREAM)
	_daily_boost_video_button.add_theme_stylebox_override("normal", ManaTheme.button_style(Color("#28536a"), Color("#71cbd0"), 16, 2, 16, 8))
	_daily_boost_video_button.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#367287"), Color("#b0ffff"), 16, 2, 16, 8))
	_daily_boost_video_button.pressed.connect(_on_daily_boost_video_pressed)
	content.add_child(_daily_boost_video_button)
	return card

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

func _show_gem_sources_modal() -> void:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#171b3b"), 24, Color("#79e6e8"), 2, 28, true))
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	popup.add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	content.add_child(heading)
	var icon := TextureRect.new()
	icon.texture = GameArt.GEM_ICON
	icon.custom_minimum_size = Vector2(62, 62)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(icon)
	var title := Label.new()
	title.text = "Como conseguir Gemas"
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ManaTheme.CREAM)
	heading.add_child(title)
	var intro := Label.new()
	intro.text = "Gemas também são conquistadas jogando."
	intro.add_theme_font_size_override("font_size", 19)
	intro.add_theme_color_override("font_color", TEXT_DIM)
	content.add_child(intro)
	for source in [
		["RESSURREIÇÃO", "+" + str(LiveOps.scale_free_gem_reward(10)), "Depois, +" + str(LiveOps.scale_free_gem_reward(2)) + " por jornada"],
		["VIDA DE CRISTO", "+" + str(LiveOps.scale_free_gem_reward(50)), "Ao concluir o capítulo"],
		["IGREJA & APOCALIPSE", "+" + str(LiveOps.scale_free_gem_reward(100)), "Ao concluir o capítulo"],
	]:
		content.add_child(_build_gem_source_row(str(source[0]), str(source[1]), str(source[2])))
	var close := Button.new()
	close.text = "Entendi"
	close.custom_minimum_size = Vector2(0, 56)
	close.add_theme_font_size_override("font_size", 18)
	ManaTheme.apply_primary_button(close)
	close.pressed.connect(popup.hide)
	content.add_child(close)
	_popup_center_compact(popup, Vector2(650, 560))

func _build_gem_package(name: String, amount: int, price: String, featured: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 246)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := ManaTheme.GOLD if featured else Color("#497a86")
	var bg := Color("#18313e") if featured else Color("#1d2839")
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(bg, 18, border, 2 if featured else 1, 18, featured))
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = GameArt.GEM_ICON
	icon.custom_minimum_size = Vector2(0, 74)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", -3)
	row.add_child(info)
	var package_name := Label.new()
	package_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	package_name.text = name.to_upper() + ("  ·  MELHOR VALOR" if featured else "")
	package_name.add_theme_font_override("font", ManaTheme.body_semibold())
	package_name.add_theme_font_size_override("font_size", 19)
	package_name.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT if featured else TEXT_DIM)
	info.add_child(package_name)
	var package_amount := Label.new()
	package_amount.text = str(amount) + " Gemas"
	package_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	package_amount.add_theme_font_override("font", ManaTheme.serif_bold())
	package_amount.add_theme_font_size_override("font_size", 31)
	package_amount.add_theme_color_override("font_color", Color("#d9fdff"))
	info.add_child(package_amount)
	var comprar := Button.new()
	comprar.text = price + "\nEM BREVE"
	comprar.disabled = true
	comprar.custom_minimum_size = Vector2(0, 58)
	comprar.add_theme_font_size_override("font_size", 15)
	row.add_child(comprar)
	return card

func _refresh_gemas() -> void:
	_gemas_label.text = str(GameState.gemas) + " Gemas"
	_gemas_total_label.text = str(GameState.gemas_total) + " conquistadas desde o início"
	if _video_reward_title_label != null:
		_video_reward_title_label.text = "+" + str(_video_gem_reward()) + " GEMAS"
	_refresh_video_button()
	_refresh_daily_boost_video_card()
	_refresh_boost_store()


func _video_gem_reward() -> int:
	return LiveOps.scale_free_gem_reward(LiveOps.video_gems())

func _refresh_boost_store() -> void:
	for boost_id in _boost_store_buttons:
		var key := str(boost_id)
		var data := GameState.get_boost_data(key)
		var buy: Button = _boost_store_buttons[key]
		buy.disabled = GameState.gemas < int(data.get("custo", 0))
		var stock: Label = _boost_store_count_labels.get(key)
		if stock != null:
			var inventory := GameState.get_boost_inventory(key)
			stock.text = str(inventory) + (" CARGA" if inventory == 1 else " CARGAS")

func _refresh_video_button() -> void:
	if _video_btn == null or _panel_gemas == null or not _panel_gemas.visible:
		return
	var agora := Time.get_unix_time_from_system()
	var videos_left := GameState.get_reward_videos_remaining()
	if videos_left <= 0:
		_video_btn.text = "VÍDEOS ESGOTADOS"
		_video_status_label.text = "A cota de 6 vídeos volta em até 24 h"
		_video_btn.disabled = true
	elif agora >= _video_cooldown_until:
		_video_btn.text = "▶  ASSISTIR"
		_video_status_label.text = "Recompensa pronta  ·  " + str(videos_left) + "/" + str(GameState.REWARD_VIDEO_LIMIT) + " vídeos"
		_video_btn.disabled = false
	else:
		var restante := int(_video_cooldown_until - agora)
		_video_btn.text = "AGUARDE " + str(restante) + "s"
		_video_status_label.text = "Próxima recompensa em " + str(restante) + " segundos"
		_video_btn.disabled = true

func _refresh_daily_boost_video_card() -> void:
	if _daily_boost_video_button == null or _daily_boost_video_status == null:
		return
	var remaining := GameState.get_daily_boost_video_remaining_seconds()
	if remaining <= 0:
		_daily_boost_video_button.text = "▶  RECEBER POR VÍDEO"
		_daily_boost_video_button.disabled = false
		_daily_boost_video_status.text = "1 VÍDEO DISPONÍVEL HOJE"
	else:
		_daily_boost_video_button.text = "VÍDEO RESGATADO"
		_daily_boost_video_button.disabled = true
		var last_reward := GameState.get_daily_boost_video_last_reward()
		var received := "RECEBIDO: " + str(GameState.get_boost_data(last_reward).get("nome", "Impulso")) if not last_reward.is_empty() else "BÊNÇÃO RECEBIDA"
		_daily_boost_video_status.text = received + "\nVOLTA EM " + _format_duration(remaining)

func _refresh_tenda_timers() -> void:
	_refresh_video_button()
	_refresh_daily_boost_video_card()

# Modal de coleta offline: o ganho base ja foi creditado; as opcoes de
# video (x2) e gema (x3) somam o EXTRA por cima.
func _show_offline_modal(ganho: float) -> void:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE, 24, ManaTheme.GOLD_DARK, 2, 36))
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 28
	vbox.offset_right = -28
	vbox.offset_top = 24
	vbox.offset_bottom = -24
	vbox.add_theme_constant_override("separation", 12)
	popup.add_child(vbox)

	var title := Label.new()
	title.text = "Enquanto você esteve fora..."
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	var ganho_label := Label.new()
	ganho_label.text = "Seus profetas coletaram\n+" + NumberFormat.format(ganho) + " Fé"
	ganho_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ganho_label.add_theme_font_size_override("font_size", 30)
	ganho_label.add_theme_color_override("font_color", GOLD)
	vbox.add_child(ganho_label)

	var video_btn := Button.new()
	video_btn.text = "▶  Dobrar com vídeo  ·  +" + NumberFormat.format(ganho)
	video_btn.custom_minimum_size = Vector2(0, 70)
	video_btn.add_theme_font_size_override("font_size", 20)
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
	var offline_triple_cost := LiveOps.offline_triple_gem_cost()
	gema_btn.text = "Triplicar por " + str(offline_triple_cost) + " Gemas  ·  +" + NumberFormat.format(ganho * 2.0)
	gema_btn.custom_minimum_size = Vector2(0, 70)
	gema_btn.add_theme_font_size_override("font_size", 20)
	gema_btn.disabled = GameState.gemas < offline_triple_cost
	gema_btn.pressed.connect(func():
		if GameState.spend_gemas(offline_triple_cost):
			GameState.add_fe_bonus(ganho * 2.0)
			EventBus.toast_requested.emit("Ganho offline triplicado: +" + NumberFormat.format(ganho * 2.0) + " Fé")
		popup.hide()
	)
	vbox.add_child(gema_btn)

	var coletar_btn := Button.new()
	coletar_btn.text = "Coletar"
	coletar_btn.custom_minimum_size = Vector2(0, 70)
	coletar_btn.add_theme_font_size_override("font_size", 22)
	ManaTheme.apply_primary_button(coletar_btn)
	coletar_btn.pressed.connect(popup.hide)
	vbox.add_child(coletar_btn)

	_popup_center_compact(popup, Vector2(640, 560))

func _on_video_pressed() -> void:
	# Placeholder do rewarded ad: aqui entra o SDK (AdMob) no futuro.
	_video_cooldown_until = Time.get_unix_time_from_system() + VIDEO_COOLDOWN_S
	_video_btn.disabled = true
	_video_btn.text = "Reproduzindo vídeo..."
	await get_tree().create_timer(2.0).timeout
	if GameState.consume_reward_video():
		GameState.add_gemas(_video_gem_reward(), "vídeo")
		SaveSystem.save_game()
	_refresh_gemas()

func _on_daily_boost_video_pressed() -> void:
	if not GameState.can_claim_daily_boost_video() or _daily_boost_video_button == null:
		_refresh_daily_boost_video_card()
		return
	_daily_boost_video_button.disabled = true
	_daily_boost_video_button.text = "REPRODUZINDO VÍDEO..."
	await get_tree().create_timer(2.0).timeout
	var boost_id := GameState.claim_daily_random_boost_video()
	if not boost_id.is_empty():
		_refresh_boost_icons()
		_refresh_boost_store()
		_show_daily_boost_reveal(boost_id)
	_update_all()
	_refresh_gemas()

func _show_daily_boost_reveal(boost_id: String) -> void:
	var data := GameState.get_boost_data(boost_id)
	if data.is_empty():
		return
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#17223d"), 24, Color("#79e6e8"), 2, 28, true))
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	popup.add_child(content)
	var blessing := TextureRect.new()
	blessing.texture = GameArt.DAILY_BLESSING_ICON
	blessing.custom_minimum_size = Vector2(0, 100)
	blessing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blessing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	blessing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(blessing)
	var eyebrow := Label.new()
	eyebrow.text = "BÊNÇÃO RECEBIDA"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_override("font", ManaTheme.body_semibold())
	eyebrow.add_theme_font_size_override("font_size", 18)
	eyebrow.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	content.add_child(eyebrow)
	var reward_icon := TextureRect.new()
	reward_icon.texture = GameArt.sidebar_boost_icon(boost_id)
	reward_icon.custom_minimum_size = Vector2(0, 126)
	reward_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(reward_icon)
	var title := Label.new()
	title.text = str(data.get("nome", "Impulso"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", ManaTheme.CREAM)
	content.add_child(title)
	var effect := Label.new()
	effect.text = str(data.get("efeito", "")) + "\n1 carga adicionada aos seus impulsos"
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.add_theme_font_size_override("font_size", 19)
	effect.add_theme_color_override("font_color", Color("#91e6d0"))
	content.add_child(effect)
	var close := Button.new()
	close.text = "Guardar impulso"
	close.custom_minimum_size = Vector2(0, 62)
	close.add_theme_font_size_override("font_size", 19)
	ManaTheme.apply_primary_button(close)
	close.pressed.connect(popup.hide)
	content.add_child(close)
	_popup_center_compact(popup, Vector2(610, 660))

func _refresh_santos() -> void:
	var bonus_pct: float = (Economy.get_multiplicador_santos() - 1.0) * 100.0
	_santos_info_label.text = str(GameState.santos) + " Santos  ·  +" + String.num(bonus_pct, 1) + "% de produção global"
	_relics_label.text = NumberFormat.format(GameState.reliquias) + " Relíquias"

	# Objetivo visivel: quanto falta de fe acumulada para o proximo Santo.
	# Espelha a formula cubica de Economy.santos_ganhos.
	var santos_prox: int = GameState.get_santos_proximo_prestige()
	var proximo_alvo: float = pow(float(santos_prox + 1), 3.0) * Economy.get_prestige_divisor()
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

	for tab in [["geradores", "JORNADA"], ["milagres", "BÊNÇÃOS"], ["estudo", "ESTUDO"], ["santos", "SANTOS"], ["gemas", "TENDA"]]:
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
		var attention_tag := _build_tab_attention_tag()
		btn.add_child(attention_tag)
		_tab_buttons[tab[0]] = btn
		_tab_attention_tags[tab[0]] = attention_tag
		hbox.add_child(btn)

	return panel

func _build_tab_attention_tag() -> Label:
	var tag := Label.new()
	tag.text = "!"
	tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tag.offset_left = -32
	tag.offset_right = -6
	tag.offset_top = 7
	tag.offset_bottom = 33
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_theme_font_override("font", ManaTheme.body_semibold())
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", ManaTheme.CREAM)
	tag.add_theme_stylebox_override("normal", ManaTheme.panel_style(Color("#b65b3c"), 9, Color("#ffe0a6"), 1, 4, true))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.visible = false
	return tag

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
	_set_tab_attention("geradores", false)
	_set_tab_attention("milagres", _has_affordable_blessing())
	_set_tab_attention("estudo", _has_study_attention())
	_set_tab_attention("santos", _has_saints_attention())
	_set_tab_attention("gemas", _has_gems_attention())

func _set_tab_attention(tab: String, visible: bool) -> void:
	var tag: Label = _tab_attention_tags.get(tab)
	if tag != null:
		tag.visible = visible
	var button: Button = _tab_buttons.get(tab)
	if button != null:
		button.tooltip_text = "Ação disponível" if visible else ""

func _has_affordable_blessing() -> bool:
	for blessing_variant in Upgrades.disponiveis():
		var blessing: Dictionary = blessing_variant
		if GameState.fe >= float(blessing.get("custo", 0.0)):
			return true
	return false

func _has_study_attention() -> bool:
	if int(StudySystem.get_progress_summary().get("unread", 0)) > 0:
		return true
	for knowledge_variant in Conhecimentos.all():
		var knowledge: Dictionary = knowledge_variant
		var knowledge_id := str(knowledge.get("id", ""))
		if StudySystem.can_purchase_knowledge(knowledge_id) or StudySystem.can_activate_knowledge(knowledge_id):
			return true
	return false

func _has_saints_attention() -> bool:
	for gift_variant in Dadivas.disponiveis():
		var gift: Dictionary = gift_variant
		if GameState.santos >= int(gift.get("custo", 0)):
			return true
	var incoming_saints := GameState.get_santos_proximo_prestige()
	if incoming_saints <= 0:
		return false
	if int(GameState.estatisticas.get("prestiges", 0)) == 0:
		return true
	return incoming_saints > GameState.santos

func _has_gems_attention() -> bool:
	if GameState.can_claim_daily_boost_video():
		return true
	if GameState.get_reward_videos_remaining() > 0 and Time.get_unix_time_from_system() >= _video_cooldown_until:
		return true
	for boost_id in GameState.BOOSTS:
		if GameState.gemas >= int(GameState.get_boost_data(str(boost_id)).get("custo", 0)):
			return true
	return false

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
	LiveOps.config_changed.connect(_on_liveops_config_changed)
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
	EventBus.knowledge_activation_changed.connect(func(_id: String): _on_economy_changed())
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
	EventBus.boosts_changed.connect(func():
		_refresh_boost_icons()
		_refresh_boost_store()
		if _tab_atual == "gemas":
			_refresh_gemas()
		_update_all()
	)
	EventBus.cloud_conflict_detected.connect(_show_cloud_conflict_dialog)
	EventBus.sync_state_changed.connect(func(_state: String, message: String):
		if CloudIdentity.is_authenticated() and _notification_label != null:
			_notification_label.tooltip_text = message
	)


func _on_liveops_config_changed(_summary: Dictionary) -> void:
	_refresh_liveops_banner()
	if _gemas_label != null:
		_refresh_gemas()
	if _game_loaded:
		_update_all()


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
	_refresh_inactive_operator_stack()
	# Progresso dos ciclos anima a cada tick (barato); resto so a cada N ticks.
	_full_update_counter += 1
	var do_full: bool = _full_update_counter >= FULL_UPDATE_EVERY
	if do_full:
		_full_update_counter = 0
		_update_tab_badges()
		_refresh_boost_icons()
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
	_refresh_era_operator_grid()

func _refresh_era_operator_grid() -> void:
	if _era_operator_grid == null:
		return
	var generators := Geradores.get_by_adventure(_current_adventure)
	var expected_ids: Array[int] = []
	for generator in generators:
		expected_ids.append(int(generator.id))
	var existing_ids: Array[int] = []
	for generator_id in _era_squares:
		existing_ids.append(int(generator_id))
	expected_ids.sort()
	existing_ids.sort()
	if expected_ids != existing_ids:
		for child in _era_operator_grid.get_children():
			child.queue_free()
		_era_squares.clear()
		for generator in generators:
			var generator_id := int(generator.id)
			var slot := Control.new()
			slot.custom_minimum_size = Vector2(0, 30)
			slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_era_operator_grid.add_child(slot)
			var square: EraProgressSquare = EraProgressSquareScript.new()
			square.set_anchors_preset(Control.PRESET_FULL_RECT)
			square.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(square)
			_era_squares[generator_id] = square
	for generator in generators:
		var generator_id := int(generator.id)
		var square: EraProgressSquare = _era_squares.get(generator_id)
		var unlocked := GameState.is_unlocked(generator_id)
		square.visible = unlocked
		if not unlocked:
			continue
		var state: Dictionary = GameState.geradores.get(generator_id, {})
		var quantity := int(state.get("qtd", 0))
		var complete := quantity >= OPERATOR_PROGRESS_TARGET
		var fill := clampf(float(quantity) / float(OPERATOR_PROGRESS_TARGET), 0.0, 1.0)
		square.set_state(fill, complete, str(generator.nome) + " · " + str(quantity) + "/" + str(OPERATOR_PROGRESS_TARGET))

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
	_refresh_inactive_operator_stack()
	if _panel_estudo != null and _tab_atual == "estudo":
		_panel_estudo.refresh()

func _on_buy(gen_id: int, amount: int) -> void:
	GameState.buy_generator(gen_id, amount)

func _on_prophet(gen_id: int) -> void:
	GameState.buy_prophet(gen_id)

func _on_cycle_start(gen_id: int) -> void:
	if GameState.start_cycle(gen_id):
		_update_item(gen_id)
		_refresh_inactive_operator_stack()

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
	get_window().content_scale_factor = 1.0
	theme = ManaTheme.make_theme(_font_scale)
	_apply_font_scale_to_tree(self)

func _apply_font_scale_to_tree(node: Node) -> void:
	if node is Control:
		_apply_font_scale_to_control(node)
	for child in node.get_children():
		_apply_font_scale_to_tree(child)

func _apply_font_scale_to_control(control: Control) -> void:
	for theme_key in [&"font_size", &"normal_font_size"]:
		if not control.has_theme_font_size_override(theme_key):
			continue
		var base_meta := "mana_base_" + str(theme_key)
		if not control.has_meta(base_meta):
			control.set_meta(base_meta, control.get_theme_font_size(theme_key))
		var base_size := int(control.get_meta(base_meta))
		control.add_theme_font_size_override(theme_key, maxi(1, roundi(float(base_size) * _font_scale)))

func _on_tree_node_added(node: Node) -> void:
	if is_equal_approx(_font_scale, 1.0) or node == self or not is_ancestor_of(node):
		return
	call_deferred("_apply_font_scale_to_tree", node)

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
		else:
			btn.pressed.connect(func():
				_set_font_scale(scale)
				popup.hide()
			)
		fonte_row.add_child(btn)

	var cloud_divider := HSeparator.new()
	vbox.add_child(cloud_divider)

	var cloud_title := Label.new()
	cloud_title.text = "Conta de Peregrino"
	cloud_title.add_theme_font_override("font", ManaTheme.serif_bold())
	cloud_title.add_theme_font_size_override("font_size", 30)
	cloud_title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	vbox.add_child(cloud_title)

	var cloud_status := Label.new()
	cloud_status.text = CloudSave.state_message()
	cloud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cloud_status.add_theme_font_size_override("font_size", 21)
	cloud_status.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(cloud_status)

	var cloud_btn := Button.new()
	cloud_btn.text = "Gerenciar save online" if CloudIdentity.is_authenticated() else "Ativar ou recuperar save online"
	cloud_btn.custom_minimum_size = Vector2(0, 70)
	ManaTheme.apply_primary_button(cloud_btn)
	cloud_btn.pressed.connect(func():
		popup.hide()
		_show_cloud_account()
	)
	vbox.add_child(cloud_btn)

	var legal_btn := Button.new()
	legal_btn.text = "Aviso legal"
	legal_btn.custom_minimum_size = Vector2(0, 70)
	legal_btn.pressed.connect(func():
		popup.hide()
		_show_legal()
	)
	vbox.add_child(legal_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Apagar progresso deste aparelho"
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

func _show_cloud_account() -> void:
	var parts: Dictionary = _create_cloud_popup("Conta de Peregrino")
	var popup: PopupPanel = parts.popup
	var content: VBoxContainer = parts.content
	var description := Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 21)
	description.add_theme_color_override("font_color", TEXT_DIM)
	if CloudIdentity.is_authenticated():
		description.text = CloudSave.state_message() + "\nConta: " + CloudIdentity.player_id().left(13) + "...  ·  revisão " + str(CloudSave.cloud_revision())
	else:
		description.text = "Opcional. Seu jogo continua funcionando offline. A conta permite restaurar o progresso após reinstalar e sincronizar aparelhos."
	content.add_child(description)

	if not CloudIdentity.is_authenticated():
		var activate_btn := _cloud_action_button("Ativar save online", true)
		activate_btn.pressed.connect(func():
			popup.hide()
			_confirm_activate_cloud()
		)
		content.add_child(activate_btn)
		var recover_btn := _cloud_action_button("Recuperar com código", false)
		recover_btn.pressed.connect(func():
			popup.hide()
			_prompt_recover_cloud()
		)
		content.add_child(recover_btn)
	else:
		var sync_btn := _cloud_action_button("Sincronizar agora", true)
		sync_btn.disabled = CloudSave.has_conflict()
		sync_btn.pressed.connect(func():
			popup.hide()
			_cloud_sync_pressed()
		)
		content.add_child(sync_btn)

		if CloudSave.has_conflict():
			var conflict_btn := _cloud_action_button("Resolver conflito", false)
			conflict_btn.pressed.connect(func():
				popup.hide()
				_show_cloud_conflict_dialog(CloudSave.conflict_summary())
			)
			content.add_child(conflict_btn)

		var devices_btn := _cloud_action_button("Aparelhos e sessões", false)
		devices_btn.pressed.connect(func():
			popup.hide()
			_show_cloud_devices()
		)
		content.add_child(devices_btn)

		var recovery_btn := _cloud_action_button("Segurança e código de recuperação", false)
		recovery_btn.pressed.connect(func():
			popup.hide()
			_show_cloud_security()
		)
		content.add_child(recovery_btn)

		var logout_btn := _cloud_action_button("Desvincular este aparelho", false)
		logout_btn.pressed.connect(func():
			popup.hide()
			_confirm_cloud_logout()
		)
		content.add_child(logout_btn)

		var delete_btn := _cloud_action_button("Excluir conta e save da nuvem", false, true)
		delete_btn.pressed.connect(func():
			popup.hide()
			_show_cloud_deletion_options()
		)
		content.add_child(delete_btn)

	var close_btn := _cloud_action_button("Fechar", false)
	close_btn.pressed.connect(popup.hide)
	content.add_child(close_btn)
	_popup_cloud(parts)


func _create_cloud_popup(title_text: String) -> Dictionary:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE, 24, ManaTheme.OUTLINE, 2, 30))
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(minf(get_viewport_rect().size.x * 0.86, 820.0), minf(get_viewport_rect().size.y * 0.72, 1100.0))
	popup.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	var title := Label.new()
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	content.add_child(title)
	return {"popup": popup, "content": content}


func _popup_cloud(parts: Dictionary) -> void:
	var popup: PopupPanel = parts.popup
	popup.popup_centered(Vector2i(
		int(minf(get_viewport_rect().size.x * 0.9, 860.0)),
		int(minf(get_viewport_rect().size.y * 0.78, 1180.0))
	))


func _cloud_action_button(text_value: String, primary: bool = false, destructive: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 70)
	if primary:
		ManaTheme.apply_primary_button(button)
	if destructive:
		button.add_theme_color_override("font_color", Color("#ff9d91"))
		button.add_theme_color_override("font_hover_color", Color("#ffc0b8"))
	return button


func _confirm_activate_cloud() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Ativar save online"
	dialog.dialog_text = "Será criada uma Conta de Peregrino anônima. Você receberá um código mostrado uma única vez. Guarde-o fora deste aparelho: sem o código e sem uma sessão ativa, não há como recuperar a conta.\n\nO save local continuará funcionando quando a internet cair."
	dialog.get_ok_button().text = "Criar conta"
	dialog.get_cancel_button().text = "Agora não"
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_activate_cloud_account()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _activate_cloud_account() -> void:
	_show_notification("Criando Conta de Peregrino...")
	var result: Dictionary = await CloudIdentity.create_account()
	if not bool(result.get("ok", false)):
		if bool(result.get("accountCreated", false)) and not str(result.get("recoveryCode", "")).is_empty():
			_show_recovery_code_once(str(result.get("recoveryCode", "")), "Conta criada — sessão não salva")
			return
		_show_cloud_error(result)
		return
	var reconcile: Dictionary = await CloudSave.reconcile_account()
	if not bool(reconcile.get("ok", false)):
		_show_cloud_error(reconcile)
	var recovery_code: String = str(result.get("recoveryCode", ""))
	if recovery_code.is_empty():
		_show_cloud_error({"message": "A conta foi criada, mas o servidor não retornou o código de recuperação."})
		return
	_show_recovery_code_once(recovery_code, "Código de recuperação")


func _prompt_recover_cloud() -> void:
	_show_cloud_text_prompt(
		"Recuperar save online",
		"Digite o código de recuperação. Antes de enviar qualquer progresso deste aparelho, a nuvem será consultada. Se ambos tiverem progresso, você escolherá qual manter.",
		"R1-...",
		func(value: String): _recover_cloud_account(value)
	)


func _recover_cloud_account(recovery_code: String) -> void:
	_show_notification("Recuperando Conta de Peregrino...")
	var result: Dictionary = await CloudIdentity.recover_account(recovery_code)
	if not bool(result.get("ok", false)):
		_show_cloud_error(result)
		return
	var reconcile: Dictionary = await CloudSave.reconcile_account()
	if not bool(reconcile.get("ok", false)):
		_show_cloud_error(reconcile)
	elif bool(reconcile.get("conflict", false)):
		_show_cloud_conflict_dialog(CloudSave.conflict_summary())
	else:
		_show_notification("Save online recuperado")


func _cloud_sync_pressed() -> void:
	_show_notification("Sincronizando...")
	var result: Dictionary = await CloudSave.sync_now()
	if bool(result.get("ok", false)):
		_show_notification("Progresso sincronizado")
	else:
		_show_cloud_error(result)


func _show_cloud_security() -> void:
	var parts: Dictionary = _create_cloud_popup("Segurança da conta")
	var popup: PopupPanel = parts.popup
	var content: VBoxContainer = parts.content
	var info := Label.new()
	info.text = "O código não fica salvo no jogo. Rotacioná-lo revoga as outras sessões. Se ele foi perdido, um reset exige espera de 24 horas e pode ser cancelado por qualquer aparelho conectado."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", TEXT_DIM)
	info.add_theme_font_size_override("font_size", 21)
	content.add_child(info)

	var rotate_btn := _cloud_action_button("Trocar código de recuperação", true)
	rotate_btn.pressed.connect(func():
		popup.hide()
		_show_cloud_text_prompt("Trocar código", "Digite o código atual. O novo código será mostrado uma única vez e as outras sessões serão revogadas.", "Código atual", func(value: String): _rotate_cloud_recovery(value))
	)
	content.add_child(rotate_btn)

	var lost_btn := _cloud_action_button("Perdi o código — iniciar espera de 24 h", false)
	lost_btn.pressed.connect(func():
		popup.hide()
		_confirm_recovery_reset()
	)
	content.add_child(lost_btn)

	var actions_btn := _cloud_action_button("Ver ações de segurança pendentes", false)
	actions_btn.pressed.connect(func():
		popup.hide()
		_show_security_actions()
	)
	content.add_child(actions_btn)
	var close_btn := _cloud_action_button("Voltar", false)
	close_btn.pressed.connect(func():
		popup.hide()
		_show_cloud_account()
	)
	content.add_child(close_btn)
	_popup_cloud(parts)


func _rotate_cloud_recovery(current_code: String) -> void:
	var result: Dictionary = await CloudIdentity.rotate_recovery_code(current_code)
	if not bool(result.get("ok", false)):
		_show_cloud_error(result)
		return
	_show_recovery_code_once(str(result.get("recoveryCode", "")), "Novo código de recuperação")


func _confirm_recovery_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Iniciar reset do código"
	dialog.dialog_text = "O reset ficará pendente por 24 horas. Qualquer sessão ativa poderá cancelá-lo. Depois da espera, somente este aparelho poderá concluí-lo; as outras sessões serão revogadas."
	dialog.get_ok_button().text = "Iniciar espera"
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_request_recovery_reset()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _request_recovery_reset() -> void:
	var result: Dictionary = await CloudIdentity.request_recovery_reset()
	if bool(result.get("ok", false)):
		_show_notification("Reset agendado para daqui a 24 horas")
	else:
		_show_cloud_error(result)


func _show_security_actions() -> void:
	var result: Dictionary = await CloudIdentity.list_security_actions()
	if not bool(result.get("ok", false)):
		_show_cloud_error(result)
		return
	var parts: Dictionary = _create_cloud_popup("Ações de segurança")
	var popup: PopupPanel = parts.popup
	var content: VBoxContainer = parts.content
	var items: Array = result.get("items", []) as Array
	if items.is_empty():
		var empty := Label.new()
		empty.text = "Nenhuma ação pendente."
		empty.add_theme_color_override("font_color", TEXT_DIM)
		content.add_child(empty)
	for action_value: Variant in items:
		if action_value is not Dictionary:
			continue
		var action: Dictionary = action_value as Dictionary
		var action_id: String = str(action.get("id", ""))
		var row := VBoxContainer.new()
		var action_label := Label.new()
		var kind_label: String = "Reset do código" if str(action.get("kind", "")) == "recovery_reset" else "Exclusão da conta"
		action_label.text = kind_label + " · " + str(action.get("status", "")) + "\nDisponível em: " + Time.get_datetime_string_from_unix_time(int(action.get("executeAfter", 0)), true)
		action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(action_label)
		if str(action.get("status", "")) == "pending":
			var cancel_btn := _cloud_action_button("Cancelar", false)
			cancel_btn.pressed.connect(func():
				popup.hide()
				_cancel_security_action(action_id)
			)
			row.add_child(cancel_btn)
			if str(action.get("kind", "")) == "recovery_reset" and bool(action.get("requestedByThisDevice", false)) and Time.get_unix_time_from_system() >= float(action.get("executeAfter", 0)):
				var complete_btn := _cloud_action_button("Concluir e receber novo código", true)
				complete_btn.pressed.connect(func():
					popup.hide()
					_complete_security_action(action_id)
				)
				row.add_child(complete_btn)
		content.add_child(row)
		content.add_child(HSeparator.new())
	var back_btn := _cloud_action_button("Voltar", false)
	back_btn.pressed.connect(func():
		popup.hide()
		_show_cloud_security()
	)
	content.add_child(back_btn)
	_popup_cloud(parts)


func _cancel_security_action(action_id: String) -> void:
	var result: Dictionary = await CloudIdentity.cancel_security_action(action_id)
	if bool(result.get("ok", false)):
		_show_notification("Ação de segurança cancelada")
	else:
		_show_cloud_error(result)


func _complete_security_action(action_id: String) -> void:
	var result: Dictionary = await CloudIdentity.complete_security_action(action_id)
	if not bool(result.get("ok", false)):
		_show_cloud_error(result)
		return
	_show_recovery_code_once(str(result.get("recoveryCode", "")), "Novo código de recuperação")


func _show_cloud_devices() -> void:
	var result: Dictionary = await CloudIdentity.list_devices()
	if not bool(result.get("ok", false)):
		_show_cloud_error(result)
		return
	var parts: Dictionary = _create_cloud_popup("Aparelhos e sessões")
	var popup: PopupPanel = parts.popup
	var content: VBoxContainer = parts.content
	for device_value: Variant in result.get("items", []) as Array:
		if device_value is not Dictionary:
			continue
		var device: Dictionary = device_value as Dictionary
		var target_id: String = str(device.get("id", ""))
		var label := Label.new()
		label.text = str(device.get("label", "Aparelho")) + (" · este aparelho" if bool(device.get("isCurrent", false)) else "") + "\nÚltimo acesso: " + Time.get_datetime_string_from_unix_time(int(device.get("lastSeenAt", 0)), true) + " · sessões: " + str(device.get("activeSessions", 0))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(label)
		if not bool(device.get("isCurrent", false)) and device.get("revokedAt", null) == null:
			var revoke_btn := _cloud_action_button("Revogar aparelho", false, true)
			revoke_btn.pressed.connect(func():
				popup.hide()
				_revoke_cloud_device(target_id)
			)
			content.add_child(revoke_btn)
		content.add_child(HSeparator.new())
	var revoke_others := _cloud_action_button("Encerrar todas as outras sessões", false, true)
	revoke_others.pressed.connect(func():
		popup.hide()
		_revoke_other_cloud_sessions()
	)
	content.add_child(revoke_others)
	var back_btn := _cloud_action_button("Voltar", false)
	back_btn.pressed.connect(func():
		popup.hide()
		_show_cloud_account()
	)
	content.add_child(back_btn)
	_popup_cloud(parts)


func _revoke_cloud_device(target_id: String) -> void:
	var result: Dictionary = await CloudIdentity.revoke_device(target_id)
	if bool(result.get("ok", false)):
		_show_notification("Aparelho revogado")
	else:
		_show_cloud_error(result)


func _revoke_other_cloud_sessions() -> void:
	var result: Dictionary = await CloudIdentity.revoke_other_sessions()
	if bool(result.get("ok", false)):
		_show_notification("Outras sessões encerradas")
	else:
		_show_cloud_error(result)


func _confirm_cloud_logout() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Desvincular aparelho"
	dialog.dialog_text = "O progresso local será mantido, mas este aparelho deixará de sincronizar. Para entrar novamente, será necessário o código de recuperação."
	dialog.get_ok_button().text = "Desvincular"
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_cloud_logout()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _cloud_logout() -> void:
	var result: Dictionary = await CloudIdentity.logout()
	if bool(result.get("ok", false)):
		_show_notification("Este aparelho foi desvinculado")
	else:
		_show_cloud_error(result)


func _show_cloud_deletion_options() -> void:
	var parts: Dictionary = _create_cloud_popup("Excluir conta online")
	var popup: PopupPanel = parts.popup
	var content: VBoxContainer = parts.content
	var warning := Label.new()
	warning.text = "Isto apaga a conta e o save da nuvem. O progresso deste aparelho só será apagado pelo comando separado nas Configurações."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_color_override("font_color", Color("#ffb0a6"))
	content.add_child(warning)
	var immediate := _cloud_action_button("Excluir agora com código", false, true)
	immediate.pressed.connect(func():
		popup.hide()
		_show_cloud_text_prompt("Exclusão imediata", "Digite o código de recuperação. Depois haverá uma confirmação final. Esta ação não pode ser desfeita.", "Código de recuperação", func(value: String): _confirm_immediate_cloud_deletion(value))
	)
	content.add_child(immediate)
	var delayed := _cloud_action_button("Não tenho o código — agendar em 7 dias", false, true)
	delayed.pressed.connect(func():
		popup.hide()
		_confirm_delayed_cloud_deletion()
	)
	content.add_child(delayed)
	var back := _cloud_action_button("Cancelar", false)
	back.pressed.connect(func():
		popup.hide()
		_show_cloud_account()
	)
	content.add_child(back)
	_popup_cloud(parts)


func _confirm_immediate_cloud_deletion(recovery_code: String) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Confirmação final"
	dialog.dialog_text = "Excluir permanentemente a Conta de Peregrino e todo o save online? Esta ação não pode ser desfeita."
	dialog.get_ok_button().text = "EXCLUIR"
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_delete_cloud_account(recovery_code)
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _confirm_delayed_cloud_deletion() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Agendar exclusão"
	dialog.dialog_text = "A exclusão será agendada para daqui a 7 dias. Durante a espera, qualquer sessão ativa poderá cancelá-la em Segurança."
	dialog.get_ok_button().text = "Agendar exclusão"
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_delete_cloud_account("")
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _delete_cloud_account(recovery_code: String) -> void:
	var result: Dictionary = await CloudIdentity.delete_cloud_account(recovery_code)
	if not bool(result.get("ok", false)):
		_show_cloud_error(result)
		return
	if int(result.get("status", 0)) == 204:
		_show_notification("Conta online excluída")
	else:
		_show_notification("Exclusão agendada para daqui a 7 dias")


func _show_cloud_text_prompt(title_text: String, explanation: String, placeholder: String, submitted: Callable) -> void:
	var parts: Dictionary = _create_cloud_popup(title_text)
	var popup: PopupPanel = parts.popup
	var content: VBoxContainer = parts.content
	var label := Label.new()
	label.text = explanation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", TEXT_DIM)
	content.add_child(label)
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.secret = true
	input.custom_minimum_size = Vector2(0, 68)
	content.add_child(input)
	var submit_btn := _cloud_action_button("Continuar", true)
	submit_btn.pressed.connect(func():
		var value: String = input.text.strip_edges()
		if value.is_empty():
			input.grab_focus()
			return
		popup.hide()
		submitted.call(value)
	)
	content.add_child(submit_btn)
	var cancel_btn := _cloud_action_button("Cancelar", false)
	cancel_btn.pressed.connect(popup.hide)
	content.add_child(cancel_btn)
	_popup_cloud(parts)
	input.grab_focus()


func _show_recovery_code_once(recovery_code: String, title_text: String) -> void:
	if recovery_code.is_empty():
		_show_cloud_error({"message": "O servidor não retornou um novo código."})
		return
	var dialog := AcceptDialog.new()
	dialog.title = title_text
	dialog.dialog_text = "Guarde este código fora do aparelho. Ele não ficará salvo no jogo e não será mostrado novamente.\n\n" + recovery_code
	dialog.get_ok_button().text = "Já guardei"
	dialog.add_button("Copiar código", true, "copy")
	dialog.custom_action.connect(func(action: StringName):
		if action == &"copy":
			DisplayServer.clipboard_set(recovery_code)
			_show_notification("Código copiado")
	)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _show_cloud_error(result: Dictionary) -> void:
	var message: String = str(result.get("message", "Não foi possível concluir agora."))
	var request_id: String = str(result.get("requestId", ""))
	if not request_id.is_empty():
		message += "\n\nCódigo de suporte: " + request_id
	var dialog := AcceptDialog.new()
	dialog.title = "Save online"
	dialog.dialog_text = message
	dialog.get_ok_button().text = "Entendi"
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _show_cloud_conflict_dialog(summary: Dictionary) -> void:
	if summary.is_empty() or not CloudSave.has_conflict():
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "Dois progressos encontrados"
	dialog.dialog_text = "Este aparelho e a nuvem avançaram separadamente. Nada será substituído sem sua escolha.\n\nNeste aparelho: " + NumberFormat.format(float(summary.get("localHistoricalFaith", 0.0))) + " Fé histórica, " + str(summary.get("localSaints", 0)) + " Santos e " + str(summary.get("localGems", 0)) + " Gemas.\nNuvem: revisão " + str(summary.get("cloudRevision", 0)) + ".\n\nOs dois candidatos já foram preservados neste aparelho."
	dialog.get_ok_button().text = "Manter este aparelho"
	dialog.get_cancel_button().text = "Decidir depois"
	var cloud_button: Button = dialog.add_button("Usar nuvem", true, "use_cloud")
	cloud_button.disabled = not bool(summary.get("cloudHasPayload", false))
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_confirm_keep_device_conflict()
	)
	dialog.custom_action.connect(func(action: StringName):
		if action == &"use_cloud":
			dialog.queue_free()
			_confirm_use_cloud_conflict()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _confirm_keep_device_conflict() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Sobrescrever save online?"
	dialog.dialog_text = "O progresso deste aparelho será enviado como a próxima revisão. A cópia da nuvem já foi preservada para recuperação curta. Confirmar?"
	dialog.get_ok_button().text = "Manter este aparelho"
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_resolve_keep_device_conflict()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _confirm_use_cloud_conflict() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Usar save da nuvem?"
	dialog.dialog_text = "O estado atual do jogo será substituído pela nuvem. A cópia local já foi preservada fora do backup rotativo. Confirmar?"
	dialog.get_ok_button().text = "Usar nuvem"
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_resolve_use_cloud_conflict()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_fit_dialog_to_screen(dialog)
	dialog.popup_centered()


func _resolve_keep_device_conflict() -> void:
	var result: Dictionary = await CloudSave.resolve_conflict_keep_device()
	if bool(result.get("ok", false)):
		_show_notification("Este aparelho foi sincronizado")
	else:
		_show_cloud_error(result)


func _resolve_use_cloud_conflict() -> void:
	var result: Dictionary = CloudSave.resolve_conflict_use_cloud()
	if bool(result.get("ok", false)):
		_update_all()
		_show_notification("Save da nuvem aplicado")
	else:
		_show_cloud_error(result)

func _confirm_reset_save() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Apagar save"
	dialog.dialog_text = "Isto apaga TODO o progresso (Fé, geradores, Santos, estudos) e fecha o jogo.\n\nAo abrir de novo, você começa do zero.\n\nTem certeza?"
	dialog.get_ok_button().text = "Apagar tudo"
	dialog.get_cancel_button().text = "Cancelar"
	dialog.confirmed.connect(func():
		SaveSystem.set_persistence_enabled(false)
		SaveSystem.delete_save()
		CloudIdentity.clear_local_session()
		CloudSave.clear_local_sync_state(true)
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
		CloudSave.notify_app_paused()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		_pause_time = Time.get_unix_time_from_system()
		SaveSystem.save_game()
		CloudSave.notify_app_paused()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if _pause_time > 0:
			_pending_resume_away += maxf(0.0, Time.get_unix_time_from_system() - _pause_time)
			_last_tick_msec = Time.get_ticks_msec()
			_pause_time = 0.0
			call_deferred("_resume_after_liveops_refresh")


func _resume_after_liveops_refresh() -> void:
	if _resume_refresh_in_progress:
		return
	_resume_refresh_in_progress = true
	while _pending_resume_away > 0.0:
		var away := _pending_resume_away
		_pending_resume_away = 0.0
		# Atualiza campanhas antes de integrar o intervalo pausado. Falha de rede
		# continua segura porque LiveOps preserva o cache/default embutido.
		await LiveOps.bootstrap(2.0)
		if away > 5.0:
			var ganho: float = GameState.apply_offline_production(away)
			if ganho > 0 and away > 60.0:
				_show_offline_modal(ganho)
		_last_tick_msec = Time.get_ticks_msec()
		_update_all()
		SaveSystem.save_game()
		CloudSave.notify_app_resumed()
	_resume_refresh_in_progress = false

class_name StudyPanel
extends VBoxContainer

## Interface modular do Caminho da Palavra.
##
## Toda concessao de recursos e validacao de respostas permanece no StudySystem.
## Este painel somente apresenta o catalogo, envia IDs de acoes e reflete o
## estado persistido, evitando que a camada visual se torne uma segunda economia.

const SECTION_STUDIES := "studies"
const SECTION_BIBLE := "bible"
const SECTION_KNOWLEDGE := "knowledge"

const STATE_LOCKED := "locked"
const STATE_NEW := "new"
const STATE_READ := "read"
const STATE_MASTERED := "mastered"
const OLIVE_TREE_TEXTURE: Texture2D = preload("res://assets/ui/knowledge_olive_tree.png")

var _built := false
var _refreshing := false
var _active_section := SECTION_STUDIES
var _active_study_id := ""
var _selected_option_id := ""
var _summary: Dictionary = {}

var _tab_buttons: Dictionary = {}
var _content_host: Control
var _studies_view: VBoxContainer
var _detail_view: VBoxContainer
var _knowledge_view: VBoxContainer
var _bible_reader: BibleReaderPanel
var _studies_list: VBoxContainer
var _knowledge_tree_canvas: Control
var _knowledge_detail_title: Label
var _knowledge_detail_effect: Label
var _knowledge_detail_state: Label
var _knowledge_detail_action: Button
var _knowledge_build_label: Label
var _knowledge_clear_button: Button
var _selected_knowledge_id := "knowledge_good_seed"

var _progress_label: Label
var _progress_bar: ProgressBar
var _wisdom_label: Label
var _pages_label: Label
var _answer_buttons: Dictionary = {}
var _submit_button: Button
var _quiz_feedback_label: Label


func _ready() -> void:
	_ensure_built()
	_connect_signals()
	refresh()


## Atualiza desbloqueios, resumo, cartoes e a tela atualmente aberta.
func refresh() -> void:
	_ensure_built()
	if _refreshing:
		return
	_refreshing = true
	StudySystem.refresh_unlocks()
	_summary = StudySystem.get_progress_summary()
	_refresh_header()
	_refresh_studies_list()
	_refresh_knowledge_tree()
	if not _active_study_id.is_empty() and _detail_view != null and _detail_view.visible:
		_show_study_detail(_active_study_id)
	_refreshing = false


## Permite que Main ou um link interno abra diretamente uma subaba.
func show_section(section: String) -> void:
	_ensure_built()
	if section not in [SECTION_STUDIES, SECTION_BIBLE, SECTION_KNOWLEDGE]:
		section = SECTION_STUDIES
	_active_section = section
	_active_study_id = ""
	_set_view_visibility()
	_update_section_buttons()
	if section == SECTION_BIBLE:
		_bible_reader.refresh_books()
	elif section == SECTION_KNOWLEDGE:
		_refresh_knowledge_tree()
	else:
		_refresh_studies_list()


## Atalho para links vindos de outras partes do jogo.
func open_study(study_id: String) -> void:
	_ensure_built()
	_active_section = SECTION_STUDIES
	_open_study(study_id)


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)

	add_child(_build_header())
	add_child(_build_section_tabs())

	_content_host = Control.new()
	_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content_host)

	_studies_view = _build_studies_view()
	_studies_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_host.add_child(_studies_view)

	_bible_reader = BibleReaderPanel.new()
	_bible_reader.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_host.add_child(_bible_reader)

	_knowledge_view = _build_knowledge_view()
	_knowledge_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_host.add_child(_knowledge_view)

	_set_view_visibility()
	_update_section_buttons()


func _connect_signals() -> void:
	if not EventBus.study_progress_changed.is_connected(_on_study_progress_changed):
		EventBus.study_progress_changed.connect(_on_study_progress_changed)
	if not EventBus.study_unlocked.is_connected(_on_study_unlocked):
		EventBus.study_unlocked.connect(_on_study_unlocked)
	if not EventBus.wisdom_changed.is_connected(_on_wisdom_changed):
		EventBus.wisdom_changed.connect(_on_wisdom_changed)
	if not EventBus.knowledge_activation_changed.is_connected(_on_knowledge_activation_changed):
		EventBus.knowledge_activation_changed.connect(_on_knowledge_activation_changed)


func _build_header() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 130)
	panel.add_theme_stylebox_override(
		"panel",
		ManaTheme.panel_style(Color(0.06, 0.06, 0.17, 0.95), 26, Color(ManaTheme.GOLD_LIGHT, 0.24), 2, 20, true)
	)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)

	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 1)
	row.add_child(heading)

	var title := Label.new()
	title.text = "Caminho da Palavra"
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 47)
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	heading.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Leia, reflita e avance no seu ritmo."
	subtitle.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT)
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	heading.add_child(subtitle)

	var progress_column := VBoxContainer.new()
	progress_column.custom_minimum_size = Vector2(260, 0)
	progress_column.add_theme_constant_override("separation", 7)
	row.add_child(progress_column)

	_progress_label = Label.new()
	_progress_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_progress_label.add_theme_font_size_override("font_size", 23)
	_progress_label.add_theme_color_override("font_color", ManaTheme.CREAM)
	progress_column.add_child(_progress_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 15)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	progress_column.add_child(_progress_bar)

	_pages_label = Label.new()
	_pages_label.add_theme_font_size_override("font_size", 20)
	_pages_label.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	progress_column.add_child(_pages_label)

	var wisdom_pill := PanelContainer.new()
	wisdom_pill.custom_minimum_size = Vector2(178, 82)
	wisdom_pill.add_theme_stylebox_override(
		"panel",
		ManaTheme.panel_style(ManaTheme.SURFACE_HIGH, 24, Color(ManaTheme.GOLD_LIGHT, 0.35), 2, 16)
	)
	row.add_child(wisdom_pill)

	var wisdom_column := VBoxContainer.new()
	wisdom_column.add_theme_constant_override("separation", -2)
	wisdom_pill.add_child(wisdom_column)
	var wisdom_caption := Label.new()
	wisdom_caption.text = "SABEDORIA"
	wisdom_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wisdom_caption.add_theme_font_override("font", ManaTheme.body_semibold())
	wisdom_caption.add_theme_font_size_override("font_size", 18)
	wisdom_caption.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	wisdom_column.add_child(wisdom_caption)
	_wisdom_label = Label.new()
	_wisdom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wisdom_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_wisdom_label.add_theme_font_size_override("font_size", 41)
	_wisdom_label.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	wisdom_column.add_child(_wisdom_label)

	return panel


func _build_section_tabs() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(ManaTheme.SURFACE_LOW, 20, Color(ManaTheme.GOLD_LIGHT, 0.12), 1, 10)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var definitions := [
		[SECTION_STUDIES, "Estudos"],
		[SECTION_KNOWLEDGE, "Conhecimentos"],
		[SECTION_BIBLE, "Leia a Bíblia"],
	]
	for definition in definitions:
		var button := Button.new()
		button.text = str(definition[1])
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(show_section.bind(str(definition[0])))
		_tab_buttons[definition[0]] = button
		row.add_child(button)
	return panel


func _build_studies_view() -> VBoxContainer:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var intro_row := HBoxContainer.new()
	intro_row.add_theme_constant_override("separation", 10)
	root.add_child(intro_row)
	var intro := Label.new()
	intro.text = "Pergaminhos da Jornada"
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_theme_font_override("font", ManaTheme.serif_bold())
	intro.add_theme_font_size_override("font_size", 37)
	intro.add_theme_color_override("font_color", ManaTheme.CREAM)
	intro_row.add_child(intro)
	var hint := Label.new()
	hint.text = "10 unidades revelam cada estudo"
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	intro_row.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_studies_list = VBoxContainer.new()
	_studies_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_studies_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_studies_list)
	ManaTheme.enable_touch_scroll(scroll, _studies_list)
	return root


func _build_knowledge_view() -> VBoxContainer:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	root.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_copy.add_theme_constant_override("separation", -3)
	heading.add_child(heading_copy)
	var title := Label.new()
	title.text = "Oliveira da Sabedoria"
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	heading_copy.add_child(title)
	var explanation := Label.new()
	explanation.text = "Compre nos permanentes e ative os ramos que deseja usar na sua build."
	explanation.add_theme_font_size_override("font_size", 18)
	explanation.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	heading_copy.add_child(explanation)
	var build_panel := PanelContainer.new()
	build_panel.custom_minimum_size = Vector2(196, 62)
	build_panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#173447"), 16, Color("#79e6e8"), 1, 10, true))
	heading.add_child(build_panel)
	_knowledge_build_label = Label.new()
	_knowledge_build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_knowledge_build_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_knowledge_build_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_knowledge_build_label.add_theme_font_size_override("font_size", 17)
	_knowledge_build_label.add_theme_color_override("font_color", Color("#d9fdff"))
	build_panel.add_child(_knowledge_build_label)
	_knowledge_clear_button = Button.new()
	_knowledge_clear_button.text = "LIMPAR"
	_knowledge_clear_button.custom_minimum_size = Vector2(98, 62)
	_knowledge_clear_button.add_theme_font_size_override("font_size", 14)
	ManaTheme.apply_secondary_light_button(_knowledge_clear_button)
	_knowledge_clear_button.pressed.connect(_clear_knowledge_build)
	heading.add_child(_knowledge_clear_button)

	var detail := PanelContainer.new()
	detail.custom_minimum_size = Vector2(0, 166)
	detail.add_theme_stylebox_override("panel", ManaTheme.panel_style(Color("#18233e"), 18, Color("#d3ad5a"), 1, 16, true))
	root.add_child(detail)
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 14)
	detail.add_child(detail_row)
	var detail_copy := VBoxContainer.new()
	detail_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_copy.add_theme_constant_override("separation", 2)
	detail_row.add_child(detail_copy)
	_knowledge_detail_title = Label.new()
	_knowledge_detail_title.add_theme_font_override("font", ManaTheme.serif_bold())
	_knowledge_detail_title.add_theme_font_size_override("font_size", 30)
	_knowledge_detail_title.add_theme_color_override("font_color", ManaTheme.CREAM)
	detail_copy.add_child(_knowledge_detail_title)
	_knowledge_detail_effect = Label.new()
	_knowledge_detail_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_knowledge_detail_effect.add_theme_font_size_override("font_size", 19)
	_knowledge_detail_effect.add_theme_color_override("font_color", Color("#91e6d0"))
	detail_copy.add_child(_knowledge_detail_effect)
	_knowledge_detail_state = Label.new()
	_knowledge_detail_state.add_theme_font_override("font", ManaTheme.body_semibold())
	_knowledge_detail_state.add_theme_font_size_override("font_size", 16)
	_knowledge_detail_state.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	detail_copy.add_child(_knowledge_detail_state)
	_knowledge_detail_action = Button.new()
	_knowledge_detail_action.custom_minimum_size = Vector2(210, 84)
	_knowledge_detail_action.add_theme_font_size_override("font_size", 18)
	_knowledge_detail_action.pressed.connect(_on_knowledge_action)
	detail_row.add_child(_knowledge_detail_action)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_knowledge_tree_canvas = Control.new()
	_knowledge_tree_canvas.custom_minimum_size = Vector2(880, 1560)
	scroll.add_child(_knowledge_tree_canvas)
	ManaTheme.enable_touch_scroll(scroll, _knowledge_tree_canvas)
	return root


func _refresh_header() -> void:
	var total := int(_summary.get("total", EstudosBiblicos.count()))
	var mastered := int(_summary.get("mastered", 0))
	var pages: Array = _summary.get("pages", [])
	var page_total := _get_page_group_count()
	_progress_label.text = str(mastered) + "/" + str(total) + " estudos dominados"
	_progress_bar.value = float(mastered) / float(max(1, total))
	_pages_label.text = str(pages.size()) + "/" + str(page_total) + " Páginas Iluminadas"
	_wisdom_label.text = str(int(_summary.get("wisdom", GameState.sabedoria)))


func _refresh_studies_list() -> void:
	if _studies_list == null:
		return
	_clear_children(_studies_list)
	var studies: Array = EstudosBiblicos.all()
	for index in range(studies.size()):
		_studies_list.add_child(_build_study_card(studies[index], index + 1))


func _build_study_card(study: Dictionary, number: int) -> PanelContainer:
	var study_id := str(study.get("id", ""))
	var state := StudySystem.get_study_state(study_id)
	var locked := state == STATE_LOCKED
	var accent := _state_color(state)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 138)
	var background := ManaTheme.SURFACE if locked else ManaTheme.PARCHMENT
	var border := Color(1.0, 1.0, 1.0, 0.08) if locked else Color(accent, 0.72)
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(background, 22, border, 2, 20, not locked))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)

	var seal := PanelContainer.new()
	seal.custom_minimum_size = Vector2(82, 82)
	seal.add_theme_stylebox_override(
		"panel",
		ManaTheme.panel_style(Color(accent, 0.18), 41, accent.darkened(0.18), 3, 8)
	)
	row.add_child(seal)
	var seal_label := Label.new()
	seal_label.text = "%02d" % number
	seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seal_label.add_theme_font_override("font", ManaTheme.serif_bold())
	seal_label.add_theme_font_size_override("font_size", 32)
	seal_label.add_theme_color_override("font_color", ManaTheme.DISABLED if locked else ManaTheme.INK)
	seal.add_child(seal_label)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)
	var title := Label.new()
	title.text = str(study.get("title", "Estudo"))
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ManaTheme.DISABLED if locked else ManaTheme.INK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(title)
	var reference := Label.new()
	reference.text = str(study.get("reference", ""))
	reference.add_theme_font_override("font", ManaTheme.body_semibold())
	reference.add_theme_font_size_override("font_size", 23)
	reference.add_theme_color_override("font_color", ManaTheme.DISABLED if locked else ManaTheme.GOLD_DARK)
	info.add_child(reference)
	var state_hint := Label.new()
	state_hint.text = _locked_hint(study) if locked else _state_description(state)
	state_hint.add_theme_font_size_override("font_size", 20)
	state_hint.add_theme_color_override("font_color", ManaTheme.DISABLED if locked else ManaTheme.INK_MUTED)
	info.add_child(state_hint)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(194, 0)
	actions.add_theme_constant_override("separation", 8)
	row.add_child(actions)
	var badge := Label.new()
	badge.text = _state_label(state)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_override("font", ManaTheme.body_semibold())
	badge.add_theme_font_size_override("font_size", 19)
	badge.add_theme_color_override("font_color", ManaTheme.INK if not locked else ManaTheme.CREAM_MUTED)
	badge.add_theme_stylebox_override("normal", ManaTheme.panel_style(Color(accent, 0.22), 14, Color(accent, 0.48), 1, 7))
	actions.add_child(badge)

	var open_button := Button.new()
	open_button.text = "Bloqueado" if locked else ("Revisitar" if state == STATE_MASTERED else "Abrir estudo")
	open_button.disabled = locked
	open_button.custom_minimum_size = Vector2(0, 58)
	open_button.add_theme_font_size_override("font_size", 23)
	open_button.pressed.connect(_open_study.bind(study_id))
	if not locked:
		ManaTheme.apply_secondary_light_button(open_button)
	actions.add_child(open_button)
	return panel


func _open_study(study_id: String) -> void:
	if StudySystem.get_study_state(study_id) == STATE_LOCKED:
		return
	_active_section = SECTION_STUDIES
	_active_study_id = study_id
	_selected_option_id = ""
	_show_study_detail(study_id)
	_set_view_visibility()
	_update_section_buttons()


func _show_study_detail(study_id: String) -> void:
	var study: Dictionary = EstudosBiblicos.get_data(study_id)
	if study.is_empty():
		return
	if _detail_view != null and is_instance_valid(_detail_view):
		_content_host.remove_child(_detail_view)
		_detail_view.queue_free()
	_detail_view = _build_study_detail(study)
	_detail_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_host.add_child(_detail_view)
	_set_view_visibility()


func _build_study_detail(study: Dictionary) -> VBoxContainer:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	root.add_child(top)
	var back := Button.new()
	back.text = "‹ Voltar"
	back.custom_minimum_size = Vector2(164, 62)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(_back_to_studies)
	top.add_child(back)
	var title := Label.new()
	title.text = str(study.get("title", "Estudo"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 41)
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	top.add_child(title)
	var status := Label.new()
	var state := StudySystem.get_study_state(str(study.get("id", "")))
	status.text = _state_label(state)
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_theme_font_override("font", ManaTheme.body_semibold())
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_color", _state_color(state))
	top.add_child(status)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	ManaTheme.enable_touch_scroll(scroll, content)

	content.add_child(_build_passage_card(study))
	content.add_child(_build_text_card("Contexto", str(study.get("context", "")), false))
	content.add_child(_build_text_card("Para refletir", str(study.get("reflection", "")), true))

	var study_id := str(study.get("id", ""))
	var has_read := state in [STATE_READ, STATE_MASTERED]
	if not has_read:
		var complete := Button.new()
		complete.text = "Concluir leitura e receber Fé"
		complete.custom_minimum_size = Vector2(0, 72)
		complete.add_theme_font_size_override("font_size", 28)
		complete.pressed.connect(_complete_reading.bind(study_id))
		ManaTheme.apply_primary_button(complete)
		content.add_child(complete)
	else:
		content.add_child(_build_completed_banner("Leitura concluída", "O quiz está liberado para esta passagem."))

	content.add_child(_build_quiz_card(study, has_read, state == STATE_MASTERED))

	var full_chapter := Button.new()
	full_chapter.text = "Ler capítulo completo na Bíblia"
	full_chapter.custom_minimum_size = Vector2(0, 66)
	full_chapter.add_theme_font_size_override("font_size", 25)
	full_chapter.pressed.connect(_open_full_chapter.bind(study))
	content.add_child(full_chapter)
	return root


func _build_passage_card(study: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(ManaTheme.PARCHMENT, 24, ManaTheme.PARCHMENT_BORDER, 2, 24, true)
	)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	var reference := Label.new()
	reference.text = str(study.get("reference", "Passagem bíblica"))
	reference.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reference.add_theme_font_override("font", ManaTheme.serif_bold())
	reference.add_theme_font_size_override("font_size", 37)
	reference.add_theme_color_override("font_color", ManaTheme.INK)
	column.add_child(reference)

	var passage_data: Dictionary = study.get("passage", {})
	var passage := BibleTextProvider.get_passage(
		str(passage_data.get("book", "")),
		int(passage_data.get("chapter", 1)),
		int(passage_data.get("verse_from", 1)),
		int(passage_data.get("verse_to", passage_data.get("verse_from", 1)))
	)
	var text := RichTextLabel.new()
	text.fit_content = true
	text.scroll_active = false
	text.selection_enabled = true
	text.add_theme_font_override("normal_font", ManaTheme.SERIF_FONT)
	text.add_theme_font_size_override("normal_font_size", 26)
	text.add_theme_color_override("default_color", ManaTheme.INK)
	text.add_theme_constant_override("line_separation", 8)
	var verses: Array = passage.get("verses", [])
	if verses.is_empty():
		text.text = "O texto desta passagem não está disponível no arquivo local."
	else:
		for index in range(verses.size()):
			var verse: Dictionary = verses[index]
			text.push_color(ManaTheme.GOLD_DARK)
			text.push_font(ManaTheme.body_semibold())
			text.push_font_size(18)
			text.add_text(str(int(verse.get("number", index + 1))) + "  ")
			text.pop()
			text.pop()
			text.pop()
			text.push_font(ManaTheme.SERIF_FONT)
			text.push_font_size(26)
			text.add_text(str(verse.get("text", "")))
			text.pop()
			text.pop()
			if index < verses.size() - 1:
				text.add_text("\n\n")
	column.add_child(text)

	var attribution := BibleTextProvider.get_attribution()
	var attribution_label := Label.new()
	attribution_label.text = _short_attribution(attribution)
	attribution_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attribution_label.add_theme_font_size_override("font_size", 18)
	attribution_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	column.add_child(attribution_label)
	return card


func _build_text_card(title_text: String, body_text: String, reflection: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var bg := Color(0.12, 0.12, 0.27, 0.96) if not reflection else Color(0.17, 0.14, 0.24, 0.96)
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(bg, 20, Color(ManaTheme.GOLD_LIGHT, 0.16), 1, 20))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	card.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	column.add_child(title)
	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT if reflection else ManaTheme.SERIF_FONT)
	body.add_theme_font_size_override("font_size", 26)
	body.add_theme_color_override("font_color", ManaTheme.CREAM)
	column.add_child(body)
	return card


func _build_completed_banner(title_text: String, body_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 64)
	panel.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(Color(ManaTheme.GREEN, 0.18), 16, Color(ManaTheme.GREEN, 0.66), 2, 12)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var mark := Label.new()
	mark.text = "✓"
	mark.custom_minimum_size = Vector2(34, 0)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_override("font", ManaTheme.serif_bold())
	mark.add_theme_font_size_override("font_size", 30)
	mark.add_theme_color_override("font_color", ManaTheme.GREEN.lightened(0.24))
	row.add_child(mark)
	var label := Label.new()
	label.text = title_text + "  ·  " + body_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", ManaTheme.CREAM)
	row.add_child(label)
	return panel


func _build_quiz_card(study: Dictionary, reading_complete: bool, mastered: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(ManaTheme.SURFACE_HIGH, 22, Color(ManaTheme.GOLD_LIGHT, 0.24), 2, 20)
	)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 11)
	card.add_child(column)
	var heading := Label.new()
	heading.text = "Pergunta de compreensão"
	heading.add_theme_font_override("font", ManaTheme.serif_bold())
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	column.add_child(heading)

	if not reading_complete:
		var locked := Label.new()
		locked.text = "Conclua a leitura para liberar o quiz."
		locked.add_theme_font_size_override("font_size", 24)
		locked.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
		column.add_child(locked)
		return card

	var question: Dictionary = study.get("question", {})
	var prompt := Label.new()
	prompt.text = str(question.get("prompt", ""))
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_font_override("font", ManaTheme.SERIF_FONT)
	prompt.add_theme_font_size_override("font_size", 28)
	prompt.add_theme_color_override("font_color", ManaTheme.CREAM)
	column.add_child(prompt)

	_answer_buttons.clear()
	var options: Array = question.get("options", [])
	for option_variant in options:
		var option: Dictionary = option_variant
		var option_id := str(option.get("id", ""))
		var button := Button.new()
		button.text = str(option.get("text", ""))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 78)
		button.add_theme_font_size_override("font_size", 23)
		button.disabled = mastered
		_apply_quiz_option_style(button, false)
		button.pressed.connect(_select_answer.bind(option_id))
		_answer_buttons[option_id] = button
		column.add_child(button)

	_quiz_feedback_label = Label.new()
	_quiz_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quiz_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quiz_feedback_label.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT)
	_quiz_feedback_label.add_theme_font_size_override("font_size", 23)
	_quiz_feedback_label.visible = mastered
	if mastered:
		_quiz_feedback_label.text = "Resposta dominada. " + str(question.get("explanation", ""))
		_quiz_feedback_label.add_theme_color_override("font_color", ManaTheme.GREEN.lightened(0.24))
	column.add_child(_quiz_feedback_label)

	_submit_button = Button.new()
	_submit_button.text = "Responder"
	_submit_button.custom_minimum_size = Vector2(0, 66)
	_submit_button.add_theme_font_size_override("font_size", 26)
	_submit_button.disabled = mastered or _selected_option_id.is_empty()
	_submit_button.visible = not mastered
	_submit_button.pressed.connect(_submit_answer.bind(str(question.get("id", ""))))
	ManaTheme.apply_primary_button(_submit_button)
	column.add_child(_submit_button)
	_update_answer_styles()
	return card


func _select_answer(option_id: String) -> void:
	_selected_option_id = option_id
	_update_answer_styles()
	if _submit_button != null:
		_submit_button.disabled = false
	if _quiz_feedback_label != null:
		_quiz_feedback_label.visible = false


func _update_answer_styles() -> void:
	for option_id in _answer_buttons:
		var button: Button = _answer_buttons[option_id]
		_apply_quiz_option_style(button, option_id == _selected_option_id)


func _apply_quiz_option_style(button: Button, selected: bool) -> void:
	if selected:
		button.add_theme_color_override("font_color", Color("#f7fff8"))
		button.add_theme_color_override("font_hover_color", Color("#ffffff"))
		button.add_theme_stylebox_override("normal", ManaTheme.button_style(Color("#24766f"), Color("#c7fff5"), 16, 3, 20, 14))
		button.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#2e8b82"), Color.WHITE, 16, 3, 20, 14))
		button.add_theme_stylebox_override("pressed", ManaTheme.button_style(Color("#1c625c"), Color("#d8fff8"), 16, 3, 20, 14))
		return
	button.add_theme_color_override("font_color", ManaTheme.CREAM)
	button.add_theme_color_override("font_hover_color", Color("#fff4d4"))
	button.add_theme_stylebox_override("normal", ManaTheme.button_style(Color("#242d4b"), Color("#526885"), 16, 2, 20, 14))
	button.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#304267"), Color("#8acfd1"), 16, 2, 20, 14))
	button.add_theme_stylebox_override("pressed", ManaTheme.button_style(Color("#1b243d"), Color("#d8fff8"), 16, 2, 20, 14))


func _complete_reading(study_id: String) -> void:
	var result: Dictionary = StudySystem.complete_reading(study_id)
	if not bool(result.get("ok", false)):
		EventBus.toast_requested.emit("Não foi possível concluir esta leitura agora.")
		return
	_selected_option_id = ""
	_summary = StudySystem.get_progress_summary()
	_refresh_header()
	_show_study_detail(study_id)


func _submit_answer(question_id: String) -> void:
	if _selected_option_id.is_empty():
		return
	var result: Dictionary = StudySystem.submit_answer(question_id, _selected_option_id)
	if not bool(result.get("ok", false)):
		EventBus.toast_requested.emit("Conclua a leitura antes de responder.")
		return
	var correct := bool(result.get("correct", false))
	if correct:
		_selected_option_id = ""
		_summary = StudySystem.get_progress_summary()
		_refresh_header()
		_show_study_detail(_active_study_id)
	else:
		_quiz_feedback_label.text = "Ainda não. " + str(result.get("explanation", "Releia a passagem e tente novamente."))
		_quiz_feedback_label.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
		_quiz_feedback_label.visible = true


func _open_full_chapter(study: Dictionary) -> void:
	var passage: Dictionary = study.get("passage", {})
	var book := str(passage.get("book", ""))
	var chapter := int(passage.get("chapter", 1))
	var verse_from := int(passage.get("verse_from", 0))
	var verse_to := int(passage.get("verse_to", verse_from))
	StudySystem.set_last_passage(book, chapter, verse_from)
	_active_section = SECTION_BIBLE
	_active_study_id = ""
	_bible_reader.open_passage(book, chapter, verse_from, verse_to)
	_set_view_visibility()
	_update_section_buttons()


func _back_to_studies() -> void:
	_active_study_id = ""
	_selected_option_id = ""
	_set_view_visibility()


func _refresh_knowledge_tree() -> void:
	if _knowledge_tree_canvas == null:
		return
	_clear_children(_knowledge_tree_canvas)
	var background := TextureRect.new()
	background.texture = OLIVE_TREE_TEXTURE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.modulate = Color(1.0, 1.0, 1.0, 0.94)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_knowledge_tree_canvas.add_child(background)

	var knowledge_data := Conhecimentos.all()
	for knowledge_variant in knowledge_data:
		var knowledge: Dictionary = knowledge_variant
		for required_id in Conhecimentos.get_requires(knowledge):
			_add_knowledge_link(str(required_id), str(knowledge.get("id", "")))
		for required_id in Conhecimentos.get_requires_any(knowledge):
			_add_knowledge_link(str(required_id), str(knowledge.get("id", "")))
	for knowledge_variant in knowledge_data:
		var knowledge: Dictionary = knowledge_variant
		_knowledge_tree_canvas.add_child(_build_knowledge_node(knowledge))
	_refresh_knowledge_detail()

func _add_knowledge_link(parent_id: String, child_id: String) -> void:
	var parent := Conhecimentos.get_data(parent_id)
	var child := Conhecimentos.get_data(child_id)
	if parent.is_empty() or child.is_empty():
		return
	var link := Line2D.new()
	link.add_point(_knowledge_position(parent))
	link.add_point(_knowledge_position(child))
	var linked_active := parent_id in GameState.conhecimentos_ativos and child_id in GameState.conhecimentos_ativos
	var linked_owned := parent_id in GameState.conhecimentos_comprados and child_id in GameState.conhecimentos_comprados
	link.width = 6.0 if linked_active else 3.0
	link.default_color = Color("#ffe08a") if linked_active else (Color("#82b5ac") if linked_owned else Color(1.0, 1.0, 1.0, 0.16))
	link.z_index = 1
	_knowledge_tree_canvas.add_child(link)

func _knowledge_position(knowledge: Dictionary) -> Vector2:
	var value: Variant = knowledge.get("position", [440, 780])
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2(440, 780)

func _build_knowledge_node(knowledge: Dictionary) -> Button:
	var knowledge_id := str(knowledge.get("id", ""))
	var owned := knowledge_id in GameState.conhecimentos_comprados
	var active := knowledge_id in GameState.conhecimentos_ativos
	var category := str(knowledge.get("category", "roots"))
	var accent := Conhecimentos.category_color(category)
	var node := Button.new()
	node.custom_minimum_size = Vector2(76, 76)
	node.size = Vector2(76, 76)
	node.position = _knowledge_position(knowledge) - Vector2(38, 38)
	node.tooltip_text = str(knowledge.get("name", "Conhecimento")) + "\n" + str(knowledge.get("effect_text", ""))
	node.add_theme_stylebox_override("normal", ManaTheme.button_style(Color(accent, 0.88) if active else Color(accent, 0.12), Color("#fff9e7") if active else Color(accent, 0.60), 38, 3 if active else 2, 6, 4))
	node.add_theme_stylebox_override("hover", ManaTheme.button_style(Color(accent, 0.35), Color("#fff0bd"), 38, 3, 6, 4))
	node.add_theme_stylebox_override("pressed", ManaTheme.button_style(Color(accent, 0.45), Color.WHITE, 38, 3, 6, 4))
	if not owned:
		node.modulate = Color(0.70, 0.70, 0.76, 0.82)
	if knowledge_id == _selected_knowledge_id:
		node.add_theme_stylebox_override("normal", ManaTheme.button_style(Color(accent, 0.96) if active else Color(accent, 0.36), Color.WHITE if active else Color("#fff0bd"), 38, 4, 6, 4))
	var icon := TextureRect.new()
	icon.texture = GameArt.knowledge_icon(category)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 12
	icon.offset_top = 12
	icon.offset_right = -12
	icon.offset_bottom = -12
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(icon)
	var cost := Label.new()
	cost.text = str(int(knowledge.get("cost", 0)))
	cost.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	cost.offset_left = -23
	cost.offset_right = -1
	cost.offset_top = 2
	cost.offset_bottom = 24
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost.add_theme_font_override("font", ManaTheme.body_semibold())
	cost.add_theme_font_size_override("font_size", 12)
	cost.add_theme_color_override("font_color", ManaTheme.INK)
	cost.add_theme_stylebox_override("normal", ManaTheme.panel_style(ManaTheme.GOLD_LIGHT, 9, ManaTheme.GOLD, 1, 2, true))
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(cost)
	node.pressed.connect(_select_knowledge.bind(knowledge_id))
	node.z_index = 2
	return node

func _select_knowledge(knowledge_id: String) -> void:
	_selected_knowledge_id = knowledge_id
	_refresh_knowledge_tree()

func _refresh_knowledge_detail() -> void:
	var knowledge := Conhecimentos.get_data(_selected_knowledge_id)
	if knowledge.is_empty():
		var all := Conhecimentos.all()
		if all.is_empty():
			return
		knowledge = all[0]
		_selected_knowledge_id = str(knowledge.get("id", ""))
	var knowledge_id := str(knowledge.get("id", ""))
	var owned := knowledge_id in GameState.conhecimentos_comprados
	var active := knowledge_id in GameState.conhecimentos_ativos
	var purchased_prerequisites := _knowledge_requirements_met(knowledge, GameState.conhecimentos_comprados)
	var active_prerequisites := _knowledge_requirements_met(knowledge, GameState.conhecimentos_ativos)
	_knowledge_build_label.text = "BUILD  " + str(GameState.conhecimentos_ativos.size()) + " ATIVOS"
	_knowledge_clear_button.disabled = GameState.conhecimentos_ativos.is_empty()
	_knowledge_detail_title.text = str(knowledge.get("name", "Conhecimento"))
	_knowledge_detail_effect.text = str(knowledge.get("effect_text", ""))
	if active:
		_knowledge_detail_state.text = "ATIVO  ·  efeito aplicado"
		_knowledge_detail_action.text = "DESATIVAR"
		_knowledge_detail_action.disabled = false
		ManaTheme.apply_secondary_light_button(_knowledge_detail_action)
	elif owned:
		_knowledge_detail_state.text = "ADQUIRIDO  ·  " + _knowledge_requirement_text(knowledge, true)
		_knowledge_detail_action.text = "ATIVAR"
		_knowledge_detail_action.disabled = not active_prerequisites
		ManaTheme.apply_primary_button(_knowledge_detail_action)
	else:
		_knowledge_detail_state.text = _knowledge_requirement_text(knowledge, false)
		_knowledge_detail_action.text = "ADQUIRIR  ·  " + str(int(knowledge.get("cost", 0))) + " SAB"
		_knowledge_detail_action.disabled = not purchased_prerequisites or GameState.sabedoria < int(knowledge.get("cost", 0))
		ManaTheme.apply_primary_button(_knowledge_detail_action)

func _knowledge_requirements_met(knowledge: Dictionary, source: Array) -> bool:
	for required_id in Conhecimentos.get_requires(knowledge):
		if str(required_id) not in source:
			return false
	var requires_any := Conhecimentos.get_requires_any(knowledge)
	if not requires_any.is_empty():
		for required_id in requires_any:
			if str(required_id) in source:
				return true
		return false
	return true

func _knowledge_requirement_text(knowledge: Dictionary, use_active: bool) -> String:
	var source := GameState.conhecimentos_ativos if use_active else GameState.conhecimentos_comprados
	if _knowledge_requirements_met(knowledge, source):
		return "PRONTO PARA " + ("ATIVAR" if use_active else "ADQUIRIR")
	var labels: Array[String] = []
	for required_id in Conhecimentos.get_requires(knowledge):
		labels.append(str(Conhecimentos.get_data(str(required_id)).get("name", "ramo anterior")))
	var requires_any := Conhecimentos.get_requires_any(knowledge)
	if not requires_any.is_empty():
		labels.append("uma especializacao da copa")
	return "REQUER  " + ", ".join(labels)

func _on_knowledge_action() -> void:
	var knowledge := Conhecimentos.get_data(_selected_knowledge_id)
	if knowledge.is_empty():
		return
	var owned := _selected_knowledge_id in GameState.conhecimentos_comprados
	var result := StudySystem.set_knowledge_active(_selected_knowledge_id, not (_selected_knowledge_id in GameState.conhecimentos_ativos)) if owned else StudySystem.buy_knowledge(_selected_knowledge_id)
	if not bool(result.get("ok", false)):
		match str(result.get("reason", "")):
			"insufficient": EventBus.toast_requested.emit("Sabedoria insuficiente para este conhecimento.")
			"prerequisite": EventBus.toast_requested.emit("Adquira primeiro o ramo anterior da oliveira.")
			"inactive_prerequisite": EventBus.toast_requested.emit("Ative primeiro o ramo anterior desta build.")
			_: EventBus.toast_requested.emit("Este conhecimento nao pode ser alterado agora.")
		return
	_summary = StudySystem.get_progress_summary()
	_refresh_header()
	_refresh_knowledge_tree()

func _clear_knowledge_build() -> void:
	if StudySystem.clear_active_knowledge():
		EventBus.toast_requested.emit("Build da oliveira limpa.")
	_summary = StudySystem.get_progress_summary()
	_refresh_header()
	_refresh_knowledge_tree()


func _set_view_visibility() -> void:
	if _studies_view == null:
		return
	var showing_detail := _active_section == SECTION_STUDIES and not _active_study_id.is_empty()
	_studies_view.visible = _active_section == SECTION_STUDIES and not showing_detail
	if _detail_view != null:
		_detail_view.visible = showing_detail
	_bible_reader.visible = _active_section == SECTION_BIBLE
	_knowledge_view.visible = _active_section == SECTION_KNOWLEDGE


func _update_section_buttons() -> void:
	for section in _tab_buttons:
		var button: Button = _tab_buttons[section]
		if section == _active_section:
			button.add_theme_color_override("font_color", ManaTheme.INK)
			button.add_theme_color_override("font_hover_color", ManaTheme.INK)
			button.add_theme_stylebox_override(
				"normal", ManaTheme.button_style(ManaTheme.GOLD, ManaTheme.GOLD_LIGHT, 16, 2, 18, 10)
			)
		else:
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_hover_color")
			button.remove_theme_stylebox_override("normal")


func _on_study_progress_changed(_study_id: String = "") -> void:
	refresh()


func _on_study_unlocked(_study_id: String = "") -> void:
	refresh()


func _on_wisdom_changed(_amount: int = 0) -> void:
	refresh()

func _on_knowledge_activation_changed(_knowledge_id: String = "") -> void:
	refresh()


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _state_label(state: String) -> String:
	match state:
		STATE_NEW: return "NOVO"
		STATE_READ: return "LIDO"
		STATE_MASTERED: return "DOMINADO"
		_: return "BLOQUEADO"


func _state_description(state: String) -> String:
	match state:
		STATE_NEW: return "Passagem disponível para leitura"
		STATE_READ: return "Leitura concluída · quiz pendente"
		STATE_MASTERED: return "Leitura e quiz concluídos"
		_: return "Continue sua jornada para revelar"


func _state_color(state: String) -> Color:
	match state:
		STATE_NEW: return ManaTheme.GOLD_LIGHT
		STATE_READ: return Color("#78a7d8")
		STATE_MASTERED: return ManaTheme.GREEN
		_: return ManaTheme.DISABLED


func _locked_hint(study: Dictionary) -> String:
	var quantity := int(study.get("required_quantity", 10))
	var generator_id := int(study.get("generator_id", 0))
	var generator := Geradores.get_data(generator_id)
	var generator_name := str(generator.get("nome", "gerador relacionado"))
	return "Alcance " + str(quantity) + " unidades de " + generator_name


func _short_attribution(data: Dictionary) -> String:
	if data.is_empty():
		return "Texto bíblico offline"
	var translation := str(data.get("translation", "Bíblia Livre"))
	var abbreviation := str(data.get("abbreviation", ""))
	var license_name := str(data.get("license", ""))
	var text := translation
	if not abbreviation.is_empty():
		text += " (" + abbreviation + ")"
	if not license_name.is_empty():
		text += " · " + license_name
	return text


func _get_page_group_count() -> int:
	var groups: Dictionary = {}
	for study_variant in EstudosBiblicos.all():
		var study: Dictionary = study_variant
		var group_id := str(study.get("era_group", ""))
		if not group_id.is_empty():
			groups[group_id] = true
	return max(1, groups.size())

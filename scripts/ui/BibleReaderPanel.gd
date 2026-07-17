class_name BibleReaderPanel
extends VBoxContainer

## Leitor biblico offline, pensado para a aba Estudo.
##
## O painel não conhece a economia nem o estado das lições. Ele apenas consulta o
## BibleTextProvider e mantém a navegação entre livro e capítulo, o que permite
## reutilizá-lo em planos de leitura e em futuras telas de busca.

const MIN_FONT_SIZE := 22
const MAX_FONT_SIZE := 38
const DEFAULT_FONT_SIZE := 28

var _built := false
var _books: Array = []
var _font_size := DEFAULT_FONT_SIZE
var _selected_book_code := ""
var _selected_chapter := 1
var _focus_from := 0
var _focus_to := 0

var _book_selector: OptionButton
var _chapter_selector: OptionButton
var _reference_label: Label
var _reading_text: RichTextLabel
var _attribution_label: Label
var _font_value_label: Label
var _read_chapter_button: Button
var _bookmark_button: Button
var _reading_stats_label: Label
var _navigation_panel: PanelContainer
var _reading_page: PanelContainer
var _theme_ornament: TextureRect


func _ready() -> void:
	_ensure_built()
	EventBus.cosmetic_changed.connect(_apply_cosmetic_theme)
	_apply_cosmetic_theme()
	refresh_books()


## Recarrega o índice de livros, preservando a seleção atual quando possível.
func refresh_books() -> void:
	_ensure_built()
	var previous_code := _selected_book_code
	var previous_chapter := _selected_chapter
	if previous_code.is_empty():
		var saved_location_value: Variant = GameState.estudo_progresso.get("ultimaPassagem", {})
		if saved_location_value is Dictionary:
			var saved_location: Dictionary = saved_location_value
			previous_code = str(saved_location.get("book", ""))
			previous_chapter = max(1, int(saved_location.get("chapter", 1)))
	_books = BibleTextProvider.get_books()
	_book_selector.clear()

	for book_variant in _books:
		var book: Dictionary = book_variant
		var code := str(book.get("code", ""))
		var name := str(book.get("name", code))
		_book_selector.add_item(name)
		_book_selector.set_item_metadata(_book_selector.item_count - 1, code)

	if _books.is_empty():
		_selected_book_code = ""
		_chapter_selector.clear()
		_show_empty("A biblioteca bíblica ainda não foi importada.")
		return

	var selected_index := _find_book_index(previous_code)
	if selected_index < 0:
		selected_index = 0
	_book_selector.select(selected_index)
	_select_book_at(selected_index, false)
	_select_chapter(previous_chapter)


## Abre um capítulo vindo de uma lição. Os versículos da lição ficam destacados.
func open_passage(book_code: String, chapter: int, verse_from: int = 0, verse_to: int = 0) -> void:
	_ensure_built()
	if _books.is_empty():
		refresh_books()

	_focus_from = max(0, verse_from)
	_focus_to = max(_focus_from, verse_to)
	var index := _find_book_index(book_code)
	if index >= 0:
		_book_selector.select(index)
		_select_book_at(index, false)
		_select_chapter(chapter)
	else:
		_selected_book_code = book_code
		_selected_chapter = max(1, chapter)
		_load_selected_chapter()


func get_selected_location() -> Dictionary:
	return {
		"code": _selected_book_code,
		"chapter": _selected_chapter,
		"verse_from": _focus_from,
		"verse_to": _focus_to,
	}


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)

	var intro := VBoxContainer.new()
	intro.add_theme_constant_override("separation", 2)
	add_child(intro)

	var title := Label.new()
	title.text = "Bíblia para leitura"
	title.add_theme_font_override("font", ManaTheme.serif_bold())
	title.add_theme_font_size_override("font_size", 43)
	title.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	intro.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Escolha um livro e continue sua leitura enquanto a jornada avanca."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT)
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	intro.add_child(subtitle)

	add_child(_build_navigation())
	add_child(_build_reading_page())


func _build_navigation() -> PanelContainer:
	var panel := PanelContainer.new()
	_navigation_panel = panel
	panel.add_theme_stylebox_override(
		"panel",
		ManaTheme.panel_style(ManaTheme.SURFACE, 20, Color(ManaTheme.GOLD_LIGHT, 0.18), 1, 16)
	)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	_book_selector = OptionButton.new()
	_book_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book_selector.custom_minimum_size = Vector2(0, 64)
	_book_selector.tooltip_text = "Selecionar livro"
	_book_selector.add_theme_font_override("font", ManaTheme.body_semibold())
	_book_selector.add_theme_font_size_override("font_size", 26)
	_book_selector.item_selected.connect(_on_book_selected)
	row.add_child(_book_selector)

	_chapter_selector = OptionButton.new()
	_chapter_selector.custom_minimum_size = Vector2(174, 64)
	_chapter_selector.tooltip_text = "Selecionar capítulo"
	_chapter_selector.add_theme_font_override("font", ManaTheme.body_semibold())
	_chapter_selector.add_theme_font_size_override("font_size", 26)
	_chapter_selector.item_selected.connect(_on_chapter_selected)
	row.add_child(_chapter_selector)

	var decrease := Button.new()
	decrease.text = "A-"
	decrease.tooltip_text = "Diminuir o texto"
	decrease.custom_minimum_size = Vector2(72, 64)
	decrease.add_theme_font_size_override("font_size", 24)
	decrease.pressed.connect(func(): _change_font_size(-2))
	row.add_child(decrease)

	_font_value_label = Label.new()
	_font_value_label.custom_minimum_size = Vector2(54, 0)
	_font_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_font_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_font_value_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_font_value_label.add_theme_font_size_override("font_size", 22)
	_font_value_label.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	row.add_child(_font_value_label)

	var increase := Button.new()
	increase.text = "A+"
	increase.tooltip_text = "Aumentar o texto"
	increase.custom_minimum_size = Vector2(72, 64)
	increase.add_theme_font_size_override("font_size", 24)
	increase.pressed.connect(func(): _change_font_size(2))
	row.add_child(increase)

	_update_font_size_label()
	return panel


func _build_reading_page() -> PanelContainer:
	var page := PanelContainer.new()
	_reading_page = page
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override(
		"panel",
		ManaTheme.panel_style(ManaTheme.PARCHMENT, 24, ManaTheme.PARCHMENT_BORDER, 2, 24, true)
	)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	page.add_child(column)

	_theme_ornament = TextureRect.new()
	_theme_ornament.texture = GameArt.cosmetic_preview("tema_leitor_pergaminho")
	_theme_ornament.custom_minimum_size = Vector2(0, 92)
	_theme_ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_theme_ornament.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_theme_ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_theme_ornament.visible = false
	column.add_child(_theme_ornament)

	_reference_label = Label.new()
	_reference_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_reference_label.add_theme_font_size_override("font_size", 40)
	_reference_label.add_theme_color_override("font_color", ManaTheme.INK)
	_reference_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_reference_label)

	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 10)
	column.add_child(divider)

	_reading_text = RichTextLabel.new()
	_reading_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reading_text.custom_minimum_size = Vector2(0, 390)
	_reading_text.fit_content = false
	_reading_text.scroll_active = true
	_reading_text.scroll_following = false
	_reading_text.selection_enabled = true
	_reading_text.context_menu_enabled = true
	_reading_text.add_theme_font_override("normal_font", ManaTheme.SERIF_FONT)
	_reading_text.add_theme_font_override("bold_font", ManaTheme.serif_bold())
	_reading_text.add_theme_font_size_override("normal_font_size", _font_size)
	_reading_text.add_theme_color_override("default_color", ManaTheme.INK)
	_reading_text.add_theme_constant_override("line_separation", 10)
	column.add_child(_reading_text)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)

	_read_chapter_button = Button.new()
	_read_chapter_button.text = "Marcar capítulo como lido"
	_read_chapter_button.custom_minimum_size = Vector2(0, 62)
	_read_chapter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_read_chapter_button.add_theme_font_size_override("font_size", 23)
	_read_chapter_button.pressed.connect(_mark_selected_chapter_read)
	ManaTheme.apply_secondary_light_button(_read_chapter_button)
	actions.add_child(_read_chapter_button)

	_bookmark_button = Button.new()
	_bookmark_button.text = "Favoritar capítulo"
	_bookmark_button.custom_minimum_size = Vector2(0, 62)
	_bookmark_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bookmark_button.add_theme_font_size_override("font_size", 23)
	_bookmark_button.pressed.connect(_toggle_selected_bookmark)
	ManaTheme.apply_secondary_light_button(_bookmark_button)
	actions.add_child(_bookmark_button)

	_reading_stats_label = Label.new()
	_reading_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reading_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reading_stats_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_reading_stats_label.add_theme_font_size_override("font_size", 19)
	_reading_stats_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	actions.add_child(_reading_stats_label)

	_attribution_label = Label.new()
	_attribution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_attribution_label.add_theme_font_override("font", ManaTheme.BODY_FONT)
	_attribution_label.add_theme_font_size_override("font_size", 19)
	_attribution_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	_attribution_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_attribution_label)

	return page

func _apply_cosmetic_theme() -> void:
	if _navigation_panel == null or _reading_page == null:
		return
	var parchment_active := Cosmeticos.is_active("tema_leitor_pergaminho")
	if parchment_active:
		_navigation_panel.add_theme_stylebox_override(
			"panel",
			ManaTheme.panel_style(Color("#3d2a20"), 16, Color("#a9742d"), 2, 16, true)
		)
		_reading_page.add_theme_stylebox_override(
			"panel",
			ManaTheme.panel_style(Color("#ead4a6"), 14, Color("#8a5928"), 4, 26, true)
		)
		_reference_label.add_theme_color_override("font_color", Color("#5b321b"))
		_reading_text.add_theme_color_override("default_color", Color("#382417"))
		_attribution_label.add_theme_color_override("font_color", Color("#6b4b32"))
	else:
		_navigation_panel.add_theme_stylebox_override(
			"panel",
			ManaTheme.panel_style(ManaTheme.SURFACE, 20, Color(ManaTheme.GOLD_LIGHT, 0.18), 1, 16)
		)
		_reading_page.add_theme_stylebox_override(
			"panel",
			ManaTheme.panel_style(ManaTheme.PARCHMENT, 24, ManaTheme.PARCHMENT_BORDER, 2, 24, true)
		)
		_reference_label.add_theme_color_override("font_color", ManaTheme.INK)
		_reading_text.add_theme_color_override("default_color", ManaTheme.INK)
		_attribution_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	if _theme_ornament != null:
		_theme_ornament.visible = parchment_active
	if not _selected_book_code.is_empty():
		_load_selected_chapter()


func _on_book_selected(index: int) -> void:
	_focus_from = 0
	_focus_to = 0
	_select_book_at(index, true)


func _select_book_at(index: int, load_chapter: bool) -> void:
	if index < 0 or index >= _books.size():
		return
	var book: Dictionary = _books[index]
	_selected_book_code = str(book.get("code", ""))
	_chapter_selector.clear()
	var chapter_count: int = maxi(1, int(book.get("chapters", 1)))
	for number in range(1, chapter_count + 1):
		_chapter_selector.add_item("Cap. " + str(number))
		_chapter_selector.set_item_metadata(number - 1, number)
	_selected_chapter = 1
	_chapter_selector.select(0)
	if load_chapter:
		_load_selected_chapter()


func _on_chapter_selected(index: int) -> void:
	_focus_from = 0
	_focus_to = 0
	if index >= 0 and index < _chapter_selector.item_count:
		_selected_chapter = int(_chapter_selector.get_item_metadata(index))
	_load_selected_chapter()


func _select_chapter(chapter: int) -> void:
	var safe_chapter := clampi(chapter, 1, max(1, _chapter_selector.item_count))
	_selected_chapter = safe_chapter
	if _chapter_selector.item_count > 0:
		_chapter_selector.select(safe_chapter - 1)
	_load_selected_chapter()


func _load_selected_chapter() -> void:
	if _selected_book_code.is_empty():
		_show_empty("Selecione um livro para começar.")
		return

	var chapter: Dictionary = BibleTextProvider.get_chapter(_selected_book_code, _selected_chapter)
	if chapter.is_empty():
		_show_empty("Este capítulo não está disponível no arquivo local.")
		return

	var book_name := _get_selected_book_name()
	_reference_label.text = book_name + " " + str(_selected_chapter)
	_reading_text.clear()

	var verses: Array = chapter.get("verses", [])
	for verse_index in range(verses.size()):
		var verse: Dictionary = verses[verse_index]
		var number := int(verse.get("number", verse_index + 1))
		var highlighted := _focus_from > 0 and number >= _focus_from and number <= _focus_to
		if highlighted:
			_reading_text.push_bgcolor(Color(ManaTheme.GOLD_LIGHT, 0.22))
		_reading_text.push_color(ManaTheme.GOLD_DARK)
		_reading_text.push_font(ManaTheme.body_semibold())
		_reading_text.push_font_size(max(MIN_FONT_SIZE - 4, _font_size - 7))
		_reading_text.add_text(str(number) + "  ")
		_reading_text.pop()
		_reading_text.pop()
		_reading_text.pop()
		_reading_text.push_color(ManaTheme.INK)
		_reading_text.push_font(ManaTheme.SERIF_FONT)
		_reading_text.push_font_size(_font_size)
		_reading_text.add_text(str(verse.get("text", "")))
		_reading_text.pop()
		_reading_text.pop()
		_reading_text.pop()
		if highlighted:
			_reading_text.pop()
		if verse_index < verses.size() - 1:
			_reading_text.add_text("\n\n")

	_reading_text.scroll_to_line(0)
	_attribution_label.text = _format_attribution(BibleTextProvider.get_attribution())
	StudySystem.set_last_passage(_selected_book_code, _selected_chapter, max(1, _focus_from))
	_update_chapter_actions()


func _show_empty(message: String) -> void:
	_reference_label.text = "Biblioteca bíblica"
	_reading_text.clear()
	_reading_text.add_text(message)
	_attribution_label.text = _format_attribution(BibleTextProvider.get_attribution())
	_update_chapter_actions()


func _mark_selected_chapter_read() -> void:
	if _selected_book_code.is_empty():
		return
	var result: Dictionary = StudySystem.mark_chapter_read(_selected_book_code, _selected_chapter)
	if not bool(result.get("ok", false)):
		EventBus.toast_requested.emit("Não foi possível registrar este capítulo.")
	_update_chapter_actions()


func _toggle_selected_bookmark() -> void:
	if _selected_book_code.is_empty():
		return
	StudySystem.toggle_bookmark(_chapter_bookmark_id())
	_update_chapter_actions()


func _update_chapter_actions() -> void:
	if _read_chapter_button == null:
		return
	var has_location := not _selected_book_code.is_empty()
	var is_read := has_location and StudySystem.is_chapter_read(_selected_book_code, _selected_chapter)
	var is_bookmarked := has_location and _chapter_bookmark_id() in _get_bookmarks()
	_read_chapter_button.disabled = not has_location or is_read
	_read_chapter_button.text = "✓ Capítulo lido" if is_read else "Marcar capítulo como lido"
	_bookmark_button.disabled = not has_location
	_bookmark_button.text = "★ Capítulo favorito" if is_bookmarked else "☆ Favoritar capítulo"
	_reading_stats_label.text = str(StudySystem.get_read_chapter_count()) + " lidos"


func _chapter_bookmark_id() -> String:
	return _selected_book_code.to_upper() + ":" + str(_selected_chapter)


func _get_bookmarks() -> Array:
	var progress: Dictionary = GameState.estudo_progresso
	var value: Variant = progress.get("marcadores", [])
	return value if value is Array else []


func _change_font_size(delta: int) -> void:
	_font_size = clampi(_font_size + delta, MIN_FONT_SIZE, MAX_FONT_SIZE)
	_reading_text.add_theme_font_size_override("normal_font_size", _font_size)
	_update_font_size_label()
	_load_selected_chapter()


func _update_font_size_label() -> void:
	if _font_value_label != null:
		_font_value_label.text = str(_font_size)


func _find_book_index(code: String) -> int:
	if code.is_empty():
		return -1
	for index in range(_books.size()):
		var book: Dictionary = _books[index]
		if str(book.get("code", "")).to_upper() == code.to_upper():
			return index
	return -1


func _get_selected_book_name() -> String:
	var index := _find_book_index(_selected_book_code)
	if index >= 0:
		return str((_books[index] as Dictionary).get("name", _selected_book_code))
	return _selected_book_code


func _format_attribution(data: Dictionary) -> String:
	if data.is_empty():
		return "Texto bíblico disponível offline."
	var translation := str(data.get("translation", "Bíblia Livre"))
	var abbreviation := str(data.get("abbreviation", ""))
	var license_name := str(data.get("license", ""))
	var result := translation
	if not abbreviation.is_empty():
		result += " (" + abbreviation + ")"
	if not license_name.is_empty():
		result += "  -  " + license_name
	return result

class_name BibleTextProvider
extends RefCounted

## Leitor dos dados offline da Bíblia Livre (BLIVRE).
##
## Os livros são carregados sob demanda e mantidos em cache. A API devolve
## cópias dos dados para impedir que uma tela altere o cache compartilhado.

const MANIFEST_PATH := "res://assets/bible/manifest.json"
const BIBLE_ROOT := "res://assets/bible/"

static var _manifest_cache: Dictionary = {}
static var _book_cache: Dictionary = {}


static func get_manifest() -> Dictionary:
	if _manifest_cache.is_empty():
		var value := _read_json_dictionary(MANIFEST_PATH)
		if value.is_empty():
			return {}
		_manifest_cache = value
	return _manifest_cache.duplicate(true)


static func get_books() -> Array:
	var manifest := get_manifest()
	var books_value: Variant = manifest.get("books", [])
	if books_value is not Array:
		return []
	return (books_value as Array).duplicate(true)


static func get_book(code: String) -> Dictionary:
	var book := _get_book_cached(code)
	if book.is_empty():
		return {}
	return book.duplicate(true)


static func _get_book_cached(code: String) -> Dictionary:
	var normalized_code := code.strip_edges().to_upper()
	if normalized_code.is_empty():
		return {}

	if _book_cache.has(normalized_code):
		return _book_cache[normalized_code] as Dictionary

	var book_summary := _find_book_summary(normalized_code)
	if book_summary.is_empty():
		push_warning("Livro bíblico desconhecido: %s" % code)
		return {}

	var relative_path := str(book_summary.get("file", ""))
	if relative_path.is_empty() or relative_path.contains(".."):
		push_error("Caminho inválido no manifesto bíblico para %s." % normalized_code)
		return {}

	var book := _read_json_dictionary(BIBLE_ROOT + relative_path)
	if book.is_empty():
		return {}

	_book_cache[normalized_code] = book
	return book


static func get_chapter(code: String, chapter: int) -> Dictionary:
	if chapter < 1:
		return {}

	var book := _get_book_cached(code)
	var chapters_value: Variant = book.get("chapters", [])
	if chapters_value is not Array:
		return {}

	for chapter_value: Variant in chapters_value:
		if chapter_value is Dictionary and int(chapter_value.get("number", 0)) == chapter:
			return (chapter_value as Dictionary).duplicate(true)
	return {}


static func get_passage(
	code: String,
	chapter: int,
	verse_from: int,
	verse_to: int
) -> Dictionary:
	if verse_from < 1:
		return {}
	if verse_to < verse_from:
		verse_to = verse_from

	var chapter_data := get_chapter(code, chapter)
	if chapter_data.is_empty():
		return {}

	var selected_verses: Array = []
	var text_parts: PackedStringArray = []
	var verses_value: Variant = chapter_data.get("verses", [])
	if verses_value is not Array:
		return {}

	for verse_value: Variant in verses_value:
		if verse_value is not Dictionary:
			continue
		var verse := verse_value as Dictionary
		var verse_number := int(verse.get("number", 0))
		if verse_number < verse_from or verse_number > verse_to:
			continue
		selected_verses.append(verse.duplicate(true))
		text_parts.append("%d %s" % [verse_number, str(verse.get("text", ""))])

	if selected_verses.is_empty():
		return {}

	var book_summary := _find_book_summary(code.strip_edges().to_upper())
	var book_name := str(book_summary.get("name", code.to_upper()))
	var actual_from := int((selected_verses[0] as Dictionary).get("number", verse_from))
	var actual_to := int((selected_verses[-1] as Dictionary).get("number", verse_to))
	var verse_reference := str(actual_from)
	if actual_to != actual_from:
		verse_reference += "–%d" % actual_to

	return {
		"book": book_name,
		"code": str(book_summary.get("code", code.to_upper())),
		"chapter": chapter,
		"verse_from": actual_from,
		"verse_to": actual_to,
		"reference": "%s %d:%s" % [book_name, chapter, verse_reference],
		"verses": selected_verses,
		"text": "\n".join(text_parts),
	}


static func get_attribution() -> Dictionary:
	var manifest := get_manifest()
	var attribution_value: Variant = manifest.get("attribution", {})
	if attribution_value is not Dictionary:
		return {}
	return (attribution_value as Dictionary).duplicate(true)


static func _find_book_summary(code: String) -> Dictionary:
	for book_value: Variant in get_books():
		if book_value is Dictionary and str(book_value.get("code", "")) == code:
			return (book_value as Dictionary).duplicate(true)
	return {}


static func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Arquivo bíblico não encontrado: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir o arquivo bíblico: %s" % path)
		return {}

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		push_error(
			"JSON bíblico inválido em %s (linha %d): %s"
			% [path, json.get_error_line(), json.get_error_message()]
		)
		return {}

	var value: Variant = json.data
	if value is not Dictionary:
		push_error("A raiz do arquivo bíblico deve ser um objeto: %s" % path)
		return {}
	return value as Dictionary

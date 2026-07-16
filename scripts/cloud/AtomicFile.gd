class_name CloudAtomicFile
extends RefCounted

## Escrita crash-safe para os pequenos arquivos privados do cloud save.
## O arquivo anterior permanece em `.bak`; um `.tmp` valido tambem pode ser
## recuperado se o processo for encerrado entre a gravacao e a promocao.


static func ensure_parent(path: String) -> bool:
	var directory_path: String = path.get_base_dir()
	if directory_path.is_empty() or DirAccess.dir_exists_absolute(directory_path):
		return true
	return DirAccess.make_dir_recursive_absolute(directory_path) == OK


static func write_text(path: String, contents: String, keep_backup: bool = true) -> bool:
	if path.is_empty() or not ensure_parent(path):
		return false
	var temporary_path: String = path + ".tmp"
	var backup_path: String = path + ".bak"
	if FileAccess.file_exists(temporary_path):
		DirAccess.remove_absolute(temporary_path)

	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return false

	# Verifica os bytes antes de tocar na versao confirmada.
	if read_text(temporary_path) != contents:
		return false

	if FileAccess.file_exists(path):
		if keep_backup:
			if FileAccess.file_exists(backup_path):
				var remove_backup_error: Error = DirAccess.remove_absolute(backup_path)
				if remove_backup_error != OK:
					return false
			var backup_error: Error = DirAccess.copy_absolute(path, backup_path)
			if backup_error != OK:
				return false
		var remove_target_error: Error = DirAccess.remove_absolute(path)
		if remove_target_error != OK:
			return false

	var promote_error: Error = DirAccess.rename_absolute(temporary_path, path)
	if promote_error != OK:
		# A copia confirmada nunca e apagada de forma irrecuperavel.
		if keep_backup and FileAccess.file_exists(backup_path) and not FileAccess.file_exists(path):
			DirAccess.copy_absolute(backup_path, path)
		return false
	return read_text(path) == contents


static func write_json(path: String, data: Dictionary, keep_backup: bool = true) -> bool:
	return write_text(path, JSON.stringify(data), keep_backup)


static func read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var contents: String = file.get_as_text()
	file.close()
	return contents


static func parse_dictionary(contents: String) -> Dictionary:
	if contents.is_empty():
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(contents) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	return (parser.data as Dictionary).duplicate(true)


static func read_json_with_fallback(path: String) -> Dictionary:
	for candidate_path: String in [path, path + ".tmp", path + ".bak"]:
		var parsed: Dictionary = parse_dictionary(read_text(candidate_path))
		if not parsed.is_empty():
			return parsed
	return {}


static func remove_family(path: String) -> bool:
	var success: bool = true
	for candidate_path: String in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(candidate_path):
			success = DirAccess.remove_absolute(candidate_path) == OK and success
	return success

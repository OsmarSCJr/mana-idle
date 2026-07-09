extends Node

const SAVE_PATH: String = "user://save.json"
const SAVE_TMP: String = "user://save.json.tmp"
const SAVE_BAK: String = "user://save.json.bak"
const AUTOSAVE_INTERVAL: float = 10.0

var _autosave_timer: Timer
var _last_save_time: float = 0.0

func _ready() -> void:
	_setup_autosave()

func _setup_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.timeout.connect(_on_autosave)
	add_child(_autosave_timer)
	_autosave_timer.start()

func _on_autosave() -> void:
	save_game()

func _read_save_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_string: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data

func load_game() -> bool:
	var data: Dictionary = _read_save_dict(SAVE_PATH)
	if data.is_empty():
		# Save principal corrompido/ausente: tenta o backup.
		data = _read_save_dict(SAVE_BAK)
	if data.is_empty():
		return false

	_last_save_time = float(data.get("lastSeen", Time.get_unix_time_from_system()))
	GameState.load_save_data(data)

	var now: float = Time.get_unix_time_from_system()
	var offline_seconds: float = now - _last_save_time
	# Anti-cheat leve: relogio adiantado no passado -> ignora ganho offline.
	if offline_seconds > 60.0:
		var ganho: float = GameState.apply_offline_production(offline_seconds)
		if ganho > 0:
			EventBus.toast_requested.emit("Bem-vindo de volta! Seus profetas coletaram " + NumberFormat.format(ganho) + " de Fe enquanto voce estava fora.")
	EventBus.ui_needs_update.emit()
	return true

func save_game() -> void:
	var data: Dictionary = GameState.get_save_data()
	var file: FileAccess = FileAccess.open(SAVE_TMP, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()

	# Escrita atomica: grava no .tmp, rotaciona o atual para .bak e promove o .tmp.
	var dir: DirAccess = DirAccess.open("user://")
	if dir != null:
		if dir.file_exists("save.json"):
			dir.copy(SAVE_PATH, SAVE_BAK)
		dir.rename(SAVE_TMP, SAVE_PATH)
	_last_save_time = Time.get_unix_time_from_system()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	for path in [SAVE_PATH, SAVE_TMP, SAVE_BAK]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

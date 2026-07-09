extends Node

const SAVE_PATH: String = "user://save.json"
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

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var json_string: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: int = json.parse(json_string)
	if error != OK:
		return false
	var data: Dictionary = json.data
	_last_save_time = float(data.get("lastSeen", Time.get_unix_time_from_system()))
	GameState.load_save_data(data)
	var now: float = Time.get_unix_time_from_system()
	var offline_seconds: float = now - _last_save_time
	if offline_seconds > 60.0:
		var ganho: float = GameState.apply_offline_production(offline_seconds)
		if ganho > 0:
			EventBus.notification.emit("Bem-vindo de volta! Seus profetas coletaram " + NumberFormat.format(ganho) + " de Fe enquanto voce estava fora.")
	EventBus.ui_needs_update.emit()
	return true

func save_game() -> void:
	var data: Dictionary = GameState.get_save_data()
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var json_string: String = JSON.stringify(data, "  ")
	file.store_string(json_string)
	file.close()
	_last_save_time = Time.get_unix_time_from_system()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

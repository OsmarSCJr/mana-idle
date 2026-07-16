extends Node

const AtomicFile = preload("res://scripts/cloud/AtomicFile.gd")
const SaveValidator = preload("res://scripts/cloud/SaveValidator.gd")

const SAVE_PATH: String = "user://save.json"
const SAVE_TMP: String = "user://save.json.tmp"
const SAVE_BAK: String = "user://save.json.bak"
const AUTOSAVE_INTERVAL: float = 10.0

var _autosave_timer: Timer
var _last_save_time: float = 0.0
var _bootstrap_in_progress: bool = false
var persistence_enabled: bool = not OS.get_cmdline_user_args().has("--smoke-test")
# Ganho offline calculado no load; Main consome e mostra o modal de coleta.
var pending_offline_gain: float = 0.0


func _ready() -> void:
	_setup_autosave()


func set_persistence_enabled(enabled: bool) -> void:
	persistence_enabled = enabled
	if _autosave_timer != null:
		_autosave_timer.paused = not enabled or _bootstrap_in_progress


func begin_bootstrap() -> void:
	_bootstrap_in_progress = true
	if _autosave_timer != null:
		_autosave_timer.paused = true
	var study_system: Node = get_node_or_null("/root/StudySystem")
	if study_system != null and study_system.has_method("set_mutations_suspended"):
		study_system.call("set_mutations_suspended", true)


func end_bootstrap() -> void:
	_bootstrap_in_progress = false
	if _autosave_timer != null:
		_autosave_timer.paused = not persistence_enabled
	var study_system: Node = get_node_or_null("/root/StudySystem")
	if study_system != null and study_system.has_method("set_mutations_suspended"):
		study_system.call("set_mutations_suspended", false)


func is_bootstrapping() -> bool:
	return _bootstrap_in_progress


func _setup_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.timeout.connect(_on_autosave)
	add_child(_autosave_timer)
	_autosave_timer.start()


func _on_autosave() -> void:
	if persistence_enabled and not _bootstrap_in_progress:
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
	if json.parse(json_string) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = (json.data as Dictionary).duplicate(true)
	var validation: Dictionary = SaveValidator.validate_save_data(data, false)
	return data if bool(validation.get("ok", false)) else {}


func read_local_candidate() -> Dictionary:
	var best_data: Dictionary = {}
	var best_path: String = ""
	var best_last_seen: float = -1.0
	# Um .tmp valido pode ser o commit mais recente interrompido antes do rename.
	for path: String in [SAVE_PATH, SAVE_TMP, SAVE_BAK]:
		var data: Dictionary = _read_save_dict(path)
		if data.is_empty():
			continue
		var last_seen: float = float(data.get("lastSeen", 0.0))
		if best_data.is_empty() or last_seen > best_last_seen:
			best_data = data
			best_path = path
			best_last_seen = last_seen
	if best_data.is_empty():
		return {"hasData": false, "data": {}, "path": "", "payloadJson": "", "sha256": ""}
	var payload_json: String = SaveValidator.compact_json(best_data)
	return {
		"hasData": true,
		"data": best_data,
		"path": best_path,
		"payloadJson": payload_json,
		"sha256": SaveValidator.sha256_text(payload_json),
	}


func read_saved_compact_payload() -> Dictionary:
	var candidate: Dictionary = read_local_candidate()
	if not bool(candidate.get("hasData", false)):
		return {"ok": false, "payloadJson": "", "sha256": "", "data": {}}
	return {
		"ok": true,
		"payloadJson": str(candidate.get("payloadJson", "")),
		"sha256": str(candidate.get("sha256", "")),
		"data": (candidate.get("data", {}) as Dictionary).duplicate(true),
	}


func load_game() -> bool:
	if not persistence_enabled:
		return false
	var candidate: Dictionary = read_local_candidate()
	if not bool(candidate.get("hasData", false)):
		return false
	return apply_candidate(candidate.get("data", {}) as Dictionary)


func apply_candidate(data: Dictionary, offline_seconds_override: float = -1.0) -> bool:
	var validation: Dictionary = SaveValidator.validate_save_data(data, false)
	if not bool(validation.get("ok", false)):
		return false
	pending_offline_gain = 0.0
	_last_save_time = float(data.get("lastSeen", Time.get_unix_time_from_system()))
	GameState.load_save_data(data)
	var study_system: Node = get_node_or_null("/root/StudySystem")
	if study_system != null:
		study_system.call("refresh_unlocks", false)

	var offline_seconds: float = offline_seconds_override
	if offline_seconds < 0.0:
		offline_seconds = Time.get_unix_time_from_system() - _last_save_time
	# Relogio no passado ou intervalos pequenos nao geram credito.
	if offline_seconds > 60.0:
		var gain: float = GameState.apply_offline_production(offline_seconds)
		if gain > 0.0:
			pending_offline_gain = gain
	EventBus.ui_needs_update.emit()
	return true


func apply_cloud_payload(payload_json: String, expected_sha256: String, server_updated_at: float, server_now: float) -> Dictionary:
	var parsed: Dictionary = SaveValidator.parse_payload(payload_json, expected_sha256, true)
	if not bool(parsed.get("ok", false)):
		return parsed
	# Persiste e rele o candidato antes de alterar o estado em memoria.
	if not AtomicFile.write_text(SAVE_PATH, payload_json, true):
		return {"ok": false, "code": "LOCAL_WRITE_FAILED", "message": "Nao foi possivel gravar o save recebido."}
	var persisted_text: String = AtomicFile.read_text(SAVE_PATH)
	var persisted: Dictionary = SaveValidator.parse_payload(persisted_text, expected_sha256, true)
	if not bool(persisted.get("ok", false)):
		return {"ok": false, "code": "LOCAL_VERIFY_FAILED", "message": "O save recebido nao passou pela verificacao local."}

	var trusted_offline_seconds: float = -1.0
	if server_updated_at > 0.0 and server_now >= server_updated_at:
		trusted_offline_seconds = server_now - server_updated_at
	if not apply_candidate(persisted.get("data", {}) as Dictionary, trusted_offline_seconds):
		return {"ok": false, "code": "LOCAL_APPLY_FAILED", "message": "Nao foi possivel aplicar o save recebido."}
	# Persiste o ganho offline final sem emitir dirty antes de CloudSave atualizar
	# sua revisao. CloudSave compara o novo hash e agenda o proximo upload.
	if not save_game(false):
		return {"ok": false, "code": "LOCAL_FINAL_WRITE_FAILED", "message": "Nao foi possivel confirmar o save recebido."}
	var current: Dictionary = read_saved_compact_payload()
	return {
		"ok": true,
		"currentSha256": str(current.get("sha256", "")),
		"payloadSha256": str(parsed.get("sha256", "")),
		"offlineGain": pending_offline_gain,
	}


func save_game(notify_cloud: bool = true) -> bool:
	if not persistence_enabled:
		return false
	var data: Dictionary = GameState.get_save_data()
	var validation: Dictionary = SaveValidator.validate_save_data(data, true)
	if not bool(validation.get("ok", false)):
		push_error("Save local rejeitado: " + str(validation.get("code", "INVALID_SAVE")))
		return false
	var canonical: Dictionary = SaveValidator.canonicalize(data) as Dictionary
	var pretty_json: String = JSON.stringify(canonical, "  ")
	if not AtomicFile.write_text(SAVE_PATH, pretty_json, true):
		push_error("Falha ao gravar save local de forma atomica.")
		return false
	var persisted: Dictionary = _read_save_dict(SAVE_PATH)
	if persisted.is_empty():
		push_error("Falha ao reler save local apos a gravacao.")
		return false
	var payload_json: String = SaveValidator.compact_json(persisted)
	var payload_sha256: String = SaveValidator.sha256_text(payload_json)
	if payload_sha256.is_empty():
		return false
	_last_save_time = Time.get_unix_time_from_system()
	if notify_cloud and not _bootstrap_in_progress:
		EventBus.game_state_dirty.emit(payload_sha256)
	return true


func has_save() -> bool:
	return bool(read_local_candidate().get("hasData", false))


func delete_save() -> bool:
	return AtomicFile.remove_family(SAVE_PATH)

extends Node

const AtomicFile = preload("res://scripts/cloud/AtomicFile.gd")
const SaveValidator = preload("res://scripts/cloud/SaveValidator.gd")
const CloudApiScript = preload("res://scripts/cloud/CloudApi.gd")

const META_PATH: String = "user://cloud_sync_meta.json"
const PENDING_DIRECTORY: String = "user://cloud_pending"
const CONFLICT_DIRECTORY: String = "user://cloud_conflicts"
const NORMAL_DEBOUNCE_SECONDS: float = 120.0
const NORMAL_MIN_UPLOAD_INTERVAL_SECONDS: float = 300.0
const RETRY_DELAYS: Array[float] = [5.0, 15.0, 60.0, 300.0, 900.0]

const STATE_DISABLED: String = "disabled"
const STATE_SYNCED: String = "synced"
const STATE_SAVING: String = "saving"
const STATE_PENDING: String = "pending"
const STATE_OFFLINE: String = "offline"
const STATE_CONFLICT: String = "conflict"
const STATE_SESSION_EXPIRED: String = "session_expired"
const STATE_ERROR: String = "error"

var _api: CloudApi
var _meta: Dictionary = {}
var _state: String = STATE_DISABLED
var _state_message: String = "Save somente neste aparelho"
var _operation_in_progress: bool = false
var _next_sync_at: float = INF
var _bootstrap_epoch: int = 0
var _timer: Timer


func _ready() -> void:
	if not SaveSystem.persistence_enabled:
		_meta = _default_meta()
		_state = STATE_DISABLED
		_state_message = "Save somente neste aparelho"
		return
	DirAccess.make_dir_recursive_absolute(PENDING_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(CONFLICT_DIRECTORY)
	_load_meta()
	LiveOps.config_changed.connect(_on_liveops_config_changed)
	_record_liveops_summary(LiveOps.summary())
	_api = CloudApiScript.new()
	add_child(_api)
	EventBus.game_state_dirty.connect(_on_local_save_committed)
	EventBus.cloud_identity_changed.connect(_on_identity_changed)
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_timer)
	add_child(_timer)
	_timer.start()
	if CloudIdentity.is_authenticated():
		_ensure_meta_for_current_account()
		_set_state(STATE_PENDING if bool(_meta.get("dirty", false)) else STATE_SYNCED)


func bootstrap(timeout_seconds: float = 3.0) -> Dictionary:
	if not SaveSystem.persistence_enabled:
		_set_state(STATE_DISABLED)
		return {"ok": true, "loaded": false, "source": "disabled"}
	# Faz a funcao ser sempre aguardavel, mesmo quando nao ha conta.
	await get_tree().process_frame
	SaveSystem.begin_bootstrap()
	_bootstrap_epoch += 1
	var epoch: int = _bootstrap_epoch
	var local: Dictionary = SaveSystem.read_local_candidate()
	_rebuild_dirty_from_candidate(local)

	if not CloudIdentity.is_authenticated():
		var local_loaded: bool = _apply_local_candidate(local)
		SaveSystem.end_bootstrap()
		_set_state(STATE_DISABLED)
		return {"ok": true, "loaded": local_loaded, "source": "local"}

	_operation_in_progress = true
	_set_state(STATE_PENDING, "Consultando save online...")
	var response: Dictionary = await _api.send_json(
		HTTPClient.METHOD_GET,
		"save",
		null,
		CloudIdentity.bearer_headers(),
		timeout_seconds
	)
	_operation_in_progress = false
	if epoch != _bootstrap_epoch:
		var stale_loaded: bool = _apply_local_candidate(local)
		SaveSystem.end_bootstrap()
		return {"ok": false, "loaded": stale_loaded, "source": "local", "code": "STALE_BOOTSTRAP"}

	var status: int = int(response.get("status", 0))
	if status == 200:
		var remote: Dictionary = _dictionary_body(response)
		var result: Dictionary = _select_bootstrap_candidate(local, remote)
		if bool(result.get("ok", false)) and not CloudIdentity.mark_reconciled():
			result["ok"] = false
			result["code"] = "AUTH_WRITE_FAILED"
		SaveSystem.end_bootstrap()
		return result
	if status == 401:
		CloudIdentity.mark_session_expired()
		var expired_loaded: bool = _apply_local_candidate(local)
		SaveSystem.end_bootstrap()
		_set_state(STATE_SESSION_EXPIRED)
		return {"ok": false, "loaded": expired_loaded, "source": "local", "code": "SESSION_EXPIRED"}

	var fallback_loaded: bool = _apply_local_candidate(local)
	SaveSystem.end_bootstrap()
	_set_state(STATE_OFFLINE)
	_schedule_retry()
	return {"ok": false, "loaded": fallback_loaded, "source": "local", "code": str(response.get("networkError", "REMOTE_UNAVAILABLE"))}


func _select_bootstrap_candidate(local: Dictionary, remote: Dictionary) -> Dictionary:
	var remote_validation: Dictionary = _validate_remote_snapshot(remote)
	if not bool(remote_validation.get("ok", false)):
		var invalid_loaded: bool = _apply_local_candidate(local)
		_set_state(STATE_ERROR, str(remote_validation.get("message", "Save online invalido")))
		return {"ok": false, "loaded": invalid_loaded, "source": "local", "code": str(remote_validation.get("code", "INVALID_REMOTE"))}
	if bool(remote_validation.get("obsolete", false)):
		return _prepare_alpha_schema_reset(local, remote)

	var has_local: bool = bool(local.get("hasData", false))
	var has_remote: bool = bool(remote.get("hasPayload", false))
	var local_sha: String = str(local.get("sha256", ""))
	var remote_sha: String = str(remote.get("sha256", ""))
	var remote_revision: int = int(remote.get("revision", 0))
	var local_significant: bool = has_local and SaveValidator.is_significant(local.get("data", {}) as Dictionary)
	var first_recovery: bool = CloudIdentity.needs_initial_reconcile() and CloudIdentity.get_link_mode() == "recovered"

	if has_local and has_remote and local_sha == remote_sha:
		_update_remote_meta(remote, remote_sha)
		_meta["dirty"] = false
		var same_loaded: bool = _apply_local_candidate(local)
		_recheck_dirty_after_apply(remote_sha)
		_save_meta()
		_set_state(STATE_PENDING if bool(_meta.get("dirty", false)) else STATE_SYNCED)
		return {"ok": true, "loaded": same_loaded, "source": "local_same_as_cloud"}

	if first_recovery and local_significant:
		var recovered_loaded: bool = _apply_local_candidate(local)
		if not _store_conflict(str(local.get("payloadJson", "")), remote, "recovery_with_local_progress"):
			return {"ok": false, "loaded": recovered_loaded, "source": "local", "code": "CONFLICT_WRITE_FAILED"}
		return {"ok": true, "loaded": recovered_loaded, "source": "local", "conflict": true}

	if not has_local and has_remote:
		var applied_remote: Dictionary = _apply_remote_snapshot(remote)
		return {"ok": bool(applied_remote.get("ok", false)), "loaded": bool(applied_remote.get("ok", false)), "source": "cloud"}

	if has_local and not has_remote:
		var empty_remote_loaded: bool = _apply_local_candidate(local)
		_update_remote_meta(remote, "")
		_meta["dirty"] = true
		_save_meta()
		_schedule_normal_sync(true)
		_set_state(STATE_PENDING)
		return {"ok": true, "loaded": empty_remote_loaded, "source": "local"}

	if not has_local and not has_remote:
		_update_remote_meta(remote, "")
		_meta["dirty"] = false
		_save_meta()
		_set_state(STATE_SYNCED)
		return {"ok": true, "loaded": false, "source": "new"}

	var known_revision: int = int(_meta.get("cloudRevision", 0))
	var last_synced_sha: String = str(_meta.get("lastSyncedSha256", ""))
	var local_dirty: bool = local_sha != last_synced_sha
	if remote_revision > known_revision and local_dirty:
		var conflict_loaded: bool = _apply_local_candidate(local)
		if not _store_conflict(str(local.get("payloadJson", "")), remote, "remote_advanced_while_local_dirty"):
			return {"ok": false, "loaded": conflict_loaded, "source": "local", "code": "CONFLICT_WRITE_FAILED"}
		return {"ok": true, "loaded": conflict_loaded, "source": "local", "conflict": true}
	if remote_revision > known_revision and not local_dirty:
		var newer_remote: Dictionary = _apply_remote_snapshot(remote)
		return {"ok": bool(newer_remote.get("ok", false)), "loaded": bool(newer_remote.get("ok", false)), "source": "cloud"}
	if remote_revision < known_revision:
		var rollback_loaded: bool = _apply_local_candidate(local)
		if not _store_conflict(str(local.get("payloadJson", "")), remote, "remote_revision_rollback"):
			return {"ok": false, "loaded": rollback_loaded, "source": "local", "code": "CONFLICT_WRITE_FAILED"}
		return {"ok": true, "loaded": rollback_loaded, "source": "local", "conflict": true}

	var local_loaded: bool = _apply_local_candidate(local)
	_update_remote_meta(remote, remote_sha)
	_meta["dirty"] = local_dirty
	_save_meta()
	if local_dirty:
		_schedule_normal_sync(false)
	_set_state(STATE_PENDING if local_dirty else STATE_SYNCED)
	return {"ok": true, "loaded": local_loaded, "source": "local"}


func sync_now() -> Dictionary:
	if not CloudIdentity.is_authenticated():
		return _local_error("NOT_AUTHENTICATED", "Ative ou recupere sua Conta de Peregrino.")
	if has_conflict():
		return _local_error("CONFLICT_PENDING", "Resolva o conflito antes de sincronizar.")
	if not SaveSystem.save_game():
		return _local_error("LOCAL_SAVE_FAILED", "Nao foi possivel salvar neste aparelho.")
	_next_sync_at = 0.0
	return await _upload_pending()


func request_sync(immediate: bool = false) -> void:
	if not CloudIdentity.is_authenticated() or has_conflict():
		return
	if immediate:
		_next_sync_at = 0.0
	else:
		_schedule_normal_sync(false)
	_set_state(STATE_PENDING)


func reconcile_account() -> Dictionary:
	if not CloudIdentity.is_authenticated():
		return _local_error("NOT_AUTHENTICATED", "A conta nao esta ativa.")
	if _operation_in_progress:
		return _local_error("REQUEST_IN_PROGRESS", "Ja existe uma operacao em andamento.")
	SaveSystem.save_game(false)
	var local: Dictionary = SaveSystem.read_local_candidate()
	_operation_in_progress = true
	var response: Dictionary = await _api.send_json(HTTPClient.METHOD_GET, "save", null, CloudIdentity.bearer_headers())
	_operation_in_progress = false
	if int(response.get("status", 0)) != 200:
		return _handle_read_error(response)
	var remote: Dictionary = _dictionary_body(response)
	var validation: Dictionary = _validate_remote_snapshot(remote)
	if not bool(validation.get("ok", false)):
		return validation
	if bool(validation.get("obsolete", false)):
		var schema_reset := _prepare_alpha_schema_reset(local, remote)
		if not bool(schema_reset.get("ok", false)):
			return schema_reset
		if not CloudIdentity.mark_reconciled():
			return _local_error("AUTH_WRITE_FAILED", "Nao foi possivel confirmar a vinculacao neste aparelho.")
		_next_sync_at = 0.0
		return await _upload_pending()
	var has_local: bool = bool(local.get("hasData", false))
	var has_remote: bool = bool(remote.get("hasPayload", false))
	var is_recovery: bool = CloudIdentity.get_link_mode() == "recovered" and CloudIdentity.needs_initial_reconcile()
	if is_recovery and has_local and SaveValidator.is_significant(local.get("data", {}) as Dictionary) and str(local.get("sha256", "")) != str(remote.get("sha256", "")):
		if not _store_conflict(str(local.get("payloadJson", "")), remote, "recovery_with_local_progress"):
			return _local_error("CONFLICT_WRITE_FAILED", "Nao foi possivel preservar os dois progressos com seguranca.")
		if not CloudIdentity.mark_reconciled():
			return _local_error("AUTH_WRITE_FAILED", "Nao foi possivel confirmar a vinculacao neste aparelho.")
		return {"ok": true, "conflict": true}
	if has_remote and (not has_local or not SaveValidator.is_significant(local.get("data", {}) as Dictionary)):
		var applied: Dictionary = _apply_remote_snapshot(remote)
		if not bool(applied.get("ok", false)):
			return applied
		if not CloudIdentity.mark_reconciled():
			return _local_error("AUTH_WRITE_FAILED", "Nao foi possivel confirmar a vinculacao neste aparelho.")
		return applied
	_update_remote_meta(remote, str(remote.get("sha256", "")))
	_meta["dirty"] = has_local and (not has_remote or str(local.get("sha256", "")) != str(remote.get("sha256", "")))
	_save_meta()
	if not CloudIdentity.mark_reconciled():
		return _local_error("AUTH_WRITE_FAILED", "Nao foi possivel confirmar a vinculacao neste aparelho.")
	if bool(_meta.get("dirty", false)):
		_next_sync_at = 0.0
		return await _upload_pending()
	_set_state(STATE_SYNCED)
	return {"ok": true, "synced": true}


func check_remote_updates() -> Dictionary:
	if not CloudIdentity.is_authenticated() or has_conflict():
		return {"ok": true, "skipped": true}
	if _operation_in_progress:
		return _local_error("REQUEST_IN_PROGRESS", "Ja existe uma sincronizacao em andamento.")
	if not SaveSystem.save_game(false):
		return _local_error("LOCAL_SAVE_FAILED", "Nao foi possivel confirmar o progresso local.")
	var known_revision: int = int(_meta.get("cloudRevision", 0))
	var last_synced_sha: String = str(_meta.get("lastSyncedSha256", ""))
	_operation_in_progress = true
	var response: Dictionary = await _api.send_json(HTTPClient.METHOD_GET, "save", null, CloudIdentity.bearer_headers())
	_operation_in_progress = false
	if int(response.get("status", 0)) != 200:
		return _handle_read_error(response)
	var remote: Dictionary = _dictionary_body(response)
	var validation: Dictionary = _validate_remote_snapshot(remote)
	if not bool(validation.get("ok", false)):
		return validation
	if bool(validation.get("obsolete", false)):
		var current_local: Dictionary = SaveSystem.read_local_candidate()
		return _prepare_alpha_schema_reset(current_local, remote)
	# Nenhum dado capturado antes do await pode decidir a matriz. Confirma e rele
	# o estado atual depois da resposta para não apagar uma jogada feita em voo.
	if not SaveSystem.save_game(false):
		return _local_error("LOCAL_SAVE_FAILED", "Nao foi possivel confirmar uma alteracao feita durante a consulta.")
	var local: Dictionary = SaveSystem.read_local_candidate()
	var local_sha: String = str(local.get("sha256", ""))
	var local_dirty: bool = local_sha != last_synced_sha
	var remote_revision: int = int(remote.get("revision", 0))
	var remote_sha: String = str(remote.get("sha256", ""))
	if remote_revision == known_revision and remote_sha != last_synced_sha:
		if not _store_conflict(str(local.get("payloadJson", "")), remote, "same_revision_hash_changed"):
			return _local_error("CONFLICT_WRITE_FAILED", "Nao foi possivel preservar os dois saves.")
		return {"ok": true, "conflict": true}
	if bool(remote.get("hasPayload", false)) and remote_sha == local_sha:
		_update_remote_meta(remote, remote_sha)
		_meta["dirty"] = false
		_save_meta()
		_set_state(STATE_SYNCED)
		return {"ok": true, "unchanged": true}
	if remote_revision > known_revision:
		if local_dirty:
			if not _store_conflict(str(local.get("payloadJson", "")), remote, "resume_remote_advanced"):
				return _local_error("CONFLICT_WRITE_FAILED", "Nao foi possivel preservar os dois saves.")
			return {"ok": true, "conflict": true}
		return _apply_remote_snapshot(remote)
	if remote_revision < known_revision:
		if not _store_conflict(str(local.get("payloadJson", "")), remote, "resume_remote_rollback"):
			return _local_error("CONFLICT_WRITE_FAILED", "Nao foi possivel preservar os dois saves.")
		return {"ok": true, "conflict": true}
	if local_dirty:
		_schedule_normal_sync(false)
		_set_state(STATE_PENDING)
	return {"ok": true, "dirty": local_dirty}


func _upload_pending() -> Dictionary:
	if _operation_in_progress:
		return _local_error("REQUEST_IN_PROGRESS", "Ja existe uma sincronizacao em andamento.")
	if not CloudIdentity.is_authenticated():
		return _local_error("NOT_AUTHENTICATED", "A sessao online nao esta ativa.")
	if has_conflict():
		return _local_error("CONFLICT_PENDING", "Resolva o conflito antes de enviar outro save.")
	if not bool(_meta.get("dirty", false)):
		_set_state(STATE_SYNCED)
		return {"ok": true, "synced": true, "unchanged": true}

	var pending: Dictionary = _load_or_create_pending()
	if not bool(pending.get("ok", false)):
		_set_state(STATE_ERROR, str(pending.get("message", "Falha ao preparar save")))
		return pending
	var envelope_text: String = str(pending.get("envelopeText", ""))
	var in_flight: Dictionary = _meta.get("inFlight", {}) as Dictionary
	var base_revision: int = int(in_flight.get("baseRevision", int(_meta.get("cloudRevision", 0))))
	var headers: PackedStringArray = CloudIdentity.bearer_headers()
	headers.append("If-Match: \"save-%d\"" % base_revision)

	_operation_in_progress = true
	_meta["lastUploadAttemptAt"] = int(Time.get_unix_time_from_system())
	_save_meta()
	_set_state(STATE_SAVING)
	var response: Dictionary = await _api.send_raw(HTTPClient.METHOD_PUT, "save", envelope_text, headers)
	_operation_in_progress = false
	return _handle_upload_response(response, in_flight)


func _load_or_create_pending() -> Dictionary:
	var in_flight: Dictionary = _meta.get("inFlight", {}) as Dictionary
	if not in_flight.is_empty():
		var existing_path: String = str(in_flight.get("payloadFile", ""))
		var existing_text: String = AtomicFile.read_text(existing_path)
		var existing_parser: JSON = JSON.new()
		if not existing_text.is_empty() and existing_parser.parse(existing_text) == OK and typeof(existing_parser.data) == TYPE_DICTIONARY:
			var existing_envelope: Dictionary = existing_parser.data as Dictionary
			if str(existing_envelope.get("mutationId", "")) == str(in_flight.get("mutationId", "")) and str(existing_envelope.get("payloadSha256", "")) == str(in_flight.get("payloadSha256", "")):
				return {"ok": true, "envelopeText": existing_text}
		# Metadado incompleto nao pode gerar retry com bytes diferentes.
		_meta["inFlight"] = {}
		_save_meta()

	var local: Dictionary = SaveSystem.read_saved_compact_payload()
	if not bool(local.get("ok", false)):
		return _local_error("LOCAL_SAVE_MISSING", "Nao ha um save local valido para enviar.")
	var payload_json: String = str(local.get("payloadJson", ""))
	var payload_sha: String = str(local.get("sha256", ""))
	if payload_json.to_utf8_buffer().size() > SaveValidator.MAX_PAYLOAD_BYTES:
		return _local_error("PAYLOAD_TOO_LARGE", "O save local excede 64 KiB.")
	var mutation_id: String = SaveValidator.make_uuid_v4()
	if mutation_id.is_empty():
		return _local_error("RANDOM_FAILED", "Nao foi possivel criar uma operacao segura.")
	var resolution: String = str(_meta.get("pendingResolution", "normal"))
	if resolution not in ["normal", "keep_device"]:
		resolution = "normal"
	var envelope: Dictionary = {
		"mutationId": mutation_id,
		"schemaVersion": GameState.SAVE_VERSION,
		"clientSavedAt": int((local.get("data", {}) as Dictionary).get("lastSeen", Time.get_unix_time_from_system())),
		"resolution": resolution,
		"payloadSha256": payload_sha,
		"payloadJson": payload_json,
	}
	var envelope_text: String = JSON.stringify(envelope)
	var pending_path: String = PENDING_DIRECTORY + "/" + mutation_id + ".json"
	if not AtomicFile.write_text(pending_path, envelope_text, true):
		return _local_error("PENDING_WRITE_FAILED", "Nao foi possivel preparar a fila de sincronizacao.")
	_meta["inFlight"] = {
		"mutationId": mutation_id,
		"baseRevision": int(_meta.get("cloudRevision", 0)),
		"payloadSha256": payload_sha,
		"payloadFile": pending_path,
		"localChangeSeq": int(_meta.get("localChangeSeq", 0)),
		"resolution": resolution,
	}
	if not _save_meta():
		return _local_error("META_WRITE_FAILED", "Nao foi possivel confirmar a fila de sincronizacao.")
	return {"ok": true, "envelopeText": envelope_text}


func _handle_upload_response(response: Dictionary, in_flight: Dictionary) -> Dictionary:
	var status: int = int(response.get("status", 0))
	if status >= 200 and status < 300:
		var body: Dictionary = _dictionary_body(response)
		if str(body.get("mutationId", "")) != str(in_flight.get("mutationId", "")) or str(body.get("sha256", "")) != str(in_flight.get("payloadSha256", "")):
			_set_state(STATE_ERROR, "Resposta de sincronizacao nao confere")
			return _local_error("ACK_MISMATCH", "A confirmacao do servidor nao corresponde ao envio.")
		_meta["cloudRevision"] = int(body.get("revision", 0))
		_meta["etag"] = str(body.get("etag", "\"save-%d\"" % int(body.get("revision", 0))))
		_meta["lastSyncedSha256"] = str(body.get("sha256", ""))
		_meta["lastServerUpdatedAt"] = int(body.get("serverUpdatedAt", 0))
		_meta["lastServerNow"] = int(body.get("serverNow", 0))
		_meta["lastSuccessfulSyncAt"] = int(Time.get_unix_time_from_system())
		_meta["retryIndex"] = 0
		_meta["nextRetryAt"] = 0
		_meta["pendingResolution"] = "normal"
		var confirmed_path: String = str(in_flight.get("payloadFile", ""))
		_meta["inFlight"] = {}
		var current: Dictionary = SaveSystem.read_saved_compact_payload()
		# Um ACK antigo nunca limpa uma alteracao feita durante a requisicao.
		_meta["dirty"] = not bool(current.get("ok", false)) or str(current.get("sha256", "")) != str(body.get("sha256", ""))
		_save_meta()
		if not confirmed_path.is_empty():
			AtomicFile.remove_family(confirmed_path)
		if bool(_meta.get("dirty", false)):
			_schedule_normal_sync(false)
			_set_state(STATE_PENDING)
		else:
			_next_sync_at = INF
			_set_state(STATE_SYNCED)
		var success: Dictionary = body.duplicate(true)
		success["ok"] = true
		return success

	if status == 412:
		var body: Dictionary = _dictionary_body(response)
		var remote_value: Variant = body.get("conflict", {})
		var remote: Dictionary = remote_value as Dictionary if remote_value is Dictionary else {}
		var local_payload: String = _payload_from_in_flight(in_flight)
		if local_payload.is_empty():
			local_payload = str(SaveSystem.read_saved_compact_payload().get("payloadJson", ""))
		if not _store_conflict(local_payload, remote, "compare_and_swap"):
			_set_state(STATE_ERROR, "Nao foi possivel preservar o conflito")
			return _local_error("CONFLICT_WRITE_FAILED", "Nao foi possivel preservar os dois saves.")
		return _local_error("SAVE_CONFLICT", "O save online mudou em outro aparelho.")
	if status == 401:
		CloudIdentity.mark_session_expired()
		_set_state(STATE_SESSION_EXPIRED)
		return _response_error(response)
	if status == 413 or status == 422:
		_meta["automaticSyncPaused"] = true
		_save_meta()
		_set_state(STATE_ERROR, "O save precisa de revisao antes de novo envio")
		return _response_error(response)

	_schedule_retry()
	_set_state(STATE_OFFLINE if status == 0 else STATE_ERROR)
	return _response_error(response)


func _on_local_save_committed(payload_sha256: String) -> void:
	var previous_local_sha: String = str(_meta.get("currentLocalSha256", ""))
	if payload_sha256 != previous_local_sha:
		_meta["localChangeSeq"] = int(_meta.get("localChangeSeq", 0)) + 1
	_meta["currentLocalSha256"] = payload_sha256
	_meta["dirty"] = payload_sha256 != str(_meta.get("lastSyncedSha256", ""))
	_save_meta()
	if CloudIdentity.is_authenticated() and bool(_meta.get("dirty", false)):
		_schedule_normal_sync(false)
		_set_state(STATE_PENDING)


func _on_timer() -> void:
	if not CloudIdentity.is_authenticated() or _operation_in_progress or has_conflict():
		return
	if bool(_meta.get("automaticSyncPaused", false)) or not bool(_meta.get("dirty", false)):
		return
	var now: float = Time.get_unix_time_from_system()
	if now >= _next_sync_at and now >= float(_meta.get("nextRetryAt", 0)):
		call_deferred("_upload_pending")


func _schedule_normal_sync(immediate: bool) -> void:
	var now: float = Time.get_unix_time_from_system()
	if immediate:
		_next_sync_at = now
		return
	var debounce_at: float = now + NORMAL_DEBOUNCE_SECONDS
	var minimum_at: float = float(_meta.get("lastSuccessfulSyncAt", 0)) + NORMAL_MIN_UPLOAD_INTERVAL_SECONDS
	_next_sync_at = maxf(debounce_at, minimum_at)


func _schedule_retry() -> void:
	var retry_index: int = clampi(int(_meta.get("retryIndex", 0)), 0, RETRY_DELAYS.size() - 1)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()
	var jitter: float = random.randf_range(0.85, 1.15)
	var delay: float = RETRY_DELAYS[retry_index] * jitter
	_meta["retryIndex"] = mini(retry_index + 1, RETRY_DELAYS.size() - 1)
	_meta["nextRetryAt"] = int(Time.get_unix_time_from_system() + delay)
	_next_sync_at = float(_meta["nextRetryAt"])
	_save_meta()


func _apply_local_candidate(candidate: Dictionary) -> bool:
	if not bool(candidate.get("hasData", false)):
		return false
	var loaded: bool = SaveSystem.apply_candidate(candidate.get("data", {}) as Dictionary)
	if loaded:
		# O ganho offline e confirmado imediatamente. CloudSave o detecta pelo hash.
		SaveSystem.save_game(false)
		var current: Dictionary = SaveSystem.read_saved_compact_payload()
		if bool(current.get("ok", false)):
			_meta["currentLocalSha256"] = str(current.get("sha256", ""))
			_meta["dirty"] = str(current.get("sha256", "")) != str(_meta.get("lastSyncedSha256", ""))
			_save_meta()
	return loaded


func _apply_remote_snapshot(remote: Dictionary) -> Dictionary:
	if not bool(remote.get("hasPayload", false)):
		return _local_error("REMOTE_EMPTY", "A conta online ainda nao possui save.")
	var applied: Dictionary = SaveSystem.apply_cloud_payload(
		str(remote.get("payloadJson", "")),
		str(remote.get("sha256", "")),
		float(remote.get("serverUpdatedAt", 0)),
		float(remote.get("serverNow", 0))
	)
	if not bool(applied.get("ok", false)):
		_set_state(STATE_ERROR, str(applied.get("message", "Falha ao aplicar save online")))
		return applied
	_update_remote_meta(remote, str(remote.get("sha256", "")))
	var current_sha: String = str(applied.get("currentSha256", ""))
	_meta["currentLocalSha256"] = current_sha
	# Ganho offline/migracao posterior ao snapshot gera um novo estado local.
	_meta["dirty"] = current_sha != str(remote.get("sha256", ""))
	_meta["localChangeSeq"] = int(_meta.get("localChangeSeq", 0)) + (1 if bool(_meta["dirty"]) else 0)
	_save_meta()
	if bool(_meta.get("dirty", false)):
		_schedule_normal_sync(false)
		_set_state(STATE_PENDING)
	else:
		_set_state(STATE_SYNCED)
	return applied


func _validate_remote_snapshot(remote: Dictionary) -> Dictionary:
	var revision: int = int(remote.get("revision", -1))
	if revision < 0:
		return _local_error("INVALID_REMOTE_REVISION", "O servidor retornou uma revisao invalida.")
	if not bool(remote.get("hasPayload", false)):
		return {"ok": true}
	var remote_version: int = int(remote.get("schemaVersion", 0))
	if remote_version < GameState.SAVE_VERSION:
		return {"ok": true, "obsolete": true, "schemaVersion": remote_version}
	if remote_version > GameState.SAVE_VERSION:
		return _local_error("SAVE_VERSION", "O save online requer outra versao do aplicativo.")
	return SaveValidator.parse_payload(str(remote.get("payloadJson", "")), str(remote.get("sha256", "")), true)


func _prepare_alpha_schema_reset(local: Dictionary, remote: Dictionary) -> Dictionary:
	# Durante o alpha, uma mudanca estrutural invalida o progresso anterior de forma
	# intencional. Um save local ja atualizado vence; qualquer formato antigo inicia
	# as tres campanhas do zero e substitui a revisao obsoleta na proxima sincronizacao.
	var local_data: Dictionary = local.get("data", {}) as Dictionary
	var loaded: bool = false
	if bool(local.get("hasData", false)) and int(local_data.get("version", 0)) == GameState.SAVE_VERSION:
		loaded = _apply_local_candidate(local)
	else:
		GameState._reset_alpha_progress()
		loaded = true
	if not SaveSystem.save_game(false):
		return _local_error("LOCAL_SAVE_FAILED", "Nao foi possivel iniciar o novo progresso alpha.")
	var fresh: Dictionary = SaveSystem.read_local_candidate()
	_update_remote_meta(remote, str(remote.get("sha256", "")))
	_meta["currentLocalSha256"] = str(fresh.get("sha256", ""))
	_meta["dirty"] = true
	_meta["localChangeSeq"] = int(_meta.get("localChangeSeq", 0)) + 1
	_save_meta()
	_schedule_normal_sync(false)
	_set_state(STATE_PENDING)
	return {"ok": true, "loaded": loaded, "source": "alpha_schema_reset", "reset": true}


func _store_conflict(local_payload_json: String, remote: Dictionary, reason: String) -> bool:
	var conflict_id: String = SaveValidator.make_uuid_v4()
	var directory: String = CONFLICT_DIRECTORY + "/" + conflict_id
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		_set_state(STATE_ERROR, "Nao foi possivel preservar o conflito")
		return false
	var local_path: String = directory + "/local.json"
	var remote_path: String = directory + "/cloud.json"
	var manifest_path: String = directory + "/manifest.json"
	var remote_payload: String = str(remote.get("payloadJson", "")) if bool(remote.get("hasPayload", false)) else "null"
	if not AtomicFile.write_text(local_path, local_payload_json, false):
		return false
	if not AtomicFile.write_text(remote_path, remote_payload, false):
		return false
	var manifest: Dictionary = {
		"id": conflict_id,
		"reason": reason,
		"createdAt": int(Time.get_unix_time_from_system()),
		"localPath": local_path,
		"cloudPath": remote_path,
		"cloudRevision": int(remote.get("revision", 0)),
		"cloudEtag": str(remote.get("etag", "\"save-%d\"" % int(remote.get("revision", 0)))),
		"cloudSha256": str(remote.get("sha256", "")),
		"cloudHasPayload": bool(remote.get("hasPayload", false)),
		"cloudSchemaVersion": remote.get("schemaVersion", null),
		"serverUpdatedAt": remote.get("serverUpdatedAt", null),
		"serverNow": remote.get("serverNow", Time.get_unix_time_from_system()),
	}
	if not AtomicFile.write_json(manifest_path, manifest, false):
		return false
	_meta["conflict"] = manifest
	_meta["dirty"] = true
	_meta["automaticSyncPaused"] = true
	var in_flight: Dictionary = _meta.get("inFlight", {}) as Dictionary
	if not in_flight.is_empty():
		_meta["conflictPendingFile"] = str(in_flight.get("payloadFile", ""))
	_meta["inFlight"] = {}
	_save_meta()
	_set_state(STATE_CONFLICT)
	var summary: Dictionary = conflict_summary()
	EventBus.cloud_conflict_detected.emit(summary)
	return true


func has_conflict() -> bool:
	return not (_meta.get("conflict", {}) as Dictionary).is_empty()


func conflict_summary() -> Dictionary:
	var conflict: Dictionary = (_meta.get("conflict", {}) as Dictionary).duplicate(true)
	if conflict.is_empty():
		return {}
	var local_text: String = AtomicFile.read_text(str(conflict.get("localPath", "")))
	var local_parser: JSON = JSON.new()
	var local_data: Dictionary = {}
	if local_parser.parse(local_text) == OK and typeof(local_parser.data) == TYPE_DICTIONARY:
		local_data = local_parser.data as Dictionary
	return {
		"id": str(conflict.get("id", "")),
		"reason": str(conflict.get("reason", "")),
		"cloudRevision": int(conflict.get("cloudRevision", 0)),
		"cloudHasPayload": bool(conflict.get("cloudHasPayload", false)),
		"serverUpdatedAt": conflict.get("serverUpdatedAt", null),
		"localFaith": float(local_data.get("fe", 0.0)),
		"localHistoricalFaith": float(local_data.get("feTotalHistorica", 0.0)),
		"localSaints": int(local_data.get("santos", 0)),
		"localGems": int(local_data.get("gemas", 0)),
	}


func resolve_conflict_use_cloud() -> Dictionary:
	if not has_conflict():
		return _local_error("NO_CONFLICT", "Nao ha conflito pendente.")
	var conflict: Dictionary = _meta.get("conflict", {}) as Dictionary
	if not bool(conflict.get("cloudHasPayload", false)):
		return _local_error("REMOTE_EMPTY", "A nuvem esta vazia; mantenha este aparelho para continuar.")
	var remote_payload: String = AtomicFile.read_text(str(conflict.get("cloudPath", "")))
	var remote: Dictionary = {
		"hasPayload": true,
		"revision": int(conflict.get("cloudRevision", 0)),
		"etag": str(conflict.get("cloudEtag", "")),
		"schemaVersion": int(conflict.get("cloudSchemaVersion", GameState.SAVE_VERSION)),
		"payloadJson": remote_payload,
		"sha256": str(conflict.get("cloudSha256", "")),
		"serverUpdatedAt": conflict.get("serverUpdatedAt", 0),
		"serverNow": conflict.get("serverNow", Time.get_unix_time_from_system()),
	}
	var result: Dictionary = _apply_remote_snapshot(remote)
	if bool(result.get("ok", false)):
		_clear_conflict_runtime()
	return result


func resolve_conflict_keep_device() -> Dictionary:
	if not has_conflict():
		return _local_error("NO_CONFLICT", "Nao ha conflito pendente.")
	var conflict: Dictionary = _meta.get("conflict", {}) as Dictionary
	_meta["cloudRevision"] = int(conflict.get("cloudRevision", 0))
	_meta["etag"] = str(conflict.get("cloudEtag", "\"save-%d\"" % int(conflict.get("cloudRevision", 0))))
	_meta["lastSyncedSha256"] = str(conflict.get("cloudSha256", ""))
	_meta["pendingResolution"] = "keep_device"
	_meta["dirty"] = true
	_clear_conflict_runtime(false)
	SaveSystem.save_game()
	_next_sync_at = 0.0
	return await _upload_pending()


func _clear_conflict_runtime(save: bool = true) -> void:
	var old_pending: String = str(_meta.get("conflictPendingFile", ""))
	_meta["conflict"] = {}
	_meta["conflictPendingFile"] = ""
	_meta["automaticSyncPaused"] = false
	if save:
		_save_meta()
	if not old_pending.is_empty():
		AtomicFile.remove_family(old_pending)


func _update_remote_meta(remote: Dictionary, remote_sha: String) -> void:
	_meta["cloudRevision"] = int(remote.get("revision", 0))
	_meta["etag"] = str(remote.get("etag", "\"save-%d\"" % int(remote.get("revision", 0))))
	_meta["lastSyncedSha256"] = remote_sha
	_meta["lastServerUpdatedAt"] = int(remote.get("serverUpdatedAt", 0))
	_meta["lastServerNow"] = int(remote.get("serverNow", 0))


func _recheck_dirty_after_apply(remote_sha: String) -> void:
	var current: Dictionary = SaveSystem.read_saved_compact_payload()
	_meta["currentLocalSha256"] = str(current.get("sha256", ""))
	_meta["dirty"] = not bool(current.get("ok", false)) or str(current.get("sha256", "")) != remote_sha


func _rebuild_dirty_from_candidate(candidate: Dictionary) -> void:
	if not bool(candidate.get("hasData", false)):
		_meta["currentLocalSha256"] = ""
		_meta["dirty"] = false
		_save_meta()
		return
	var current_sha: String = str(candidate.get("sha256", ""))
	_meta["currentLocalSha256"] = current_sha
	_meta["dirty"] = current_sha != str(_meta.get("lastSyncedSha256", ""))
	_save_meta()


func _load_meta() -> void:
	_meta = AtomicFile.read_json_with_fallback(META_PATH)
	var defaults: Dictionary = _default_meta()
	for key: String in defaults:
		if not _meta.has(key):
			_meta[key] = defaults[key]
	_next_sync_at = float(_meta.get("nextRetryAt", INF))
	_save_meta()


func _default_meta() -> Dictionary:
	return {
		"playerId": "",
		"cloudRevision": 0,
		"etag": "\"save-0\"",
		"lastSyncedSha256": "",
		"currentLocalSha256": "",
		"localChangeSeq": 0,
		"dirty": false,
		"inFlight": {},
		"conflict": {},
		"pendingResolution": "normal",
		"retryIndex": 0,
		"nextRetryAt": 0,
		"automaticSyncPaused": false,
		"liveOpsRevision": 0,
		"liveOpsVersionId": "bundled-1",
		"liveOpsActiveCampaignIds": [],
	}


func liveops_summary() -> Dictionary:
	return {
		"revision": int(_meta.get("liveOpsRevision", 0)),
		"versionId": str(_meta.get("liveOpsVersionId", "bundled-1")),
		"activeCampaignIds": (_meta.get("liveOpsActiveCampaignIds", []) as Array).duplicate(),
	}


func _on_liveops_config_changed(liveops: Dictionary) -> void:
	_record_liveops_summary(liveops)


func _record_liveops_summary(liveops: Dictionary) -> void:
	_meta["liveOpsRevision"] = int(liveops.get("revision", 0))
	_meta["liveOpsVersionId"] = str(liveops.get("versionId", "bundled-1"))
	_meta["liveOpsActiveCampaignIds"] = (liveops.get("activeCampaignIds", []) as Array).duplicate()
	_save_meta()


func _save_meta() -> bool:
	if not SaveSystem.persistence_enabled:
		return true
	return AtomicFile.write_json(META_PATH, _meta, true)


func clear_local_sync_state(remove_preserved_conflicts: bool = false) -> bool:
	if not SaveSystem.persistence_enabled:
		_meta = _default_meta()
		_set_state(STATE_DISABLED)
		return true
	_operation_in_progress = false
	if _api != null and _api.is_busy():
		_api.cancel()
	var success: bool = AtomicFile.remove_family(META_PATH)
	_remove_directory_contents(PENDING_DIRECTORY, false)
	if remove_preserved_conflicts:
		_remove_directory_contents(CONFLICT_DIRECTORY, false)
	_meta = {}
	_load_meta()
	_set_state(STATE_DISABLED if not CloudIdentity.is_authenticated() else STATE_PENDING)
	return success


func notify_app_paused() -> void:
	if CloudIdentity.is_authenticated() and bool(_meta.get("dirty", false)) and not has_conflict():
		_next_sync_at = 0.0
		call_deferred("_upload_pending")


func notify_app_resumed() -> void:
	if CloudIdentity.is_authenticated() and not has_conflict():
		call_deferred("check_remote_updates")


func state() -> String:
	return _state


func state_message() -> String:
	return _state_message


func is_dirty() -> bool:
	return bool(_meta.get("dirty", false))


func cloud_revision() -> int:
	return int(_meta.get("cloudRevision", 0))


func _set_state(new_state: String, custom_message: String = "") -> void:
	_state = new_state
	if not custom_message.is_empty():
		_state_message = custom_message
	else:
		match new_state:
			STATE_DISABLED: _state_message = "Save somente neste aparelho"
			STATE_SYNCED: _state_message = "Sincronizado"
			STATE_SAVING: _state_message = "Salvando na nuvem..."
			STATE_PENDING: _state_message = "Alteracoes pendentes"
			STATE_OFFLINE: _state_message = "Sem conexao - salvo neste aparelho"
			STATE_CONFLICT: _state_message = "Conflito: escolha qual save manter"
			STATE_SESSION_EXPIRED: _state_message = "Sessao expirada"
			STATE_ERROR: _state_message = "Erro temporario no save online"
	EventBus.sync_state_changed.emit(_state, _state_message)


func _on_identity_changed(authenticated: bool) -> void:
	if authenticated:
		_ensure_meta_for_current_account()
		_set_state(STATE_PENDING)
	else:
		_set_state(STATE_DISABLED)


func _ensure_meta_for_current_account() -> void:
	var current_player_id: String = CloudIdentity.player_id()
	if current_player_id.is_empty() or str(_meta.get("playerId", "")) == current_player_id:
		return
	# Metadados CAS e mutacoes nunca atravessam contas diferentes.
	_remove_directory_contents(PENDING_DIRECTORY, false)
	AtomicFile.remove_family(META_PATH)
	_meta = {}
	_load_meta()
	_meta["playerId"] = current_player_id
	_save_meta()


func _remove_directory_contents(directory_path: String, remove_root: bool) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child_path: String = directory_path.path_join(entry)
			if directory.current_is_dir():
				_remove_directory_contents(child_path, true)
			else:
				DirAccess.remove_absolute(child_path)
		entry = directory.get_next()
	directory.list_dir_end()
	if remove_root:
		DirAccess.remove_absolute(directory_path)


func _payload_from_in_flight(in_flight: Dictionary) -> String:
	var envelope_text: String = AtomicFile.read_text(str(in_flight.get("payloadFile", "")))
	var parser: JSON = JSON.new()
	if parser.parse(envelope_text) == OK and typeof(parser.data) == TYPE_DICTIONARY:
		return str((parser.data as Dictionary).get("payloadJson", ""))
	return ""


func _handle_read_error(response: Dictionary) -> Dictionary:
	if int(response.get("status", 0)) == 401:
		CloudIdentity.mark_session_expired()
		_set_state(STATE_SESSION_EXPIRED)
	else:
		_schedule_retry()
		_set_state(STATE_OFFLINE if int(response.get("status", 0)) == 0 else STATE_ERROR)
	return _response_error(response)


func _dictionary_body(response: Dictionary) -> Dictionary:
	var value: Variant = response.get("body", {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _response_error(response: Dictionary) -> Dictionary:
	var body: Dictionary = _dictionary_body(response)
	var error_value: Variant = body.get("error", {})
	var error_data: Dictionary = error_value as Dictionary if error_value is Dictionary else {}
	return {
		"ok": false,
		"status": int(response.get("status", 0)),
		"code": str(error_data.get("code", response.get("networkError", "NETWORK_ERROR"))),
		"message": str(error_data.get("message", "Nao foi possivel sincronizar agora.")),
		"requestId": str(error_data.get("requestId", "")),
	}


func _local_error(code: String, message: String) -> Dictionary:
	return {"ok": false, "status": 0, "code": code, "message": message, "requestId": ""}

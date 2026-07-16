extends Node

signal account_ready(result: Dictionary)
signal session_cleared()

const AtomicFile = preload("res://scripts/cloud/AtomicFile.gd")
const SaveValidator = preload("res://scripts/cloud/SaveValidator.gd")
const CloudApiScript = preload("res://scripts/cloud/CloudApi.gd")

const AUTH_PATH: String = "user://cloud_auth.json"
const MAX_DEVICE_LABEL_LENGTH: int = 64

var _api: CloudApi
var _auth: Dictionary = {}


func _ready() -> void:
	if SaveSystem.persistence_enabled:
		_load_or_create_installation()
	else:
		# Testes nunca leem nem alteram a identidade privada do jogador.
		_auth = {"installationId": SaveValidator.make_uuid_v4(), "ephemeral": true}
	_api = CloudApiScript.new()
	add_child(_api)


func _load_or_create_installation() -> void:
	_auth = AtomicFile.read_json_with_fallback(AUTH_PATH)
	var installation_id: String = str(_auth.get("installationId", ""))
	if not _looks_like_uuid(installation_id):
		installation_id = SaveValidator.make_uuid_v4()
		_auth = {"installationId": installation_id}
	_persist_auth()


func is_authenticated() -> bool:
	return not str(_auth.get("sessionToken", "")).is_empty()


func is_ephemeral() -> bool:
	return bool(_auth.get("ephemeral", false))


func installation_id() -> String:
	return str(_auth.get("installationId", ""))


func player_id() -> String:
	return str(_auth.get("playerId", ""))


func device_id() -> String:
	return str(_auth.get("deviceId", ""))


func session_expires_at() -> int:
	return int(_auth.get("sessionExpiresAt", 0))


func bearer_headers() -> PackedStringArray:
	var token: String = str(_auth.get("sessionToken", ""))
	var headers: PackedStringArray = PackedStringArray(["X-Client-Version: " + _client_version()])
	if token.is_empty():
		return headers
	headers.append("Authorization: Bearer " + token)
	return headers


func get_link_mode() -> String:
	return str(_auth.get("linkMode", "existing"))


func needs_initial_reconcile() -> bool:
	return bool(_auth.get("needsInitialReconcile", false))


func mark_reconciled() -> bool:
	var previous_pending: bool = bool(_auth.get("needsInitialReconcile", false))
	var previous_mode: String = str(_auth.get("linkMode", "existing"))
	_auth["needsInitialReconcile"] = false
	_auth["linkMode"] = "existing"
	if _persist_auth():
		return true
	_auth["needsInitialReconcile"] = previous_pending
	_auth["linkMode"] = previous_mode
	return false


func public_summary() -> Dictionary:
	return {
		"authenticated": is_authenticated(),
		"playerId": player_id(),
		"deviceId": device_id(),
		"sessionExpiresAt": session_expires_at(),
		"needsInitialReconcile": needs_initial_reconcile(),
		"linkMode": get_link_mode(),
	}


func create_account(device_label: String = "") -> Dictionary:
	if is_authenticated():
		return _local_error("ALREADY_AUTHENTICATED", "Este aparelho ja possui uma Conta de Peregrino.")
	var body: Dictionary = {
		"installationId": installation_id(),
		"deviceLabel": _device_label(device_label),
		"clientVersion": _client_version(),
	}
	# Criacao de conta nao recebe retry automatico: uma resposta perdida pode
	# ter criado uma conta vazia, mas nunca contem o save local.
	var response: Dictionary = await _api.send_json(HTTPClient.METHOD_POST, "players", body)
	if int(response.get("status", 0)) != 201:
		return _response_error(response)
	var response_body: Dictionary = _dictionary_body(response)
	var credential_error: Dictionary = _validate_credentials(response_body)
	if not credential_error.is_empty():
		return credential_error
	_auth.merge({
		"playerId": str(response_body.get("playerId", "")),
		"deviceId": str(response_body.get("deviceId", "")),
		"sessionToken": str(response_body.get("sessionToken", "")),
		"sessionExpiresAt": int(response_body.get("sessionExpiresAt", 0)),
		"linkMode": "created",
		"needsInitialReconcile": true,
	}, true)
	if not _persist_auth():
		_auth.erase("sessionToken")
		var write_failure: Dictionary = _local_error("AUTH_WRITE_FAILED", "A conta foi criada, mas a sessao nao pode ser guardada neste aparelho. Guarde o codigo exibido para recuperar a conta.")
		write_failure["recoveryCode"] = str(response_body.get("recoveryCode", ""))
		write_failure["accountCreated"] = true
		return write_failure
	EventBus.cloud_identity_changed.emit(true)
	var result: Dictionary = response_body.duplicate(true)
	result["ok"] = true
	account_ready.emit(result)
	return result


func recover_account(recovery_code: String, device_label: String = "", purpose: String = "game") -> Dictionary:
	if is_authenticated():
		return _local_error("ALREADY_AUTHENTICATED", "Saia da conta atual antes de recuperar outra.")
	var normalized_code: String = recovery_code.strip_edges().to_upper()
	if normalized_code.length() < 16:
		return _local_error("INVALID_RECOVERY_CODE", "Digite o codigo de recuperacao completo.")
	var body: Dictionary = {
		"recoveryCode": normalized_code,
		"installationId": installation_id(),
		"deviceLabel": _device_label(device_label),
		"clientVersion": _client_version(),
		"purpose": purpose,
	}
	var response: Dictionary = await _api.send_json(HTTPClient.METHOD_POST, "sessions/recover", body)
	if int(response.get("status", 0)) != 200:
		return _response_error(response)
	var response_body: Dictionary = _dictionary_body(response)
	var credential_error: Dictionary = _validate_credentials(response_body)
	if not credential_error.is_empty():
		return credential_error
	_auth.merge({
		"playerId": str(response_body.get("playerId", "")),
		"deviceId": str(response_body.get("deviceId", "")),
		"sessionToken": str(response_body.get("sessionToken", "")),
		"sessionExpiresAt": int(response_body.get("sessionExpiresAt", 0)),
		"purpose": str(response_body.get("purpose", purpose)),
		"linkMode": "recovered",
		"needsInitialReconcile": true,
	}, true)
	if not _persist_auth():
		_auth.erase("sessionToken")
		return _local_error("AUTH_WRITE_FAILED", "A sessao recuperada nao pode ser guardada neste aparelho.")
	EventBus.cloud_identity_changed.emit(true)
	var result: Dictionary = response_body.duplicate(true)
	result["ok"] = true
	account_ready.emit(result)
	return result


func logout() -> Dictionary:
	if not is_authenticated():
		clear_local_session()
		return {"ok": true}
	var response: Dictionary = await _api.send_json(
		HTTPClient.METHOD_POST,
		"sessions/logout",
		null,
		bearer_headers()
	)
	var status: int = int(response.get("status", 0))
	if status != 204 and status != 401:
		return _response_error(response)
	clear_local_session()
	return {"ok": true}


func rotate_recovery_code(current_code: String) -> Dictionary:
	return await _authenticated_request(
		HTTPClient.METHOD_POST,
		"recovery-code/rotate",
		{"recoveryCode": current_code.strip_edges().to_upper()}
	)


func request_recovery_reset() -> Dictionary:
	return await _authenticated_request(HTTPClient.METHOD_POST, "security/recovery-reset", {})


func list_security_actions() -> Dictionary:
	return await _authenticated_request(HTTPClient.METHOD_GET, "security/actions")


func cancel_security_action(action_id: String) -> Dictionary:
	return await _authenticated_request(HTTPClient.METHOD_DELETE, "security/actions/" + action_id.uri_encode())


func complete_security_action(action_id: String) -> Dictionary:
	return await _authenticated_request(HTTPClient.METHOD_POST, "security/actions/" + action_id.uri_encode() + "/complete", {})


func list_devices() -> Dictionary:
	return await _authenticated_request(HTTPClient.METHOD_GET, "devices")


func revoke_device(target_device_id: String) -> Dictionary:
	return await _authenticated_request(HTTPClient.METHOD_DELETE, "devices/" + target_device_id.uri_encode())


func revoke_other_sessions() -> Dictionary:
	return await _authenticated_request(HTTPClient.METHOD_POST, "sessions/revoke-others", {})


func delete_cloud_account(recovery_code: String = "") -> Dictionary:
	var body: Dictionary = {"confirmation": "EXCLUIR"}
	if not recovery_code.strip_edges().is_empty():
		body["recoveryCode"] = recovery_code.strip_edges().to_upper()
	var result: Dictionary = await _authenticated_request(HTTPClient.METHOD_DELETE, "account", body)
	if bool(result.get("ok", false)) and int(result.get("status", 0)) == 204:
		clear_local_session()
	return result


func mark_session_expired() -> void:
	if not is_authenticated():
		return
	_auth["sessionToken"] = ""
	_auth["sessionExpired"] = true
	_persist_auth()
	EventBus.cloud_identity_changed.emit(false)


func clear_local_session() -> void:
	var preserved_installation: String = installation_id()
	_auth = {"installationId": preserved_installation}
	_persist_auth()
	EventBus.cloud_identity_changed.emit(false)
	session_cleared.emit()


func delete_local_identity() -> bool:
	var removed: bool = AtomicFile.remove_family(AUTH_PATH)
	_auth = {"installationId": SaveValidator.make_uuid_v4()}
	return _persist_auth() and removed


func _authenticated_request(method: int, path: String, body: Variant = null) -> Dictionary:
	if not is_authenticated():
		return _local_error("NOT_AUTHENTICATED", "Ative ou recupere sua Conta de Peregrino.")
	var response: Dictionary = await _api.send_json(method, path, body, bearer_headers())
	var status: int = int(response.get("status", 0))
	if status == 401:
		mark_session_expired()
		return _response_error(response)
	if status < 200 or status >= 300:
		return _response_error(response)
	var result: Dictionary = _dictionary_body(response)
	result["ok"] = true
	result["status"] = status
	return result


func _persist_auth() -> bool:
	# Recovery code e qualquer resposta que o contenha jamais entram neste arquivo.
	_auth.erase("recoveryCode")
	if not SaveSystem.persistence_enabled:
		return true
	return AtomicFile.write_json(AUTH_PATH, _auth, true)


func _validate_credentials(body: Dictionary) -> Dictionary:
	if str(body.get("playerId", "")).is_empty() or str(body.get("deviceId", "")).is_empty():
		return _local_error("INVALID_SERVER_RESPONSE", "O servidor nao retornou os identificadores da conta.")
	var token: String = str(body.get("sessionToken", ""))
	var separator: int = token.find(".")
	var key_version: String = token.substr(1, separator - 1) if separator > 1 else ""
	if token.is_empty() or not token.begins_with("S") or separator <= 1 or not key_version.is_valid_int() or int(key_version) < 1:
		return _local_error("INVALID_SERVER_RESPONSE", "O servidor nao retornou uma sessao valida.")
	return {}


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
		"message": str(error_data.get("message", "Nao foi possivel concluir a operacao agora.")),
		"requestId": str(error_data.get("requestId", "")),
	}


func _local_error(code: String, message: String) -> Dictionary:
	return {"ok": false, "status": 0, "code": code, "message": message, "requestId": ""}


func _client_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev")).left(32)


func _device_label(provided: String) -> String:
	var label: String = provided.strip_edges()
	if label.is_empty():
		label = OS.get_model_name().strip_edges()
	if label.is_empty():
		label = "Dispositivo Godot"
	return label.left(MAX_DEVICE_LABEL_LENGTH)


func _looks_like_uuid(value: String) -> bool:
	if value.length() != 36:
		return false
	for separator: int in [8, 13, 18, 23]:
		if value[separator] != "-":
			return false
	var compact: String = value.replace("-", "").to_lower()
	if compact.length() != 32:
		return false
	for character: String in compact:
		if character not in "0123456789abcdef":
			return false
	return true

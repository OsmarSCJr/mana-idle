class_name CloudApi
extends Node

signal response_received(response: Dictionary)

const DEFAULT_TIMEOUT_SECONDS: float = 10.0

var base_url: String = ""
var _http: HTTPRequest
var _active: bool = false


func _ready() -> void:
	base_url = str(ProjectSettings.get_setting("cloud_save/api_base_url", "https://api.example.invalid/v1")).strip_edges().trim_suffix("/")
	_create_http_client()


func _create_http_client() -> void:
	_http = HTTPRequest.new()
	_http.use_threads = true
	_http.timeout = DEFAULT_TIMEOUT_SECONDS
	_http.body_size_limit = 131_072
	# Nunca encaminhar Authorization automaticamente a outro host via redirect.
	_http.max_redirects = 0
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)


func is_busy() -> bool:
	return _active


func cancel() -> void:
	if _active:
		_http.cancel_request()
		_active = false
		# Descarta o node para que um callback tardio nunca seja confundido com
		# uma requisicao nova deste cliente.
		_http.request_completed.disconnect(_on_request_completed)
		_http.queue_free()
		_create_http_client()
		response_received.emit({
			"ok": false,
			"networkOk": false,
			"networkError": "CANCELLED",
			"status": 0,
			"headers": {},
			"body": {},
		})


func send_json(
		method: int,
		path: String,
		body: Variant = null,
		extra_headers: PackedStringArray = PackedStringArray(),
		timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS
	) -> Dictionary:
	var body_text: String = ""
	if body != null:
		body_text = JSON.stringify(body)
	return await send_raw(method, path, body_text, extra_headers, timeout_seconds)


func send_raw(
		method: int,
		path: String,
		body_text: String = "",
		extra_headers: PackedStringArray = PackedStringArray(),
		timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS
	) -> Dictionary:
	if _active:
		return {"ok": false, "networkError": "REQUEST_IN_PROGRESS", "status": 0, "body": {}}
	var is_exact_local_http: bool = (
		base_url == "http://localhost"
		or base_url.begins_with("http://localhost:")
		or base_url.begins_with("http://localhost/")
		or base_url == "http://127.0.0.1"
		or base_url.begins_with("http://127.0.0.1:")
		or base_url.begins_with("http://127.0.0.1/")
	)
	var is_placeholder: bool = base_url.to_lower().contains(".invalid")
	if base_url.is_empty() or is_placeholder or (not base_url.begins_with("https://") and not is_exact_local_http):
		return {"ok": false, "networkError": "INVALID_API_URL", "status": 0, "body": {}}

	var headers: PackedStringArray = PackedStringArray(["Accept: application/json"])
	if not body_text.is_empty():
		headers.append("Content-Type: application/json")
	for header: String in extra_headers:
		headers.append(header)

	_http.timeout = maxf(1.0, timeout_seconds)
	_active = true
	var request_error: Error = _http.request(
		base_url + "/" + path.trim_prefix("/"),
		headers,
		method,
		body_text
	)
	if request_error != OK:
		_active = false
		return {
			"ok": false,
			"networkError": "REQUEST_START_FAILED",
			"error": request_error,
			"status": 0,
			"body": {},
		}
	var response: Dictionary = await response_received
	return response


func _on_request_completed(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray) -> void:
	_active = false
	var headers: Dictionary = {}
	for raw_header: String in response_headers:
		var separator: int = raw_header.find(":")
		if separator <= 0:
			continue
		var header_name: String = raw_header.substr(0, separator).strip_edges().to_lower()
		headers[header_name] = raw_header.substr(separator + 1).strip_edges()

	var response_text: String = response_body.get_string_from_utf8()
	var parsed_body: Variant = {}
	if not response_text.is_empty():
		var parser: JSON = JSON.new()
		if parser.parse(response_text) == OK:
			parsed_body = parser.data
		else:
			parsed_body = {"raw": response_text.left(256)}
	var network_ok: bool = result == HTTPRequest.RESULT_SUCCESS
	response_received.emit({
		"ok": network_ok and response_code >= 200 and response_code < 300,
		"networkOk": network_ok,
		"networkResult": result,
		"networkError": "" if network_ok else _network_error_name(result),
		"status": response_code,
		"headers": headers,
		"body": parsed_body,
	})


func _network_error_name(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH: return "CHUNKED_BODY_SIZE_MISMATCH"
		HTTPRequest.RESULT_CANT_CONNECT: return "CANT_CONNECT"
		HTTPRequest.RESULT_CANT_RESOLVE: return "CANT_RESOLVE"
		HTTPRequest.RESULT_CONNECTION_ERROR: return "CONNECTION_ERROR"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR: return "TLS_HANDSHAKE_ERROR"
		HTTPRequest.RESULT_NO_RESPONSE: return "NO_RESPONSE"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED: return "BODY_SIZE_LIMIT_EXCEEDED"
		HTTPRequest.RESULT_REQUEST_FAILED: return "REQUEST_FAILED"
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN: return "DOWNLOAD_FILE_CANT_OPEN"
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR: return "DOWNLOAD_FILE_WRITE_ERROR"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED: return "REDIRECT_LIMIT_REACHED"
		HTTPRequest.RESULT_TIMEOUT: return "TIMEOUT"
		_: return "HTTP_RESULT_%d" % result

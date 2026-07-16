extends Node

signal config_changed(summary: Dictionary)
signal refresh_finished(result: Dictionary)

const AtomicFile = preload("res://scripts/cloud/AtomicFile.gd")
const CloudApiScript = preload("res://scripts/cloud/CloudApi.gd")

const CACHE_PATH: String = "user://liveops_config.json"
const SCHEMA_VERSION: int = 1
const CACHE_SCHEMA_VERSION: int = 1
const MAX_CAMPAIGNS: int = 64
const MAX_GENERATOR_ID: int = 36
const BACKGROUND_REFRESH_SECONDS: float = 900.0
const MAX_STACKED_MULTIPLIER: float = 1.0e6
const MAX_FREE_GEM_STACKED_MULTIPLIER: float = 100.0
const MAX_EFFECTIVE_PRODUCTION_MULTIPLIER: float = 1.0e12

const DEFAULT_CONFIG: Dictionary = {
	"economy": {
		"growthRate": 1.11,
		"saintBonus": 0.06,
		"prestigeDivisor": 2.0e12,
		"prophetUnlockQuantity": 25,
		"prophetCostMultiplier": 20.0,
		"offlineCapSeconds": 8.0 * 3600.0,
		"milestones": [
			{"quantity": 25, "multiplier": 1.0},
			{"quantity": 50, "multiplier": 2.0},
			{"quantity": 100, "multiplier": 2.0},
			{"quantity": 200, "multiplier": 2.0},
			{"quantity": 300, "multiplier": 2.0},
			{"quantity": 400, "multiplier": 2.0},
		],
	},
	"boosts": {
		"fervorProductionMultiplier": 2.0,
		"pentecostProductionMultiplier": 5.0,
		"holyHandsManualMultiplier": 10.0,
		"swiftStepTimeMultiplier": 0.5,
		"harvestSeconds": 7200.0,
	},
	"rewards": {
		"videoGems": 5,
		"offlineTripleGemCost": 3,
	},
}

const TOP_LEVEL_KEYS: Array[String] = [
	"schemaVersion", "revision", "versionId", "publishedAt", "serverNow", "config", "campaigns",
]
const CONFIG_KEYS: Array[String] = ["economy", "boosts", "rewards"]
const ECONOMY_KEYS: Array[String] = [
	"growthRate", "saintBonus", "prestigeDivisor", "prophetUnlockQuantity",
	"prophetCostMultiplier", "offlineCapSeconds", "milestones",
]
const BOOST_KEYS: Array[String] = [
	"fervorProductionMultiplier", "pentecostProductionMultiplier",
	"holyHandsManualMultiplier", "swiftStepTimeMultiplier", "harvestSeconds",
]
const REWARD_KEYS: Array[String] = ["videoGems", "offlineTripleGemCost"]
const CAMPAIGN_KEYS: Array[String] = [
	"id", "key", "versionId", "version", "name", "startsAt", "endsAt", "publishedAt", "effects",
]
const EFFECT_KEYS: Array[String] = [
	"globalProductionMultiplier", "offlineProductionMultiplier", "manualProductionMultiplier",
	"studyFaithMultiplier", "freeGemRewardMultiplier", "generatorProductionMultipliers",
]

var _api: CloudApi
var _envelope: Dictionary = {}
var _etag: String = ""
var _source: String = "bundled"
var _last_error: String = ""
var _server_time_offset_seconds: float = 0.0
var _active_campaigns: Array = []
var _active_signature: String = ""
var _campaign_timer: Timer
var _network_timer: Timer
var _smoke_test: bool = false
var _test_now_override: float = -1.0
var _refresh_in_progress: bool = false


func _ready() -> void:
	_smoke_test = OS.get_cmdline_user_args().has("--smoke-test")
	_apply_envelope(_bundled_envelope(), "", "bundled", 0.0, false)
	_api = CloudApiScript.new()
	add_child(_api)
	if not _smoke_test:
		_load_cache_from(CACHE_PATH, true)
	_campaign_timer = Timer.new()
	_campaign_timer.wait_time = 1.0
	_campaign_timer.timeout.connect(_refresh_campaign_state)
	add_child(_campaign_timer)
	_campaign_timer.start()
	if not _smoke_test:
		_network_timer = Timer.new()
		_network_timer.wait_time = BACKGROUND_REFRESH_SECONDS
		_network_timer.timeout.connect(_refresh_from_network_timer)
		add_child(_network_timer)
		_network_timer.start()


func bootstrap(timeout_seconds: float = 1.25) -> Dictionary:
	if _refresh_in_progress:
		var shared_result: Dictionary = await refresh_finished
		return shared_result
	_refresh_in_progress = true
	var result: Dictionary = await _bootstrap_once(timeout_seconds)
	_refresh_in_progress = false
	refresh_finished.emit(result)
	return result


func _bootstrap_once(timeout_seconds: float) -> Dictionary:
	if _smoke_test:
		return {"ok": true, "source": _source, "skipped": true}
	var headers := PackedStringArray()
	if not _etag.is_empty():
		headers.append("If-None-Match: " + _etag)
	var response: Dictionary = await _api.send_json(
		HTTPClient.METHOD_GET,
		"config",
		null,
		headers,
		clampf(timeout_seconds, 1.0, 3.0)
	)
	var status := int(response.get("status", 0))
	if status == 304:
		var not_modified_headers: Dictionary = response.get("headers", {}) as Dictionary
		var refreshed_server_now := _server_now_from_headers(not_modified_headers)
		if refreshed_server_now >= 0.0:
			_server_time_offset_seconds = refreshed_server_now - Time.get_unix_time_from_system()
			_write_cache_to(CACHE_PATH)
		_last_error = ""
		return {"ok": true, "source": _source, "notModified": true, "summary": summary()}
	if status != 200:
		_last_error = str(response.get("networkError", "HTTP_%d" % status))
		return {"ok": false, "source": _source, "fallback": true, "code": _last_error, "summary": summary()}
	var body_value: Variant = response.get("body", {})
	if body_value is not Dictionary:
		_last_error = "INVALID_RESPONSE_BODY"
		return {"ok": false, "source": _source, "fallback": true, "code": _last_error, "summary": summary()}
	var validated := _validate_envelope(body_value as Dictionary)
	if not bool(validated.get("ok", false)):
		_last_error = str(validated.get("code", "INVALID_CONFIG"))
		return {"ok": false, "source": _source, "fallback": true, "code": _last_error, "summary": summary()}
	var normalized: Dictionary = validated.envelope
	var incoming_revision := int(normalized.revision)
	var current_revision := int(_envelope.get("revision", 0))
	if incoming_revision < current_revision:
		_last_error = "REVISION_ROLLBACK"
		return {"ok": false, "source": _source, "fallback": true, "code": _last_error, "summary": summary()}
	if incoming_revision == current_revision \
			and str(normalized.versionId) != str(_envelope.get("versionId", "")):
		_last_error = "REVISION_VERSION_MISMATCH"
		return {"ok": false, "source": _source, "fallback": true, "code": _last_error, "summary": summary()}
	var response_headers: Dictionary = response.get("headers", {}) as Dictionary
	var next_etag := str(response_headers.get("etag", ""))
	var header_server_now := _server_now_from_headers(response_headers)
	var trusted_server_now := header_server_now if header_server_now >= 0.0 else float(normalized.serverNow)
	var offset := trusted_server_now - Time.get_unix_time_from_system()
	_apply_envelope(normalized, next_etag, "network", offset, true)
	_write_cache_to(CACHE_PATH)
	_last_error = ""
	return {"ok": true, "source": _source, "summary": summary()}


func _refresh_from_network_timer() -> void:
	await bootstrap(3.0)


func _server_now_from_headers(headers: Dictionary) -> float:
	var raw := str(headers.get("x-server-now", "")).strip_edges()
	if not raw.is_valid_int():
		return -1.0
	var value := int(raw)
	return float(value) if value >= 0 else -1.0


func summary() -> Dictionary:
	var names: Array[String] = []
	var ids: Array[String] = []
	for campaign_value: Variant in _active_campaigns:
		var campaign: Dictionary = campaign_value as Dictionary
		names.append(str(campaign.name))
		ids.append(str(campaign.id))
	return {
		"schemaVersion": SCHEMA_VERSION,
		"revision": int(_envelope.get("revision", 0)),
		"versionId": str(_envelope.get("versionId", "bundled-1")),
		"publishedAt": int(_envelope.get("publishedAt", 0)),
		"source": _source,
		"etag": _etag,
		"serverTimeOffsetSeconds": _server_time_offset_seconds,
		"activeCampaignIds": ids,
		"activeCampaignNames": names,
		"lastError": _last_error,
	}


func version_id() -> String:
	return str(_envelope.get("versionId", "bundled-1"))


func revision() -> int:
	return int(_envelope.get("revision", 0))


func server_adjusted_now() -> float:
	if _smoke_test and _test_now_override >= 0.0:
		return _test_now_override
	return Time.get_unix_time_from_system() + _server_time_offset_seconds


func server_time_offset_seconds() -> float:
	return _server_time_offset_seconds


func active_campaign_names() -> Array[String]:
	var names: Array[String] = []
	for campaign_value: Variant in _active_campaigns:
		names.append(str((campaign_value as Dictionary).name))
	return names


func growth_rate() -> float:
	return float(_economy().growthRate)


func saint_bonus() -> float:
	return float(_economy().saintBonus)


func prestige_divisor() -> float:
	return float(_economy().prestigeDivisor)


func prophet_unlock_quantity() -> int:
	return int(_economy().prophetUnlockQuantity)


func prophet_cost_multiplier() -> float:
	return float(_economy().prophetCostMultiplier)


func offline_cap_seconds() -> float:
	return float(_economy().offlineCapSeconds)


func milestones() -> Array:
	return (_economy().milestones as Array).duplicate(true)


func fervor_production_multiplier() -> float:
	return float(_boosts().fervorProductionMultiplier)


func pentecost_production_multiplier() -> float:
	return float(_boosts().pentecostProductionMultiplier)


func holy_hands_manual_multiplier() -> float:
	return float(_boosts().holyHandsManualMultiplier)


func swift_step_time_multiplier() -> float:
	return float(_boosts().swiftStepTimeMultiplier)


func harvest_seconds() -> float:
	return float(_boosts().harvestSeconds)


func video_gems() -> int:
	return int(_rewards().videoGems)


func offline_triple_gem_cost() -> int:
	return int(_rewards().offlineTripleGemCost)


func global_production_multiplier() -> float:
	return float(_combined_effects_at(server_adjusted_now()).globalProductionMultiplier)


func offline_production_multiplier() -> float:
	return float(_combined_effects_at(server_adjusted_now()).offlineProductionMultiplier)


func manual_production_multiplier() -> float:
	return float(_combined_effects_at(server_adjusted_now()).manualProductionMultiplier)


func study_faith_multiplier() -> float:
	return float(_combined_effects_at(server_adjusted_now()).studyFaithMultiplier)


func free_gem_reward_multiplier() -> float:
	return float(_combined_effects_at(server_adjusted_now()).freeGemRewardMultiplier)


func generator_production_multiplier(generator_id: int) -> float:
	var effects := _combined_effects_at(server_adjusted_now())
	return float((effects.generatorProductionMultipliers as Dictionary).get(str(generator_id), 1.0))


func scale_free_gem_reward(base_amount: int) -> int:
	if base_amount <= 0:
		return 0
	return maxi(0, roundi(float(base_amount) * free_gem_reward_multiplier()))


func offline_weighted_multiplier(start_at: float, end_at: float, generator_id: int) -> float:
	if end_at <= start_at:
		return 1.0
	var weighted := 0.0
	var total_duration := end_at - start_at
	for segment_value: Variant in effect_segments(start_at, end_at):
		var segment: Dictionary = segment_value as Dictionary
		var effects: Dictionary = segment.effects as Dictionary
		var generator_multiplier := float(
			(effects.generatorProductionMultipliers as Dictionary).get(str(generator_id), 1.0)
		)
		var duration := float(segment.endsAt) - float(segment.startsAt)
		var effective_multiplier := minf(
			float(effects.globalProductionMultiplier) * float(effects.offlineProductionMultiplier),
			MAX_EFFECTIVE_PRODUCTION_MULTIPLIER
		)
		effective_multiplier = minf(
			effective_multiplier * generator_multiplier,
			MAX_EFFECTIVE_PRODUCTION_MULTIPLIER
		)
		weighted += duration * effective_multiplier
	return weighted / total_duration


func effect_segments(start_at: float, end_at: float) -> Array:
	var result: Array = []
	if end_at <= start_at:
		return result
	var boundaries: Array[float] = [start_at, end_at]
	for campaign_value: Variant in _campaigns():
		var campaign: Dictionary = campaign_value as Dictionary
		var campaign_start := float(campaign.startsAt)
		var campaign_end := float(campaign.endsAt)
		if campaign_start > start_at and campaign_start < end_at:
			boundaries.append(campaign_start)
		if campaign_end > start_at and campaign_end < end_at:
			boundaries.append(campaign_end)
	boundaries.sort()
	var unique_boundaries: Array[float] = []
	for boundary: float in boundaries:
		if unique_boundaries.is_empty() or not is_equal_approx(unique_boundaries[-1], boundary):
			unique_boundaries.append(boundary)
	for index in range(unique_boundaries.size() - 1):
		var segment_start := unique_boundaries[index]
		var segment_end := unique_boundaries[index + 1]
		if segment_end <= segment_start:
			continue
		var midpoint := segment_start + (segment_end - segment_start) * 0.5
		result.append({
			"startsAt": segment_start,
			"endsAt": segment_end,
			"effects": _combined_effects_at(midpoint),
		})
	return result


func _economy() -> Dictionary:
	return (_envelope.get("config", DEFAULT_CONFIG) as Dictionary).get("economy", DEFAULT_CONFIG.economy) as Dictionary


func _boosts() -> Dictionary:
	return (_envelope.get("config", DEFAULT_CONFIG) as Dictionary).get("boosts", DEFAULT_CONFIG.boosts) as Dictionary


func _rewards() -> Dictionary:
	return (_envelope.get("config", DEFAULT_CONFIG) as Dictionary).get("rewards", DEFAULT_CONFIG.rewards) as Dictionary


func _campaigns() -> Array:
	return _envelope.get("campaigns", []) as Array


func _bundled_envelope() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"revision": 0,
		"versionId": "bundled-1",
		"publishedAt": 0,
		"serverNow": 0,
		"config": DEFAULT_CONFIG.duplicate(true),
		"campaigns": [],
	}


func _apply_envelope(
		envelope: Dictionary,
		etag: String,
		source: String,
		server_offset: float,
		emit_change: bool
	) -> void:
	var previous_version := str(_envelope.get("versionId", ""))
	var previous_revision := int(_envelope.get("revision", -1))
	_envelope = envelope.duplicate(true)
	_etag = etag
	_source = source
	_server_time_offset_seconds = server_offset
	_refresh_campaign_state(false)
	if emit_change or previous_version != version_id() or previous_revision != revision():
		config_changed.emit(summary())


func _refresh_campaign_state(emit_change: bool = true) -> void:
	var now := server_adjusted_now()
	var active: Array = []
	var signature_parts: Array[String] = []
	for campaign_value: Variant in _campaigns():
		var campaign: Dictionary = campaign_value as Dictionary
		if _campaign_active_at(campaign, now):
			active.append(campaign)
			signature_parts.append(str(campaign.id) + "@" + str(campaign.versionId))
	signature_parts.sort()
	var signature := "|".join(signature_parts)
	var changed := signature != _active_signature
	_active_campaigns = active
	_active_signature = signature
	if emit_change and changed:
		config_changed.emit(summary())


func _campaign_active_at(campaign: Dictionary, at_time: float) -> bool:
	return at_time >= float(campaign.startsAt) and at_time < float(campaign.endsAt)


func _combined_effects_at(at_time: float) -> Dictionary:
	var combined := {
		"globalProductionMultiplier": 1.0,
		"offlineProductionMultiplier": 1.0,
		"manualProductionMultiplier": 1.0,
		"studyFaithMultiplier": 1.0,
		"freeGemRewardMultiplier": 1.0,
		"generatorProductionMultipliers": {},
	}
	for campaign_value: Variant in _campaigns():
		var campaign: Dictionary = campaign_value as Dictionary
		if not _campaign_active_at(campaign, at_time):
			continue
		var effects: Dictionary = campaign.effects as Dictionary
		for key: String in [
			"globalProductionMultiplier", "offlineProductionMultiplier",
			"manualProductionMultiplier", "studyFaithMultiplier", "freeGemRewardMultiplier",
		]:
			var ceiling := MAX_FREE_GEM_STACKED_MULTIPLIER \
				if key == "freeGemRewardMultiplier" else MAX_STACKED_MULTIPLIER
			combined[key] = minf(float(combined[key]) * float(effects[key]), ceiling)
		var generator_multipliers: Dictionary = combined.generatorProductionMultipliers
		for generator_key: Variant in (effects.generatorProductionMultipliers as Dictionary):
			var normalized_key := str(generator_key)
			generator_multipliers[normalized_key] = minf(
				float(generator_multipliers.get(normalized_key, 1.0))
					* float((effects.generatorProductionMultipliers as Dictionary)[generator_key]),
				MAX_STACKED_MULTIPLIER
			)
	return combined


func _write_cache_to(path: String) -> bool:
	var cache := {
		"cacheSchemaVersion": CACHE_SCHEMA_VERSION,
		"etag": _etag,
		"cachedAt": int(Time.get_unix_time_from_system()),
		"serverTimeOffsetSeconds": _server_time_offset_seconds,
		"payload": _envelope,
	}
	return AtomicFile.write_json(path, cache, true)


func _load_cache_from(path: String, apply: bool) -> Dictionary:
	var cache := AtomicFile.read_json_with_fallback(path)
	if cache.is_empty():
		return {"ok": false, "code": "CACHE_MISSING"}
	if not _has_exact_keys(cache, [
		"cacheSchemaVersion", "etag", "cachedAt", "serverTimeOffsetSeconds", "payload",
	]):
		return {"ok": false, "code": "INVALID_CACHE_SHAPE"}
	if int(cache.get("cacheSchemaVersion", 0)) != CACHE_SCHEMA_VERSION \
			or not _is_integer_number(cache.get("cachedAt")) \
			or not _number_in_range(cache.get("serverTimeOffsetSeconds"), -86400.0, 86400.0):
		return {"ok": false, "code": "INVALID_CACHE_META"}
	var payload_value: Variant = cache.get("payload", {})
	if payload_value is not Dictionary:
		return {"ok": false, "code": "INVALID_CACHE_PAYLOAD"}
	var validated := _validate_envelope(payload_value as Dictionary)
	if not bool(validated.get("ok", false)):
		return validated
	if apply:
		_apply_envelope(
			validated.envelope,
			str(cache.etag),
			"cache",
			float(cache.serverTimeOffsetSeconds),
			true
		)
	return {"ok": true, "envelope": validated.envelope}


func _validate_envelope(envelope: Dictionary) -> Dictionary:
	var error := _envelope_error(envelope)
	if not error.is_empty():
		return {"ok": false, "code": error}
	return {"ok": true, "envelope": envelope.duplicate(true)}


func _envelope_error(envelope: Dictionary) -> String:
	if not _has_exact_keys(envelope, TOP_LEVEL_KEYS):
		return "INVALID_TOP_LEVEL_KEYS"
	if int(envelope.get("schemaVersion", 0)) != SCHEMA_VERSION:
		return "UNSUPPORTED_SCHEMA"
	if not _is_integer_number(envelope.revision) or int(envelope.revision) < 0:
		return "INVALID_REVISION"
	if not _valid_identifier(str(envelope.versionId)):
		return "INVALID_VERSION_ID"
	for time_key: String in ["publishedAt", "serverNow"]:
		if not _is_integer_number(envelope[time_key]) or int(envelope[time_key]) < 0:
			return "INVALID_" + time_key.to_upper()
	if envelope.config is not Dictionary or not _has_exact_keys(envelope.config as Dictionary, CONFIG_KEYS):
		return "INVALID_CONFIG_KEYS"
	var config: Dictionary = envelope.config
	var economy_error := _validate_economy(config.economy)
	if not economy_error.is_empty():
		return economy_error
	var boost_error := _validate_boosts(config.boosts)
	if not boost_error.is_empty():
		return boost_error
	var reward_error := _validate_rewards(config.rewards)
	if not reward_error.is_empty():
		return reward_error
	if envelope.campaigns is not Array or (envelope.campaigns as Array).size() > MAX_CAMPAIGNS:
		return "INVALID_CAMPAIGNS"
	var seen_version_ids: Dictionary = {}
	for campaign_value: Variant in envelope.campaigns as Array:
		if campaign_value is not Dictionary:
			return "INVALID_CAMPAIGN"
		var campaign: Dictionary = campaign_value as Dictionary
		var campaign_error := _validate_campaign(campaign)
		if not campaign_error.is_empty():
			return campaign_error
		if seen_version_ids.has(str(campaign.versionId)):
			return "DUPLICATE_CAMPAIGN_VERSION_ID"
		seen_version_ids[str(campaign.versionId)] = true
	return ""


func _validate_economy(value: Variant) -> String:
	if value is not Dictionary or not _has_exact_keys(value as Dictionary, ECONOMY_KEYS):
		return "INVALID_ECONOMY_KEYS"
	var economy: Dictionary = value as Dictionary
	if not _number_in_range(economy.growthRate, 1.000001, 2.0):
		return "INVALID_GROWTH_RATE"
	if not _number_in_range(economy.saintBonus, 0.0, 10.0):
		return "INVALID_SAINT_BONUS"
	if not _number_in_range(economy.prestigeDivisor, 1.0, 1.0e100):
		return "INVALID_PRESTIGE_DIVISOR"
	if not _is_integer_number(economy.prophetUnlockQuantity) \
			or int(economy.prophetUnlockQuantity) < 1 or int(economy.prophetUnlockQuantity) > 10000:
		return "INVALID_PROPHET_QUANTITY"
	if not _number_in_range(economy.prophetCostMultiplier, 0.001, 1.0e6):
		return "INVALID_PROPHET_COST"
	if not _number_in_range(economy.offlineCapSeconds, 60.0, 31_536_000.0):
		return "INVALID_OFFLINE_CAP"
	if economy.milestones is not Array or (economy.milestones as Array).is_empty() \
			or (economy.milestones as Array).size() > 32:
		return "INVALID_MILESTONES"
	var previous_quantity := 0
	for milestone_value: Variant in economy.milestones as Array:
		if milestone_value is not Dictionary \
				or not _has_exact_keys(milestone_value as Dictionary, ["quantity", "multiplier"]):
			return "INVALID_MILESTONE"
		var milestone: Dictionary = milestone_value as Dictionary
		if not _is_integer_number(milestone.quantity) or int(milestone.quantity) <= previous_quantity:
			return "INVALID_MILESTONE_QUANTITY"
		if not _number_in_range(milestone.multiplier, 0.01, 1000.0):
			return "INVALID_MILESTONE_MULTIPLIER"
		previous_quantity = int(milestone.quantity)
	return ""


func _validate_boosts(value: Variant) -> String:
	if value is not Dictionary or not _has_exact_keys(value as Dictionary, BOOST_KEYS):
		return "INVALID_BOOST_KEYS"
	var boosts: Dictionary = value as Dictionary
	for key: String in BOOST_KEYS:
		if not _number_in_range(boosts[key], 0.001, 1.0e6):
			return "INVALID_BOOST_" + key.to_upper()
	return ""


func _validate_rewards(value: Variant) -> String:
	if value is not Dictionary or not _has_exact_keys(value as Dictionary, REWARD_KEYS):
		return "INVALID_REWARD_KEYS"
	var rewards: Dictionary = value as Dictionary
	for key: String in REWARD_KEYS:
		if not _is_integer_number(rewards[key]) or int(rewards[key]) < 0 or int(rewards[key]) > 1_000_000:
			return "INVALID_REWARD_" + key.to_upper()
	return ""


func _validate_campaign(campaign: Dictionary) -> String:
	if not _has_exact_keys(campaign, CAMPAIGN_KEYS):
		return "INVALID_CAMPAIGN_KEYS"
	for key: String in ["id", "key", "versionId"]:
		if not _valid_identifier(str(campaign[key])):
			return "INVALID_CAMPAIGN_" + key.to_upper()
	var name := str(campaign.name).strip_edges()
	if name.is_empty() or name.length() > 96:
		return "INVALID_CAMPAIGN_NAME"
	if not _is_integer_number(campaign.version) or int(campaign.version) < 1:
		return "INVALID_CAMPAIGN_VERSION"
	for time_key: String in ["startsAt", "endsAt", "publishedAt"]:
		if not _is_integer_number(campaign[time_key]) or int(campaign[time_key]) < 0:
			return "INVALID_CAMPAIGN_" + time_key.to_upper()
	if int(campaign.endsAt) <= int(campaign.startsAt):
		return "INVALID_CAMPAIGN_WINDOW"
	if campaign.effects is not Dictionary or not _has_exact_keys(campaign.effects as Dictionary, EFFECT_KEYS):
		return "INVALID_EFFECT_KEYS"
	var effects: Dictionary = campaign.effects
	for key: String in EFFECT_KEYS.slice(0, 4):
		if not _number_in_range(effects[key], 0.01, 1000.0):
			return "INVALID_EFFECT_" + key.to_upper()
	if not _number_in_range(effects.freeGemRewardMultiplier, 0.0, 100.0):
		return "INVALID_EFFECT_FREEGEMREWARDMULTIPLIER"
	if effects.generatorProductionMultipliers is not Dictionary \
			or (effects.generatorProductionMultipliers as Dictionary).size() > MAX_GENERATOR_ID:
		return "INVALID_GENERATOR_MULTIPLIERS"
	for generator_key: Variant in effects.generatorProductionMultipliers as Dictionary:
		var key_text := str(generator_key)
		if not key_text.is_valid_int():
			return "INVALID_GENERATOR_ID"
		var generator_id := int(key_text)
		if generator_id < 1 or generator_id > MAX_GENERATOR_ID \
				or not _number_in_range((effects.generatorProductionMultipliers as Dictionary)[generator_key], 0.01, 1000.0):
			return "INVALID_GENERATOR_MULTIPLIER"
	return ""


func _has_exact_keys(value: Dictionary, expected: Array[String]) -> bool:
	if value.size() != expected.size():
		return false
	for key: String in expected:
		if not value.has(key):
			return false
	return true


func _is_integer_number(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return not is_nan(number) and not is_inf(number) and is_equal_approx(number, floor(number))


func _number_in_range(value: Variant, minimum: float, maximum: float) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return not is_nan(number) and not is_inf(number) and number >= minimum and number <= maximum


func _valid_identifier(value: String) -> bool:
	var normalized := value.strip_edges()
	if normalized.is_empty() or normalized.length() > 64:
		return false
	for character: String in normalized:
		if character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-":
			return false
	return true


# Helpers guardados pelo modo smoke para validar cache e boundaries sem tocar dados reais.
func smoke_validate(envelope: Dictionary) -> Dictionary:
	if not _smoke_test:
		return {"ok": false, "code": "SMOKE_ONLY"}
	return _validate_envelope(envelope)


func smoke_apply(envelope: Dictionary, now_override: float) -> Dictionary:
	if not _smoke_test:
		return {"ok": false, "code": "SMOKE_ONLY"}
	var validated := _validate_envelope(envelope)
	if not bool(validated.get("ok", false)):
		return validated
	_test_now_override = now_override
	_apply_envelope(validated.envelope, "\"smoke\"", "smoke", 0.0, true)
	return {"ok": true}


func smoke_reset() -> void:
	if not _smoke_test:
		return
	_test_now_override = -1.0
	_apply_envelope(_bundled_envelope(), "", "bundled", 0.0, true)


func smoke_cache_roundtrip(path: String, envelope: Dictionary) -> Dictionary:
	if not _smoke_test or not path.begins_with("user://liveops_smoke/"):
		return {"ok": false, "code": "SMOKE_ONLY"}
	var validated := _validate_envelope(envelope)
	if not bool(validated.get("ok", false)):
		return validated
	var previous_envelope := _envelope.duplicate(true)
	var previous_etag := _etag
	var previous_source := _source
	var previous_offset := _server_time_offset_seconds
	_envelope = validated.envelope
	_etag = "\"liveops-smoke\""
	_server_time_offset_seconds = 5.0
	var wrote := _write_cache_to(path)
	_envelope = previous_envelope
	_etag = previous_etag
	_source = previous_source
	_server_time_offset_seconds = previous_offset
	if not wrote:
		return {"ok": false, "code": "CACHE_WRITE_FAILED"}
	return _load_cache_from(path, false)

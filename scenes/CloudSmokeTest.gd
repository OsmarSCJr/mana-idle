extends Node


func _ready() -> void:
	SaveSystem.set_persistence_enabled(false)
	var ok: bool = true

	# A ordem de insercao de Dictionary nao altera o payload compacto/hash.
	var first: Dictionary = {"z": 2, "a": {"y": [3, 2, 1], "x": true}}
	var second: Dictionary = {"a": {"x": true, "y": [3, 2, 1]}, "z": 2}
	var first_json: String = CloudSaveValidator.compact_json(first)
	var second_json: String = CloudSaveValidator.compact_json(second)
	var canonical_ok: bool = first_json == second_json \
		and CloudSaveValidator.sha256_text(first_json) == CloudSaveValidator.sha256_text(second_json)
	ok = ok and canonical_ok

	var uuid: String = CloudSaveValidator.make_uuid_v4()
	var uuid_ok: bool = uuid.length() == 36 and uuid[14] == "4" and uuid[8] == "-" and uuid[13] == "-"
	ok = ok and uuid_ok

	# O jogador pode marcar todos os 1.189 capítulos da Bíblia como lidos.
	# Mantemos um pequeno teto defensivo sem impedir progresso legítimo.
	var chapters: Array = []
	for index: int in range(1_189):
		chapters.append("B%02d:%d" % [index / 19, index % 19 + 1])
	var complete_bible_save: Dictionary = GameState.get_save_data()
	complete_bible_save.estudo.progresso.capitulosLidos = chapters
	var complete_bible_ok: bool = bool(CloudSaveValidator.validate_save_data(complete_bible_save, true).get("ok", false))
	chapters.append("B99:1")
	for index: int in range(11):
		chapters.append("C%02d:1" % index)
	var oversized_bible_rejected: bool = not bool(CloudSaveValidator.validate_save_data(complete_bible_save, true).get("ok", false))
	var bible_limit_ok: bool = complete_bible_ok and oversized_bible_rejected
	ok = ok and bible_limit_ok

	# Exercita duas promocoes consecutivas: main e .bak devem usar caminhos
	# absolutos, sem tocar save/auth reais.
	var test_path: String = "user://cloud_smoke_test/atomic.json"
	CloudAtomicFile.remove_family(test_path)
	var first_write: bool = CloudAtomicFile.write_text(test_path, "{\"revision\":1}", true)
	var second_write: bool = CloudAtomicFile.write_text(test_path, "{\"revision\":2}", true)
	var atomic_ok: bool = first_write and second_write \
		and CloudAtomicFile.read_text(test_path) == "{\"revision\":2}" \
		and CloudAtomicFile.read_text(test_path + ".bak") == "{\"revision\":1}"
	ok = ok and atomic_ok
	CloudAtomicFile.remove_family(test_path)
	DirAccess.remove_absolute("user://cloud_smoke_test")

	# LiveOps preserva o balanceamento embutido, rejeita payloads fora do
	# contrato e nunca usa o cache real durante os smoke tests.
	var first_segment: Dictionary = LiveOps.growth_segments()[0] as Dictionary
	var liveops_defaults_ok: bool = is_equal_approx(float(first_segment.rate), 1.11) \
		and int(first_segment.maxQuantity) == 300 \
		and LiveOps.prophet_unlock_quantity() == 25 \
		and is_equal_approx(LiveOps.prophet_speed_multiplier(), 0.8) \
		and is_equal_approx(LiveOps.offline_cap_seconds(), 8.0 * 3600.0) \
		and LiveOps.video_gems() == 5 \
		and LiveOps.offline_triple_gem_cost() == 3 \
		and LiveOps.nova_star_daily_gems() == 2 \
		and not LiveOps.general_milestones().is_empty()
	var liveops_envelope := _make_liveops_envelope()
	var liveops_validation_result: Dictionary = LiveOps.smoke_validate(liveops_envelope)
	var liveops_validation_ok: bool = bool(liveops_validation_result.get("ok", false))
	if not liveops_validation_ok:
		print("[CLOUD] validacao LiveOps rejeitada: ", liveops_validation_result)
	var invalid_liveops := liveops_envelope.duplicate(true)
	invalid_liveops.config.economy.growthSegments = [{"maxQuantity": 0, "rate": 1.0}]
	var liveops_rejects_invalid: bool = not bool(LiveOps.smoke_validate(invalid_liveops).get("ok", false))
	var zero_free_reward := liveops_envelope.duplicate(true)
	zero_free_reward.campaigns[0].effects.freeGemRewardMultiplier = 0.0
	var liveops_accepts_zero_reward: bool = bool(LiveOps.smoke_validate(zero_free_reward).get("ok", false))
	var oversized_free_reward := liveops_envelope.duplicate(true)
	oversized_free_reward.campaigns[0].effects.freeGemRewardMultiplier = 100.01
	var liveops_rejects_oversized_reward: bool = not bool(LiveOps.smoke_validate(oversized_free_reward).get("ok", false))
	var historical_versions := liveops_envelope.duplicate(true)
	historical_versions.campaigns[0].endsAt = 150
	var replacement: Dictionary = historical_versions.campaigns[0].duplicate(true)
	replacement.versionId = "campaign-smoke-v2"
	replacement.version = 2
	replacement.startsAt = 150
	replacement.endsAt = 200
	historical_versions.campaigns.append(replacement)
	var liveops_accepts_version_history: bool = bool(
		LiveOps.smoke_validate(historical_versions).get("ok", false)
	)
	var duplicate_version := historical_versions.duplicate(true)
	duplicate_version.campaigns[1].versionId = "campaign-smoke-v1"
	var liveops_rejects_duplicate_version: bool = not bool(
		LiveOps.smoke_validate(duplicate_version).get("ok", false)
	)

	var liveops_cache_path := "user://liveops_smoke/config.json"
	CloudAtomicFile.remove_family(liveops_cache_path)
	var cache_result: Dictionary = LiveOps.smoke_cache_roundtrip(liveops_cache_path, liveops_envelope)
	var cached_envelope: Dictionary = cache_result.get("envelope", {}) as Dictionary
	var liveops_cache_ok: bool = bool(cache_result.get("ok", false)) \
		and str(cached_envelope.get("versionId", "")) == "liveops-smoke-v1"
	CloudAtomicFile.remove_family(liveops_cache_path)
	DirAccess.remove_absolute("user://liveops_smoke")

	LiveOps.smoke_apply(liveops_envelope, 99.0)
	var boundary_before: bool = LiveOps.active_campaign_names().is_empty()
	LiveOps.smoke_apply(liveops_envelope, 100.0)
	var boundary_start: bool = LiveOps.active_campaign_names() == ["Campanha Smoke"]
	LiveOps.smoke_apply(liveops_envelope, 199.0)
	var boundary_inside: bool = LiveOps.active_campaign_names() == ["Campanha Smoke"]
	LiveOps.smoke_apply(liveops_envelope, 200.0)
	var boundary_end: bool = LiveOps.active_campaign_names().is_empty()
	var liveops_boundaries_ok: bool = boundary_before and boundary_start and boundary_inside and boundary_end
	var weighted_generator_one := LiveOps.offline_weighted_multiplier(50.0, 250.0, 1)
	var weighted_generator_two := LiveOps.offline_weighted_multiplier(50.0, 250.0, 2)
	var liveops_offline_ok: bool = is_equal_approx(weighted_generator_one, 6.5) \
		and is_equal_approx(weighted_generator_two, 3.5)
	LiveOps.smoke_reset()
	var liveops_ok: bool = liveops_defaults_ok and liveops_validation_ok \
		and liveops_rejects_invalid and liveops_accepts_zero_reward \
		and liveops_rejects_oversized_reward and liveops_accepts_version_history \
		and liveops_rejects_duplicate_version and liveops_cache_ok \
		and liveops_boundaries_ok and liveops_offline_ok
	ok = ok and liveops_ok

	# `.invalid` falha localmente e nunca aguarda DNS/rede.
	var api := CloudApi.new()
	add_child(api)
	await get_tree().process_frame
	api.base_url = "https://api.example.invalid/v1"
	var started: int = Time.get_ticks_msec()
	var response: Dictionary = await api.send_json(HTTPClient.METHOD_GET, "health")
	var placeholder_ok: bool = str(response.get("networkError", "")) == "INVALID_API_URL" \
		and Time.get_ticks_msec() - started < 500
	ok = ok and placeholder_ok

	var bootstrap: Dictionary = await CloudSave.bootstrap(3.0)
	var isolation_ok: bool = str(bootstrap.get("source", "")) == "disabled" \
		and CloudIdentity.is_ephemeral() \
		and CloudSave.state() == CloudSave.STATE_DISABLED
	ok = ok and isolation_ok

	print("[CLOUD] canonical=", canonical_ok, " uuid=", uuid_ok, " biblia=", bible_limit_ok, " atomic=", atomic_ok)
	print("[CLOUD] liveops defaults=", liveops_defaults_ok, " validation=", liveops_validation_ok and liveops_rejects_invalid \
		and liveops_accepts_zero_reward and liveops_rejects_oversized_reward \
		and liveops_accepts_version_history and liveops_rejects_duplicate_version, \
		" cache=", liveops_cache_ok, " boundaries=", liveops_boundaries_ok, " offline=", liveops_offline_ok)
	print("[CLOUD] placeholder=", placeholder_ok, " isolation=", isolation_ok)
	print("=== CLOUD SMOKE TEST ", ("PASS" if ok else "FAIL"), " ===")
	get_tree().quit(0 if ok else 1)


func _make_liveops_envelope() -> Dictionary:
	return {
		"schemaVersion": LiveOps.SCHEMA_VERSION,
		"revision": 7,
		"versionId": "liveops-smoke-v1",
		"publishedAt": 90,
		"serverNow": 150,
		"config": LiveOps.DEFAULT_CONFIG.duplicate(true),
		"campaigns": [{
			"id": "campaign-smoke",
			"key": "smoke",
			"versionId": "campaign-smoke-v1",
			"version": 1,
			"name": "Campanha Smoke",
			"startsAt": 100,
			"endsAt": 200,
			"publishedAt": 90,
			"effects": {
				"globalProductionMultiplier": 2.0,
				"offlineProductionMultiplier": 3.0,
				"manualProductionMultiplier": 4.0,
				"studyFaithMultiplier": 5.0,
				"freeGemRewardMultiplier": 2.0,
				"generatorProductionMultipliers": {"1": 2.0},
			},
		}],
	}

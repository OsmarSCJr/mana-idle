class_name CloudSaveValidator
extends RefCounted

const MAX_PAYLOAD_BYTES: int = 65_536
const MAX_DEPTH: int = 12
const MAX_ARRAY_ITEMS: int = 2_048
const MAX_READ_CHAPTERS: int = 1_200
const MAX_BOOKMARKS: int = 256
const MAX_STRING_LENGTH: int = 512


static func canonicalize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var source: Dictionary = value
			var keys: Array = source.keys()
			keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
			var normalized: Dictionary = {}
			for key: Variant in keys:
				normalized[str(key)] = canonicalize(source[key])
			return normalized
		TYPE_ARRAY:
			var normalized_array: Array = []
			for item: Variant in value:
				normalized_array.append(canonicalize(item))
			return normalized_array
		_:
			return value


static func compact_json(data: Dictionary) -> String:
	return JSON.stringify(canonicalize(data))


static func sha256_text(contents: String) -> String:
	var context: HashingContext = HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if context.update(contents.to_utf8_buffer()) != OK:
		return ""
	return context.finish().hex_encode()


static func make_uuid_v4() -> String:
	var crypto: Crypto = Crypto.new()
	var bytes: PackedByteArray = crypto.generate_random_bytes(16)
	if bytes.size() != 16:
		return ""
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex: String = bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12),
	]


static func parse_payload(payload_json: String, expected_sha256: String = "", require_current_version: bool = true) -> Dictionary:
	var payload_bytes: int = payload_json.to_utf8_buffer().size()
	if payload_bytes <= 0 or payload_bytes > MAX_PAYLOAD_BYTES:
		return _invalid("PAYLOAD_SIZE", "O save excede o limite seguro de 64 KiB.")
	var actual_sha256: String = sha256_text(payload_json)
	if actual_sha256.is_empty():
		return _invalid("HASH_FAILED", "Nao foi possivel verificar o save.")
	if not expected_sha256.is_empty() and actual_sha256.to_lower() != expected_sha256.to_lower():
		return _invalid("HASH_MISMATCH", "A verificacao de integridade do save falhou.")
	var parser: JSON = JSON.new()
	if parser.parse(payload_json) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return _invalid("INVALID_JSON", "O save recebido nao e um JSON valido.")
	var data: Dictionary = (parser.data as Dictionary).duplicate(true)
	var validation: Dictionary = validate_save_data(data, require_current_version)
	if not bool(validation.get("ok", false)):
		return validation
	return {
		"ok": true,
		"data": data,
		"sha256": actual_sha256,
		"bytes": payload_bytes,
	}


static func validate_save_data(data: Dictionary, require_current_version: bool = true) -> Dictionary:
	var version: int = int(data.get("version", 0 if require_current_version else 1))
	if require_current_version and version != GameState.SAVE_VERSION:
		return _invalid("SAVE_VERSION", "A versao do save nao e compativel com este aplicativo.")
	if not require_current_version and (version < 1 or version > GameState.SAVE_VERSION):
		return _invalid("SAVE_VERSION", "A versao do save local nao e suportada.")

	var shape_error: String = _validate_shape(data, 0)
	if not shape_error.is_empty():
		return _invalid("INVALID_SHAPE", shape_error)

	for field: String in ["fe", "feTotalVida", "feTotalHistorica", "graca", "gloria", "gracaTotal", "gloriaTotal", "novaStarLastGemClaim"]:
		if not _is_non_negative_number(data.get(field, 0.0)):
			return _invalid("INVALID_VALUE", "O campo %s possui valor invalido." % field)
	for field: String in ["santos", "santosGastos", "reliquias", "gemas", "gemasTotal", "dadivaFrutosNivel"]:
		if int(data.get(field, 0)) < 0:
			return _invalid("INVALID_VALUE", "O campo %s nao pode ser negativo." % field)
	for ledger_name: String in ["marcosLedger", "moedaMarcosLedger"]:
		var ledger: Variant = data.get(ledger_name, {})
		if ledger is not Dictionary or (ledger as Dictionary).size() > 8:
			return _invalid("INVALID_LEDGER", "O registro %s e invalido." % ledger_name)
		for ledger_key: Variant in (ledger as Dictionary):
			if not GameState.ADVENTURES.has(str(ledger_key)) \
					or (ledger as Dictionary)[ledger_key] is not Array \
					or ((ledger as Dictionary)[ledger_key] as Array).size() > 64:
				return _invalid("INVALID_LEDGER", "O registro %s contem entrada invalida." % ledger_name)
	var active_cosmetics: Variant = data.get("cosmeticosAtivos", {})
	if active_cosmetics is not Dictionary or (active_cosmetics as Dictionary).size() > 16:
		return _invalid("INVALID_COSMETICS", "Os cosmeticos ativos sao invalidos.")

	var generators: Variant = data.get("geradores", {})
	if generators is not Dictionary or (generators as Dictionary).size() > 36:
		return _invalid("INVALID_GENERATORS", "A lista de geradores e invalida.")
	for generator_key: Variant in (generators as Dictionary):
		var generator_id: int = int(str(generator_key))
		if generator_id < 1 or generator_id > 36:
			return _invalid("INVALID_GENERATOR_ID", "O save contem um gerador desconhecido.")
		var generator_state: Variant = (generators as Dictionary)[generator_key]
		if generator_state is not Dictionary:
			return _invalid("INVALID_GENERATOR", "O estado de um gerador e invalido.")
		if int((generator_state as Dictionary).get("qtd", 0)) < 0:
			return _invalid("INVALID_GENERATOR", "A quantidade de gerador nao pode ser negativa.")
		if not _is_finite_number((generator_state as Dictionary).get("tempo_restante", -1.0)):
			return _invalid("INVALID_GENERATOR", "O tempo de um gerador e invalido.")
		if float((generator_state as Dictionary).get("tempo_restante", -1.0)) < -1.0:
			return _invalid("INVALID_GENERATOR", "O tempo de um gerador nao pode ser menor que -1.")

	var known_arrays: Dictionary = {
		"upgradesComprados": 512,
		"dadivasCompradas": 32,
		"aventurasDesbloqueadas": 8,
		"aventurasConcluidas": 8,
		"cosmeticosComprados": 128,
	}
	for array_name: String in known_arrays:
		var array_value: Variant = data.get(array_name, [])
		if array_value is not Array or (array_value as Array).size() > int(known_arrays[array_name]):
			return _invalid("INVALID_ARRAY", "A lista %s e invalida." % array_name)
		if not _has_unique_strings(array_value as Array):
			return _invalid("DUPLICATE_ID", "A lista %s contem itens repetidos." % array_name)

	for upgrade_id: Variant in data.get("upgradesComprados", []):
		if Upgrades.get_data(str(upgrade_id)).is_empty():
			return _invalid("UNKNOWN_ID", "O save contem uma bencao desconhecida.")
	for gift_id: Variant in data.get("dadivasCompradas", []):
		if Dadivas.get_data(str(gift_id)).is_empty():
			return _invalid("UNKNOWN_ID", "O save contem uma dadiva desconhecida.")
	for cosmetic_id: Variant in data.get("cosmeticosComprados", []):
		if Cosmeticos.get_data(str(cosmetic_id)).is_empty():
			return _invalid("UNKNOWN_ID", "O save contem um cosmetico desconhecido.")
	for adventure_id: Variant in data.get("aventurasDesbloqueadas", []):
		if not GameState.ADVENTURES.has(str(adventure_id)):
			return _invalid("UNKNOWN_ID", "O save contem uma aventura desconhecida.")
	for adventure_id: Variant in data.get("aventurasConcluidas", []):
		if not GameState.ADVENTURES.has(str(adventure_id)):
			return _invalid("UNKNOWN_ID", "O save contem uma aventura desconhecida.")
	var active_adventure := str(data.get("activeAdventure", ""))
	if not GameState.ADVENTURES.has(active_adventure):
		return _invalid("UNKNOWN_ID", "A campanha ativa e desconhecida.")
	if active_adventure not in data.get("aventurasDesbloqueadas", []):
		return _invalid("INVALID_ADVENTURE_PROGRESS", "A campanha ativa ainda nao foi desbloqueada.")
	var adventure_progress: Variant = data.get("adventureProgress", {})
	if adventure_progress is not Dictionary or (adventure_progress as Dictionary).size() != GameState.ADVENTURES.size():
		return _invalid("INVALID_ADVENTURE_PROGRESS", "Os estados de campanha sao invalidos.")
	for adventure_id: String in GameState.ADVENTURES:
		var progress: Variant = (adventure_progress as Dictionary).get(adventure_id)
		if progress is not Dictionary:
			return _invalid("INVALID_ADVENTURE_PROGRESS", "Uma campanha nao possui estado proprio.")
		for number_key: String in ["prestige", "prestige_spent", "fruit_level", "prestiges"]:
			if int((progress as Dictionary).get(number_key, -1)) < 0:
				return _invalid("INVALID_ADVENTURE_PROGRESS", "Um recurso de campanha e invalido.")
		if not _is_non_negative_number((progress as Dictionary).get("run_total", -1.0)):
			return _invalid("INVALID_ADVENTURE_PROGRESS", "O total da campanha e invalido.")
		for array_key: String in ["upgrades", "gifts"]:
			var entries: Variant = (progress as Dictionary).get(array_key, [])
			if entries is not Array or (entries as Array).size() > (512 if array_key == "upgrades" else 32) \
					or not _has_unique_strings(entries as Array):
				return _invalid("INVALID_ADVENTURE_PROGRESS", "Uma lista de campanha e invalida.")
			for entry_id: Variant in (entries as Array):
				if array_key == "upgrades" and Upgrades.get_data(str(entry_id)).is_empty():
					return _invalid("UNKNOWN_ID", "Uma campanha contem uma bencao desconhecida.")
				if array_key == "gifts" and Dadivas.get_data(str(entry_id)).is_empty():
					return _invalid("UNKNOWN_ID", "Uma campanha contem uma dadiva desconhecida.")
		for map_key: String in ["boosts", "boost_inventory"]:
			var boost_map: Variant = (progress as Dictionary).get(map_key, {})
			if boost_map is not Dictionary or (boost_map as Dictionary).size() > GameState.BOOSTS.size():
				return _invalid("INVALID_ADVENTURE_PROGRESS", "Um inventario de campanha e invalido.")
			for boost_id: Variant in (boost_map as Dictionary):
				var amount: Variant = (boost_map as Dictionary)[boost_id]
				if not GameState.BOOSTS.has(str(boost_id)) \
						or (map_key == "boosts" and not _is_non_negative_number(amount)) \
						or (map_key == "boost_inventory" and int(amount) < 0):
					return _invalid("INVALID_ADVENTURE_PROGRESS", "Uma campanha contem um impulso invalido.")

	var study: Variant = data.get("estudo", {})
	if study is not Dictionary:
		return _invalid("INVALID_STUDY", "O progresso de estudo e invalido.")
	var progress: Variant = (study as Dictionary).get("progresso", {})
	if progress is not Dictionary:
		return _invalid("INVALID_STUDY", "O progresso de leitura e invalido.")
	var read_chapters: Variant = (progress as Dictionary).get("capitulosLidos", [])
	var bookmarks: Variant = (progress as Dictionary).get("marcadores", [])
	if read_chapters is not Array or (read_chapters as Array).size() > MAX_READ_CHAPTERS \
			or not _has_unique_strings(read_chapters as Array):
		return _invalid("INVALID_STUDY", "A lista de capitulos lidos e invalida.")
	if bookmarks is not Array or (bookmarks as Array).size() > MAX_BOOKMARKS \
			or not _has_unique_strings(bookmarks as Array):
		return _invalid("INVALID_STUDY", "A lista de marcadores e invalida.")
	for knowledge_list_name: String in ["conhecimentosComprados", "conhecimentosAtivos"]:
		var knowledge_list: Variant = (study as Dictionary).get(knowledge_list_name, [])
		if knowledge_list is not Array or not _has_unique_strings(knowledge_list as Array):
			return _invalid("INVALID_STUDY", "A lista de conhecimentos e invalida.")
		for knowledge_id: Variant in knowledge_list:
			if Conhecimentos.get_data(str(knowledge_id)).is_empty():
				return _invalid("UNKNOWN_ID", "O save contem um conhecimento desconhecido.")

	var boosts: Variant = data.get("boosts", {})
	var inventory: Variant = data.get("boostInventory", {})
	if boosts is not Dictionary or inventory is not Dictionary:
		return _invalid("INVALID_BOOST", "O inventario de impulsos e invalido.")
	for boost_id: Variant in (boosts as Dictionary):
		if not GameState.BOOSTS.has(str(boost_id)) or not _is_non_negative_number((boosts as Dictionary)[boost_id]):
			return _invalid("INVALID_BOOST", "O save contem um impulso invalido.")
	for boost_id: Variant in (inventory as Dictionary):
		if not GameState.BOOSTS.has(str(boost_id)) or int((inventory as Dictionary)[boost_id]) < 0:
			return _invalid("INVALID_BOOST", "O inventario contem um impulso invalido.")
	return {"ok": true}


static func is_significant(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	if float(data.get("fe", GameState.FE_INICIAL)) > GameState.FE_INICIAL + 0.001:
		return true
	for field: String in ["santos", "reliquias", "gemas"]:
		if int(data.get(field, 0)) > 0:
			return true
	for field: String in ["upgradesComprados", "dadivasCompradas", "aventurasConcluidas"]:
		if data.get(field, []) is Array and not (data.get(field, []) as Array).is_empty():
			return true
	var generators: Variant = data.get("geradores", {})
	if generators is Dictionary:
		for state: Variant in (generators as Dictionary).values():
			if state is Dictionary and int((state as Dictionary).get("qtd", 0)) > 0:
				return true
	var study: Variant = data.get("estudo", {})
	if study is Dictionary:
		if int((study as Dictionary).get("sabedoria", 0)) > 0:
			return true
		for knowledge_key: String in ["conhecimentosComprados", "conhecimentosAtivos"]:
			var knowledge_list: Variant = (study as Dictionary).get(knowledge_key, [])
			if knowledge_list is Array and not (knowledge_list as Array).is_empty():
				return true
		var progress: Variant = (study as Dictionary).get("progresso", {})
		if progress is Dictionary:
			for progress_key: String in ["leiturasConcluidas", "questoesCorretas", "recompensasResgatadas", "capitulosLidos", "marcadores"]:
				var progress_list: Variant = (progress as Dictionary).get(progress_key, [])
				if progress_list is Array and not (progress_list as Array).is_empty():
					return true
	return false


static func _validate_shape(value: Variant, depth: int) -> String:
	if depth > MAX_DEPTH:
		return "O save possui profundidade excessiva."
	match typeof(value):
		TYPE_DICTIONARY:
			for key: Variant in (value as Dictionary):
				if str(key).length() > 96:
					return "O save possui uma chave muito longa."
				var child_error: String = _validate_shape((value as Dictionary)[key], depth + 1)
				if not child_error.is_empty():
					return child_error
		TYPE_ARRAY:
			if (value as Array).size() > MAX_ARRAY_ITEMS:
				return "O save possui uma lista grande demais."
			for item: Variant in (value as Array):
				var child_error: String = _validate_shape(item, depth + 1)
				if not child_error.is_empty():
					return child_error
		TYPE_STRING:
			if (value as String).length() > MAX_STRING_LENGTH:
				return "O save possui um texto grande demais."
		TYPE_FLOAT:
			if is_nan(value as float) or is_inf(value as float):
				return "O save possui um numero nao finito."
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			pass
		_:
			return "O save possui um tipo nao serializavel."
	return ""


static func _has_unique_strings(values: Array) -> bool:
	var seen: Dictionary = {}
	for value: Variant in values:
		var normalized: String = str(value)
		if normalized.is_empty() or seen.has(normalized):
			return false
		seen[normalized] = true
	return true


static func _is_finite_number(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return not is_nan(number) and not is_inf(number)


static func _is_non_negative_number(value: Variant) -> bool:
	return _is_finite_number(value) and float(value) >= 0.0


static func _invalid(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}

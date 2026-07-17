extends Node

func _enter_tree() -> void:
	SaveSystem.set_persistence_enabled(false)

func _ready() -> void:
	await get_tree().process_frame
	var ok := true
	GameState._init_geradores()
	GameState.cosmeticos_comprados = [
		"retratos_iluminados_era1", "moldura_arca", "moldura_templo",
		"efeito_pombas", "tema_leitor_pergaminho",
	]
	GameState.cosmeticos_ativos = {
		"retrato": "retratos_iluminados_era1",
		"moldura": "moldura_arca",
		"efeito": "efeito_pombas",
		"tema_leitor": "tema_leitor_pergaminho",
	}

	var item := GeradorItem.new()
	item.setup(1)
	item.set_icon_texture(GameArt.generator_icon(1))
	item.set_prophet_texture(GameArt.automation_portrait(1))
	add_child(item)
	await get_tree().process_frame
	var frame: TextureRect = item.get("_cosmetic_frame")
	var prophet_button: Button = item.get("_prophet_btn")
	var portraits_ok := prophet_button.icon == GameArt.illuminated_era1_portrait(1)
	var ark_ok := frame.visible and frame.texture == GameArt.cosmetic_preview("moldura_arca")
	GameState.cosmeticos_ativos.moldura = "moldura_templo"
	EventBus.cosmetic_changed.emit()
	await get_tree().process_frame
	var temple_ok := frame.texture == GameArt.cosmetic_preview("moldura_templo")

	var reader := BibleReaderPanel.new()
	add_child(reader)
	await get_tree().process_frame
	var ornament: TextureRect = reader.get("_theme_ornament")
	var reader_ok := ornament.visible
	GameState.cosmeticos_ativos.erase("tema_leitor")
	EventBus.cosmetic_changed.emit()
	await get_tree().process_frame
	reader_ok = reader_ok and not ornament.visible

	var effects := CosmeticEffectLayer.new()
	add_child(effects)
	var first_effect := effects.play_doves(Vector2(400, 500))
	var second_effect := effects.play_doves(Vector2(400, 500))
	var doves_ok := first_effect and not second_effect and effects.get_child_count() == 1

	ok = portraits_ok and ark_ok and temple_ok and reader_ok and doves_ok
	print("[COSMETICS] retratos=", portraits_ok, " arca=", ark_ok, " templo=", temple_ok)
	print("[COSMETICS] leitor=", reader_ok, " pombas=", doves_ok)
	print("=== COSMETIC SMOKE TEST ", ("PASS" if ok else "FAIL"), " ===")
	get_tree().quit(0 if ok else 1)

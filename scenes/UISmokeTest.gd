extends Node


func _enter_tree() -> void:
	# Precisa ocorrer antes de Main._ready(), que normalmente carrega user://save.json.
	SaveSystem.set_persistence_enabled(false)


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var main := get_node_or_null("Main")
	var ok := main != null
	var item_count := 0
	var tab_count := 0
	var adventure_count := 0
	var boost_space_ok := false
	var fast_cycle_ok := false
	if main != null:
		var items: Dictionary = main.get("_items")
		var tabs: Dictionary = main.get("_tab_buttons")
		var adventures: Dictionary = main.get("_adventure_buttons")
		var study_panel: Variant = main.get("_panel_estudo")
		item_count = items.size()
		tab_count = tabs.size()
		adventure_count = adventures.size()
		ok = ok and item_count == 36
		ok = ok and tab_count == 4
		ok = ok and adventure_count == 3
		ok = ok and study_panel != null
		ok = ok and study_panel.get("_bible_reader") != null

		var boost_space: Control = main.get("_future_boost_space")
		boost_space_ok = boost_space != null \
			and boost_space.get_class() == "Control" \
			and is_equal_approx(boost_space.custom_minimum_size.x, 214.0) \
			and boost_space.get_child_count() == 0
		ok = ok and boost_space_ok

		# Valida o modo estável na nova faixa abaixo de 1100 ms e sua reversão.
		var first_item: GeradorItem = items.get(2)
		GameState.geradores[1] = {"qtd": 1, "tem_profeta": false, "tempo_restante": -1.0}
		GameState.geradores[2] = {"qtd": 200, "tem_profeta": true, "tempo_restante": 0.2}
		Economy._tempo_gen[2] = 0.25 # 3,9 s × 0,25 = 0,975 s
		first_item.update()
		first_item.update_progress()
		var fast_bar: ProgressBar = first_item.get("_progress_bar")
		var fast_wave: Control = first_item.get("_fast_cycle_wave")
		fast_cycle_ok = bool(first_item.get("_fast_cycle_active")) \
			and is_equal_approx(fast_bar.value, 1.0) \
			and fast_wave.visible
		# O save pode ativar o modo antes de o card entrar na árvore; a onda deve
		# preservar esse estado quando seu _ready() for executado.
		var pre_tree_item := GeradorItem.new()
		pre_tree_item.setup(2)
		pre_tree_item.set_modo("x1")
		var active_before_tree := bool(pre_tree_item.get("_fast_cycle_active"))
		add_child(pre_tree_item)
		await get_tree().process_frame
		var pre_tree_wave: Control = pre_tree_item.get("_fast_cycle_wave")
		fast_cycle_ok = fast_cycle_ok and active_before_tree and pre_tree_wave.visible
		pre_tree_item.queue_free()
		Economy._tempo_gen.erase(2)
		first_item.update_progress()
		fast_cycle_ok = fast_cycle_ok \
			and not bool(first_item.get("_fast_cycle_active")) \
			and not fast_wave.visible
		ok = ok and fast_cycle_ok
	print("[UI] geradores=", item_count, " abas=", tab_count, " aventuras=", adventure_count)
	print("[UI] boost_vazio=", boost_space_ok, " ciclo_rapido=", fast_cycle_ok)
	print("=== UI SMOKE TEST ", ("PASS" if ok else "FAIL"), " ===")
	get_tree().quit(0 if ok else 1)

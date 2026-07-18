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
	var cloud_ui_ok := false
	var cloud_scroll_ok := false
	var special_cosmetics_ok := false
	var santos_mobile_ok := false
	var all_tabs_mobile_ok := false
	var milestone_buyer_ok := false
	if main != null:
		var items: Dictionary = main.get("_items")
		var tabs: Dictionary = main.get("_tab_buttons")
		var adventures: Dictionary = main.get("_adventure_buttons")
		var study_panel: Variant = main.get("_panel_estudo")
		item_count = items.size()
		tab_count = tabs.size()
		adventure_count = adventures.size()
		ok = ok and item_count == 36
		ok = ok and tab_count == 5
		ok = ok and adventure_count == 3
		ok = ok and study_panel != null
		ok = ok and study_panel.get("_bible_reader") != null

		var boost_space: Control = main.get("_future_boost_space")
		var boost_buttons: Dictionary = main.get("_boost_buttons")
		var adventure_icons: Dictionary = main.get("_adventure_icons")
		boost_space_ok = boost_space != null \
			and boost_space is VBoxContainer \
			and is_equal_approx(boost_space.custom_minimum_size.x, 238.0) \
			and boost_space.get_child_count() >= 2 \
			and boost_buttons.size() == GameState.BOOSTS.size() \
			and adventure_icons.size() == 2
		ok = ok and boost_space_ok

		# A gestão cloud fica nas Configurações, sem criar uma sexta aba de jogo.
		main.call("_show_settings")
		await get_tree().process_frame
		cloud_ui_ok = _tree_has_text(main, "Conta de Peregrino") \
			and CloudSave.state() == CloudSave.STATE_DISABLED \
			and not CloudIdentity.installation_id().is_empty()
		ok = ok and cloud_ui_ok
		var cloud_parts: Dictionary = main.call("_create_cloud_popup", "Teste de toque")
		var cloud_popup: PopupPanel = cloud_parts.popup
		var cloud_content: VBoxContainer = cloud_parts.content
		var dynamic_cloud_button := Button.new()
		cloud_content.add_child(dynamic_cloud_button)
		var cloud_scroll := _find_scroll_container(cloud_popup)
		cloud_scroll_ok = cloud_scroll != null \
			and cloud_scroll.scroll_deadzone == 12 \
			and dynamic_cloud_button.mouse_filter == Control.MOUSE_FILTER_PASS
		cloud_popup.queue_free()
		ok = ok and cloud_scroll_ok

		# A aba Santos precisa manter os cartoes dentro da largura util e deixar
		# o gesto de arrasto atravessar inclusive filhos criados dinamicamente.
		main.call("_show_tab", "santos")
		await get_tree().process_frame
		await get_tree().process_frame
		var santos_panel: Control = main.get("_panel_santos")
		var santos_scroll := _find_scroll_container(santos_panel)
		var frutos_button: Button = main.get("_frutos_btn")
		if santos_scroll != null and santos_scroll.get_child_count() == 1:
			var scroll_content: Control = santos_scroll.get_child(0)
			santos_mobile_ok = santos_scroll.scroll_deadzone == 12 \
				and santos_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED \
				and scroll_content.size.x <= santos_scroll.size.x + 1.0 \
				and not _tree_blocks_touch_scroll(scroll_content) \
				and frutos_button.get_parent() is VBoxContainer
		ok = ok and santos_mobile_ok

		# Faz a mesma auditoria nas cinco abas e nas duas modalidades de rolagem
		# de Estudos. Listas verticais nao podem crescer para os lados nem reter
		# o toque; a arvore de Conhecimentos deve preservar o pan horizontal.
		var panel_by_tab := {
			"geradores": main.get("_panel_geradores"),
			"milagres": main.get("_panel_milagres"),
			"estudo": study_panel,
			"santos": santos_panel,
			"gemas": main.get("_panel_gemas"),
		}
		all_tabs_mobile_ok = true
		for tab_id: String in panel_by_tab:
			main.call("_show_tab", tab_id)
			await get_tree().process_frame
			var active_panel: Control = panel_by_tab[tab_id]
			all_tabs_mobile_ok = all_tabs_mobile_ok \
				and active_panel.get_combined_minimum_size().x <= active_panel.size.x + 1.0 \
				and _scroll_tree_is_mobile_safe(active_panel)
		study_panel.show_section("knowledge")
		await get_tree().process_frame
		var knowledge_view: Control = study_panel.get("_knowledge_view")
		var knowledge_scroll := _find_scroll_container(knowledge_view)
		all_tabs_mobile_ok = all_tabs_mobile_ok \
			and knowledge_scroll != null \
			and knowledge_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO \
			and not _tree_blocks_touch_scroll(knowledge_scroll.get_child(0))
		study_panel.show_section("studies")
		ok = ok and all_tabs_mobile_ok
		main.call("_show_tab", "geradores")
		await get_tree().process_frame

		# A Dadiva exibe uma faixa fixa acima da lista, sem criar largura lateral.
		GameState.dadivas_compradas.append("d_comprador_marcos")
		GameState.geradores[1].qtd = 24
		GameState.fe = Economy.custo_lote(1, 1, 24)
		main.call("_update_all")
		await get_tree().process_frame
		var buyer_strip: PanelContainer = main.get("_milestone_buyer_strip")
		var buyer_button: Button = main.get("_milestone_buyer_button")
		milestone_buyer_ok = buyer_strip != null and buyer_strip.visible \
			and buyer_button != null and not buyer_button.disabled \
			and buyer_strip.get_combined_minimum_size().x <= buyer_strip.size.x + 1.0
		ok = ok and milestone_buyer_ok

		# Valida o modo estável na nova faixa abaixo de 1100 ms e sua reversão.
		var first_item: GeradorItem = items.get(2)
		GameState.geradores[1] = {"qtd": 1, "tem_profeta": false, "tempo_restante": -1.0}
		GameState.geradores[2] = {"qtd": 200, "tem_profeta": true, "tempo_restante": 0.2}
		Economy._tempo_gen[2] = 0.1 # 8,0 s × 0,1 = 0,8 s
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

		# Aplica os cinco cosmeticos especiais nos pontos reais da interface.
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
		EventBus.cosmetic_changed.emit()
		await get_tree().process_frame
		var genesis_item: GeradorItem = items.get(1)
		var frame: TextureRect = genesis_item.get("_cosmetic_frame")
		var prophet_button: Button = genesis_item.get("_prophet_btn")
		var reader: BibleReaderPanel = study_panel.get("_bible_reader")
		var ornament: TextureRect = reader.get("_theme_ornament")
		var effect_layer: Control = main.get("_cosmetic_effect_layer")
		main.call("_on_cosmetic_cycle_complete", 1, 1.0)
		special_cosmetics_ok = frame.visible \
			and frame.texture == GameArt.cosmetic_preview("moldura_arca") \
			and prophet_button.icon == GameArt.illuminated_era1_portrait(1) \
			and ornament.visible \
			and effect_layer.get_child_count() == 1
		GameState.cosmeticos_ativos.moldura = "moldura_templo"
		EventBus.cosmetic_changed.emit()
		await get_tree().process_frame
		special_cosmetics_ok = special_cosmetics_ok \
			and frame.texture == GameArt.cosmetic_preview("moldura_templo")
		ok = ok and special_cosmetics_ok
	print("[UI] geradores=", item_count, " abas=", tab_count, " aventuras=", adventure_count)
	print("[UI] lateral=", boost_space_ok, " cloud=", cloud_ui_ok, " cloud_scroll=", cloud_scroll_ok, " ciclo_rapido=", fast_cycle_ok)
	print("[UI] santos_mobile=", santos_mobile_ok)
	print("[UI] todas_as_abas_mobile=", all_tabs_mobile_ok)
	print("[UI] comprador_de_marcos=", milestone_buyer_ok)
	print("[UI] cosmeticos_especiais=", special_cosmetics_ok)
	print("=== UI SMOKE TEST ", ("PASS" if ok else "FAIL"), " ===")
	get_tree().quit(0 if ok else 1)


func _tree_has_text(node: Node, expected: String) -> bool:
	if node is Label and expected in (node as Label).text:
		return true
	if node is Button and expected in (node as Button).text:
		return true
	for child: Node in node.get_children():
		if _tree_has_text(child, expected):
			return true
	return false


func _find_scroll_container(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node
	for child: Node in node.get_children():
		var found := _find_scroll_container(child)
		if found != null:
			return found
	return null


func _tree_blocks_touch_scroll(node: Node) -> bool:
	if node is Control and node.mouse_filter == Control.MOUSE_FILTER_STOP:
		return true
	for child: Node in node.get_children():
		if _tree_blocks_touch_scroll(child):
			return true
	return false


func _scroll_tree_is_mobile_safe(node: Node) -> bool:
	if node is ScrollContainer:
		var scroll := node as ScrollContainer
		if scroll.scroll_deadzone != 12:
			return false
		for child: Node in scroll.get_children():
			if _tree_blocks_touch_scroll(child):
				return false
			if scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED \
				and child is Control \
				and (child as Control).size.x > scroll.size.x + 1.0:
				return false
	for child: Node in node.get_children():
		if not _scroll_tree_is_mobile_safe(child):
			return false
	return true

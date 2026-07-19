extends Node

# Teste automatizado temporario: valida upgrades, dadivas, prestige e economia.
func _ready() -> void:
	SaveSystem.set_persistence_enabled(false)
	await get_tree().process_frame
	var ok := true

	GameState.fe = 1e6
	GameState.fe_total_vida = 0.0
	GameState._init_geradores()
	GameState.upgrades_comprados.clear()
	GameState.dadivas_compradas.clear()
	GameState.cosmeticos_comprados.clear()
	GameState.cosmeticos_ativos.clear()
	Economy.recompute_multiplicadores()

	# 1) Upgrade PROD: requisito atual de 25 Haja Luz, u1_1 (x2)
	GameState.buy_generator(1, 25)
	var mult_antes := Economy.get_gerador_multiplicador(1)
	var comprou_upg := GameState.buy_upgrade("u1_1")
	var mult_depois := Economy.get_gerador_multiplicador(1)
	print("[T1] u1_1 comprado=", comprou_upg, " mult ", mult_antes, " -> ", mult_depois)
	ok = ok and comprou_upg and is_equal_approx(mult_depois, mult_antes * 2.0)

	# 2) Requisito bloqueia: u2_1 requer 10x G2 (temos 0)
	var bloqueado := GameState.buy_upgrade("u2_1")
	print("[T2] u2_1 sem requisito => ", bloqueado, " (esperado false)")
	ok = ok and not bloqueado

	# 3) Upgrade SPEED via era (profeta especial Elias: -25% tempo Era 1)
	GameState.fe_total_vida = 2e8
	GameState.fe = 2e8
	var tempo_antes := Economy.get_tempo_ciclo(1)
	var comprou_elias := GameState.buy_upgrade("pe_elias")
	var tempo_depois := Economy.get_tempo_ciclo(1)
	print("[T3] pe_elias=", comprou_elias, " tempo G1 ", tempo_antes, " -> ", tempo_depois)
	ok = ok and comprou_elias and is_equal_approx(tempo_depois, tempo_antes * 0.75)

	# 4) DISCOUNT via era (Melquisedeque: -10% custo Era 1)
	var custo_antes := Economy.custo_unitario(1, 0)
	var comprou_melq := GameState.buy_upgrade("pe_melquisedeque")
	var custo_depois := Economy.custo_unitario(1, 0)
	print("[T4] pe_melquisedeque=", comprou_melq, " custo G1 ", custo_antes, " -> ", custo_depois)
	ok = ok and comprou_melq and is_equal_approx(custo_depois, custo_antes * 0.9)

	# 5) Unlock x100
	ok = ok and not Economy.is_x100_unlocked()
	GameState.fe = 2e9
	GameState.buy_generator(1, 100)
	var comprou_x100 := GameState.buy_upgrade("u4_4") == false  # requer G4>=100
	print("[T5] u4_4 sem G4 => bloqueado=", comprou_x100)
	ok = ok and comprou_x100

	# 6) Dadiva: da Santos, compra Evangelismo (+25% global)
	GameState.santos = 30
	var global_antes := Economy.get_multiplicador_global()
	var comprou_dad := GameState.buy_dadiva("d_evangelismo")
	var global_depois := Economy.get_multiplicador_global()
	print("[T6] d_evangelismo=", comprou_dad, " santos=", GameState.santos, " global ", global_antes, " -> ", global_depois)
	# O bônus conta santos TOTAIS ganhos (saldo + gastos): investir não reduz.
	# Esperado: (1 + 30*0.02) * 1.25 = 2.0.
	ok = ok and comprou_dad and GameState.santos == 5 and is_equal_approx(global_depois, 2.0)

	# 7) Dadiva offline: Jo I (+50%) e Jo II (teto 16h)
	GameState.santos = 100
	GameState.buy_dadiva("d_jo")
	GameState.buy_dadiva("d_jo2")
	print("[T7] offline_mult=", Economy.get_offline_mult(), " cap_h=", Economy.get_offline_cap() / 3600.0)
	ok = ok and is_equal_approx(Economy.get_offline_mult(), 1.5) and is_equal_approx(Economy.get_offline_cap(), 16.0 * 3600.0)

	# 8) Prestige: upgrades resetam, dadivas ficam
	GameState.fe_total_vida = 1.6e12 # cbrt(1.6e12 / 2e11) = 2 Santos
	var santos_antes := GameState.santos
	var ganhos := GameState.prestige()
	print("[T8] prestige ganhos=", ganhos, " upgrades=", GameState.upgrades_comprados.size(), " dadivas=", GameState.dadivas_compradas.size(), " x100=", Economy.is_x100_unlocked())
	ok = ok and ganhos == 2 and GameState.santos == santos_antes + 2
	ok = ok and GameState.upgrades_comprados.is_empty()
	ok = ok and GameState.dadivas_compradas.size() == 3
	# O prestige remove o bônus de velocidade e restaura o tempo-base vigente.
	ok = ok and is_equal_approx(Economy.get_tempo_ciclo(1), float(Geradores.get_data(1).tempo))

	# 9) Save/load roundtrip preserva dadivas e upgrades
	GameState.fe = 1e6
	GameState.buy_generator(1, 25)
	GameState.buy_upgrade("u1_1")
	var save := GameState.get_save_data()
	GameState._init_geradores()
	GameState.upgrades_comprados = []
	GameState.dadivas_compradas = []
	GameState.load_save_data(save)
	print("[T9] roundtrip: upgrades=", GameState.upgrades_comprados, " dadivas=", GameState.dadivas_compradas.size(), " qtd G1=", GameState.geradores[1].qtd)
	ok = ok and ("u1_1" in GameState.upgrades_comprados) and GameState.dadivas_compradas.size() == 3 and GameState.geradores[1].qtd == 25

	# 10) Upgrades.disponiveis ordenado e sem comprados
	var disp := Upgrades.disponiveis()
	var contem_comprado := false
	for u in disp:
		if u.id in GameState.upgrades_comprados:
			contem_comprado = true
	print("[T10] disponiveis=", disp.size(), " contem comprado=", contem_comprado)
	ok = ok and not contem_comprado

	# 11) Os cinco cosmeticos especiais podem ser comprados e equipados.
	GameState.reliquias = 1000
	var especiais := [
		"retratos_iluminados_era1", "moldura_arca", "moldura_templo",
		"efeito_pombas", "tema_leitor_pergaminho",
	]
	var comprou_especiais := true
	for cosmetic_id in especiais:
		comprou_especiais = GameState.buy_cosmetic(cosmetic_id) and comprou_especiais
	var especiais_ativos := Cosmeticos.is_active("retratos_iluminados_era1") \
		and Cosmeticos.is_active("moldura_templo") \
		and Cosmeticos.is_active("efeito_pombas") \
		and Cosmeticos.is_active("tema_leitor_pergaminho")
	print("[T11] cosmeticos especiais comprados=", comprou_especiais, " ativos=", especiais_ativos)
	ok = ok and comprou_especiais and especiais_ativos
	var cosmetics_save := GameState.get_save_data()
	GameState.cosmeticos_comprados.clear()
	GameState.cosmeticos_ativos.clear()
	GameState.load_save_data(cosmetics_save)
	var cosmetics_roundtrip := especiais.all(func(id: String): return id in GameState.cosmeticos_comprados) \
		and Cosmeticos.is_active("moldura_templo") \
		and Cosmeticos.is_active("tema_leitor_pergaminho")
	print("[T12] cosmeticos especiais roundtrip=", cosmetics_roundtrip)
	ok = ok and cosmetics_roundtrip

	# 13) Aventuras isoladas recebem uma largada unica em sua propria moeda.
	GameState.aventuras_desbloqueadas = ["jornada"]
	GameState.aventuras_concluidas.clear()
	GameState.graca = 0.0
	GameState.graca_total = 0.0
	GameState.gloria = 0.0
	GameState.gloria_total = 0.0
	GameState.fe = 2.0e14
	GameState.fe_total_historica = 2.0e14
	GameState.gemas = 120
	GameState._init_geradores()
	var abriu_cristo := GameState.unlock_adventure("vida_cristo")
	GameState.set_active_adventure("vida_cristo", false)
	var iniciou_cristo := GameState.buy_generator(13, 1)
	var abriu_igreja := GameState.unlock_adventure("igreja_apocalipse")
	GameState.set_active_adventure("igreja_apocalipse", false)
	var iniciou_igreja := GameState.buy_generator(25, 1)
	var aventuras_iniciam := abriu_cristo and iniciou_cristo and abriu_igreja and iniciou_igreja \
		and is_equal_approx(GameState.graca, 6.0) and is_equal_approx(GameState.gloria, 6.0)
	print("[T13] largada aventuras Cristo/Igreja=", aventuras_iniciam)
	ok = ok and aventuras_iniciam
	GameState.set_active_adventure("jornada", false)

	# 14) Saves antigos ja desbloqueados e ainda zerados recebem a mesma largada.
	var legacy_adventure_save := GameState.get_save_data()
	legacy_adventure_save.graca = 0.0
	legacy_adventure_save.gracaTotal = 0.0
	legacy_adventure_save.gloria = 0.0
	legacy_adventure_save.gloriaTotal = 0.0
	legacy_adventure_save.geradores["13"].qtd = 0
	legacy_adventure_save.geradores["25"].qtd = 0
	GameState.load_save_data(legacy_adventure_save)
	var legacy_seeded := is_equal_approx(GameState.graca, 10.0) and is_equal_approx(GameState.gloria, 10.0)
	print("[T14] save antigo recebe moedas iniciais=", legacy_seeded)
	ok = ok and legacy_seeded

	# 15) Marcos individuais e gerais compartilham nove alvos. Cada marco reduz
	# o esforco relativo ate o seguinte ao elevar o multiplicador acumulado.
	var milestones := LiveOps.milestones()
	var general_milestones := LiveOps.general_milestones()
	var milestones_ok := milestones.size() == 9 and general_milestones.size() == 9
	for index in range(milestones.size()):
		var target := int((milestones[index] as Dictionary).quantity)
		milestones_ok = milestones_ok \
			and target == int((general_milestones[index] as Dictionary).quantity) \
			and Economy.next_milestone(target - 1) == target \
			and Economy.milestone_bonus(target) > Economy.milestone_bonus(target - 1)
	milestones_ok = milestones_ok \
		and Economy.next_milestone(int((milestones[-1] as Dictionary).quantity)) \
			== int((milestones[-1] as Dictionary).quantity)
	print("[T15] milestones alinhados e progressivos=", milestones_ok, " total=", milestones.size())
	ok = ok and milestones_ok

	# 16) Dez Santos base equivalem a +20%, inclusive apos concluir Cristo.
	GameState.santos = 10
	GameState.santos_gastos = 0
	GameState.dadivas_compradas.clear()
	GameState.conhecimentos_comprados.clear()
	GameState.conhecimentos_ativos.clear()
	GameState.aventuras_concluidas = ["vida_cristo"]
	Economy.recompute_multiplicadores()
	var santo_dois_pct := is_equal_approx(Economy.get_multiplicador_santos(), 1.2)
	print("[T16] dez Santos em 2% cada=", santo_dois_pct)
	ok = ok and santo_dois_pct

	# 17) A Mordomia custa mais de 100 Santos e persiste como Dadiva permanente.
	GameState.santos = 150
	GameState.santos_gastos = 0
	GameState.dadivas_compradas.clear()
	var comprou_mordomia := GameState.buy_dadiva("d_comprador_marcos")
	var mordomia_save := GameState.get_save_data()
	GameState.dadivas_compradas.clear()
	GameState.load_save_data(mordomia_save)
	var mordomia_persistiu := GameState.has_blessing_buyer()
	print("[T17] mordomia comprada e persistente=", comprou_mordomia and mordomia_persistiu)
	ok = ok and comprou_mordomia and GameState.santos == 0 and mordomia_persistiu

	# 18) O comprador adquire as bencaos liberadas que o saldo alcanca sem
	# comprar unidades dos geradores.
	GameState.aventuras_desbloqueadas = ["jornada"]
	GameState._init_geradores()
	GameState.upgrades_comprados.clear()
	GameState.fe_total_vida = 0.0
	GameState.geradores[1].qtd = 25
	GameState.geradores[2].qtd = 25
	GameState.fe = 505000.0
	var plano_bencaos := GameState.get_blessing_purchase_plan()
	var eventos_lote := {"individuais": 0, "lotes": 0}
	var on_individual := func(_id: String): eventos_lote.individuais += 1
	var on_batch := func(_ids: Array): eventos_lote.lotes += 1
	EventBus.upgrade_purchased.connect(on_individual)
	EventBus.upgrades_batch_purchased.connect(on_batch)
	var compra_bencaos := GameState.buy_all_available_blessings()
	EventBus.upgrade_purchased.disconnect(on_individual)
	EventBus.upgrades_batch_purchased.disconnect(on_batch)
	var pacote_ok := int(plano_bencaos.count) == 2 \
		and is_equal_approx(float((plano_bencaos.totals as Dictionary).fe), 505000.0) \
		and int(compra_bencaos.count) == 2 \
		and int(eventos_lote.individuais) == 0 \
		and int(eventos_lote.lotes) == 1 \
		and "u1_1" in GameState.upgrades_comprados \
		and "u2_1" in GameState.upgrades_comprados \
		and int(GameState.geradores[1].qtd) == 25 \
		and int(GameState.geradores[2].qtd) == 25 \
		and is_zero_approx(GameState.fe)
	print("[T18] comprador adquire duas bencaos em um lote=", pacote_ok)
	ok = ok and pacote_ok

	# 19) Sem a Dadiva, o mesmo saldo nao habilita compras automaticas.
	GameState.dadivas_compradas.clear()
	var plano_bloqueado := GameState.get_blessing_purchase_plan()
	var comprador_bloqueado := not bool(plano_bloqueado.enabled) and int(plano_bloqueado.count) == 0
	print("[T19] comprador bloqueado sem Dadiva=", comprador_bloqueado)
	ok = ok and comprador_bloqueado

	# 20) Um acúmulo grande continua sendo uma unica mutacao visual/economica.
	GameState.dadivas_compradas = ["d_comprador_marcos"]
	GameState.upgrades_comprados.clear()
	GameState.aventuras_desbloqueadas = ["jornada", "vida_cristo", "igreja_apocalipse"]
	GameState._init_geradores()
	for gen_id in GameState.geradores:
		GameState.geradores[gen_id].qtd = 1000
	GameState.fe = 1.0e300
	GameState.graca = 1.0e300
	GameState.gloria = 1.0e300
	GameState.fe_total_vida = 1.0e300
	var plano_grande := GameState.get_blessing_purchase_plan()
	var lotes_grandes := [0]
	var on_large_batch := func(_ids: Array): lotes_grandes[0] += 1
	EventBus.upgrades_batch_purchased.connect(on_large_batch)
	var inicio_lote := Time.get_ticks_msec()
	var compra_grande := GameState.buy_all_available_blessings()
	var duracao_lote := Time.get_ticks_msec() - inicio_lote
	EventBus.upgrades_batch_purchased.disconnect(on_large_batch)
	var lote_grande_ok: bool = int(plano_grande.count) > 100 \
		and int(compra_grande.count) == int(plano_grande.count) \
		and lotes_grandes[0] == 1 and duracao_lote < 2000
	print("[T20] lote grande sem cascata=", lote_grande_ok, " bencaos=", compra_grande.count, " ms=", duracao_lote)
	ok = ok and lote_grande_ok

	# 21) Trocar de campanha congela integralmente o estado anterior. A
	# Ressurreicao de Cristo nao toca em operadores, bencaos ou Santos da Jornada.
	GameState._reset_alpha_progress()
	GameState.aventuras_desbloqueadas = ["jornada", "vida_cristo", "igreja_apocalipse"]
	GameState.santos = 7
	GameState.fe = 1234.0
	GameState.fe_total_vida = 999.0
	GameState.upgrades_comprados = ["u1_1"]
	GameState.geradores[1].qtd = 42
	GameState.set_active_adventure("vida_cristo", false)
	GameState.graca = 10.0
	GameState.fe_total_vida = Economy.get_prestige_divisor()
	GameState.geradores[13].qtd = 5
	var testemunhos_ganhos := GameState.prestige()
	var voltou_jornada := GameState.set_active_adventure("jornada", false)
	var jornada_intacta := voltou_jornada and GameState.santos == 7 \
		and is_equal_approx(GameState.fe, 1234.0) \
		and int(GameState.geradores[1].qtd) == 42 \
		and "u1_1" in GameState.upgrades_comprados
	GameState.set_active_adventure("vida_cristo", false)
	var cristo_independente := testemunhos_ganhos == 1 and GameState.santos == 1 \
		and int(GameState.geradores[13].qtd) == 0 \
		and GameState.upgrades_comprados.is_empty()
	print("[T21] campanhas e ressurreicoes isoladas=", jornada_intacta and cristo_independente)
	ok = ok and jornada_intacta and cristo_independente

	# 22) A quebra de schema do alpha e deliberada: nenhum save v9 e migrado.
	var obsolete_save := GameState.get_save_data()
	obsolete_save.version = 9
	GameState.load_save_data(obsolete_save)
	var alpha_reset_ok := GameState.active_adventure == "jornada" \
		and GameState.aventuras_desbloqueadas == ["jornada"] \
		and is_equal_approx(GameState.fe, GameState.FE_INICIAL) \
		and GameState.santos == 0 and GameState.adventure_progress.size() == 3
	print("[T22] save anterior reinicia o alpha=", alpha_reset_ok)
	ok = ok and alpha_reset_ok

	print("=== SMOKE TEST ", ("PASS" if ok else "FAIL"), " ===")
	get_tree().quit(0 if ok else 1)

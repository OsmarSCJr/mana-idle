extends Node

# Teste automatizado temporario: valida upgrades, dadivas, prestige e economia.
func _ready() -> void:
	await get_tree().process_frame
	var ok := true

	GameState.fe = 1e6
	GameState.fe_total_vida = 0.0
	GameState._init_geradores()
	GameState.upgrades_comprados.clear()
	GameState.dadivas_compradas.clear()
	Economy.recompute_multiplicadores()

	# 1) Upgrade PROD: compra 10 Haja Luz, compra u1_1 (x3)
	GameState.buy_generator(1, 10)
	var mult_antes := Economy.get_gerador_multiplicador(1)
	var comprou_upg := GameState.buy_upgrade("u1_1")
	var mult_depois := Economy.get_gerador_multiplicador(1)
	print("[T1] u1_1 comprado=", comprou_upg, " mult ", mult_antes, " -> ", mult_depois)
	ok = ok and comprou_upg and is_equal_approx(mult_depois, mult_antes * 3.0)

	# 2) Requisito bloqueia: u2_1 requer 10x G2 (temos 0)
	var bloqueado := GameState.buy_upgrade("u2_1")
	print("[T2] u2_1 sem requisito => ", bloqueado, " (esperado false)")
	ok = ok and not bloqueado

	# 3) Upgrade SPEED via era (profeta especial Elias: -25% tempo Era 1)
	GameState.fe_total_vida = 1e7
	GameState.fe = 1e7
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
	# Gastar Santos reduz o bonus deles (30->5); esperado: (1 + 5*0.02) * 1.25 = 1.375
	ok = ok and comprou_dad and GameState.santos == 5 and is_equal_approx(global_depois, 1.375)

	# 7) Dadiva offline: Jo I (+50%) e Jo II (teto 16h)
	GameState.santos = 100
	GameState.buy_dadiva("d_jo")
	GameState.buy_dadiva("d_jo2")
	print("[T7] offline_mult=", Economy.get_offline_mult(), " cap_h=", Economy.get_offline_cap() / 3600.0)
	ok = ok and is_equal_approx(Economy.get_offline_mult(), 1.5) and is_equal_approx(Economy.get_offline_cap(), 16.0 * 3600.0)

	# 8) Prestige: upgrades resetam, dadivas ficam
	GameState.fe_total_vida = 4e9  # sqrt(4) = 2 santos
	var santos_antes := GameState.santos
	var ganhos := GameState.prestige()
	print("[T8] prestige ganhos=", ganhos, " upgrades=", GameState.upgrades_comprados.size(), " dadivas=", GameState.dadivas_compradas.size(), " x100=", Economy.is_x100_unlocked())
	ok = ok and ganhos == 2 and GameState.santos == santos_antes + 2
	ok = ok and GameState.upgrades_comprados.is_empty()
	ok = ok and GameState.dadivas_compradas.size() == 3
	ok = ok and is_equal_approx(Economy.get_tempo_ciclo(1), 0.6)  # speed resetou

	# 9) Save/load roundtrip preserva dadivas e upgrades
	GameState.fe = 555.0
	GameState.buy_generator(1, 10)
	GameState.buy_upgrade("u1_1")
	var save := GameState.get_save_data()
	GameState._init_geradores()
	GameState.upgrades_comprados = []
	GameState.dadivas_compradas = []
	GameState.load_save_data(save)
	print("[T9] roundtrip: upgrades=", GameState.upgrades_comprados, " dadivas=", GameState.dadivas_compradas.size(), " qtd G1=", GameState.geradores[1].qtd)
	ok = ok and ("u1_1" in GameState.upgrades_comprados) and GameState.dadivas_compradas.size() == 3 and GameState.geradores[1].qtd == 10

	# 10) Upgrades.disponiveis ordenado e sem comprados
	var disp := Upgrades.disponiveis()
	var contem_comprado := false
	for u in disp:
		if u.id in GameState.upgrades_comprados:
			contem_comprado = true
	print("[T10] disponiveis=", disp.size(), " contem comprado=", contem_comprado)
	ok = ok and not contem_comprado

	print("=== SMOKE TEST ", ("PASS" if ok else "FAIL"), " ===")
	get_tree().quit()

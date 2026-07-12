extends Node

# Fe inicial: suficiente p/ comprar o 1o gerador (custo 4) e sobrar margem.
const FE_INICIAL: float = 10.0
var fe: float = FE_INICIAL
var santos: int = 0
var santos_gastos: int = 0
var reliquias: int = 0
var gemas: int = 0
var gemas_total: int = 0  # historico de gemas ganhas (estatistica/anti-abuso)
var fe_total_vida: float = 0.0
var fe_total_historica: float = 0.0
var geradores: Dictionary = {}
var maior_qtd_gerador: Dictionary = {}
var upgrades_comprados: Array = []
var dadivas_compradas: Array = []
var sabedoria: int = 0
var sabedoria_total: int = 0
var estudo_progresso: Dictionary = {
	"desbloqueados": [],
	"leiturasConcluidas": [],
	"questoesCorretas": [],
	"recompensasResgatadas": [],
	"paginasIluminadas": [],
	"titulo": "",
	"ultimaPassagem": {},
	"marcadores": [],
	"capitulosLidos": [],
}
var conhecimentos_comprados: Array = []
var aventuras_desbloqueadas: Array = ["jornada"]
var aventuras_concluidas: Array = []
var estatisticas: Dictionary = {"prestiges": 0, "tempo_jogado": 0.0}

const ESTATISTICAS_DEFAULT: Dictionary = {"prestiges": 0, "tempo_jogado": 0.0}
const SAVE_VERSION: int = 2
# Aventuras independentes (sem sequencia obrigatoria), cada uma com sua moeda:
# vida_cristo e paywall de Fe (moeda do jogo); igreja_apocalipse e paywall de Gemas.
const ADVENTURES: Dictionary = {
	"jornada": {"entry_cost": 0.0, "historical_requirement": 0.0, "first_generator": 1, "last_generator": 12, "currency": "fe"},
	"vida_cristo": {"entry_cost": 2.0e14, "historical_requirement": 2.0e14, "first_generator": 13, "last_generator": 24, "currency": "fe"},
	"igreja_apocalipse": {"entry_cost": 120.0, "historical_requirement": 0.0, "first_generator": 25, "last_generator": 36, "currency": "gemas"},
}

func _default_study_progress() -> Dictionary:
	return {
		"desbloqueados": [],
		"leiturasConcluidas": [],
		"questoesCorretas": [],
		"recompensasResgatadas": [],
		"paginasIluminadas": [],
		"titulo": "",
		"ultimaPassagem": {},
		"marcadores": [],
		"capitulosLidos": [],
	}

func _unique_string_array(value: Variant) -> Array:
	var result: Array = []
	if value is not Array:
		return result
	for item in value:
		var normalized := str(item)
		if not normalized.is_empty() and normalized not in result:
			result.append(normalized)
	return result

# Ponto de entrada para migracoes futuras. Ao subir SAVE_VERSION, tratar aqui
# a conversao dos campos do save antigo antes de aplicar em load_save_data.
func _migrate_save(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var v: int = int(migrated.get("version", 1))
	if v < 2:
		migrated["feTotalHistorica"] = float(migrated.get("feTotalVida", 0.0))
		migrated["maiorQtdGerador"] = {}
		migrated["estudo"] = {
			"sabedoria": 0,
			"sabedoriaTotal": 0,
			"progresso": _default_study_progress(),
			"conhecimentosComprados": [],
		}
		migrated["aventurasDesbloqueadas"] = ["jornada"]
		migrated["aventurasConcluidas"] = []
		migrated["version"] = 2
	return migrated

func _ready() -> void:
	_init_geradores()
	Economy.recompute_multiplicadores()

func _init_geradores() -> void:
	geradores.clear()
	for i in range(1, Geradores.count() + 1):
		geradores[i] = {
			"qtd": 0,
			"tem_profeta": false,
			"tempo_restante": -1.0,
		}

func is_unlocked(gen_id: int) -> bool:
	var data := Geradores.get_data(gen_id)
	if data.is_empty():
		return false
	var adventure_id := str(data.get("adventure", "jornada"))
	if adventure_id not in aventuras_desbloqueadas:
		return false
	var first_generator := int(ADVENTURES.get(adventure_id, {}).get("first_generator", 1))
	if gen_id == first_generator:
		return true
	var prev: Dictionary = geradores.get(gen_id - 1, {})
	return int(prev.get("qtd", 0)) > 0

func is_adventure_unlocked(adventure_id: String) -> bool:
	return adventure_id in aventuras_desbloqueadas

func can_unlock_adventure(adventure_id: String) -> bool:
	if adventure_id in aventuras_desbloqueadas:
		return false
	var data: Dictionary = ADVENTURES.get(adventure_id, {})
	if data.is_empty():
		return false
	if str(data.get("currency", "fe")) == "gemas":
		return gemas >= int(data.entry_cost)
	if fe_total_historica < float(data.historical_requirement):
		return false
	return fe >= float(data.entry_cost)

func unlock_adventure(adventure_id: String) -> bool:
	if not can_unlock_adventure(adventure_id):
		return false
	var data: Dictionary = ADVENTURES[adventure_id]
	if str(data.get("currency", "fe")) == "gemas":
		gemas = max(0, gemas - int(data.entry_cost))
		EventBus.gems_changed.emit(gemas)
	else:
		fe = max(0.0, fe - float(data.entry_cost))
		EventBus.faith_changed.emit(fe)
	aventuras_desbloqueadas.append(adventure_id)
	EventBus.adventure_unlocked.emit(adventure_id)
	EventBus.toast_requested.emit("Nova aventura desbloqueada: " + _adventure_display_name(adventure_id))
	return true

func add_gemas(amount: int, motivo: String = "") -> void:
	if amount <= 0:
		return
	gemas += amount
	gemas_total += amount
	EventBus.gems_changed.emit(gemas)
	var texto := "+" + str(amount) + " Gemas"
	if not motivo.is_empty():
		texto += " (" + motivo + ")"
	EventBus.toast_requested.emit(texto)

func get_adventure_unlock_status(adventure_id: String) -> Dictionary:
	var data: Dictionary = ADVENTURES.get(adventure_id, {})
	if data.is_empty():
		return {"exists": false}
	return {
		"exists": true,
		"unlocked": adventure_id in aventuras_desbloqueadas,
		"completed": adventure_id in aventuras_concluidas,
		"entry_cost": float(data.entry_cost),
		"historical_requirement": float(data.historical_requirement),
		"historical_progress": fe_total_historica,
		"currency": str(data.get("currency", "fe")),
		"can_unlock": can_unlock_adventure(adventure_id),
	}

func _adventure_display_name(adventure_id: String) -> String:
	match adventure_id:
		"vida_cristo": return "Vida de Cristo"
		"igreja_apocalipse": return "Igreja & Apocalipse"
		_: return "Jornada Principal"

func buy_generator(gen_id: int, amount: int) -> bool:
	if not geradores.has(gen_id):
		return false
	if amount <= 0:
		return false
	if not is_unlocked(gen_id):
		return false
	var state: Dictionary = geradores[gen_id]
	var custo: float = Economy.custo_lote(gen_id, amount, state.qtd)
	if fe < custo:
		amount = Economy.max_compravel(gen_id, fe, state.qtd)
		if amount <= 0:
			return false
		custo = Economy.custo_lote(gen_id, amount, state.qtd)
	fe = max(fe - custo, 0.0)
	state.qtd += amount
	geradores[gen_id] = state
	maior_qtd_gerador[gen_id] = max(int(maior_qtd_gerador.get(gen_id, 0)), int(state.qtd))
	_check_adventure_completion(gen_id)
	EventBus.generator_changed.emit(gen_id)
	EventBus.faith_changed.emit(fe)
	return true

func _check_adventure_completion(gen_id: int) -> void:
	var adventure_id := ""
	var relic_reward := 0
	if gen_id == 24:
		adventure_id = "vida_cristo"
		relic_reward = 50
	elif gen_id == 36:
		adventure_id = "igreja_apocalipse"
		relic_reward = 100
	if adventure_id.is_empty() or adventure_id in aventuras_concluidas:
		return
	aventuras_concluidas.append(adventure_id)
	reliquias += relic_reward
	Economy.recompute_multiplicadores()
	EventBus.relics_changed.emit(reliquias)
	EventBus.adventure_completed.emit(adventure_id)
	EventBus.toast_requested.emit("Aventura concluída: +" + str(relic_reward) + " Relíquias")
	# Gemas por conclusao: fonte gratuita principal da moeda premium.
	add_gemas(50 if adventure_id == "vida_cristo" else 100, "aventura concluída")

func buy_prophet(gen_id: int) -> bool:
	if not Economy.profeta_disponivel(gen_id):
		return false
	var data: Dictionary = Geradores.get_data(gen_id)
	if fe < data.profeta_custo:
		return false
	var state: Dictionary = geradores[gen_id]
	fe -= data.profeta_custo
	state.tem_profeta = true
	if state.tempo_restante < 0:
		state.tempo_restante = Economy.get_tempo_ciclo(gen_id)
	geradores[gen_id] = state
	EventBus.prophet_changed.emit(gen_id)
	EventBus.faith_changed.emit(fe)
	EventBus.toast_requested.emit("Profeta contratado: " + data.profeta_nome)
	return true

func buy_upgrade(upgrade_id: String) -> bool:
	if upgrade_id in upgrades_comprados:
		return false
	var u: Dictionary = Upgrades.get_data(upgrade_id)
	if u.is_empty():
		return false
	if not Upgrades.requisito_atingido(u):
		return false
	if fe < u.custo:
		return false
	fe = max(fe - u.custo, 0.0)
	upgrades_comprados.append(upgrade_id)
	Economy.recompute_multiplicadores()
	EventBus.upgrade_purchased.emit(upgrade_id)
	EventBus.faith_changed.emit(fe)
	EventBus.toast_requested.emit(u.nome + ": " + u.efeito)
	return true

func buy_dadiva(dadiva_id: String) -> bool:
	if dadiva_id in dadivas_compradas:
		return false
	var d: Dictionary = Dadivas.get_data(dadiva_id)
	if d.is_empty():
		return false
	if santos < d.custo:
		return false
	santos -= d.custo
	santos_gastos += d.custo
	dadivas_compradas.append(dadiva_id)
	Economy.recompute_multiplicadores()
	EventBus.dadiva_purchased.emit(dadiva_id)
	EventBus.toast_requested.emit("Dadiva recebida: " + d.nome)
	return true

func start_cycle(gen_id: int) -> bool:
	if not geradores.has(gen_id):
		return false
	var state: Dictionary = geradores[gen_id]
	if state.qtd <= 0:
		return false
	if state.tempo_restante >= 0:
		return false
	state.tempo_restante = Economy.get_tempo_ciclo(gen_id)
	geradores[gen_id] = state
	return true

func process_tick(delta: float) -> void:
	estatisticas.tempo_jogado += delta
	var fe_mudou: bool = false
	for gen_id in geradores:
		var state: Dictionary = geradores[gen_id]
		if state.qtd <= 0:
			continue
		if state.tempo_restante < 0:
			continue
		state.tempo_restante -= delta
		if state.tempo_restante <= 0:
			var data: Dictionary = Geradores.get_data(gen_id)
			var receita: float = data.receita_base * float(state.qtd) * Economy.get_gerador_multiplicador(gen_id)
			fe += receita
			fe_total_vida += receita
			fe_total_historica += receita
			fe_mudou = true
			if state.tem_profeta:
				# Carrega o excedente negativo em vez de descartá-lo (preserva a taxa real).
				state.tempo_restante += Economy.get_tempo_ciclo(gen_id)
			else:
				state.tempo_restante = -1.0
			EventBus.generator_cycle_complete.emit(gen_id, receita)
		geradores[gen_id] = state
	if fe_mudou:
		EventBus.faith_changed.emit(fe)

func get_receita_por_segundo() -> float:
	return Economy.receita_total_por_segundo()

func get_receita_por_segundo_gerador(gen_id: int) -> float:
	var state: Dictionary = geradores.get(gen_id, {})
	if state.is_empty():
		return 0.0
	return Economy.receita_por_segundo(gen_id, state.qtd, state.tem_profeta) * Economy.get_gerador_multiplicador(gen_id)

func get_progresso_ciclo(gen_id: int) -> float:
	var state: Dictionary = geradores.get(gen_id, {})
	if state.is_empty():
		return 0.0
	if state.tempo_restante < 0:
		return 0.0
	var tempo: float = Economy.get_tempo_ciclo(gen_id)
	return clampf(1.0 - (state.tempo_restante / tempo), 0.0, 1.0)

func can_prestige() -> bool:
	return Economy.santos_ganhos(fe_total_vida) > 0

func prestige() -> int:
	var ganhos: int = Economy.santos_ganhos(fe_total_vida)
	if ganhos <= 0:
		return 0
	santos += ganhos
	estatisticas.prestiges += 1
	# Gemas por ressurreicao: 1a paga bem (funil p/ conhecer a moeda), depois goteja.
	add_gemas(10 if estatisticas.prestiges == 1 else 2, "Ressurreição")
	# Sem fe inicial o jogador nao consegue comprar o 1o gerador e trava.
	fe = FE_INICIAL
	fe_total_vida = 0.0
	for gen_id in geradores:
		geradores[gen_id] = {
			"qtd": 0,
			"tem_profeta": false,
			"tempo_restante": -1.0,
		}
	upgrades_comprados.clear()
	# Dadivas persistem (bonus permanente do prestige).
	Economy.recompute_multiplicadores()
	EventBus.prestige_done.emit()
	EventBus.faith_changed.emit(fe)
	EventBus.toast_requested.emit("Ressurreicao! +" + str(ganhos) + " Santos")
	return ganhos

func get_santos_proximo_prestige() -> int:
	return Economy.santos_ganhos(fe_total_vida)

func get_save_data() -> Dictionary:
	var gens_save: Dictionary = {}
	for gen_id in geradores:
		var state: Dictionary = geradores[gen_id]
		gens_save[str(gen_id)] = {
			"qtd": state.qtd,
			"tem_profeta": state.tem_profeta,
			"tempo_restante": state.tempo_restante,
		}
	return {
		"version": SAVE_VERSION,
		"lastSeen": Time.get_unix_time_from_system(),
		"fe": fe,
		"santos": santos,
		"santosGastos": santos_gastos,
		"reliquias": reliquias,
		"gemas": gemas,
		"gemasTotal": gemas_total,
		"feTotalVida": fe_total_vida,
		"feTotalHistorica": fe_total_historica,
		"geradores": gens_save,
		"maiorQtdGerador": maior_qtd_gerador.duplicate(true),
		"upgradesComprados": upgrades_comprados.duplicate(),
		"dadivasCompradas": dadivas_compradas.duplicate(),
		"estudo": {
			"sabedoria": sabedoria,
			"sabedoriaTotal": sabedoria_total,
			"progresso": estudo_progresso.duplicate(true),
			"conhecimentosComprados": conhecimentos_comprados.duplicate(),
		},
		"aventurasDesbloqueadas": aventuras_desbloqueadas.duplicate(),
		"aventurasConcluidas": aventuras_concluidas.duplicate(),
		"estatisticas": estatisticas.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	data = _migrate_save(data)
	_init_geradores()
	fe = float(data.get("fe", 0.0))
	santos = int(data.get("santos", 0))
	santos_gastos = int(data.get("santosGastos", 0))
	reliquias = int(data.get("reliquias", 0))
	gemas = max(0, int(data.get("gemas", 0)))
	gemas_total = max(gemas, int(data.get("gemasTotal", gemas)))
	fe_total_vida = float(data.get("feTotalVida", 0.0))
	fe_total_historica = float(data.get("feTotalHistorica", fe_total_vida))
	upgrades_comprados = _unique_string_array(data.get("upgradesComprados", []))
	dadivas_compradas = _unique_string_array(data.get("dadivasCompradas", []))
	aventuras_desbloqueadas = _unique_string_array(data.get("aventurasDesbloqueadas", ["jornada"]))
	aventuras_concluidas = _unique_string_array(data.get("aventurasConcluidas", []))
	if "jornada" not in aventuras_desbloqueadas:
		aventuras_desbloqueadas.push_front("jornada")
	maior_qtd_gerador.clear()
	var maiores_save: Dictionary = data.get("maiorQtdGerador", {})
	for gen_id_key in maiores_save:
		maior_qtd_gerador[int(gen_id_key)] = max(0, int(maiores_save[gen_id_key]))

	var estudo_save: Dictionary = data.get("estudo", {})
	sabedoria = max(0, int(estudo_save.get("sabedoria", 0)))
	sabedoria_total = max(sabedoria, int(estudo_save.get("sabedoriaTotal", sabedoria)))
	conhecimentos_comprados = _unique_string_array(estudo_save.get("conhecimentosComprados", []))
	estudo_progresso = _default_study_progress()
	var progresso_save: Dictionary = estudo_save.get("progresso", {})
	for array_key in ["desbloqueados", "leiturasConcluidas", "questoesCorretas", "recompensasResgatadas", "paginasIluminadas", "marcadores", "capitulosLidos"]:
		estudo_progresso[array_key] = _unique_string_array(progresso_save.get(array_key, []))
	estudo_progresso.titulo = str(progresso_save.get("titulo", ""))
	var ultima_passagem: Variant = progresso_save.get("ultimaPassagem", {})
	estudo_progresso.ultimaPassagem = ultima_passagem.duplicate(true) if ultima_passagem is Dictionary else {}
	estatisticas = ESTATISTICAS_DEFAULT.duplicate()
	var stats_save: Dictionary = data.get("estatisticas", {})
	estatisticas.prestiges = int(stats_save.get("prestiges", 0))
	estatisticas.tempo_jogado = float(stats_save.get("tempo_jogado", 0.0))
	var gens_save: Dictionary = data.get("geradores", {})
	for gen_id_str in gens_save:
		var gen_id: int = int(gen_id_str)
		var saved: Dictionary = gens_save[gen_id_str]
		if geradores.has(gen_id):
			geradores[gen_id] = {
				"qtd": int(saved.get("qtd", 0)),
				"tem_profeta": bool(saved.get("tem_profeta", false)),
				"tempo_restante": float(saved.get("tempo_restante", -1.0)),
			}
			maior_qtd_gerador[gen_id] = max(int(maior_qtd_gerador.get(gen_id, 0)), int(saved.get("qtd", 0)))
	Economy.recompute_multiplicadores()
	EventBus.faith_changed.emit(fe)
	EventBus.wisdom_changed.emit(sabedoria)

func apply_offline_production(seconds: float) -> float:
	var cap: float = Economy.get_offline_cap()
	if seconds > cap:
		seconds = cap
	var total: float = 0.0
	for gen_id in geradores:
		var state: Dictionary = geradores[gen_id]
		if not state.tem_profeta or state.qtd <= 0:
			continue
		var data: Dictionary = Geradores.get_data(gen_id)
		var ciclos: float = seconds / Economy.get_tempo_ciclo(gen_id)
		var receita: float = data.receita_base * float(state.qtd) * Economy.get_gerador_multiplicador(gen_id) * ciclos
		total += receita
	total *= Economy.get_offline_mult()
	if total > 0:
		fe += total
		fe_total_vida += total
		fe_total_historica += total
		EventBus.faith_changed.emit(fe)
	return total

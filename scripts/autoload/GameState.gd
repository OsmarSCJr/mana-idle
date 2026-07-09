extends Node

var fe: float = 10.0
var santos: int = 0
var santos_gastos: int = 0
var reliquias: int = 0
var fe_total_vida: float = 0.0
var geradores: Dictionary = {}
var upgrades_comprados: Array = []
var estatisticas: Dictionary = {"prestiges": 0, "tempo_jogado": 0.0}

const ESTATISTICAS_DEFAULT: Dictionary = {"prestiges": 0, "tempo_jogado": 0.0}
const SAVE_VERSION: int = 1

# Ponto de entrada para migracoes futuras. Ao subir SAVE_VERSION, tratar aqui
# a conversao dos campos do save antigo antes de aplicar em load_save_data.
func _migrate_save(data: Dictionary) -> Dictionary:
	var v: int = int(data.get("version", 1))
	# if v < 2: data = _migrate_v1_to_v2(data)
	return data

func _ready() -> void:
	_init_geradores()

func _init_geradores() -> void:
	for i in range(1, Geradores.count() + 1):
		geradores[i] = {
			"qtd": 0,
			"tem_profeta": false,
			"tempo_restante": -1.0,
		}

func is_unlocked(gen_id: int) -> bool:
	if gen_id <= 1:
		return true
	var prev: Dictionary = geradores.get(gen_id - 1, {})
	return int(prev.get("qtd", 0)) > 0

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
	EventBus.generator_changed.emit(gen_id)
	EventBus.faith_changed.emit(fe)
	return true

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
		state.tempo_restante = data.tempo
	geradores[gen_id] = state
	EventBus.prophet_changed.emit(gen_id)
	EventBus.faith_changed.emit(fe)
	EventBus.toast_requested.emit("Profeta contratado: " + data.profeta_nome)
	return true

func start_cycle(gen_id: int) -> bool:
	if not geradores.has(gen_id):
		return false
	var state: Dictionary = geradores[gen_id]
	if state.qtd <= 0:
		return false
	if state.tempo_restante >= 0:
		return false
	var data: Dictionary = Geradores.get_data(gen_id)
	state.tempo_restante = data.tempo
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
			fe_mudou = true
			if state.tem_profeta:
				# Carrega o excedente negativo em vez de descartá-lo (preserva a taxa real).
				state.tempo_restante += data.tempo
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
	var data: Dictionary = Geradores.get_data(gen_id)
	return 1.0 - (state.tempo_restante / data.tempo)

func can_prestige() -> bool:
	return Economy.santos_ganhos(fe_total_vida) > 0

func prestige() -> int:
	var ganhos: int = Economy.santos_ganhos(fe_total_vida)
	if ganhos <= 0:
		return 0
	santos += ganhos
	estatisticas.prestiges += 1
	fe = 0.0
	fe_total_vida = 0.0
	for gen_id in geradores:
		geradores[gen_id] = {
			"qtd": 0,
			"tem_profeta": false,
			"tempo_restante": -1.0,
		}
	upgrades_comprados.clear()
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
		"feTotalVida": fe_total_vida,
		"geradores": gens_save,
		"upgradesComprados": upgrades_comprados,
		"estatisticas": estatisticas,
	}

func load_save_data(data: Dictionary) -> void:
	data = _migrate_save(data)
	fe = float(data.get("fe", 0.0))
	santos = int(data.get("santos", 0))
	santos_gastos = int(data.get("santosGastos", 0))
	reliquias = int(data.get("reliquias", 0))
	fe_total_vida = float(data.get("feTotalVida", 0.0))
	upgrades_comprados = data.get("upgradesComprados", [])
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
	EventBus.faith_changed.emit(fe)

func apply_offline_production(seconds: float) -> float:
	var cap: float = 8.0 * 3600.0
	if seconds > cap:
		seconds = cap
	var total: float = 0.0
	for gen_id in geradores:
		var state: Dictionary = geradores[gen_id]
		if not state.tem_profeta or state.qtd <= 0:
			continue
		var data: Dictionary = Geradores.get_data(gen_id)
		var ciclos: float = seconds / data.tempo
		var receita: float = data.receita_base * float(state.qtd) * Economy.get_gerador_multiplicador(gen_id) * ciclos
		total += receita
	if total > 0:
		fe += total
		fe_total_vida += total
		EventBus.faith_changed.emit(fe)
	return total

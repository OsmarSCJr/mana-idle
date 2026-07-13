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
var conhecimentos_ativos: Array = []
var aventuras_desbloqueadas: Array = ["jornada"]
var aventuras_concluidas: Array = []
var boosts: Dictionary = {} # boost_id -> timestamp Unix de expiracao
var boost_inventory: Dictionary = {} # boost_id -> cargas compradas e ainda nao usadas
var reward_video_window_started: float = 0.0
var reward_videos_watched: int = 0
var daily_boost_video_last_claimed: float = 0.0
var daily_boost_video_last_reward: String = ""
var estatisticas: Dictionary = {"prestiges": 0, "tempo_jogado": 0.0}

const ESTATISTICAS_DEFAULT: Dictionary = {"prestiges": 0, "tempo_jogado": 0.0}
const SAVE_VERSION: int = 8
const REWARD_VIDEO_LIMIT: int = 6
const REWARD_VIDEO_WINDOW_SECONDS: int = 24 * 3600
const DAILY_BOOST_VIDEO_COOLDOWN: int = 24 * 3600
const BOOSTS: Dictionary = {
	"fervor": {"nome": "Fervor", "efeito": "Produção global ×2", "descricao": "Dobra toda a Fé produzida por seus geradores.", "duracao": 14400, "custo": 20, "icon_gen": 1},
	"pentecoste": {"nome": "Pentecoste", "efeito": "Produção global ×5", "descricao": "Uma explosão breve de produção para momentos decisivos.", "duracao": 900, "custo": 10, "icon_gen": 25},
	"colheita": {"nome": "Colheita", "efeito": "+2 h de produção", "descricao": "Receba instantaneamente duas horas da sua produção automática atual.", "duracao": 0, "custo": 15, "icon_gen": 5},
	"passo_ligeiro": {"nome": "Passo Ligeiro", "efeito": "Ciclos 2× mais rápidos", "descricao": "Reduz pela metade a duração dos ciclos de todos os geradores.", "duracao": 3600, "custo": 12, "icon_gen": 27},
	"maos_santas": {"nome": "Mãos Santas", "efeito": "Toque manual ×10", "descricao": "Cada ciclo iniciado manualmente entrega dez vezes mais Fé.", "duracao": 1800, "custo": 8, "icon_gen": 15},
}
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
	if v < 3:
		migrated["boosts"] = {}
		migrated["version"] = 3
	if v < 4:
		migrated["rewardVideoWindowStarted"] = 0.0
		migrated["rewardVideosWatched"] = 0
		migrated["version"] = 4
	if v < 5:
		migrated["boostInventory"] = {}
		migrated["version"] = 5
	if v < 6:
		migrated["dailyBoostVideoLastClaimed"] = 0.0
		migrated["version"] = 6
	if v < 7:
		migrated["dailyBoostVideoLastReward"] = ""
		migrated["version"] = 7
	if v < 8:
		var legacy_study: Dictionary = migrated.get("estudo", {})
		legacy_study["conhecimentosAtivos"] = legacy_study.get("conhecimentosComprados", [])
		migrated["estudo"] = legacy_study
		migrated["version"] = 8
	return migrated

func get_reward_videos_remaining() -> int:
	_refresh_reward_video_window()
	return maxi(0, REWARD_VIDEO_LIMIT - reward_videos_watched)

func can_watch_reward_video() -> bool:
	return get_reward_videos_remaining() > 0

func consume_reward_video() -> bool:
	_refresh_reward_video_window()
	if reward_videos_watched >= REWARD_VIDEO_LIMIT:
		return false
	if reward_video_window_started <= 0.0:
		reward_video_window_started = Time.get_unix_time_from_system()
	reward_videos_watched += 1
	SaveSystem.save_game()
	return true

func _refresh_reward_video_window() -> void:
	if reward_video_window_started > 0.0 and Time.get_unix_time_from_system() - reward_video_window_started >= REWARD_VIDEO_WINDOW_SECONDS:
		reward_video_window_started = 0.0
		reward_videos_watched = 0

func get_daily_boost_video_remaining_seconds() -> int:
	if daily_boost_video_last_claimed <= 0.0:
		return 0
	return maxi(0, ceili(DAILY_BOOST_VIDEO_COOLDOWN - (Time.get_unix_time_from_system() - daily_boost_video_last_claimed)))

func can_claim_daily_boost_video() -> bool:
	return get_daily_boost_video_remaining_seconds() <= 0

func get_daily_boost_video_last_reward() -> String:
	return daily_boost_video_last_reward

func claim_daily_random_boost_video() -> String:
	if not can_claim_daily_boost_video():
		return ""
	var boost_ids: Array = BOOSTS.keys()
	if boost_ids.is_empty():
		return ""
	boost_ids.sort()
	var random := RandomNumberGenerator.new()
	random.randomize()
	var boost_id := str(boost_ids[random.randi_range(0, boost_ids.size() - 1)])
	boost_inventory[boost_id] = get_boost_inventory(boost_id) + 1
	daily_boost_video_last_claimed = Time.get_unix_time_from_system()
	daily_boost_video_last_reward = boost_id
	EventBus.boosts_changed.emit()
	EventBus.toast_requested.emit("Impulso recebido: " + str(BOOSTS[boost_id].nome))
	SaveSystem.save_game()
	return boost_id

func activate_boost_from_video(boost_id: String) -> bool:
	if boost_id not in ["fervor", "passo_ligeiro"] or not consume_reward_video():
		return false
	_extend_boost(boost_id, 1800.0)
	EventBus.boosts_changed.emit()
	EventBus.toast_requested.emit(str(BOOSTS[boost_id].nome) + " estendido por 30 min")
	SaveSystem.save_game()
	return true

func get_boost_data(boost_id: String) -> Dictionary:
	return BOOSTS.get(boost_id, {})

func get_boost_inventory(boost_id: String) -> int:
	return maxi(0, int(boost_inventory.get(boost_id, 0)))

func get_boost_remaining(boost_id: String) -> int:
	return maxi(0, int(float(boosts.get(boost_id, 0.0)) - Time.get_unix_time_from_system()))

func is_boost_active(boost_id: String) -> bool:
	return get_boost_remaining(boost_id) > 0

func get_boost_production_multiplier() -> float:
	var mult := 1.0
	if is_boost_active("fervor"):
		mult *= 2.0
	if is_boost_active("pentecoste"):
		mult *= 5.0
	return mult

func get_manual_boost_multiplier() -> float:
	var boost_multiplier := 10.0 if is_boost_active("maos_santas") else 1.0
	return boost_multiplier * Economy.get_manual_knowledge_multiplier()

func buy_boost_charge(boost_id: String) -> bool:
	var data: Dictionary = get_boost_data(boost_id)
	if data.is_empty() or not spend_gemas(int(data.custo)):
		return false
	boost_inventory[boost_id] = get_boost_inventory(boost_id) + 1
	EventBus.boosts_changed.emit()
	EventBus.toast_requested.emit(str(data.nome) + " adicionado aos seus impulsos")
	SaveSystem.save_game()
	return true

func use_boost_charge(boost_id: String) -> bool:
	var data: Dictionary = get_boost_data(boost_id)
	var available := get_boost_inventory(boost_id)
	if data.is_empty() or available <= 0:
		return false
	if available == 1:
		boost_inventory.erase(boost_id)
	else:
		boost_inventory[boost_id] = available - 1
	if boost_id == "colheita":
		var harvest := get_receita_por_segundo() * 7200.0
		add_fe_bonus(harvest)
		EventBus.toast_requested.emit("Colheita recebida: +" + NumberFormat.format(harvest) + " Fé")
	else:
		_extend_boost(boost_id, float(data.duracao))
		EventBus.toast_requested.emit(str(data.nome) + " ativado")
	EventBus.boosts_changed.emit()
	SaveSystem.save_game()
	return true

func purchase_boost(boost_id: String) -> bool:
	return buy_boost_charge(boost_id)

func _extend_boost(boost_id: String, duration: float) -> void:
	var now := Time.get_unix_time_from_system()
	boosts[boost_id] = maxf(now, float(boosts.get(boost_id, 0.0))) + duration * Economy.get_boost_duration_multiplier()

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
	var entry_cost := _get_adventure_entry_cost(data)
	if str(data.get("currency", "fe")) == "gemas":
		return gemas >= int(entry_cost)
	if fe_total_historica < float(data.historical_requirement):
		return false
	return fe >= entry_cost

func unlock_adventure(adventure_id: String) -> bool:
	if not can_unlock_adventure(adventure_id):
		return false
	var data: Dictionary = ADVENTURES[adventure_id]
	var entry_cost := _get_adventure_entry_cost(data)
	if str(data.get("currency", "fe")) == "gemas":
		gemas = max(0, gemas - int(entry_cost))
		EventBus.gems_changed.emit(gemas)
	else:
		fe = max(0.0, fe - entry_cost)
		EventBus.faith_changed.emit(fe)
	aventuras_desbloqueadas.append(adventure_id)
	EventBus.adventure_unlocked.emit(adventure_id)
	EventBus.toast_requested.emit("Nova aventura desbloqueada: " + _adventure_display_name(adventure_id))
	return true

func spend_gemas(amount: int) -> bool:
	if amount <= 0 or gemas < amount:
		return false
	gemas -= amount
	EventBus.gems_changed.emit(gemas)
	return true

# Fe extra (bonus de video/gema do ganho offline): conta em todos os totais.
func add_fe_bonus(amount: float) -> void:
	if amount <= 0:
		return
	fe += amount
	fe_total_vida += amount
	fe_total_historica += amount
	EventBus.faith_changed.emit(fe)

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
	var entry_cost := _get_adventure_entry_cost(data)
	return {
		"exists": true,
		"unlocked": adventure_id in aventuras_desbloqueadas,
		"completed": adventure_id in aventuras_concluidas,
		"entry_cost": entry_cost,
		"historical_requirement": float(data.historical_requirement),
		"historical_progress": fe_total_historica,
		"currency": str(data.get("currency", "fe")),
		"can_unlock": can_unlock_adventure(adventure_id),
	}

func _get_adventure_entry_cost(data: Dictionary) -> float:
	var base_cost := float(data.get("entry_cost", 0.0))
	if str(data.get("currency", "fe")) == "gemas":
		return float(ceili(base_cost * Economy.get_adventure_gem_discount()))
	return base_cost * Economy.get_adventure_fe_discount()

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
	var custo: float = Economy.get_profeta_custo(gen_id)
	if fe < custo:
		return false
	var state: Dictionary = geradores[gen_id]
	fe -= custo
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
			if not bool(state.tem_profeta):
				receita *= get_manual_boost_multiplier()
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
			"conhecimentosAtivos": conhecimentos_ativos.duplicate(),
		},
		"aventurasDesbloqueadas": aventuras_desbloqueadas.duplicate(),
		"aventurasConcluidas": aventuras_concluidas.duplicate(),
		"boosts": boosts.duplicate(true),
		"boostInventory": boost_inventory.duplicate(true),
		"rewardVideoWindowStarted": reward_video_window_started,
		"rewardVideosWatched": reward_videos_watched,
		"dailyBoostVideoLastClaimed": daily_boost_video_last_claimed,
		"dailyBoostVideoLastReward": daily_boost_video_last_reward,
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
	boosts.clear()
	var saved_boosts: Dictionary = data.get("boosts", {})
	for boost_id in saved_boosts:
		if BOOSTS.has(str(boost_id)) and float(saved_boosts[boost_id]) > Time.get_unix_time_from_system():
			boosts[str(boost_id)] = float(saved_boosts[boost_id])
	boost_inventory.clear()
	var saved_boost_inventory: Dictionary = data.get("boostInventory", {})
	for boost_id in saved_boost_inventory:
		var amount := maxi(0, int(saved_boost_inventory[boost_id]))
		if BOOSTS.has(str(boost_id)) and amount > 0:
			boost_inventory[str(boost_id)] = amount
	reward_video_window_started = float(data.get("rewardVideoWindowStarted", 0.0))
	reward_videos_watched = clampi(int(data.get("rewardVideosWatched", 0)), 0, REWARD_VIDEO_LIMIT)
	daily_boost_video_last_claimed = float(data.get("dailyBoostVideoLastClaimed", 0.0))
	var saved_daily_reward := str(data.get("dailyBoostVideoLastReward", ""))
	daily_boost_video_last_reward = saved_daily_reward if BOOSTS.has(saved_daily_reward) else ""
	_refresh_reward_video_window()
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
	var active_source: Array = _unique_string_array(estudo_save.get("conhecimentosAtivos", conhecimentos_comprados))
	conhecimentos_ativos = []
	for knowledge_id in active_source:
		if knowledge_id in conhecimentos_comprados and not Conhecimentos.get_data(knowledge_id).is_empty():
			conhecimentos_ativos.append(knowledge_id)
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

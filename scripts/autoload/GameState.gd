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
# Moedas isoladas das aventuras. Nunca convertem entre si nem com a Fe.
var graca: float = 0.0
var gloria: float = 0.0
var graca_total: float = 0.0    # producao historica (marcos de moeda/ledger)
var gloria_total: float = 0.0
var dadiva_frutos_nivel: int = 0  # escada infinita "Frutos do Espirito"
var marcos_ledger: Dictionary = {}        # adventure_id -> Array[int] marcos gerais pagos 1x
var moeda_marcos_ledger: Dictionary = {}  # adventure_id -> Array[String] marcos de moeda pagos 1x
var cosmeticos_comprados: Array = []
var cosmeticos_ativos: Dictionary = {}    # categoria -> id
var nova_star_last_gem_claim: float = 0.0
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
var active_adventure: String = "jornada"
# O facade acima (santos/upgrades/dadivas/boosts/fe_total_vida) representa
# somente a campanha carregada. As outras ficam congeladas neste cofre.
var adventure_progress: Dictionary = {}

const ESTATISTICAS_DEFAULT: Dictionary = {"prestiges": 0, "tempo_jogado": 0.0}
const SAVE_VERSION: int = 10
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
# Aventuras independentes (sem sequencia obrigatoria). "currency" e a moeda do
# paywall de entrada; "generator_currency" e a moeda ISOLADA em que os geradores
# da aventura custam e produzem. Marcos de moeda acumulada pagam Reliquias +
# poucas gemas, 1x cada (ledger) — nunca cambio livre.
const ADVENTURES: Dictionary = {
	"jornada": {"entry_cost": 0.0, "historical_requirement": 0.0, "first_generator": 1, "last_generator": 12, "currency": "fe", "generator_currency": "fe", "starting_currency": 10.0, "prestige_name": "Santos", "theme_name": "Criação"},
	"vida_cristo": {"entry_cost": 2.0e14, "historical_requirement": 2.0e14, "first_generator": 13, "last_generator": 24, "currency": "fe", "generator_currency": "graca", "starting_currency": 10.0, "prestige_name": "Testemunhos", "theme_name": "Caminho"},
	"igreja_apocalipse": {"entry_cost": 120.0, "historical_requirement": 0.0, "first_generator": 25, "last_generator": 36, "currency": "gemas", "generator_currency": "gloria", "starting_currency": 10.0, "prestige_name": "Coroas", "theme_name": "Consumação"},
}
const CURRENCY_NAMES: Dictionary = {"fe": "Fé", "graca": "Graça", "gloria": "Glória"}
const ADVENTURE_PALETTES: Dictionary = {
	"jornada": {"top": Color("#10102e"), "bottom": Color("#17183d"), "glow": Color(0.94, 0.65, 0.0, 0.055), "star": Color("#f4dfad")},
	"vida_cristo": {"top": Color("#172b2a"), "bottom": Color("#35432d"), "glow": Color(0.98, 0.72, 0.34, 0.10), "star": Color("#ffe6ae")},
	"igreja_apocalipse": {"top": Color("#21152f"), "bottom": Color("#3c1730"), "glow": Color(0.62, 0.76, 1.0, 0.10), "star": Color("#d8e6ff")},
}
# Marcos de moeda acumulada por aventura: Reliquias + pacote pequeno de gemas, 1x.
const MOEDA_MARCOS: Array = [
	{"key": "1e6", "amount": 1.0e6, "relics": 10, "gems": 10},
	{"key": "1e9", "amount": 1.0e9, "relics": 20, "gems": 15},
	{"key": "1e12", "amount": 1.0e12, "relics": 35, "gems": 20},
	{"key": "1e15", "amount": 1.0e15, "relics": 60, "gems": 30},
]

func _new_adventure_progress() -> Dictionary:
	return {
		"prestige": 0,
		"prestige_spent": 0,
		"run_total": 0.0,
		"fruit_level": 0,
		"upgrades": [],
		"gifts": [],
		"boosts": {},
		"boost_inventory": {},
		"prestiges": 0,
	}

func _init_adventure_progress() -> void:
	adventure_progress.clear()
	for adventure_id in ADVENTURES:
		adventure_progress[adventure_id] = _new_adventure_progress()

func _ensure_adventure_progress(adventure_id: String) -> void:
	if not adventure_progress.has(adventure_id):
		adventure_progress[adventure_id] = _new_adventure_progress()

func _sync_active_adventure() -> void:
	_ensure_adventure_progress(active_adventure)
	var progress: Dictionary = adventure_progress[active_adventure]
	progress.prestige = santos
	progress.prestige_spent = santos_gastos
	progress.run_total = fe_total_vida
	progress.fruit_level = dadiva_frutos_nivel
	progress.upgrades = upgrades_comprados.duplicate()
	progress.gifts = dadivas_compradas.duplicate()
	progress.boosts = boosts.duplicate(true)
	progress.boost_inventory = boost_inventory.duplicate(true)
	progress.prestiges = int(estatisticas.get("prestiges", 0))
	adventure_progress[active_adventure] = progress

func _load_adventure_progress(adventure_id: String) -> void:
	_ensure_adventure_progress(adventure_id)
	var progress: Dictionary = adventure_progress[adventure_id]
	santos = int(progress.get("prestige", 0))
	santos_gastos = int(progress.get("prestige_spent", 0))
	fe_total_vida = float(progress.get("run_total", 0.0))
	dadiva_frutos_nivel = int(progress.get("fruit_level", 0))
	upgrades_comprados = (progress.get("upgrades", []) as Array).duplicate()
	dadivas_compradas = (progress.get("gifts", []) as Array).duplicate()
	boosts = (progress.get("boosts", {}) as Dictionary).duplicate(true)
	boost_inventory = (progress.get("boost_inventory", {}) as Dictionary).duplicate(true)
	estatisticas.prestiges = int(progress.get("prestiges", 0))

func set_active_adventure(adventure_id: String, emit_signal: bool = true) -> bool:
	if not ADVENTURES.has(adventure_id) or adventure_id not in aventuras_desbloqueadas:
		return false
	if adventure_id == active_adventure:
		return true
	_sync_active_adventure()
	active_adventure = adventure_id
	_load_adventure_progress(adventure_id)
	Economy.recompute_multiplicadores()
	if emit_signal:
		EventBus.adventure_context_changed.emit(adventure_id)
		EventBus.ui_needs_update.emit()
	return true

func get_prestige_name(adventure_id: String = active_adventure) -> String:
	return str(ADVENTURES.get(adventure_id, {}).get("prestige_name", "Santos"))

func get_active_run_total() -> float:
	return fe_total_vida

func get_adventure_palette(adventure_id: String = active_adventure) -> Dictionary:
	return (ADVENTURE_PALETTES.get(adventure_id, ADVENTURE_PALETTES.jornada) as Dictionary).duplicate()

# ------------------------------------------------------------ Moedas isoladas

func get_currency_for_gen(gen_id: int) -> String:
	var adventure_id := Geradores.get_adventure_for_id(gen_id)
	return str(ADVENTURES.get(adventure_id, {}).get("generator_currency", "fe"))

func get_currency_name(currency: String) -> String:
	return str(CURRENCY_NAMES.get(currency, "Fé"))

func get_adventure_for_currency(currency: String) -> String:
	match currency:
		"graca": return "vida_cristo"
		"gloria": return "igreja_apocalipse"
		_: return "jornada"

func get_currency_amount(currency: String) -> float:
	match currency:
		"graca": return graca
		"gloria": return gloria
		_: return fe

func add_currency(currency: String, amount: float) -> void:
	if amount <= 0.0:
		return
	var adventure_id := get_adventure_for_currency(currency)
	if adventure_id == active_adventure:
		fe_total_vida += amount
	else:
		_ensure_adventure_progress(adventure_id)
		var progress: Dictionary = adventure_progress[adventure_id]
		progress.run_total = float(progress.get("run_total", 0.0)) + amount
		adventure_progress[adventure_id] = progress
	match currency:
		"graca":
			graca += amount
			graca_total += amount
			EventBus.adventure_currency_changed.emit("graca", graca)
			_check_moeda_marcos("vida_cristo", graca_total)
		"gloria":
			gloria += amount
			gloria_total += amount
			EventBus.adventure_currency_changed.emit("gloria", gloria)
			_check_moeda_marcos("igreja_apocalipse", gloria_total)
		_:
			fe += amount
			fe_total_historica += amount
			EventBus.faith_changed.emit(fe)

func spend_currency(currency: String, amount: float) -> bool:
	if amount < 0.0 or get_currency_amount(currency) < amount:
		return false
	match currency:
		"graca":
			graca = maxf(graca - amount, 0.0)
			EventBus.adventure_currency_changed.emit("graca", graca)
		"gloria":
			gloria = maxf(gloria - amount, 0.0)
			EventBus.adventure_currency_changed.emit("gloria", gloria)
		_:
			fe = maxf(fe - amount, 0.0)
			EventBus.faith_changed.emit(fe)
	return true

func _set_currency_amount(currency: String, amount: float) -> void:
	match currency:
		"graca":
			graca = maxf(amount, 0.0)
			EventBus.adventure_currency_changed.emit(currency, graca)
		"gloria":
			gloria = maxf(amount, 0.0)
			EventBus.adventure_currency_changed.emit(currency, gloria)
		_:
			fe = maxf(amount, 0.0)
			EventBus.faith_changed.emit(fe)

# Marcos de moeda acumulada (1e6/1e9/...): Reliquias + poucas gemas, 1x cada.
func _check_moeda_marcos(adventure_id: String, total: float) -> void:
	var pagos: Array = moeda_marcos_ledger.get(adventure_id, [])
	for marco in MOEDA_MARCOS:
		var key := str(marco.key)
		if key in pagos or total < float(marco.amount):
			continue
		pagos.append(key)
		reliquias += int(marco.relics)
		EventBus.relics_changed.emit(reliquias)
		add_gemas(LiveOps.scale_free_gem_reward(int(marco.gems)), "marco de " + _adventure_display_name(adventure_id))
		EventBus.toast_requested.emit("Marco alcançado: +" + str(int(marco.relics)) + " Relíquias")
	moeda_marcos_ledger[adventure_id] = pagos

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
	if v < 9:
		# Aventuras viram economias isoladas: quantidades de geradores 13-36 sao
		# preservadas (produzem Graca/Gloria daqui em diante), mas os ciclos
		# reiniciam porque os tempos mudaram de escala.
		migrated["graca"] = 0.0
		migrated["gloria"] = 0.0
		migrated["gracaTotal"] = 0.0
		migrated["gloriaTotal"] = 0.0
		migrated["dadivaFrutosNivel"] = 0
		migrated["marcosLedger"] = {}
		migrated["moedaMarcosLedger"] = {}
		migrated["cosmeticosComprados"] = []
		migrated["cosmeticosAtivos"] = {}
		migrated["novaStarLastGemClaim"] = 0.0
		var gens_saved: Dictionary = migrated.get("geradores", {})
		for gen_key in gens_saved:
			if int(str(gen_key)) >= 13 and gens_saved[gen_key] is Dictionary:
				(gens_saved[gen_key] as Dictionary)["tempo_restante"] = -1.0
		migrated["geradores"] = gens_saved
		migrated["version"] = 9
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
	var source: Dictionary = BOOSTS.get(boost_id, {})
	if source.is_empty():
		return {}
	var data := source.duplicate(true)
	match boost_id:
		"fervor":
			var multiplier := LiveOps.fervor_production_multiplier()
			data.efeito = "Produção global ×" + _compact_liveops_number(multiplier)
			data.descricao = "Multiplica por ×" + _compact_liveops_number(multiplier) + " toda a Fé produzida por seus geradores."
		"pentecoste":
			var multiplier := LiveOps.pentecost_production_multiplier()
			data.efeito = "Produção global ×" + _compact_liveops_number(multiplier)
			data.descricao = "Uma explosão breve de produção global ×" + _compact_liveops_number(multiplier) + "."
		"colheita":
			var duration := _compact_liveops_duration(LiveOps.harvest_seconds())
			data.efeito = "+" + duration + " de produção"
			data.descricao = "Receba instantaneamente " + duration + " da sua produção automática atual."
		"passo_ligeiro":
			var time_multiplier := LiveOps.swift_step_time_multiplier()
			if time_multiplier <= 1.0:
				var speed_multiplier := 1.0 / time_multiplier
				data.efeito = "Ciclos " + _compact_liveops_number(speed_multiplier) + "× mais rápidos"
				data.descricao = "Acelera por ×" + _compact_liveops_number(speed_multiplier) + " os ciclos de todos os geradores."
			else:
				data.efeito = "Duração dos ciclos ×" + _compact_liveops_number(time_multiplier)
				data.descricao = "Multiplica por ×" + _compact_liveops_number(time_multiplier) + " a duração dos ciclos."
		"maos_santas":
			var multiplier := LiveOps.holy_hands_manual_multiplier()
			data.efeito = "Toque manual ×" + _compact_liveops_number(multiplier)
			data.descricao = "Cada ciclo iniciado manualmente entrega ×" + _compact_liveops_number(multiplier) + " mais Fé."
	return data


func _compact_liveops_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return str(snappedf(value, 0.01))


func _compact_liveops_duration(seconds: float) -> String:
	if seconds >= 3600.0:
		return _compact_liveops_number(seconds / 3600.0) + " h"
	if seconds >= 60.0:
		return _compact_liveops_number(seconds / 60.0) + " min"
	return _compact_liveops_number(seconds) + " s"

func get_boost_inventory(boost_id: String) -> int:
	return maxi(0, int(boost_inventory.get(boost_id, 0)))

func get_boost_remaining(boost_id: String) -> int:
	return maxi(0, int(float(boosts.get(boost_id, 0.0)) - Time.get_unix_time_from_system()))

func is_boost_active(boost_id: String) -> bool:
	return get_boost_remaining(boost_id) > 0

func get_boost_production_multiplier() -> float:
	var mult := 1.0
	if is_boost_active("fervor"):
		mult *= LiveOps.fervor_production_multiplier()
	if is_boost_active("pentecoste"):
		mult *= LiveOps.pentecost_production_multiplier()
	return mult

func get_manual_boost_multiplier() -> float:
	var boost_multiplier := LiveOps.holy_hands_manual_multiplier() if is_boost_active("maos_santas") else 1.0
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
		var currency := str(ADVENTURES[active_adventure].generator_currency)
		var harvest := get_receita_por_segundo(active_adventure) * LiveOps.harvest_seconds()
		add_currency(currency, harvest)
		EventBus.toast_requested.emit("Colheita recebida: +" + NumberFormat.format(harvest) + " " + get_currency_name(currency))
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
	_init_adventure_progress()
	_load_adventure_progress("jornada")
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
	if adventure_id != active_adventure:
		return false
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
	_grant_adventure_starting_currency(adventure_id)
	EventBus.adventure_unlocked.emit(adventure_id)
	EventBus.toast_requested.emit("Nova aventura desbloqueada: " + _adventure_display_name(adventure_id))
	return true

func _grant_adventure_starting_currency(adventure_id: String) -> void:
	var data: Dictionary = ADVENTURES.get(adventure_id, {})
	var currency := str(data.get("generator_currency", "fe"))
	var starting_currency := float(data.get("starting_currency", 0.0))
	if currency == "fe" or starting_currency <= 0.0:
		return
	# O total historico funciona como recibo da concessao unica. Assim, saves
	# antigos travados em zero recebem a largada, sem reabrir um recurso infinito.
	var historical_total := graca_total if currency == "graca" else gloria_total
	if historical_total > 0.0:
		return
	var missing := starting_currency - get_currency_amount(currency)
	if missing > 0.0:
		_set_currency_amount(currency, get_currency_amount(currency) + missing)
		if currency == "graca":
			graca_total = maxf(graca_total, starting_currency)
		else:
			gloria_total = maxf(gloria_total, starting_currency)

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
	if Geradores.get_adventure_for_id(gen_id) != active_adventure:
		return false
	if amount <= 0:
		return false
	if not is_unlocked(gen_id):
		return false
	var currency := get_currency_for_gen(gen_id)
	var saldo := get_currency_amount(currency)
	var state: Dictionary = geradores[gen_id]
	var custo: float = Economy.custo_lote(gen_id, amount, state.qtd)
	if saldo < custo:
		amount = Economy.max_compravel(gen_id, saldo, state.qtd)
		if amount <= 0:
			return false
		custo = Economy.custo_lote(gen_id, amount, state.qtd)
	spend_currency(currency, custo)
	state.qtd += amount
	geradores[gen_id] = state
	maior_qtd_gerador[gen_id] = max(int(maior_qtd_gerador.get(gen_id, 0)), int(state.qtd))
	_check_adventure_completion(gen_id)
	_check_marcos_gerais(Geradores.get_adventure_for_id(gen_id))
	EventBus.generator_changed.emit(gen_id)
	return true

const MILESTONE_BUYER_DADIVA := "d_comprador_marcos"

func has_blessing_buyer() -> bool:
	return MILESTONE_BUYER_DADIVA in dadivas_compradas

# Monta o pacote de bencaos ja liberadas que cada saldo consegue pagar. Como as
# aventuras usam moedas isoladas, cada caixa e simulada separadamente.
func get_blessing_purchase_plan() -> Dictionary:
	var balances := {
		"fe": fe,
		"graca": graca,
		"gloria": gloria,
	}
	var result := {
		"enabled": has_blessing_buyer(),
		"totals": {"fe": 0.0, "graca": 0.0, "gloria": 0.0},
		"count": 0,
		"purchases": [],
		"remaining": balances.duplicate(),
	}
	if not result.enabled:
		return result

	var purchases: Array[Dictionary] = []
	var totals: Dictionary = result.totals
	var remaining: Dictionary = result.remaining
	for upgrade_value: Variant in Upgrades.disponiveis():
		var upgrade: Dictionary = upgrade_value as Dictionary
		var currency := Upgrades.currency_for(upgrade)
		var cost := float(upgrade.custo)
		var available := float(remaining.get(currency, 0.0))
		if cost > available and not is_equal_approx(cost, available):
			continue
		purchases.append({"upgrade_id": str(upgrade.id), "currency": currency, "cost": cost})
		totals[currency] = float(totals.get(currency, 0.0)) + cost
		remaining[currency] = maxf(available - cost, 0.0)
	result.purchases = purchases
	result.count = purchases.size()
	result.totals = totals
	result.remaining = remaining
	return result

func buy_all_available_blessings() -> Dictionary:
	var plan := get_blessing_purchase_plan()
	if not bool(plan.enabled) or int(plan.count) <= 0:
		return {"count": 0, "totals": plan.totals}
	var totals: Dictionary = plan.totals
	# Valida o lote inteiro antes do primeiro debito para a operacao ser atomica.
	for currency in ["fe", "graca", "gloria"]:
		if get_currency_amount(currency) < float(totals.get(currency, 0.0)):
			return {"count": 0, "totals": totals}
	for currency in ["fe", "graca", "gloria"]:
		var total := float(totals.get(currency, 0.0))
		if total > 0.0:
			spend_currency(currency, total)

	var purchased_ids: Array[String] = []
	for purchase_value: Variant in plan.purchases:
		var purchase: Dictionary = purchase_value as Dictionary
		var upgrade_id := str(purchase.upgrade_id)
		# O plano ja filtrou compradas, requisitos e saldo. Mutar diretamente evita
		# N recomputacoes, N reconstrucoes da lista e N notificacoes consecutivas.
		upgrades_comprados.append(upgrade_id)
		purchased_ids.append(upgrade_id)
	Economy.recompute_multiplicadores()
	EventBus.upgrades_batch_purchased.emit(purchased_ids)
	EventBus.toast_requested.emit("Comprador de Bencaos: " + str(purchased_ids.size()) + " adquiridas")
	return {"count": purchased_ids.size(), "totals": totals}

# Marcos gerais: bonus recorrentes sao computados ao vivo (Economy); aqui so as
# recompensas unicas (gemas/reliquias), pagas 1x por marco via ledger.
func _check_marcos_gerais(adventure_id: String) -> void:
	var minimo := Economy.marco_min_qtd(adventure_id)
	var pagos: Array = marcos_ledger.get(adventure_id, [])
	for marco_value: Variant in LiveOps.general_milestones():
		var marco: Dictionary = marco_value as Dictionary
		var alvo := int(marco.quantity)
		if minimo < alvo or alvo in pagos:
			continue
		pagos.append(alvo)
		var partes: Array[String] = []
		var relics := int(marco.relics)
		if relics > 0:
			reliquias += relics
			EventBus.relics_changed.emit(reliquias)
			partes.append("+" + str(relics) + " Relíquias")
		var gems := LiveOps.scale_free_gem_reward(int(marco.gems))
		if gems > 0:
			add_gemas(gems, "marco geral")
		var efeito := ("velocidade ×" if str(marco.type) == "speed" else "produção ×") + str(float(marco.multiplier))
		partes.append(efeito)
		EventBus.marco_geral_reached.emit(adventure_id, alvo)
		EventBus.toast_requested.emit("Marco geral: todos em " + str(alvo) + "!  " + "  ·  ".join(partes))
		Economy.recompute_multiplicadores()
	marcos_ledger[adventure_id] = pagos

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
	add_gemas(LiveOps.scale_free_gem_reward(50 if adventure_id == "vida_cristo" else 100), "aventura concluída")

func buy_prophet(gen_id: int) -> bool:
	if Geradores.get_adventure_for_id(gen_id) != active_adventure:
		return false
	if not Economy.profeta_disponivel(gen_id):
		return false
	var data: Dictionary = Geradores.get_data(gen_id)
	var custo: float = Economy.get_profeta_custo(gen_id)
	var currency := get_currency_for_gen(gen_id)
	if not spend_currency(currency, custo):
		return false
	var state: Dictionary = geradores[gen_id]
	state.tem_profeta = true
	if state.tempo_restante < 0:
		state.tempo_restante = Economy.get_tempo_ciclo(gen_id)
	geradores[gen_id] = state
	EventBus.prophet_changed.emit(gen_id)
	EventBus.toast_requested.emit("Profeta contratado: " + data.profeta_nome + "  ·  ciclos 25% mais rápidos")
	return true

func buy_upgrade(upgrade_id: String) -> bool:
	if upgrade_id in upgrades_comprados:
		return false
	var u: Dictionary = Upgrades.get_data(upgrade_id)
	if u.is_empty():
		return false
	if Upgrades.adventure_for(u) != active_adventure:
		return false
	if not Upgrades.requisito_atingido(u):
		return false
	var currency := Upgrades.currency_for(u)
	if not spend_currency(currency, float(u.custo)):
		return false
	upgrades_comprados.append(upgrade_id)
	Economy.recompute_multiplicadores()
	EventBus.upgrade_purchased.emit(upgrade_id)
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

# Escada infinita "Frutos do Espirito": sempre existe um proximo nivel.
func buy_dadiva_frutos() -> bool:
	var custo := Dadivas.ladder_cost(dadiva_frutos_nivel)
	if santos < custo:
		return false
	santos -= custo
	santos_gastos += custo
	dadiva_frutos_nivel += 1
	Economy.recompute_multiplicadores()
	EventBus.dadiva_purchased.emit("frutos_" + str(dadiva_frutos_nivel))
	EventBus.toast_requested.emit("Frutos do Espírito " + str(dadiva_frutos_nivel) + ": produção global ×" + String.num(pow(LiveOps.dadiva_ladder_multiplier(), dadiva_frutos_nivel), 2))
	return true

# ------------------------------------------------------------ Estrela Nova

func can_claim_star_gem() -> bool:
	return LiveOps.server_adjusted_now() - nova_star_last_gem_claim >= 24 * 3600

func claim_nova_star(current_adventure: String) -> Dictionary:
	# Recompensa base: alguns minutos da producao atual da aventura em foco
	# (fallback fixo no comeco do jogo, quando a renda ainda e zero).
	var currency := str(ADVENTURES.get(current_adventure, {}).get("generator_currency", "fe"))
	var producao := Economy.receita_total_por_segundo(current_adventure)
	var ganho := producao * LiveOps.nova_star_production_seconds()
	if ganho < 10.0:
		ganho = 10.0
	add_currency(currency, ganho)
	var resultado := {
		"currency": currency,
		"amount": ganho,
		"gems": 0,
	}
	if can_claim_star_gem():
		var gems := LiveOps.scale_free_gem_reward(LiveOps.nova_star_daily_gems())
		if gems > 0:
			nova_star_last_gem_claim = LiveOps.server_adjusted_now()
			add_gemas(gems, "Estrela Nova")
			resultado.gems = gems
	SaveSystem.save_game()
	return resultado

# ------------------------------------------------------------ Cosmeticos

func buy_cosmetic(cosmetic_id: String) -> bool:
	if cosmetic_id in cosmeticos_comprados:
		return false
	var data: Dictionary = Cosmeticos.get_data(cosmetic_id)
	if data.is_empty():
		return false
	if reliquias < int(data.custo):
		return false
	reliquias -= int(data.custo)
	cosmeticos_comprados.append(cosmetic_id)
	# Equipa na hora: comprar cosmetico sem ver o efeito frustra.
	cosmeticos_ativos[str(data.categoria)] = cosmetic_id
	EventBus.relics_changed.emit(reliquias)
	EventBus.cosmetic_changed.emit()
	EventBus.toast_requested.emit("Cosmético adquirido: " + str(data.nome))
	SaveSystem.save_game()
	return true

func equip_cosmetic(cosmetic_id: String) -> bool:
	var data: Dictionary = Cosmeticos.get_data(cosmetic_id)
	if data.is_empty() or cosmetic_id not in cosmeticos_comprados:
		return false
	var categoria := str(data.categoria)
	if str(cosmeticos_ativos.get(categoria, "")) == cosmetic_id:
		cosmeticos_ativos.erase(categoria)  # toque de novo = volta ao padrao
	else:
		cosmeticos_ativos[categoria] = cosmetic_id
	EventBus.cosmetic_changed.emit()
	SaveSystem.save_game()
	return true

func start_cycle(gen_id: int) -> bool:
	if not geradores.has(gen_id):
		return false
	if Geradores.get_adventure_for_id(gen_id) != active_adventure:
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
	# Ciclos creditam a moeda da aventura do gerador (economias isoladas).
	var ganhos: Dictionary = {}
	for gen_id in geradores:
		if Geradores.get_adventure_for_id(gen_id) != active_adventure:
			continue
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
			var currency := get_currency_for_gen(gen_id)
			ganhos[currency] = float(ganhos.get(currency, 0.0)) + receita
			if state.tem_profeta:
				# Carrega o excedente negativo em vez de descartá-lo (preserva a taxa real).
				state.tempo_restante += Economy.get_tempo_ciclo(gen_id)
			else:
				state.tempo_restante = -1.0
			EventBus.generator_cycle_complete.emit(gen_id, receita)
		geradores[gen_id] = state
	for currency in ganhos:
		add_currency(currency, ganhos[currency])

func get_receita_por_segundo(adventure_id: String = "jornada") -> float:
	if adventure_id != active_adventure:
		return 0.0
	return Economy.receita_total_por_segundo(adventure_id)

func get_receita_por_segundo_gerador(gen_id: int) -> float:
	if Geradores.get_adventure_for_id(gen_id) != active_adventure:
		return 0.0
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
	add_gemas(LiveOps.scale_free_gem_reward(10 if estatisticas.prestiges == 1 else 2), "Ressurreição")
	var adventure: Dictionary = ADVENTURES[active_adventure]
	var currency := str(adventure.generator_currency)
	_set_currency_amount(currency, float(adventure.get("starting_currency", FE_INICIAL)))
	fe_total_vida = 0.0
	for gen_id in geradores:
		if gen_id < int(adventure.first_generator) or gen_id > int(adventure.last_generator):
			continue
		geradores[gen_id] = {
			"qtd": 0,
			"tem_profeta": false,
			"tempo_restante": -1.0,
		}
	upgrades_comprados.clear()
	_apply_start_units()
	_sync_active_adventure()
	Economy.recompute_multiplicadores()
	EventBus.prestige_done.emit()
	EventBus.toast_requested.emit("Ressurreição! +" + str(ganhos) + " " + get_prestige_name())
	return ganhos

# Dadivas "Primicias": apos o prestige, comeca com N unidades dos geradores da
# faixa. Usa o maior valor entre as dadivas possuidas para cada gerador.
func _apply_start_units() -> void:
	var adventure: Dictionary = ADVENTURES[active_adventure]
	var base_id := int(adventure.first_generator)
	var last_id := int(adventure.last_generator)
	for dadiva_id in dadivas_compradas:
		var d: Dictionary = Dadivas.get_data(str(dadiva_id))
		if d.is_empty() or str(d.get("tipo", "")) != "start_units":
			continue
		var unidades := int(d.mult)
		var first_relative := int(d.get("start_first", 1)) - 1
		var last_relative := int(d.get("start_last", 1)) - 1
		for gen_id in range(base_id + first_relative, mini(base_id + last_relative, last_id) + 1):
			if not geradores.has(gen_id):
				continue
			var state: Dictionary = geradores[gen_id]
			if int(state.qtd) < unidades:
				state.qtd = unidades
				geradores[gen_id] = state
				maior_qtd_gerador[gen_id] = max(int(maior_qtd_gerador.get(gen_id, 0)), unidades)

func get_santos_proximo_prestige() -> int:
	return Economy.santos_ganhos(fe_total_vida)

func get_save_data() -> Dictionary:
	_sync_active_adventure()
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
		"activeAdventure": active_adventure,
		"adventureProgress": adventure_progress.duplicate(true),
		"lastSeen": Time.get_unix_time_from_system(),
		"fe": fe,
		"santos": santos,
		"santosGastos": santos_gastos,
		"reliquias": reliquias,
		"gemas": gemas,
		"gemasTotal": gemas_total,
		"feTotalVida": fe_total_vida,
		"feTotalHistorica": fe_total_historica,
		"graca": graca,
		"gloria": gloria,
		"gracaTotal": graca_total,
		"gloriaTotal": gloria_total,
		"dadivaFrutosNivel": dadiva_frutos_nivel,
		"marcosLedger": marcos_ledger.duplicate(true),
		"moedaMarcosLedger": moeda_marcos_ledger.duplicate(true),
		"cosmeticosComprados": cosmeticos_comprados.duplicate(),
		"cosmeticosAtivos": cosmeticos_ativos.duplicate(true),
		"novaStarLastGemClaim": nova_star_last_gem_claim,
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

func _reset_alpha_progress() -> void:
	fe = FE_INICIAL
	graca = 0.0
	gloria = 0.0
	santos = 0
	santos_gastos = 0
	reliquias = 0
	gemas = 0
	gemas_total = 0
	fe_total_vida = 0.0
	fe_total_historica = 0.0
	graca_total = 0.0
	gloria_total = 0.0
	dadiva_frutos_nivel = 0
	marcos_ledger.clear()
	moeda_marcos_ledger.clear()
	cosmeticos_comprados.clear()
	cosmeticos_ativos.clear()
	nova_star_last_gem_claim = 0.0
	upgrades_comprados.clear()
	dadivas_compradas.clear()
	sabedoria = 0
	sabedoria_total = 0
	estudo_progresso = _default_study_progress()
	conhecimentos_comprados.clear()
	conhecimentos_ativos.clear()
	aventuras_desbloqueadas = ["jornada"]
	aventuras_concluidas.clear()
	boosts.clear()
	boost_inventory.clear()
	reward_video_window_started = 0.0
	reward_videos_watched = 0
	daily_boost_video_last_claimed = 0.0
	daily_boost_video_last_reward = ""
	estatisticas = ESTATISTICAS_DEFAULT.duplicate()
	active_adventure = "jornada"
	_init_geradores()
	maior_qtd_gerador.clear()
	_init_adventure_progress()
	_load_adventure_progress(active_adventure)
	Economy.recompute_multiplicadores()

func load_save_data(data: Dictionary) -> void:
	if int(data.get("version", 0)) != SAVE_VERSION:
		_reset_alpha_progress()
		EventBus.ui_needs_update.emit()
		return
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
	graca = maxf(0.0, float(data.get("graca", 0.0)))
	gloria = maxf(0.0, float(data.get("gloria", 0.0)))
	graca_total = maxf(graca, float(data.get("gracaTotal", graca)))
	gloria_total = maxf(gloria, float(data.get("gloriaTotal", gloria)))
	dadiva_frutos_nivel = maxi(0, int(data.get("dadivaFrutosNivel", 0)))
	nova_star_last_gem_claim = maxf(0.0, float(data.get("novaStarLastGemClaim", 0.0)))
	marcos_ledger = {}
	var marcos_save: Dictionary = data.get("marcosLedger", {})
	for adventure_key in marcos_save:
		if ADVENTURES.has(str(adventure_key)) and marcos_save[adventure_key] is Array:
			var valores: Array = []
			for item in (marcos_save[adventure_key] as Array):
				var quantidade := int(item)
				if quantidade > 0 and quantidade not in valores:
					valores.append(quantidade)
			marcos_ledger[str(adventure_key)] = valores
	moeda_marcos_ledger = {}
	var moeda_save: Dictionary = data.get("moedaMarcosLedger", {})
	for adventure_key in moeda_save:
		if ADVENTURES.has(str(adventure_key)) and moeda_save[adventure_key] is Array:
			moeda_marcos_ledger[str(adventure_key)] = _unique_string_array(moeda_save[adventure_key])
	cosmeticos_comprados = []
	for cosmetic_id in _unique_string_array(data.get("cosmeticosComprados", [])):
		if not Cosmeticos.get_data(cosmetic_id).is_empty():
			cosmeticos_comprados.append(cosmetic_id)
	cosmeticos_ativos = {}
	var ativos_save: Dictionary = data.get("cosmeticosAtivos", {})
	for categoria_key in ativos_save:
		var cosmetic_id := str(ativos_save[categoria_key])
		if cosmetic_id in cosmeticos_comprados:
			cosmeticos_ativos[str(categoria_key)] = cosmetic_id
	upgrades_comprados = _unique_string_array(data.get("upgradesComprados", []))
	dadivas_compradas = _unique_string_array(data.get("dadivasCompradas", []))
	aventuras_desbloqueadas = _unique_string_array(data.get("aventurasDesbloqueadas", ["jornada"]))
	aventuras_concluidas = _unique_string_array(data.get("aventurasConcluidas", []))
	boosts.clear()
	var saved_boosts: Dictionary = data.get("boosts", {})
	for boost_id in saved_boosts:
		# Expirações recentes também são necessárias para segmentar corretamente
		# os impulsos que terminaram durante o período offline.
		if BOOSTS.has(str(boost_id)) and float(saved_boosts[boost_id]) > 0.0:
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
	_init_adventure_progress()
	var progress_save: Dictionary = data.get("adventureProgress", {})
	for adventure_id in ADVENTURES:
		var raw: Dictionary = progress_save.get(adventure_id, {})
		if raw.is_empty():
			continue
		var progress := _new_adventure_progress()
		progress.prestige = maxi(0, int(raw.get("prestige", 0)))
		progress.prestige_spent = maxi(0, int(raw.get("prestige_spent", 0)))
		progress.run_total = maxf(0.0, float(raw.get("run_total", 0.0)))
		progress.fruit_level = maxi(0, int(raw.get("fruit_level", 0)))
		progress.upgrades = _unique_string_array(raw.get("upgrades", []))
		progress.gifts = _unique_string_array(raw.get("gifts", []))
		progress.boosts = (raw.get("boosts", {}) as Dictionary).duplicate(true)
		progress.boost_inventory = (raw.get("boost_inventory", {}) as Dictionary).duplicate(true)
		progress.prestiges = maxi(0, int(raw.get("prestiges", 0)))
		adventure_progress[adventure_id] = progress
	active_adventure = str(data.get("activeAdventure", "jornada"))
	if active_adventure not in aventuras_desbloqueadas or not ADVENTURES.has(active_adventure):
		active_adventure = "jornada"
	_load_adventure_progress(active_adventure)
	for adventure_id in aventuras_desbloqueadas:
		_grant_adventure_starting_currency(str(adventure_id))
	Economy.recompute_multiplicadores()
	EventBus.faith_changed.emit(fe)
	EventBus.wisdom_changed.emit(sabedoria)
	EventBus.cosmetic_changed.emit()

func _boost_active_at_adjusted_time(boost_id: String, at_time: float) -> bool:
	var local_expiry := float(boosts.get(boost_id, 0.0))
	var adjusted_expiry := local_expiry + LiveOps.server_time_offset_seconds()
	return local_expiry > 0.0 and at_time < adjusted_expiry


func _offline_weighted_multiplier(start_at: float, end_at: float, generator_id: int) -> float:
	if end_at <= start_at:
		return 1.0
	var weighted := 0.0
	var total_duration := end_at - start_at
	for campaign_segment_value: Variant in LiveOps.effect_segments(start_at, end_at):
		var campaign_segment: Dictionary = campaign_segment_value as Dictionary
		var segment_start := float(campaign_segment.startsAt)
		var segment_end := float(campaign_segment.endsAt)
		var boundaries: Array[float] = [segment_start, segment_end]
		for boost_id: String in ["fervor", "pentecoste", "passo_ligeiro"]:
			var expiry := float(boosts.get(boost_id, 0.0)) + LiveOps.server_time_offset_seconds()
			if expiry > segment_start and expiry < segment_end:
				boundaries.append(expiry)
		boundaries.sort()
		for index in range(boundaries.size() - 1):
			var part_start := boundaries[index]
			var part_end := boundaries[index + 1]
			var midpoint := part_start + (part_end - part_start) * 0.5
			var effects: Dictionary = campaign_segment.effects as Dictionary
			var generator_multiplier := float(
				(effects.generatorProductionMultipliers as Dictionary).get(str(generator_id), 1.0)
			)
			var multiplier := float(effects.globalProductionMultiplier) \
				* float(effects.offlineProductionMultiplier) \
				* generator_multiplier
			if _boost_active_at_adjusted_time("fervor", midpoint):
				multiplier *= LiveOps.fervor_production_multiplier()
			if _boost_active_at_adjusted_time("pentecoste", midpoint):
				multiplier *= LiveOps.pentecost_production_multiplier()
			if _boost_active_at_adjusted_time("passo_ligeiro", midpoint):
				multiplier *= 1.0 / LiveOps.swift_step_time_multiplier()
			multiplier = minf(multiplier, LiveOps.MAX_EFFECTIVE_PRODUCTION_MULTIPLIER)
			weighted += (part_end - part_start) * multiplier
	return weighted / total_duration


func apply_offline_production(seconds: float) -> float:
	var cap: float = Economy.get_offline_cap()
	if seconds > cap:
		seconds = cap
	if seconds <= 0.0:
		return 0.0
	# O intervalo termina no relógio ajustado pelo Worker. Cada gerador integra
	# campanhas por segmentos [startsAt, endsAt), inclusive eventos já encerrados
	# que ainda vieram na janela histórica do endpoint.
	var interval_end := LiveOps.server_adjusted_now()
	var interval_start := interval_end - seconds
	var totais: Dictionary = {}
	for gen_id in geradores:
		if Geradores.get_adventure_for_id(gen_id) != active_adventure:
			continue
		var state: Dictionary = geradores[gen_id]
		if not state.tem_profeta or state.qtd <= 0:
			continue
		var data: Dictionary = Geradores.get_data(gen_id)
		var ciclos: float = seconds / Economy.get_tempo_ciclo_persistent(gen_id)
		var campaign_weight := _offline_weighted_multiplier(interval_start, interval_end, gen_id)
		var receita: float = data.receita_base \
			* float(state.qtd) \
			* Economy.get_gerador_multiplicador_offline_base(gen_id) \
			* campaign_weight \
			* ciclos
		var currency := get_currency_for_gen(gen_id)
		totais[currency] = float(totais.get(currency, 0.0)) + receita
	# O multiplicador LiveOps offline já foi integrado em campaign_weight.
	var offline_mult := Economy.get_offline_mult_base()
	for currency in totais:
		add_currency(currency, float(totais[currency]) * offline_mult)
	for boost_id: Variant in boosts.keys():
		if float(boosts[boost_id]) <= Time.get_unix_time_from_system():
			boosts.erase(boost_id)
	var active_currency := str(ADVENTURES[active_adventure].generator_currency)
	return float(totais.get(active_currency, 0.0)) * offline_mult

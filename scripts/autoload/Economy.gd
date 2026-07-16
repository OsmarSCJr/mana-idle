extends Node

# Defaults e overrides validados vivem em LiveOps. Os getters abaixo preservam
# a economia offline mesmo quando a consulta remota falha.

# Caches derivados de upgrades_comprados + dadivas_compradas.
# Recalculados em recompute_multiplicadores() (compra, prestige, load).
var _prod_gen: Dictionary = {}       # gen_id -> mult de producao
var _tempo_gen: Dictionary = {}      # gen_id -> mult de tempo de ciclo (<1 = mais rapido)
var _custo_gen: Dictionary = {}      # gen_id -> mult de custo (<1 = mais barato)
var _global_prod: float = 1.0        # upgrades globais + dadivas
var _santo_bonus_extra: float = 0.0  # aditivo por Santo (dadiva Comunhao)
var _offline_mult: float = 1.0
var _offline_cap_mult: float = 1.0
var _offline_cap_bonus: float = 0.0
var _manual_knowledge_mult: float = 1.0
var _prophet_cost_mult: float = 1.0
var _boost_duration_mult: float = 1.0
var _study_faith_mult: float = 1.0
var _adventure_fe_discount: float = 1.0
var _adventure_gem_discount: float = 1.0
var _x100_unlocked: bool = false


func _ready() -> void:
	LiveOps.config_changed.connect(func(_summary: Dictionary): recompute_multiplicadores())

func recompute_multiplicadores() -> void:
	_prod_gen.clear()
	_tempo_gen.clear()
	_custo_gen.clear()
	_global_prod = 1.0
	_santo_bonus_extra = 0.0
	_offline_mult = 1.0
	_offline_cap_mult = 1.0
	_offline_cap_bonus = 0.0
	_manual_knowledge_mult = 1.0
	_prophet_cost_mult = 1.0
	_boost_duration_mult = 1.0
	_study_faith_mult = 1.0
	_adventure_fe_discount = 1.0
	_adventure_gem_discount = 1.0
	_x100_unlocked = false

	for uid in GameState.upgrades_comprados:
		var u: Dictionary = Upgrades.get_data(uid)
		if u.is_empty():
			continue
		match u.tipo:
			"prod":
				_apply_gen_mult(_prod_gen, u, u.mult)
			"global":
				_global_prod *= u.mult
			"speed":
				_apply_gen_mult(_tempo_gen, u, u.mult)
			"discount":
				_apply_gen_mult(_custo_gen, u, u.mult)
			"unlock":
				if u.id == "u4_4":
					_x100_unlocked = true

	for did in GameState.dadivas_compradas:
		var d: Dictionary = Dadivas.get_data(did)
		if d.is_empty():
			continue
		match d.tipo:
			"santo_bonus":
				_santo_bonus_extra += d.mult
			"global_prod":
				_global_prod *= d.mult
			"offline_mult":
				_offline_mult *= d.mult
			"offline_cap":
				_offline_cap_mult *= d.mult
			"discount":
				for i in range(1, Geradores.count() + 1):
					_custo_gen[i] = _custo_gen.get(i, 1.0) * d.mult

	# Conhecimentos comprados podem ser ativados ou guardados para outra build.
	for knowledge_id in GameState.conhecimentos_ativos:
		var knowledge: Dictionary = Conhecimentos.get_data(knowledge_id)
		if knowledge.is_empty():
			continue
		var effect: Dictionary = knowledge.get("effect", {})
		var value := float(effect.get("value", 1.0))
		match str(effect.get("type", "")):
			"offline_mult":
				_offline_mult *= value
			"offline_cap_seconds":
				_offline_cap_bonus += value
			"discount_global":
				for i in range(1, Geradores.count() + 1):
					_custo_gen[i] = _custo_gen.get(i, 1.0) * value
			"global_prod":
				_global_prod *= value
			"global_speed":
				for i in range(1, Geradores.count() + 1):
					_tempo_gen[i] = _tempo_gen.get(i, 1.0) * value
			"manual_mult":
				_manual_knowledge_mult *= value
			"santo_bonus":
				_santo_bonus_extra += value
			"prophet_discount":
				_prophet_cost_mult *= value
			"boost_duration":
				_boost_duration_mult *= value
			"study_faith":
				_study_faith_mult *= value
			"adventure_fe_discount":
				_adventure_fe_discount *= value
			"adventure_gem_discount":
				_adventure_gem_discount *= value

	# Paginas Iluminadas concedem um bonus pequeno apenas a sua era.
	var pages: Array = GameState.estudo_progresso.get("paginasIluminadas", [])
	for page_id in pages:
		var first := 0
		var last := -1
		match str(page_id):
			"genesis":
				first = 1
				last = 4
			"exodus", "exodus_conquest", "exodo":
				first = 5
				last = 8
			"kingdom", "reino":
				first = 9
				last = 12
			"christ_birth":
				first = 13
				last = 16
			"christ_ministry":
				first = 17
				last = 20
			"christ_resurrection":
				first = 21
				last = 24
			"early_church":
				first = 25
				last = 28
			"expansion_reformation":
				first = 29
				last = 32
			"revelation_renewal":
				first = 33
				last = 36
		for gen_id in range(first, last + 1):
			_prod_gen[gen_id] = _prod_gen.get(gen_id, 1.0) * 1.02

	if "igreja_apocalipse" in GameState.aventuras_concluidas:
		_global_prod *= 2.0

# Aplica mult a um gerador, a uma era inteira ou a todos, conforme o alvo do upgrade.
func _apply_gen_mult(cache: Dictionary, u: Dictionary, mult: float) -> void:
	match u.alvo:
		"g":
			cache[u.alvo_id] = cache.get(u.alvo_id, 1.0) * mult
		"era":
			for d in Geradores.get_by_era(u.alvo_id):
				cache[d.id] = cache.get(d.id, 1.0) * mult
		"global":
			for i in range(1, Geradores.count() + 1):
				cache[i] = cache.get(i, 1.0) * mult

func is_x100_unlocked() -> bool:
	return _x100_unlocked

func get_desconto(gen_id: int) -> float:
	return _custo_gen.get(gen_id, 1.0)

func get_tempo_ciclo(gen_id: int) -> float:
	return _get_tempo_ciclo(gen_id, true)


func get_tempo_ciclo_persistent(gen_id: int) -> float:
	return _get_tempo_ciclo(gen_id, false)


func _get_tempo_ciclo(gen_id: int, include_temporary_boost: bool) -> float:
	var data: Dictionary = Geradores.get_data(gen_id)
	var tempo: float = data.tempo * _tempo_gen.get(gen_id, 1.0)
	if include_temporary_boost and GameState.is_boost_active("passo_ligeiro"):
		tempo *= LiveOps.swift_step_time_multiplier()
	# tempo_min e o teto de aceleracao do gerador: com todas as bencaos de
	# velocidade ativas, o ciclo chega exatamente ai e nao passa disso.
	return max(tempo, float(data.get("tempo_min", 0.1)))

func custo_unitario(gen_id: int, ja_possui: int) -> float:
	var data: Dictionary = Geradores.get_data(gen_id)
	return data.custo_base * get_desconto(gen_id) * pow(LiveOps.growth_rate(), ja_possui)

func custo_lote(gen_id: int, qtd: int, ja_possui: int) -> float:
	if qtd <= 0:
		return 0.0
	var base: float = custo_unitario(gen_id, ja_possui)
	var growth_rate := LiveOps.growth_rate()
	return base * (pow(growth_rate, qtd) - 1.0) / (growth_rate - 1.0)

func max_compravel(gen_id: int, fe_disponivel: float, ja_possui: int) -> int:
	var base: float = custo_unitario(gen_id, ja_possui)
	var growth_rate := LiveOps.growth_rate()
	var ratio: float = fe_disponivel * (growth_rate - 1.0) / base + 1.0
	if ratio <= 1.0:
		return 0
	return int(log(ratio) / log(growth_rate))

func receita_ciclo(gen_id: int, unidades: int) -> float:
	var data: Dictionary = Geradores.get_data(gen_id)
	return data.receita_base * float(unidades)

func receita_por_segundo(gen_id: int, unidades: int, tem_profeta: bool) -> float:
	if unidades <= 0:
		return 0.0
	if not tem_profeta:
		return 0.0
	var data: Dictionary = Geradores.get_data(gen_id)
	return data.receita_base * float(unidades) / get_tempo_ciclo(gen_id)

func receita_total_por_segundo() -> float:
	var total: float = 0.0
	for gen_id in GameState.geradores:
		var state: Dictionary = GameState.geradores[gen_id]
		total += receita_por_segundo(gen_id, state.qtd, state.tem_profeta) \
			* milestone_bonus(state.qtd) \
			* _prod_gen.get(gen_id, 1.0) \
			* LiveOps.generator_production_multiplier(gen_id)
	return total * get_multiplicador_global()

func santos_ganhos(fe_total: float) -> int:
	var prestige_divisor := LiveOps.prestige_divisor()
	if fe_total < prestige_divisor:
		return 0
	# Raiz cubica: o 2o Santo custa 8x o 1o, o 3o custa 27x... segura a
	# multiplicacao rapida de Santos nas runs avancadas.
	return int(pow(fe_total / prestige_divisor, 1.0 / 3.0))

func get_multiplicador_santos() -> float:
	var value_per_saint := LiveOps.saint_bonus() + _santo_bonus_extra
	if "vida_cristo" in GameState.aventuras_concluidas:
		value_per_saint *= 1.5
	return 1.0 + float(GameState.santos) * value_per_saint

func get_multiplicador_global() -> float:
	return get_multiplicador_global_base() * LiveOps.global_production_multiplier()


func get_multiplicador_global_base() -> float:
	return get_multiplicador_global_persistent_base() * GameState.get_boost_production_multiplier()


func get_multiplicador_global_persistent_base() -> float:
	return get_multiplicador_santos() * _global_prod

func get_offline_mult() -> float:
	return get_offline_mult_base() * LiveOps.offline_production_multiplier()


func get_offline_mult_base() -> float:
	return _offline_mult

func get_offline_cap() -> float:
	return LiveOps.offline_cap_seconds() * _offline_cap_mult + _offline_cap_bonus

func get_manual_knowledge_multiplier() -> float:
	return _manual_knowledge_mult * LiveOps.manual_production_multiplier()

func get_boost_duration_multiplier() -> float:
	return _boost_duration_mult

func get_study_faith_multiplier() -> float:
	return _study_faith_mult * LiveOps.study_faith_multiplier()

func get_adventure_fe_discount() -> float:
	return _adventure_fe_discount

func get_adventure_gem_discount() -> float:
	return _adventure_gem_discount

func profeta_disponivel(gen_id: int) -> bool:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	if state.is_empty():
		return false
	return state.qtd >= LiveOps.prophet_unlock_quantity() and not state.tem_profeta

func get_profeta_custo(gen_id: int) -> float:
	var data: Dictionary = Geradores.get_data(gen_id)
	if data.is_empty():
		return 0.0
	var growth_rate := LiveOps.growth_rate()
	var unlock_quantity := LiveOps.prophet_unlock_quantity()
	var custo_liberacao: float = data.custo_base * (pow(growth_rate, unlock_quantity) - 1.0) / (growth_rate - 1.0)
	return custo_liberacao * LiveOps.prophet_cost_multiplier() * _prophet_cost_mult

func profeta_pode_comprar(gen_id: int) -> bool:
	if not profeta_disponivel(gen_id):
		return false
	return GameState.fe >= get_profeta_custo(gen_id)

func next_milestone(qtd: int) -> int:
	var configured := LiveOps.milestones()
	for milestone_value: Variant in configured:
		var alvo := int((milestone_value as Dictionary).quantity)
		if qtd < alvo:
			return alvo
	# Alem de 400 nao ha bonus novos; segue de 100 em 100 como meta.
	var last_target := int((configured[-1] as Dictionary).quantity)
	return maxi(last_target + 100, (floori(qtd / 100.0) + 1) * 100)

func milestone_bonus(qtd: int) -> float:
	var mult: float = 1.0
	for milestone_value: Variant in LiveOps.milestones():
		var milestone: Dictionary = milestone_value as Dictionary
		if qtd >= int(milestone.quantity):
			mult *= float(milestone.multiplier)
	return mult

func get_gerador_multiplicador(gen_id: int) -> float:
	return get_gerador_multiplicador_base(gen_id) \
		* LiveOps.global_production_multiplier() \
		* LiveOps.generator_production_multiplier(gen_id)


func get_gerador_multiplicador_base(gen_id: int) -> float:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	if state.is_empty():
		return 1.0
	return milestone_bonus(state.qtd) * _prod_gen.get(gen_id, 1.0) * get_multiplicador_global_base()


func get_gerador_multiplicador_offline_base(gen_id: int) -> float:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	if state.is_empty():
		return 1.0
	return milestone_bonus(state.qtd) \
		* _prod_gen.get(gen_id, 1.0) \
		* get_multiplicador_global_persistent_base()


func get_prestige_divisor() -> float:
	return LiveOps.prestige_divisor()

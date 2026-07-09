extends Node

const GROWTH_RATE: float = 1.07
const SANTO_BONUS: float = 0.02
const PRESTIGE_DIVISOR: float = 1.0e9

func custo_unitario(gen_id: int, ja_possui: int) -> float:
	var data: Dictionary = Geradores.get_data(gen_id)
	return data.custo_base * pow(GROWTH_RATE, ja_possui)

func custo_lote(gen_id: int, qtd: int, ja_possui: int) -> float:
	if qtd <= 0:
		return 0.0
	var data: Dictionary = Geradores.get_data(gen_id)
	var base: float = data.custo_base * pow(GROWTH_RATE, ja_possui)
	return base * (pow(GROWTH_RATE, qtd) - 1.0) / (GROWTH_RATE - 1.0)

func max_compravel(gen_id: int, fe_disponivel: float, ja_possui: int) -> int:
	var data: Dictionary = Geradores.get_data(gen_id)
	var base: float = data.custo_base * pow(GROWTH_RATE, ja_possui)
	var ratio: float = fe_disponivel * (GROWTH_RATE - 1.0) / base + 1.0
	if ratio <= 1.0:
		return 0
	return int(log(ratio) / log(GROWTH_RATE))

func receita_ciclo(gen_id: int, unidades: int) -> float:
	var data: Dictionary = Geradores.get_data(gen_id)
	return data.receita_base * float(unidades)

func receita_por_segundo(gen_id: int, unidades: int, tem_profeta: bool) -> float:
	if unidades <= 0:
		return 0.0
	var data: Dictionary = Geradores.get_data(gen_id)
	var rev_ciclo: float = data.receita_base * float(unidades)
	var tempo: float = data.tempo
	if tempo <= 0:
		tempo = 0.1
	if not tem_profeta:
		return 0.0
	return rev_ciclo / tempo

func receita_total_por_segundo() -> float:
	var total: float = 0.0
	for gen_id in GameState.geradores:
		var state: Dictionary = GameState.geradores[gen_id]
		total += receita_por_segundo(gen_id, state.qtd, state.tem_profeta) * milestone_bonus(state.qtd)
	return total * get_multiplicador_global()

func santos_ganhos(fe_total: float) -> int:
	if fe_total < PRESTIGE_DIVISOR:
		return 0
	return int(sqrt(fe_total / PRESTIGE_DIVISOR))

func get_multiplicador_santos() -> float:
	return 1.0 + float(GameState.santos) * SANTO_BONUS

func get_multiplicador_global() -> float:
	return get_multiplicador_santos()

func profeta_disponivel(gen_id: int) -> bool:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	if state.is_empty():
		return false
	return state.qtd >= 25 and not state.tem_profeta

func profeta_pode_comprar(gen_id: int) -> bool:
	if not profeta_disponivel(gen_id):
		return false
	var data: Dictionary = Geradores.get_data(gen_id)
	return GameState.fe >= data.profeta_custo

func milestone_bonus(qtd: int) -> float:
	var mult: float = 1.0
	if qtd >= 400:
		mult *= 2.0
	if qtd >= 300:
		mult *= 2.0
	if qtd >= 200:
		mult *= 2.0
	if qtd >= 100:
		mult *= 2.0
	if qtd >= 50:
		mult *= 2.0
	return mult

func get_gerador_multiplicador(gen_id: int) -> float:
	var state: Dictionary = GameState.geradores.get(gen_id, {})
	if state.is_empty():
		return 1.0
	return milestone_bonus(state.qtd) * get_multiplicador_global()

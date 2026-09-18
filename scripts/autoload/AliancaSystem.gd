extends Node

## Aliança: a segunda camada de prestígio, acima dos Santos.
##
## É o que substitui a "corrida aos 10.000" como meta de meses. Libera quando o
## jogador conquista o troféu de uma campanha (todos os geradores na
## Geradores.META_UNIDADES) e é o único reset que atravessa as três campanhas.
##
## RESETA  : Santos, Dádivas, escada de Frutos, geradores, bênçãos e moedas de
##           TODAS as campanhas (as campanhas continuam desbloqueadas).
## PRESERVA: Relíquias, cosméticos, Conhecimentos, Sabedoria, conquistas,
##           devocional, Provações e a própria árvore da Aliança.
##
## O reset é sempre uma escolha explícita do jogador, nunca automático.

const DIVISOR: float = 100.0
const MAX_NOS_POR_ASCENSAO: int = 0  # 0 = sem limite; a moeda e o custo bastam

## Árvore da Aliança. `requer` é uma lista de nós que precisam estar comprados.
## Efeitos são aplicados em Economy.recompute_multiplicadores(), exceto
## start_prophets/start_units, lidos na ascensão e no prestige.
const NOS: Array = [
	{
		"id": "a_alicerce", "nome": "Alicerce", "custo": 1, "requer": [],
		"tipo": "global_prod", "valor": 2.0,
		"efeito": "×2 produção global, para sempre",
		"flavor": "Sobre esta pedra.",
	},
	{
		"id": "a_vigilia_longa", "nome": "Vigília Longa", "custo": 1, "requer": [],
		"tipo": "offline_cap_bonus", "valor": 57600.0,
		"efeito": "+16 h no teto de produção offline",
		"flavor": "Os que vigiam pela noite.",
	},
	{
		"id": "a_primeiro_chamado", "nome": "Primeiro Chamado", "custo": 2, "requer": ["a_alicerce"],
		"tipo": "start_prophets", "valor": 4.0,
		"efeito": "Após cada Ressurreição, os 4 primeiros geradores já vêm com profeta",
		"flavor": "Antes que eu te formasse, eu te conheci.",
	},
	{
		"id": "a_maos_abertas", "nome": "Mãos Abertas", "custo": 2, "requer": ["a_alicerce"],
		"tipo": "saint_bonus", "valor": 0.10,
		"efeito": "Cada Santo vale +10% de produção a mais",
		"flavor": "Dai, e ser-vos-á dado.",
	},
	{
		"id": "a_selo_firme", "nome": "Selo Firme", "custo": 3, "requer": ["a_maos_abertas"],
		"tipo": "selo_bonus", "valor": 0.20,
		"efeito": "+20 pontos percentuais no teto do Selo do Dia",
		"flavor": "Põe-me como selo sobre o teu coração.",
	},
	{
		"id": "a_entendimento", "nome": "Entendimento Dobrado", "custo": 3, "requer": ["a_alicerce"],
		"tipo": "wisdom_mult", "valor": 2.0,
		"efeito": "Toda Sabedoria recebida em dobro",
		"flavor": "Sobre tudo o que se deve guardar, guarda o coração.",
	},
	{
		"id": "a_slots", "nome": "Mente Larga", "custo": 4, "requer": ["a_entendimento"],
		"tipo": "knowledge_slots", "valor": 3.0,
		"efeito": "+3 espaços de Conhecimento ativo",
		"flavor": "Alargaste o meu coração.",
	},
	{
		"id": "a_marcos_maiores", "nome": "Marcos Maiores", "custo": 4, "requer": ["a_primeiro_chamado"],
		"tipo": "marco_mult", "valor": 1.5,
		"efeito": "Marcos gerais de produção valem ×1.5 do valor normal",
		"flavor": "Pedras levantadas para lembrar o caminho.",
	},
	{
		"id": "a_primicias_eternas", "nome": "Primícias Eternas", "custo": 5, "requer": ["a_primeiro_chamado"],
		"tipo": "start_units", "valor": 100.0,
		"efeito": "Após cada Ressurreição, comece com 100 unidades em todos os geradores",
		"flavor": "O primeiro fruto pertence a quem plantou.",
	},
	{
		"id": "a_porta_aberta", "nome": "Porta Aberta", "custo": 5, "requer": ["a_vigilia_longa"],
		"tipo": "adventure_discount", "valor": 0.5,
		"efeito": "Entrada das campanhas custa metade",
		"flavor": "Eis que te pus diante uma porta aberta.",
	},
	{
		"id": "a_escada_suave", "nome": "Escada Suave", "custo": 6, "requer": ["a_maos_abertas"],
		"tipo": "ladder_discount", "valor": 0.6,
		"efeito": "Frutos do Espírito custam 40% menos Santos",
		"flavor": "Degrau por degrau, sem pressa.",
	},
	{
		"id": "a_sopro_constante", "nome": "Sopro Constante", "custo": 7, "requer": ["a_marcos_maiores"],
		"tipo": "global_speed", "valor": 0.75,
		"efeito": "Ciclos 25% mais rápidos, para sempre",
		"flavor": "O vento não para de soprar.",
	},
	{
		"id": "a_colheita_dobrada", "nome": "Colheita Dobrada", "custo": 8, "requer": ["a_porta_aberta"],
		"tipo": "offline_mult", "valor": 2.0,
		"efeito": "×2 produção offline",
		"flavor": "Enquanto dormia, a terra trabalhava.",
	},
	{
		"id": "a_coroa_de_luz", "nome": "Coroa de Luz", "custo": 12,
		"requer": ["a_sopro_constante", "a_colheita_dobrada", "a_primicias_eternas"],
		"tipo": "global_prod", "valor": 5.0,
		"efeito": "×5 produção global, para sempre",
		"flavor": "Recebereis a coroa que não se desvanece.",
	},
]

var _by_id: Dictionary = {}


func _ready() -> void:
	for no in NOS:
		_by_id[str(no.id)] = no


func no_existe(node_id: String) -> bool:
	return _by_id.has(node_id)


func no_data(node_id: String) -> Dictionary:
	return _by_id.get(node_id, {})


func total_nos() -> int:
	return NOS.size()


func estado() -> Dictionary:
	return GameState.alianca


func saldo() -> int:
	return int(estado().get("saldo", 0))


func total_ganho() -> int:
	return int(estado().get("total", 0))


func ascensoes() -> int:
	return int(estado().get("ascensoes", 0))


func nos_comprados() -> Array:
	return estado().get("nos", [])


func tem_no(node_id: String) -> bool:
	return node_id in nos_comprados()


# ------------------------------------------------------------- Desbloqueio

## A Aliança abre com o primeiro troféu de campanha: todos os geradores de alguma
## campanha na meta, registrado no ledger de marcos gerais (pago uma vez só).
func liberada() -> bool:
	if ascensoes() > 0:
		return true
	for adventure_id in GameState.marcos_ledger:
		if Geradores.META_UNIDADES in (GameState.marcos_ledger[adventure_id] as Array):
			return true
	return false


## Santos acumulados em TODAS as campanhas — a Aliança é a camada que junta o que
## as campanhas mantêm isolado.
func santos_totais() -> int:
	GameState._sync_active_adventure()
	var total := 0
	for adventure_id in GameState.adventure_progress:
		var progresso: Dictionary = GameState.adventure_progress[adventure_id]
		total += int(progresso.get("prestige", 0)) + int(progresso.get("prestige_spent", 0))
	return total


## Raiz cúbica como nos Santos: a segunda Aliança custa 8× a primeira. A primeira
## ascensão sempre rende ao menos uma, para o botão nunca prometer zero.
func aliancas_ganhas() -> int:
	if not liberada():
		return 0
	var base := floori(pow(maxf(float(santos_totais()), 0.0) / DIVISOR, 1.0 / 3.0))
	return maxi(base, 1)


func pode_ascender() -> bool:
	return liberada() and aliancas_ganhas() > 0


func ascender() -> Dictionary:
	if not pode_ascender():
		return {"ok": false, "motivo": "bloqueada"}
	var ganhas := aliancas_ganhas()
	var e := estado()
	e.saldo = int(e.get("saldo", 0)) + ganhas
	e.total = int(e.get("total", 0)) + ganhas
	e.ascensoes = int(e.get("ascensoes", 0)) + 1
	GameState.alianca = e
	GameState.reset_para_ascensao()
	Conquistas.verificar()
	EventBus.alianca_changed.emit()
	EventBus.toast_requested.emit("Ascensão! +" + str(ganhas) + (" Aliança" if ganhas == 1 else " Alianças"))
	SaveSystem.save_game()
	return {"ok": true, "ganhas": ganhas, "saldo": int(e.saldo), "ascensoes": int(e.ascensoes)}


# ------------------------------------------------------------------ Árvore

func requisitos_atendidos(node_id: String) -> bool:
	for requerido in (no_data(node_id).get("requer", []) as Array):
		if not tem_no(str(requerido)):
			return false
	return true


func pode_comprar(node_id: String) -> bool:
	var no := no_data(node_id)
	if no.is_empty() or tem_no(node_id):
		return false
	return requisitos_atendidos(node_id) and saldo() >= int(no.custo)


func comprar(node_id: String) -> bool:
	if not pode_comprar(node_id):
		return false
	var no := no_data(node_id)
	var e := estado()
	e.saldo = int(e.get("saldo", 0)) - int(no.custo)
	e.gastas = int(e.get("gastas", 0)) + int(no.custo)
	var lista: Array = e.get("nos", [])
	lista.append(node_id)
	e.nos = lista
	GameState.alianca = e
	Economy.recompute_multiplicadores()
	Conquistas.verificar()
	EventBus.alianca_changed.emit()
	EventBus.toast_requested.emit(str(no.nome) + ": " + str(no.efeito))
	SaveSystem.save_game()
	return true


func disponiveis() -> Array:
	var lista: Array = []
	for no in NOS:
		if not tem_no(str(no.id)) and requisitos_atendidos(str(no.id)):
			lista.append(no)
	return lista


# --------------------------------------------------- Efeitos lidos por fora

func valor_de(tipo: String, padrao: float = 0.0) -> float:
	for node_id in nos_comprados():
		var no := no_data(str(node_id))
		if str(no.get("tipo", "")) == tipo:
			return float(no.valor)
	return padrao


## Quantidade de geradores que já nascem com profeta após a Ressurreição.
func profetas_iniciais() -> int:
	return int(valor_de("start_prophets", 0.0))


## Unidades iniciais concedidas a todos os geradores da campanha após o prestige.
func unidades_iniciais() -> int:
	return int(valor_de("start_units", 0.0))


func slots_conhecimento_extra() -> int:
	return int(valor_de("knowledge_slots", 0.0))


func bonus_selo_extra() -> float:
	return valor_de("selo_bonus", 0.0)


func multiplicador_sabedoria() -> float:
	return maxf(valor_de("wisdom_mult", 1.0), 1.0)


func multiplicador_marcos() -> float:
	return maxf(valor_de("marco_mult", 1.0), 1.0)


func desconto_escada() -> float:
	return clampf(valor_de("ladder_discount", 1.0), 0.01, 1.0)


func resumo() -> Dictionary:
	return {
		"liberada": liberada(),
		"saldo": saldo(),
		"total": total_ganho(),
		"ascensoes": ascensoes(),
		"nos": nos_comprados().size(),
		"nos_total": total_nos(),
		"proximas": aliancas_ganhas(),
		"santos_totais": santos_totais(),
	}

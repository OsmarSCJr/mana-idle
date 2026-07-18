extends Node

# Dadivas: arvore de upgrades permanentes comprados com Santos (GDD secao 8).
# Persistem apos o prestige. Custos sao pontos de partida de balanceamento.
#
# Tipos de efeito:
#   "santo_bonus"       - cada Santo passa a valer +mult a mais (aditivo, ex.: 0.005)
#   "global_prod"       - multiplica producao global
#   "offline_mult"      - multiplica ganho offline
#   "offline_cap"       - multiplica o teto de horas offline
#   "offline_cap_bonus" - soma mult segundos ao teto offline
#   "global_speed"      - multiplica tempo de ciclo de todos (<1 = mais rapido)
#   "discount"          - multiplica custo de todos os geradores (<1 = mais barato)
#   "start_units"       - apos o prestige, comeca com mult unidades dos geradores
#                         start_first..start_last (a corrida aos 10000 recomeca
#                         mais perto da linha de largada)
#   "milestone_buyer"   - libera a compra conjunta dos proximos marcos
#
# Alem da tabela, existe a escada infinita "Frutos do Espirito": nivel N custa
# base*growth^N Santos e da x(multiplier) de producao global permanente
# (constantes no LiveOps; nivel em GameState.dadiva_frutos_nivel).

const DADOS: Array = [
	{"id": "d_comunhao", "nome": "Comunhao", "custo": 10, "tipo": "santo_bonus", "mult": 0.005, "efeito": "Cada Santo vale +0.5% de producao a mais", "flavor": "Perseveravam na comunhao e no partir do pao."},
	{"id": "d_evangelismo", "nome": "Evangelismo", "custo": 25, "tipo": "global_prod", "mult": 1.25, "efeito": "+25% producao de TODOS os geradores", "flavor": "Ide por todo o mundo e pregai o evangelho."},
	{"id": "d_evangelismo2", "nome": "Evangelismo II", "custo": 100, "tipo": "global_prod", "mult": 1.25, "efeito": "+25% producao de TODOS os geradores", "flavor": "E a palavra se espalhava cada vez mais."},
	{"id": "d_comprador_marcos", "nome": "Mordomia dos Marcos", "custo": 150, "tipo": "milestone_buyer", "mult": 1.0, "efeito": "Libera o Comprador de Marcos em todas as aventuras", "flavor": "Quem planeja a colheita reconhece cada tempo e cada medida."},
	{"id": "d_jo", "nome": "Paciencia de Jo", "custo": 15, "tipo": "offline_mult", "mult": 1.5, "efeito": "+50% producao offline", "flavor": "O Senhor deu, o Senhor tomou. E depois devolveu em dobro."},
	{"id": "d_jo2", "nome": "Paciencia de Jo II", "custo": 60, "tipo": "offline_cap", "mult": 2.0, "efeito": "Teto de producao offline: 8h -> 16h", "flavor": "Depois disto viveu Jo cento e quarenta anos."},
	{"id": "d_salomao", "nome": "Sabedoria de Salomao", "custo": 20, "tipo": "discount", "mult": 0.95, "efeito": "-5% custo de TODOS os geradores", "flavor": "Da-me agora sabedoria e conhecimento."},
	# ---- Tiers altos: incentivo permanente ate custos extremos de Santos.
	{"id": "d_primicias", "nome": "Primicias", "custo": 500, "tipo": "start_units", "mult": 10.0, "start_first": 1, "start_last": 4, "efeito": "Apos a Ressurreicao, comece com 10 unidades dos geradores 1-4", "flavor": "As primicias da colheita pertencem ao Senhor."},
	{"id": "d_vigilia", "nome": "Vigilia Constante", "custo": 2000, "tipo": "offline_cap_bonus", "mult": 14400.0, "efeito": "+4 h no teto de producao offline", "flavor": "Vigiai e orai, para que nao entreis em tentacao."},
	{"id": "d_primicias2", "nome": "Primicias II", "custo": 5000, "tipo": "start_units", "mult": 25.0, "start_first": 1, "start_last": 8, "efeito": "Apos a Ressurreicao, comece com 25 unidades dos geradores 1-8", "flavor": "Honra ao Senhor com as primicias de toda a tua renda."},
	{"id": "d_sopro", "nome": "Sopro Divino", "custo": 50000, "tipo": "global_speed", "mult": 0.9, "efeito": "Ciclos 10% mais rapidos, para sempre", "flavor": "O vento sopra onde quer; ouves a sua voz."},
	{"id": "d_primicias3", "nome": "Primicias III", "custo": 100000, "tipo": "start_units", "mult": 50.0, "start_first": 1, "start_last": 12, "efeito": "Apos a Ressurreicao, comece com 50 unidades de todos os geradores da Jornada", "flavor": "Celeiros fartos para quem semeia primeiro."},
	{"id": "d_coroa", "nome": "Coroa da Perseveranca", "custo": 1000000, "tipo": "global_prod", "mult": 3.0, "efeito": "x3 producao de TODOS os geradores, para sempre", "flavor": "Se fiel ate a morte, e dar-te-ei a coroa da vida."},
]

var _by_id: Dictionary = {}

func _ready() -> void:
	for d in DADOS:
		_by_id[d.id] = d

func get_data(id: String) -> Dictionary:
	return _by_id.get(id, {})

# Dadivas ainda nao compradas.
func disponiveis() -> Array:
	var result: Array = []
	for d in DADOS:
		if not (d.id in GameState.dadivas_compradas):
			result.append(d)
	result.sort_custom(func(a, b): return a.custo < b.custo)
	return result

# ---- Escada infinita "Frutos do Espirito" ----

func ladder_cost(nivel: int) -> int:
	return int(ceil(LiveOps.dadiva_ladder_base_cost() * pow(LiveOps.dadiva_ladder_cost_growth(), nivel)))

func ladder_next() -> Dictionary:
	var nivel: int = GameState.dadiva_frutos_nivel
	var mult := LiveOps.dadiva_ladder_multiplier()
	return {
		"nivel": nivel + 1,
		"custo": ladder_cost(nivel),
		"mult": mult,
		"mult_total": pow(mult, nivel + 1),
		"efeito": "x" + String.num(mult, 2) + " producao global permanente",
	}

extends Node

# Dadivas: arvore de upgrades permanentes comprados com Santos (GDD secao 8).
# Persistem apos o prestige. Custos sao pontos de partida de balanceamento.
#
# Tipos de efeito:
#   "santo_bonus"   - cada Santo passa a valer +mult a mais (aditivo, ex.: 0.005)
#   "global_prod"   - multiplica producao global
#   "offline_mult"  - multiplica ganho offline
#   "offline_cap"   - multiplica o teto de horas offline
#   "discount"      - multiplica custo de todos os geradores (<1 = mais barato)

const DADOS: Array = [
	{"id": "d_comunhao", "nome": "Comunhao", "custo": 10, "tipo": "santo_bonus", "mult": 0.005, "efeito": "Cada Santo vale +0.5% de producao (2% -> 2.5%)", "flavor": "Perseveravam na comunhao e no partir do pao."},
	{"id": "d_evangelismo", "nome": "Evangelismo", "custo": 25, "tipo": "global_prod", "mult": 1.25, "efeito": "+25% producao de TODOS os geradores", "flavor": "Ide por todo o mundo e pregai o evangelho."},
	{"id": "d_evangelismo2", "nome": "Evangelismo II", "custo": 100, "tipo": "global_prod", "mult": 1.25, "efeito": "+25% producao de TODOS os geradores", "flavor": "E a palavra se espalhava cada vez mais."},
	{"id": "d_jo", "nome": "Paciencia de Jo", "custo": 15, "tipo": "offline_mult", "mult": 1.5, "efeito": "+50% producao offline", "flavor": "O Senhor deu, o Senhor tomou. E depois devolveu em dobro."},
	{"id": "d_jo2", "nome": "Paciencia de Jo II", "custo": 60, "tipo": "offline_cap", "mult": 2.0, "efeito": "Teto de producao offline: 8h -> 16h", "flavor": "Depois disto viveu Jo cento e quarenta anos."},
	{"id": "d_salomao", "nome": "Sabedoria de Salomao", "custo": 20, "tipo": "discount", "mult": 0.95, "efeito": "-5% custo de TODOS os geradores", "flavor": "Da-me agora sabedoria e conhecimento."},
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

extends Node

const DADOS: Array = [
	{
		"id": 1,
		"nome": "Haja Luz",
		"custo_base": 4.0,
		"receita_base": 1.0,
		"tempo": 0.6,
		"profeta_nome": "Arcanjo Gabriel",
		"profeta_custo": 15.0,
		"era": 1,
		"era_nome": "Genesis",
		"flavor": "E disse Deus: haja lucro. E houve lucro.",
		"cor": Color(1.0, 0.85, 0.0),
	},
	{
		"id": 2,
		"nome": "Jardim do Eden",
		"custo_base": 60.0,
		"receita_base": 60.0,
		"tempo": 3.0,
		"profeta_nome": "Adao",
		"profeta_custo": 900.0,
		"era": 1,
		"era_nome": "Genesis",
		"flavor": "Tudo era perfeito. Ate a primeira reclamacao de cliente.",
		"cor": Color(0.3, 0.8, 0.3),
	},
	{
		"id": 3,
		"nome": "Arca de Noe",
		"custo_base": 720.0,
		"receita_base": 540.0,
		"tempo": 6.0,
		"profeta_nome": "Noe",
		"profeta_custo": 8100.0,
		"era": 1,
		"era_nome": "Genesis",
		"flavor": "40 dias e 40 noites de logistica intensa.",
		"cor": Color(0.55, 0.35, 0.15),
	},
	{
		"id": 4,
		"nome": "Torre de Babel",
		"custo_base": 8640.0,
		"receita_base": 4320.0,
		"tempo": 12.0,
		"profeta_nome": "Nemrod",
		"profeta_custo": 64800.0,
		"era": 1,
		"era_nome": "Genesis",
		"flavor": "Eles queriam chegar ao ceu. O SEO divino nao aprovou.",
		"cor": Color(0.7, 0.5, 0.3),
	},
	{
		"id": 5,
		"nome": "Mana do Ceu",
		"custo_base": 103680.0,
		"receita_base": 51840.0,
		"tempo": 24.0,
		"profeta_nome": "Moises",
		"profeta_custo": 777600.0,
		"era": 2,
		"era_nome": "Exodo",
		"flavor": "Pao do ceu com prazo de validade de 1 dia.",
		"cor": Color(0.95, 0.95, 0.7),
	},
	{
		"id": 6,
		"nome": "Mar Vermelho",
		"custo_base": 1244160.0,
		"receita_base": 622080.0,
		"tempo": 48.0,
		"profeta_nome": "Moises (II)",
		"profeta_custo": 9331200.0,
		"era": 2,
		"era_nome": "Exodo",
		"flavor": "A travessia mais epica da historia. Sem pedagio.",
		"cor": Color(0.2, 0.4, 0.8),
	},
	{
		"id": 7,
		"nome": "Muralhas de Jerico",
		"custo_base": 14929920.0,
		"receita_base": 7464960.0,
		"tempo": 60.0,
		"profeta_nome": "Josue",
		"profeta_custo": 111974400.0,
		"era": 2,
		"era_nome": "Exodo",
		"flavor": "7 voltas, 7 trombetas, 1 demolicao diplomatica.",
		"cor": Color(0.8, 0.6, 0.4),
	},
	{
		"id": 8,
		"nome": "Sansao",
		"custo_base": 179159040.0,
		"receita_base": 89579520.0,
		"tempo": 120.0,
		"profeta_nome": "Dalila",
		"profeta_custo": 1343692800.0,
		"era": 2,
		"era_nome": "Exodo",
		"flavor": "Forca sobrenatural. Cabelo nao incluso.",
		"cor": Color(0.85, 0.3, 0.3),
	},
	{
		"id": 9,
		"nome": "Davi vs Golias",
		"custo_base": 2.15e9,
		"receita_base": 1.07e9,
		"tempo": 180.0,
		"profeta_nome": "Davi",
		"profeta_custo": 1.61e10,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "A pedra original. O startup que derrubou o gigante.",
		"cor": Color(0.6, 0.4, 0.8),
	},
	{
		"id": 10,
		"nome": "Templo de Salomao",
		"custo_base": 2.58e10,
		"receita_base": 1.29e10,
		"tempo": 300.0,
		"profeta_nome": "Salomao",
		"profeta_custo": 1.94e11,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "7 anos de obra, ouro a partir do teto. Obra de luxo.",
		"cor": Color(0.9, 0.8, 0.2),
	},
	{
		"id": 11,
		"nome": "Jonas e a Baleia",
		"custo_base": 3.09e11,
		"receita_base": 1.55e11,
		"tempo": 480.0,
		"profeta_nome": "Jonas",
		"profeta_custo": 2.33e12,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "3 dias de hospedagem premium (sem chance de fuga).",
		"cor": Color(0.2, 0.5, 0.6),
	},
	{
		"id": 12,
		"nome": "Fornalha Ardente",
		"custo_base": 3.71e12,
		"receita_base": 1.86e12,
		"tempo": 720.0,
		"profeta_nome": "Sadraque",
		"profeta_custo": 2.79e13,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "4 homens na fogueira. O 4o nao estava na folha de pagamento.",
		"cor": Color(1.0, 0.4, 0.1),
	},
]

func get_data(id: int) -> Dictionary:
	if id < 1 or id > DADOS.size():
		return {}
	return DADOS[id - 1]

func count() -> int:
	return DADOS.size()

func get_by_era(era: int) -> Array:
	var result: Array = []
	for d in DADOS:
		if d.era == era:
			result.append(d)
	return result

func get_era_name(era: int) -> String:
	match era:
		1: return "Genesis"
		2: return "Exodo & Conquista"
		3: return "Reino de Israel"
		_: return "Desconhecida"

func era_count() -> int:
	return 3

func get_era_progress(era: int) -> Dictionary:
	var gens = get_by_era(era)
	var first_id = gens[0].id
	var last_id = gens[-1].id
	return {
		"first": first_id,
		"last": last_id,
		"count": gens.size(),
		"name": get_era_name(era),
	}

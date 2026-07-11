extends Node

const DADOS: Array = [
	{
		"id": 1,
		"nome": "Haja Luz",
		"custo_base": 4.0,
		"receita_base": 1.0,
		"tempo": 0.78,
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
		"tempo": 3.9,
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
		"tempo": 7.8,
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
		"tempo": 15.6,
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
	{
		"id": 13, "nome": "Nascimento em Belém", "custo_base": 4.45e13, "receita_base": 2.23e13,
		"tempo": 900.0, "profeta_nome": "José", "profeta_custo": 3.34e14,
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "Sem lugar na hospedaria; a esperança nasceu com simplicidade.", "cor": Color(0.95, 0.78, 0.35),
	},
	{
		"id": 14, "nome": "Fuga para o Egito", "custo_base": 5.34e14, "receita_base": 2.67e14,
		"tempo": 1500.0, "profeta_nome": "José (II)", "profeta_custo": 4.00e15,
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "Uma família em viagem, protegendo uma promessa ainda pequena.", "cor": Color(0.78, 0.58, 0.32),
	},
	{
		"id": 15, "nome": "Batismo no Jordão", "custo_base": 6.41e15, "receita_base": 3.20e15,
		"tempo": 2400.0, "profeta_nome": "João Batista", "profeta_custo": 4.80e16,
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "Água, voz e pomba marcam o início de uma missão.", "cor": Color(0.32, 0.68, 0.86),
	},
	{
		"id": 16, "nome": "Bodas de Caná", "custo_base": 7.69e16, "receita_base": 3.84e16,
		"tempo": 3600.0, "profeta_nome": "Maria", "profeta_custo": 5.76e17,
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "Quando faltou vinho, a celebração recebeu um novo começo.", "cor": Color(0.60, 0.25, 0.42),
	},
	{
		"id": 17, "nome": "Sermão do Monte", "custo_base": 9.23e17, "receita_base": 4.61e17,
		"tempo": 5400.0, "profeta_nome": "Mateus", "profeta_custo": 6.92e18,
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "Palavras antigas que continuam convidando a uma vida transformada.", "cor": Color(0.45, 0.72, 0.43),
	},
	{
		"id": 18, "nome": "Multiplicação dos Pães", "custo_base": 1.11e19, "receita_base": 5.54e18,
		"tempo": 9000.0, "profeta_nome": "Pedro", "profeta_custo": 8.31e19,
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "Cinco pães, dois peixes e uma multidão acolhida.", "cor": Color(0.88, 0.66, 0.32),
	},
	{
		"id": 19, "nome": "Caminhar sobre as Águas", "custo_base": 1.33e20, "receita_base": 6.65e19,
		"tempo": 14400.0, "profeta_nome": "Pedro (II)", "profeta_custo": 9.98e20,
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "Mesmo em meio ao vento, ainda havia uma mão estendida.", "cor": Color(0.22, 0.52, 0.78),
	},
	{
		"id": 20, "nome": "Transfiguração", "custo_base": 1.60e21, "receita_base": 8.00e20,
		"tempo": 21600.0, "profeta_nome": "Tiago", "profeta_custo": 1.20e22,
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "No alto do monte, a glória tornou-se visível por um instante.", "cor": Color(0.94, 0.86, 0.48),
	},
	{
		"id": 21, "nome": "Ressurreição de Lázaro", "custo_base": 1.92e22, "receita_base": 9.60e21,
		"tempo": 32400.0, "profeta_nome": "Marta", "profeta_custo": 1.44e23,
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "A pedra foi retirada e o luto encontrou esperança.", "cor": Color(0.48, 0.64, 0.58),
	},
	{
		"id": 22, "nome": "Entrada em Jerusalém", "custo_base": 2.30e23, "receita_base": 1.15e23,
		"tempo": 43200.0, "profeta_nome": "Zaqueu", "profeta_custo": 1.73e24,
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "Ramos no caminho e um rei chegando com humildade.", "cor": Color(0.40, 0.68, 0.38),
	},
	{
		"id": 23, "nome": "Última Ceia", "custo_base": 2.76e24, "receita_base": 1.38e24,
		"tempo": 64800.0, "profeta_nome": "João", "profeta_custo": 2.07e25,
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "Pão, cálice e serviço à mesa antes da noite mais difícil.", "cor": Color(0.64, 0.38, 0.28),
	},
	{
		"id": 24, "nome": "Ressurreição", "custo_base": 3.31e25, "receita_base": 1.66e25,
		"tempo": 86400.0, "profeta_nome": "Maria Madalena", "profeta_custo": 2.49e26,
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "O túmulo vazio transformou o fim em começo.", "cor": Color(1.0, 0.78, 0.30),
	},
	{
		"id": 25, "nome": "Pentecostes", "custo_base": 3.98e26, "receita_base": 1.99e26,
		"tempo": 72000.0, "profeta_nome": "Apóstolos", "profeta_custo": 2.99e27,
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Muitas línguas, uma mensagem e uma comunidade nascendo.", "cor": Color(0.95, 0.38, 0.18),
	},
	{
		"id": 26, "nome": "Conversão de Saulo", "custo_base": 4.77e27, "receita_base": 2.39e27,
		"tempo": 108000.0, "profeta_nome": "Paulo", "profeta_custo": 3.59e28,
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Uma luz no caminho mudou perseguição em missão.", "cor": Color(0.92, 0.76, 0.32),
	},
	{
		"id": 27, "nome": "Viagens Missionárias", "custo_base": 5.73e28, "receita_base": 2.86e28,
		"tempo": 129600.0, "profeta_nome": "Paulo (II)", "profeta_custo": 4.29e29,
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Estradas, mares e cidades conectadas por uma boa notícia.", "cor": Color(0.28, 0.60, 0.72),
	},
	{
		"id": 28, "nome": "Cartas às Igrejas", "custo_base": 6.87e29, "receita_base": 3.44e29,
		"tempo": 172800.0, "profeta_nome": "Timóteo", "profeta_custo": 5.16e30,
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Conselhos atravessaram distâncias e continuam sendo lidos.", "cor": Color(0.76, 0.56, 0.32),
	},
	{
		"id": 29, "nome": "Mártires da Fé", "custo_base": 8.25e30, "receita_base": 4.12e30,
		"tempo": 259200.0, "profeta_nome": "Estêvão", "profeta_custo": 6.18e31,
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "Testemunhos mantidos com coragem mesmo sob grande pressão.", "cor": Color(0.66, 0.28, 0.30),
	},
	{
		"id": 30, "nome": "Édito de Milão", "custo_base": 9.90e31, "receita_base": 4.95e31,
		"tempo": 345600.0, "profeta_nome": "Constantino", "profeta_custo": 7.43e32,
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "Após perseguições, a fé encontrou espaço público.", "cor": Color(0.62, 0.54, 0.76),
	},
	{
		"id": 31, "nome": "Reforma Protestante", "custo_base": 1.19e33, "receita_base": 5.94e32,
		"tempo": 518400.0, "profeta_nome": "Lutero", "profeta_custo": 8.91e33,
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "Perguntas, textos e debates transformaram uma época.", "cor": Color(0.48, 0.32, 0.22),
	},
	{
		"id": 32, "nome": "Grande Comissão", "custo_base": 1.43e34, "receita_base": 7.13e33,
		"tempo": 777600.0, "profeta_nome": "Apóstolos (II)", "profeta_custo": 1.07e35,
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "Uma missão sem fronteiras confiada a pessoas comuns.", "cor": Color(0.30, 0.62, 0.48),
	},
	{
		"id": 33, "nome": "Evangelismo Mundial", "custo_base": 1.71e35, "receita_base": 8.56e34,
		"tempo": 1036800.0, "profeta_nome": "Missionários", "profeta_custo": 1.28e36,
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "Tradução, rádio e internet levaram a mensagem mais longe.", "cor": Color(0.28, 0.54, 0.74),
	},
	{
		"id": 34, "nome": "Sete Igrejas da Ásia", "custo_base": 2.06e36, "receita_base": 1.03e36,
		"tempo": 1382400.0, "profeta_nome": "João (II)", "profeta_custo": 1.55e37,
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "Sete comunidades recebem encorajamento, correção e esperança.", "cor": Color(0.72, 0.50, 0.72),
	},
	{
		"id": 35, "nome": "Apocalipse", "custo_base": 2.47e37, "receita_base": 1.23e37,
		"tempo": 1814400.0, "profeta_nome": "João (III)", "profeta_custo": 1.85e38,
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "Selos, trombetas e visões apontam para justiça e restauração.", "cor": Color(0.46, 0.28, 0.68),
	},
	{
		"id": 36, "nome": "Nova Jerusalém", "custo_base": 2.96e38, "receita_base": 1.48e38,
		"tempo": 2419200.0, "profeta_nome": "O Cordeiro", "profeta_custo": 2.22e39,
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "Sem morte nem lágrimas: a jornada termina em renovação.", "cor": Color(1.0, 0.78, 0.34),
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
		4: return "Nascimento & Preparação"
		5: return "Sinais & Ensinamentos"
		6: return "Paixão & Ressurreição"
		7: return "Igreja Primitiva"
		8: return "Expansão & Reforma"
		9: return "Apocalipse & Renovação"
		_: return "Desconhecida"

func era_count() -> int:
	return 9

func get_adventure_for_id(id: int) -> String:
	var data := get_data(id)
	return str(data.get("adventure", "jornada"))

func get_by_adventure(adventure_id: String) -> Array:
	var result: Array = []
	for data in DADOS:
		if str(data.get("adventure", "jornada")) == adventure_id:
			result.append(data)
	return result

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

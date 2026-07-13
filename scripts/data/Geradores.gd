extends Node

const DADOS: Array = [
	{
		"id": 1,
		"nome": "Haja Luz",
		"custo_base": 4.0,
		"receita_base": 1.0,
		"tempo": 4.0, "tempo_min": 0.1,
		"profeta_nome": "Arcanjo Gabriel",
		"profeta_custo": 15.0,
		"era": 1,
		"era_nome": "Genesis",
		"flavor": "A luz marcou o início da criação.",
		"cor": Color(1.0, 0.85, 0.0),
	},
	{
		"id": 2,
		"nome": "Jardim do Eden",
		"custo_base": 60.0,
		"receita_base": 30.0,
		"tempo": 8.0, "tempo_min": 0.3,
		"profeta_nome": "Adao",
		"profeta_custo": 900.0,
		"era": 1,
		"era_nome": "Genesis",
		"flavor": "O jardim preparado para a vida.",
		"cor": Color(0.3, 0.8, 0.3),
	},
	{
		"id": 3,
		"nome": "Arca de Noe",
		"custo_base": 720.0,
		"receita_base": 270.0,
		"tempo": 12.0, "tempo_min": 0.9,
		"profeta_nome": "Noe",
		"profeta_custo": 8100.0,
		"era": 1,
		"era_nome": "Genesis",
		"flavor": "A arca preservou a vida durante o dilúvio.",
		"cor": Color(0.55, 0.35, 0.15),
	},
	{
		"id": 4,
		"nome": "Torre de Babel",
		"custo_base": 8640.0,
		"receita_base": 2160.0,
		"tempo": 20.0, "tempo_min": 2.0,
		"profeta_nome": "Nemrod",
		"profeta_custo": 64800.0,
		"era": 1,
		"era_nome": "Genesis",
		"flavor": "A cidade e a torre foram interrompidas.",
		"cor": Color(0.7, 0.5, 0.3),
	},
	{
		"id": 5,
		"nome": "Mana do Ceu",
		"custo_base": 103680.0,
		"receita_base": 10368.0,
		"tempo": 30.0, "tempo_min": 3.0,
		"profeta_nome": "Moises",
		"profeta_custo": 777600.0,
		"era": 2,
		"era_nome": "Exodo",
		"flavor": "O alimento diário sustentou o povo no deserto.",
		"cor": Color(0.95, 0.95, 0.7),
	},
	{
		"id": 6,
		"nome": "Mar Vermelho",
		"custo_base": 1244160.0,
		"receita_base": 124416.0,
		"tempo": 45.0, "tempo_min": 5.0,
		"profeta_nome": "Moises (II)",
		"profeta_custo": 9331200.0,
		"era": 2,
		"era_nome": "Exodo",
		"flavor": "O mar se abriu para a passagem do povo.",
		"cor": Color(0.2, 0.4, 0.8),
	},
	{
		"id": 7,
		"nome": "Muralhas de Jerico",
		"custo_base": 14929920.0,
		"receita_base": 1492992.0,
		"tempo": 70.0, "tempo_min": 7.0,
		"profeta_nome": "Josue",
		"profeta_custo": 111974400.0,
		"era": 2,
		"era_nome": "Exodo",
		"flavor": "As muralhas caíram após a marcha do povo.",
		"cor": Color(0.8, 0.6, 0.4),
	},
	{
		"id": 8,
		"nome": "Sansao",
		"custo_base": 179159040.0,
		"receita_base": 17915904.0,
		"tempo": 100.0, "tempo_min": 10.0,
		"profeta_nome": "Dalila",
		"profeta_custo": 1343692800.0,
		"era": 2,
		"era_nome": "Exodo",
		"flavor": "A força de Sansão venceu os inimigos.",
		"cor": Color(0.85, 0.3, 0.3),
	},
	{
		"id": 9,
		"nome": "Davi vs Golias",
		"custo_base": 2.15e9,
		"receita_base": 2.14e8,
		"tempo": 150.0, "tempo_min": 15.0,
		"profeta_nome": "Davi",
		"profeta_custo": 1.61e10,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "Davi venceu Golias com fé e coragem.",
		"cor": Color(0.6, 0.4, 0.8),
	},
	{
		"id": 10,
		"nome": "Templo de Salomao",
		"custo_base": 2.58e10,
		"receita_base": 2.58e9,
		"tempo": 220.0, "tempo_min": 22.0,
		"profeta_nome": "Salomao",
		"profeta_custo": 1.94e11,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "O templo foi dedicado à adoração.",
		"cor": Color(0.9, 0.8, 0.2),
	},
	{
		"id": 11,
		"nome": "Jonas e a Baleia",
		"custo_base": 3.09e11,
		"receita_base": 3.10e10,
		"tempo": 280.0, "tempo_min": 28.0,
		"profeta_nome": "Jonas",
		"profeta_custo": 2.33e12,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "Jonas foi preservado no grande peixe.",
		"cor": Color(0.2, 0.5, 0.6),
	},
	{
		"id": 12,
		"nome": "Fornalha Ardente",
		"custo_base": 3.71e12,
		"receita_base": 3.73e11,
		"tempo": 360.0, "tempo_min": 36.0,
		"profeta_nome": "Sadraque",
		"profeta_custo": 2.79e13,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "A fidelidade permaneceu mesmo na fornalha.",
		"cor": Color(1.0, 0.4, 0.1),
	},
	{
		"id": 13, "nome": "Nascimento em Belém", "custo_base": 4.45e13, "receita_base": 7.43e12,
		"tempo": 2.0, "tempo_min": 0.1, "profeta_nome": "José", "profeta_custo": 3.34e14,
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "A esperança nasceu em Belém.", "cor": Color(0.95, 0.78, 0.35),
	},
	{
		"id": 14, "nome": "Fuga para o Egito", "custo_base": 5.34e14, "receita_base": 8.90e13,
		"tempo": 4.0, "tempo_min": 0.4, "profeta_nome": "José (II)", "profeta_custo": 4.00e15,
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "A família foi protegida em sua jornada.", "cor": Color(0.78, 0.58, 0.32),
	},
	{
		"id": 15, "nome": "Batismo no Jordão", "custo_base": 6.41e15, "receita_base": 1.07e15,
		"tempo": 8.0, "tempo_min": 1.0, "profeta_nome": "João Batista", "profeta_custo": 4.80e16,
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "O batismo marcou o início da missão.", "cor": Color(0.32, 0.68, 0.86),
	},
	{
		"id": 16, "nome": "Bodas de Caná", "custo_base": 7.69e16, "receita_base": 1.28e16,
		"tempo": 16.0, "tempo_min": 2.0, "profeta_nome": "Maria", "profeta_custo": 5.76e17,
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "A celebração recebeu um novo começo.", "cor": Color(0.60, 0.25, 0.42),
	},
	{
		"id": 17, "nome": "Sermão do Monte", "custo_base": 9.23e17, "receita_base": 1.54e17,
		"tempo": 32.0, "tempo_min": 4.0, "profeta_nome": "Mateus", "profeta_custo": 6.92e18,
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "Ensinamentos para uma vida transformada.", "cor": Color(0.45, 0.72, 0.43),
	},
	{
		"id": 18, "nome": "Multiplicação dos Pães", "custo_base": 1.11e19, "receita_base": 1.85e18,
		"tempo": 64.0, "tempo_min": 8.0, "profeta_nome": "Pedro", "profeta_custo": 8.31e19,
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "Pães e peixes serviram à multidão.", "cor": Color(0.88, 0.66, 0.32),
	},
	{
		"id": 19, "nome": "Caminhar sobre as Águas", "custo_base": 1.33e20, "receita_base": 2.22e19,
		"tempo": 128.0, "tempo_min": 16.0, "profeta_nome": "Pedro (II)", "profeta_custo": 9.98e20,
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "A fé permaneceu mesmo sobre as águas.", "cor": Color(0.22, 0.52, 0.78),
	},
	{
		"id": 20, "nome": "Transfiguração", "custo_base": 1.60e21, "receita_base": 2.67e20,
		"tempo": 256.0, "tempo_min": 24.0, "profeta_nome": "Tiago", "profeta_custo": 1.20e22,
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "A glória foi revelada no monte.", "cor": Color(0.94, 0.86, 0.48),
	},
	{
		"id": 21, "nome": "Ressurreição de Lázaro", "custo_base": 1.92e22, "receita_base": 3.20e21,
		"tempo": 512.0, "tempo_min": 32.0, "profeta_nome": "Marta", "profeta_custo": 1.44e23,
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "A esperança venceu o luto.", "cor": Color(0.48, 0.64, 0.58),
	},
	{
		"id": 22, "nome": "Entrada em Jerusalém", "custo_base": 2.30e23, "receita_base": 3.83e22,
		"tempo": 1024.0, "tempo_min": 40.0, "profeta_nome": "Zaqueu", "profeta_custo": 1.73e24,
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "O rei chegou com humildade.", "cor": Color(0.40, 0.68, 0.38),
	},
	{
		"id": 23, "nome": "Última Ceia", "custo_base": 2.76e24, "receita_base": 4.60e23,
		"tempo": 2048.0, "tempo_min": 48.0, "profeta_nome": "João", "profeta_custo": 2.07e25,
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "Pão, cálice e serviço à mesa.", "cor": Color(0.64, 0.38, 0.28),
	},
	{
		"id": 24, "nome": "Ressurreição", "custo_base": 3.31e25, "receita_base": 5.53e24,
		"tempo": 4096.0, "tempo_min": 60.0, "profeta_nome": "Maria Madalena", "profeta_custo": 2.49e26,
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "O túmulo vazio anunciou um novo começo.", "cor": Color(1.0, 0.78, 0.30),
	},
	{
		"id": 25, "nome": "Pentecostes", "custo_base": 3.98e26, "receita_base": 6.63e25,
		"tempo": 10.0, "tempo_min": 0.1, "profeta_nome": "Apóstolos", "profeta_custo": 2.99e27,
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Uma mensagem uniu muitas línguas.", "cor": Color(0.95, 0.38, 0.18),
	},
	{
		"id": 26, "nome": "Conversão de Saulo", "custo_base": 4.77e27, "receita_base": 7.97e26,
		"tempo": 20.0, "tempo_min": 0.2, "profeta_nome": "Paulo", "profeta_custo": 3.59e28,
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Uma luz transformou perseguição em missão.", "cor": Color(0.92, 0.76, 0.32),
	},
	{
		"id": 27, "nome": "Viagens Missionárias", "custo_base": 5.73e28, "receita_base": 9.53e27,
		"tempo": 30.0, "tempo_min": 0.4, "profeta_nome": "Paulo (II)", "profeta_custo": 4.29e29,
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "A mensagem alcançou cidades e povos.", "cor": Color(0.28, 0.60, 0.72),
	},
	{
		"id": 28, "nome": "Cartas às Igrejas", "custo_base": 6.87e29, "receita_base": 1.15e29,
		"tempo": 40.0, "tempo_min": 1.0, "profeta_nome": "Timóteo", "profeta_custo": 5.16e30,
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Conselhos fortaleceram as primeiras igrejas.", "cor": Color(0.76, 0.56, 0.32),
	},
	{
		"id": 29, "nome": "Mártires da Fé", "custo_base": 8.25e30, "receita_base": 1.37e30,
		"tempo": 50.0, "tempo_min": 2.0, "profeta_nome": "Estêvão", "profeta_custo": 6.18e31,
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "A fé foi testemunhada com coragem.", "cor": Color(0.66, 0.28, 0.30),
	},
	{
		"id": 30, "nome": "Édito de Milão", "custo_base": 9.90e31, "receita_base": 1.65e31,
		"tempo": 60.0, "tempo_min": 3.0, "profeta_nome": "Constantino", "profeta_custo": 7.43e32,
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "A fé conquistou espaço público.", "cor": Color(0.62, 0.54, 0.76),
	},
	{
		"id": 31, "nome": "Reforma Protestante", "custo_base": 1.19e33, "receita_base": 1.98e32,
		"tempo": 70.0, "tempo_min": 4.0, "profeta_nome": "Lutero", "profeta_custo": 8.91e33,
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "Textos e debates transformaram uma época.", "cor": Color(0.48, 0.32, 0.22),
	},
	{
		"id": 32, "nome": "Grande Comissão", "custo_base": 1.43e34, "receita_base": 2.38e33,
		"tempo": 80.0, "tempo_min": 5.0, "profeta_nome": "Apóstolos (II)", "profeta_custo": 1.07e35,
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "Uma missão para alcançar todos os povos.", "cor": Color(0.30, 0.62, 0.48),
	},
	{
		"id": 33, "nome": "Evangelismo Mundial", "custo_base": 1.71e35, "receita_base": 2.85e34,
		"tempo": 90.0, "tempo_min": 6.0, "profeta_nome": "Missionários", "profeta_custo": 1.28e36,
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "A mensagem alcançou o mundo.", "cor": Color(0.28, 0.54, 0.74),
	},
	{
		"id": 34, "nome": "Sete Igrejas da Ásia", "custo_base": 2.06e36, "receita_base": 3.43e35,
		"tempo": 100.0, "tempo_min": 7.0, "profeta_nome": "João (II)", "profeta_custo": 1.55e37,
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "Sete igrejas receberam correção e esperança.", "cor": Color(0.72, 0.50, 0.72),
	},
	{
		"id": 35, "nome": "Apocalipse", "custo_base": 2.47e37, "receita_base": 4.10e36,
		"tempo": 110.0, "tempo_min": 8.0, "profeta_nome": "João (III)", "profeta_custo": 1.85e38,
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "Visões de justiça e restauração.", "cor": Color(0.46, 0.28, 0.68),
	},
	{
		"id": 36, "nome": "Nova Jerusalém", "custo_base": 2.96e38, "receita_base": 4.93e37,
		"tempo": 120.0, "tempo_min": 9.0, "profeta_nome": "O Cordeiro", "profeta_custo": 2.22e39,
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "A renovação encerra a jornada.", "cor": Color(1.0, 0.78, 0.34),
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

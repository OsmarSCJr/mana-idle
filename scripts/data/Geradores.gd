extends Node

# Ciclos (V3): o teto passou a ser 60 s. No alpha o g12 levava 360 s por ciclo e
# os geradores das eras 5-6 chegavam a 300 s — telas mortas, e a causa principal
# do ROI por Fe/s cair 224x de g1 a g12. O teto de 60 s recupera ~6x desse fator
# sem mexer em custo nem receita. Ver PLANO_JOGABILIDADE_V3.md secao 2.4.
#
# Meta de unidades por gerador (V3). Levar TODOS os geradores da aventura a este
# numero e o trofeu da campanha e o que libera a Alianca.
#
# Por que 1.000 e nao 10.000: o custo acumulado do g12 em 10.000 unidades chega a
# 2.5e87 de Fe e exigiria multiplicador global ~1e70, contra um teto real de ~1e10
# nos motores existentes. Nenhuma tabela de milestones fecha esse gap — ver
# PLANO_JOGABILIDADE_V3.md secao 2.
const META_UNIDADES: int = 1000

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
		"era_nome": "Gênesis",
		"flavor": "A luz marcou o início da criação.",
		"cor": Color(1.0, 0.85, 0.0),
	},
	{
		"id": 2,
		"nome": "Jardim do Eden",
		"custo_base": 60.0,
		"receita_base": 30.0,
		"tempo": 8.0, "tempo_min": 0.3,
		"profeta_nome": "Adão",
		"profeta_custo": 900.0,
		"era": 1,
		"era_nome": "Gênesis",
		"flavor": "O jardim preparado para a vida.",
		"cor": Color(0.3, 0.8, 0.3),
	},
	{
		"id": 3,
		"nome": "Arca de Noé",
		"custo_base": 720.0,
		"receita_base": 270.0,
		"tempo": 12.0, "tempo_min": 0.9,
		"profeta_nome": "Noé",
		"profeta_custo": 8100.0,
		"era": 1,
		"era_nome": "Gênesis",
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
		"era_nome": "Gênesis",
		"flavor": "A cidade e a torre foram interrompidas.",
		"cor": Color(0.7, 0.5, 0.3),
	},
	{
		"id": 5,
		"nome": "Maná do Céu",
		"custo_base": 103680.0,
		"receita_base": 10368.0,
		"tempo": 26.0, "tempo_min": 2.6,
		"profeta_nome": "Moisés",
		"profeta_custo": 777600.0,
		"era": 2,
		"era_nome": "Êxodo",
		"flavor": "O alimento diário sustentou o povo no deserto.",
		"cor": Color(0.95, 0.95, 0.7),
	},
	{
		"id": 6,
		"nome": "Mar Vermelho",
		"custo_base": 1244160.0,
		"receita_base": 124416.0,
		"tempo": 32.0, "tempo_min": 3.2,
		"profeta_nome": "Moisés (II)",
		"profeta_custo": 9331200.0,
		"era": 2,
		"era_nome": "Êxodo",
		"flavor": "O mar se abriu para a passagem do povo.",
		"cor": Color(0.2, 0.4, 0.8),
	},
	{
		"id": 7,
		"nome": "Muralhas de Jericó",
		"custo_base": 14929920.0,
		"receita_base": 1492992.0,
		"tempo": 38.0, "tempo_min": 3.8,
		"profeta_nome": "Josué",
		"profeta_custo": 111974400.0,
		"era": 2,
		"era_nome": "Êxodo",
		"flavor": "As muralhas caíram após a marcha do povo.",
		"cor": Color(0.8, 0.6, 0.4),
	},
	{
		"id": 8,
		"nome": "Sansão",
		"custo_base": 179159040.0,
		"receita_base": 17915904.0,
		"tempo": 44.0, "tempo_min": 4.4,
		"profeta_nome": "Dalila",
		"profeta_custo": 1343692800.0,
		"era": 2,
		"era_nome": "Êxodo",
		"flavor": "A força de Sansão venceu os inimigos.",
		"cor": Color(0.85, 0.3, 0.3),
	},
	{
		"id": 9,
		"nome": "Davi vs Golias",
		"custo_base": 2.15e9,
		"receita_base": 2.14e8,
		"tempo": 50.0, "tempo_min": 5.0,
		"profeta_nome": "Davi",
		"profeta_custo": 1.61e10,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "Davi venceu Golias com fé e coragem.",
		"cor": Color(0.6, 0.4, 0.8),
	},
	{
		"id": 10,
		"nome": "Templo de Salomão",
		"custo_base": 2.58e10,
		"receita_base": 2.58e9,
		"tempo": 54.0, "tempo_min": 5.4,
		"profeta_nome": "Salomão",
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
		"tempo": 57.0, "tempo_min": 5.7,
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
		"tempo": 60.0, "tempo_min": 6.0,
		"profeta_nome": "Sadraque",
		"profeta_custo": 2.79e13,
		"era": 3,
		"era_nome": "Reino",
		"flavor": "A fidelidade permaneceu mesmo na fornalha.",
		"cor": Color(1.0, 0.4, 0.1),
	},
	# ---- Vida de Cristo (moeda: Graça). Economia isolada: a escala numerica
	# recomeca pequena, com razao receita/custo 0.25 e ciclos de no maximo 60s (V3).
	{
		"id": 13, "nome": "Nascimento em Belém", "custo_base": 4.0, "receita_base": 1.0,
		"tempo": 3.0, "tempo_min": 0.3, "profeta_nome": "José",
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "A esperança nasceu em Belém.", "cor": Color(0.95, 0.78, 0.35),
	},
	{
		"id": 14, "nome": "Fuga para o Egito", "custo_base": 60.0, "receita_base": 15.0,
		"tempo": 6.0, "tempo_min": 0.6, "profeta_nome": "José (II)",
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "A família foi protegida em sua jornada.", "cor": Color(0.78, 0.58, 0.32),
	},
	{
		"id": 15, "nome": "Batismo no Jordão", "custo_base": 720.0, "receita_base": 180.0,
		"tempo": 10.0, "tempo_min": 1.0, "profeta_nome": "João Batista",
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "O batismo marcou o início da missão.", "cor": Color(0.32, 0.68, 0.86),
	},
	{
		"id": 16, "nome": "Bodas de Caná", "custo_base": 8640.0, "receita_base": 2160.0,
		"tempo": 16.0, "tempo_min": 1.6, "profeta_nome": "Maria",
		"era": 4, "era_nome": "Nascimento & Preparação", "adventure": "vida_cristo",
		"flavor": "A celebração recebeu um novo começo.", "cor": Color(0.60, 0.25, 0.42),
	},
	{
		"id": 17, "nome": "Sermão do Monte", "custo_base": 103680.0, "receita_base": 25920.0,
		"tempo": 22.0, "tempo_min": 2.2, "profeta_nome": "Mateus",
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "Ensinamentos para uma vida transformada.", "cor": Color(0.45, 0.72, 0.43),
	},
	{
		"id": 18, "nome": "Multiplicação dos Pães", "custo_base": 1244160.0, "receita_base": 311040.0,
		"tempo": 28.0, "tempo_min": 2.8, "profeta_nome": "Pedro",
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "Pães e peixes serviram à multidão.", "cor": Color(0.88, 0.66, 0.32),
	},
	{
		"id": 19, "nome": "Caminhar sobre as Águas", "custo_base": 14929920.0, "receita_base": 3732480.0,
		"tempo": 34.0, "tempo_min": 3.4, "profeta_nome": "Pedro (II)",
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "A fé permaneceu mesmo sobre as águas.", "cor": Color(0.22, 0.52, 0.78),
	},
	{
		"id": 20, "nome": "Transfiguração", "custo_base": 1.79e8, "receita_base": 4.48e7,
		"tempo": 40.0, "tempo_min": 4.0, "profeta_nome": "Tiago",
		"era": 5, "era_nome": "Sinais & Ensinamentos", "adventure": "vida_cristo",
		"flavor": "A glória foi revelada no monte.", "cor": Color(0.94, 0.86, 0.48),
	},
	{
		"id": 21, "nome": "Ressurreição de Lázaro", "custo_base": 2.15e9, "receita_base": 5.38e8,
		"tempo": 46.0, "tempo_min": 4.6, "profeta_nome": "Marta",
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "A esperança venceu o luto.", "cor": Color(0.48, 0.64, 0.58),
	},
	{
		"id": 22, "nome": "Entrada em Jerusalém", "custo_base": 2.58e10, "receita_base": 6.45e9,
		"tempo": 52.0, "tempo_min": 5.2, "profeta_nome": "Zaqueu",
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "O rei chegou com humildade.", "cor": Color(0.40, 0.68, 0.38),
	},
	{
		"id": 23, "nome": "Última Ceia", "custo_base": 3.09e11, "receita_base": 7.73e10,
		"tempo": 56.0, "tempo_min": 5.6, "profeta_nome": "João",
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "Pão, cálice e serviço à mesa.", "cor": Color(0.64, 0.38, 0.28),
	},
	{
		"id": 24, "nome": "Ressurreição", "custo_base": 3.71e12, "receita_base": 9.28e11,
		"tempo": 60.0, "tempo_min": 6.0, "profeta_nome": "Maria Madalena",
		"era": 6, "era_nome": "Paixão & Ressurreição", "adventure": "vida_cristo",
		"flavor": "O túmulo vazio anunciou um novo começo.", "cor": Color(1.0, 0.78, 0.30),
	},
	# ---- Igreja & Apocalipse (moeda: Glória). Mesma estrutura isolada, ciclos <= 60s.
	{
		"id": 25, "nome": "Pentecostes", "custo_base": 4.0, "receita_base": 1.0,
		"tempo": 3.0, "tempo_min": 0.3, "profeta_nome": "Apóstolos",
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Uma mensagem uniu muitas línguas.", "cor": Color(0.95, 0.38, 0.18),
	},
	{
		"id": 26, "nome": "Conversão de Saulo", "custo_base": 60.0, "receita_base": 15.0,
		"tempo": 6.0, "tempo_min": 0.6, "profeta_nome": "Paulo",
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Uma luz transformou perseguição em missão.", "cor": Color(0.92, 0.76, 0.32),
	},
	{
		"id": 27, "nome": "Viagens Missionárias", "custo_base": 720.0, "receita_base": 180.0,
		"tempo": 10.0, "tempo_min": 1.0, "profeta_nome": "Paulo (II)",
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "A mensagem alcançou cidades e povos.", "cor": Color(0.28, 0.60, 0.72),
	},
	{
		"id": 28, "nome": "Cartas às Igrejas", "custo_base": 8640.0, "receita_base": 2160.0,
		"tempo": 16.0, "tempo_min": 1.6, "profeta_nome": "Timóteo",
		"era": 7, "era_nome": "Igreja Primitiva", "adventure": "igreja_apocalipse",
		"flavor": "Conselhos fortaleceram as primeiras igrejas.", "cor": Color(0.76, 0.56, 0.32),
	},
	{
		"id": 29, "nome": "Mártires da Fé", "custo_base": 103680.0, "receita_base": 25920.0,
		"tempo": 22.0, "tempo_min": 2.2, "profeta_nome": "Estêvão",
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "A fé foi testemunhada com coragem.", "cor": Color(0.66, 0.28, 0.30),
	},
	{
		"id": 30, "nome": "Édito de Milão", "custo_base": 1244160.0, "receita_base": 311040.0,
		"tempo": 28.0, "tempo_min": 2.8, "profeta_nome": "Constantino",
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "A fé conquistou espaço público.", "cor": Color(0.62, 0.54, 0.76),
	},
	{
		"id": 31, "nome": "Reforma Protestante", "custo_base": 14929920.0, "receita_base": 3732480.0,
		"tempo": 34.0, "tempo_min": 3.4, "profeta_nome": "Lutero",
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "Textos e debates transformaram uma época.", "cor": Color(0.48, 0.32, 0.22),
	},
	{
		"id": 32, "nome": "Grande Comissão", "custo_base": 1.79e8, "receita_base": 4.48e7,
		"tempo": 40.0, "tempo_min": 4.0, "profeta_nome": "Apóstolos (II)",
		"era": 8, "era_nome": "Expansão & Reforma", "adventure": "igreja_apocalipse",
		"flavor": "Uma missão para alcançar todos os povos.", "cor": Color(0.30, 0.62, 0.48),
	},
	{
		"id": 33, "nome": "Evangelismo Mundial", "custo_base": 2.15e9, "receita_base": 5.38e8,
		"tempo": 46.0, "tempo_min": 4.6, "profeta_nome": "Missionários",
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "A mensagem alcançou o mundo.", "cor": Color(0.28, 0.54, 0.74),
	},
	{
		"id": 34, "nome": "Sete Igrejas da Ásia", "custo_base": 2.58e10, "receita_base": 6.45e9,
		"tempo": 52.0, "tempo_min": 5.2, "profeta_nome": "João (II)",
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "Sete igrejas receberam correção e esperança.", "cor": Color(0.72, 0.50, 0.72),
	},
	{
		"id": 35, "nome": "Apocalipse", "custo_base": 3.09e11, "receita_base": 7.73e10,
		"tempo": 56.0, "tempo_min": 5.6, "profeta_nome": "João (III)",
		"era": 9, "era_nome": "Apocalipse & Renovação", "adventure": "igreja_apocalipse",
		"flavor": "Visões de justiça e restauração.", "cor": Color(0.46, 0.28, 0.68),
	},
	{
		"id": 36, "nome": "Nova Jerusalém", "custo_base": 3.71e12, "receita_base": 9.28e11,
		"tempo": 60.0, "tempo_min": 6.0, "profeta_nome": "O Cordeiro",
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
		1: return "Gênesis"
		2: return "Êxodo & Conquista"
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

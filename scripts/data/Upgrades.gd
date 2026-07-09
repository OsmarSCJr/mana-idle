extends Node

# Upgrades (Milagres) e Profetas Especiais da Jornada Principal.
# Fonte: Upgrades_Profetas.md (Parte 1) e Balanceamento.md (secao 6).
#
# Campos:
#   id          - identificador unico salvo no save
#   nome        - exibido na UI
#   custo       - em Fe
#   tipo        - "prod" | "global" | "speed" | "discount" | "unlock"
#   alvo        - "g" (gerador especifico) | "era" | "global"
#   alvo_id     - gen_id ou numero da era (0 quando alvo == "global")
#   mult        - multiplicador aplicado (prod/global: producao; speed: tempo de
#                 ciclo, <1 = mais rapido; discount: custo, <1 = mais barato)
#   req_gen/req_qtd   - requisito: gerador req_gen com >= req_qtd unidades
#   req_fe_total      - requisito alternativo: fe total ganha na vida
#   categoria   - "milagre" | "profeta" (profetas especiais aparecem em secao propria)
#   efeito      - texto de efeito exibido na UI
#   flavor      - piada/lore

const DADOS: Array = [
	# ===== Era 1: Genesis =====
	{"id": "u1_1", "nome": "Dia e Noite", "custo": 100.0, "tipo": "prod", "alvo": "g", "alvo_id": 1, "mult": 3.0, "req_gen": 1, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao de Haja Luz", "flavor": "E separou a luz das trevas. E tambem o dia da noite."},
	{"id": "u1_2", "nome": "Seja Fecundo", "custo": 5e3, "tipo": "prod", "alvo": "g", "alvo_id": 1, "mult": 7.0, "req_gen": 1, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao de Haja Luz", "flavor": "Crescei e multiplicai-vos. Ate os numeros."},
	{"id": "u1_3", "nome": "E Viu que era Bom", "custo": 5e4, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_gen": 1, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 producao de TODOS os geradores", "flavor": "E viu Deus tudo quanto tinha feito, e eis que era muito bom."},
	{"id": "u2_1", "nome": "Arvores do Jardim", "custo": 1e4, "tipo": "prod", "alvo": "g", "alvo_id": 2, "mult": 3.0, "req_gen": 2, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao do Jardim do Eden", "flavor": "Arvore da vida, arvore do conhecimento. Cardapio divino."},
	{"id": "u2_2", "nome": "Quatro Rios", "custo": 1e5, "tipo": "prod", "alvo": "g", "alvo_id": 2, "mult": 7.0, "req_gen": 2, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao do Jardim do Eden", "flavor": "Pisom, Giom, Tigre, Eufrates. O primeiro sistema de irrigacao."},
	{"id": "u2_3", "nome": "Coroa da Criacao", "custo": 1e6, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_gen": 2, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 producao de TODOS os geradores", "flavor": "Adao deu nome a todos os animais. O primeiro CEO."},
	{"id": "u3_1", "nome": "Tabuas Extra", "custo": 5e5, "tipo": "prod", "alvo": "g", "alvo_id": 3, "mult": 3.0, "req_gen": 3, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao da Arca de Noe", "flavor": "Madeira de gofer. O primeiro material sustentavel."},
	{"id": "u3_2", "nome": "Dois a Dois", "custo": 5e6, "tipo": "prod", "alvo": "g", "alvo_id": 3, "mult": 7.0, "req_gen": 3, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao da Arca de Noe", "flavor": "Entraram de dois em dois. Logistica impecavel."},
	{"id": "u3_3", "nome": "Arco-Iris", "custo": 5e7, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_gen": 3, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 producao de TODOS os geradores", "flavor": "Sinal da alianca. O primeiro SLA entre ceu e terra."},
	{"id": "u4_1", "nome": "Tijolos Cozidos", "custo": 5e6, "tipo": "prod", "alvo": "g", "alvo_id": 4, "mult": 3.0, "req_gen": 4, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao da Torre de Babel", "flavor": "Tijolos em vez de pedras. O primeiro pivo de materiais."},
	{"id": "u4_2", "nome": "Betume por Argamassa", "custo": 5e7, "tipo": "prod", "alvo": "g", "alvo_id": 4, "mult": 7.0, "req_gen": 4, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao da Torre de Babel", "flavor": "Betume e mais adesivo. Engenharia de ponta."},
	{"id": "u4_3", "nome": "Confusao de Linguas", "custo": 5e8, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_gen": 4, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 producao de TODOS os geradores", "flavor": "Deus confundiu as linguas. O primeiro Babel Fish falhou."},
	{"id": "u4_4", "nome": "Desbloqueio x100", "custo": 1e9, "tipo": "unlock", "alvo": "global", "alvo_id": 0, "mult": 1.0, "req_gen": 4, "req_qtd": 100, "categoria": "milagre", "efeito": "Habilita o modo de compra x100", "flavor": "Compre em massa. Nem a torre era tao alta."},
	# ===== Era 2: Exodo & Conquista =====
	{"id": "u5_1", "nome": "Pao dos Anjos", "custo": 1e8, "tipo": "prod", "alvo": "g", "alvo_id": 5, "mult": 3.0, "req_gen": 5, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao do Mana do Ceu", "flavor": "Pao do ceu. Breakfast delivery sem taxa."},
	{"id": "u5_2", "nome": "Dobro na Sexta", "custo": 1e9, "tipo": "prod", "alvo": "g", "alvo_id": 5, "mult": 7.0, "req_gen": 5, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao do Mana do Ceu", "flavor": "Colham o dobro na sexta. O primeiro fim de semana."},
	{"id": "u5_3", "nome": "Agua da Rocha", "custo": 1e10, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_gen": 5, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 producao de TODOS os geradores", "flavor": "Moises bateu na rocha. A primeira fonte divina."},
	{"id": "u6_1", "nome": "Vento Oriental", "custo": 1e9, "tipo": "prod", "alvo": "g", "alvo_id": 6, "mult": 3.0, "req_gen": 6, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao do Mar Vermelho", "flavor": "Um vento forte dividiu as aguas. Natureza a servico."},
	{"id": "u6_2", "nome": "Paredes de Agua", "custo": 1e10, "tipo": "prod", "alvo": "g", "alvo_id": 6, "mult": 7.0, "req_gen": 6, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao do Mar Vermelho", "flavor": "Agua como muralhas dos dois lados. Engenharia hidraulica."},
	{"id": "u6_3", "nome": "Bastao de Moises", "custo": 1e11, "tipo": "speed", "alvo": "g", "alvo_id": 6, "mult": 0.5, "req_gen": 6, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 velocidade do Mar Vermelho", "flavor": "Levanta o bastao. O botao de turbo."},
	{"id": "u7_1", "nome": "Sete Trombetas", "custo": 1e10, "tipo": "prod", "alvo": "g", "alvo_id": 7, "mult": 3.0, "req_gen": 7, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao das Muralhas de Jerico", "flavor": "7 trombetas, 7 dias. O setlist mais eficaz."},
	{"id": "u7_2", "nome": "Grito de Guerra", "custo": 1e11, "tipo": "prod", "alvo": "g", "alvo_id": 7, "mult": 7.0, "req_gen": 7, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao das Muralhas de Jerico", "flavor": "E o povo gritou. E a muralha caiu. Acustica impressionante."},
	{"id": "u7_3", "nome": "Raabe a Espia", "custo": 1e12, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_gen": 7, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 producao de TODOS os geradores", "flavor": "Raabe escondeu os espias. A primeira informacao privilegiada."},
	{"id": "u8_1", "nome": "Jugo do Leao", "custo": 1e11, "tipo": "prod", "alvo": "g", "alvo_id": 8, "mult": 3.0, "req_gen": 8, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao de Sansao", "flavor": "Matou um leao com as maos. O primeiro powerlifter."},
	{"id": "u8_2", "nome": "Queixada de Jumento", "custo": 1e12, "tipo": "prod", "alvo": "g", "alvo_id": 8, "mult": 7.0, "req_gen": 8, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao de Sansao", "flavor": "Mil filisteus, uma queixada. Eficiencia sem igual."},
	{"id": "u8_3", "nome": "Cabelo Restaurado", "custo": 1e13, "tipo": "speed", "alvo": "g", "alvo_id": 8, "mult": 0.5, "req_gen": 8, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 velocidade de Sansao", "flavor": "O cabelo cresceu de novo. Bonus: forca."},
	# ===== Era 3: Reino de Israel =====
	{"id": "u9_1", "nome": "Cinco Pedras", "custo": 1e13, "tipo": "prod", "alvo": "g", "alvo_id": 9, "mult": 3.0, "req_gen": 9, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao de Davi vs Golias", "flavor": "5 pedras, 1 gigante. O primeiro pitch Davi vs Golias."},
	{"id": "u9_2", "nome": "Funda de Pastor", "custo": 1e14, "tipo": "prod", "alvo": "g", "alvo_id": 9, "mult": 7.0, "req_gen": 9, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao de Davi vs Golias", "flavor": "A funda era precisa. O primeiro sniper."},
	{"id": "u9_3", "nome": "Coracao de Davi", "custo": 1e15, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_gen": 9, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 producao de TODOS os geradores", "flavor": "Homem segundo o coracao de Deus. A primeira avaliacao 5 estrelas."},
	{"id": "u10_1", "nome": "Ouro Puro", "custo": 1e14, "tipo": "prod", "alvo": "g", "alvo_id": 10, "mult": 3.0, "req_gen": 10, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao do Templo de Salomao", "flavor": "Tudo era ouro. O primeiro escritorio de luxo."},
	{"id": "u10_2", "nome": "Cedro do Libano", "custo": 1e15, "tipo": "prod", "alvo": "g", "alvo_id": 10, "mult": 7.0, "req_gen": 10, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao do Templo de Salomao", "flavor": "Madeira de cedro importada. O primeiro material premium."},
	{"id": "u10_3", "nome": "Sabedoria de Salomao", "custo": 1e16, "tipo": "discount", "alvo": "era", "alvo_id": 3, "mult": 0.9, "req_gen": 10, "req_qtd": 50, "categoria": "milagre", "efeito": "-10% custo dos geradores da Era 3", "flavor": "Pediu sabedoria, recebeu economia. O primeiro CFO."},
	{"id": "u11_1", "nome": "Tres Dias e Tres Noites", "custo": 1e15, "tipo": "prod", "alvo": "g", "alvo_id": 11, "mult": 3.0, "req_gen": 11, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao de Jonas e a Baleia", "flavor": "3 dias dentro de um peixe. A maior hospedagem forcada da historia."},
	{"id": "u11_2", "nome": "Ninive Arrependida", "custo": 1e16, "tipo": "prod", "alvo": "g", "alvo_id": 11, "mult": 7.0, "req_gen": 11, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao de Jonas e a Baleia", "flavor": "Ninive se arrependeu. O maior pivot de cidade."},
	{"id": "u11_3", "nome": "Folha de Abobora", "custo": 1e17, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_gen": 11, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 producao de TODOS os geradores", "flavor": "Deus fez crescer e secar uma planta. O primeiro teste A/B."},
	{"id": "u12_1", "nome": "Fogo Aquecido 7x", "custo": 1e16, "tipo": "prod", "alvo": "g", "alvo_id": 12, "mult": 3.0, "req_gen": 12, "req_qtd": 10, "categoria": "milagre", "efeito": "x3 producao da Fornalha Ardente", "flavor": "A fornalha foi aquecida 7x mais. O primeiro overclock."},
	{"id": "u12_2", "nome": "Quarto Homem", "custo": 1e17, "tipo": "prod", "alvo": "g", "alvo_id": 12, "mult": 7.0, "req_gen": 12, "req_qtd": 25, "categoria": "milagre", "efeito": "x7 producao da Fornalha Ardente", "flavor": "Um semelhante a um filho dos deuses. O consultor mais improvavel."},
	{"id": "u12_3", "nome": "Cheiro de Fogo", "custo": 1e18, "tipo": "speed", "alvo": "g", "alvo_id": 12, "mult": 0.5, "req_gen": 12, "req_qtd": 50, "categoria": "milagre", "efeito": "x2 velocidade da Fornalha Ardente", "flavor": "Nem cheiro de fogo ficou. O upgrade mais puro."},
	# ===== Profetas Especiais (Balanceamento.md secao 6) =====
	# Desconto
	{"id": "pe_melquisedeque", "nome": "Melquisedeque", "custo": 1e5, "tipo": "discount", "alvo": "era", "alvo_id": 1, "mult": 0.9, "req_fe_total": 1e6, "categoria": "profeta", "efeito": "-10% custo dos geradores da Era 1", "flavor": "Rei de Salem, sacerdote do Altissimo. Descontos sacerdotais."},
	{"id": "pe_jetro", "nome": "Jetro", "custo": 1e8, "tipo": "discount", "alvo": "era", "alvo_id": 2, "mult": 0.9, "req_fe_total": 1e9, "categoria": "profeta", "efeito": "-10% custo dos geradores da Era 2", "flavor": "Sogro de Moises e consultor de gestao. Delegar e economizar."},
	{"id": "pe_samuel", "nome": "Samuel", "custo": 1e11, "tipo": "discount", "alvo": "era", "alvo_id": 3, "mult": 0.9, "req_fe_total": 1e12, "categoria": "profeta", "efeito": "-10% custo dos geradores da Era 3", "flavor": "Ungiu dois reis. Sabe negociar com a realeza."},
	{"id": "pe_bezalel", "nome": "Bezalel", "custo": 1e17, "tipo": "discount", "alvo": "global", "alvo_id": 0, "mult": 0.95, "req_fe_total": 1e18, "categoria": "profeta", "efeito": "-5% custo de TODOS os geradores", "flavor": "Artesao do Tabernaculo. Materiais no atacado."},
	# Velocidade
	{"id": "pe_elias", "nome": "Elias", "custo": 1e6, "tipo": "speed", "alvo": "era", "alvo_id": 1, "mult": 0.75, "req_fe_total": 1e7, "categoria": "profeta", "efeito": "-25% tempo de ciclo na Era 1", "flavor": "Subiu num carro de fogo. Entrega expressa."},
	{"id": "pe_eliseu", "nome": "Eliseu", "custo": 1e9, "tipo": "speed", "alvo": "era", "alvo_id": 2, "mult": 0.75, "req_fe_total": 1e10, "categoria": "profeta", "efeito": "-25% tempo de ciclo na Era 2", "flavor": "Porcao dobrada do espirito. Dobro da agilidade."},
	{"id": "pe_isaias", "nome": "Isaias", "custo": 1e12, "tipo": "speed", "alvo": "era", "alvo_id": 3, "mult": 0.75, "req_fe_total": 1e13, "categoria": "profeta", "efeito": "-25% tempo de ciclo na Era 3", "flavor": "Os que esperam no Senhor renovam as forcas. E o cronometro."},
	{"id": "pe_henoc", "nome": "Henoc", "custo": 1e19, "tipo": "speed", "alvo": "global", "alvo_id": 0, "mult": 0.9, "req_fe_total": 1e20, "categoria": "profeta", "efeito": "-10% tempo de ciclo em TODOS os geradores", "flavor": "Andou com Deus e nao foi visto mais. Rapido assim."},
	# Globais (x3 producao)
	{"id": "pe_abraao", "nome": "Abraao", "custo": 1e7, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 3.0, "req_fe_total": 1e8, "categoria": "profeta", "efeito": "x3 producao de TODOS os geradores", "flavor": "Pai de multidoes. Multiplicar esta no contrato."},
	{"id": "pe_isaque", "nome": "Isaque", "custo": 1e10, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 3.0, "req_fe_total": 1e11, "categoria": "profeta", "efeito": "x3 producao de TODOS os geradores", "flavor": "Colheu cem vezes mais naquele ano. ROI biblico."},
	{"id": "pe_jaco", "nome": "Jaco", "custo": 1e13, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 3.0, "req_fe_total": 1e14, "categoria": "profeta", "efeito": "x3 producao de TODOS os geradores", "flavor": "Lutou com o anjo e venceu. Persistencia premiada."},
	{"id": "pe_daniel", "nome": "Daniel", "custo": 1e16, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 3.0, "req_fe_total": 1e17, "categoria": "profeta", "efeito": "x3 producao de TODOS os geradores", "flavor": "Sobreviveu a cova dos leoes. Gestao de risco impecavel."},
]

var _by_id: Dictionary = {}

func _ready() -> void:
	for u in DADOS:
		_by_id[u.id] = u

func get_data(id: String) -> Dictionary:
	return _by_id.get(id, {})

func requisito_atingido(u: Dictionary) -> bool:
	if u.has("req_gen"):
		var state: Dictionary = GameState.geradores.get(u.req_gen, {})
		return int(state.get("qtd", 0)) >= u.req_qtd
	if u.has("req_fe_total"):
		return GameState.fe_total_vida >= u.req_fe_total
	return true

func requisito_texto(u: Dictionary) -> String:
	if u.has("req_gen"):
		var data: Dictionary = Geradores.get_data(u.req_gen)
		return str(u.req_qtd) + "x " + str(data.get("nome", "?"))
	if u.has("req_fe_total"):
		return NumberFormat.format(u.req_fe_total) + " de Fe total"
	return ""

# Upgrades ainda nao comprados cujo requisito ja foi atingido.
func disponiveis() -> Array:
	var result: Array = []
	for u in DADOS:
		if u.id in GameState.upgrades_comprados:
			continue
		if requisito_atingido(u):
			result.append(u)
	result.sort_custom(func(a, b): return a.custo < b.custo)
	return result

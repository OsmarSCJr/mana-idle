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
	{"id": "u1_1", "nome": "Dia e Noite", "custo": 5e+3, "tipo": "prod", "alvo": "g", "alvo_id": 1, "mult": 2.0, "req_gen": 1, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao de Haja Luz", "flavor": "E separou a luz das trevas. E tambem o dia da noite."},
	{"id": "u1_2", "nome": "Seja Fecundo", "custo": 2.5e+5, "tipo": "prod", "alvo": "g", "alvo_id": 1, "mult": 3.0, "req_gen": 1, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao de Haja Luz", "flavor": "Crescei e multiplicai-vos. Ate os numeros."},
	{"id": "u1_3", "nome": "E Viu que era Bom", "custo": 2.5e+6, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 1.5, "req_gen": 1, "req_qtd": 150, "categoria": "milagre", "efeito": "x1.5 producao de TODOS os geradores", "flavor": "E viu Deus tudo quanto tinha feito, e eis que era muito bom."},
	{"id": "u2_1", "nome": "Arvores do Jardim", "custo": 5e+5, "tipo": "prod", "alvo": "g", "alvo_id": 2, "mult": 2.0, "req_gen": 2, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao do Jardim do Eden", "flavor": "Arvore da vida, arvore do conhecimento. Cardapio divino."},
	{"id": "u2_2", "nome": "Quatro Rios", "custo": 5e+6, "tipo": "prod", "alvo": "g", "alvo_id": 2, "mult": 3.0, "req_gen": 2, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao do Jardim do Eden", "flavor": "Pisom, Giom, Tigre, Eufrates. O primeiro sistema de irrigacao."},
	{"id": "u2_3", "nome": "Coroa da Criacao", "custo": 5e+7, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 1.5, "req_gen": 2, "req_qtd": 150, "categoria": "milagre", "efeito": "x1.5 producao de TODOS os geradores", "flavor": "Adao deu nome a todos os animais. O primeiro CEO."},
	{"id": "u3_1", "nome": "Tabuas Extra", "custo": 2.5e+7, "tipo": "prod", "alvo": "g", "alvo_id": 3, "mult": 2.0, "req_gen": 3, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao da Arca de Noe", "flavor": "Madeira de gofer. O primeiro material sustentavel."},
	{"id": "u3_2", "nome": "Dois a Dois", "custo": 2.5e+8, "tipo": "prod", "alvo": "g", "alvo_id": 3, "mult": 3.0, "req_gen": 3, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao da Arca de Noe", "flavor": "Entraram de dois em dois. Logistica impecavel."},
	{"id": "u3_3", "nome": "Arco-Iris", "custo": 2.5e+9, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 1.5, "req_gen": 3, "req_qtd": 150, "categoria": "milagre", "efeito": "x1.5 producao de TODOS os geradores", "flavor": "Sinal da alianca. O primeiro SLA entre ceu e terra."},
	{"id": "u4_1", "nome": "Tijolos Cozidos", "custo": 2.5e+8, "tipo": "prod", "alvo": "g", "alvo_id": 4, "mult": 2.0, "req_gen": 4, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao da Torre de Babel", "flavor": "Tijolos em vez de pedras. O primeiro pivo de materiais."},
	{"id": "u4_2", "nome": "Betume por Argamassa", "custo": 2.5e+9, "tipo": "prod", "alvo": "g", "alvo_id": 4, "mult": 3.0, "req_gen": 4, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao da Torre de Babel", "flavor": "Betume e mais adesivo. Engenharia de ponta."},
	{"id": "u4_3", "nome": "Confusao de Linguas", "custo": 2.5e+10, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 1.5, "req_gen": 4, "req_qtd": 150, "categoria": "milagre", "efeito": "x1.5 producao de TODOS os geradores", "flavor": "Deus confundiu as linguas. O primeiro Babel Fish falhou."},
	{"id": "u4_4", "nome": "Desbloqueio x100", "custo": 5e+10, "tipo": "unlock", "alvo": "global", "alvo_id": 0, "mult": 1.0, "req_gen": 4, "req_qtd": 200, "categoria": "milagre", "efeito": "Habilita o modo de compra x100", "flavor": "Compre em massa. Nem a torre era tao alta."},
	# ===== Era 2: Exodo & Conquista =====
	{"id": "u5_1", "nome": "Pao dos Anjos", "custo": 5e+9, "tipo": "prod", "alvo": "g", "alvo_id": 5, "mult": 2.0, "req_gen": 5, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao do Mana do Ceu", "flavor": "Pao do ceu. Breakfast delivery sem taxa."},
	{"id": "u5_2", "nome": "Dobro na Sexta", "custo": 5e+10, "tipo": "prod", "alvo": "g", "alvo_id": 5, "mult": 3.0, "req_gen": 5, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao do Mana do Ceu", "flavor": "Colham o dobro na sexta. O primeiro fim de semana."},
	{"id": "u5_3", "nome": "Agua da Rocha", "custo": 5e+11, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 1.5, "req_gen": 5, "req_qtd": 150, "categoria": "milagre", "efeito": "x1.5 producao de TODOS os geradores", "flavor": "Moises bateu na rocha. A primeira fonte divina."},
	{"id": "u6_1", "nome": "Vento Oriental", "custo": 5e+10, "tipo": "prod", "alvo": "g", "alvo_id": 6, "mult": 2.0, "req_gen": 6, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao do Mar Vermelho", "flavor": "Um vento forte dividiu as aguas. Natureza a servico."},
	{"id": "u6_2", "nome": "Paredes de Agua", "custo": 5e+11, "tipo": "prod", "alvo": "g", "alvo_id": 6, "mult": 3.0, "req_gen": 6, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao do Mar Vermelho", "flavor": "Agua como muralhas dos dois lados. Engenharia hidraulica."},
	{"id": "u6_3", "nome": "Bastao de Moises", "custo": 5e+12, "tipo": "speed", "alvo": "g", "alvo_id": 6, "mult": 0.7, "req_gen": 6, "req_qtd": 150, "categoria": "milagre", "efeito": "-30% tempo de ciclo do Mar Vermelho", "flavor": "Levanta o bastao. O botao de turbo."},
	{"id": "u7_1", "nome": "Sete Trombetas", "custo": 5e+11, "tipo": "prod", "alvo": "g", "alvo_id": 7, "mult": 2.0, "req_gen": 7, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao das Muralhas de Jerico", "flavor": "7 trombetas, 7 dias. O setlist mais eficaz."},
	{"id": "u7_2", "nome": "Grito de Guerra", "custo": 5e+12, "tipo": "prod", "alvo": "g", "alvo_id": 7, "mult": 3.0, "req_gen": 7, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao das Muralhas de Jerico", "flavor": "E o povo gritou. E a muralha caiu. Acustica impressionante."},
	{"id": "u7_3", "nome": "Raabe a Espia", "custo": 5e+13, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 1.5, "req_gen": 7, "req_qtd": 150, "categoria": "milagre", "efeito": "x1.5 producao de TODOS os geradores", "flavor": "Raabe escondeu os espias. A primeira informacao privilegiada."},
	{"id": "u8_1", "nome": "Jugo do Leao", "custo": 5e+12, "tipo": "prod", "alvo": "g", "alvo_id": 8, "mult": 2.0, "req_gen": 8, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao de Sansao", "flavor": "Matou um leao com as maos. O primeiro powerlifter."},
	{"id": "u8_2", "nome": "Queixada de Jumento", "custo": 5e+13, "tipo": "prod", "alvo": "g", "alvo_id": 8, "mult": 3.0, "req_gen": 8, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao de Sansao", "flavor": "Mil filisteus, uma queixada. Eficiencia sem igual."},
	{"id": "u8_3", "nome": "Cabelo Restaurado", "custo": 5e+14, "tipo": "speed", "alvo": "g", "alvo_id": 8, "mult": 0.7, "req_gen": 8, "req_qtd": 150, "categoria": "milagre", "efeito": "-30% tempo de ciclo de Sansao", "flavor": "O cabelo cresceu de novo. Bonus: forca."},
	# ===== Era 3: Reino de Israel =====
	{"id": "u9_1", "nome": "Cinco Pedras", "custo": 5e+14, "tipo": "prod", "alvo": "g", "alvo_id": 9, "mult": 2.0, "req_gen": 9, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao de Davi vs Golias", "flavor": "5 pedras, 1 gigante. O primeiro pitch Davi vs Golias."},
	{"id": "u9_2", "nome": "Funda de Pastor", "custo": 5e+15, "tipo": "prod", "alvo": "g", "alvo_id": 9, "mult": 3.0, "req_gen": 9, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao de Davi vs Golias", "flavor": "A funda era precisa. O primeiro sniper."},
	{"id": "u9_3", "nome": "Coracao de Davi", "custo": 5e+16, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 1.5, "req_gen": 9, "req_qtd": 150, "categoria": "milagre", "efeito": "x1.5 producao de TODOS os geradores", "flavor": "Homem segundo o coracao de Deus. A primeira avaliacao 5 estrelas."},
	{"id": "u10_1", "nome": "Ouro Puro", "custo": 5e+15, "tipo": "prod", "alvo": "g", "alvo_id": 10, "mult": 2.0, "req_gen": 10, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao do Templo de Salomao", "flavor": "Tudo era ouro. O primeiro escritorio de luxo."},
	{"id": "u10_2", "nome": "Cedro do Libano", "custo": 5e+16, "tipo": "prod", "alvo": "g", "alvo_id": 10, "mult": 3.0, "req_gen": 10, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao do Templo de Salomao", "flavor": "Madeira de cedro importada. O primeiro material premium."},
	{"id": "u10_3", "nome": "Sabedoria de Salomao", "custo": 5e+17, "tipo": "discount", "alvo": "era", "alvo_id": 3, "mult": 0.9, "req_gen": 10, "req_qtd": 150, "categoria": "milagre", "efeito": "-10% custo dos geradores da Era 3", "flavor": "Pediu sabedoria, recebeu economia. O primeiro CFO."},
	{"id": "u11_1", "nome": "Tres Dias e Tres Noites", "custo": 5e+16, "tipo": "prod", "alvo": "g", "alvo_id": 11, "mult": 2.0, "req_gen": 11, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao de Jonas e a Baleia", "flavor": "3 dias dentro de um peixe. A maior hospedagem forcada da historia."},
	{"id": "u11_2", "nome": "Ninive Arrependida", "custo": 5e+17, "tipo": "prod", "alvo": "g", "alvo_id": 11, "mult": 3.0, "req_gen": 11, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao de Jonas e a Baleia", "flavor": "Ninive se arrependeu. O maior pivot de cidade."},
	{"id": "u11_3", "nome": "Folha de Abobora", "custo": 5e+18, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 1.5, "req_gen": 11, "req_qtd": 150, "categoria": "milagre", "efeito": "x1.5 producao de TODOS os geradores", "flavor": "Deus fez crescer e secar uma planta. O primeiro teste A/B."},
	{"id": "u12_1", "nome": "Fogo Aquecido 7x", "custo": 5e+17, "tipo": "prod", "alvo": "g", "alvo_id": 12, "mult": 2.0, "req_gen": 12, "req_qtd": 25, "categoria": "milagre", "efeito": "x2 producao da Fornalha Ardente", "flavor": "A fornalha foi aquecida 7x mais. O primeiro overclock."},
	{"id": "u12_2", "nome": "Quarto Homem", "custo": 5e+18, "tipo": "prod", "alvo": "g", "alvo_id": 12, "mult": 3.0, "req_gen": 12, "req_qtd": 75, "categoria": "milagre", "efeito": "x3 producao da Fornalha Ardente", "flavor": "Um semelhante a um filho dos deuses. O consultor mais improvavel."},
	{"id": "u12_3", "nome": "Cheiro de Fogo", "custo": 5e+19, "tipo": "speed", "alvo": "g", "alvo_id": 12, "mult": 0.7, "req_gen": 12, "req_qtd": 150, "categoria": "milagre", "efeito": "-30% tempo de ciclo da Fornalha Ardente", "flavor": "Nem cheiro de fogo ficou. O upgrade mais puro."},
	# ===== Profetas Especiais (Balanceamento.md secao 6) =====
	# Desconto
	{"id": "pe_melquisedeque", "nome": "Melquisedeque", "custo": 5e+6, "tipo": "discount", "alvo": "era", "alvo_id": 1, "mult": 0.9, "req_fe_total": 2e+7, "categoria": "profeta", "efeito": "-10% custo dos geradores da Era 1", "flavor": "Rei de Salem, sacerdote do Altissimo. Descontos sacerdotais."},
	{"id": "pe_jetro", "nome": "Jetro", "custo": 5e+9, "tipo": "discount", "alvo": "era", "alvo_id": 2, "mult": 0.9, "req_fe_total": 2e+10, "categoria": "profeta", "efeito": "-10% custo dos geradores da Era 2", "flavor": "Sogro de Moises e consultor de gestao. Delegar e economizar."},
	{"id": "pe_samuel", "nome": "Samuel", "custo": 5e+12, "tipo": "discount", "alvo": "era", "alvo_id": 3, "mult": 0.9, "req_fe_total": 2e+13, "categoria": "profeta", "efeito": "-10% custo dos geradores da Era 3", "flavor": "Ungiu dois reis. Sabe negociar com a realeza."},
	{"id": "pe_bezalel", "nome": "Bezalel", "custo": 5e+18, "tipo": "discount", "alvo": "global", "alvo_id": 0, "mult": 0.95, "req_fe_total": 2e+19, "categoria": "profeta", "efeito": "-5% custo de TODOS os geradores", "flavor": "Artesao do Tabernaculo. Materiais no atacado."},
	# Velocidade
	{"id": "pe_elias", "nome": "Elias", "custo": 5e+7, "tipo": "speed", "alvo": "era", "alvo_id": 1, "mult": 0.75, "req_fe_total": 2e+8, "categoria": "profeta", "efeito": "-25% tempo de ciclo na Era 1", "flavor": "Subiu num carro de fogo. Entrega expressa."},
	{"id": "pe_eliseu", "nome": "Eliseu", "custo": 5e+10, "tipo": "speed", "alvo": "era", "alvo_id": 2, "mult": 0.75, "req_fe_total": 2e+11, "categoria": "profeta", "efeito": "-25% tempo de ciclo na Era 2", "flavor": "Porcao dobrada do espirito. Dobro da agilidade."},
	{"id": "pe_isaias", "nome": "Isaias", "custo": 5e+13, "tipo": "speed", "alvo": "era", "alvo_id": 3, "mult": 0.75, "req_fe_total": 2e+14, "categoria": "profeta", "efeito": "-25% tempo de ciclo na Era 3", "flavor": "Os que esperam no Senhor renovam as forcas. E o cronometro."},
	{"id": "pe_henoc", "nome": "Henoc", "custo": 5e+20, "tipo": "speed", "alvo": "global", "alvo_id": 0, "mult": 0.9, "req_fe_total": 2e+21, "categoria": "profeta", "efeito": "-10% tempo de ciclo em TODOS os geradores", "flavor": "Andou com Deus e nao foi visto mais. Rapido assim."},
	# Globais (x3 producao)
	{"id": "pe_abraao", "nome": "Abraao", "custo": 5e+8, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_fe_total": 2e+9, "categoria": "profeta", "efeito": "x2 producao de TODOS os geradores", "flavor": "Pai de multidoes. Multiplicar esta no contrato."},
	{"id": "pe_isaque", "nome": "Isaque", "custo": 5e+11, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_fe_total": 2e+12, "categoria": "profeta", "efeito": "x2 producao de TODOS os geradores", "flavor": "Colheu cem vezes mais naquele ano. ROI biblico."},
	{"id": "pe_jaco", "nome": "Jaco", "custo": 5e+14, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_fe_total": 2e+15, "categoria": "profeta", "efeito": "x2 producao de TODOS os geradores", "flavor": "Lutou com o anjo e venceu. Persistencia premiada."},
	{"id": "pe_daniel", "nome": "Daniel", "custo": 5e+17, "tipo": "global", "alvo": "global", "alvo_id": 0, "mult": 2.0, "req_fe_total": 2e+18, "categoria": "profeta", "efeito": "x2 producao de TODOS os geradores", "flavor": "Sobreviveu a cova dos leoes. Gestao de risco impecavel."},
]

# Bencaos de nivel alto geradas por codigo: 5 tiers para CADA um dos 36
# geradores (curadas acima cobrem so o comeco). Custos derivam do custo_base
# do gerador, entao acompanham qualquer rebalanceamento automaticamente.
const TIERS_ALTOS: Array = [
	{"req": 150, "mult": 2.0, "custo_fator": 1.0e5, "sufixo": "I"},
	{"req": 250, "mult": 2.0, "custo_fator": 1.0e8, "sufixo": "II"},
	{"req": 400, "mult": 3.0, "custo_fator": 1.0e12, "sufixo": "III"},
	{"req": 600, "mult": 3.0, "custo_fator": 1.0e16, "sufixo": "IV"},
	{"req": 1000, "mult": 5.0, "custo_fator": 1.0e21, "sufixo": "V"},
]

const FLAVORS_TIER: Array = [
	"A fidelidade constante gera frutos cada vez maiores.",
	"Quem foi fiel no pouco, sobre o muito sera colocado.",
	"A perseveranca completa a obra.",
	"Ate aqui nos ajudou o Senhor.",
	"Coroa para quem corre ate o fim.",
]

# Bencaos de VELOCIDADE geradas: 5 tiers por gerador. O multiplicador por
# tier e a raiz 5a de (tempo_min / tempo), entao comprar os 5 leva o ciclo
# exatamente ao tempo_min da tabela de Geradores (o clamp em Economy garante
# que outros bonus de velocidade nao passem desse teto).
# Reqs alinhados a corrida aos 10000: o tier V e alcancavel de verdade com o
# softcap de growth (900 unidades a 1.11 fixo era matematicamente inatingivel).
const TIERS_VELOCIDADE: Array = [
	{"req": 50, "custo_fator": 1.0e4, "sufixo": "I"},
	{"req": 100, "custo_fator": 1.0e7, "sufixo": "II"},
	{"req": 250, "custo_fator": 1.0e11, "sufixo": "III"},
	{"req": 500, "custo_fator": 1.0e15, "sufixo": "IV"},
	{"req": 1000, "custo_fator": 1.0e20, "sufixo": "V"},
]

const FLAVORS_VELOCIDADE: Array = [
	"O vento sopra onde quer. Hoje, a favor.",
	"Correram e nao se cansaram.",
	"Asas como aguias.",
	"Mais veloz que corca sobre os montes.",
	"O carro de fogo nao espera.",
]

var _by_id: Dictionary = {}
var _dados_all: Array = []

func _ready() -> void:
	_dados_all = DADOS.duplicate()
	for gen_id in range(1, Geradores.count() + 1):
		var gdata: Dictionary = Geradores.get_data(gen_id)
		for i in TIERS_ALTOS.size():
			var tier: Dictionary = TIERS_ALTOS[i]
			_dados_all.append({
				"id": "ub%d_%s" % [gen_id, tier.sufixo],
				"nome": "Bênção de " + str(gdata.nome) + " " + str(tier.sufixo),
				"custo": float(gdata.custo_base) * float(tier.custo_fator),
				"tipo": "prod", "alvo": "g", "alvo_id": gen_id,
				"mult": float(tier.mult),
				"req_gen": gen_id, "req_qtd": int(tier.req),
				"categoria": "milagre",
				"efeito": "x" + str(int(tier.mult)) + " producao de " + str(gdata.nome),
				"flavor": FLAVORS_TIER[i],
			})
		# Serie de velocidade: 5 compras levam do tempo base ao tempo_min.
		var ratio: float = float(gdata.get("tempo_min", 0.1)) / float(gdata.tempo)
		var mult_tier: float = pow(ratio, 1.0 / float(TIERS_VELOCIDADE.size()))
		var pct: int = int(round((1.0 - mult_tier) * 100.0))
		for i in TIERS_VELOCIDADE.size():
			var tier: Dictionary = TIERS_VELOCIDADE[i]
			_dados_all.append({
				"id": "us%d_%s" % [gen_id, tier.sufixo],
				"nome": "Sopro de " + str(gdata.nome) + " " + str(tier.sufixo),
				"custo": float(gdata.custo_base) * float(tier.custo_fator),
				"tipo": "speed", "alvo": "g", "alvo_id": gen_id,
				"mult": mult_tier,
				"req_gen": gen_id, "req_qtd": int(tier.req),
				"categoria": "milagre",
				"efeito": "-" + str(pct) + "% tempo de ciclo de " + str(gdata.nome),
				"flavor": FLAVORS_VELOCIDADE[i],
			})
	for u in _dados_all:
		_by_id[u.id] = u

func get_data(id: String) -> Dictionary:
	return _by_id.get(id, {})

# Moeda cobrada pelo upgrade: a da aventura do gerador/era alvo. Upgrades
# globais e profetas especiais pertencem a Jornada Principal (Fe).
func currency_for(u: Dictionary) -> String:
	match str(u.get("alvo", "global")):
		"g":
			return GameState.get_currency_for_gen(int(u.alvo_id))
		"era":
			var era_gens: Array = Geradores.get_by_era(int(u.alvo_id))
			if not era_gens.is_empty():
				return GameState.get_currency_for_gen(int(era_gens[0].id))
	return "fe"

# Upgrades de aventura persistem no prestige (a Ressurreicao e um evento da
# Jornada Principal; as aventuras sao a camada permanente entre resets).
func is_adventure_upgrade(u: Dictionary) -> bool:
	return currency_for(u) != "fe"

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
	for u in _dados_all:
		if u.id in GameState.upgrades_comprados:
			continue
		if requisito_atingido(u):
			result.append(u)
	result.sort_custom(func(a, b): return a.custo < b.custo)
	return result

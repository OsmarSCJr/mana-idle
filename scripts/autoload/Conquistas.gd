extends Node

## Conquistas: metas permanentes que atravessam todos os sistemas.
##
## Cada conquista concede um bônus pequeno e permanente de produção global
## (BONUS_PADRAO, ou BONUS_MARCO para as de peso). O efeito é somado, não
## multiplicado, e tem teto explícito em BONUS_MAXIMO — assim o sistema nunca
## vira o motor principal de poder, só uma recompensa por explorar o jogo.
##
## Verificação: em vez de código por conquista, cada uma declara um `tipo` e um
## `alvo`, avaliados contra um retrato do estado. Isso mantém a tabela legível e
## o avaliador em um só lugar, que é o que os testes exercitam.

const BONUS_PADRAO: float = 0.01
const BONUS_MARCO: float = 0.03
const BONUS_MAXIMO: float = 1.0

const DADOS: Array = [
	# ---- Geradores e unidades
	{"id": "c_primeira_luz", "nome": "Primeira Luz", "desc": "Compre a sua primeira unidade.", "cat": "jornada", "tipo": "qualquer_gen_qtd", "alvo": 1},
	{"id": "c_dez_unidades", "nome": "Semente", "desc": "Chegue a 10 unidades em um gerador.", "cat": "jornada", "tipo": "qualquer_gen_qtd", "alvo": 10},
	{"id": "c_cem_unidades", "nome": "Centena", "desc": "Chegue a 100 unidades em um gerador.", "cat": "jornada", "tipo": "qualquer_gen_qtd", "alvo": 100},
	{"id": "c_meia_meta", "nome": "Meio Caminho", "desc": "Chegue a 500 unidades em um gerador.", "cat": "jornada", "tipo": "qualquer_gen_qtd", "alvo": 500},
	{"id": "c_meta_unica", "nome": "Plenitude", "desc": "Leve um gerador à meta da campanha.", "cat": "jornada", "tipo": "qualquer_gen_qtd", "alvo": 1000, "bonus": BONUS_MARCO},
	{"id": "c_todos_25", "nome": "Nenhum Deixado", "desc": "Todos os geradores da campanha em 25.", "cat": "jornada", "tipo": "min_qtd", "alvo": 25},
	{"id": "c_todos_100", "nome": "Coro Completo", "desc": "Todos os geradores da campanha em 100.", "cat": "jornada", "tipo": "min_qtd", "alvo": 100},
	{"id": "c_todos_250", "nome": "Assembleia", "desc": "Todos os geradores da campanha em 250.", "cat": "jornada", "tipo": "min_qtd", "alvo": 250},
	{"id": "c_todos_500", "nome": "Concerto", "desc": "Todos os geradores da campanha em 500.", "cat": "jornada", "tipo": "min_qtd", "alvo": 500, "bonus": BONUS_MARCO},
	{"id": "c_todos_meta", "nome": "Troféu da Campanha", "desc": "Todos os geradores da campanha na meta.", "cat": "jornada", "tipo": "min_qtd", "alvo": 1000, "bonus": BONUS_MARCO},
	{"id": "c_era_completa", "nome": "Uma Era", "desc": "Destrave os quatro geradores de uma era.", "cat": "jornada", "tipo": "geradores_destravados", "alvo": 4},
	{"id": "c_doze_geradores", "nome": "Do Início ao Fim", "desc": "Destrave os doze geradores de uma campanha.", "cat": "jornada", "tipo": "geradores_destravados", "alvo": 12},

	# ---- Profetas e automação
	{"id": "c_primeiro_profeta", "nome": "Chamado", "desc": "Contrate o seu primeiro profeta.", "cat": "profetas", "tipo": "profetas", "alvo": 1},
	{"id": "c_quatro_profetas", "nome": "Quatro Vozes", "desc": "Tenha quatro profetas ativos.", "cat": "profetas", "tipo": "profetas", "alvo": 4},
	{"id": "c_doze_profetas", "nome": "Todos Enviados", "desc": "Tenha doze profetas ativos.", "cat": "profetas", "tipo": "profetas", "alvo": 12},
	{"id": "c_vinte_profetas", "nome": "Nuvem de Testemunhas", "desc": "Tenha vinte profetas ativos.", "cat": "profetas", "tipo": "profetas", "alvo": 20},

	# ---- Bênçãos
	{"id": "c_dez_bencaos", "nome": "Favor", "desc": "Compre 10 bênçãos.", "cat": "bencaos", "tipo": "bencaos", "alvo": 10},
	{"id": "c_cinquenta_bencaos", "nome": "Abundância", "desc": "Compre 50 bênçãos.", "cat": "bencaos", "tipo": "bencaos", "alvo": 50},
	{"id": "c_duzentas_bencaos", "nome": "Transbordo", "desc": "Compre 200 bênçãos.", "cat": "bencaos", "tipo": "bencaos", "alvo": 200, "bonus": BONUS_MARCO},

	# ---- Prestígio
	{"id": "c_primeiro_santo", "nome": "Primeiro Santo", "desc": "Faça a sua primeira Ressurreição.", "cat": "prestigio", "tipo": "prestiges", "alvo": 1},
	{"id": "c_cinco_prestiges", "nome": "Ciclo", "desc": "Cinco Ressurreições.", "cat": "prestigio", "tipo": "prestiges", "alvo": 5},
	{"id": "c_vinte_prestiges", "nome": "Perseverança", "desc": "Vinte Ressurreições.", "cat": "prestigio", "tipo": "prestiges", "alvo": 20},
	{"id": "c_cem_prestiges", "nome": "Sem Desistir", "desc": "Cem Ressurreições.", "cat": "prestigio", "tipo": "prestiges", "alvo": 100, "bonus": BONUS_MARCO},
	{"id": "c_cem_santos", "nome": "Cem Santos", "desc": "Acumule 100 Santos no total.", "cat": "prestigio", "tipo": "santos_total", "alvo": 100},
	{"id": "c_mil_santos", "nome": "Mil Santos", "desc": "Acumule 1.000 Santos no total.", "cat": "prestigio", "tipo": "santos_total", "alvo": 1000},
	{"id": "c_frutos_dez", "nome": "Frutos do Espírito X", "desc": "Chegue ao nível 10 da escada de Frutos.", "cat": "prestigio", "tipo": "frutos", "alvo": 10},
	{"id": "c_frutos_trinta", "nome": "Frutos do Espírito XXX", "desc": "Chegue ao nível 30 da escada de Frutos.", "cat": "prestigio", "tipo": "frutos", "alvo": 30},

	# ---- Aliança
	{"id": "c_primeira_alianca", "nome": "Aliança", "desc": "Faça a sua primeira Ascensão.", "cat": "alianca", "tipo": "ascensoes", "alvo": 1, "bonus": BONUS_MARCO},
	{"id": "c_tres_aliancas", "nome": "Três Vezes Fiel", "desc": "Três Ascensões.", "cat": "alianca", "tipo": "ascensoes", "alvo": 3},
	{"id": "c_dez_aliancas", "nome": "Aliança Eterna", "desc": "Dez Ascensões.", "cat": "alianca", "tipo": "ascensoes", "alvo": 10, "bonus": BONUS_MARCO},
	{"id": "c_cinco_nos", "nome": "Raízes", "desc": "Compre cinco nós da árvore da Aliança.", "cat": "alianca", "tipo": "nos_alianca", "alvo": 5},
	{"id": "c_arvore_completa", "nome": "Árvore Completa", "desc": "Compre todos os nós da Aliança.", "cat": "alianca", "tipo": "nos_alianca", "alvo": 99, "bonus": BONUS_MARCO},

	# ---- Campanhas
	{"id": "c_segunda_aventura", "nome": "O Caminho", "desc": "Desbloqueie a Vida de Cristo.", "cat": "campanhas", "tipo": "aventuras_desbloqueadas", "alvo": 2},
	{"id": "c_terceira_aventura", "nome": "A Consumação", "desc": "Desbloqueie Igreja & Apocalipse.", "cat": "campanhas", "tipo": "aventuras_desbloqueadas", "alvo": 3},
	{"id": "c_uma_concluida", "nome": "Capítulo Fechado", "desc": "Conclua uma campanha.", "cat": "campanhas", "tipo": "aventuras_concluidas", "alvo": 1},
	{"id": "c_todas_concluidas", "nome": "Do Gênesis ao Apocalipse", "desc": "Conclua todas as campanhas.", "cat": "campanhas", "tipo": "aventuras_concluidas", "alvo": 2, "bonus": BONUS_MARCO},
	{"id": "c_dez_marcos", "nome": "Marcado", "desc": "Alcance 10 marcos gerais.", "cat": "campanhas", "tipo": "marcos_gerais", "alvo": 10},
	{"id": "c_vinte_marcos", "nome": "Colecionador de Marcos", "desc": "Alcance 20 marcos gerais.", "cat": "campanhas", "tipo": "marcos_gerais", "alvo": 20},

	# ---- Estudo e Bíblia
	{"id": "c_primeiro_estudo", "nome": "Aluno", "desc": "Domine o seu primeiro estudo.", "cat": "estudo", "tipo": "estudos_dominados", "alvo": 1},
	{"id": "c_dez_estudos", "nome": "Escriba", "desc": "Domine 10 estudos.", "cat": "estudo", "tipo": "estudos_dominados", "alvo": 10},
	{"id": "c_todos_estudos", "nome": "Mestre da Palavra", "desc": "Domine todos os estudos.", "cat": "estudo", "tipo": "estudos_dominados", "alvo": 36, "bonus": BONUS_MARCO},
	{"id": "c_dez_capitulos", "nome": "Leitor", "desc": "Leia 10 capítulos da Bíblia.", "cat": "estudo", "tipo": "capitulos_lidos", "alvo": 10},
	{"id": "c_cem_capitulos", "nome": "Leitor Assíduo", "desc": "Leia 100 capítulos da Bíblia.", "cat": "estudo", "tipo": "capitulos_lidos", "alvo": 100},
	{"id": "c_mil_capitulos", "nome": "Bíblia Inteira", "desc": "Leia 1.000 capítulos da Bíblia.", "cat": "estudo", "tipo": "capitulos_lidos", "alvo": 1000, "bonus": BONUS_MARCO},
	{"id": "c_dez_conhecimentos", "nome": "Entendimento", "desc": "Compre 10 Conhecimentos.", "cat": "estudo", "tipo": "conhecimentos", "alvo": 10},
	{"id": "c_vinte_sabedoria", "nome": "Sabedoria", "desc": "Acumule 20 pontos de Sabedoria.", "cat": "estudo", "tipo": "sabedoria_total", "alvo": 20},
	{"id": "c_cem_sabedoria", "nome": "Coração Entendido", "desc": "Acumule 100 pontos de Sabedoria.", "cat": "estudo", "tipo": "sabedoria_total", "alvo": 100},

	# ---- Devocional
	{"id": "c_primeiro_devocional", "nome": "Primeiro Dia", "desc": "Conclua o seu primeiro devocional.", "cat": "devocional", "tipo": "devocional_total", "alvo": 1},
	{"id": "c_sequencia_3", "nome": "Três Dias", "desc": "Três dias seguidos de devocional.", "cat": "devocional", "tipo": "devocional_sequencia", "alvo": 3},
	{"id": "c_sequencia_7", "nome": "Uma Semana", "desc": "Sete dias seguidos de devocional.", "cat": "devocional", "tipo": "devocional_sequencia", "alvo": 7},
	{"id": "c_sequencia_30", "nome": "Um Mês", "desc": "Trinta dias seguidos de devocional.", "cat": "devocional", "tipo": "devocional_sequencia", "alvo": 30, "bonus": BONUS_MARCO},
	{"id": "c_sequencia_100", "nome": "Cem Dias", "desc": "Cem dias seguidos de devocional.", "cat": "devocional", "tipo": "devocional_sequencia", "alvo": 100, "bonus": BONUS_MARCO},
	{"id": "c_plano_completo", "nome": "Plano Concluído", "desc": "Conclua um plano de leitura.", "cat": "devocional", "tipo": "planos_devocional", "alvo": 1},
	{"id": "c_dois_planos", "nome": "Dois Planos", "desc": "Conclua dois planos de leitura.", "cat": "devocional", "tipo": "planos_devocional", "alvo": 2, "bonus": BONUS_MARCO},
	{"id": "c_dez_destaques", "nome": "Sublinhado", "desc": "Destaque 10 versículos.", "cat": "devocional", "tipo": "destaques", "alvo": 10},
	{"id": "c_cinco_notas", "nome": "Caderno", "desc": "Escreva 5 anotações.", "cat": "devocional", "tipo": "notas", "alvo": 5},

	# ---- Provações
	{"id": "c_primeira_provacao", "nome": "Provado", "desc": "Conclua a sua primeira Provação.", "cat": "provacoes", "tipo": "provacoes_concluidas", "alvo": 1},
	{"id": "c_todas_provacoes", "nome": "Aprovado", "desc": "Conclua todas as Provações ao menos uma vez.", "cat": "provacoes", "tipo": "provacoes_distintas", "alvo": 6, "bonus": BONUS_MARCO},
	{"id": "c_dez_provacoes", "nome": "Refinado", "desc": "Conclua 10 Provações.", "cat": "provacoes", "tipo": "provacoes_concluidas", "alvo": 10},

	# ---- Coleção e hábito
	{"id": "c_primeiro_cosmetico", "nome": "Ornamento", "desc": "Adquira o seu primeiro cosmético.", "cat": "colecao", "tipo": "cosmeticos", "alvo": 1},
	{"id": "c_cinco_cosmeticos", "nome": "Santuário Vestido", "desc": "Adquira cinco cosméticos.", "cat": "colecao", "tipo": "cosmeticos", "alvo": 5},
	{"id": "c_dez_metas", "nome": "Disciplina", "desc": "Cumpra 10 metas diárias.", "cat": "colecao", "tipo": "metas_cumpridas", "alvo": 10},
	{"id": "c_cinquenta_metas", "nome": "Constância", "desc": "Cumpra 50 metas diárias.", "cat": "colecao", "tipo": "metas_cumpridas", "alvo": 50},
	{"id": "c_uma_hora", "nome": "Uma Hora", "desc": "Uma hora de jogo.", "cat": "colecao", "tipo": "tempo_jogado", "alvo": 3600},
	{"id": "c_dez_horas", "nome": "Dez Horas", "desc": "Dez horas de jogo.", "cat": "colecao", "tipo": "tempo_jogado", "alvo": 36000},
	{"id": "c_cem_horas", "nome": "Cem Horas", "desc": "Cem horas de jogo.", "cat": "colecao", "tipo": "tempo_jogado", "alvo": 360000, "bonus": BONUS_MARCO},
]

var _by_id: Dictionary = {}


func _ready() -> void:
	for d in DADOS:
		_by_id[str(d.id)] = d


func exists(achievement_id: String) -> bool:
	return _by_id.has(achievement_id)


func get_data(achievement_id: String) -> Dictionary:
	return _by_id.get(achievement_id, {})


func bonus_de(achievement_id: String) -> float:
	return float(get_data(achievement_id).get("bonus", BONUS_PADRAO))


func desbloqueada(achievement_id: String) -> bool:
	return achievement_id in GameState.conquistas


func total() -> int:
	return DADOS.size()


func desbloqueadas() -> int:
	return GameState.conquistas.size()


## Bônus somado de todas as conquistas, com teto. Entra na produção global.
func bonus_total() -> float:
	var soma := 0.0
	for achievement_id in GameState.conquistas:
		soma += bonus_de(str(achievement_id))
	return minf(soma, BONUS_MAXIMO)


func multiplicador() -> float:
	return 1.0 + bonus_total()


## Metas diárias cumpridas na vida da conta. É o único progresso de conquista que
## não se deduz de outro campo, por isso vive no save (metasDiarias.totalCumpridas).
func metas_cumpridas() -> int:
	return maxi(0, int(GameState.metas_diarias.get("totalCumpridas", 0)))


# ------------------------------------------------------------------ Avaliação

## Retrato do estado usado pelo avaliador. Montado uma vez por verificação para
## não recalcular a mesma contagem dezenas de vezes.
func _retrato() -> Dictionary:
	var adventure_id := GameState.active_adventure
	var maior_qtd := 0
	var profetas := 0
	var destravados := 0
	for gen_id in GameState.geradores:
		var estado: Dictionary = GameState.geradores[gen_id]
		var qtd := int(estado.get("qtd", 0))
		if qtd > 0:
			destravados += 1
		if bool(estado.get("tem_profeta", false)):
			profetas += 1
		if Geradores.get_adventure_for_id(int(gen_id)) == adventure_id:
			maior_qtd = maxi(maior_qtd, qtd)
	var marcos := 0
	for adventure_key in GameState.marcos_ledger:
		marcos += (GameState.marcos_ledger[adventure_key] as Array).size()
	var provacoes_total := 0
	var provacoes_distintas := 0
	for provacao_key in (GameState.provacoes.get("concluidas", {}) as Dictionary):
		var vezes := int((GameState.provacoes.concluidas as Dictionary)[provacao_key])
		provacoes_total += vezes
		if vezes > 0:
			provacoes_distintas += 1
	var estudo := StudySystem.get_progress_summary()
	return {
		"qualquer_gen_qtd": maior_qtd,
		"min_qtd": Economy.marco_min_qtd(adventure_id),
		"geradores_destravados": destravados,
		"profetas": profetas,
		"bencaos": GameState.upgrades_comprados.size(),
		"prestiges": int(GameState.estatisticas.get("prestiges", 0)),
		"santos_total": GameState.santos + GameState.santos_gastos,
		"frutos": GameState.dadiva_frutos_nivel,
		"ascensoes": int(GameState.alianca.get("ascensoes", 0)),
		"nos_alianca": (GameState.alianca.get("nos", []) as Array).size(),
		"aventuras_desbloqueadas": GameState.aventuras_desbloqueadas.size(),
		"aventuras_concluidas": GameState.aventuras_concluidas.size(),
		"marcos_gerais": marcos,
		"estudos_dominados": int(estudo.get("mastered", 0)),
		"capitulos_lidos": StudySystem.get_read_chapter_count(),
		"conhecimentos": GameState.conhecimentos_comprados.size(),
		"sabedoria_total": GameState.sabedoria_total,
		"devocional_total": int(GameState.devocional.get("totalLidos", 0)),
		"devocional_sequencia": int(GameState.devocional.get("melhorSequencia", 0)),
		"planos_devocional": (GameState.devocional.get("planosConcluidos", []) as Array).size(),
		"destaques": (GameState.devocional.get("destaques", []) as Array).size(),
		"notas": (GameState.devocional.get("notas", {}) as Dictionary).size(),
		"provacoes_concluidas": provacoes_total,
		"provacoes_distintas": provacoes_distintas,
		"cosmeticos": GameState.cosmeticos_comprados.size(),
		"metas_cumpridas": metas_cumpridas(),
		"tempo_jogado": int(GameState.estatisticas.get("tempo_jogado", 0.0)),
	}


## Desbloqueia tudo que já foi merecido. Chamada nos pontos de mudança de estado
## (compra, prestige, marco, devocional), não a cada tick.
func verificar() -> Array[String]:
	var novas: Array[String] = []
	if GameState.conquistas.size() >= DADOS.size():
		return novas
	var retrato := _retrato()
	for d in DADOS:
		var achievement_id := str(d.id)
		if achievement_id in GameState.conquistas:
			continue
		var tipo := str(d.tipo)
		var alvo := float(d.alvo)
		# "nos_alianca" com alvo 99 significa a arvore inteira, sem numero fixo.
		if tipo == "nos_alianca" and int(d.alvo) >= 99:
			alvo = float(AliancaSystem.total_nos())
		if float(retrato.get(tipo, 0)) < alvo:
			continue
		GameState.conquistas.append(achievement_id)
		novas.append(achievement_id)
		EventBus.achievement_unlocked.emit(achievement_id)
		EventBus.toast_requested.emit("Conquista: " + str(d.nome))
	if not novas.is_empty():
		Economy.recompute_multiplicadores()
		SaveSystem.save_game()
	return novas


func progresso(achievement_id: String) -> Dictionary:
	var d := get_data(achievement_id)
	if d.is_empty():
		return {}
	var retrato := _retrato()
	var alvo := float(d.alvo)
	if str(d.tipo) == "nos_alianca" and int(d.alvo) >= 99:
		alvo = float(AliancaSystem.total_nos())
	var atual := float(retrato.get(str(d.tipo), 0))
	return {
		"id": achievement_id,
		"atual": atual,
		"alvo": alvo,
		"fracao": clampf(atual / maxf(alvo, 1.0), 0.0, 1.0),
		"desbloqueada": desbloqueada(achievement_id),
	}


func por_categoria() -> Dictionary:
	var grupos: Dictionary = {}
	for d in DADOS:
		var cat := str(d.cat)
		if not grupos.has(cat):
			grupos[cat] = []
		(grupos[cat] as Array).append(d)
	return grupos

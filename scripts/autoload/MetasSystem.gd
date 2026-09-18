extends Node

## Metas diárias: três objetivos por dia, sorteados de forma determinística.
##
## O sorteio vem do próprio número do dia, não de RandomNumberGenerator: assim o
## mesmo jogador vê as mesmas metas em qualquer aparelho, funciona offline e não
## é possível reembaralhar fechando o app.
##
## As metas existem para dar à sessão um motivo de presença — hoje o jogador abre,
## compra o que dá e fecha. Cada meta é curta, mensurável com o estado que já
## existe, e paga pouco: gemas e Relíquias em quantidade pequena.

const METAS_POR_DIA: int = 3

const DADOS: Array = [
	{"id": "m_unidades_50", "nome": "Mãos à obra", "desc": "Compre 50 unidades de geradores.", "tipo": "unidades", "alvo": 50.0, "gemas": 2, "reliquias": 3},
	{"id": "m_unidades_200", "nome": "Construtor", "desc": "Compre 200 unidades de geradores.", "tipo": "unidades", "alvo": 200.0, "gemas": 3, "reliquias": 5},
	{"id": "m_ciclos_25", "nome": "Ofício manual", "desc": "Conclua 25 ciclos iniciados por toque.", "tipo": "ciclos_manuais", "alvo": 25.0, "gemas": 2, "reliquias": 3},
	{"id": "m_ciclos_100", "nome": "Sem pressa", "desc": "Conclua 100 ciclos iniciados por toque.", "tipo": "ciclos_manuais", "alvo": 100.0, "gemas": 3, "reliquias": 6},
	{"id": "m_profeta_1", "nome": "Novo chamado", "desc": "Contrate um profeta.", "tipo": "profetas", "alvo": 1.0, "gemas": 3, "reliquias": 4},
	{"id": "m_bencaos_5", "nome": "Favor recebido", "desc": "Compre 5 bênçãos.", "tipo": "bencaos", "alvo": 5.0, "gemas": 2, "reliquias": 3},
	{"id": "m_bencaos_20", "nome": "Mordomia", "desc": "Compre 20 bênçãos.", "tipo": "bencaos", "alvo": 20.0, "gemas": 3, "reliquias": 5},
	{"id": "m_marco_1", "nome": "Nenhum atrás", "desc": "Alcance um marco geral.", "tipo": "marcos", "alvo": 1.0, "gemas": 5, "reliquias": 8},
	{"id": "m_quiz_1", "nome": "Lição do dia", "desc": "Acerte a questão de um estudo.", "tipo": "quiz", "alvo": 1.0, "gemas": 3, "reliquias": 4},
	{"id": "m_capitulo_1", "nome": "Um capítulo", "desc": "Leia um capítulo da Bíblia.", "tipo": "capitulos", "alvo": 1.0, "gemas": 3, "reliquias": 4},
	{"id": "m_devocional", "nome": "Devocional", "desc": "Conclua a leitura devocional de hoje.", "tipo": "devocional", "alvo": 1.0, "gemas": 4, "reliquias": 6},
	{"id": "m_prestige_1", "nome": "Ressurreição", "desc": "Faça uma Ressurreição.", "tipo": "prestiges", "alvo": 1.0, "gemas": 4, "reliquias": 6},
	{"id": "m_boost_1", "nome": "Impulso", "desc": "Ative um impulso.", "tipo": "boosts", "alvo": 1.0, "gemas": 2, "reliquias": 3},
	{"id": "m_estrela_1", "nome": "Estrela Nova", "desc": "Recolha uma Estrela Nova.", "tipo": "estrelas", "alvo": 1.0, "gemas": 3, "reliquias": 4},
	{"id": "m_destaque_1", "nome": "Sublinhar", "desc": "Destaque um versículo.", "tipo": "destaques", "alvo": 1.0, "gemas": 2, "reliquias": 3},
]

var _by_id: Dictionary = {}


func _ready() -> void:
	for d in DADOS:
		_by_id[str(d.id)] = d
	EventBus.generator_cycle_complete.connect(_on_ciclo_completo)
	EventBus.prophet_changed.connect(func(_gen_id: int): registrar("profetas", 1.0))
	EventBus.upgrade_purchased.connect(func(_id: String): registrar("bencaos", 1.0))
	EventBus.upgrades_batch_purchased.connect(
		func(ids: Array): registrar("bencaos", float(ids.size()))
	)
	EventBus.marco_geral_reached.connect(
		func(_adventure_id: String, _quantity: int): registrar("marcos", 1.0)
	)
	EventBus.prestige_done.connect(func(): registrar("prestiges", 1.0))
	EventBus.boosts_changed.connect(func(): pass)  # impulsos registram no uso explicito


func existe(meta_id: String) -> bool:
	return _by_id.has(meta_id)


func get_data(meta_id: String) -> Dictionary:
	return _by_id.get(meta_id, {})


# ------------------------------------------------------------------ Sorteio

## Três metas distintas escolhidas a partir do número do dia. O passo coprimo com
## o tamanho da lista garante variedade entre dias vizinhos.
func metas_do_dia(dia: int) -> Array[String]:
	var total := DADOS.size()
	var escolhidas: Array[String] = []
	if total <= 0:
		return escolhidas
	var passo := 7
	while passo > 1 and _mdc(passo, total) != 1:
		passo += 1
	for i in range(mini(METAS_POR_DIA, total)):
		var indice := posmod(dia * METAS_POR_DIA + i * passo, total)
		var id := str((DADOS[indice] as Dictionary).id)
		# Colisão só acontece se a lista for muito curta; avança até achar livre.
		var tentativas := 0
		while id in escolhidas and tentativas < total:
			indice = posmod(indice + 1, total)
			id = str((DADOS[indice] as Dictionary).id)
			tentativas += 1
		escolhidas.append(id)
	return escolhidas


func _mdc(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


## Garante que o estado salvo corresponde ao dia de hoje. Chamada na abertura do
## app e antes de qualquer registro de progresso.
func garantir_dia() -> bool:
	var hoje := DevocionalSystem.dia_de_hoje()
	var e := GameState.metas_diarias
	if int(e.get("dia", -1)) == hoje and not (e.get("metas", []) as Array).is_empty():
		return false
	e.dia = hoje
	e.metas = metas_do_dia(hoje)
	e.progresso = {}
	e.resgatadas = []
	GameState.metas_diarias = e
	EventBus.meta_diaria_changed.emit()
	return true


func metas_ativas() -> Array:
	garantir_dia()
	return GameState.metas_diarias.get("metas", [])


func progresso_de(meta_id: String) -> float:
	return float((GameState.metas_diarias.get("progresso", {}) as Dictionary).get(meta_id, 0.0))


func concluida(meta_id: String) -> bool:
	var d := get_data(meta_id)
	return not d.is_empty() and progresso_de(meta_id) >= float(d.alvo)


func resgatada(meta_id: String) -> bool:
	return meta_id in (GameState.metas_diarias.get("resgatadas", []) as Array)


func total_cumpridas() -> int:
	return maxi(0, int(GameState.metas_diarias.get("totalCumpridas", 0)))


# ---------------------------------------------------------------- Progresso

func _on_ciclo_completo(gen_id: int, _receita: float) -> void:
	var estado: Dictionary = GameState.geradores.get(gen_id, {})
	# Ciclo de gerador sem profeta é o ciclo que o jogador iniciou por toque.
	if not bool(estado.get("tem_profeta", false)):
		registrar("ciclos_manuais", 1.0)


## Soma progresso em todas as metas de hoje daquele tipo. Não salva a cada ponto:
## o save acontece no resgate e nos outros pontos normais do jogo.
func registrar(tipo: String, quantidade: float) -> void:
	if quantidade <= 0.0:
		return
	garantir_dia()
	var e := GameState.metas_diarias
	var progresso: Dictionary = e.get("progresso", {})
	var mudou := false
	for meta_id: Variant in (e.get("metas", []) as Array):
		var d := get_data(str(meta_id))
		if d.is_empty() or str(d.tipo) != tipo:
			continue
		var antes := float(progresso.get(meta_id, 0.0))
		if antes >= float(d.alvo):
			continue
		progresso[meta_id] = minf(antes + quantidade, float(d.alvo))
		mudou = true
		if float(progresso[meta_id]) >= float(d.alvo):
			EventBus.toast_requested.emit("Meta cumprida: " + str(d.nome))
	if mudou:
		e.progresso = progresso
		GameState.metas_diarias = e
		EventBus.meta_diaria_changed.emit()


func resgatar(meta_id: String) -> Dictionary:
	if not concluida(meta_id) or resgatada(meta_id):
		return {"ok": false}
	var d := get_data(meta_id)
	var e := GameState.metas_diarias
	var resgatadas: Array = e.get("resgatadas", [])
	resgatadas.append(meta_id)
	e.resgatadas = resgatadas
	e.totalCumpridas = total_cumpridas() + 1
	GameState.metas_diarias = e
	var gemas := LiveOps.scale_free_gem_reward(int(d.gemas))
	if gemas > 0:
		GameState.add_gemas(gemas, "meta diária")
	var reliquias := int(d.reliquias)
	if reliquias > 0:
		GameState.reliquias += reliquias
		EventBus.relics_changed.emit(GameState.reliquias)
	Conquistas.verificar()
	EventBus.meta_diaria_changed.emit()
	SaveSystem.save_game()
	return {"ok": true, "gemas": gemas, "reliquias": reliquias}


func resgatar_todas() -> Dictionary:
	var gemas := 0
	var reliquias := 0
	var total := 0
	for meta_id: Variant in metas_ativas().duplicate():
		var resultado := resgatar(str(meta_id))
		if bool(resultado.get("ok", false)):
			gemas += int(resultado.gemas)
			reliquias += int(resultado.reliquias)
			total += 1
	return {"count": total, "gemas": gemas, "reliquias": reliquias}


func pendentes_para_resgate() -> int:
	var total := 0
	for meta_id: Variant in metas_ativas():
		if concluida(str(meta_id)) and not resgatada(str(meta_id)):
			total += 1
	return total


func resumo() -> Array:
	var lista: Array = []
	for meta_id: Variant in metas_ativas():
		var d := get_data(str(meta_id))
		if d.is_empty():
			continue
		lista.append({
			"id": str(meta_id),
			"nome": str(d.nome),
			"desc": str(d.desc),
			"atual": progresso_de(str(meta_id)),
			"alvo": float(d.alvo),
			"fracao": clampf(progresso_de(str(meta_id)) / maxf(float(d.alvo), 1.0), 0.0, 1.0),
			"concluida": concluida(str(meta_id)),
			"resgatada": resgatada(str(meta_id)),
			"gemas": int(d.gemas),
			"reliquias": int(d.reliquias),
		})
	return lista

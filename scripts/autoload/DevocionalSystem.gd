extends Node

## Devocional diário: plano de leitura, sequência de dias e o Selo do Dia.
##
## O devocional é o loop diário do jogo e o lugar onde o acervo bíblico offline
## deixa de ser conteúdo de consulta e passa a ser motivo de retorno. Concluir a
## leitura do dia concede o Selo do Dia — um bônus de produção global de 24 h que
## cresce com a sequência — mais a moeda da campanha ativa e, a cada três dias,
## um ponto de Sabedoria (a única fonte repetível de Sabedoria do jogo).
##
## Regras de tempo: o dia é o dia LOCAL do jogador, calculado sobre o relógio
## ajustado pelo Worker quando existe (LiveOps.server_adjusted_now), o que evita
## que mudar o relógio do aparelho renda vários selos. Sem rede, o relógio local
## é usado e o devocional continua funcionando offline.

const SELO_BASE: float = 0.10
const SELO_POR_DIA: float = 0.05
const SELO_MAX: float = 0.50
const SELO_DURACAO_SEGUNDOS: float = 24.0 * 3600.0
const SEGUNDOS_DE_PRODUCAO: float = 300.0
const RECOMPENSA_MINIMA: float = 10.0
const DIAS_POR_SABEDORIA: int = 3
const MAX_DESTAQUES: int = 128
const MAX_NOTAS: int = 30
const MAX_NOTA_CARACTERES: int = 180

## Marcos de sequência pagos uma vez cada, comparados contra a melhor sequência
## já alcançada. Não há ledger: a própria melhor sequência é o recibo, então não
## existe forma de repetir o pagamento quebrando e refazendo a série.
const MARCOS_SEQUENCIA: Array = [
	{"dias": 3, "gemas": 3, "reliquias": 0},
	{"dias": 7, "gemas": 8, "reliquias": 10},
	{"dias": 14, "gemas": 12, "reliquias": 15},
	{"dias": 30, "gemas": 25, "reliquias": 40},
	{"dias": 60, "gemas": 40, "reliquias": 75},
	{"dias": 100, "gemas": 75, "reliquias": 150},
]

const RECOMPENSA_PLANO_CONCLUIDO: Dictionary = {"gemas": 20, "reliquias": 30}


func _ready() -> void:
	EventBus.devocional_changed.connect(func(): pass)  # mantém o sinal vivo para a UI


# ------------------------------------------------------------------ Calendário

## Dia local como número inteiro de dias desde a época Unix. O deslocamento de
## fuso vem do sistema; em UTC-3 o dia vira à meia-noite local, não às 21 h.
func dia_de_hoje() -> int:
	return dia_de(agora())


func dia_de(timestamp: float) -> int:
	return floori((timestamp + _deslocamento_fuso_segundos()) / 86400.0)


func agora() -> float:
	var ajustado := LiveOps.server_adjusted_now()
	return ajustado if ajustado > 0.0 else Time.get_unix_time_from_system()


func _deslocamento_fuso_segundos() -> float:
	var fuso: Dictionary = Time.get_time_zone_from_system()
	return float(fuso.get("bias", 0)) * 60.0


func segundos_ate_amanha() -> int:
	var limite := float(dia_de_hoje() + 1) * 86400.0 - _deslocamento_fuso_segundos()
	return maxi(0, ceili(limite - agora()))


# --------------------------------------------------------------------- Estado

func estado() -> Dictionary:
	return GameState.devocional


func plano_atual() -> String:
	var plano_id := str(estado().get("planoId", Devocional.PLANO_PADRAO))
	return plano_id if Devocional.exists(plano_id) else Devocional.PLANO_PADRAO


func escolher_plano(plano_id: String) -> bool:
	if not Devocional.exists(plano_id) or plano_id == plano_atual():
		return false
	var e := estado()
	e.planoId = plano_id
	e.dia = 0
	# A sequência é do hábito, não do plano: trocar de plano não pune o jogador.
	GameState.devocional = e
	EventBus.devocional_changed.emit()
	SaveSystem.save_game()
	return true


func ja_leu_hoje() -> bool:
	return int(estado().get("ultimoDiaLido", -1)) == dia_de_hoje()


## Leitura de hoje: a entrada do plano somada ao texto bíblico do acervo offline.
func leitura_de_hoje() -> Dictionary:
	var plano_id := plano_atual()
	var e := estado()
	var entrada := Devocional.entrada(plano_id, int(e.get("dia", 0)), dia_de_hoje())
	if entrada.is_empty():
		return {}
	var passagem := BibleTextProvider.get_passage(
		str(entrada.book), int(entrada.chapter), int(entrada.verse_from), int(entrada.verse_to)
	)
	var total_dias := Devocional.dias(plano_id)
	return {
		"plano_id": plano_id,
		"plano": Devocional.resumo(plano_id),
		"dia_indice": int(e.get("dia", 0)),
		"dia_numero": int(e.get("dia", 0)) + 1,
		"total_dias": total_dias,
		"perpetuo": total_dias <= 0,
		"titulo": str(entrada.titulo),
		"reflexao": str(entrada.get("reflexao", "")),
		"oracao": str(entrada.get("oracao", "")),
		"aplicacao": str(entrada.get("aplicacao", "")),
		"referencia": str(passagem.get("reference", "")),
		"versos": passagem.get("verses", []),
		"book": str(entrada.book),
		"chapter": int(entrada.chapter),
		"concluida": ja_leu_hoje(),
	}


# ------------------------------------------------------------ Selo e sequência

## Teto do Selo. O no "Selo Firme" da Alianca eleva o maximo; a base e o passo
## por dia continuam os mesmos, entao o selo cresce mais longe, nao mais rapido.
func selo_maximo() -> float:
	return SELO_MAX + AliancaSystem.bonus_selo_extra()


func selo_bonus_para_sequencia(sequencia: int) -> float:
	return clampf(SELO_BASE + float(maxi(sequencia, 1) - 1) * SELO_POR_DIA, SELO_BASE, selo_maximo())


func selo_ativo() -> bool:
	return selo_segundos_restantes() > 0


func selo_segundos_restantes() -> int:
	return maxi(0, ceili(float(estado().get("seloExpiraEm", 0.0)) - agora()))


func selo_bonus_vigente() -> float:
	return float(estado().get("seloBonus", 0.0)) if selo_ativo() else 0.0


## Multiplicador aplicado à produção global enquanto o Selo estiver válido.
func selo_multiplicador() -> float:
	return 1.0 + selo_bonus_vigente()


func selo_expira_em() -> float:
	return float(estado().get("seloExpiraEm", 0.0))


func sequencia() -> int:
	return int(estado().get("sequencia", 0))


func melhor_sequencia() -> int:
	return int(estado().get("melhorSequencia", 0))


## A sequência é considerada viva se a última leitura foi hoje ou ontem. Com dois
## dias de intervalo ela ainda sobrevive perdendo um degrau (perdão de um dia).
func sequencia_em_risco() -> bool:
	var ultimo := int(estado().get("ultimoDiaLido", -1))
	return ultimo >= 0 and dia_de_hoje() - ultimo == 1


func proximo_marco_sequencia() -> Dictionary:
	var melhor := melhor_sequencia()
	for marco_value: Variant in MARCOS_SEQUENCIA:
		var marco: Dictionary = marco_value as Dictionary
		if melhor < int(marco.dias):
			return marco.duplicate()
	return {}


# -------------------------------------------------------------------- Concluir

## Conclui a leitura do dia. Idempotente: a segunda chamada no mesmo dia devolve
## ok=false sem pagar nada, como as recompensas de Estudo.
func concluir_leitura() -> Dictionary:
	if ja_leu_hoje():
		return {"ok": false, "motivo": "ja_concluida"}
	var leitura := leitura_de_hoje()
	if leitura.is_empty():
		return {"ok": false, "motivo": "sem_conteudo"}

	var e := estado()
	var hoje := dia_de_hoje()
	var ultimo := int(e.get("ultimoDiaLido", -1))
	var nova_sequencia := 1
	var perdoado := false
	if ultimo >= 0:
		var intervalo := hoje - ultimo
		if intervalo == 1:
			nova_sequencia = int(e.get("sequencia", 0)) + 1
		elif intervalo == 2:
			# Perdão de um dia: perde um degrau em vez da série inteira.
			nova_sequencia = maxi(1, int(e.get("sequencia", 0)) - 1)
			perdoado = true
	e.ultimoDiaLido = hoje
	e.sequencia = nova_sequencia
	e.melhorSequencia = maxi(int(e.get("melhorSequencia", 0)), nova_sequencia)
	e.totalLidos = int(e.get("totalLidos", 0)) + 1

	var bonus := selo_bonus_para_sequencia(nova_sequencia)
	e.seloBonus = bonus
	e.seloExpiraEm = agora() + SELO_DURACAO_SEGUNDOS

	# Avanço no plano. Plano perpétuo não tem fim; plano finito marca conclusão.
	var plano_id := str(leitura.plano_id)
	var total_dias := int(leitura.total_dias)
	var plano_concluido := false
	if total_dias > 0:
		var proximo := int(e.get("dia", 0)) + 1
		if proximo >= total_dias:
			var concluidos: Array = e.get("planosConcluidos", [])
			if plano_id not in concluidos:
				concluidos.append(plano_id)
				plano_concluido = true
			e.planosConcluidos = concluidos
			e.dia = total_dias - 1
		else:
			e.dia = proximo
	GameState.devocional = e

	# Moeda da campanha ativa: alguns minutos de produção, com piso para quem
	# ainda não tem renda automática no começo do jogo.
	var currency := str(GameState.ADVENTURES[GameState.active_adventure].generator_currency)
	var ganho := maxf(
		Economy.receita_total_por_segundo(GameState.active_adventure) * SEGUNDOS_DE_PRODUCAO,
		RECOMPENSA_MINIMA
	)
	GameState.add_currency(currency, ganho)

	var sabedoria_ganha := 0
	if int(e.totalLidos) % DIAS_POR_SABEDORIA == 0:
		sabedoria_ganha = maxi(1, int(round(AliancaSystem.multiplicador_sabedoria())))
		GameState.sabedoria += sabedoria_ganha
		GameState.sabedoria_total += sabedoria_ganha
		EventBus.wisdom_changed.emit(GameState.sabedoria)

	var gemas_ganhas := 0
	var reliquias_ganhas := 0
	for marco_value: Variant in MARCOS_SEQUENCIA:
		var marco: Dictionary = marco_value as Dictionary
		# Paga ao cruzar o marco pela primeira vez: a melhor sequência é o recibo.
		if nova_sequencia == int(marco.dias) and int(e.melhorSequencia) == int(marco.dias):
			gemas_ganhas += LiveOps.scale_free_gem_reward(int(marco.gemas))
			reliquias_ganhas += int(marco.reliquias)
	if plano_concluido:
		gemas_ganhas += LiveOps.scale_free_gem_reward(int(RECOMPENSA_PLANO_CONCLUIDO.gemas))
		reliquias_ganhas += int(RECOMPENSA_PLANO_CONCLUIDO.reliquias)
	if gemas_ganhas > 0:
		GameState.add_gemas(gemas_ganhas, "devocional")
	if reliquias_ganhas > 0:
		GameState.reliquias += reliquias_ganhas
		EventBus.relics_changed.emit(GameState.reliquias)

	MetasSystem.registrar("devocional", 1.0)
	Conquistas.verificar()
	Economy.recompute_multiplicadores()
	EventBus.devocional_changed.emit()
	EventBus.devocional_selo_changed.emit()
	EventBus.toast_requested.emit(
		"Selo do Dia: produção +" + str(roundi(bonus * 100.0)) + "% por 24 h"
	)
	SaveSystem.save_game()
	return {
		"ok": true,
		"sequencia": nova_sequencia,
		"perdoado": perdoado,
		"selo_bonus": bonus,
		"currency": currency,
		"amount": ganho,
		"sabedoria": sabedoria_ganha,
		"gemas": gemas_ganhas,
		"reliquias": reliquias_ganhas,
		"plano_concluido": plano_concluido,
	}


# --------------------------------------------------------- Destaques e notas

static func referencia_de(book: String, chapter: int, verse: int) -> String:
	return "%s:%d:%d" % [book.to_upper(), chapter, verse]


func destaques() -> Array:
	return estado().get("destaques", [])


func tem_destaque(referencia: String) -> bool:
	return referencia in destaques()


func alternar_destaque(referencia: String) -> bool:
	if referencia.is_empty():
		return false
	var e := estado()
	var lista: Array = e.get("destaques", [])
	if referencia in lista:
		lista.erase(referencia)
	elif lista.size() >= MAX_DESTAQUES:
		EventBus.toast_requested.emit("Limite de " + str(MAX_DESTAQUES) + " destaques alcançado")
		return false
	else:
		lista.append(referencia)
	e.destaques = lista
	GameState.devocional = e
	MetasSystem.registrar("destaques", 1.0)
	Conquistas.verificar()
	EventBus.devocional_changed.emit()
	SaveSystem.save_game()
	return true


func nota(referencia: String) -> String:
	return str((estado().get("notas", {}) as Dictionary).get(referencia, ""))


func definir_nota(referencia: String, texto: String) -> Dictionary:
	if referencia.is_empty():
		return {"ok": false, "motivo": "referencia"}
	var e := estado()
	var notas: Dictionary = e.get("notas", {})
	var limpo := texto.strip_edges()
	if limpo.is_empty():
		notas.erase(referencia)
	else:
		if not notas.has(referencia) and notas.size() >= MAX_NOTAS:
			return {"ok": false, "motivo": "limite", "limite": MAX_NOTAS}
		notas[referencia] = limpo.substr(0, MAX_NOTA_CARACTERES)
	e.notas = notas
	GameState.devocional = e
	EventBus.devocional_changed.emit()
	SaveSystem.save_game()
	return {"ok": true, "total": notas.size()}


# ------------------------------------------------------------------ Lembrete

func hora_lembrete() -> int:
	return int(estado().get("horaLembrete", -1))


func definir_hora_lembrete(hora: int) -> void:
	var e := estado()
	e.horaLembrete = clampi(hora, -1, 23)
	GameState.devocional = e
	EventBus.devocional_changed.emit()
	Notificacoes.reagendar_lembrete_devocional()
	SaveSystem.save_game()


# -------------------------------------------------------------------- Resumo

func resumo() -> Dictionary:
	var e := estado()
	return {
		"plano_id": plano_atual(),
		"sequencia": sequencia(),
		"melhor_sequencia": melhor_sequencia(),
		"total_lidos": int(e.get("totalLidos", 0)),
		"leu_hoje": ja_leu_hoje(),
		"selo_ativo": selo_ativo(),
		"selo_bonus": selo_bonus_vigente(),
		"selo_restante": selo_segundos_restantes(),
		"proximo_marco": proximo_marco_sequencia(),
		"destaques": destaques().size(),
		"notas": (e.get("notas", {}) as Dictionary).size(),
		"planos_concluidos": (e.get("planosConcluidos", []) as Array).duplicate(),
		"hora_lembrete": hora_lembrete(),
	}

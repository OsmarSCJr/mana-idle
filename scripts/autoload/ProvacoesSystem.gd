extends Node

## Provações: corridas com modificadores, liberadas pela primeira Aliança.
##
## Uma Provação começa como uma Ressurreição sem recompensa (a run da campanha
## ativa zera) e aplica modificadores até o objetivo ser alcançado. Concluir paga
## Relíquias, gemas e um bônus permanente pequeno — repetível, com recompensa
## decrescente a cada repetição, para que repetir seja opção e não obrigação.
##
## É conteúdo de semanas construído sobre a economia que já existe: os
## modificadores entram em Economy.recompute_multiplicadores() e nos pontos de
## compra, sem sistema de combate nem conteúdo novo de arte.

const MULTIPLICADOR_REPETICAO: float = 0.5
const MINIMO_RECOMPENSA: float = 0.1

const DADOS: Array = [
	{
		"id": "p_deserto", "nome": "Deserto", "ordem": 1,
		"descricao": "Quarenta dias sem automação: nenhum profeta pode ser contratado.",
		"objetivo_qtd": 100,
		"mods": {"sem_profetas": true},
		"reliquias": 40, "gemas": 10,
		"bonus_tipo": "manual_mult", "bonus_valor": 1.5,
		"bonus_texto": "Toque manual ×1.5, para sempre",
		"flavor": "No deserto se aprende de que se vive.",
	},
	{
		"id": "p_cativeiro", "nome": "Cativeiro", "ordem": 2,
		"descricao": "O tempo se arrasta: todos os ciclos duram três vezes mais.",
		"objetivo_qtd": 150,
		"mods": {"tempo_mult": 3.0},
		"reliquias": 50, "gemas": 12,
		"bonus_tipo": "global_speed", "bonus_valor": 0.95,
		"bonus_texto": "Ciclos 5% mais rápidos, para sempre",
		"flavor": "Junto aos rios da Babilônia.",
	},
	{
		"id": "p_sarepta", "nome": "Viúva de Sarepta", "ordem": 3,
		"descricao": "Só os geradores de posição ímpar produzem.",
		"objetivo_qtd": 200,
		"mods": {"somente_impares": true},
		"reliquias": 60, "gemas": 15,
		"bonus_tipo": "global_prod", "bonus_valor": 1.10,
		"bonus_texto": "+10% produção global, para sempre",
		"flavor": "O punhado de farinha não acabou.",
	},
	{
		"id": "p_jejum", "nome": "Jejum", "ordem": 4,
		"descricao": "Sem impulsos e sem Estrela Nova durante toda a Provação.",
		"objetivo_qtd": 250,
		"mods": {"sem_boosts": true},
		"reliquias": 75, "gemas": 18,
		"bonus_tipo": "boost_duration", "bonus_valor": 1.25,
		"bonus_texto": "Impulsos duram 25% mais, para sempre",
		"flavor": "Não só de pão vive o homem.",
	},
	{
		"id": "p_viuva_duas_moedas", "nome": "Duas Moedas", "ordem": 5,
		"descricao": "Tudo custa o dobro. A oferta pequena é a que conta.",
		"objetivo_qtd": 300,
		"mods": {"custo_mult": 2.0},
		"reliquias": 90, "gemas": 22,
		"bonus_tipo": "discount", "bonus_valor": 0.95,
		"bonus_texto": "−5% custo de todos os geradores, para sempre",
		"flavor": "Ela deu tudo o que tinha.",
	},
	{
		"id": "p_fornalha", "nome": "Fornalha", "ordem": 6,
		"descricao": "Sem automação, custo dobrado e ciclos dobrados. A prova final.",
		"objetivo_qtd": 300,
		"mods": {"sem_profetas": true, "custo_mult": 2.0, "tempo_mult": 2.0},
		"reliquias": 150, "gemas": 40,
		"bonus_tipo": "global_prod", "bonus_valor": 1.25,
		"bonus_texto": "+25% produção global, para sempre",
		"flavor": "E não havia nem cheiro de fogo neles.",
	},
]

var _by_id: Dictionary = {}


func _ready() -> void:
	for d in DADOS:
		_by_id[str(d.id)] = d


func existe(provacao_id: String) -> bool:
	return _by_id.has(provacao_id)


func get_data(provacao_id: String) -> Dictionary:
	return _by_id.get(provacao_id, {})


func liberadas() -> bool:
	return AliancaSystem.ascensoes() > 0


func ativa_id() -> String:
	return str(GameState.provacoes.get("ativa", ""))


func ativa() -> Dictionary:
	return get_data(ativa_id())


func em_andamento() -> bool:
	return not ativa_id().is_empty()


func vezes_concluida(provacao_id: String) -> int:
	return int((GameState.provacoes.get("concluidas", {}) as Dictionary).get(provacao_id, 0))


func total_concluidas() -> int:
	var total := 0
	for chave in (GameState.provacoes.get("concluidas", {}) as Dictionary):
		total += int((GameState.provacoes.concluidas as Dictionary)[chave])
	return total


# ------------------------------------------------------------ Modificadores

func mods_ativos() -> Dictionary:
	return (ativa().get("mods", {}) as Dictionary).duplicate()


func sem_profetas() -> bool:
	return bool(mods_ativos().get("sem_profetas", false))


func sem_boosts() -> bool:
	return bool(mods_ativos().get("sem_boosts", false))


func multiplicador_tempo() -> float:
	return maxf(float(mods_ativos().get("tempo_mult", 1.0)), 0.01)


func multiplicador_custo() -> float:
	return maxf(float(mods_ativos().get("custo_mult", 1.0)), 0.01)


## Geradores silenciados pelo modificador "somente_impares". A posição é relativa
## à campanha, então a Provação vale igual nas três.
func gerador_silenciado(gen_id: int) -> bool:
	if not bool(mods_ativos().get("somente_impares", false)):
		return false
	var adventure_id := Geradores.get_adventure_for_id(gen_id)
	var primeiro := int(GameState.ADVENTURES.get(adventure_id, {}).get("first_generator", 1))
	return (gen_id - primeiro) % 2 == 1


# ------------------------------------------------------- Iniciar e concluir

func pode_iniciar(provacao_id: String) -> bool:
	return liberadas() and not em_andamento() and existe(provacao_id)


func iniciar(provacao_id: String) -> Dictionary:
	if not pode_iniciar(provacao_id):
		return {"ok": false, "motivo": "bloqueada"}
	var p := get_data(provacao_id)
	var e := GameState.provacoes
	e.ativa = provacao_id
	e.iniciadaEm = DevocionalSystem.agora()
	GameState.provacoes = e
	# A run da campanha ativa recomeça: a Provação é uma corrida limpa.
	GameState.reset_run_para_provacao()
	Economy.recompute_multiplicadores()
	EventBus.provacao_changed.emit()
	EventBus.toast_requested.emit("Provação iniciada: " + str(p.nome))
	SaveSystem.save_game()
	return {"ok": true, "provacao": provacao_id}


func abandonar() -> bool:
	if not em_andamento():
		return false
	var nome := str(ativa().get("nome", ""))
	var e := GameState.provacoes
	e.ativa = ""
	e.iniciadaEm = 0.0
	GameState.provacoes = e
	GameState.reset_run_para_provacao()
	Economy.recompute_multiplicadores()
	EventBus.provacao_changed.emit()
	EventBus.toast_requested.emit("Provação abandonada: " + nome)
	SaveSystem.save_game()
	return true


func objetivo_atual() -> int:
	return int(ativa().get("objetivo_qtd", 0))


func progresso() -> Dictionary:
	if not em_andamento():
		return {}
	var alvo := objetivo_atual()
	var atual := Economy.marco_min_qtd(GameState.active_adventure)
	return {
		"id": ativa_id(),
		"nome": str(ativa().get("nome", "")),
		"atual": atual,
		"alvo": alvo,
		"fracao": clampf(float(atual) / maxf(float(alvo), 1.0), 0.0, 1.0),
		"concluivel": atual >= alvo,
	}


## Chamado quando um marco geral avança. Concluir é automático: chegar ao objetivo
## É a conclusão, sem botão extra para o jogador esquecer de apertar.
func verificar_conclusao() -> Dictionary:
	if not em_andamento():
		return {}
	var alvo := objetivo_atual()
	if Economy.marco_min_qtd(GameState.active_adventure) < alvo:
		return {}
	var provacao_id := ativa_id()
	var p := get_data(provacao_id)
	var vezes := vezes_concluida(provacao_id)
	var fator := maxf(pow(MULTIPLICADOR_REPETICAO, float(vezes)), MINIMO_RECOMPENSA)
	var reliquias := maxi(1, int(round(float(p.reliquias) * fator)))
	var gemas := LiveOps.scale_free_gem_reward(maxi(0, int(round(float(p.gemas) * fator))))

	var e := GameState.provacoes
	var concluidas: Dictionary = e.get("concluidas", {})
	concluidas[provacao_id] = vezes + 1
	e.concluidas = concluidas
	e.ativa = ""
	e.iniciadaEm = 0.0
	GameState.provacoes = e

	GameState.reliquias += reliquias
	EventBus.relics_changed.emit(GameState.reliquias)
	if gemas > 0:
		GameState.add_gemas(gemas, "Provação")
	Economy.recompute_multiplicadores()
	Conquistas.verificar()
	EventBus.provacao_changed.emit()
	EventBus.toast_requested.emit(
		"Provação concluída: " + str(p.nome) + "  ·  +" + str(reliquias) + " Relíquias"
	)
	SaveSystem.save_game()
	return {
		"ok": true,
		"provacao": provacao_id,
		"vezes": vezes + 1,
		"reliquias": reliquias,
		"gemas": gemas,
		"bonus_texto": str(p.bonus_texto),
	}


# --------------------------------------------- Bônus permanentes conquistados

## Cada Provação concluída ao menos uma vez concede seu bônus permanente. Repetir
## não empilha o bônus: repetir paga Relíquias, não poder.
func bonus_permanentes() -> Array:
	var lista: Array = []
	for d in DADOS:
		if vezes_concluida(str(d.id)) > 0:
			lista.append({"tipo": str(d.bonus_tipo), "valor": float(d.bonus_valor), "texto": str(d.bonus_texto)})
	return lista


func bonus_permanente(tipo: String, padrao: float = 1.0) -> float:
	var acumulado := padrao
	for bonus_value: Variant in bonus_permanentes():
		var bonus: Dictionary = bonus_value as Dictionary
		if str(bonus.tipo) == tipo:
			acumulado *= float(bonus.valor)
	return acumulado


func resumo() -> Dictionary:
	var lista: Array = []
	for d in DADOS:
		lista.append({
			"id": str(d.id),
			"nome": str(d.nome),
			"descricao": str(d.descricao),
			"objetivo_qtd": int(d.objetivo_qtd),
			"vezes": vezes_concluida(str(d.id)),
			"bonus_texto": str(d.bonus_texto),
			"flavor": str(d.flavor),
			"ativa": str(d.id) == ativa_id(),
		})
	return {
		"liberadas": liberadas(),
		"ativa": ativa_id(),
		"progresso": progresso(),
		"total_concluidas": total_concluidas(),
		"lista": lista,
	}

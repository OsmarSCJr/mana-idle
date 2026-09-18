extends Node

## Cobertura das camadas do V3: devocional, metas diárias, conquistas, Aliança e
## Provações, mais o roundtrip do save v11 e a validação do payload.
##
## O tempo é injetado por LiveOps.smoke_apply/_test_now_override, então a
## sequência de dias é testada sem esperar 24 h e sem mexer no relógio do sistema.

const SEGUNDOS_POR_DIA: float = 86400.0


func _ready() -> void:
	SaveSystem.set_persistence_enabled(false)
	await get_tree().process_frame
	var ok := true

	GameState._reset_alpha_progress()

	# ---------------------------------------------------------------- Devocional
	# V0) A leitura de hoje vem do plano padrão com texto bíblico real do acervo
	# offline, e o catálogo inteiro resolve passagem (nenhuma referência quebrada).
	var leitura := DevocionalSystem.leitura_de_hoje()
	var catalogo_ok := true
	var referencias_quebradas: Array[String] = []
	for plano_id in Devocional.plano_ids():
		var total := Devocional.dias(str(plano_id))
		var dias := total if total > 0 else DevocionalPalavra.PASSAGENS.size()
		for dia in range(dias):
			var entrada := Devocional.entrada(str(plano_id), dia, dia)
			var passagem := BibleTextProvider.get_passage(
				str(entrada.book), int(entrada.chapter), int(entrada.verse_from), int(entrada.verse_to)
			)
			if passagem.is_empty() or (passagem.get("verses", []) as Array).is_empty():
				catalogo_ok = false
				referencias_quebradas.append("%s d%d %s %d:%d" % [
					plano_id, dia + 1, entrada.book, entrada.chapter, entrada.verse_from
				])
	print("[V0] catalogo devocional resolve passagem=", catalogo_ok,
		" quebradas=", referencias_quebradas.slice(0, 5))
	ok = ok and catalogo_ok and not leitura.is_empty() \
		and not (leitura.versos as Array).is_empty()

	# V1) Concluir paga Selo, moeda e é idempotente no mesmo dia.
	var global_antes := Economy.get_multiplicador_global_base()
	var primeiro := DevocionalSystem.concluir_leitura()
	var global_depois := Economy.get_multiplicador_global_base()
	var repetido := DevocionalSystem.concluir_leitura()
	var selo_esperado := DevocionalSystem.SELO_BASE
	# Concluir também desbloqueia conquistas, que multiplicam o global: a checagem
	# é pelo multiplicador do selo e por um piso de crescimento, não por igualdade.
	var devocional_ok := bool(primeiro.get("ok", false)) \
		and not bool(repetido.get("ok", true)) \
		and DevocionalSystem.sequencia() == 1 \
		and is_equal_approx(float(primeiro.selo_bonus), selo_esperado) \
		and is_equal_approx(DevocionalSystem.selo_multiplicador(), 1.0 + selo_esperado) \
		and global_depois >= global_antes * (1.0 + selo_esperado) - 0.0001 \
		and float(primeiro.amount) >= DevocionalSystem.RECOMPENSA_MINIMA
	print("[V1] selo do dia=", devocional_ok, " bonus=", primeiro.get("selo_bonus", 0.0),
		" global ", global_antes, " -> ", global_depois)
	ok = ok and devocional_ok

	# V2) Sequência cresce em dias consecutivos e o Selo sobe 5 pontos por dia.
	var base_now := DevocionalSystem.agora()
	_avancar_dias(base_now, 1)
	DevocionalSystem.concluir_leitura()
	_avancar_dias(base_now, 2)
	var terceiro := DevocionalSystem.concluir_leitura()
	var crescimento_ok := DevocionalSystem.sequencia() == 3 \
		and is_equal_approx(
			float(terceiro.selo_bonus),
			DevocionalSystem.SELO_BASE + 2.0 * DevocionalSystem.SELO_POR_DIA
		)
	print("[V2] sequencia cresce=", crescimento_ok, " sequencia=", DevocionalSystem.sequencia(),
		" bonus=", terceiro.get("selo_bonus", 0.0))
	ok = ok and crescimento_ok

	# V3) Perdão de um dia: faltar um dia perde um degrau, não a série. Faltar dois
	# reinicia em 1.
	_avancar_dias(base_now, 4)
	var perdoado := DevocionalSystem.concluir_leitura()
	var perdao_ok := bool(perdoado.get("perdoado", false)) and DevocionalSystem.sequencia() == 2
	_avancar_dias(base_now, 10)
	var reiniciado := DevocionalSystem.concluir_leitura()
	var reinicio_ok := not bool(reiniciado.get("perdoado", true)) and DevocionalSystem.sequencia() == 1
	print("[V3] perdao de um dia=", perdao_ok, " reinicio apos dois=", reinicio_ok,
		" recorde=", DevocionalSystem.melhor_sequencia())
	ok = ok and perdao_ok and reinicio_ok and DevocionalSystem.melhor_sequencia() == 3

	# V4) Selo vence: expirado, a produção volta ao valor sem selo.
	_avancar_dias(base_now, 12)
	var sem_selo := not DevocionalSystem.selo_ativo() \
		and is_equal_approx(DevocionalSystem.selo_multiplicador(), 1.0)
	print("[V4] selo expira sozinho=", sem_selo, " restante=", DevocionalSystem.selo_segundos_restantes())
	ok = ok and sem_selo

	# V5) Destaques e notas respeitam os tetos e sobrevivem ao roundtrip.
	var referencia := DevocionalSystem.referencia_de("GEN", 1, 1)
	DevocionalSystem.alternar_destaque(referencia)
	DevocionalSystem.definir_nota(referencia, "Primeira anotação do teste.")
	var nota_longa := ""
	for _i in range(400):
		nota_longa += "x"
	DevocionalSystem.definir_nota(DevocionalSystem.referencia_de("GEN", 1, 2), nota_longa)
	var marcadores_ok := DevocionalSystem.tem_destaque(referencia) \
		and DevocionalSystem.nota(referencia) == "Primeira anotação do teste." \
		and DevocionalSystem.nota(DevocionalSystem.referencia_de("GEN", 1, 2)).length() \
			== DevocionalSystem.MAX_NOTA_CARACTERES
	print("[V5] destaques e notas=", marcadores_ok)
	ok = ok and marcadores_ok

	# --------------------------------------------------------------------- Metas
	# V6) Três metas por dia, determinísticas e estáveis para o mesmo dia.
	MetasSystem.garantir_dia()
	var metas_hoje := MetasSystem.metas_do_dia(20_000)
	var metas_iguais := MetasSystem.metas_do_dia(20_000)
	var metas_outro_dia := MetasSystem.metas_do_dia(20_001)
	var metas_ok := metas_hoje.size() == MetasSystem.METAS_POR_DIA \
		and metas_hoje == metas_iguais \
		and metas_hoje != metas_outro_dia \
		and MetasSystem.metas_ativas().size() == MetasSystem.METAS_POR_DIA
	print("[V6] metas deterministicas=", metas_ok, " hoje=", metas_hoje)
	ok = ok and metas_ok

	# V7) Progresso avança pelo tipo, o resgate é único e conta na conquista.
	GameState.metas_diarias.metas = ["m_unidades_50"]
	GameState.metas_diarias.progresso = {}
	GameState.metas_diarias.resgatadas = []
	GameState.fe = 1.0e9
	GameState.buy_generator(1, 60)
	var resgate := MetasSystem.resgatar("m_unidades_50")
	var resgate_repetido := MetasSystem.resgatar("m_unidades_50")
	var resgate_ok := MetasSystem.concluida("m_unidades_50") \
		and bool(resgate.get("ok", false)) \
		and not bool(resgate_repetido.get("ok", true)) \
		and MetasSystem.total_cumpridas() == 1
	print("[V7] meta progride e resgata uma vez=", resgate_ok,
		" progresso=", MetasSystem.progresso_de("m_unidades_50"))
	ok = ok and resgate_ok

	# ---------------------------------------------------------------- Conquistas
	# V8) Conquistas de abertura entram e o bônus global cresce com teto.
	Conquistas.verificar()
	var bonus := Conquistas.bonus_total()
	var conquistas_ok := Conquistas.desbloqueada("c_primeira_luz") \
		and Conquistas.desbloqueada("c_dez_unidades") \
		and bonus > 0.0 and bonus <= Conquistas.BONUS_MAXIMO \
		and is_equal_approx(Conquistas.multiplicador(), 1.0 + bonus)
	print("[V8] conquistas somam bonus=", conquistas_ok,
		" desbloqueadas=", Conquistas.desbloqueadas(), "/", Conquistas.total(),
		" bonus=", bonus)
	ok = ok and conquistas_ok

	# V9) Toda conquista declara um tipo que o avaliador conhece.
	var tipos_ok := true
	var tipos_desconhecidos: Array[String] = []
	var retrato: Dictionary = Conquistas._retrato()
	for d in Conquistas.DADOS:
		if not retrato.has(str((d as Dictionary).tipo)):
			tipos_ok = false
			tipos_desconhecidos.append(str((d as Dictionary).tipo))
	print("[V9] tipos de conquista conhecidos=", tipos_ok, " desconhecidos=", tipos_desconhecidos)
	ok = ok and tipos_ok

	# ------------------------------------------------------------------- Aliança
	# V10) Bloqueada sem troféu; o troféu de campanha a libera.
	var bloqueada_ok := not AliancaSystem.liberada() and not AliancaSystem.pode_ascender() \
		and not ProvacoesSystem.liberadas()
	GameState.marcos_ledger["jornada"] = [Geradores.META_UNIDADES]
	var liberada_ok := AliancaSystem.liberada() and AliancaSystem.pode_ascender()
	print("[V10] alianca bloqueada sem trofeu=", bloqueada_ok, " liberada com trofeu=", liberada_ok)
	ok = ok and bloqueada_ok and liberada_ok

	# V11) Ascender zera a economia das três campanhas e preserva o resto.
	GameState.santos = 800
	GameState.santos_gastos = 0
	GameState.reliquias = 123
	GameState.sabedoria = 7
	GameState.buy_dadiva("d_evangelismo")
	GameState.graca = 5000.0
	var conquistas_antes := GameState.conquistas.size()
	var sequencia_antes := DevocionalSystem.melhor_sequencia()
	var ascensao := AliancaSystem.ascender()
	var ascensao_ok := bool(ascensao.get("ok", false)) \
		and int(ascensao.ganhas) >= 1 \
		and GameState.santos == 0 \
		and GameState.santos_gastos == 0 \
		and GameState.dadivas_compradas.is_empty() \
		and GameState.dadiva_frutos_nivel == 0 \
		and GameState.upgrades_comprados.is_empty() \
		and int(GameState.geradores[1].qtd) == 0 \
		and is_equal_approx(GameState.fe, GameState.FE_INICIAL) \
		and GameState.reliquias == 123 \
		and GameState.sabedoria == 7 \
		and GameState.conquistas.size() >= conquistas_antes \
		and DevocionalSystem.melhor_sequencia() == sequencia_antes \
		and AliancaSystem.ascensoes() == 1 \
		and ProvacoesSystem.liberadas()
	print("[V11] ascensao zera economia e preserva coleção=", ascensao_ok,
		" aliancas=", AliancaSystem.saldo())
	ok = ok and ascensao_ok

	# V12) Nós respeitam requisito, custo e aplicam efeito.
	# Concede Alianças mexendo em saldo E total: o validador recusa saldo acima
	# do total ganho, e o teste precisa produzir um save legítimo.
	GameState.alianca.saldo = int(GameState.alianca.saldo) + 3
	GameState.alianca.total = int(GameState.alianca.total) + 3
	var sem_requisito := AliancaSystem.comprar("a_primeiro_chamado")
	var global_no_antes := Economy.get_multiplicador_global_base()
	var comprou_raiz := AliancaSystem.comprar("a_alicerce")
	var global_no_depois := Economy.get_multiplicador_global_base()
	var com_requisito := AliancaSystem.pode_comprar("a_primeiro_chamado")
	var nos_ok := not sem_requisito and comprou_raiz and com_requisito \
		and is_equal_approx(global_no_depois, global_no_antes * 2.0) \
		and AliancaSystem.tem_no("a_alicerce")
	print("[V12] nos da alianca=", nos_ok, " global ", global_no_antes, " -> ", global_no_depois)
	ok = ok and nos_ok

	# ----------------------------------------------------------------- Provações
	# V13) Modificadores valem enquanto a Provação corre.
	var tempo_normal := Economy.get_tempo_ciclo(1)
	var custo_normal := Economy.custo_unitario(1, 0)
	ProvacoesSystem.iniciar("p_cativeiro")
	var tempo_provacao := Economy.get_tempo_ciclo(1)
	ProvacoesSystem.abandonar()
	ProvacoesSystem.iniciar("p_viuva_duas_moedas")
	var custo_provacao := Economy.custo_unitario(1, 0)
	ProvacoesSystem.abandonar()
	ProvacoesSystem.iniciar("p_deserto")
	GameState.fe = 1.0e12
	GameState.buy_generator(1, 30)
	var profeta_bloqueado := not GameState.buy_prophet(1)
	var mods_ok := is_equal_approx(tempo_provacao, tempo_normal * 3.0) \
		and is_equal_approx(custo_provacao, custo_normal * 2.0) \
		and profeta_bloqueado \
		and not Economy.profeta_disponivel(1)
	print("[V13] modificadores de provacao=", mods_ok,
		" tempo ", tempo_normal, " -> ", tempo_provacao,
		" custo ", custo_normal, " -> ", custo_provacao)
	ok = ok and mods_ok

	# V14) Chegar ao objetivo conclui a Provação, paga e dá o bônus permanente.
	var reliquias_antes := GameState.reliquias
	var objetivo := ProvacoesSystem.objetivo_atual()
	GameState.fe = 1.0e120
	for gen_id in range(1, 13):
		GameState.buy_generator(gen_id, objetivo)
	var manual_apos := Economy.get_manual_knowledge_multiplier()
	var conclusao_ok := not ProvacoesSystem.em_andamento() \
		and ProvacoesSystem.vezes_concluida("p_deserto") == 1 \
		and GameState.reliquias > reliquias_antes \
		and manual_apos > 1.0
	print("[V14] provacao conclui no objetivo=", conclusao_ok,
		" reliquias ", reliquias_antes, " -> ", GameState.reliquias,
		" manual=", manual_apos)
	ok = ok and conclusao_ok

	# V15) Repetir paga menos, e o bônus permanente não empilha.
	ProvacoesSystem.iniciar("p_deserto")
	var reliquias_repeticao_antes := GameState.reliquias
	var manual_antes_repeticao := Economy.get_manual_knowledge_multiplier()
	GameState.fe = 1.0e120
	for gen_id in range(1, 13):
		GameState.buy_generator(gen_id, ProvacoesSystem.objetivo_atual())
	var ganho_repeticao := GameState.reliquias - reliquias_repeticao_antes
	var repeticao_ok := ProvacoesSystem.vezes_concluida("p_deserto") == 2 \
		and ganho_repeticao > 0 \
		and ganho_repeticao < 40 \
		and is_equal_approx(Economy.get_manual_knowledge_multiplier(), manual_antes_repeticao)
	print("[V15] repeticao paga menos e nao empilha bonus=", repeticao_ok,
		" ganho=", ganho_repeticao)
	ok = ok and repeticao_ok

	# ------------------------------------------------------- Conhecimentos/slots
	# V16) Conhecimento ativo tem limite de espaços, ampliado pela Aliança.
	GameState.conhecimentos_comprados = []
	GameState.conhecimentos_ativos = []
	GameState.sabedoria = 500
	var comprados: Array[String] = []
	for knowledge_variant in Conhecimentos.all():
		var knowledge_id := str((knowledge_variant as Dictionary).get("id", ""))
		if StudySystem.can_purchase_knowledge(knowledge_id):
			StudySystem.buy_knowledge(knowledge_id)
			comprados.append(knowledge_id)
		if comprados.size() >= 8:
			break
	var base_slots := StudySystem.SLOTS_CONHECIMENTO_BASE
	var slots_ok := StudySystem.slots_conhecimento() == base_slots \
		and GameState.conhecimentos_ativos.size() <= base_slots \
		and StudySystem.slots_conhecimento_livres() == 0
	GameState.alianca.saldo = int(GameState.alianca.saldo) + 99
	GameState.alianca.total = int(GameState.alianca.total) + 99
	AliancaSystem.comprar("a_entendimento")
	AliancaSystem.comprar("a_slots")
	slots_ok = slots_ok and StudySystem.slots_conhecimento() == base_slots + 3
	print("[V16] limite de conhecimentos ativos=", slots_ok,
		" ativos=", GameState.conhecimentos_ativos.size(), "/", StudySystem.slots_conhecimento())
	ok = ok and slots_ok

	# --------------------------------------------------------------------- Save
	# V17) Roundtrip do save v11 preserva as cinco camadas.
	var save := GameState.get_save_data()
	var save_version_ok := int(save.version) == 11
	GameState._reset_alpha_progress()
	GameState.load_save_data(save)
	var roundtrip_ok := save_version_ok \
		and DevocionalSystem.melhor_sequencia() == sequencia_antes \
		and DevocionalSystem.tem_destaque(referencia) \
		and GameState.conquistas.size() > 0 \
		and AliancaSystem.ascensoes() == 1 \
		and AliancaSystem.tem_no("a_alicerce") \
		and ProvacoesSystem.vezes_concluida("p_deserto") == 2 \
		and MetasSystem.total_cumpridas() >= 1
	print("[V17] roundtrip save v11=", roundtrip_ok, " version=", save.version)
	ok = ok and roundtrip_ok

	# V18) O validador aceita o save real e recusa camadas adulteradas.
	var valido: Dictionary = CloudSaveValidator.validate_save_data(save, true)
	var no_falso := save.duplicate(true)
	(no_falso.alianca as Dictionary).nos = ["a_no_inexistente"]
	var conquista_falsa := save.duplicate(true)
	(conquista_falsa.conquistas as Array).append("c_conquista_inexistente")
	var selo_absurdo := save.duplicate(true)
	(selo_absurdo.devocional as Dictionary).seloBonus = 99.0
	var saldo_inflado := save.duplicate(true)
	(saldo_inflado.alianca as Dictionary).saldo = 9999
	var validador_ok := bool(valido.get("ok", false)) \
		and not bool(CloudSaveValidator.validate_save_data(no_falso, true).get("ok", true)) \
		and not bool(CloudSaveValidator.validate_save_data(conquista_falsa, true).get("ok", true)) \
		and not bool(CloudSaveValidator.validate_save_data(selo_absurdo, true).get("ok", true)) \
		and not bool(CloudSaveValidator.validate_save_data(saldo_inflado, true).get("ok", true))
	print("[V18] validador aceita real e recusa adulterado=", validador_ok,
		" erro real=", valido.get("code", ""))
	ok = ok and validador_ok

	# V19) O save cabe no limite de 64 KiB com as camadas cheias.
	var bytes := CloudSaveValidator.compact_json(save).to_utf8_buffer().size()
	var tamanho_ok := bytes < CloudSaveValidator.MAX_PAYLOAD_BYTES
	print("[V19] tamanho do save=", bytes, " bytes (limite ",
		CloudSaveValidator.MAX_PAYLOAD_BYTES, ")=", tamanho_ok)
	ok = ok and tamanho_ok

	# V20) Notificações decidem horário mesmo sem o plugin nativo instalado.
	# Usa a hora local seguinte, que ainda não ocorreu hoje: assim "pular hoje"
	# tem efeito observável e o teste não depende da hora em que roda.
	var agora_local := DevocionalSystem.agora() + float(Time.get_time_zone_from_system().get("bias", 0)) * 60.0
	var hora_seguinte := (int(floorf(fposmod(agora_local, 86400.0) / 3600.0)) + 1) % 24
	DevocionalSystem.definir_hora_lembrete(hora_seguinte)
	var atraso := Notificacoes.segundos_ate_hora_local(hora_seguinte, false)
	var atraso_pulando := Notificacoes.segundos_ate_hora_local(hora_seguinte, true)
	var lembrete_ok := DevocionalSystem.hora_lembrete() == hora_seguinte \
		and atraso > 0 and atraso <= 3600 \
		and atraso_pulando == atraso + 86_400 \
		and Notificacoes.segundos_ate_hora_local(0, false) > 0
	DevocionalSystem.definir_hora_lembrete(-1)
	print("[V20] agendamento de lembrete=", lembrete_ok, " hora=", hora_seguinte,
		" atraso=", atraso, " pulando=", atraso_pulando,
		" plugin nativo=", Notificacoes.disponivel())
	ok = ok and lembrete_ok and DevocionalSystem.hora_lembrete() == -1

	print("=== V3 SMOKE TEST ", ("PASS" if ok else "FAIL"), " ===")
	get_tree().quit(0 if ok else 1)


## Avança o relógio ajustado pelo Worker em N dias, sem tocar o relógio do sistema.
func _avancar_dias(base_now: float, dias: int) -> void:
	var envelope := LiveOps.summary()
	LiveOps.smoke_apply(
		{
			"schemaVersion": LiveOps.SCHEMA_VERSION,
			"revision": int(envelope.get("revision", 0)),
			"versionId": str(envelope.get("versionId", "smoke")),
			"publishedAt": 0,
			"serverNow": base_now + float(dias) * SEGUNDOS_POR_DIA,
			"config": LiveOps.DEFAULT_CONFIG.duplicate(true),
			"campaigns": [],
		},
		base_now + float(dias) * SEGUNDOS_POR_DIA
	)

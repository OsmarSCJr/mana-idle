class_name ProgressoPanel
extends VBoxContainer

## Camadas permanentes: Aliança, Provações e Conquistas.
##
## Vive dentro da aba SANTOS, que passa a ser a aba de progresso permanente. As
## regras ficam em AliancaSystem, ProvacoesSystem e Conquistas; aqui só a
## apresentação, o envio de ações e a explicação do que cada reset preserva —
## Ascensão e Provação apagam progresso, e o jogador precisa ler isso antes.

const SECTION_ALIANCA := "alianca"
const SECTION_PROVACOES := "provacoes"
const SECTION_CONQUISTAS := "conquistas"

const CATEGORIA_NOMES: Dictionary = {
	"jornada": "Jornada",
	"profetas": "Profetas",
	"bencaos": "Bênçãos",
	"prestigio": "Ressurreição",
	"alianca": "Aliança",
	"campanhas": "Campanhas",
	"estudo": "Estudo",
	"devocional": "Devocional",
	"provacoes": "Provações",
	"colecao": "Coleção",
}

var _built := false
var _active_section := SECTION_ALIANCA

var _tab_buttons: Dictionary = {}
var _content_host: VBoxContainer
var _alianca_view: VBoxContainer
var _provacoes_view: VBoxContainer
var _conquistas_view: VBoxContainer

var _alianca_header: Label
var _alianca_detalhe: Label
var _alianca_button: Button
var _alianca_nos_host: VBoxContainer
var _provacoes_header: Label
var _provacoes_host: VBoxContainer
var _conquistas_header: Label
var _conquistas_bar: ProgressBar
var _conquistas_host: VBoxContainer


func _ready() -> void:
	_ensure_built()
	EventBus.alianca_changed.connect(_on_state_changed)
	EventBus.provacao_changed.connect(_on_state_changed)
	EventBus.achievement_unlocked.connect(func(_id: String): _on_state_changed())
	refresh()


func _on_state_changed() -> void:
	if is_visible_in_tree():
		refresh()


func show_section(section: String) -> void:
	_active_section = section
	_ensure_built()
	_apply_section()
	refresh()


func refresh() -> void:
	_ensure_built()
	_refresh_alianca()
	_refresh_provacoes()
	_refresh_conquistas()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_constant_override("separation", 12)
	add_child(_build_section_tabs())
	_content_host = VBoxContainer.new()
	_content_host.add_theme_constant_override("separation", 0)
	_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_content_host)
	_alianca_view = _build_scroll_view(_build_alianca())
	_provacoes_view = _build_scroll_view(_build_provacoes())
	_conquistas_view = _build_scroll_view(_build_conquistas())
	_apply_section()


## Este painel vive DENTRO do scroll da aba SANTOS, então não cria scroll próprio:
## ScrollContainer dentro de ScrollContainer, os dois com expansão vertical, faz o
## layout do Godot oscilar sem convergir. Aqui a seção só cresce e o scroll de fora
## cuida do resto.
func _build_scroll_view(content: Control) -> VBoxContainer:
	var host := VBoxContainer.new()
	host.add_theme_constant_override("separation", 12)
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(content)
	_content_host.add_child(host)
	return host


func _apply_section() -> void:
	if _alianca_view == null:
		return
	_alianca_view.visible = _active_section == SECTION_ALIANCA
	_provacoes_view.visible = _active_section == SECTION_PROVACOES
	_conquistas_view.visible = _active_section == SECTION_CONQUISTAS
	for key in _tab_buttons:
		var button: Button = _tab_buttons[key]
		var ativo: bool = key == _active_section
		button.add_theme_stylebox_override(
			"normal",
			ManaTheme.button_style(
				ManaTheme.SILVER if ativo else ManaTheme.SURFACE_HIGH,
				ManaTheme.CREAM if ativo else ManaTheme.OUTLINE,
				14, 2, 16, 10
			)
		)
		button.add_theme_color_override("font_color", ManaTheme.INK if ativo else ManaTheme.CREAM_MUTED)


func _build_section_tabs() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE_LOW, 16, ManaTheme.OUTLINE, 1, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	for item in [
		[SECTION_ALIANCA, "ALIANÇA"], [SECTION_PROVACOES, "PROVAÇÕES"], [SECTION_CONQUISTAS, "CONQUISTAS"],
	]:
		var button := Button.new()
		button.text = str(item[1])
		button.custom_minimum_size = Vector2(0, 62)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 19)
		button.pressed.connect(show_section.bind(str(item[0])))
		_tab_buttons[str(item[0])] = button
		row.add_child(button)
	return panel


# --------------------------------------------------------------------- Aliança

func _build_alianca() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(ManaTheme.SURFACE, 20, ManaTheme.SILVER, 2, 22, true)
	)
	column.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	card.add_child(inner)

	_alianca_header = Label.new()
	_alianca_header.add_theme_font_override("font", ManaTheme.serif_bold())
	_alianca_header.add_theme_font_size_override("font_size", 34)
	_alianca_header.add_theme_color_override("font_color", ManaTheme.SILVER)
	inner.add_child(_alianca_header)

	_alianca_detalhe = Label.new()
	_alianca_detalhe.add_theme_font_size_override("font_size", 20)
	_alianca_detalhe.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	_alianca_detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(_alianca_detalhe)

	_alianca_button = Button.new()
	_alianca_button.custom_minimum_size = Vector2(0, 88)
	_alianca_button.add_theme_font_size_override("font_size", 24)
	ManaTheme.apply_primary_button(_alianca_button)
	_alianca_button.pressed.connect(_confirmar_ascensao)
	inner.add_child(_alianca_button)

	_alianca_nos_host = VBoxContainer.new()
	_alianca_nos_host.add_theme_constant_override("separation", 10)
	column.add_child(_alianca_nos_host)
	return column


func _refresh_alianca() -> void:
	var resumo := AliancaSystem.resumo()
	if not bool(resumo.liberada):
		_alianca_header.text = "Aliança — bloqueada"
		_alianca_detalhe.text = (
			"A Aliança abre quando você conquista o troféu de uma campanha: todos os "
			+ "%d geradores dela em %d unidades. " % [12, Geradores.META_UNIDADES]
			+ "É a camada acima da Ressurreição, e o que sustenta o jogo depois do troféu."
		)
		_alianca_button.text = "CONQUISTE UM TROFÉU DE CAMPANHA"
		_alianca_button.disabled = true
	else:
		_alianca_header.text = "Aliança  ·  %d disponível%s" % [
			int(resumo.saldo), "" if int(resumo.saldo) == 1 else "is"
		]
		_alianca_detalhe.text = (
			"Ascensões: %d  ·  total ganho: %d  ·  nós: %d de %d\n" % [
				int(resumo.ascensoes), int(resumo.total), int(resumo.nos), int(resumo.nos_total)
			]
			+ "Santos somados nas três campanhas: %d." % int(resumo.santos_totais)
		)
		_alianca_button.text = "ASCENDER  ·  +%d ALIANÇA%s" % [
			int(resumo.proximas), "" if int(resumo.proximas) == 1 else "S"
		]
		_alianca_button.disabled = not AliancaSystem.pode_ascender()
	_rebuild_nos()


func _rebuild_nos() -> void:
	for child in _alianca_nos_host.get_children():
		child.queue_free()
	for no in AliancaSystem.NOS:
		_alianca_nos_host.add_child(_build_no_card(no as Dictionary))


func _build_no_card(no: Dictionary) -> PanelContainer:
	var node_id := str(no.id)
	var comprado := AliancaSystem.tem_no(node_id)
	var disponivel := AliancaSystem.requisitos_atendidos(node_id)
	var card := PanelContainer.new()
	var fundo := ManaTheme.SURFACE_HIGH if comprado else (ManaTheme.SURFACE if disponivel else ManaTheme.SURFACE_LOW)
	var borda := ManaTheme.GREEN if comprado else (ManaTheme.SILVER if disponivel else ManaTheme.OUTLINE)
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(fundo, 18, borda, 2 if comprado or disponivel else 1, 20))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)

	var titulo := Label.new()
	titulo.text = "%s  ·  %d %s" % [
		str(no.nome), int(no.custo), "Aliança" if int(no.custo) == 1 else "Alianças"
	]
	titulo.add_theme_font_override("font", ManaTheme.body_semibold())
	titulo.add_theme_font_size_override("font_size", 25)
	titulo.add_theme_color_override("font_color", ManaTheme.CREAM if disponivel or comprado else ManaTheme.DISABLED)
	column.add_child(titulo)

	var efeito := Label.new()
	efeito.text = str(no.efeito)
	efeito.add_theme_font_size_override("font_size", 20)
	efeito.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT if disponivel or comprado else ManaTheme.DISABLED)
	efeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(efeito)

	var flavor := Label.new()
	flavor.text = str(no.flavor)
	flavor.add_theme_font_override("font", ManaTheme.SERIF_ITALIC_FONT)
	flavor.add_theme_font_size_override("font_size", 17)
	flavor.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(flavor)

	if comprado:
		var selo := Label.new()
		selo.text = "✓ ativo"
		selo.add_theme_font_size_override("font_size", 18)
		selo.add_theme_color_override("font_color", ManaTheme.GREEN)
		column.add_child(selo)
		return card

	if not disponivel:
		var requisitos: Array[String] = []
		for requerido in (no.get("requer", []) as Array):
			requisitos.append(str(AliancaSystem.no_data(str(requerido)).get("nome", requerido)))
		var bloqueio := Label.new()
		bloqueio.text = "Requer: " + ", ".join(requisitos)
		bloqueio.add_theme_font_size_override("font_size", 18)
		bloqueio.add_theme_color_override("font_color", ManaTheme.DISABLED)
		bloqueio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(bloqueio)
		return card

	var botao := Button.new()
	botao.text = "COMPRAR"
	botao.custom_minimum_size = Vector2(0, 66)
	botao.add_theme_font_size_override("font_size", 20)
	botao.disabled = not AliancaSystem.pode_comprar(node_id)
	if not botao.disabled:
		ManaTheme.apply_primary_button(botao)
	else:
		botao.text = "ALIANÇAS INSUFICIENTES"
	botao.pressed.connect(func():
		if AliancaSystem.comprar(node_id):
			refresh()
	)
	column.add_child(botao)
	return card


func _confirmar_ascensao() -> void:
	var ganhas := AliancaSystem.aliancas_ganhas()
	_confirmar(
		"Ascender?",
		"Você recebe %d Aliança%s.\n\n" % [ganhas, "" if ganhas == 1 else "s"]
		+ "ZERA: Santos, Dádivas, Frutos do Espírito, geradores, bênçãos e as moedas "
		+ "das três campanhas.\n\n"
		+ "PRESERVA: Relíquias, cosméticos, Conhecimentos, Sabedoria, conquistas, "
		+ "devocional, Provações e a árvore da Aliança.\n\n"
		+ "As campanhas continuam desbloqueadas.",
		"ASCENDER",
		func():
			AliancaSystem.ascender()
			refresh()
	)


# ------------------------------------------------------------------ Provações

func _build_provacoes() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE, 20, ManaTheme.OUTLINE, 1, 22))
	column.add_child(card)
	_provacoes_header = Label.new()
	_provacoes_header.add_theme_font_size_override("font_size", 21)
	_provacoes_header.add_theme_color_override("font_color", ManaTheme.CREAM)
	_provacoes_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(_provacoes_header)
	_provacoes_host = VBoxContainer.new()
	_provacoes_host.add_theme_constant_override("separation", 10)
	column.add_child(_provacoes_host)
	return column


func _refresh_provacoes() -> void:
	var resumo := ProvacoesSystem.resumo()
	if not bool(resumo.liberadas):
		_provacoes_header.text = (
			"As Provações abrem depois da sua primeira Ascensão. São corridas com "
			+ "modificadores: cada uma paga Relíquias e um bônus permanente pequeno, e "
			+ "pode ser repetida com recompensa decrescente."
		)
	elif ProvacoesSystem.em_andamento():
		var progresso: Dictionary = resumo.progresso
		_provacoes_header.text = "Em curso: %s  ·  gargalo em %d de %d unidades." % [
			str(progresso.nome), int(progresso.atual), int(progresso.alvo)
		]
	else:
		_provacoes_header.text = (
			"Nenhuma Provação em curso. Iniciar recomeça a run da campanha ativa "
			+ "(Santos e Dádivas ficam) e aplica os modificadores até o objetivo."
		)
	for child in _provacoes_host.get_children():
		child.queue_free()
	if not bool(resumo.liberadas):
		return
	for item_value: Variant in (resumo.lista as Array):
		_provacoes_host.add_child(_build_provacao_card(item_value as Dictionary))


func _build_provacao_card(item: Dictionary) -> PanelContainer:
	var provacao_id := str(item.id)
	var ativa := bool(item.ativa)
	var vezes := int(item.vezes)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel",
		ManaTheme.panel_style(
			ManaTheme.SURFACE_HIGH if ativa else ManaTheme.SURFACE,
			18, ManaTheme.GOLD if ativa else (ManaTheme.GREEN if vezes > 0 else ManaTheme.OUTLINE),
			2 if ativa or vezes > 0 else 1, 20
		)
	)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)

	var titulo := Label.new()
	titulo.text = str(item.nome) + ("  ·  EM CURSO" if ativa else ("  ·  %dx" % vezes if vezes > 0 else ""))
	titulo.add_theme_font_override("font", ManaTheme.serif_bold())
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", ManaTheme.CREAM)
	column.add_child(titulo)

	var descricao := Label.new()
	descricao.text = str(item.descricao)
	descricao.add_theme_font_size_override("font_size", 20)
	descricao.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(descricao)

	var objetivo := Label.new()
	objetivo.text = "Objetivo: todos os geradores da campanha em %d unidades." % int(item.objetivo_qtd)
	objetivo.add_theme_font_size_override("font_size", 19)
	objetivo.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(objetivo)

	var recompensa := Label.new()
	recompensa.text = "Recompensa permanente: " + str(item.bonus_texto) + (
		"  (já conquistada)" if vezes > 0 else ""
	)
	recompensa.add_theme_font_size_override("font_size", 19)
	recompensa.add_theme_color_override("font_color", ManaTheme.GREEN if vezes > 0 else ManaTheme.CREAM)
	recompensa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(recompensa)

	if ativa:
		var progresso := ProvacoesSystem.progresso()
		var barra := ProgressBar.new()
		barra.custom_minimum_size = Vector2(0, 16)
		barra.show_percentage = false
		barra.max_value = 1.0
		barra.value = float(progresso.get("fracao", 0.0))
		barra.add_theme_stylebox_override("background", ManaTheme.progress_style(ManaTheme.SURFACE_HIGH))
		barra.add_theme_stylebox_override("fill", ManaTheme.progress_style(ManaTheme.GOLD))
		column.add_child(barra)
		var abandonar := Button.new()
		abandonar.text = "ABANDONAR"
		abandonar.custom_minimum_size = Vector2(0, 66)
		abandonar.add_theme_font_size_override("font_size", 20)
		abandonar.pressed.connect(func():
			_confirmar(
				"Abandonar a Provação?",
				"A run da campanha ativa recomeça e nenhuma recompensa é paga. "
				+ "Santos, Dádivas e a árvore da Aliança ficam como estão.",
				"ABANDONAR",
				func():
					ProvacoesSystem.abandonar()
					refresh()
			)
		)
		column.add_child(abandonar)
		return card

	var iniciar := Button.new()
	iniciar.custom_minimum_size = Vector2(0, 66)
	iniciar.add_theme_font_size_override("font_size", 20)
	if ProvacoesSystem.em_andamento():
		iniciar.text = "OUTRA PROVAÇÃO EM CURSO"
		iniciar.disabled = true
	else:
		iniciar.text = "INICIAR"
		ManaTheme.apply_primary_button(iniciar)
		iniciar.pressed.connect(func():
			_confirmar(
				"Iniciar %s?" % str(item.nome),
				str(item.descricao) + "\n\n"
				+ "A run da campanha ativa recomeça: geradores e bênçãos zeram. "
				+ "Santos, Dádivas, Relíquias e a Aliança ficam.\n\n"
				+ "Objetivo: todos em %d unidades." % int(item.objetivo_qtd),
				"INICIAR",
				func():
					ProvacoesSystem.iniciar(provacao_id)
					refresh()
			)
		)
	column.add_child(iniciar)
	return card


# ----------------------------------------------------------------- Conquistas

func _build_conquistas() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE, 20, ManaTheme.OUTLINE, 1, 22))
	column.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)
	_conquistas_header = Label.new()
	_conquistas_header.add_theme_font_size_override("font_size", 21)
	_conquistas_header.add_theme_color_override("font_color", ManaTheme.CREAM)
	_conquistas_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(_conquistas_header)
	_conquistas_bar = ProgressBar.new()
	_conquistas_bar.custom_minimum_size = Vector2(0, 16)
	_conquistas_bar.show_percentage = false
	_conquistas_bar.max_value = 1.0
	_conquistas_bar.add_theme_stylebox_override("background", ManaTheme.progress_style(ManaTheme.SURFACE_HIGH))
	_conquistas_bar.add_theme_stylebox_override("fill", ManaTheme.progress_style(ManaTheme.GOLD))
	inner.add_child(_conquistas_bar)
	_conquistas_host = VBoxContainer.new()
	_conquistas_host.add_theme_constant_override("separation", 12)
	column.add_child(_conquistas_host)
	return column


func _refresh_conquistas() -> void:
	var desbloqueadas := Conquistas.desbloqueadas()
	var total := Conquistas.total()
	_conquistas_header.text = "%d de %d conquistas  ·  produção global +%d%% (teto +%d%%)" % [
		desbloqueadas, total,
		roundi(Conquistas.bonus_total() * 100.0),
		roundi(Conquistas.BONUS_MAXIMO * 100.0),
	]
	_conquistas_bar.value = clampf(float(desbloqueadas) / maxf(float(total), 1.0), 0.0, 1.0)
	for child in _conquistas_host.get_children():
		child.queue_free()
	var grupos := Conquistas.por_categoria()
	for categoria in grupos:
		var titulo := Label.new()
		titulo.text = str(CATEGORIA_NOMES.get(categoria, categoria)).to_upper()
		titulo.add_theme_font_override("font", ManaTheme.body_semibold())
		titulo.add_theme_font_size_override("font_size", 18)
		titulo.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
		_conquistas_host.add_child(titulo)
		for item_value: Variant in (grupos[categoria] as Array):
			_conquistas_host.add_child(_build_conquista_linha(item_value as Dictionary))


func _build_conquista_linha(item: Dictionary) -> PanelContainer:
	var achievement_id := str(item.id)
	var progresso := Conquistas.progresso(achievement_id)
	var feita := bool(progresso.get("desbloqueada", false))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel",
		ManaTheme.panel_style(
			ManaTheme.SURFACE_HIGH if feita else ManaTheme.SURFACE_LOW,
			14, ManaTheme.GREEN if feita else ManaTheme.OUTLINE, 1, 16
		)
	)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var titulo := Label.new()
	titulo.text = ("✓ " if feita else "") + str(item.nome) + "  ·  +%d%%" % roundi(
		Conquistas.bonus_de(achievement_id) * 100.0
	)
	titulo.add_theme_font_override("font", ManaTheme.body_semibold())
	titulo.add_theme_font_size_override("font_size", 21)
	titulo.add_theme_color_override("font_color", ManaTheme.GREEN if feita else ManaTheme.CREAM)
	column.add_child(titulo)
	var desc := Label.new()
	desc.text = str(item.desc)
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(desc)
	if not feita:
		var barra := ProgressBar.new()
		barra.custom_minimum_size = Vector2(0, 10)
		barra.show_percentage = false
		barra.max_value = 1.0
		barra.value = float(progresso.get("fracao", 0.0))
		barra.add_theme_stylebox_override("background", ManaTheme.progress_style(ManaTheme.SURFACE))
		barra.add_theme_stylebox_override("fill", ManaTheme.progress_style(ManaTheme.SILVER))
		column.add_child(barra)
		var contador := Label.new()
		contador.text = "%s de %s" % [
			NumberFormat.format(float(progresso.get("atual", 0.0))),
			NumberFormat.format(float(progresso.get("alvo", 1.0))),
		]
		contador.add_theme_font_size_override("font_size", 16)
		contador.add_theme_color_override("font_color", ManaTheme.DISABLED)
		column.add_child(contador)
	return card


# ------------------------------------------------------------------ Confirmação

## Diálogo obrigatório antes de qualquer reset. Ascensão e Provação apagam
## progresso: o jogador confirma lendo exatamente o que sai e o que fica.
func _confirmar(titulo: String, corpo: String, rotulo: String, acao: Callable) -> void:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(ManaTheme.SURFACE, 22, ManaTheme.GOLD_DARK, 2, 26)
	)
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	popup.add_child(column)
	var header := Label.new()
	header.text = titulo
	header.add_theme_font_override("font", ManaTheme.serif_bold())
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", ManaTheme.CREAM)
	column.add_child(header)
	var texto := Label.new()
	texto.text = corpo
	texto.add_theme_font_size_override("font_size", 20)
	texto.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(640, 0)
	column.add_child(texto)
	var acoes := HBoxContainer.new()
	acoes.add_theme_constant_override("separation", 12)
	column.add_child(acoes)
	var cancelar := Button.new()
	cancelar.text = "CANCELAR"
	cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancelar.custom_minimum_size = Vector2(0, 70)
	cancelar.pressed.connect(popup.hide)
	acoes.add_child(cancelar)
	var confirmar := Button.new()
	confirmar.text = rotulo
	confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirmar.custom_minimum_size = Vector2(0, 70)
	ManaTheme.apply_primary_button(confirmar)
	confirmar.pressed.connect(func():
		popup.hide()
		acao.call()
	)
	acoes.add_child(confirmar)
	popup.popup_centered()

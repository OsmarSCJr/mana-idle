class_name DevocionalPanel
extends VBoxContainer

## Aba Devocional: a leitura do dia, a sequência e as metas diárias.
##
## Toda a regra (dia local, sequência, Selo do Dia, recompensas) vive em
## DevocionalSystem e MetasSystem. Este painel apresenta o conteúdo, envia ações
## e reflete o estado — nunca concede recurso por conta própria.
##
## O versículo é a unidade de interação: tocar destaca, tocar e segurar abre a
## anotação. É o gesto que apps de devocional usam, e o que transforma o acervo
## bíblico offline em algo que o jogador marca como seu.

const SECTION_HOJE := "hoje"
const SECTION_PLANOS := "planos"
const SECTION_MARCADOS := "marcados"

var _built := false
var _refreshing := false
var _active_section := SECTION_HOJE
var _leitura: Dictionary = {}

var _tab_buttons: Dictionary = {}
var _content_host: Control
var _hoje_view: VBoxContainer
var _planos_view: VBoxContainer
var _marcados_view: VBoxContainer

var _sequencia_label: Label
var _selo_label: Label
var _selo_bar: ProgressBar
var _marco_label: Label
var _plano_label: Label
var _titulo_label: Label
var _referencia_label: Label
var _versos_host: VBoxContainer
var _reflexao_label: Label
var _oracao_card: PanelContainer
var _oracao_label: Label
var _aplicacao_card: PanelContainer
var _aplicacao_label: Label
var _concluir_button: Button
var _concluir_hint: Label
var _lembrete_button: Button
var _metas_host: VBoxContainer
var _metas_resgatar_button: Button
var _planos_host: VBoxContainer
var _marcados_host: VBoxContainer
var _nota_popup: PopupPanel
var _nota_edit: TextEdit
var _nota_referencia := ""


func _ready() -> void:
	_ensure_built()
	EventBus.devocional_changed.connect(_on_state_changed)
	EventBus.meta_diaria_changed.connect(_on_state_changed)
	EventBus.wisdom_changed.connect(func(_v: int): _on_state_changed())
	refresh()


func _on_state_changed() -> void:
	if is_visible_in_tree():
		refresh()


func show_section(section: String) -> void:
	_active_section = section
	_ensure_built()
	_apply_section()


func refresh() -> void:
	_ensure_built()
	if _refreshing:
		return
	_refreshing = true
	MetasSystem.garantir_dia()
	_leitura = DevocionalSystem.leitura_de_hoje()
	_refresh_header()
	_refresh_leitura()
	_refresh_metas()
	_refresh_planos()
	_refresh_marcados()
	_refreshing = false


# ------------------------------------------------------------------ Estrutura

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_constant_override("separation", 14)

	add_child(_build_header())
	add_child(_build_section_tabs())

	_content_host = Control.new()
	_content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content_host)

	_hoje_view = _build_scroll_view(_build_hoje())
	_planos_view = _build_scroll_view(_build_planos())
	_marcados_view = _build_scroll_view(_build_marcados())
	_apply_section()


func _build_scroll_view(content: Control) -> VBoxContainer:
	var host := VBoxContainer.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(content)
	scroll.add_child(list)
	host.add_child(scroll)
	ManaTheme.enable_touch_scroll(scroll, list)
	_content_host.add_child(host)
	return host


func _apply_section() -> void:
	if _hoje_view == null:
		return
	_hoje_view.visible = _active_section == SECTION_HOJE
	_planos_view.visible = _active_section == SECTION_PLANOS
	_marcados_view.visible = _active_section == SECTION_MARCADOS
	for key in _tab_buttons:
		var button: Button = _tab_buttons[key]
		var ativo: bool = key == _active_section
		button.add_theme_stylebox_override(
			"normal",
			ManaTheme.button_style(
				ManaTheme.GOLD if ativo else ManaTheme.SURFACE_HIGH,
				ManaTheme.GOLD_LIGHT if ativo else ManaTheme.OUTLINE,
				16, 2, 18, 12
			)
		)
		button.add_theme_color_override("font_color", ManaTheme.INK if ativo else ManaTheme.CREAM_MUTED)


func _build_section_tabs() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE_LOW, 18, ManaTheme.OUTLINE, 1, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for item in [[SECTION_HOJE, "HOJE"], [SECTION_PLANOS, "PLANOS"], [SECTION_MARCADOS, "MARCADOS"]]:
		var button := Button.new()
		button.text = str(item[1])
		button.custom_minimum_size = Vector2(0, 68)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(show_section.bind(str(item[0])))
		_tab_buttons[str(item[0])] = button
		row.add_child(button)
	return panel


# -------------------------------------------------------------------- Cabeçalho

func _build_header() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE, 20, ManaTheme.OUTLINE, 1, 22))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)

	_sequencia_label = Label.new()
	_sequencia_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_sequencia_label.add_theme_font_size_override("font_size", 34)
	_sequencia_label.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	_sequencia_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_sequencia_label)

	_lembrete_button = Button.new()
	_lembrete_button.custom_minimum_size = Vector2(0, 62)
	_lembrete_button.add_theme_font_size_override("font_size", 19)
	_lembrete_button.pressed.connect(_abrir_lembrete)
	row.add_child(_lembrete_button)

	_selo_label = Label.new()
	_selo_label.add_theme_font_size_override("font_size", 21)
	_selo_label.add_theme_color_override("font_color", ManaTheme.CREAM)
	_selo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_selo_label)

	_selo_bar = ProgressBar.new()
	_selo_bar.custom_minimum_size = Vector2(0, 18)
	_selo_bar.show_percentage = false
	_selo_bar.max_value = 1.0
	_selo_bar.add_theme_stylebox_override("background", ManaTheme.progress_style(ManaTheme.SURFACE_HIGH))
	column.add_child(_selo_bar)

	_marco_label = Label.new()
	_marco_label.add_theme_font_size_override("font_size", 18)
	_marco_label.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	_marco_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_marco_label)
	return panel


func _refresh_header() -> void:
	var resumo := DevocionalSystem.resumo()
	var sequencia := int(resumo.sequencia)
	_sequencia_label.text = (
		"Sequência: %d %s" % [sequencia, "dia" if sequencia == 1 else "dias"]
	)
	if bool(resumo.selo_ativo):
		_selo_label.text = "Selo do Dia ativo  ·  produção +%d%%  ·  %s restantes" % [
			roundi(float(resumo.selo_bonus) * 100.0),
			NumberFormat.format_time(float(resumo.selo_restante)),
		]
		_selo_bar.visible = true
		_selo_bar.value = clampf(
			float(resumo.selo_restante) / DevocionalSystem.SELO_DURACAO_SEGUNDOS, 0.0, 1.0
		)
		_selo_bar.add_theme_stylebox_override("fill", ManaTheme.progress_style(ManaTheme.GOLD))
	else:
		var proximo := DevocionalSystem.selo_bonus_para_sequencia(sequencia + 1)
		_selo_label.text = "Sem Selo do Dia. A leitura de hoje concede +%d%% de produção por 24 h." % roundi(proximo * 100.0)
		# Barra vazia de largura total lia como divisor: sem selo, ela não existe.
		_selo_bar.visible = false
		_selo_bar.value = 0.0
	var marco: Dictionary = resumo.proximo_marco
	if marco.is_empty():
		_marco_label.text = "Recorde: %d dias  ·  todos os marcos de sequência conquistados." % int(resumo.melhor_sequencia)
	else:
		_marco_label.text = "Recorde: %d dias  ·  próximo marco em %d dias (+%d gemas, +%d Relíquias)" % [
			int(resumo.melhor_sequencia), int(marco.dias), int(marco.gemas), int(marco.reliquias),
		]
	var hora := int(resumo.hora_lembrete)
	_lembrete_button.text = "LEMBRETE: OFF" if hora < 0 else "LEMBRETE %02d:00" % hora


# ----------------------------------------------------------------------- Hoje

func _build_hoje() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	column.add_child(_build_metas_card())

	var leitura_card := PanelContainer.new()
	leitura_card.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(ManaTheme.PARCHMENT, 22, ManaTheme.PARCHMENT_BORDER, 2, 26, true)
	)
	column.add_child(leitura_card)
	var leitura := VBoxContainer.new()
	leitura.add_theme_constant_override("separation", 12)
	leitura_card.add_child(leitura)

	_plano_label = Label.new()
	_plano_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_plano_label.add_theme_font_size_override("font_size", 18)
	_plano_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	leitura.add_child(_plano_label)

	_titulo_label = Label.new()
	_titulo_label.add_theme_font_override("font", ManaTheme.serif_bold())
	_titulo_label.add_theme_font_size_override("font_size", 40)
	_titulo_label.add_theme_color_override("font_color", ManaTheme.INK)
	_titulo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leitura.add_child(_titulo_label)

	_referencia_label = Label.new()
	_referencia_label.add_theme_font_override("font", ManaTheme.body_semibold())
	_referencia_label.add_theme_font_size_override("font_size", 22)
	_referencia_label.add_theme_color_override("font_color", ManaTheme.GOLD_DARK)
	leitura.add_child(_referencia_label)

	_versos_host = VBoxContainer.new()
	_versos_host.add_theme_constant_override("separation", 6)
	leitura.add_child(_versos_host)

	var dica := Label.new()
	dica.text = "Toque em um versículo para destacar. Toque e segure para anotar."
	dica.add_theme_font_size_override("font_size", 16)
	dica.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leitura.add_child(dica)

	column.add_child(_build_texto_card("REFLEXÃO", ManaTheme.SURFACE, ManaTheme.CREAM))
	_reflexao_label = _ultimo_texto_label

	_oracao_card = _build_texto_card("ORAÇÃO", Color("#1b2a33"), Color("#cfe9f2"))
	_oracao_label = _ultimo_texto_label
	column.add_child(_oracao_card)

	_aplicacao_card = _build_texto_card("PARA HOJE", Color("#2a2338"), Color("#e6d6f2"))
	_aplicacao_label = _ultimo_texto_label
	column.add_child(_aplicacao_card)

	_concluir_button = Button.new()
	_concluir_button.custom_minimum_size = Vector2(0, 96)
	_concluir_button.add_theme_font_size_override("font_size", 26)
	ManaTheme.apply_primary_button(_concluir_button)
	_concluir_button.pressed.connect(_on_concluir)
	column.add_child(_concluir_button)

	_concluir_hint = Label.new()
	_concluir_hint.add_theme_font_size_override("font_size", 18)
	_concluir_hint.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	_concluir_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_concluir_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_concluir_hint)
	return column


var _ultimo_texto_label: Label


func _build_texto_card(titulo: String, fundo: Color, cor_texto: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(fundo, 18, ManaTheme.OUTLINE, 1, 22))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var header := Label.new()
	header.text = titulo
	header.add_theme_font_override("font", ManaTheme.body_semibold())
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	column.add_child(header)
	var corpo := Label.new()
	corpo.add_theme_font_size_override("font_size", 22)
	corpo.add_theme_color_override("font_color", cor_texto)
	corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(corpo)
	_ultimo_texto_label = corpo
	return card


func _refresh_leitura() -> void:
	if _leitura.is_empty():
		_titulo_label.text = "Nenhuma leitura disponível"
		_referencia_label.text = ""
		_plano_label.text = ""
		_concluir_button.disabled = true
		return
	var plano: Dictionary = _leitura.plano
	if bool(_leitura.perpetuo):
		_plano_label.text = "%s  ·  leitura de hoje" % str(plano.nome).to_upper()
	else:
		_plano_label.text = "%s  ·  dia %d de %d" % [
			str(plano.nome).to_upper(), int(_leitura.dia_numero), int(_leitura.total_dias)
		]
	_titulo_label.text = str(_leitura.titulo)
	_referencia_label.text = str(_leitura.referencia)
	_reflexao_label.text = str(_leitura.reflexao)
	var oracao := str(_leitura.oracao)
	_oracao_card.visible = not oracao.is_empty()
	_oracao_label.text = oracao
	var aplicacao := str(_leitura.aplicacao)
	_aplicacao_card.visible = not aplicacao.is_empty()
	_aplicacao_label.text = aplicacao
	_rebuild_versos()

	if bool(_leitura.concluida):
		_concluir_button.text = "LEITURA CONCLUÍDA HOJE"
		_concluir_button.disabled = true
		_concluir_hint.text = "Volte amanhã para renovar o Selo do Dia e somar à sequência."
	else:
		_concluir_button.text = "CONCLUIR LEITURA"
		_concluir_button.disabled = false
		var bonus := DevocionalSystem.selo_bonus_para_sequencia(DevocionalSystem.sequencia() + 1)
		_concluir_hint.text = "Concede o Selo do Dia (+%d%% por 24 h), alguns minutos de produção e, a cada %d dias, um ponto de Sabedoria." % [
			roundi(bonus * 100.0), DevocionalSystem.DIAS_POR_SABEDORIA,
		]


func _rebuild_versos() -> void:
	for child in _versos_host.get_children():
		child.queue_free()
	var versos: Array = _leitura.get("versos", [])
	if versos.is_empty():
		var aviso := Label.new()
		aviso.text = "Texto bíblico indisponível para esta referência."
		aviso.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
		aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_versos_host.add_child(aviso)
		return
	var book := str(_leitura.book)
	var chapter := int(_leitura.chapter)
	for verso_value: Variant in versos:
		var verso: Dictionary = verso_value as Dictionary
		var numero := int(verso.get("number", 0))
		var referencia := DevocionalSystem.referencia_de(book, chapter, numero)
		_versos_host.add_child(_build_verso(referencia, numero, str(verso.get("text", ""))))


func _build_verso(referencia: String, numero: int, texto: String) -> Button:
	var destacado := DevocionalSystem.tem_destaque(referencia)
	var tem_nota := not DevocionalSystem.nota(referencia).is_empty()
	var button := Button.new()
	button.text = "%d  %s" % [numero, texto]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = false
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", ManaTheme.INK)
	button.add_theme_color_override("font_hover_color", ManaTheme.INK)
	button.add_theme_color_override("font_pressed_color", ManaTheme.INK)
	var fundo := Color("#fbe9b8") if destacado else Color(0, 0, 0, 0)
	var borda := ManaTheme.GOLD if destacado else Color(0, 0, 0, 0)
	button.add_theme_stylebox_override("normal", ManaTheme.button_style(fundo, borda, 12, 2 if destacado else 0, 14, 10))
	button.add_theme_stylebox_override("hover", ManaTheme.button_style(Color("#f3ead4"), ManaTheme.PARCHMENT_BORDER, 12, 1, 14, 10))
	button.add_theme_stylebox_override("pressed", ManaTheme.button_style(Color("#f0dfae"), ManaTheme.GOLD_DARK, 12, 2, 14, 10))
	if tem_nota:
		button.tooltip_text = DevocionalSystem.nota(referencia)
	button.pressed.connect(func(): _alternar_destaque(referencia))
	button.gui_input.connect(func(event: InputEvent): _verso_gui_input(event, referencia))
	return button


func _verso_gui_input(event: InputEvent, referencia: String) -> void:
	# Toque longo (ou botão direito no desktop) abre a anotação em vez de destacar.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_abrir_nota(referencia)
	elif event is InputEventScreenDrag:
		pass


func _alternar_destaque(referencia: String) -> void:
	DevocionalSystem.alternar_destaque(referencia)
	refresh()


# ----------------------------------------------------------------- Anotações

func _abrir_nota(referencia: String) -> void:
	_nota_referencia = referencia
	if _nota_popup == null:
		_nota_popup = PopupPanel.new()
		_nota_popup.add_theme_stylebox_override(
			"panel", ManaTheme.panel_style(ManaTheme.SURFACE, 22, ManaTheme.GOLD_DARK, 2, 26)
		)
		add_child(_nota_popup)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 14)
		_nota_popup.add_child(column)
		var titulo := Label.new()
		titulo.text = "Anotação"
		titulo.add_theme_font_override("font", ManaTheme.serif_bold())
		titulo.add_theme_font_size_override("font_size", 32)
		titulo.add_theme_color_override("font_color", ManaTheme.CREAM)
		column.add_child(titulo)
		_nota_edit = TextEdit.new()
		_nota_edit.custom_minimum_size = Vector2(620, 240)
		_nota_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		_nota_edit.add_theme_font_size_override("font_size", 22)
		column.add_child(_nota_edit)
		var limite := Label.new()
		limite.text = "Até %d caracteres, %d anotações no total." % [
			DevocionalSystem.MAX_NOTA_CARACTERES, DevocionalSystem.MAX_NOTAS
		]
		limite.add_theme_font_size_override("font_size", 16)
		limite.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
		column.add_child(limite)
		var acoes := HBoxContainer.new()
		acoes.add_theme_constant_override("separation", 12)
		column.add_child(acoes)
		var salvar := Button.new()
		salvar.text = "SALVAR"
		salvar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		salvar.custom_minimum_size = Vector2(0, 64)
		ManaTheme.apply_primary_button(salvar)
		salvar.pressed.connect(_salvar_nota)
		acoes.add_child(salvar)
		var fechar := Button.new()
		fechar.text = "FECHAR"
		fechar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fechar.custom_minimum_size = Vector2(0, 64)
		fechar.pressed.connect(_nota_popup.hide)
		acoes.add_child(fechar)
	_nota_edit.text = DevocionalSystem.nota(referencia)
	_nota_popup.popup_centered()


func _salvar_nota() -> void:
	var resultado := DevocionalSystem.definir_nota(_nota_referencia, _nota_edit.text)
	if not bool(resultado.get("ok", false)):
		EventBus.toast_requested.emit("Limite de %d anotações alcançado" % DevocionalSystem.MAX_NOTAS)
	_nota_popup.hide()
	refresh()


# --------------------------------------------------------------- Metas do dia

func _build_metas_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", ManaTheme.panel_style(ManaTheme.SURFACE_LOW, 20, ManaTheme.OUTLINE, 1, 22))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	var header := Label.new()
	header.text = "METAS DE HOJE"
	header.add_theme_font_override("font", ManaTheme.body_semibold())
	header.add_theme_font_size_override("font_size", 21)
	header.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
	column.add_child(header)
	_metas_host = VBoxContainer.new()
	_metas_host.add_theme_constant_override("separation", 8)
	column.add_child(_metas_host)
	_metas_resgatar_button = Button.new()
	_metas_resgatar_button.custom_minimum_size = Vector2(0, 68)
	_metas_resgatar_button.add_theme_font_size_override("font_size", 21)
	ManaTheme.apply_primary_button(_metas_resgatar_button)
	_metas_resgatar_button.pressed.connect(_on_resgatar_metas)
	column.add_child(_metas_resgatar_button)
	return card


func _refresh_metas() -> void:
	for child in _metas_host.get_children():
		child.queue_free()
	for meta_value: Variant in MetasSystem.resumo():
		var meta: Dictionary = meta_value as Dictionary
		var linha := VBoxContainer.new()
		linha.add_theme_constant_override("separation", 3)
		var titulo := Label.new()
		var marca := "✓ " if bool(meta.concluida) else ""
		titulo.text = "%s%s  ·  %d/%d" % [
			marca, str(meta.nome), int(meta.atual), int(meta.alvo)
		]
		titulo.add_theme_font_size_override("font_size", 24)
		titulo.add_theme_font_override("font", ManaTheme.body_semibold())
		titulo.add_theme_color_override(
			"font_color", ManaTheme.GREEN if bool(meta.resgatada) else ManaTheme.CREAM
		)
		linha.add_child(titulo)
		var desc := Label.new()
		desc.text = "%s  ·  +%d gemas, +%d Relíquias" % [
			str(meta.desc), int(meta.gemas), int(meta.reliquias)
		]
		desc.add_theme_font_size_override("font_size", 19)
		desc.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		linha.add_child(desc)
		var barra := ProgressBar.new()
		barra.custom_minimum_size = Vector2(0, 16)
		barra.show_percentage = false
		barra.max_value = 1.0
		barra.value = float(meta.fracao)
		barra.add_theme_stylebox_override(
			"fill",
			ManaTheme.progress_style(ManaTheme.GREEN if bool(meta.concluida) else ManaTheme.GOLD)
		)
		barra.add_theme_stylebox_override("background", ManaTheme.progress_style(ManaTheme.SURFACE_HIGH))
		linha.add_child(barra)
		_metas_host.add_child(linha)
	var pendentes := MetasSystem.pendentes_para_resgate()
	_metas_resgatar_button.disabled = pendentes <= 0
	_metas_resgatar_button.text = (
		"NADA A RESGATAR" if pendentes <= 0 else "RESGATAR %d META%s" % [pendentes, "" if pendentes == 1 else "S"]
	)


func _on_resgatar_metas() -> void:
	var resultado := MetasSystem.resgatar_todas()
	if int(resultado.count) > 0:
		EventBus.toast_requested.emit(
			"Metas resgatadas: +%d gemas, +%d Relíquias" % [int(resultado.gemas), int(resultado.reliquias)]
		)
	refresh()


# --------------------------------------------------------------------- Planos

func _build_planos() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_planos_host = VBoxContainer.new()
	_planos_host.add_theme_constant_override("separation", 14)
	column.add_child(_planos_host)
	return column


func _refresh_planos() -> void:
	if _planos_host == null:
		return
	for child in _planos_host.get_children():
		child.queue_free()
	var atual := DevocionalSystem.plano_atual()
	var concluidos: Array = GameState.devocional.get("planosConcluidos", [])
	for plano_id in Devocional.plano_ids():
		var resumo := Devocional.resumo(str(plano_id))
		if resumo.is_empty():
			continue
		var card := PanelContainer.new()
		var ativo: bool = str(plano_id) == atual
		card.add_theme_stylebox_override(
			"panel",
			ManaTheme.panel_style(
				ManaTheme.SURFACE_HIGH if ativo else ManaTheme.SURFACE,
				20, ManaTheme.GOLD if ativo else ManaTheme.OUTLINE, 2 if ativo else 1, 22
			)
		)
		_planos_host.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		card.add_child(column)
		var titulo := Label.new()
		titulo.text = str(resumo.nome) + ("  ·  EM CURSO" if ativo else "")
		titulo.add_theme_font_override("font", ManaTheme.serif_bold())
		titulo.add_theme_font_size_override("font_size", 30)
		titulo.add_theme_color_override("font_color", ManaTheme.CREAM)
		column.add_child(titulo)
		var subtitulo := Label.new()
		var extensao := "perpétuo" if bool(resumo.perpetuo) else "%d dias" % int(resumo.dias)
		subtitulo.text = "%s  ·  %s" % [str(resumo.subtitulo), extensao]
		subtitulo.add_theme_font_size_override("font_size", 19)
		subtitulo.add_theme_color_override("font_color", ManaTheme.GOLD_LIGHT)
		column.add_child(subtitulo)
		var descricao := Label.new()
		descricao.text = str(resumo.descricao)
		descricao.add_theme_font_size_override("font_size", 20)
		descricao.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
		descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(descricao)
		if str(plano_id) in concluidos:
			var selo := Label.new()
			selo.text = "✓ Plano concluído"
			selo.add_theme_font_size_override("font_size", 18)
			selo.add_theme_color_override("font_color", ManaTheme.GREEN)
			column.add_child(selo)
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(0, 72)
		botao.add_theme_font_size_override("font_size", 21)
		if ativo:
			botao.text = "PLANO ATUAL"
			botao.disabled = true
		else:
			botao.text = "COMEÇAR ESTE PLANO"
			ManaTheme.apply_primary_button(botao)
			botao.pressed.connect(func(): _escolher_plano(str(plano_id)))
		column.add_child(botao)


func _escolher_plano(plano_id: String) -> void:
	if DevocionalSystem.escolher_plano(plano_id):
		show_section(SECTION_HOJE)
		refresh()


# ------------------------------------------------------------------ Marcados

func _build_marcados() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_marcados_host = VBoxContainer.new()
	_marcados_host.add_theme_constant_override("separation", 10)
	column.add_child(_marcados_host)
	return column


func _refresh_marcados() -> void:
	if _marcados_host == null:
		return
	for child in _marcados_host.get_children():
		child.queue_free()
	var destaques: Array = DevocionalSystem.destaques()
	var notas: Dictionary = GameState.devocional.get("notas", {})
	if destaques.is_empty() and notas.is_empty():
		var vazio := Label.new()
		vazio.text = "Nada marcado ainda. Toque em um versículo na leitura de hoje para destacar, ou toque e segure para anotar."
		vazio.add_theme_font_size_override("font_size", 21)
		vazio.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_marcados_host.add_child(vazio)
		return
	var referencias: Array = destaques.duplicate()
	for chave in notas:
		if str(chave) not in referencias:
			referencias.append(str(chave))
	referencias.sort()
	for referencia in referencias:
		_marcados_host.add_child(_build_marcado(str(referencia), str(notas.get(referencia, ""))))


func _build_marcado(referencia: String, nota: String) -> PanelContainer:
	var partes := referencia.split(":")
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(ManaTheme.PARCHMENT_MUTED, 16, ManaTheme.PARCHMENT_BORDER, 1, 20)
	)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	var texto := ""
	var titulo_texto := referencia
	if partes.size() == 3:
		var passagem := BibleTextProvider.get_passage(
			partes[0], int(partes[1]), int(partes[2]), int(partes[2])
		)
		titulo_texto = str(passagem.get("reference", referencia))
		var versos: Array = passagem.get("verses", [])
		if not versos.is_empty():
			texto = str((versos[0] as Dictionary).get("text", ""))
	var titulo := Label.new()
	titulo.text = titulo_texto
	titulo.add_theme_font_override("font", ManaTheme.body_semibold())
	titulo.add_theme_font_size_override("font_size", 21)
	titulo.add_theme_color_override("font_color", ManaTheme.GOLD_DARK)
	column.add_child(titulo)
	if not texto.is_empty():
		var corpo := Label.new()
		corpo.text = texto
		corpo.add_theme_font_size_override("font_size", 22)
		corpo.add_theme_color_override("font_color", ManaTheme.INK)
		corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(corpo)
	if not nota.is_empty():
		var nota_label := Label.new()
		nota_label.text = "✎ " + nota
		nota_label.add_theme_font_size_override("font_size", 19)
		nota_label.add_theme_color_override("font_color", ManaTheme.INK_MUTED)
		nota_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(nota_label)
	var acoes := HBoxContainer.new()
	acoes.add_theme_constant_override("separation", 10)
	column.add_child(acoes)
	var anotar := Button.new()
	anotar.text = "ANOTAR" if nota.is_empty() else "EDITAR NOTA"
	anotar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anotar.custom_minimum_size = Vector2(0, 58)
	anotar.add_theme_font_size_override("font_size", 18)
	ManaTheme.apply_secondary_light_button(anotar)
	anotar.pressed.connect(func(): _abrir_nota(referencia))
	acoes.add_child(anotar)
	var remover := Button.new()
	remover.text = "REMOVER"
	remover.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remover.custom_minimum_size = Vector2(0, 58)
	remover.add_theme_font_size_override("font_size", 18)
	ManaTheme.apply_secondary_light_button(remover)
	remover.pressed.connect(func(): _remover_marcado(referencia))
	acoes.add_child(remover)
	return card


func _remover_marcado(referencia: String) -> void:
	if DevocionalSystem.tem_destaque(referencia):
		DevocionalSystem.alternar_destaque(referencia)
	DevocionalSystem.definir_nota(referencia, "")
	refresh()


# ------------------------------------------------------------------- Lembrete

func _abrir_lembrete() -> void:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override(
		"panel", ManaTheme.panel_style(ManaTheme.SURFACE, 22, ManaTheme.GOLD_DARK, 2, 24)
	)
	add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	popup.add_child(column)
	var titulo := Label.new()
	titulo.text = "Lembrete diário"
	titulo.add_theme_font_override("font", ManaTheme.serif_bold())
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", ManaTheme.CREAM)
	column.add_child(titulo)
	var explicacao := Label.new()
	explicacao.text = (
		"Escolha um horário para o aviso da leitura. "
		+ ("Notificações do sistema estão disponíveis." if Notificacoes.disponivel()
			else "Nesta versão o aviso só aparece dentro do app; a notificação do sistema chega junto com o plugin Android.")
	)
	explicacao.add_theme_font_size_override("font_size", 19)
	explicacao.add_theme_color_override("font_color", ManaTheme.CREAM_MUTED)
	explicacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explicacao.custom_minimum_size = Vector2(560, 0)
	column.add_child(explicacao)
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	column.add_child(grade)
	for hora in [-1, 6, 7, 8, 9, 12, 18, 19, 20, 21, 22, 23]:
		var botao := Button.new()
		botao.text = "DESLIGADO" if hora < 0 else "%02d:00" % hora
		botao.custom_minimum_size = Vector2(130, 62)
		botao.add_theme_font_size_override("font_size", 19)
		if hora == DevocionalSystem.hora_lembrete():
			ManaTheme.apply_primary_button(botao)
		botao.pressed.connect(func():
			DevocionalSystem.definir_hora_lembrete(hora)
			popup.hide()
			refresh()
		)
		grade.add_child(botao)
	popup.popup_centered()


# ------------------------------------------------------------------- Concluir

func _on_concluir() -> void:
	var resultado := DevocionalSystem.concluir_leitura()
	if not bool(resultado.get("ok", false)):
		return
	var partes: Array[String] = [
		"Selo do Dia +%d%%" % roundi(float(resultado.selo_bonus) * 100.0),
		"+%s %s" % [
			NumberFormat.format(float(resultado.amount)),
			GameState.get_currency_name(str(resultado.currency)),
		],
	]
	if int(resultado.sabedoria) > 0:
		partes.append("+%d Sabedoria" % int(resultado.sabedoria))
	if int(resultado.gemas) > 0:
		partes.append("+%d gemas" % int(resultado.gemas))
	if int(resultado.reliquias) > 0:
		partes.append("+%d Relíquias" % int(resultado.reliquias))
	if bool(resultado.perdoado):
		partes.append("sequência preservada por um dia de perdão")
	EventBus.toast_requested.emit("  ·  ".join(partes))
	refresh()

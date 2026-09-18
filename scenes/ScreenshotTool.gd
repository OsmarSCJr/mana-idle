extends Node

## Ferramenta de revisão visual: abre Main, percorre as abas e grava um PNG de
## cada uma em user://screenshots (ou no caminho passado em --shots-dir).
##
## Roda em janela real (NÃO headless): o renderer dummy do modo headless devolve
## textura vazia. Uso:
##
##   godot --path . scenes/ScreenshotTool.tscn -- --screenshots
##
## Não é teste: não afirma nada e não entra na suíte de smoke. Serve para olhar.

const ABAS: Array = [
	["geradores", "01-jornada"],
	["milagres", "02-bencaos"],
	["devocional", "03-diario"],
	["estudo", "04-estudo"],
	["santos", "05-santos"],
	["gemas", "06-tenda"],
]


func _ready() -> void:
	SaveSystem.set_persistence_enabled(false)
	var destino := _destino()
	DirAccess.make_dir_recursive_absolute(destino)
	await get_tree().process_frame
	await get_tree().process_frame

	var main := get_node_or_null("Main")
	if main == null:
		push_error("Main não encontrado na cena de screenshots.")
		get_tree().quit(1)
		return

	# Estado de demonstração: recursos suficientes para os cartões saírem do
	# estado "bloqueado" e o visual poder ser julgado de verdade.
	_preparar_estado()
	await get_tree().process_frame

	for entrada in ABAS:
		main.call("_show_tab", str(entrada[0]))
		# Três quadros: um para o layout assentar, dois para tweens de entrada.
		for _i in range(3):
			await RenderingServer.frame_post_draw
		_gravar(destino, str(entrada[1]))

	# Subseções que mudam bastante o visual e merecem quadro próprio.
	main.call("_show_tab", "devocional")
	var devocional: Node = main.get("_panel_devocional")
	for secao in [["planos", "03b-diario-planos"], ["marcados", "03c-diario-marcados"]]:
		devocional.call("show_section", str(secao[0]))
		for _i in range(3):
			await RenderingServer.frame_post_draw
		_gravar(destino, str(secao[1]))

	main.call("_show_tab", "santos")
	var progresso: Node = main.get("_panel_progresso")
	for secao in [["provacoes", "05b-santos-provacoes"], ["conquistas", "05c-santos-conquistas"]]:
		progresso.call("show_section", str(secao[0]))
		for _i in range(3):
			await RenderingServer.frame_post_draw
		_gravar(destino, str(secao[1]))

	print("[SHOTS] gravados em ", ProjectSettings.globalize_path(destino))
	get_tree().quit(0)


func _destino() -> String:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--shots-dir="):
			return argumento.substr("--shots-dir=".length())
	return "user://screenshots"


func _preparar_estado() -> void:
	GameState._reset_alpha_progress()
	GameState.fe = 5.0e9
	GameState.gemas = 240
	GameState.reliquias = 420
	GameState.sabedoria = 12
	GameState.santos = 90
	for gen_id in range(1, 7):
		GameState.buy_generator(gen_id, 40)
		GameState.buy_prophet(gen_id)
	GameState.fe = 5.0e9
	GameState.aventuras_desbloqueadas = ["jornada", "vida_cristo", "igreja_apocalipse"]
	GameState.marcos_ledger["jornada"] = [25, 50]
	Conquistas.verificar()
	MetasSystem.garantir_dia()
	Economy.recompute_multiplicadores()
	EventBus.ui_needs_update.emit()


func _gravar(destino: String, nome: String) -> void:
	var textura := get_viewport().get_texture()
	if textura == null:
		push_warning("Viewport sem textura para %s (modo headless?)" % nome)
		return
	var imagem := textura.get_image()
	if imagem == null or imagem.is_empty():
		push_warning("Imagem vazia para %s" % nome)
		return
	var caminho := "%s/%s.png" % [destino, nome]
	if imagem.save_png(caminho) != OK:
		push_warning("Falha ao gravar %s" % caminho)
	else:
		print("[SHOTS] ", nome, " ", imagem.get_width(), "x", imagem.get_height())

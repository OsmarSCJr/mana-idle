extends Node

## Loja de Reliquias: catalogo 100% cosmetico (zero poder, zero rebalanceamento).
## Reliquias vem dos marcos gerais e dos marcos de moeda das aventuras.
##
## Categorias com aplicacao imediata:
##   "tema_fundo" - paleta do SacredBackground (fundo procedural)
##   "titulo"     - titulo exibido no cabecalho (topbar)
##   "estrela"    - cores da Estrela Nova
## Categorias cuja aplicacao visual ainda nao foi implementada
## ("requer_implementacao": true) aparecem como EM BREVE. Seus previews ja
## existem, mas a compra permanece bloqueada ate o efeito estar ligado a UI.

const RARIDADES: Dictionary = {
	"comum": {"nome": "Comum", "cor": Color("#9aa4b5")},
	"rara": {"nome": "Rara", "cor": Color("#71cbd0")},
	"epica": {"nome": "Épica", "cor": Color("#b78fe0")},
	"lendaria": {"nome": "Lendária", "cor": Color("#f2d37a")},
}

const DADOS: Array = [
	# ---- Temas do Santuario (fundo procedural: troca de paleta) ----
	{
		"id": "fundo_aurora", "categoria": "tema_fundo", "raridade": "comum", "custo": 15,
		"nome": "Aurora da Criação", "descricao": "O primeiro amanhecer sobre as águas.",
		"palette": {
			"top": Color("#1a1030"), "bottom": Color("#432818"),
			"glow": Color(1.0, 0.55, 0.25, 0.06), "star": Color(1.0, 0.88, 0.66),
		},
	},
	{
		"id": "fundo_belem", "categoria": "tema_fundo", "raridade": "comum", "custo": 25,
		"nome": "Noite de Belém", "descricao": "Um céu profundo guiado por uma única estrela.",
		"palette": {
			"top": Color("#050b1f"), "bottom": Color("#0d1b3f"),
			"glow": Color(0.55, 0.7, 1.0, 0.05), "star": Color(0.85, 0.92, 1.0),
		},
	},
	{
		"id": "fundo_mar", "categoria": "tema_fundo", "raridade": "rara", "custo": 75,
		"nome": "Travessia do Mar", "descricao": "Paredes de água e um caminho seco no meio.",
		"palette": {
			"top": Color("#02131c"), "bottom": Color("#0a3d4f"),
			"glow": Color(0.35, 0.9, 0.9, 0.06), "star": Color(0.75, 0.98, 0.95),
		},
	},
	{
		"id": "fundo_vitral", "categoria": "tema_fundo", "raridade": "epica", "custo": 250,
		"nome": "Vitral Gótico", "descricao": "Luz coada por vidros de catedral.",
		"palette": {
			"top": Color("#160a24"), "bottom": Color("#3b1136"),
			"glow": Color(0.9, 0.4, 0.7, 0.07), "star": Color(1.0, 0.8, 0.95),
		},
	},
	{
		"id": "fundo_jerusalem", "categoria": "tema_fundo", "raridade": "lendaria", "custo": 600,
		"nome": "Nova Jerusalém", "descricao": "Ruas de ouro sob um céu que não anoitece.",
		"palette": {
			"top": Color("#1d1503"), "bottom": Color("#4f3a06"),
			"glow": Color(1.0, 0.85, 0.3, 0.10), "star": Color(1.0, 0.95, 0.7),
		},
	},
	# ---- Skins da Estrela Nova ----
	{
		"id": "estrela_cometa", "categoria": "estrela", "raridade": "comum", "custo": 20,
		"nome": "Cometa de Belém", "descricao": "Rastro azul-prateado apontando o caminho.",
		"star_color": Color(0.8, 0.9, 1.0), "trail_color": Color(0.5, 0.7, 1.0, 0.5),
	},
	{
		"id": "estrela_serafim", "categoria": "estrela", "raridade": "rara", "custo": 75,
		"nome": "Chama do Serafim", "descricao": "Um risco de fogo vivo cruzando o santuário.",
		"star_color": Color(1.0, 0.6, 0.25), "trail_color": Color(1.0, 0.4, 0.1, 0.5),
	},
	{
		"id": "estrela_alva", "categoria": "estrela", "raridade": "epica", "custo": 250,
		"nome": "Estrela da Alva", "descricao": "A que anuncia a manhã que não termina.",
		"star_color": Color(1.0, 1.0, 0.95), "trail_color": Color(1.0, 0.95, 0.6, 0.6),
	},
	# ---- Titulos (exibidos no cabecalho) ----
	{"id": "titulo_peregrino", "categoria": "titulo", "raridade": "comum", "custo": 15, "nome": "Peregrino", "descricao": "Quem caminha, chega.", "texto": "PEREGRINO"},
	{"id": "titulo_semeador", "categoria": "titulo", "raridade": "comum", "custo": 30, "nome": "Semeador", "descricao": "Plantou em boa terra.", "texto": "SEMEADOR"},
	{"id": "titulo_guardiao", "categoria": "titulo", "raridade": "rara", "custo": 75, "nome": "Guardião da Arca", "descricao": "Dois a dois, sem faltar nenhum.", "texto": "GUARDIÃO DA ARCA"},
	{"id": "titulo_escriba", "categoria": "titulo", "raridade": "rara", "custo": 100, "nome": "Escriba Fiel", "descricao": "Nem um til passará.", "texto": "ESCRIBA FIEL"},
	{"id": "titulo_profeta", "categoria": "titulo", "raridade": "epica", "custo": 250, "nome": "Voz no Deserto", "descricao": "Preparai o caminho.", "texto": "VOZ NO DESERTO"},
	{"id": "titulo_vencedor", "categoria": "titulo", "raridade": "lendaria", "custo": 1000, "nome": "Mais que Vencedor", "descricao": "Em todas estas coisas.", "texto": "MAIS QUE VENCEDOR"},
	# ---- Preview pronto; aplicacao visual ainda pendente ----
	{"id": "retratos_iluminados_era1", "categoria": "retrato", "raridade": "rara", "custo": 100, "nome": "Retratos Iluminados — Gênesis", "descricao": "Os profetas da Era 1 em iluminura dourada.", "requer_implementacao": true},
	{"id": "moldura_arca", "categoria": "moldura", "raridade": "rara", "custo": 75, "nome": "Moldura Madeira da Arca", "descricao": "Cartões de gerador em madeira de gofer.", "requer_implementacao": true},
	{"id": "moldura_templo", "categoria": "moldura", "raridade": "epica", "custo": 250, "nome": "Moldura Ouro do Templo", "descricao": "Cartões folheados a ouro puro.", "requer_implementacao": true},
	{"id": "efeito_pombas", "categoria": "efeito", "raridade": "rara", "custo": 100, "nome": "Ciclo das Pombas", "descricao": "Pombas brancas celebram cada ciclo completo.", "requer_implementacao": true},
	{"id": "tema_leitor_pergaminho", "categoria": "tema_leitor", "raridade": "comum", "custo": 30, "nome": "Leitor Pergaminho", "descricao": "A Palavra sobre pergaminho antigo.", "requer_implementacao": true},
]

# Paleta padrao do santuario (nenhum tema ativo).
const PALETTE_PADRAO: Dictionary = {}

var _by_id: Dictionary = {}

func _ready() -> void:
	for c in DADOS:
		_by_id[c.id] = c

func get_data(id: String) -> Dictionary:
	return _by_id.get(id, {})

func all() -> Array:
	return DADOS.duplicate()

func compraveis() -> Array:
	var result: Array = []
	for c in DADOS:
		if not bool(c.get("requer_implementacao", false)):
			result.append(c)
	result.sort_custom(func(a, b): return int(a.custo) < int(b.custo))
	return result

func aguardando_implementacao() -> Array:
	var result: Array = []
	for c in DADOS:
		if bool(c.get("requer_implementacao", false)):
			result.append(c)
	return result

func raridade_info(raridade: String) -> Dictionary:
	return RARIDADES.get(raridade, RARIDADES.comum)

# ---- Consultas de aplicacao (UI le daqui o cosmetico ativo) ----

func active_background_palette() -> Dictionary:
	var active_id := str(GameState.cosmeticos_ativos.get("tema_fundo", ""))
	var data := get_data(active_id)
	return data.get("palette", PALETTE_PADRAO) if not data.is_empty() else PALETTE_PADRAO

func active_title_text() -> String:
	var active_id := str(GameState.cosmeticos_ativos.get("titulo", ""))
	var data := get_data(active_id)
	return str(data.get("texto", "")) if not data.is_empty() else ""

func active_star_colors() -> Dictionary:
	var active_id := str(GameState.cosmeticos_ativos.get("estrela", ""))
	var data := get_data(active_id)
	if data.is_empty():
		return {"star": Color(1.0, 0.93, 0.72), "trail": Color(1.0, 0.85, 0.4, 0.5)}
	return {"star": data.star_color, "trail": data.trail_color}

extends Node

## A Oliveira da Sabedoria. Comprar um no desbloqueia seu potencial;
## somente os nos ativos participam da economia da jornada atual.

const EFFECT_TYPES := [
	"offline_mult",
	"offline_cap_seconds",
	"discount_global",
	"global_prod",
	"global_speed",
	"manual_mult",
	"santo_bonus",
	"prophet_discount",
	"boost_duration",
	"study_faith",
	"adventure_fe_discount",
	"adventure_gem_discount",
]

const CATEGORY_COLORS := {
	"roots": Color("#cf9e4b"),
	"word": Color("#71cbd0"),
	"work": Color("#d38e58"),
	"communion": Color("#cf8899"),
	"mission": Color("#8fbd8f"),
	"crown": Color("#f2d37a"),
}

const TIER_COSTS := [1, 2, 3, 5, 10, 20]
const DADOS: Array = [
	# Raizes: dez nos iniciais, dois por ramo da oliveira.
	{"id": "knowledge_good_seed", "name": "Boa Semente", "cost": 1, "category": "roots", "effect": {"type": "offline_mult", "value": 1.05}, "effect_text": "+5% na producao offline", "position": [150, 1160]},
	{"id": "knowledge_faithful_memory", "name": "Memoria Fiel", "cost": 1, "category": "roots", "effect": {"type": "offline_cap_seconds", "value": 1800.0}, "effect_text": "+30 min no limite offline", "position": [270, 1280]},
	{"id": "knowledge_reading_attention", "name": "Leitura Atenta", "cost": 1, "category": "word", "effect": {"type": "study_faith", "value": 1.05}, "effect_text": "+5% Fe nas leituras e quizzes", "position": [310, 1160]},
	{"id": "knowledge_living_memory", "name": "Memoria Viva", "cost": 1, "category": "word", "effect": {"type": "study_faith", "value": 1.05}, "effect_text": "+5% Fe nos estudos", "position": [370, 1280]},
	{"id": "knowledge_diligent_work", "name": "Maos Diligentes", "cost": 1, "category": "work", "effect": {"type": "manual_mult", "value": 1.15}, "effect_text": "+15% Fe nos ciclos manuais", "position": [470, 1160]},
	{"id": "knowledge_field_rhythm", "name": "Ritmo do Campo", "cost": 1, "category": "work", "effect": {"type": "global_speed", "value": 0.96}, "effect_text": "Ciclos 4% mais rapidos", "position": [470, 1280]},
	{"id": "knowledge_shared_table", "name": "Mesa Partilhada", "cost": 1, "category": "communion", "effect": {"type": "santo_bonus", "value": 0.01}, "effect_text": "+1% de efeito por Santo", "position": [630, 1160]},
	{"id": "knowledge_unison_song", "name": "Cantico Unissono", "cost": 1, "category": "communion", "effect": {"type": "global_prod", "value": 1.04}, "effect_text": "+4% producao global", "position": [570, 1280]},
	{"id": "knowledge_christ_way", "name": "Caminho de Cristo", "cost": 1, "category": "mission", "effect": {"type": "adventure_fe_discount", "value": 0.95}, "effect_text": "-5% no custo em Fe de aventuras", "position": [790, 1160]},
	{"id": "knowledge_apocalypse_vision", "name": "Visao do Apocalipse", "cost": 1, "category": "mission", "effect": {"type": "adventure_gem_discount", "value": 0.90}, "effect_text": "-10% no custo em Gemas de aventuras", "position": [670, 1280]},

	# Galhos principais: uma rota por categoria.
	{"id": "knowledge_deep_root", "name": "Raiz Profunda", "cost": 2, "category": "roots", "effect": {"type": "offline_mult", "value": 1.12}, "effect_text": "+12% producao offline", "requires": ["knowledge_good_seed"], "position": [166, 1050]},
	{"id": "knowledge_illuminated_scroll", "name": "Pergaminho Iluminado", "cost": 2, "category": "word", "effect": {"type": "study_faith", "value": 1.10}, "effect_text": "+10% Fe nos estudos", "requires": ["knowledge_reading_attention"], "position": [324, 1040]},
	{"id": "knowledge_faithful_workshop", "name": "Oficina Fiel", "cost": 2, "category": "work", "effect": {"type": "prophet_discount", "value": 0.90}, "effect_text": "-10% no custo de Profetas", "requires": ["knowledge_diligent_work"], "position": [470, 1004]},
	{"id": "knowledge_renewed_covenant", "name": "Alianca Renovada", "cost": 2, "category": "communion", "effect": {"type": "santo_bonus", "value": 0.01}, "effect_text": "+1% de efeito por Santo", "requires": ["knowledge_shared_table"], "position": [616, 1040]},
	{"id": "knowledge_testimony", "name": "Testemunho", "cost": 2, "category": "mission", "effect": {"type": "global_prod", "value": 1.05}, "effect_text": "+5% producao global", "requires": ["knowledge_christ_way"], "position": [774, 1050]},

	# Ramos maduros.
	{"id": "knowledge_ancient_roots", "name": "Raizes Antigas", "cost": 3, "category": "roots", "effect": {"type": "discount_global", "value": 0.96}, "effect_text": "-4% no custo de operadores", "requires": ["knowledge_deep_root"], "position": [204, 900]},
	{"id": "knowledge_word_firm", "name": "Palavra Firmada", "cost": 3, "category": "word", "effect": {"type": "offline_cap_seconds", "value": 3600.0}, "effect_text": "+1 h no limite offline", "requires": ["knowledge_illuminated_scroll"], "position": [350, 820]},
	{"id": "knowledge_complete_work", "name": "Obra Completa", "cost": 3, "category": "work", "effect": {"type": "global_prod", "value": 1.10}, "effect_text": "+10% producao global", "requires": ["knowledge_faithful_workshop"], "position": [470, 762]},
	{"id": "knowledge_intercession", "name": "Intercessao", "cost": 3, "category": "communion", "effect": {"type": "boost_duration", "value": 1.15}, "effect_text": "+15% na duracao de impulsos", "requires": ["knowledge_renewed_covenant"], "position": [590, 820]},
	{"id": "knowledge_multiplying_fruit", "name": "Fruto Multiplicado", "cost": 3, "category": "mission", "effect": {"type": "adventure_fe_discount", "value": 0.90}, "effect_text": "-10% no custo em Fe de aventuras", "requires": ["knowledge_testimony"], "position": [736, 900]},

	# Copa inferior.
	{"id": "knowledge_fruitful_olive", "name": "Oliveira Frutifera", "cost": 5, "category": "roots", "effect": {"type": "global_prod", "value": 1.15}, "effect_text": "+15% producao global", "requires": ["knowledge_ancient_roots"], "position": [150, 626]},
	{"id": "knowledge_discernment", "name": "Discernimento", "cost": 5, "category": "word", "effect": {"type": "discount_global", "value": 0.92}, "effect_text": "-8% no custo de operadores", "requires": ["knowledge_word_firm"], "position": [330, 596]},
	{"id": "knowledge_consecrated_tools", "name": "Ferramentas Consagradas", "cost": 5, "category": "work", "effect": {"type": "global_speed", "value": 0.90}, "effect_text": "Ciclos 10% mais rapidos", "requires": ["knowledge_complete_work"], "position": [470, 528]},
	{"id": "knowledge_living_communion", "name": "Comunhao Viva", "cost": 5, "category": "communion", "effect": {"type": "manual_mult", "value": 1.35}, "effect_text": "+35% Fe nos ciclos manuais", "requires": ["knowledge_intercession"], "position": [610, 596]},
	{"id": "knowledge_open_paths", "name": "Portas Abertas", "cost": 5, "category": "mission", "effect": {"type": "adventure_gem_discount", "value": 0.75}, "effect_text": "-25% no custo em Gemas de aventuras", "requires": ["knowledge_multiplying_fruit"], "position": [790, 626]},

	# Quatro especializacoes altas. Qualquer uma permite tocar a copa.
	{"id": "knowledge_abundant_harvest", "name": "Colheita Abundante", "cost": 10, "category": "roots", "effect": {"type": "offline_mult", "value": 1.35}, "effect_text": "+35% producao offline", "requires": ["knowledge_fruitful_olive"], "position": [234, 390]},
	{"id": "knowledge_lamp_path", "name": "Lampada do Caminho", "cost": 10, "category": "word", "effect": {"type": "study_faith", "value": 1.25}, "effect_text": "+25% Fe nos estudos", "requires": ["knowledge_discernment"], "position": [384, 318]},
	{"id": "knowledge_lasting_communion", "name": "Comunhao Duradoura", "cost": 10, "category": "communion", "effect": {"type": "boost_duration", "value": 1.25}, "effect_text": "+25% na duracao de impulsos", "requires": ["knowledge_living_communion"], "position": [556, 318]},
	{"id": "knowledge_blooming_mission", "name": "Missao Florescente", "cost": 10, "category": "mission", "effect": {"type": "global_prod", "value": 1.20}, "effect_text": "+20% producao global", "requires": ["knowledge_open_paths"], "position": [706, 390]},

	{"id": "knowledge_full_olive", "name": "Oliveira Plena", "cost": 20, "category": "crown", "effect": {"type": "global_prod", "value": 1.30}, "effect_text": "+30% producao global", "requires_any": ["knowledge_abundant_harvest", "knowledge_lamp_path", "knowledge_lasting_communion", "knowledge_blooming_mission"], "position": [470, 130]},
]

func get_data(id: String) -> Dictionary:
	for knowledge: Dictionary in DADOS:
		if knowledge.get("id", "") == id:
			return knowledge.duplicate(true)
	return {}

func all() -> Array:
	return DADOS.duplicate(true)

func count() -> int:
	return DADOS.size()

func category_color(category: String) -> Color:
	return CATEGORY_COLORS.get(category, ManaTheme.GOLD_LIGHT) as Color

func get_requires(knowledge: Dictionary) -> Array:
	var requirements: Variant = knowledge.get("requires", [])
	return requirements if requirements is Array else []

func get_requires_any(knowledge: Dictionary) -> Array:
	var requirements: Variant = knowledge.get("requires_any", [])
	return requirements if requirements is Array else []

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	var costs := {}
	for cost in TIER_COSTS:
		costs[cost] = 0
	for index in range(DADOS.size()):
		var knowledge: Dictionary = DADOS[index]
		var prefix := "Conhecimento %d" % (index + 1)
		var id := str(knowledge.get("id", ""))
		if id.is_empty() or ids.has(id):
			errors.append(prefix + " possui id ausente ou duplicado.")
		else:
			ids[id] = true
		var cost := int(knowledge.get("cost", 0))
		if not costs.has(cost):
			errors.append(prefix + " possui custo invalido.")
		else:
			costs[cost] += 1
		var effect: Variant = knowledge.get("effect", {})
		if effect is not Dictionary:
			errors.append(prefix + " possui efeito invalido.")
		else:
			var effect_data: Dictionary = effect
			if str(effect_data.get("type", "")) not in EFFECT_TYPES:
				errors.append(prefix + " possui tipo de efeito invalido.")
		if not knowledge.has("position"):
			errors.append(prefix + " nao possui posicao na oliveira.")
	if DADOS.size() != 30:
		errors.append("A Oliveira deve conter exatamente 30 conhecimentos.")
	if costs.get(1, 0) != 10 or costs.get(2, 0) != 5 or costs.get(3, 0) != 5 or costs.get(5, 0) != 5 or costs.get(10, 0) != 4 or costs.get(20, 0) != 1:
		errors.append("A distribuicao de custos da Oliveira esta incorreta.")
	return errors

func is_valid() -> bool:
	return validate_data().is_empty()

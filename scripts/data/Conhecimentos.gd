extends Node

## Conhecimentos permanentes adquiridos com Sabedoria.
##
## Os efeitos são dados declarativos; sua aplicação pertence à camada de
## economia. `offline_cap_seconds` é um acréscimo em segundos, enquanto os
## demais valores são multiplicadores.

const EFFECT_TYPES := [
	"offline_mult",
	"offline_cap_seconds",
	"discount_global",
	"global_prod",
]

const DADOS: Array = [
	{
		"id": "knowledge_good_seed",
		"name": "Boa Semente",
		"title": "Boa Semente",
		"cost": 2,
		"effect": {"type": "offline_mult", "value": 1.05},
		"effect_text": "+5% na produção offline",
	},
	{
		"id": "knowledge_faithful_memory",
		"name": "Memória Fiel",
		"title": "Memória Fiel",
		"cost": 3,
		"effect": {"type": "offline_cap_seconds", "value": 1800.0},
		"effect_text": "+30 minutos no limite de produção offline",
	},
	{
		"id": "knowledge_discernment",
		"name": "Discernimento",
		"title": "Discernimento",
		"cost": 4,
		"effect": {"type": "discount_global", "value": 0.99},
		"effect_text": "-1% no custo de todos os geradores",
	},
	{
		"id": "knowledge_constancy",
		"name": "Constância",
		"title": "Constância",
		"cost": 5,
		"effect": {"type": "global_prod", "value": 1.02},
		"effect_text": "+2% na produção global",
	},
	{
		"id": "knowledge_diligent_work",
		"name": "Trabalho Diligente",
		"title": "Trabalho Diligente",
		"cost": 7,
		"effect": {"type": "global_prod", "value": 1.03},
		"effect_text": "+3% na produção global",
	},
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


## Retorna uma lista vazia quando o catálogo está íntegro.
func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}

	if DADOS.size() != 5:
		errors.append("O catálogo deve conter exatamente 5 conhecimentos.")

	for index in range(DADOS.size()):
		var knowledge: Dictionary = DADOS[index]
		var prefix := "Conhecimento %d" % (index + 1)
		var id := str(knowledge.get("id", ""))
		if id.is_empty():
			errors.append("%s não possui id." % prefix)
		elif ids.has(id):
			errors.append("ID de conhecimento duplicado: %s." % id)
		else:
			ids[id] = true

		if str(knowledge.get("name", "")).is_empty():
			errors.append("%s não possui nome." % prefix)
		if int(knowledge.get("cost", 0)) <= 0:
			errors.append("%s possui custo inválido." % prefix)

		var effect_value: Variant = knowledge.get("effect", {})
		if effect_value is not Dictionary:
			errors.append("%s possui efeito inválido." % prefix)
			continue
		var effect: Dictionary = effect_value
		var effect_type := str(effect.get("type", ""))
		if effect_type not in EFFECT_TYPES:
			errors.append("%s possui tipo de efeito desconhecido: %s." % [prefix, effect_type])
		if float(effect.get("value", 0.0)) <= 0.0:
			errors.append("%s possui valor de efeito inválido." % prefix)

	return errors


func is_valid() -> bool:
	return validate_data().is_empty()

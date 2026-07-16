extends Node

const FINAL_JOURNEY_TARGET: float = 3.55e39
const ERA_MASTERY_WISDOM: int = 2
const JOURNEY_MASTERY_WISDOM: int = 3

var _mutations_suspended: bool = false
var _refresh_pending: bool = false

func _ready() -> void:
	EventBus.generator_changed.connect(func(_id: int): refresh_unlocks())
	EventBus.prestige_done.connect(func(): refresh_unlocks(false))
	call_deferred("refresh_unlocks", false)

func set_mutations_suspended(suspended: bool) -> void:
	_mutations_suspended = suspended
	if not suspended and _refresh_pending:
		_refresh_pending = false
		refresh_unlocks(false)

func _list(key: String) -> Array:
	if not GameState.estudo_progresso.has(key) or GameState.estudo_progresso[key] is not Array:
		GameState.estudo_progresso[key] = []
	return GameState.estudo_progresso[key]

func _append_once(key: String, value: String) -> bool:
	var values := _list(key)
	if value in values:
		return false
	values.append(value)
	return true

func _find_study_by_question(question_id: String) -> Dictionary:
	for study in EstudosBiblicos.all():
		var question: Dictionary = study.get("question", {})
		if str(question.get("id", "")) == question_id:
			return study
	return {}

func _requirement_met(study: Dictionary) -> bool:
	var gen_id := int(study.get("generator_id", 0))
	var required := int(study.get("required_quantity", 0))
	if gen_id <= 0:
		return true
	var current: Dictionary = GameState.geradores.get(gen_id, {})
	var highest: int = maxi(int(current.get("qtd", 0)), int(GameState.maior_qtd_gerador.get(gen_id, 0)))
	return highest >= required

func refresh_unlocks(emit_events: bool = true) -> int:
	if _mutations_suspended:
		_refresh_pending = true
		return 0
	var unlocked_count := 0
	for study in EstudosBiblicos.all():
		var study_id := str(study.get("id", ""))
		if study_id.is_empty() or study_id in _list("desbloqueados"):
			continue
		if not _requirement_met(study):
			continue
		_append_once("desbloqueados", study_id)
		unlocked_count += 1
		if emit_events:
			EventBus.study_unlocked.emit(study_id)
			EventBus.toast_requested.emit("Novo pergaminho disponível: " + str(study.get("title", "Estudo")))
	if unlocked_count > 0:
		_request_save()
	return unlocked_count

func is_unlocked(study_id: String) -> bool:
	return study_id in _list("desbloqueados")

func get_study_state(study_id: String) -> String:
	if study_id not in _list("desbloqueados"):
		return "locked"
	var study := EstudosBiblicos.get_data(study_id)
	if study.is_empty():
		return "locked"
	var question_id := str(study.get("question", {}).get("id", ""))
	if not question_id.is_empty() and question_id in _list("questoesCorretas"):
		return "mastered"
	if study_id in _list("leiturasConcluidas"):
		return "read"
	return "new"

func _reward_target(study: Dictionary) -> float:
	var explicit := float(study.get("reward_target", 0.0))
	if explicit > 0.0:
		return explicit
	var gen_id := int(study.get("generator_id", 0))
	if gen_id < Geradores.count():
		return float(Geradores.get_data(gen_id + 1).get("custo_base", 0.0))
	return FINAL_JOURNEY_TARGET

func _reward_amount(study: Dictionary, kind: String) -> float:
	var ratios: Dictionary = study.get("reward_ratios", {})
	var minimums: Dictionary = study.get("reward_minimums", {})
	var ratio := float(ratios.get(kind, 0.0))
	var minimum := float(minimums.get(kind, 0.0))
	return max(minimum, floor(_reward_target(study) * ratio)) * Economy.get_study_faith_multiplier()

func _claim_reward(reward_id: String, faith: float = 0.0, wisdom: int = 0) -> bool:
	if reward_id in _list("recompensasResgatadas"):
		return false
	_append_once("recompensasResgatadas", reward_id)
	if faith > 0.0:
		GameState.fe += faith
		GameState.fe_total_vida += faith
		GameState.fe_total_historica += faith
		EventBus.faith_changed.emit(GameState.fe)
	if wisdom > 0:
		GameState.sabedoria += wisdom
		GameState.sabedoria_total += wisdom
		EventBus.wisdom_changed.emit(GameState.sabedoria)
	return true

func complete_reading(study_id: String) -> Dictionary:
	var study := EstudosBiblicos.get_data(study_id)
	if study.is_empty():
		return {"ok": false, "reason": "missing"}
	if not is_unlocked(study_id):
		return {"ok": false, "reason": "locked"}
	if study_id in _list("leiturasConcluidas"):
		return {"ok": true, "rewarded": false, "faith": 0.0}

	_append_once("leiturasConcluidas", study_id)
	var reward := _reward_amount(study, "reading")
	var rewarded := _claim_reward("reading:" + study_id, reward, 0)
	EventBus.study_progress_changed.emit(study_id)
	EventBus.toast_requested.emit("Leitura concluída: +" + NumberFormat.format(reward) + " de Fé")
	_request_save()
	return {"ok": true, "rewarded": rewarded, "faith": reward}

func submit_answer(question_id: String, option_id: String) -> Dictionary:
	var study := _find_study_by_question(question_id)
	if study.is_empty():
		return {"ok": false, "reason": "missing"}
	var study_id := str(study.id)
	if study_id not in _list("leiturasConcluidas"):
		return {"ok": false, "reason": "reading_required"}
	var question: Dictionary = study.question
	var correct := option_id == str(question.get("correct_option_id", ""))
	if not correct:
		return {
			"ok": true,
			"correct": false,
			"rewarded": false,
			"explanation": str(question.get("explanation", "Leia novamente a passagem e tente outra vez.")),
		}

	var already_mastered := question_id in _list("questoesCorretas")
	_append_once("questoesCorretas", question_id)
	var reward := _reward_amount(study, "quiz")
	var rewarded := _claim_reward("quiz:" + question_id, reward, 1)
	_claim_mastery_rewards()
	EventBus.study_progress_changed.emit(study_id)
	if not already_mastered:
		EventBus.toast_requested.emit("Estudo dominado: +1 Sabedoria e +" + NumberFormat.format(reward) + " de Fé")
	_request_save()
	return {
		"ok": true,
		"correct": true,
		"rewarded": rewarded,
		"faith": reward if rewarded else 0.0,
		"wisdom": 1 if rewarded else 0,
		"explanation": str(question.get("explanation", "Resposta correta.")),
	}

func _claim_mastery_rewards() -> void:
	var groups: Dictionary = {}
	for study in EstudosBiblicos.all():
		var group_id := str(study.get("era_group", ""))
		if not groups.has(group_id):
			groups[group_id] = []
		groups[group_id].append(study)

	for group_id in groups:
		if str(group_id).is_empty():
			continue
		var complete := true
		for study in groups[group_id]:
			var question_id := str(study.get("question", {}).get("id", ""))
			if question_id not in _list("questoesCorretas"):
				complete = false
				break
		if complete:
			var page_id := str(group_id)
			_append_once("paginasIluminadas", page_id)
			if _claim_reward("mastery:era:" + page_id, 0.0, ERA_MASTERY_WISDOM):
				EventBus.toast_requested.emit("Página Iluminada concluída: +2 Sabedoria")
				Economy.recompute_multiplicadores()

	var all_complete := true
	for study in EstudosBiblicos.all():
		var question_id := str(study.get("question", {}).get("id", ""))
		if question_id not in _list("questoesCorretas"):
			all_complete = false
			break
	if all_complete and EstudosBiblicos.count() > 0:
		GameState.estudo_progresso.titulo = "Leitor da Jornada Completa"
		if _claim_reward("mastery:journey", 0.0, JOURNEY_MASTERY_WISDOM):
			EventBus.toast_requested.emit("Todos os estudos concluídos: Leitor da Jornada Completa")

func buy_knowledge(knowledge_id: String) -> Dictionary:
	var knowledge := Conhecimentos.get_data(knowledge_id)
	if knowledge.is_empty():
		return {"ok": false, "reason": "missing"}
	if knowledge_id in GameState.conhecimentos_comprados:
		return {"ok": false, "reason": "owned"}
	if not _knowledge_requirements_met(knowledge, GameState.conhecimentos_comprados):
		return {"ok": false, "reason": "prerequisite"}
	var cost := int(knowledge.get("cost", 0))
	if GameState.sabedoria < cost:
		return {"ok": false, "reason": "insufficient"}
	GameState.sabedoria -= cost
	GameState.conhecimentos_comprados.append(knowledge_id)
	if _knowledge_requirements_met(knowledge, GameState.conhecimentos_ativos):
		GameState.conhecimentos_ativos.append(knowledge_id)
	Economy.recompute_multiplicadores()
	EventBus.wisdom_changed.emit(GameState.sabedoria)
	EventBus.knowledge_purchased.emit(knowledge_id)
	EventBus.knowledge_activation_changed.emit(knowledge_id)
	EventBus.study_progress_changed.emit("")
	EventBus.toast_requested.emit("Conhecimento adquirido: " + str(knowledge.get("title", knowledge_id)))
	_request_save()
	return {"ok": true, "cost": cost, "active": knowledge_id in GameState.conhecimentos_ativos}

func can_purchase_knowledge(knowledge_id: String) -> bool:
	var knowledge := Conhecimentos.get_data(knowledge_id)
	return not knowledge.is_empty() and knowledge_id not in GameState.conhecimentos_comprados and _knowledge_requirements_met(knowledge, GameState.conhecimentos_comprados) and GameState.sabedoria >= int(knowledge.get("cost", 0))

func can_activate_knowledge(knowledge_id: String) -> bool:
	var knowledge := Conhecimentos.get_data(knowledge_id)
	return not knowledge.is_empty() and knowledge_id in GameState.conhecimentos_comprados and knowledge_id not in GameState.conhecimentos_ativos and _knowledge_requirements_met(knowledge, GameState.conhecimentos_ativos)

func set_knowledge_active(knowledge_id: String, should_be_active: bool) -> Dictionary:
	var knowledge := Conhecimentos.get_data(knowledge_id)
	if knowledge.is_empty() or knowledge_id not in GameState.conhecimentos_comprados:
		return {"ok": false, "reason": "missing"}
	var was_active := knowledge_id in GameState.conhecimentos_ativos
	if should_be_active:
		if was_active:
			return {"ok": true, "changed": false}
		if not _knowledge_requirements_met(knowledge, GameState.conhecimentos_ativos):
			return {"ok": false, "reason": "inactive_prerequisite"}
		GameState.conhecimentos_ativos.append(knowledge_id)
	else:
		if not was_active:
			return {"ok": true, "changed": false}
		GameState.conhecimentos_ativos.erase(knowledge_id)
		_prune_invalid_active_knowledge()
	Economy.recompute_multiplicadores()
	EventBus.knowledge_activation_changed.emit(knowledge_id)
	EventBus.study_progress_changed.emit("")
	_request_save()
	return {"ok": true, "changed": true, "active": should_be_active}

func clear_active_knowledge() -> bool:
	if GameState.conhecimentos_ativos.is_empty():
		return false
	GameState.conhecimentos_ativos.clear()
	Economy.recompute_multiplicadores()
	EventBus.knowledge_activation_changed.emit("")
	EventBus.study_progress_changed.emit("")
	_request_save()
	return true

func _knowledge_requirements_met(knowledge: Dictionary, source: Array) -> bool:
	for required_id in Conhecimentos.get_requires(knowledge):
		if str(required_id) not in source:
			return false
	var requires_any := Conhecimentos.get_requires_any(knowledge)
	if not requires_any.is_empty():
		for required_id in requires_any:
			if str(required_id) in source:
				return true
		return false
	return true

func _prune_invalid_active_knowledge() -> void:
	var changed := true
	while changed:
		changed = false
		for active_id in GameState.conhecimentos_ativos.duplicate():
			var knowledge := Conhecimentos.get_data(str(active_id))
			if knowledge.is_empty() or not _knowledge_requirements_met(knowledge, GameState.conhecimentos_ativos):
				GameState.conhecimentos_ativos.erase(active_id)
				changed = true

func get_progress_summary() -> Dictionary:
	var total := EstudosBiblicos.count()
	var mastered := 0
	for study in EstudosBiblicos.all():
		if get_study_state(str(study.id)) == "mastered":
			mastered += 1
	var unread := 0
	for study_id in _list("desbloqueados"):
		if study_id not in _list("leiturasConcluidas"):
			unread += 1
	return {
		"total": total,
		"unlocked": _list("desbloqueados").size(),
		"read": _list("leiturasConcluidas").size(),
		"mastered": mastered,
		"unread": unread,
		"wisdom": GameState.sabedoria,
		"wisdom_total": GameState.sabedoria_total,
		"pages": _list("paginasIluminadas").duplicate(),
		"title": str(GameState.estudo_progresso.get("titulo", "")),
		"purchased_knowledge": GameState.conhecimentos_comprados.duplicate(),
		"conhecimentos_comprados": GameState.conhecimentos_comprados.duplicate(),
		"active_knowledge": GameState.conhecimentos_ativos.duplicate(),
		"read_chapters": _list("capitulosLidos").size(),
	}

func set_last_passage(book: String, chapter: int, verse: int = 1) -> void:
	GameState.estudo_progresso.ultimaPassagem = {"book": book, "chapter": chapter, "verse": verse}
	_request_save()

func toggle_bookmark(passage_id: String) -> bool:
	var bookmarks := _list("marcadores")
	if passage_id in bookmarks:
		bookmarks.erase(passage_id)
		_request_save()
		return false
	bookmarks.append(passage_id)
	_request_save()
	return true

func mark_chapter_read(book: String, chapter: int) -> Dictionary:
	if book.is_empty() or chapter < 1 or BibleTextProvider.get_chapter(book, chapter).is_empty():
		return {"ok": false, "reason": "missing"}
	var chapter_id := book.to_upper() + ":" + str(chapter)
	var added := _append_once("capitulosLidos", chapter_id)
	set_last_passage(book.to_upper(), chapter, 1)
	if added:
		EventBus.study_progress_changed.emit("bible:" + chapter_id)
		EventBus.toast_requested.emit("Capítulo marcado como lido")
		_request_save()
	return {"ok": true, "new": added, "chapter_id": chapter_id}

func is_chapter_read(book: String, chapter: int) -> bool:
	return book.to_upper() + ":" + str(chapter) in _list("capitulosLidos")

func get_read_chapter_count() -> int:
	return _list("capitulosLidos").size()

func _request_save() -> void:
	if _mutations_suspended:
		return
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null:
		save_system.save_game()

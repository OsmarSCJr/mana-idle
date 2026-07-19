extends Node

func _ready() -> void:
	SaveSystem.set_persistence_enabled(false)
	await get_tree().process_frame
	var ok := true
	var study_errors := EstudosBiblicos.validate_data()
	var knowledge_errors := Conhecimentos.validate_data()
	ok = ok and EstudosBiblicos.count() == 36 and study_errors.is_empty()
	ok = ok and Conhecimentos.count() == 30 and knowledge_errors.is_empty()
	print("[S0] catalogos estudos=", EstudosBiblicos.count(), " erros=", study_errors, " conhecimentos=", Conhecimentos.count(), " erros=", knowledge_errors)

	GameState.fe = 1.0e8
	GameState.fe_total_vida = 0.0
	GameState.fe_total_historica = 0.0
	GameState.sabedoria = 0
	GameState.sabedoria_total = 0
	GameState.estudo_progresso = GameState._default_study_progress()
	GameState.conhecimentos_comprados.clear()
	GameState.aventuras_desbloqueadas = ["jornada"]
	GameState.aventuras_concluidas.clear()
	GameState.maior_qtd_gerador.clear()
	GameState.upgrades_comprados.clear()
	GameState.dadivas_compradas.clear()
	GameState._init_geradores()
	Economy.recompute_multiplicadores()

	var first_study: Dictionary = EstudosBiblicos.get_data("journey_genesis_01")
	ok = ok and not first_study.is_empty()
	ok = ok and StudySystem.refresh_unlocks(false) == 0
	var first_requirement: int = int(first_study.get("required_quantity", 25))
	ok = ok and GameState.buy_generator(1, first_requirement)
	ok = ok and StudySystem.is_unlocked(first_study.id)
	print("[S1] desbloqueio por ", first_requirement, " unidades=", StudySystem.is_unlocked(first_study.id))

	var faith_before := GameState.fe
	var reading: Dictionary = StudySystem.complete_reading(first_study.id)
	var reading_repeat: Dictionary = StudySystem.complete_reading(first_study.id)
	ok = ok and reading.get("rewarded", false) and not reading_repeat.get("rewarded", true)
	ok = ok and GameState.fe > faith_before
	print("[S2] leitura unica=", reading, " repeticao=", reading_repeat)

	var question: Dictionary = first_study.question
	var wrong_option := ""
	for option in question.options:
		if str(option.id) != str(question.correct_option_id):
			wrong_option = str(option.id)
			break
	var wrong: Dictionary = StudySystem.submit_answer(question.id, wrong_option)
	var wisdom_before := GameState.sabedoria
	var correct: Dictionary = StudySystem.submit_answer(question.id, question.correct_option_id)
	var correct_repeat: Dictionary = StudySystem.submit_answer(question.id, question.correct_option_id)
	ok = ok and not wrong.get("correct", true)
	ok = ok and correct.get("correct", false) and correct.get("rewarded", false)
	ok = ok and not correct_repeat.get("rewarded", true)
	ok = ok and GameState.sabedoria == wisdom_before + 1
	print("[S3] quiz errado/correto/idempotente=", wrong.get("correct"), "/", correct, "/", correct_repeat)

	GameState.sabedoria = 2
	var offline_before := Economy.get_offline_mult()
	var knowledge: Dictionary = StudySystem.buy_knowledge("knowledge_good_seed")
	ok = ok and knowledge.get("ok", false)
	ok = ok and is_equal_approx(Economy.get_offline_mult(), offline_before * 1.05)
	print("[S4] conhecimento persistente=", knowledge, " offline=", Economy.get_offline_mult())

	var passage: Dictionary = BibleTextProvider.get_passage("GEN", 1, 1, 5)
	var books: Array = BibleTextProvider.get_books()
	ok = ok and books.size() == 66 and passage.get("verses", []).size() == 5
	ok = ok and not str(passage.get("text", "")).is_empty()
	var chapter_mark: Dictionary = StudySystem.mark_chapter_read("GEN", 1)
	ok = ok and chapter_mark.get("new", false) and StudySystem.is_chapter_read("GEN", 1)
	print("[S5] Biblia offline livros=", books.size(), " passagem=", passage.get("reference"), " lido=", chapter_mark)

	var save: Dictionary = GameState.get_save_data()
	GameState.sabedoria = 0
	GameState.estudo_progresso = GameState._default_study_progress()
	GameState.conhecimentos_comprados.clear()
	GameState.load_save_data(save)
	ok = ok and GameState.sabedoria == 1 # Boa Semente custa 1 dos 2 pontos.
	ok = ok and "knowledge_good_seed" in GameState.conhecimentos_comprados
	ok = ok and first_study.id in GameState.estudo_progresso.leiturasConcluidas
	ok = ok and StudySystem.is_chapter_read("GEN", 1)
	print("[S6] roundtrip save v10 conhecimento=", GameState.conhecimentos_comprados, " capitulos=", StudySystem.get_read_chapter_count())

	GameState.fe_total_historica = 3.0e14
	GameState.fe = 3.0e14
	var can_unlock_adventure := GameState.can_unlock_adventure("vida_cristo")
	var unlocked_adventure := GameState.unlock_adventure("vida_cristo")
	var entered_adventure := GameState.set_active_adventure("vida_cristo", false)
	ok = can_unlock_adventure and unlocked_adventure and entered_adventure and GameState.is_unlocked(13) and ok
	print("[S7] aventura Vida de Cristo desbloqueada=", GameState.is_adventure_unlocked("vida_cristo"))

	var old_save := {
		"version": 1,
		"fe": 123.0,
		"santos": 2,
		"feTotalVida": 45.0,
		"geradores": {},
	}
	GameState.load_save_data(old_save)
	ok = ok and GameState.sabedoria == 0
	ok = ok and GameState.estudo_progresso.leiturasConcluidas.is_empty()
	ok = ok and GameState.aventuras_desbloqueadas == ["jornada"]
	ok = ok and is_equal_approx(GameState.fe, GameState.FE_INICIAL)
	print("[S8] reset alpha pre-v10 sabedoria=", GameState.sabedoria, " aventuras=", GameState.aventuras_desbloqueadas)

	print("=== STUDY SMOKE TEST ", ("PASS" if ok else "FAIL"), " ===")
	get_tree().quit(0 if ok else 1)

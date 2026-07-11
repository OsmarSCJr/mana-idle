extends Node

## Catálogo editorial dos estudos da Jornada Principal e das duas Aventuras.
##
## Os IDs são persistidos no save e, por isso, são imutáveis. O catálogo contém
## apenas referências e material didático original; o texto bíblico é fornecido
## separadamente pelo BibleTextProvider.

const REQUIRED_QUANTITY := 10
const READING_REWARD_RATIO := 0.01
const QUIZ_REWARD_RATIO := 0.02
const READING_REWARD_MINIMUM := 10.0
const QUIZ_REWARD_MINIMUM := 20.0

const DADOS: Array = [
	{
		"id": "journey_genesis_01",
		"generator_id": 1,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma luz para começar",
		"reference": "Gênesis 1:1–5",
		"passage": {"book": "GEN", "chapter": 1, "verse_from": 1, "verse_to": 5},
		"context": "A narrativa bíblica começa com a criação ainda sem forma e envolta em escuridão. A luz inaugura ordem, distinção e a primeira medida do tempo.",
		"reflection": "Que pequena ação pode trazer clareza a algo confuso hoje?",
		"question": {
			"id": "journey_genesis_01_q1",
			"prompt": "Qual separação marca o primeiro dia da criação?",
			"options": [
				{"id": "earth_sea", "text": "Terra e mar"},
				{"id": "light_dark", "text": "Luz e escuridão"},
				{"id": "animals_plants", "text": "Animais e plantas"},
			],
			"correct_option_id": "light_dark",
			"explanation": "A passagem apresenta a luz, sua distinção das trevas e a nomeação de Dia e Noite.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "genesis",
	},
	{
		"id": "journey_genesis_02",
		"generator_id": 2,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Cuidar do jardim",
		"reference": "Gênesis 2:8–17",
		"passage": {"book": "GEN", "chapter": 2, "verse_from": 8, "verse_to": 17},
		"context": "O jardim é apresentado como lugar de beleza, provisão e responsabilidade. O ser humano recebe liberdade para desfrutá-lo e uma tarefa concreta de cuidado.",
		"reflection": "O que foi confiado aos seus cuidados nesta fase da vida?",
		"question": {
			"id": "journey_genesis_02_q1",
			"prompt": "Qual tarefa foi confiada ao ser humano no jardim?",
			"options": [
				{"id": "build_city", "text": "Construir uma cidade"},
				{"id": "cultivate_guard", "text": "Cultivar e guardar o jardim"},
				{"id": "name_rivers", "text": "Dar nome aos rios"},
			],
			"correct_option_id": "cultivate_guard",
			"explanation": "O texto afirma que o ser humano foi colocado no jardim para cultivá-lo e guardá-lo.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "genesis",
	},
	{
		"id": "journey_genesis_03",
		"generator_id": 3,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma aliança para recomeçar",
		"reference": "Gênesis 9:8–17",
		"passage": {"book": "GEN", "chapter": 9, "verse_from": 8, "verse_to": 17},
		"context": "Depois do dilúvio, a história da arca culmina em uma aliança que inclui Noé, sua família e todos os seres vivos. O sinal visível aponta para memória e esperança.",
		"reflection": "Que sinal ajuda você a recordar compromissos importantes?",
		"question": {
			"id": "journey_genesis_03_q1",
			"prompt": "Qual sinal é apresentado como lembrança da aliança?",
			"options": [
				{"id": "rainbow", "text": "O arco nas nuvens"},
				{"id": "olive_tree", "text": "Uma oliveira"},
				{"id": "stone_altar", "text": "Um altar de pedras"},
			],
			"correct_option_id": "rainbow",
			"explanation": "O arco colocado nas nuvens é descrito como sinal da aliança entre Deus, a humanidade e os seres vivos.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "genesis",
	},
	{
		"id": "journey_genesis_04",
		"generator_id": 4,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Quando o projeto perde o propósito",
		"reference": "Gênesis 11:1–9",
		"passage": {"book": "GEN", "chapter": 11, "verse_from": 1, "verse_to": 9},
		"context": "Babel retrata uma comunidade capaz de cooperar e construir, mas movida pelo desejo de exaltar o próprio nome e impedir sua dispersão.",
		"reflection": "Como manter um objetivo coletivo sem perder de vista seu propósito?",
		"question": {
			"id": "journey_genesis_04_q1",
			"prompt": "Segundo a passagem, por que o povo quis construir a cidade e a torre?",
			"options": [
				{"id": "shelter_flood", "text": "Para se proteger de outra inundação"},
				{"id": "name_avoid_scattering", "text": "Para fazer um nome e não se espalhar"},
				{"id": "observe_stars", "text": "Para observar as estrelas"},
			],
			"correct_option_id": "name_avoid_scattering",
			"explanation": "Os construtores queriam tornar célebre o próprio nome e evitar que fossem espalhados pela terra.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "genesis",
	},
	{
		"id": "journey_exodus_05",
		"generator_id": 5,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Provisão para cada dia",
		"reference": "Êxodo 16:1–21",
		"passage": {"book": "EXO", "chapter": 16, "verse_from": 1, "verse_to": 21},
		"context": "No deserto, o povo aprende a recolher o necessário para cada dia. O maná associa provisão à confiança e ao cuidado com o excesso.",
		"reflection": "O que significa reconhecer o suficiente em meio às preocupações de amanhã?",
		"question": {
			"id": "journey_exodus_05_q1",
			"prompt": "O que aconteceu com o maná guardado indevidamente para o dia seguinte?",
			"options": [
				{"id": "became_gold", "text": "Transformou-se em ouro"},
				{"id": "remained_fresh", "text": "Permaneceu fresco"},
				{"id": "spoiled", "text": "Criou vermes e estragou"},
			],
			"correct_option_id": "spoiled",
			"explanation": "Quando alguns guardaram o alimento contra a orientação recebida, ele criou vermes e cheirou mal.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "exodus_conquest",
	},
	{
		"id": "journey_exodus_06",
		"generator_id": 6,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Um caminho entre as águas",
		"reference": "Êxodo 14:10–31",
		"passage": {"book": "EXO", "chapter": 14, "verse_from": 10, "verse_to": 31},
		"context": "Entre o mar e o exército egípcio, o povo se vê sem saída. A narrativa combina confiança, movimento e uma travessia que parecia impossível.",
		"reflection": "Qual é o próximo passo possível quando a solução completa ainda não está visível?",
		"question": {
			"id": "journey_exodus_06_q1",
			"prompt": "Diante do medo do povo, qual foi a primeira orientação de Moisés?",
			"options": [
				{"id": "return_egypt", "text": "Retornar ao Egito"},
				{"id": "stand_firm", "text": "Não temer, permanecer firme e observar o livramento"},
				{"id": "build_boats", "text": "Construir barcos imediatamente"},
			],
			"correct_option_id": "stand_firm",
			"explanation": "Moisés pede que o povo não tema, permaneça firme e veja o livramento; em seguida, a caminhada prossegue.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "exodus_conquest",
	},
	{
		"id": "journey_exodus_07",
		"generator_id": 7,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Persistência ao redor das muralhas",
		"reference": "Josué 6:1–20",
		"passage": {"book": "JOS", "chapter": 6, "verse_from": 1, "verse_to": 20},
		"context": "A tomada de Jericó é narrada como uma ação comunitária repetida por vários dias. O resultado chega depois de disciplina, espera e cooperação.",
		"reflection": "Que prática simples merece constância antes que seus resultados apareçam?",
		"question": {
			"id": "journey_exodus_07_q1",
			"prompt": "Quantas voltas o povo deu ao redor da cidade no sétimo dia?",
			"options": [
				{"id": "one", "text": "Uma volta"},
				{"id": "three", "text": "Três voltas"},
				{"id": "seven", "text": "Sete voltas"},
			],
			"correct_option_id": "seven",
			"explanation": "Durante seis dias houve uma volta por dia; no sétimo dia, o povo contornou Jericó sete vezes.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "exodus_conquest",
	},
	{
		"id": "journey_exodus_08",
		"generator_id": 8,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Força com propósito",
		"reference": "Juízes 13:1–5",
		"passage": {"book": "JDG", "chapter": 13, "verse_from": 1, "verse_to": 5},
		"context": "Antes do nascimento de Sansão, sua história é ligada a uma vocação e a uma consagração particular. O sinal externo apontava para uma responsabilidade maior.",
		"reflection": "Como seus talentos podem servir a um propósito que vai além de você?",
		"question": {
			"id": "journey_exodus_08_q1",
			"prompt": "Qual sinal estava ligado à consagração de Sansão desde o nascimento?",
			"options": [
				{"id": "gold_bracelet", "text": "Um bracelete de ouro"},
				{"id": "uncut_hair", "text": "O cabelo não seria cortado"},
				{"id": "blue_cloak", "text": "Um manto azul"},
			],
			"correct_option_id": "uncut_hair",
			"explanation": "A passagem declara que navalha não passaria sobre a cabeça do menino, ligado à sua consagração como nazireu.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "exodus_conquest",
	},
	{
		"id": "journey_kingdom_09",
		"generator_id": 9,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Coragem com o que se tem",
		"reference": "1 Samuel 17:32–50",
		"passage": {"book": "1SA", "chapter": 17, "verse_from": 32, "verse_to": 50},
		"context": "Davi enfrenta Golias sem adotar a armadura de Saul. Ele segue com instrumentos que conhecia e com a convicção que orientava sua coragem.",
		"reflection": "Quais recursos simples e já conhecidos podem ajudar você a enfrentar um grande desafio?",
		"question": {
			"id": "journey_kingdom_09_q1",
			"prompt": "Que instrumento Davi usou para lançar a pedra contra Golias?",
			"options": [
				{"id": "bow", "text": "Um arco"},
				{"id": "sling", "text": "Uma funda"},
				{"id": "spear", "text": "Uma lança"},
			],
			"correct_option_id": "sling",
			"explanation": "Davi colocou uma pedra na funda e a lançou, atingindo Golias na testa.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "kingdom",
	},
	{
		"id": "journey_kingdom_10",
		"generator_id": 10,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Um templo e uma presença maior",
		"reference": "1 Reis 8:22–30",
		"passage": {"book": "1KI", "chapter": 8, "verse_from": 22, "verse_to": 30},
		"context": "Na dedicação do templo, Salomão valoriza o lugar construído e, ao mesmo tempo, reconhece que a presença divina não pode ser limitada por uma construção.",
		"reflection": "Como valorizar símbolos e lugares importantes sem confundi-los com aquilo que representam?",
		"question": {
			"id": "journey_kingdom_10_q1",
			"prompt": "O que Salomão reconheceu sobre Deus durante sua oração?",
			"options": [
				{"id": "limited_temple", "text": "Que habitaria somente no templo"},
				{"id": "not_contained", "text": "Que nem os céus poderiam contê-lo"},
				{"id": "absent_city", "text": "Que permaneceria distante da cidade"},
			],
			"correct_option_id": "not_contained",
			"explanation": "Salomão afirma que nem os céus podem conter Deus, muito menos o templo que ele havia construído.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "kingdom",
	},
	{
		"id": "journey_kingdom_11",
		"generator_id": 11,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma nova direção",
		"reference": "Jonas 1:1–3",
		"passage": {"book": "JON", "chapter": 1, "verse_from": 1, "verse_to": 3},
		"context": "Jonas recebe uma missão clara, mas parte na direção oposta. O início de sua história abre espaço para pensar em fuga, aprendizado e mudança de rota.",
		"reflection": "Existe alguma responsabilidade da qual você tem se afastado e que merece ser reconsiderada?",
		"question": {
			"id": "journey_kingdom_11_q1",
			"prompt": "Para qual cidade Jonas foi enviado?",
			"options": [
				{"id": "nineveh", "text": "Nínive"},
				{"id": "jerusalem", "text": "Jerusalém"},
				{"id": "damascus", "text": "Damasco"},
			],
			"correct_option_id": "nineveh",
			"explanation": "Jonas recebeu a ordem de ir a Nínive, embora inicialmente tenha embarcado na direção contrária.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "kingdom",
	},
	{
		"id": "journey_kingdom_12",
		"generator_id": 12,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Convicção sob pressão",
		"reference": "Daniel 3:8–30",
		"passage": {"book": "DAN", "chapter": 3, "verse_from": 8, "verse_to": 30},
		"context": "Sadraque, Mesaque e Abede-Nego enfrentam uma ordem que contrariava suas convicções. A passagem destaca firmeza mesmo quando o resultado ainda era incerto.",
		"reflection": "Quais valores você deseja preservar quando existe pressão para agir de outro modo?",
		"question": {
			"id": "journey_kingdom_12_q1",
			"prompt": "O que os três jovens se recusaram a fazer?",
			"options": [
				{"id": "leave_babylon", "text": "Deixar a Babilônia"},
				{"id": "serve_army", "text": "Servir no exército"},
				{"id": "worship_image", "text": "Adorar a imagem de ouro"},
			],
			"correct_option_id": "worship_image",
			"explanation": "Eles se recusaram a servir aos deuses do rei e a adorar a imagem de ouro levantada por Nabucodonosor.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "kingdom",
	},
	{
		"id": "journey_christ_13",
		"generator_id": 13,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Esperança em simplicidade",
		"reference": "Lucas 2:1–20",
		"passage": {"book": "LUK", "chapter": 2, "verse_from": 1, "verse_to": 20},
		"context": "O nascimento de Jesus acontece longe de sinais de prestígio. Pastores recebem a notícia e encontram uma criança em circunstâncias simples, reconhecida como motivo de alegria.",
		"reflection": "Que acontecimentos discretos merecem mais atenção e gratidão em sua caminhada?",
		"question": {
			"id": "journey_christ_13_q1",
			"prompt": "Qual sinal ajudaria os pastores a reconhecer a criança?",
			"options": [
				{"id": "royal_crown", "text": "Uma coroa real"},
				{"id": "manger", "text": "Um bebê envolto em panos e deitado numa manjedoura"},
				{"id": "bright_temple", "text": "Uma luz sobre o templo"},
			],
			"correct_option_id": "manger",
			"explanation": "O sinal anunciado aos pastores foi encontrar o bebê envolto em panos e deitado numa manjedoura.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_birth",
	},
	{
		"id": "journey_christ_14",
		"generator_id": 14,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Cuidado em terra estrangeira",
		"reference": "Mateus 2:13–15",
		"passage": {"book": "MAT", "chapter": 2, "verse_from": 13, "verse_to": 15},
		"context": "Diante de uma ameaça, José recebe a orientação de proteger a criança e sua mãe. A família parte durante a noite e vive por um tempo em terra estrangeira.",
		"reflection": "Como podemos acolher e proteger pessoas que precisaram deixar seu lugar de origem?",
		"question": {
			"id": "journey_christ_14_q1",
			"prompt": "O que José foi orientado a fazer em sonho?",
			"options": [
				{"id": "remain_bethlehem", "text": "Permanecer em Belém"},
				{"id": "go_jerusalem", "text": "Levar a família a Jerusalém"},
				{"id": "flee_egypt", "text": "Levar a criança e sua mãe para o Egito"},
			],
			"correct_option_id": "flee_egypt",
			"explanation": "Um anjo orientou José a levar a criança e sua mãe ao Egito e permanecer ali até uma nova instrução.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_birth",
	},
	{
		"id": "journey_christ_15",
		"generator_id": 15,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "O começo de uma missão",
		"reference": "Mateus 3:13–17",
		"passage": {"book": "MAT", "chapter": 3, "verse_from": 13, "verse_to": 17},
		"context": "Jesus procura João no Jordão e é batizado antes do início de seu ministério público. A cena reúne água, a descida do Espírito e uma voz de aprovação.",
		"reflection": "Que confirmação ajuda você a começar uma responsabilidade com confiança e humildade?",
		"question": {
			"id": "journey_christ_15_q1",
			"prompt": "De que modo o Espírito é descrito descendo sobre Jesus?",
			"options": [
				{"id": "like_dove", "text": "Como uma pomba"},
				{"id": "like_rain", "text": "Como chuva"},
				{"id": "like_cloud", "text": "Como uma nuvem"},
			],
			"correct_option_id": "like_dove",
			"explanation": "Após o batismo, o Espírito de Deus é descrito descendo como uma pomba sobre Jesus.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_birth",
	},
	{
		"id": "journey_christ_16",
		"generator_id": 16,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "A alegria preservada",
		"reference": "João 2:1–11",
		"passage": {"book": "JHN", "chapter": 2, "verse_from": 1, "verse_to": 11},
		"context": "Em uma celebração de casamento, a falta de vinho ameaçava constranger os anfitriões. O primeiro sinal narrado por João acontece no cotidiano de uma comunidade reunida.",
		"reflection": "Como a atenção às necessidades discretas pode preservar a dignidade e a alegria de outras pessoas?",
		"question": {
			"id": "journey_christ_16_q1",
			"prompt": "No sinal realizado em Caná, em que a água foi transformada?",
			"options": [
				{"id": "oil", "text": "Azeite"},
				{"id": "wine", "text": "Vinho"},
				{"id": "milk", "text": "Leite"},
			],
			"correct_option_id": "wine",
			"explanation": "A água colocada nas talhas foi servida como vinho, sinal que revelou a glória de Jesus aos discípulos.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_birth",
	},
	{
		"id": "journey_christ_17",
		"generator_id": 17,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma felicidade que transforma",
		"reference": "Mateus 5:1–12",
		"passage": {"book": "MAT", "chapter": 5, "verse_from": 1, "verse_to": 12},
		"context": "As bem-aventuranças abrem o Sermão do Monte com uma visão de felicidade ligada à misericórdia, à justiça, à paz e à perseverança.",
		"reflection": "Qual bem-aventurança mais desafia a maneira como você entende uma vida bem-sucedida?",
		"question": {
			"id": "journey_christ_17_q1",
			"prompt": "Como são chamados aqueles que promovem a paz?",
			"options": [
				{"id": "rulers", "text": "Governantes da terra"},
				{"id": "children_god", "text": "Filhos de Deus"},
				{"id": "keepers_city", "text": "Guardiões da cidade"},
			],
			"correct_option_id": "children_god",
			"explanation": "Na passagem, os pacificadores são chamados felizes porque serão chamados filhos de Deus.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_ministry",
	},
	{
		"id": "journey_christ_18",
		"generator_id": 18,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "O pouco colocado em comum",
		"reference": "João 6:1–14",
		"passage": {"book": "JHN", "chapter": 6, "verse_from": 1, "verse_to": 14},
		"context": "Diante de uma grande multidão, os discípulos enxergam recursos insuficientes. A pequena refeição de um menino se torna o ponto de partida para alimentar muita gente.",
		"reflection": "Que recurso modesto você pode colocar a serviço de uma necessidade coletiva?",
		"question": {
			"id": "journey_christ_18_q1",
			"prompt": "Que alimento o menino tinha antes da multiplicação?",
			"options": [
				{"id": "five_two", "text": "Cinco pães de cevada e dois peixes"},
				{"id": "seven_one", "text": "Sete pães e um peixe"},
				{"id": "twelve_five", "text": "Doze pães e cinco peixes"},
			],
			"correct_option_id": "five_two",
			"explanation": "André menciona um menino com cinco pães de cevada e dois peixes, que são compartilhados com a multidão.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_ministry",
	},
	{
		"id": "journey_christ_19",
		"generator_id": 19,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma mão em meio ao vento",
		"reference": "Mateus 14:22–33",
		"passage": {"book": "MAT", "chapter": 14, "verse_from": 22, "verse_to": 33},
		"context": "Durante a travessia, os discípulos enfrentam vento e medo. Pedro dá alguns passos sobre as águas, vacila e encontra uma mão estendida quando pede ajuda.",
		"reflection": "A quem você pode pedir ajuda quando a coragem começa a ceder?",
		"question": {
			"id": "journey_christ_19_q1",
			"prompt": "O que Jesus fez quando Pedro começou a afundar?",
			"options": [
				{"id": "left_boat", "text": "Voltou sozinho para o barco"},
				{"id": "stilled_without_help", "text": "Apenas fez o vento parar"},
				{"id": "extended_hand", "text": "Estendeu a mão e o segurou"},
			],
			"correct_option_id": "extended_hand",
			"explanation": "Ao ouvir o pedido de Pedro, Jesus imediatamente estendeu a mão e o segurou.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_ministry",
	},
	{
		"id": "journey_christ_20",
		"generator_id": 20,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Escutar no alto do monte",
		"reference": "Mateus 17:1–8",
		"passage": {"book": "MAT", "chapter": 17, "verse_from": 1, "verse_to": 8},
		"context": "Pedro, Tiago e João acompanham Jesus ao monte e testemunham uma cena extraordinária. A experiência aponta para sua identidade e para o chamado a escutá-lo.",
		"reflection": "Que espaço de silêncio pode ajudar você a escutar antes de agir?",
		"question": {
			"id": "journey_christ_20_q1",
			"prompt": "Quais personagens apareceram conversando com Jesus?",
			"options": [
				{"id": "abraham_david", "text": "Abraão e Davi"},
				{"id": "moses_elijah", "text": "Moisés e Elias"},
				{"id": "isaiah_jeremiah", "text": "Isaías e Jeremias"},
			],
			"correct_option_id": "moses_elijah",
			"explanation": "Moisés e Elias aparecem conversando com Jesus durante a transfiguração.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_ministry",
	},
	{
		"id": "journey_christ_21",
		"generator_id": 21,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Esperança diante da pedra",
		"reference": "João 11:38–44",
		"passage": {"book": "JHN", "chapter": 11, "verse_from": 38, "verse_to": 44},
		"context": "No túmulo de Lázaro, o luto ainda é recente e a pedra parece marcar um fim. A narrativa combina a participação da comunidade com um chamado de vida.",
		"reflection": "Que gesto de cuidado pode ajudar alguém a retirar uma pedra em um momento de luto ou desânimo?",
		"question": {
			"id": "journey_christ_21_q1",
			"prompt": "Que chamado Jesus dirigiu a Lázaro?",
			"options": [
				{"id": "come_out", "text": "Venha para fora"},
				{"id": "remain_asleep", "text": "Permaneça dormindo"},
				{"id": "go_home", "text": "Volte para casa"},
			],
			"correct_option_id": "come_out",
			"explanation": "Jesus chamou Lázaro para fora do túmulo e depois pediu à comunidade que retirasse suas faixas.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_resurrection",
	},
	{
		"id": "journey_christ_22",
		"generator_id": 22,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Um rei que chega com humildade",
		"reference": "Mateus 21:1–11",
		"passage": {"book": "MAT", "chapter": 21, "verse_from": 1, "verse_to": 11},
		"context": "A entrada de Jesus em Jerusalém reúne expectativa pública e uma imagem de humildade. A multidão prepara o caminho e o recebe com aclamações.",
		"reflection": "Como exercer influência sem depender de ostentação ou superioridade?",
		"question": {
			"id": "journey_christ_22_q1",
			"prompt": "Qual aclamação a multidão dirigiu ao Filho de Davi?",
			"options": [
				{"id": "hosanna", "text": "Hosana"},
				{"id": "hallelujah_elijah", "text": "Viva Elias"},
				{"id": "glory_rome", "text": "Glória a Roma"},
			],
			"correct_option_id": "hosanna",
			"explanation": "A multidão clamava ‘Hosana ao Filho de Davi’ enquanto Jesus entrava na cidade.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_resurrection",
	},
	{
		"id": "journey_christ_23",
		"generator_id": 23,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Memória ao redor da mesa",
		"reference": "Lucas 22:14–20",
		"passage": {"book": "LUK", "chapter": 22, "verse_from": 14, "verse_to": 20},
		"context": "Na ceia antes de sua prisão, Jesus compartilha pão e cálice com os discípulos. A refeição torna-se um ato de memória, comunhão e aliança.",
		"reflection": "Que práticas ajudam sua comunidade a preservar memória, gratidão e compromisso?",
		"question": {
			"id": "journey_christ_23_q1",
			"prompt": "A que Jesus associou o cálice compartilhado?",
			"options": [
				{"id": "new_covenant", "text": "À nova aliança — o Novo Testamento em seu sangue"},
				{"id": "harvest_festival", "text": "A uma festa da colheita"},
				{"id": "journey_galilee", "text": "A uma viagem à Galileia"},
			],
			"correct_option_id": "new_covenant",
			"explanation": "Jesus apresenta o cálice como o Novo Testamento, ou nova aliança, em seu sangue, derramado em favor de outros.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_resurrection",
	},
	{
		"id": "journey_christ_24",
		"generator_id": 24,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Quando o fim se torna começo",
		"reference": "João 20:1–18",
		"passage": {"book": "JHN", "chapter": 20, "verse_from": 1, "verse_to": 18},
		"context": "Maria Madalena chega ao túmulo e encontra a pedra retirada. Sua tristeza se transforma quando ela reconhece Jesus e recebe a tarefa de contar aos discípulos.",
		"reflection": "Que notícia de esperança você pode compartilhar com alguém hoje?",
		"question": {
			"id": "journey_christ_24_q1",
			"prompt": "Quem foi ao túmulo ainda cedo e encontrou a pedra retirada?",
			"options": [
				{"id": "mary_magdalene", "text": "Maria Madalena"},
				{"id": "martha", "text": "Marta"},
				{"id": "elizabeth", "text": "Isabel"},
			],
			"correct_option_id": "mary_magdalene",
			"explanation": "João narra que Maria Madalena foi ao túmulo de madrugada e viu que a pedra havia sido retirada.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "christ_resurrection",
	},
	{
		"id": "journey_church_25",
		"generator_id": 25,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma mensagem em muitas línguas",
		"reference": "Atos 2:1–13",
		"passage": {"book": "ACT", "chapter": 2, "verse_from": 1, "verse_to": 13},
		"context": "No Pentecostes, pessoas de diferentes lugares ouvem a mensagem em suas próprias línguas. A diversidade não é apagada; torna-se parte da comunicação e do encontro.",
		"reflection": "Como adaptar sua comunicação para acolher pessoas com histórias e linguagens diferentes?",
		"question": {
			"id": "journey_church_25_q1",
			"prompt": "Por que os visitantes ficaram admirados com o que ouviam?",
			"options": [
				{"id": "own_languages", "text": "Cada um ouvia em sua própria língua"},
				{"id": "complete_silence", "text": "Todo o lugar ficou em silêncio"},
				{"id": "single_accent", "text": "Todos passaram a usar o mesmo sotaque"},
			],
			"correct_option_id": "own_languages",
			"explanation": "Os visitantes reconheciam suas próprias línguas sendo faladas por pessoas da Galileia.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "early_church",
	},
	{
		"id": "journey_church_26",
		"generator_id": 26,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma rota profundamente transformada",
		"reference": "Atos 9:1–19",
		"passage": {"book": "ACT", "chapter": 9, "verse_from": 1, "verse_to": 19},
		"context": "Saulo parte para Damasco com intenção de perseguir e termina a passagem acolhido por alguém que antes teria motivos para temê-lo. A transformação envolve confronto, espera e cuidado comunitário.",
		"reflection": "Como oferecer espaço responsável para que uma mudança verdadeira seja demonstrada?",
		"question": {
			"id": "journey_church_26_q1",
			"prompt": "Quem foi enviado para encontrar Saulo em Damasco?",
			"options": [
				{"id": "ananias", "text": "Ananias"},
				{"id": "barnabas", "text": "Barnabé"},
				{"id": "timothy", "text": "Timóteo"},
			],
			"correct_option_id": "ananias",
			"explanation": "Ananias recebeu a orientação de procurar Saulo, colocou as mãos sobre ele e o acolheu como irmão.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "early_church",
	},
	{
		"id": "journey_church_27",
		"generator_id": 27,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Enviados por uma comunidade",
		"reference": "Atos 13:1–12",
		"passage": {"book": "ACT", "chapter": 13, "verse_from": 1, "verse_to": 12},
		"context": "A missão de Barnabé e Saulo nasce em uma comunidade diversa que ora, discerne e os envia. O caminho também inclui resistência e a necessidade de clareza.",
		"reflection": "Que decisões importantes merecem discernimento e apoio de uma comunidade?",
		"question": {
			"id": "journey_church_27_q1",
			"prompt": "Quem foi separado para o trabalho descrito na passagem?",
			"options": [
				{"id": "peter_john", "text": "Pedro e João"},
				{"id": "barnabas_saul", "text": "Barnabé e Saulo"},
				{"id": "james_thomas", "text": "Tiago e Tomé"},
			],
			"correct_option_id": "barnabas_saul",
			"explanation": "Durante o culto e o jejum, Barnabé e Saulo foram separados e enviados para a obra indicada.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "early_church",
	},
	{
		"id": "journey_church_28",
		"generator_id": 28,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Aprender, examinar e praticar",
		"reference": "2 Timóteo 3:14–17",
		"passage": {"book": "2TI", "chapter": 3, "verse_from": 14, "verse_to": 17},
		"context": "A carta recorda a Timóteo o aprendizado recebido desde cedo e apresenta as Escrituras como recurso para formar, corrigir e preparar para boas obras.",
		"reflection": "Como transformar leitura e conhecimento em uma prática que beneficie outras pessoas?",
		"question": {
			"id": "journey_church_28_q1",
			"prompt": "Para quais finalidades a passagem considera útil a Escritura?",
			"options": [
				{"id": "teaching_correction", "text": "Ensinar, mostrar erros, corrigir e instruir"},
				{"id": "predict_dates", "text": "Prever datas e acontecimentos"},
				{"id": "replace_work", "text": "Substituir toda experiência prática"},
			],
			"correct_option_id": "teaching_correction",
			"explanation": "A Escritura é apresentada como útil para ensinar, mostrar erros, corrigir e instruir, preparando para boas obras.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "early_church",
	},
	{
		"id": "journey_history_29",
		"generator_id": 29,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Coragem sem abandonar a compaixão",
		"reference": "Atos 7:54–60",
		"passage": {"book": "ACT", "chapter": 7, "verse_from": 54, "verse_to": 60},
		"context": "A morte de Estêvão é narrada sem ocultar a violência sofrida. Mesmo sob agressão, suas últimas palavras incluem entrega e um pedido para que o pecado não fosse atribuído aos ofensores.",
		"reflection": "Como manter convicção e humanidade quando existe hostilidade, buscando também segurança e justiça?",
		"question": {
			"id": "journey_history_29_q1",
			"prompt": "O que Estêvão pediu em favor daqueles que o atacavam?",
			"options": [
				{"id": "greater_punishment", "text": "Que recebessem punição maior"},
				{"id": "not_charge_sin", "text": "Que aquele pecado não lhes fosse atribuído"},
				{"id": "leave_city", "text": "Que deixassem a cidade"},
			],
			"correct_option_id": "not_charge_sin",
			"explanation": "Em suas últimas palavras, Estêvão pediu que aquele pecado não fosse atribuído aos que o apedrejavam.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "expansion_reformation",
	},
	{
		"id": "journey_history_30",
		"generator_id": 30,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Fé e responsabilidade pública",
		"reference": "Romanos 13:1–7",
		"passage": {"book": "ROM", "chapter": 13, "verse_from": 1, "verse_to": 7},
		"context": "O Édito de Milão é um marco histórico posterior à Bíblia e não é descrito nesta passagem. Romanos 13 permite estudar responsabilidades civis no contexto do primeiro século; sua leitura responsável considera também consciência, justiça e o conjunto do testemunho bíblico, sem tratar qualquer governo como imune à avaliação moral.",
		"reflection": "Como equilibrar deveres civis, consciência e compromisso com a justiça em seu contexto?",
		"question": {
			"id": "journey_history_30_q1",
			"prompt": "Quais responsabilidades civis são mencionadas ao final da passagem?",
			"options": [
				{"id": "tax_respect_honor", "text": "Imposto, taxa, temor e honra"},
				{"id": "military_rank", "text": "Patente militar e posse de terras"},
				{"id": "travel_trade", "text": "Viagens e comércio marítimo"},
			],
			"correct_option_id": "tax_respect_honor",
			"explanation": "A conclusão orienta a dar a cada pessoa o que é devido, incluindo imposto, taxa, temor e honra.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "expansion_reformation",
	},
	{
		"id": "journey_history_31",
		"generator_id": 31,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma mensagem redescoberta",
		"reference": "Romanos 1:16–17",
		"passage": {"book": "ROM", "chapter": 1, "verse_from": 16, "verse_to": 17},
		"context": "Séculos depois de Paulo, Romanos teve papel importante nos debates da Reforma. A passagem apresenta o evangelho como poder de salvação e destaca uma justiça recebida pela fé.",
		"reflection": "Como retornar às fontes pode renovar a compreensão de uma tradição?",
		"question": {
			"id": "journey_history_31_q1",
			"prompt": "Segundo a citação apresentada por Paulo, como o justo viverá?",
			"options": [
				{"id": "by_faith", "text": "Pela fé"},
				{"id": "by_wealth", "text": "Pela riqueza"},
				{"id": "by_reputation", "text": "Pela reputação"},
			],
			"correct_option_id": "by_faith",
			"explanation": "Paulo afirma que a justiça de Deus é revelada pela fé e cita que o justo viverá pela fé.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "expansion_reformation",
	},
	{
		"id": "journey_history_32",
		"generator_id": 32,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma missão sem fronteiras",
		"reference": "Mateus 28:16–20",
		"passage": {"book": "MAT", "chapter": 28, "verse_from": 16, "verse_to": 20},
		"context": "No encerramento de Mateus, os discípulos recebem uma missão que atravessa povos e gerações: fazer discípulos, batizar e ensinar, acompanhados por uma promessa de presença.",
		"reflection": "Como compartilhar convicções com respeito, serviço e disposição para também aprender?",
		"question": {
			"id": "journey_history_32_q1",
			"prompt": "A quem os discípulos deveriam alcançar em sua missão?",
			"options": [
				{"id": "all_nations", "text": "Todas as nações"},
				{"id": "one_city", "text": "Somente uma cidade"},
				{"id": "rulers_only", "text": "Apenas governantes"},
			],
			"correct_option_id": "all_nations",
			"explanation": "A missão é dirigida a todas as nações e inclui ensinar a guardar o que Jesus ordenou.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "expansion_reformation",
	},
	{
		"id": "journey_revelation_33",
		"generator_id": 33,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Uma multidão de todos os povos",
		"reference": "Apocalipse 7:9–12",
		"passage": {"book": "REV", "chapter": 7, "verse_from": 9, "verse_to": 12},
		"context": "A visão reúne uma multidão impossível de contar diante do trono. Sua unidade não elimina as origens diversas que continuam sendo nomeadas.",
		"reflection": "Como construir unidade que celebre, em vez de apagar, a diversidade das pessoas?",
		"question": {
			"id": "journey_revelation_33_q1",
			"prompt": "De onde vinha a grande multidão vista por João?",
			"options": [
				{"id": "every_people", "text": "De todas as nações, tribos, povos e línguas"},
				{"id": "single_kingdom", "text": "De um único reino"},
				{"id": "one_family", "text": "De uma só família"},
			],
			"correct_option_id": "every_people",
			"explanation": "João descreve uma multidão de todas as nações, tribos, povos e línguas diante do trono.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "revelation_renewal",
	},
	{
		"id": "journey_revelation_34",
		"generator_id": 34,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Perseverança e primeiro amor",
		"reference": "Apocalipse 2:1–7",
		"passage": {"book": "REV", "chapter": 2, "verse_from": 1, "verse_to": 7},
		"context": "A mensagem à igreja de Éfeso reconhece trabalho, discernimento e perseverança, mas também chama a comunidade a recordar o amor que havia abandonado.",
		"reflection": "Que prática valiosa corre o risco de perder seu sentido quando é feita sem amor?",
		"question": {
			"id": "journey_revelation_34_q1",
			"prompt": "O que a comunidade de Éfeso havia abandonado?",
			"options": [
				{"id": "first_love", "text": "Seu primeiro amor"},
				{"id": "city_walls", "text": "As muralhas da cidade"},
				{"id": "written_letters", "text": "As cartas recebidas"},
			],
			"correct_option_id": "first_love",
			"explanation": "Apesar de elogiar sua perseverança, a mensagem adverte que a comunidade havia abandonado seu primeiro amor.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "revelation_renewal",
	},
	{
		"id": "journey_revelation_35",
		"generator_id": 35,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "O Cordeiro e o livro",
		"reference": "Apocalipse 5:1–10",
		"passage": {"book": "REV", "chapter": 5, "verse_from": 1, "verse_to": 10},
		"context": "A visão começa com tristeza porque ninguém parece capaz de abrir o livro selado. A resposta une as imagens de vitória e entrega na figura do Cordeiro.",
		"reflection": "Como a imagem de uma vitória alcançada pela entrega desafia ideias comuns sobre poder?",
		"question": {
			"id": "journey_revelation_35_q1",
			"prompt": "Quem é apresentado como digno de receber e abrir o livro?",
			"options": [
				{"id": "the_lamb", "text": "O Cordeiro"},
				{"id": "one_elder", "text": "Um dos anciãos"},
				{"id": "roman_emperor", "text": "O imperador romano"},
			],
			"correct_option_id": "the_lamb",
			"explanation": "João vê o Cordeiro receber o livro; o cântico declara que ele é digno de abri-lo.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "revelation_renewal",
	},
	{
		"id": "journey_revelation_36",
		"generator_id": 36,
		"required_quantity": REQUIRED_QUANTITY,
		"title": "Todas as coisas renovadas",
		"reference": "Apocalipse 21:1–7",
		"passage": {"book": "REV", "chapter": 21, "verse_from": 1, "verse_to": 7},
		"context": "A jornada termina com uma visão de nova criação e presença próxima. A esperança é expressa pelo fim da morte, do luto e da dor, e pela declaração de que tudo se faz novo.",
		"reflection": "Que pequeno gesto de restauração pode antecipar esperança no lugar onde você vive?",
		"question": {
			"id": "journey_revelation_36_q1",
			"prompt": "O que a visão afirma que já não existirá?",
			"options": [
				{"id": "death_mourning_pain", "text": "Morte, luto, clamor e dor"},
				{"id": "people_nations", "text": "Pessoas e nações"},
				{"id": "water_light", "text": "Água e luz"},
			],
			"correct_option_id": "death_mourning_pain",
			"explanation": "A visão anuncia que a morte, o luto, o clamor e a dor não existirão mais, pois as coisas anteriores passaram.",
		},
		"reward_ratios": {"reading": READING_REWARD_RATIO, "quiz": QUIZ_REWARD_RATIO},
		"reward_minimums": {"reading": READING_REWARD_MINIMUM, "quiz": QUIZ_REWARD_MINIMUM},
		"era_group": "revelation_renewal",
	},
]


func get_data(id: String) -> Dictionary:
	for study: Dictionary in DADOS:
		if study.get("id", "") == id:
			return study.duplicate(true)
	return {}


func all() -> Array:
	return DADOS.duplicate(true)


func count() -> int:
	return DADOS.size()


## Retorna uma lista vazia quando o catálogo está íntegro.
func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	var generator_ids := {}

	if DADOS.size() != 36:
		errors.append("O catálogo deve conter exatamente 36 estudos.")

	for index in range(DADOS.size()):
		var study: Dictionary = DADOS[index]
		var prefix := "Estudo %d" % (index + 1)
		var id := str(study.get("id", ""))
		var generator_id := int(study.get("generator_id", 0))

		if id.is_empty():
			errors.append("%s não possui id." % prefix)
		elif ids.has(id):
			errors.append("ID de estudo duplicado: %s." % id)
		else:
			ids[id] = true

		if generator_id < 1 or generator_id > 36:
			errors.append("%s possui generator_id inválido." % prefix)
		elif generator_ids.has(generator_id):
			errors.append("generator_id duplicado: %d." % generator_id)
		else:
			generator_ids[generator_id] = true

		if int(study.get("required_quantity", 0)) != REQUIRED_QUANTITY:
			errors.append("%s deve exigir %d unidades." % [prefix, REQUIRED_QUANTITY])
		if str(study.get("title", "")).is_empty() or str(study.get("reference", "")).is_empty():
			errors.append("%s deve possuir título e referência." % prefix)

		_validate_passage(study.get("passage", {}), prefix, errors)
		_validate_question(study.get("question", {}), prefix, errors)

		var ratios: Dictionary = study.get("reward_ratios", {})
		if float(ratios.get("reading", 0.0)) <= 0.0 or float(ratios.get("quiz", 0.0)) <= 0.0:
			errors.append("%s possui proporções de recompensa inválidas." % prefix)
		if str(study.get("era_group", "")).is_empty():
			errors.append("%s não possui era_group." % prefix)

	return errors


func is_valid() -> bool:
	return validate_data().is_empty()


func _validate_passage(value: Variant, prefix: String, errors: PackedStringArray) -> void:
	if value is not Dictionary:
		errors.append("%s possui passagem inválida." % prefix)
		return
	var passage: Dictionary = value
	if str(passage.get("book", "")).is_empty():
		errors.append("%s não informa o livro da passagem." % prefix)
	if int(passage.get("chapter", 0)) < 1:
		errors.append("%s possui capítulo inválido." % prefix)
	var verse_from := int(passage.get("verse_from", 0))
	var verse_to := int(passage.get("verse_to", 0))
	if verse_from < 1 or verse_to < verse_from:
		errors.append("%s possui intervalo de versículos inválido." % prefix)


func _validate_question(value: Variant, prefix: String, errors: PackedStringArray) -> void:
	if value is not Dictionary:
		errors.append("%s possui questão inválida." % prefix)
		return
	var question: Dictionary = value
	var question_id := str(question.get("id", ""))
	var correct_option_id := str(question.get("correct_option_id", ""))
	var options_value: Variant = question.get("options", [])
	if question_id.is_empty() or str(question.get("prompt", "")).is_empty():
		errors.append("%s possui questão sem id ou enunciado." % prefix)
	if options_value is not Array or options_value.size() < 2:
		errors.append("%s deve possuir pelo menos duas alternativas." % prefix)
		return
	var option_ids := {}
	for option_value: Variant in options_value:
		if option_value is not Dictionary:
			errors.append("%s possui alternativa inválida." % prefix)
			continue
		var option: Dictionary = option_value
		var option_id := str(option.get("id", ""))
		if option_id.is_empty() or str(option.get("text", "")).is_empty():
			errors.append("%s possui alternativa sem id ou texto." % prefix)
		elif option_ids.has(option_id):
			errors.append("%s possui alternativa duplicada: %s." % [prefix, option_id])
		else:
			option_ids[option_id] = true
	if correct_option_id.is_empty() or not option_ids.has(correct_option_id):
		errors.append("%s possui gabarito que não corresponde às alternativas." % prefix)
	if str(question.get("explanation", "")).is_empty():
		errors.append("%s não possui explicação da resposta." % prefix)

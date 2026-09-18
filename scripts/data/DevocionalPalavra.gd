extends Node

## Plano perpetuo "Palavra do Dia".
##
## Lista curada de passagens com uma meditacao curta. A escolha do dia e
## deterministica a partir do numero de dias desde a epoca Unix, entao o mesmo
## jogador ve a mesma leitura em qualquer aparelho e funciona offline, sem
## sorteio guardado no save.
##
## A lista e embaralhada por um passo coprimo com o tamanho, para que dias
## seguidos nao caiam em passagens vizinhas do mesmo livro.

const PLANO_ID: String = "palavra_do_dia"
const NOME: String = "Palavra do Dia"
const SUBTITULO: String = "Uma passagem por dia, sem fim"
const DESCRICAO: String = "Leitura curta e independente para todos os dias. Não termina: quando a lista fecha, recomeça em outra ordem."

const PASSAGENS: Array = [
	{"titulo": "Descanso", "book": "MAT", "chapter": 11, "verse_from": 28, "verse_to": 30, "meditacao": "O convite é para quem está carregando peso, não para quem está de mãos livres."},
	{"titulo": "O bom pastor", "book": "JHN", "chapter": 10, "verse_from": 11, "verse_to": 15, "meditacao": "Conhecer pelo nome é o oposto de tratar em quantidade."},
	{"titulo": "Sem ansiedade", "book": "PHP", "chapter": 4, "verse_from": 4, "verse_to": 9, "meditacao": "O remédio proposto não é parar de pensar: é escolher melhor no que pensar."},
	{"titulo": "Amor paciente", "book": "1CO", "chapter": 13, "verse_from": 1, "verse_to": 8, "meditacao": "A lista começa pela paciência, que é a parte menos fotogênica do amor."},
	{"titulo": "Renovar as forças", "book": "ISA", "chapter": 40, "verse_from": 28, "verse_to": 31, "meditacao": "Correr, andar, voar — a promessa inclui o ritmo lento."},
	{"titulo": "Misericórdias novas", "book": "LAM", "chapter": 3, "verse_from": 19, "verse_to": 26, "meditacao": "Escrito em meio a um lamento, e não depois dele."},
	{"titulo": "Lâmpada para os pés", "book": "PSA", "chapter": 119, "verse_from": 103, "verse_to": 112, "meditacao": "Lâmpada para os pés ilumina o próximo passo, não o mapa inteiro."},
	{"titulo": "Justiça e misericórdia", "book": "MIC", "chapter": 6, "verse_from": 6, "verse_to": 8, "meditacao": "Três verbos, nenhum deles sobre religiosidade visível."},
	{"titulo": "Coração novo", "book": "EZK", "chapter": 36, "verse_from": 25, "verse_to": 28, "meditacao": "A promessa é de substituição, não de esforço redobrado."},
	{"titulo": "Casa sobre a rocha", "book": "MAT", "chapter": 7, "verse_from": 24, "verse_to": 27, "meditacao": "As duas casas enfrentam a mesma tempestade. A diferença estava embaixo."},
	{"titulo": "O semeador", "book": "MRK", "chapter": 4, "verse_from": 3, "verse_to": 9, "meditacao": "O semeador não muda a semente conforme o terreno. Semeia em todos."},
	{"titulo": "A ovelha perdida", "book": "LUK", "chapter": 15, "verse_from": 1, "verse_to": 7, "meditacao": "A conta não fecha: noventa e nove ficam para buscar uma."},
	{"titulo": "O filho que volta", "book": "LUK", "chapter": 15, "verse_from": 17, "verse_to": 24, "meditacao": "O pai corre antes do discurso pronto ser dito."},
	{"titulo": "O bom samaritano", "book": "LUK", "chapter": 10, "verse_from": 30, "verse_to": 37, "meditacao": "Dois passaram de longe por motivos provavelmente razoáveis."},
	{"titulo": "Marta e Maria", "book": "LUK", "chapter": 10, "verse_from": 38, "verse_to": 42, "meditacao": "A correção não é ao trabalho, é à ansiedade dentro dele."},
	{"titulo": "Zaqueu", "book": "LUK", "chapter": 19, "verse_from": 1, "verse_to": 10, "meditacao": "Subiu numa árvore para ver, e foi visto primeiro."},
	{"titulo": "Pedir, buscar, bater", "book": "LUK", "chapter": 11, "verse_from": 9, "verse_to": 13, "meditacao": "Três verbos em ordem crescente de insistência."},
	{"titulo": "O maior mandamento", "book": "MRK", "chapter": 12, "verse_from": 28, "verse_to": 34, "meditacao": "A resposta vem em dois, porque um sem o outro não se sustenta."},
	{"titulo": "Sal e luz", "book": "MAT", "chapter": 5, "verse_from": 13, "verse_to": 16, "meditacao": "Sal e luz só existem para o que está fora deles."},
	{"titulo": "O perdão sem conta", "book": "MAT", "chapter": 18, "verse_from": 21, "verse_to": 35, "meditacao": "Setenta vezes sete é um jeito de dizer: pare de contar."},
	{"titulo": "Tesouro no céu", "book": "MAT", "chapter": 6, "verse_from": 19, "verse_to": 24, "meditacao": "Onde está o tesouro está o coração — e não o contrário."},
	{"titulo": "Oração simples", "book": "MAT", "chapter": 6, "verse_from": 5, "verse_to": 15, "meditacao": "Curta, coletiva, e pedindo o pão de um dia só."},
	{"titulo": "A videira", "book": "JHN", "chapter": 15, "verse_from": 1, "verse_to": 8, "meditacao": "Permanecer é apresentado como trabalho, não como espera."},
	{"titulo": "Paz que fica", "book": "JHN", "chapter": 14, "verse_from": 25, "verse_to": 27, "meditacao": "Uma paz explicitamente diferente da que o mundo dá."},
	{"titulo": "Nada nos separa", "book": "ROM", "chapter": 8, "verse_from": 31, "verse_to": 39, "meditacao": "A lista de ameaças é longa de propósito. Nenhuma entra."},
	{"titulo": "Todas as coisas", "book": "ROM", "chapter": 8, "verse_from": 18, "verse_to": 28, "meditacao": "A criação inteira gemendo junto — a dor aqui não é individual."},
	{"titulo": "Um corpo", "book": "1CO", "chapter": 12, "verse_from": 12, "verse_to": 27, "meditacao": "A parte que parece menor é a que recebe mais cuidado."},
	{"titulo": "Vaso de barro", "book": "2CO", "chapter": 4, "verse_from": 7, "verse_to": 12, "meditacao": "A fragilidade do vaso é parte do argumento, não um defeito dele."},
	{"titulo": "Força na fraqueza", "book": "2CO", "chapter": 12, "verse_from": 7, "verse_to": 10, "meditacao": "O espinho não é removido. É reinterpretado."},
	{"titulo": "Frutos", "book": "GAL", "chapter": 5, "verse_from": 22, "verse_to": 26, "meditacao": "Fruto, não produto: cresce com tempo, não com esforço concentrado."},
	{"titulo": "Pela graça", "book": "EPH", "chapter": 2, "verse_from": 4, "verse_to": 10, "meditacao": "Se fosse por mérito, haveria motivo para comparar."},
	{"titulo": "Revestir-se", "book": "COL", "chapter": 3, "verse_from": 12, "verse_to": 17, "meditacao": "Compaixão e paciência descritas como roupa: escolhidas todo dia."},
	{"titulo": "O mesmo sentimento", "book": "PHP", "chapter": 2, "verse_from": 3, "verse_to": 11, "meditacao": "Esvaziar-se aparece como movimento voluntário, não como perda."},
	{"titulo": "Contentamento", "book": "PHP", "chapter": 4, "verse_from": 10, "verse_to": 13, "meditacao": "Aprendi — o contentamento é descrito como aprendizado, não temperamento."},
	{"titulo": "Fé e obras", "book": "JAS", "chapter": 2, "verse_from": 14, "verse_to": 18, "meditacao": "Desejar bem a quem tem frio, sem dar agasalho, é uma frase vazia."},
	{"titulo": "Domar a língua", "book": "JAS", "chapter": 3, "verse_from": 2, "verse_to": 10, "meditacao": "Timão pequeno, navio grande. A imagem é sobre proporção."},
	{"titulo": "Lançar a ansiedade", "book": "1PE", "chapter": 5, "verse_from": 5, "verse_to": 11, "meditacao": "Lançar sobre alguém pressupõe que exista alguém para receber."},
	{"titulo": "Esperança viva", "book": "1PE", "chapter": 1, "verse_from": 3, "verse_to": 9, "meditacao": "A alegria descrita convive com provações, não as substitui."},
	{"titulo": "Amar de verdade", "book": "1JN", "chapter": 4, "verse_from": 7, "verse_to": 12, "meditacao": "Ninguém viu; e é no amor entre pessoas que se torna visível."},
	{"titulo": "Confissão", "book": "1JN", "chapter": 1, "verse_from": 5, "verse_to": 10, "meditacao": "Andar na luz inclui admitir o que está no escuro."},
	{"titulo": "Pela fé", "book": "HEB", "chapter": 11, "verse_from": 1, "verse_to": 10, "meditacao": "A lista é de gente que saiu sem saber para onde ia."},
	{"titulo": "Corramos", "book": "HEB", "chapter": 12, "verse_from": 1, "verse_to": 3, "meditacao": "Primeiro deixar o peso, depois correr. Nessa ordem."},
	{"titulo": "Não te desampararei", "book": "HEB", "chapter": 13, "verse_from": 5, "verse_to": 8, "meditacao": "A promessa vem logo depois de um conselho sobre dinheiro."},
	{"titulo": "Criação e cuidado", "book": "PSA", "chapter": 8, "verse_from": 1, "verse_to": 9, "meditacao": "Diante da imensidão, a pergunta é por que sermos lembrados."},
	{"titulo": "Conhecido", "book": "PSA", "chapter": 139, "verse_from": 1, "verse_to": 12, "meditacao": "Ser conhecido por inteiro pode ser assustador ou um alívio enorme."},
	{"titulo": "Refúgio", "book": "PSA", "chapter": 46, "verse_from": 1, "verse_to": 11, "meditacao": "Aquietar-se aparece como ordem, não como sugestão."},
	{"titulo": "Espera", "book": "PSA", "chapter": 27, "verse_from": 1, "verse_to": 14, "meditacao": "Termina em espera, e não em resposta. É honesto."},
	{"titulo": "Coração quebrantado", "book": "PSA", "chapter": 51, "verse_from": 1, "verse_to": 12, "meditacao": "O pedido não é por punição menor, é por coração novo."},
	{"titulo": "Louvor de tudo", "book": "PSA", "chapter": 103, "verse_from": 1, "verse_to": 14, "meditacao": "Lembra-se de que somos pó — dito como ternura, não como desprezo."},
	{"titulo": "Guardião", "book": "PSA", "chapter": 121, "verse_from": 1, "verse_to": 8, "meditacao": "Canto de quem estava a caminho, olhando para os montes."},
	{"titulo": "Semente de mostarda", "book": "MAT", "chapter": 13, "verse_from": 31, "verse_to": 33, "meditacao": "O reino comparado a duas coisas pequenas e escondidas."},
	{"titulo": "Os trabalhadores", "book": "MAT", "chapter": 20, "verse_from": 1, "verse_to": 16, "meditacao": "A revolta não é contra injustiça: é contra generosidade alheia."},
	{"titulo": "Os talentos", "book": "MAT", "chapter": 25, "verse_from": 14, "verse_to": 30, "meditacao": "O erro do terceiro servo foi o medo, não a quantidade."},
	{"titulo": "Tive fome", "book": "MAT", "chapter": 25, "verse_from": 31, "verse_to": 40, "meditacao": "Nenhum dos dois lados sabia o que estava fazendo."},
	{"titulo": "Dois dracmas", "book": "MRK", "chapter": 12, "verse_from": 41, "verse_to": 44, "meditacao": "A medida usada é o que sobrou, não o que foi dado."},
	{"titulo": "Deixai vir", "book": "MRK", "chapter": 10, "verse_from": 13, "verse_to": 16, "meditacao": "Os discípulos estavam protegendo o mestre de quem ele queria receber."},
	{"titulo": "Creio, ajuda-me", "book": "MRK", "chapter": 9, "verse_from": 17, "verse_to": 24, "meditacao": "A oração mais sincera do evangelho admite a própria falta de fé."},
	{"titulo": "Caminho de Emaús", "book": "LUK", "chapter": 24, "verse_from": 13, "verse_to": 32, "meditacao": "Caminharam horas sem reconhecer. O pão abriu os olhos."},
	{"titulo": "Um novo nome", "book": "ISA", "chapter": 43, "verse_from": 1, "verse_to": 7, "meditacao": "Passar pelas águas, e não em volta delas."},
	{"titulo": "Como a chuva", "book": "ISA", "chapter": 55, "verse_from": 6, "verse_to": 13, "meditacao": "A palavra é comparada à chuva: age devagar e por baixo."},
	{"titulo": "Planos de paz", "book": "JER", "chapter": 29, "verse_from": 10, "verse_to": 14, "meditacao": "Escrito a exilados, com prazo longo. Não era consolo rápido."},
	{"titulo": "Ainda que a figueira", "book": "HAB", "chapter": 3, "verse_from": 17, "verse_to": 19, "meditacao": "A alegria afirmada aqui é sem colheita nenhuma."},
	{"titulo": "Volta e descanso", "book": "HOS", "chapter": 6, "verse_from": 1, "verse_to": 3, "meditacao": "Conhecer é apresentado como algo que se persegue, não que se tem."},
	{"titulo": "Escolhe hoje", "book": "DEU", "chapter": 30, "verse_from": 15, "verse_to": 20, "meditacao": "A escolha é colocada como diária, não definitiva."},
	{"titulo": "Sê forte", "book": "JOS", "chapter": 1, "verse_from": 5, "verse_to": 9, "meditacao": "Três vezes a mesma ordem. Quem precisava ouvir estava com medo."},
	{"titulo": "Fala, que escuto", "book": "1SA", "chapter": 3, "verse_from": 1, "verse_to": 10, "meditacao": "Levou três chamados e a ajuda de um velho para entender."},
	{"titulo": "Brisa suave", "book": "1KI", "chapter": 19, "verse_from": 9, "verse_to": 13, "meditacao": "Não estava no vento, no terremoto nem no fogo."},
	{"titulo": "Tempo para tudo", "book": "ECC", "chapter": 3, "verse_from": 1, "verse_to": 8, "meditacao": "A lista inclui o tempo de perder e o de deixar ir."},
	{"titulo": "Dois são melhores", "book": "ECC", "chapter": 4, "verse_from": 9, "verse_to": 12, "meditacao": "O argumento é prático: quem cai sozinho não tem quem levante."},
	{"titulo": "Confia de todo o coração", "book": "PRO", "chapter": 16, "verse_from": 1, "verse_to": 9, "meditacao": "O homem planeja os passos; a direção é outra conversa."},
	{"titulo": "Palavra branda", "book": "PRO", "chapter": 15, "verse_from": 1, "verse_to": 4, "meditacao": "Resposta branda desvia o furor. Custa mais e resolve melhor."},
	{"titulo": "Restaurar", "book": "JOL", "chapter": 2, "verse_from": 23, "verse_to": 27, "meditacao": "Restituir os anos — não apenas parar a perda."},
]

var _ordem: Array[int] = []


func _ready() -> void:
	# Passo coprimo com o tamanho embaralha a lista sem sorteio nem estado salvo.
	var total := PASSAGENS.size()
	var passo := 17
	while passo > 1 and _mdc(passo, total) != 1:
		passo += 1
	_ordem.resize(total)
	for i in range(total):
		_ordem[i] = (i * passo) % total


func _mdc(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


func entrada_para_dia(dia_epoch: int) -> Dictionary:
	var total := PASSAGENS.size()
	if total <= 0:
		return {}
	var indice := _ordem[posmod(dia_epoch, total)] if _ordem.size() == total else posmod(dia_epoch, total)
	var fonte: Dictionary = PASSAGENS[indice]
	# A Palavra do Dia nao tem oracao e aplicacao escritas: a meditacao curta faz
	# o papel da reflexao, e os campos ausentes ficam vazios para a UI esconder.
	return {
		"titulo": str(fonte.titulo),
		"book": str(fonte.book),
		"chapter": int(fonte.chapter),
		"verse_from": int(fonte.verse_from),
		"verse_to": int(fonte.verse_to),
		"reflexao": str(fonte.meditacao),
		"oracao": "",
		"aplicacao": "",
	}


func resumo() -> Dictionary:
	return {
		"id": PLANO_ID,
		"nome": NOME,
		"subtitulo": SUBTITULO,
		"descricao": DESCRICAO,
		"dias": PASSAGENS.size(),
		"perpetuo": true,
	}

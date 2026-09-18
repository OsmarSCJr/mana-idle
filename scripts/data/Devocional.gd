extends Node

## Planos de leitura devocional.
##
## Cada dia traz uma passagem (lida do acervo offline BLIVRE via
## BibleTextProvider), uma reflexao curta, uma oracao e uma pergunta de
## aplicacao. O texto biblico NUNCA e duplicado aqui: apenas a referencia.
##
## Tom: devocional e reverente, sem afirmar doutrina de nenhuma igreja — ver
## PRODUCT.md e o aviso legal do app. As reflexoes falam da passagem e da vida
## de quem le, nao de interpretacao oficial.
##
## O plano "jornada_completa" acompanha os 36 geradores do jogo na mesma ordem
## historica, e e o elo entre a mecanica e o conteudo devocional: o dia N fala da
## mesma cena que o gerador N representa, com uma passagem complementar a do
## Estudo (que usa a cena narrativa; aqui a leitura e de meditacao).

const PLANO_PADRAO: String = "sete_dias"

const PLANOS: Array = [
	{
		"id": "sete_dias",
		"nome": "Sete Dias de Fé",
		"subtitulo": "Uma semana para começar",
		"descricao": "Sete leituras curtas sobre confiança, descanso e começo. Bom para criar o hábito.",
		"dias": [
			{
				"titulo": "No princípio",
				"book": "GEN", "chapter": 1, "verse_from": 1, "verse_to": 5,
				"reflexao": "A primeira coisa que a Escritura conta não é uma conquista: é uma separação. A luz é distinguida das trevas, e só então recebe nome. Começar bem raramente significa começar grande. Significa separar o que estava misturado e chamar cada coisa pelo que ela é.",
				"oracao": "Que eu comece este dia separando o essencial do ruído, e tenha coragem de nomear o que preciso encarar.",
				"aplicacao": "O que na sua semana está misturado e precisa ser separado hoje?",
			},
			{
				"titulo": "O descanso que não se compra",
				"book": "GEN", "chapter": 2, "verse_from": 1, "verse_to": 3,
				"reflexao": "O descanso aparece na Escritura antes de qualquer mandamento sobre trabalho. Não é recompensa por produtividade: é parte do desenho. Parar é um ato de confiança — a afirmação de que o mundo não depende do seu esforço para continuar existindo.",
				"oracao": "Ensina-me a parar sem culpa, e a confiar que aquilo que deixo incompleto hoje não se perde.",
				"aplicacao": "Quando foi a última vez que você parou sem estar exausto?",
			},
			{
				"titulo": "Ainda que eu ande",
				"book": "PSA", "chapter": 23, "verse_from": 1, "verse_to": 6,
				"reflexao": "O salmo não promete a ausência do vale. Promete companhia dentro dele. É uma diferença pequena na frase e enorme na vida: a fé aqui não é um atalho que desvia da sombra, é a certeza de não atravessá-la sozinho.",
				"oracao": "Nas horas em que eu não enxergar o caminho, que eu ao menos reconheça que não estou só.",
				"aplicacao": "Que vale você está atravessando agora, e quem caminha com você?",
			},
			{
				"titulo": "O pouco que basta",
				"book": "EXO", "chapter": 16, "verse_from": 14, "verse_to": 21,
				"reflexao": "O maná caía na medida do dia. Guardar mais estragava; recolher menos não faltava. Uma economia inteira construída contra a ansiedade — e contra o acúmulo. O suficiente é uma quantidade real, e quase sempre menor do que imaginamos.",
				"oracao": "Dá-me o pão de hoje e a serenidade de não exigir garantias para amanhã.",
				"aplicacao": "O que você tem guardado por medo, e não por necessidade?",
			},
			{
				"titulo": "Palavras que sustentam",
				"book": "PRO", "chapter": 3, "verse_from": 1, "verse_to": 8,
				"reflexao": "A sabedoria do provérbio é prática: escreve na memória, anda com bondade, não se apoia só no próprio entendimento. Não é misticismo, é higiene da alma. Confiar é também admitir que a nossa perspectiva é parcial.",
				"oracao": "Corrige o que em mim é certeza apressada, e firma o que em mim é confiança verdadeira.",
				"aplicacao": "Em que assunto você está confiando demais no seu próprio entendimento?",
			},
			{
				"titulo": "Bem-aventurados",
				"book": "MAT", "chapter": 5, "verse_from": 1, "verse_to": 12,
				"reflexao": "A lista inverte tudo o que se espera de uma lista de felizes. Os que choram, os mansos, os que têm fome de justiça. Não é uma glorificação da dor: é o anúncio de que o valor de uma vida não se mede pelos critérios que costumamos usar para medi-la.",
				"oracao": "Que eu aprenda a contar a minha vida por outra régua que não a do sucesso visível.",
				"aplicacao": "Qual dessas bem-aventuranças descreve o seu momento?",
			},
			{
				"titulo": "Tudo novo",
				"book": "REV", "chapter": 21, "verse_from": 1, "verse_to": 7,
				"reflexao": "A Escritura termina com uma promessa de renovação, não de fuga. Não é um outro mundo em outro lugar: é este, enxugado. Quem lê o fim antes do meio caminha diferente pelo meio — com pressa menor e esperança maior.",
				"oracao": "Sustenta em mim a esperança que não nega a realidade, mas também não se rende a ela.",
				"aplicacao": "O que você gostaria de ver renovado, e não apenas substituído?",
			},
		],
	},
	{
		"id": "jornada_completa",
		"nome": "Do Gênesis ao Apocalipse",
		"subtitulo": "36 dias, um por capítulo da jornada",
		"descricao": "A mesma linha do tempo que você percorre no jogo, em 36 leituras de meditação.",
		"dias": [
			{
				"titulo": "Haja luz",
				"book": "JHN", "chapter": 1, "verse_from": 1, "verse_to": 5,
				"reflexao": "João retoma o primeiro capítulo do Gênesis e coloca a luz numa frase nova: ela brilha nas trevas, e as trevas não prevaleceram. Não diz que as trevas desapareceram. Diz que não venceram. É uma esperança mais resistente do que o otimismo.",
				"oracao": "Que a luz que não se apaga me baste nos dias em que eu não vejo longe.",
				"aplicacao": "Onde, no seu dia, uma luz pequena tem sido suficiente?",
			},
			{
				"titulo": "O jardim e o cuidado",
				"book": "GEN", "chapter": 2, "verse_from": 15, "verse_to": 17,
				"reflexao": "A primeira tarefa humana no relato não é dominar, é cultivar e guardar. O jardim é entregue para ser cuidado, com um limite explícito. Liberdade e limite chegam juntos — e é o limite que faz do jardim um lugar, e não apenas um espaço.",
				"oracao": "Ajuda-me a cuidar bem do pedaço de mundo que me foi confiado.",
				"aplicacao": "Que coisa boa da sua vida precisa hoje mais de cuidado do que de expansão?",
			},
			{
				"titulo": "O arco na nuvem",
				"book": "GEN", "chapter": 9, "verse_from": 12, "verse_to": 17,
				"reflexao": "Depois do dilúvio, o sinal da aliança é posto na nuvem — no próprio lugar da tempestade. O lembrete não fica guardado no céu limpo: aparece quando o tempo fecha. A memória da promessa serve exatamente para as horas em que ela parece improvável.",
				"oracao": "Que eu reconheça os teus sinais mesmo quando o céu estiver carregado.",
				"aplicacao": "Que promessa você precisa relembrar num momento difícil?",
			},
			{
				"titulo": "Uma só língua",
				"book": "GEN", "chapter": 11, "verse_from": 1, "verse_to": 9,
				"reflexao": "Babel não cai por falta de técnica. Cai por excesso de projeto e falta de escuta. A confusão das línguas espalha o que queria se concentrar. Às vezes o que parece dispersão é a única forma de um povo voltar a caber no mundo.",
				"oracao": "Guarda-me de construir torres para o meu próprio nome.",
				"aplicacao": "Que projeto seu está mais alto do que necessário?",
			},
			{
				"titulo": "Pão do céu",
				"book": "DEU", "chapter": 8, "verse_from": 2, "verse_to": 5,
				"reflexao": "Olhando para trás, Moisés lê o deserto como escola: a fome veio antes do maná para ensinar que se vive de mais do que pão. A lição não estava no alimento, estava na ordem das coisas. O deserto é o lugar onde se descobre do que a gente realmente depende.",
				"oracao": "Nos dias de escassez, ensina-me o que só a escassez ensina.",
				"aplicacao": "O que uma falta já lhe ensinou que a abundância não ensinaria?",
			},
			{
				"titulo": "Mar aberto",
				"book": "EXO", "chapter": 14, "verse_from": 13, "verse_to": 18,
				"reflexao": "Diante do mar, a ordem é dupla e aparentemente contraditória: fiquem firmes e vejam — e depois, avancem. Há um tempo de parar e um de mover. A fé desse capítulo não é passividade nem pressa: é saber qual dos dois é a hora.",
				"oracao": "Dá-me discernimento para saber quando esperar e quando avançar.",
				"aplicacao": "Na sua decisão pendente, é hora de firmar ou de avançar?",
			},
			{
				"titulo": "Muralhas",
				"book": "JOS", "chapter": 6, "verse_from": 12, "verse_to": 20,
				"reflexao": "Seis dias de volta ao redor da mesma muralha, sem nada visível acontecer. A obediência aqui é monótona antes de ser vitoriosa. Quase tudo que se derruba na vida é derrubado assim: por repetição paciente, e não por um golpe único.",
				"oracao": "Sustenta a minha constância nos dias em que nada parece mudar.",
				"aplicacao": "Que volta ao redor da mesma muralha você precisa dar hoje?",
			},
			{
				"titulo": "Força e fraqueza",
				"book": "JDG", "chapter": 16, "verse_from": 23, "verse_to": 30,
				"reflexao": "A história de Sansão é sobre um homem forte derrotado pelo que havia de mais frágil nele. E termina com uma oração feita já sem visão e sem cabelos. A força que importa no fim do relato não é a dos braços — é a de ainda saber a quem pedir.",
				"oracao": "Quando a minha força falhar, que eu me lembre de onde ela vinha.",
				"aplicacao": "Qual é o seu ponto forte que mais precisa de vigilância?",
			},
			{
				"titulo": "Cinco pedras",
				"book": "1SA", "chapter": 17, "verse_from": 38, "verse_to": 50,
				"reflexao": "Davi recusa a armadura que não é a dele. Vai com o que sabe usar. A coragem do capítulo não está em enfrentar o gigante, está em não fingir ser outra pessoa para enfrentá-lo. Muita luta se perde vestindo a armadura errada.",
				"oracao": "Que eu enfrente o que é meu com aquilo que é meu, sem imitar ninguém.",
				"aplicacao": "Que armadura emprestada você deveria devolver?",
			},
			{
				"titulo": "A casa e a oração",
				"book": "1KI", "chapter": 8, "verse_from": 27, "verse_to": 30,
				"reflexao": "No dia em que inaugura o templo, Salomão diz que os céus não podem contê-Lo — muito menos aquela casa. É uma frase notável para se dizer numa festa de inauguração. Reconhecer o limite do próprio projeto é o que o torna digno.",
				"oracao": "Que o que eu construir sirva ao encontro, e não à minha vaidade.",
				"aplicacao": "Onde você tem confundido o lugar com o que o lugar deveria abrigar?",
			},
			{
				"titulo": "Fugir e voltar",
				"book": "JON", "chapter": 2, "verse_from": 1, "verse_to": 10,
				"reflexao": "A oração de Jônas é feita no fundo — literalmente. Ele não reza antes de fugir nem depois de ser perdoado: reza no meio, quando já não há para onde correr. Há orações que só nascem quando as saídas acabam.",
				"oracao": "Do lugar onde eu estiver, mesmo do fundo, que eu ainda saiba falar contigo.",
				"aplicacao": "Existe algo de que você está fugindo e que já é hora de encarar?",
			},
			{
				"titulo": "E se não nos livrar",
				"book": "DAN", "chapter": 3, "verse_from": 16, "verse_to": 25,
				"reflexao": "A resposta dos três diante da fornalha guarda a frase mais corajosa do capítulo: e se não nos livrar, ainda assim. A fidelidade que depende do resultado é negócio, não fidelidade. E foi dentro do fogo, não fora dele, que apareceu o quarto.",
				"oracao": "Que a minha fidelidade não seja condicionada ao que eu recebo por ela.",
				"aplicacao": "O que você faria igual mesmo sem garantia de resultado?",
			},
			{
				"titulo": "Nasceu em Belém",
				"book": "LUK", "chapter": 2, "verse_from": 8, "verse_to": 20,
				"reflexao": "O anúncio não vai ao palácio: vai a trabalhadores no turno da noite. E o sinal oferecido é o mais comum possível — um recém-nascido enfaixado. A grandeza aqui se apresenta em formato pequeno, e quem não se abaixa não vê.",
				"oracao": "Dá-me olhos para reconhecer o que é grande quando vier pequeno.",
				"aplicacao": "Que coisa comum na sua rotina merecia mais atenção?",
			},
			{
				"titulo": "Caminho no escuro",
				"book": "MAT", "chapter": 2, "verse_from": 13, "verse_to": 15,
				"reflexao": "A primeira viagem da família é uma fuga de madrugada para um país estrangeiro. O relato não poupa a história do medo real. Quem lê isso e depois encontra a própria vida cheia de desvios pode ao menos saber que desvio não é sinal de abandono.",
				"oracao": "Nos desvios que eu não escolhi, que eu confie que o caminho continua.",
				"aplicacao": "Que desvio da sua vida hoje você já consegue ler de outra forma?",
			},
			{
				"titulo": "Águas do Jordão",
				"book": "MAT", "chapter": 3, "verse_from": 13, "verse_to": 17,
				"reflexao": "Antes de qualquer milagre ou ensino, vem a afirmação: este é o amado. A identidade precede a obra. É uma inversão silenciosa da lógica com que normalmente vivemos, tentando merecer com desempenho aquilo que já foi dito de graça.",
				"oracao": "Que eu não passe o dia tentando merecer o que já me foi dado.",
				"aplicacao": "O que você faz para provar um valor que não precisa ser provado?",
			},
			{
				"titulo": "O melhor no fim",
				"book": "JHN", "chapter": 2, "verse_from": 1, "verse_to": 11,
				"reflexao": "O primeiro sinal do evangelho de João acontece numa festa, para evitar o embaraço dos anfitriões. Não resolve fome nem doença: resolve alegria. E o mestre-sala observa o que ninguém esperava — o bom vinho ficou para o fim.",
				"oracao": "Ensina-me a confiar que há coisas boas guardadas para depois.",
				"aplicacao": "Onde você tem pressa de algo que talvez esteja guardado para o fim?",
			},
			{
				"titulo": "No monte",
				"book": "MAT", "chapter": 6, "verse_from": 25, "verse_to": 34,
				"reflexao": "Olhe as aves, olhe os lírios. O argumento contra a ansiedade não é uma ordem, é um convite a observar. E termina com uma medida: basta ao dia o seu próprio mal. A preocupação quase sempre é o hoje carregando o peso de um amanhã que não chegou.",
				"oracao": "Tira dos meus ombros o peso dos dias que ainda não vieram.",
				"aplicacao": "Que preocupação de amanhã você pode devolver a amanhã?",
			},
			{
				"titulo": "Cinco pães",
				"book": "JHN", "chapter": 6, "verse_from": 5, "verse_to": 14,
				"reflexao": "A conta de Filipe está certa: não dá. O menino aparece com o que não resolve. E é justamente o insuficiente, entregue, que se multiplica. O relato não elogia a escassez; elogia a coragem de oferecer o pouco em vez de guardá-lo.",
				"oracao": "Que eu ofereça o meu pouco sem esperar que ele já seja suficiente.",
				"aplicacao": "Que pouco seu poderia servir a alguém hoje?",
			},
			{
				"titulo": "Sobre as águas",
				"book": "MAT", "chapter": 14, "verse_from": 25, "verse_to": 33,
				"reflexao": "Pedro anda e afunda no mesmo parágrafo. O que muda entre uma coisa e outra não é o vento: é para onde ele olha. E a mão que o segura chega antes da repreensão. Falhar no meio do caminho não anula ter saído do barco.",
				"oracao": "Quando eu afundar, que eu grite em vez de me afogar em silêncio.",
				"aplicacao": "Que passo você deu e interrompeu no meio?",
			},
			{
				"titulo": "Luz no alto",
				"book": "MAT", "chapter": 17, "verse_from": 1, "verse_to": 8,
				"reflexao": "Pedro quer construir tendas e ficar. A resposta é uma nuvem, uma voz e a descida do monte. As experiências que transformam não são para morar — são para sustentar a volta. Quem tenta acampar no alto perde o vale onde o alto faz sentido.",
				"oracao": "Que eu desça dos meus montes com o que recebi neles.",
				"aplicacao": "Que momento marcante você precisa transformar em prática comum?",
			},
			{
				"titulo": "Chorou",
				"book": "JHN", "chapter": 11, "verse_from": 32, "verse_to": 44,
				"reflexao": "Antes de chamar Lázaro, ele chora. Sabendo o que ia acontecer, ainda assim chora. O verso mais curto do evangelho é também o que mais desmonta a ideia de que fé e luto se excluem. A esperança não dispensa as lágrimas; ela as acompanha.",
				"oracao": "Que eu não tenha vergonha das minhas lágrimas nem pressa de secá-las.",
				"aplicacao": "Que luto você tem tentado atravessar rápido demais?",
			},
			{
				"titulo": "Entrada humilde",
				"book": "ZEC", "chapter": 9, "verse_from": 9, "verse_to": 10,
				"reflexao": "A profecia anuncia um rei que chega humilde, montado num jumentinho, e que quebra o arco de guerra. A imagem desmonta a expectativa de poder pela força. Uma autoridade que desarma em vez de armar é a mais difícil de imitar.",
				"oracao": "Onde eu tiver alguma autoridade, que eu a use para desarmar.",
				"aplicacao": "Onde você poderia baixar a guarda primeiro?",
			},
			{
				"titulo": "À mesa",
				"book": "JHN", "chapter": 13, "verse_from": 3, "verse_to": 15,
				"reflexao": "Sabendo tudo o que tinha nas mãos, ele pega uma toalha e lava pés. O gesto é escolhido justamente no momento de maior consciência do próprio lugar. Servir de baixo é uma decisão de quem poderia ficar de cima.",
				"oracao": "Dá-me disposição para o serviço que ninguém vê nem agradece.",
				"aplicacao": "Que serviço pequeno você pode fazer hoje sem contar a ninguém?",
			},
			{
				"titulo": "De manhã, no jardim",
				"book": "JHN", "chapter": 20, "verse_from": 11, "verse_to": 18,
				"reflexao": "Maria chora diante do túmulo vazio e não reconhece quem procura. Só o próprio nome, dito em voz alta, abre os olhos dela. Há reconhecimentos que não vêm por argumento: vêm por alguém nos chamando do jeito que só ele chama.",
				"oracao": "Chama-me pelo nome quando eu estiver procurando no lugar errado.",
				"aplicacao": "Você está procurando algo onde já não está?",
			},
			{
				"titulo": "Línguas de fogo",
				"book": "ACT", "chapter": 2, "verse_from": 1, "verse_to": 12,
				"reflexao": "O milagre de Pentecostes não é uma língua única: é cada um ouvir na sua. O oposto exato de Babel. A unidade que nasce ali não apaga diferenças, atravessa-as. Entender e ser entendido continua sendo um dos maiores milagres possíveis.",
				"oracao": "Dá-me paciência para entender antes de exigir ser entendido.",
				"aplicacao": "Com quem você precisa recomeçar a conversa ouvindo?",
			},
			{
				"titulo": "No caminho",
				"book": "ACT", "chapter": 9, "verse_from": 1, "verse_to": 9,
				"reflexao": "Saulo cai a caminho de fazer o que achava certo. O relato não descreve um homem mau convertido: descreve um homem convicto interrompido. Cegueira temporária como preço de uma visão nova. Poucas mudanças profundas chegam sem desorientação.",
				"oracao": "Interrompe em mim as convicções que estão me levando para o lugar errado.",
				"aplicacao": "Em que você está absolutamente certo e poderia estar errado?",
			},
			{
				"titulo": "Estrangeiros",
				"book": "ACT", "chapter": 17, "verse_from": 22, "verse_to": 28,
				"reflexao": "Em Atenas, Paulo não começa condenando: começa citando o que os atenienses já haviam escrito. Fala a partir do que o outro conhece. É um método antes de ser uma mensagem — e continua sendo raro.",
				"oracao": "Ensina-me a começar pelo que o outro já tem, e não pelo que lhe falta.",
				"aplicacao": "Com quem você poderia falar partindo do mundo dela, e não do seu?",
			},
			{
				"titulo": "Cartas e conselhos",
				"book": "2TI", "chapter": 3, "verse_from": 14, "verse_to": 17,
				"reflexao": "O conselho a Timóteo é para permanecer no que aprendeu, lembrando de quem aprendeu. A fé chega quase sempre com rosto — alguém ensinou, alguém viveu perto. Herdar bem é saber a quem se deve o que se sabe.",
				"oracao": "Obrigado por quem me ensinou. Que eu ensine com o mesmo cuidado.",
				"aplicacao": "Quem lhe ensinou algo que você carrega até hoje? Diga a essa pessoa.",
			},
			{
				"titulo": "Testemunho e coragem",
				"book": "ACT", "chapter": 7, "verse_from": 54, "verse_to": 60,
				"reflexao": "O relato mais duro dos Atos termina com um pedido de perdão para quem apedrejava. Não há aqui heroísmo de vingança. A coragem descrita é de outro tipo, mais difícil: manter-se sem ódio no pior momento.",
				"oracao": "Guarda o meu coração de devolver o mal que eu receber.",
				"aplicacao": "A quem você precisa parar de devolver o mal recebido?",
			},
			{
				"titulo": "Praça pública",
				"book": "ROM", "chapter": 12, "verse_from": 9, "verse_to": 18,
				"reflexao": "A lista de Paulo é quase toda sobre convivência: alegrar-se com quem se alegra, chorar com quem chora, não pagar mal com mal, viver em paz se possível. Nenhuma dessas coisas é abstrata. A fé se mede no quanto ela muda o jeito de tratar as pessoas.",
				"oracao": "Que a minha fé apareça primeiro no jeito como eu trato quem está perto.",
				"aplicacao": "Qual item dessa lista está mais difícil para você esta semana?",
			},
			{
				"titulo": "O justo viverá",
				"book": "ROM", "chapter": 1, "verse_from": 16, "verse_to": 17,
				"reflexao": "Duas frases que mudaram séculos de história. Não têm nada de espetacular: falam de não se envergonhar e de viver pela fé. Reformas costumam começar assim, com alguém lendo devagar o que já estava escrito.",
				"oracao": "Que eu leia devagar o que julgo já saber.",
				"aplicacao": "Que texto ou ideia conhecida você poderia reler com atenção nova?",
			},
			{
				"titulo": "Ide",
				"book": "MAT", "chapter": 28, "verse_from": 16, "verse_to": 20,
				"reflexao": "O envio termina com uma promessa de companhia, não de sucesso. E o texto registra que alguns ali ainda duvidavam. Foram enviados de qualquer forma. É um alívio: a missão não espera a dúvida acabar.",
				"oracao": "Envia-me mesmo com as dúvidas que eu ainda tenho.",
				"aplicacao": "O que você tem adiado até ter certeza absoluta?",
			},
			{
				"titulo": "De toda nação",
				"book": "REV", "chapter": 7, "verse_from": 9, "verse_to": 12,
				"reflexao": "A visão do fim é uma multidão que ninguém consegue contar, de toda nação, tribo e língua. Não uma seleção pequena de iguais. Se é assim que termina, vale perguntar por que insistimos em círculos tão estreitos no meio do caminho.",
				"oracao": "Alarga o meu coração para caber gente que não se parece comigo.",
				"aplicacao": "Que círculo seu está mais estreito do que deveria?",
			},
			{
				"titulo": "O primeiro amor",
				"book": "REV", "chapter": 2, "verse_from": 1, "verse_to": 7,
				"reflexao": "A igreja de Éfeso é elogiada por trabalho, paciência e discernimento — e corrigida por uma coisa só: deixou o primeiro amor. É possível acertar em quase tudo e perder o motivo. Eficiência não substitui afeto.",
				"oracao": "Devolve-me o motivo, quando eu já estiver funcionando só por hábito.",
				"aplicacao": "Que coisa boa você continua fazendo sem lembrar por quê?",
			},
			{
				"titulo": "O livro e o Cordeiro",
				"book": "REV", "chapter": 5, "verse_from": 1, "verse_to": 10,
				"reflexao": "Anunciam um leão e aparece um cordeiro. A imagem central do último livro da Escritura é essa troca. O poder que abre o livro é o que foi entregue. Nada na visão do fim endossa a força como caminho.",
				"oracao": "Corrige em mim a ideia de que vencer é a mesma coisa que dominar.",
				"aplicacao": "Onde você tem confundido vencer com dominar?",
			},
			{
				"titulo": "Nova Jerusalém",
				"book": "REV", "chapter": 22, "verse_from": 1, "verse_to": 5,
				"reflexao": "A última cena traz de volta a árvore da vida e um rio no meio da cidade. A Escritura fecha o círculo: começou num jardim, termina num jardim dentro de uma cidade. Nada do caminho foi desperdiçado — tudo foi recolhido.",
				"oracao": "Que eu chegue ao fim sabendo que nada do caminho foi perdido.",
				"aplicacao": "Que parte da sua história você ainda considera desperdício?",
			},
		],
	},
]

var _by_id: Dictionary = {}


func _ready() -> void:
	for plano in PLANOS:
		_by_id[str(plano.id)] = plano


func get_plano(plano_id: String) -> Dictionary:
	return _by_id.get(plano_id, {})


func plano_ids() -> Array[String]:
	var ids: Array[String] = []
	for plano in PLANOS:
		ids.append(str(plano.id))
	ids.append(DevocionalPalavra.PLANO_ID)
	return ids


func exists(plano_id: String) -> bool:
	return _by_id.has(plano_id) or plano_id == DevocionalPalavra.PLANO_ID


func dias(plano_id: String) -> int:
	if plano_id == DevocionalPalavra.PLANO_ID:
		return 0  # perpetuo
	return (get_plano(plano_id).get("dias", []) as Array).size()


## Entrada do dia. Em planos finitos o indice e o dia atual; no plano perpetuo o
## conteudo e escolhido de forma deterministica pela data, para todo aparelho do
## mesmo jogador ver a mesma leitura no mesmo dia, mesmo offline.
func entrada(plano_id: String, dia_indice: int, dia_epoch: int) -> Dictionary:
	if plano_id == DevocionalPalavra.PLANO_ID:
		return DevocionalPalavra.entrada_para_dia(dia_epoch)
	var lista: Array = get_plano(plano_id).get("dias", [])
	if lista.is_empty():
		return {}
	return (lista[clampi(dia_indice, 0, lista.size() - 1)] as Dictionary).duplicate(true)


func resumo(plano_id: String) -> Dictionary:
	if plano_id == DevocionalPalavra.PLANO_ID:
		return DevocionalPalavra.resumo()
	var plano := get_plano(plano_id)
	if plano.is_empty():
		return {}
	return {
		"id": str(plano.id),
		"nome": str(plano.nome),
		"subtitulo": str(plano.subtitulo),
		"descricao": str(plano.descricao),
		"dias": (plano.get("dias", []) as Array).size(),
		"perpetuo": false,
	}

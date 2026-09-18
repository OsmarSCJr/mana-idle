extends Node

## Notificações locais do sistema (Android) atrás de uma fachada.
##
## Godot não agenda notificações locais sozinho: é preciso um plugin Android. Este
## autoload concentra TODA a decisão de quando notificar, em GDScript, e delega o
## agendamento ao singleton nativo quando ele existe. Sem o plugin instalado — no
## desktop, nos smoke tests e em qualquer build sem o .aar — os métodos apenas
## registram a intenção e não fazem nada, sem quebrar nada.
##
## Contrato esperado do singleton nativo (ver PLANO_PUBLICACAO_ANDROID.md e
## AJUSTES_VISUAIS_E_ASSETS.md, seção de pendências técnicas):
##
##   schedule(id: int, title: String, body: String, delay_seconds: int) -> void
##   cancel(id: int) -> void
##   cancelAll() -> void
##   hasPermission() -> bool
##   requestPermission() -> void
##
## IDs fixos para que reagendar substitua a notificação anterior em vez de
## acumular várias na bandeja.

const SINGLETON_NAME: String = "ManaNotifications"

const ID_DEVOCIONAL: int = 1001
const ID_OFFLINE_CHEIO: int = 1002
const ID_SELO_EXPIRANDO: int = 1003

var _singleton: Object = null
var _disponivel: bool = false
var _ultimo_agendamento: Dictionary = {}


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--smoke-test"):
		return
	if Engine.has_singleton(SINGLETON_NAME):
		_singleton = Engine.get_singleton(SINGLETON_NAME)
		_disponivel = _singleton != null
	if _disponivel:
		EventBus.devocional_changed.connect(reagendar_lembrete_devocional)
		EventBus.devocional_selo_changed.connect(reagendar_selo)


func disponivel() -> bool:
	return _disponivel


func tem_permissao() -> bool:
	if not _disponivel:
		return false
	return bool(_singleton.call("hasPermission"))


func pedir_permissao() -> void:
	if _disponivel:
		_singleton.call("requestPermission")


## Último agendamento pedido por id, para depuração e para os testes verificarem
## a decisão sem precisar do plugin nativo.
func ultimo_agendamento(id: int) -> Dictionary:
	return (_ultimo_agendamento.get(id, {}) as Dictionary).duplicate()


func agendar(id: int, titulo: String, corpo: String, atraso_segundos: int) -> bool:
	if atraso_segundos <= 0:
		cancelar(id)
		return false
	_ultimo_agendamento[id] = {
		"titulo": titulo,
		"corpo": corpo,
		"atraso": atraso_segundos,
		"pedido_em": Time.get_unix_time_from_system(),
	}
	if not _disponivel:
		return false
	_singleton.call("schedule", id, titulo, corpo, atraso_segundos)
	return true


func cancelar(id: int) -> void:
	_ultimo_agendamento.erase(id)
	if _disponivel:
		_singleton.call("cancel", id)


func cancelar_tudo() -> void:
	_ultimo_agendamento.clear()
	if _disponivel:
		_singleton.call("cancelAll")


# ---------------------------------------------------------------- Devocional

## Lembrete do devocional no horário escolhido. Se o jogador já leu hoje, o
## lembrete vai para o horário de amanhã — nunca se avisa sobre algo já feito.
func reagendar_lembrete_devocional() -> int:
	var hora := DevocionalSystem.hora_lembrete()
	if hora < 0:
		cancelar(ID_DEVOCIONAL)
		return 0
	var atraso := segundos_ate_hora_local(hora, DevocionalSystem.ja_leu_hoje())
	agendar(
		ID_DEVOCIONAL,
		"Devocional do dia",
		"Sua leitura de hoje está esperando. O Selo do Dia dura 24 h.",
		atraso
	)
	return atraso


## Aviso de que o Selo do Dia está perto de vencer (1 h antes), para a sequência
## não se perder por esquecimento.
func reagendar_selo() -> int:
	if not DevocionalSystem.selo_ativo():
		cancelar(ID_SELO_EXPIRANDO)
		return 0
	var atraso := DevocionalSystem.selo_segundos_restantes() - 3600
	if atraso <= 0:
		cancelar(ID_SELO_EXPIRANDO)
		return 0
	agendar(
		ID_SELO_EXPIRANDO,
		"O Selo do Dia vence em 1 h",
		"Uma leitura curta renova o selo e mantém a sua sequência.",
		atraso
	)
	return atraso


## Aviso de que o acúmulo offline encheu o teto — daí em diante a produção é
## perdida, e é o momento em que voltar ao jogo tem mais valor.
func reagendar_offline_cheio() -> int:
	var cap := int(Economy.get_offline_cap())
	if cap <= 0:
		cancelar(ID_OFFLINE_CHEIO)
		return 0
	agendar(
		ID_OFFLINE_CHEIO,
		"Seu santuário encheu",
		"O acúmulo offline chegou ao limite. Recolha para não deixar produção parada.",
		cap
	)
	return cap


## Segundos até a próxima ocorrência de uma hora local. `pular_hoje` força o
## agendamento para o dia seguinte.
func segundos_ate_hora_local(hora: int, pular_hoje: bool = false) -> int:
	var agora := DevocionalSystem.agora()
	var fuso := float(Time.get_time_zone_from_system().get("bias", 0)) * 60.0
	var local := agora + fuso
	var inicio_do_dia := floorf(local / 86400.0) * 86400.0
	var alvo := inicio_do_dia + float(clampi(hora, 0, 23)) * 3600.0
	# Proxima ocorrencia do horario.
	if alvo <= local:
		alvo += 86400.0
	# Ja leu hoje: o aviso vai para a ocorrencia seguinte, e nao para a de hoje.
	if pular_hoje and alvo < inicio_do_dia + 86400.0:
		alvo += 86400.0
	return maxi(1, ceili(alvo - local))

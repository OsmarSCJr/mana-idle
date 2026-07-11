class_name GameArt
extends RefCounted

## Catálogo central de texturas. `preload` garante inclusão no export e evita
## carregar arquivos durante os updates frequentes da interface.

const GENERATOR_ICONS := [
	preload("res://assets/icons/geradores/g01_haja_luz.png"),
	preload("res://assets/icons/geradores/g02_eden.png"),
	preload("res://assets/icons/geradores/g03_arca_noe.png"),
	preload("res://assets/icons/geradores/g04_torre_babel.png"),
	preload("res://assets/icons/geradores/g05_mana_ceu.png"),
	preload("res://assets/icons/geradores/g06_mar_vermelho.png"),
	preload("res://assets/icons/geradores/g07_muralhas_jerico.png"),
	preload("res://assets/icons/geradores/g08_sansao.png"),
	preload("res://assets/icons/geradores/g09_davi_golias.png"),
	preload("res://assets/icons/geradores/g10_templo_salomao.png"),
	preload("res://assets/icons/geradores/g11_jonas_baleia.png"),
	preload("res://assets/icons/geradores/g12_fornalha_ardente.png"),
	preload("res://assets/icons/geradores/g13_nascimento_belem.png"),
	preload("res://assets/icons/geradores/g14_fuga_egito.png"),
	preload("res://assets/icons/geradores/g15_batismo_jordao.png"),
	preload("res://assets/icons/geradores/g16_bodas_cana.png"),
	preload("res://assets/icons/geradores/g17_sermao_monte.png"),
	preload("res://assets/icons/geradores/g18_multiplicacao_paes.png"),
	preload("res://assets/icons/geradores/g19_caminhar_aguas.png"),
	preload("res://assets/icons/geradores/g20_transfiguracao.png"),
	preload("res://assets/icons/geradores/g21_ressurreicao_lazaro.png"),
	preload("res://assets/icons/geradores/g22_entrada_jerusalem.png"),
	preload("res://assets/icons/geradores/g23_ultima_ceia.png"),
	preload("res://assets/icons/geradores/g24_ressurreicao.png"),
	preload("res://assets/icons/geradores/g25_pentecostes.png"),
	preload("res://assets/icons/geradores/g26_conversao_saulo.png"),
	preload("res://assets/icons/geradores/g27_viagens_missionarias.png"),
	preload("res://assets/icons/geradores/g28_cartas_igrejas.png"),
	preload("res://assets/icons/geradores/g29_martires_fe.png"),
	preload("res://assets/icons/geradores/g30_edito_milao.png"),
	preload("res://assets/icons/geradores/g31_reforma_protestante.png"),
	preload("res://assets/icons/geradores/g32_grande_comissao.png"),
	preload("res://assets/icons/geradores/g33_evangelismo_mundial.png"),
	preload("res://assets/icons/geradores/g34_sete_igrejas_asia.png"),
	preload("res://assets/icons/geradores/g35_apocalipse.png"),
	preload("res://assets/icons/geradores/g36_nova_jerusalem.png"),
]

const AUTOMATION_PORTRAITS := [
	preload("res://assets/icons/profetas/p01_gabriel.png"),
	preload("res://assets/icons/profetas/p02_adao.png"),
	preload("res://assets/icons/profetas/p03_noe.png"),
	preload("res://assets/icons/profetas/p04_nemrod.png"),
	preload("res://assets/icons/profetas/p05_moises.png"),
	preload("res://assets/icons/profetas/p06_moises_ii.png"),
	preload("res://assets/icons/profetas/p07_josue.png"),
	preload("res://assets/icons/profetas/p08_dalila.png"),
	preload("res://assets/icons/profetas/p09_davi.png"),
	preload("res://assets/icons/profetas/p10_salomao.png"),
	preload("res://assets/icons/profetas/p11_jonas.png"),
	preload("res://assets/icons/profetas/p12_sadraque.png"),
	preload("res://assets/icons/profetas/p13_jose.png"),
	preload("res://assets/icons/profetas/p14_jose_ii.png"),
	preload("res://assets/icons/profetas/p15_joao_batista.png"),
	preload("res://assets/icons/profetas/p16_maria.png"),
	preload("res://assets/icons/profetas/p17_mateus.png"),
	preload("res://assets/icons/profetas/p18_pedro.png"),
	preload("res://assets/icons/profetas/p19_pedro_ii.png"),
	preload("res://assets/icons/profetas/p20_tiago.png"),
	preload("res://assets/icons/profetas/p21_marta.png"),
	preload("res://assets/icons/profetas/p22_zaqueu.png"),
	preload("res://assets/icons/profetas/p23_joao.png"),
	preload("res://assets/icons/profetas/p24_maria_madalena.png"),
	preload("res://assets/icons/profetas/p25_apostolos.png"),
	preload("res://assets/icons/profetas/p26_paulo.png"),
	preload("res://assets/icons/profetas/p27_paulo_ii.png"),
	preload("res://assets/icons/profetas/p28_timoteo.png"),
	preload("res://assets/icons/profetas/p29_estevao.png"),
	preload("res://assets/icons/profetas/p30_constantino.png"),
	preload("res://assets/icons/profetas/p31_lutero.png"),
	preload("res://assets/icons/profetas/p32_apostolos_ii.png"),
	preload("res://assets/icons/profetas/p33_missionarios.png"),
	preload("res://assets/icons/profetas/p34_joao_ii.png"),
	preload("res://assets/icons/profetas/p35_joao_iii.png"),
	preload("res://assets/icons/profetas/p36_cordeiro.png"),
]

const SPECIAL_PROPHET_PORTRAITS := {
	"pe_melquisedeque": preload("res://assets/icons/profetas/especiais/ps01_melquisedeque.png"),
	"pe_jetro": preload("res://assets/icons/profetas/especiais/ps02_jetro.png"),
	"pe_samuel": preload("res://assets/icons/profetas/especiais/ps03_samuel.png"),
	"pe_bezalel": preload("res://assets/icons/profetas/especiais/ps04_bezalel.png"),
	"pe_elias": preload("res://assets/icons/profetas/especiais/ps05_elias.png"),
	"pe_eliseu": preload("res://assets/icons/profetas/especiais/ps06_eliseu.png"),
	"pe_isaias": preload("res://assets/icons/profetas/especiais/ps07_isaias.png"),
	"pe_henoc": preload("res://assets/icons/profetas/especiais/ps08_henoc.png"),
	"pe_abraao": preload("res://assets/icons/profetas/especiais/ps09_abraao.png"),
	"pe_isaque": preload("res://assets/icons/profetas/especiais/ps10_isaque.png"),
	"pe_jaco": preload("res://assets/icons/profetas/especiais/ps11_jaco.png"),
	"pe_daniel": preload("res://assets/icons/profetas/especiais/ps12_daniel.png"),
}

const GIFT_ICONS := {
	"d_comunhao": preload("res://assets/icons/dadivas/d_comunhao.png"),
	"d_evangelismo": preload("res://assets/icons/dadivas/d_evangelismo.png"),
	"d_evangelismo2": preload("res://assets/icons/dadivas/d_evangelismo2.png"),
	"d_jo": preload("res://assets/icons/dadivas/d_jo.png"),
	"d_jo2": preload("res://assets/icons/dadivas/d_jo2.png"),
	"d_salomao": preload("res://assets/icons/dadivas/d_salomao.png"),
}

const SANTOS_ICON: Texture2D = preload("res://assets/icons/ui/ui_santos.png")
const RELIQUIAS_ICON: Texture2D = preload("res://assets/icons/ui/ui_reliquias.png")


static func generator_icon(generator_id: int) -> Texture2D:
	if generator_id < 1 or generator_id > GENERATOR_ICONS.size():
		return null
	return GENERATOR_ICONS[generator_id - 1] as Texture2D


static func automation_portrait(generator_id: int) -> Texture2D:
	if generator_id < 1 or generator_id > AUTOMATION_PORTRAITS.size():
		return null
	return AUTOMATION_PORTRAITS[generator_id - 1] as Texture2D


static func special_prophet_portrait(upgrade_id: String) -> Texture2D:
	return SPECIAL_PROPHET_PORTRAITS.get(upgrade_id) as Texture2D


static func gift_icon(gift_id: String) -> Texture2D:
	return GIFT_ICONS.get(gift_id) as Texture2D

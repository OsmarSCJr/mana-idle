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

const ILLUMINATED_ERA1_PORTRAITS := [
	preload("res://assets/icons/profetas/iluminados/p01_gabriel_iluminado.png"),
	preload("res://assets/icons/profetas/iluminados/p02_adao_iluminado.png"),
	preload("res://assets/icons/profetas/iluminados/p03_noe_iluminado.png"),
	preload("res://assets/icons/profetas/iluminados/p04_nemrod_iluminado.png"),
]

const GIFT_ICONS := {
	"d_comunhao": preload("res://assets/icons/dadivas/d_comunhao.png"),
	"d_evangelismo": preload("res://assets/icons/dadivas/d_evangelismo.png"),
	"d_evangelismo2": preload("res://assets/icons/dadivas/d_evangelismo2.png"),
	"d_comprador_marcos": preload("res://assets/icons/special/milestone_10000.png"),
	"d_jo": preload("res://assets/icons/dadivas/d_jo.png"),
	"d_jo2": preload("res://assets/icons/dadivas/d_jo2.png"),
	"d_salomao": preload("res://assets/icons/dadivas/d_salomao.png"),
	"d_primicias": preload("res://assets/icons/dadivas/d_primicias.png"),
	"d_vigilia": preload("res://assets/icons/dadivas/d_vigilia.png"),
	"d_primicias2": preload("res://assets/icons/dadivas/d_primicias2.png"),
	"d_sopro": preload("res://assets/icons/dadivas/d_sopro.png"),
	"d_primicias3": preload("res://assets/icons/dadivas/d_primicias3.png"),
	"d_coroa": preload("res://assets/icons/dadivas/d_coroa.png"),
	"d_frutos": preload("res://assets/icons/dadivas/d_frutos.png"),
}

const SANTOS_ICON: Texture2D = preload("res://assets/icons/ui/ui_santos.png")
const RELIQUIAS_ICON: Texture2D = preload("res://assets/icons/ui/ui_reliquias.png")
const GEM_ICON: Texture2D = preload("res://assets/icons/ui/ui_gema_256.png")
const DAILY_BLESSING_ICON: Texture2D = preload("res://assets/icons/ui/ui_daily_blessing.png")
const FAITH_ICON: Texture2D = preload("res://assets/icons/ui/ui_fe.png")
const SETTINGS_ICON: Texture2D = preload("res://assets/icons/ui/ui_settings_wood.png")
const MANA_ICON: Texture2D = preload("res://assets/icons/geradores/g05_mana_ceu.png")
const OPEN_BIBLE_ICON: Texture2D = preload("res://assets/icons/ui/ui_open_bible.png")
const GRACE_ICON: Texture2D = preload("res://assets/icons/currencies/ui_graca.png")
const GLORY_ICON: Texture2D = preload("res://assets/icons/currencies/ui_gloria.png")
const NOVA_STAR_ICON: Texture2D = preload("res://assets/icons/special/nova_star.png")
const MILESTONE_10000_ICON: Texture2D = preload("res://assets/icons/special/milestone_10000.png")

const COSMETIC_PREVIEWS := {
	"fundo_aurora": preload("res://assets/icons/cosmetics/fundo_aurora.png"),
	"fundo_belem": preload("res://assets/icons/cosmetics/fundo_belem.png"),
	"fundo_mar": preload("res://assets/icons/cosmetics/fundo_mar.png"),
	"fundo_vitral": preload("res://assets/icons/cosmetics/fundo_vitral.png"),
	"fundo_jerusalem": preload("res://assets/icons/cosmetics/fundo_jerusalem.png"),
	"estrela_cometa": preload("res://assets/icons/cosmetics/estrela_cometa.png"),
	"estrela_serafim": preload("res://assets/icons/cosmetics/estrela_serafim.png"),
	"estrela_alva": preload("res://assets/icons/cosmetics/estrela_alva.png"),
	"titulo_peregrino": preload("res://assets/icons/cosmetics/titulo_peregrino.png"),
	"titulo_semeador": preload("res://assets/icons/cosmetics/titulo_semeador.png"),
	"titulo_guardiao": preload("res://assets/icons/cosmetics/titulo_guardiao.png"),
	"titulo_escriba": preload("res://assets/icons/cosmetics/titulo_escriba.png"),
	"titulo_profeta": preload("res://assets/icons/cosmetics/titulo_profeta.png"),
	"titulo_vencedor": preload("res://assets/icons/cosmetics/titulo_vencedor.png"),
	"retratos_iluminados_era1": preload("res://assets/icons/cosmetics/retratos_iluminados_era1.png"),
	"moldura_arca": preload("res://assets/icons/cosmetics/moldura_arca.png"),
	"moldura_templo": preload("res://assets/icons/cosmetics/moldura_templo.png"),
	"efeito_pombas": preload("res://assets/icons/cosmetics/efeito_pombas.png"),
	"tema_leitor_pergaminho": preload("res://assets/icons/cosmetics/tema_leitor_pergaminho.png"),
}

const KNOWLEDGE_ICONS := {
	"roots": preload("res://assets/icons/knowledge/knowledge_roots.png"),
	"word": preload("res://assets/icons/knowledge/knowledge_word.png"),
	"work": preload("res://assets/icons/knowledge/knowledge_work.png"),
	"communion": preload("res://assets/icons/knowledge/knowledge_communion.png"),
	"mission": preload("res://assets/icons/knowledge/knowledge_mission.png"),
	"crown": DAILY_BLESSING_ICON,
}

const SIDEBAR_ADVENTURE_ICONS := {
	"vida_cristo": preload("res://assets/icons/sidebar/adventure_christ.png"),
	"igreja_apocalipse": preload("res://assets/icons/sidebar/adventure_apocalypse.png"),
}

const SIDEBAR_BOOST_ICONS := {
	"fervor": preload("res://assets/icons/sidebar/boost_fervor.png"),
	"pentecoste": preload("res://assets/icons/sidebar/boost_pentecost.png"),
	"colheita": preload("res://assets/icons/sidebar/boost_harvest.png"),
	"passo_ligeiro": preload("res://assets/icons/sidebar/boost_swift_step.png"),
	"maos_santas": preload("res://assets/icons/sidebar/boost_holy_hands.png"),
}


static func generator_icon(generator_id: int) -> Texture2D:
	if generator_id < 1 or generator_id > GENERATOR_ICONS.size():
		return null
	return GENERATOR_ICONS[generator_id - 1] as Texture2D


static func automation_portrait(generator_id: int) -> Texture2D:
	if generator_id < 1 or generator_id > AUTOMATION_PORTRAITS.size():
		return null
	return AUTOMATION_PORTRAITS[generator_id - 1] as Texture2D

static func illuminated_era1_portrait(generator_id: int) -> Texture2D:
	if generator_id < 1 or generator_id > ILLUMINATED_ERA1_PORTRAITS.size():
		return automation_portrait(generator_id)
	return ILLUMINATED_ERA1_PORTRAITS[generator_id - 1] as Texture2D


static func special_prophet_portrait(upgrade_id: String) -> Texture2D:
	return SPECIAL_PROPHET_PORTRAITS.get(upgrade_id) as Texture2D


static func gift_icon(gift_id: String) -> Texture2D:
	return GIFT_ICONS.get(gift_id) as Texture2D

static func currency_icon(currency_id: String) -> Texture2D:
	match currency_id:
		"graca": return GRACE_ICON
		"gloria": return GLORY_ICON
		_: return FAITH_ICON

static func cosmetic_preview(cosmetic_id: String) -> Texture2D:
	return COSMETIC_PREVIEWS.get(cosmetic_id) as Texture2D

static func sidebar_adventure_icon(adventure_id: String) -> Texture2D:
	return SIDEBAR_ADVENTURE_ICONS.get(adventure_id) as Texture2D

static func sidebar_boost_icon(boost_id: String) -> Texture2D:
	return SIDEBAR_BOOST_ICONS.get(boost_id) as Texture2D

static func knowledge_icon(category: String) -> Texture2D:
	return KNOWLEDGE_ICONS.get(category, DAILY_BLESSING_ICON) as Texture2D

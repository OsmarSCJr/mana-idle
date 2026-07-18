import { ApiError } from "../errors";
import { MAX_SAVE_BYTES } from "../http";

const ROOT_KEYS = new Set([
  "version",
  "lastSeen",
  "fe",
  "santos",
  "santosGastos",
  "reliquias",
  "gemas",
  "gemasTotal",
  "feTotalVida",
  "feTotalHistorica",
  "graca",
  "gloria",
  "gracaTotal",
  "gloriaTotal",
  "dadivaFrutosNivel",
  "marcosLedger",
  "moedaMarcosLedger",
  "cosmeticosComprados",
  "cosmeticosAtivos",
  "novaStarLastGemClaim",
  "geradores",
  "maiorQtdGerador",
  "upgradesComprados",
  "dadivasCompradas",
  "estudo",
  "aventurasDesbloqueadas",
  "aventurasConcluidas",
  "boosts",
  "boostInventory",
  "rewardVideoWindowStarted",
  "rewardVideosWatched",
  "dailyBoostVideoLastClaimed",
  "dailyBoostVideoLastReward",
  "estatisticas",
]);

const REQUIRED_ROOT_KEYS = [
  "version",
  "lastSeen",
  "fe",
  "santos",
  "santosGastos",
  "reliquias",
  "gemas",
  "gemasTotal",
  "feTotalVida",
  "feTotalHistorica",
  "graca",
  "gloria",
  "gracaTotal",
  "gloriaTotal",
  "dadivaFrutosNivel",
  "marcosLedger",
  "moedaMarcosLedger",
  "cosmeticosComprados",
  "cosmeticosAtivos",
  "novaStarLastGemClaim",
  "geradores",
  "maiorQtdGerador",
  "upgradesComprados",
  "dadivasCompradas",
  "estudo",
  "aventurasDesbloqueadas",
  "aventurasConcluidas",
  "boosts",
  "boostInventory",
  "estatisticas",
] as const;

const DADIVA_IDS = new Set([
  "d_comunhao",
  "d_evangelismo",
  "d_evangelismo2",
  "d_comprador_marcos",
  "d_jo",
  "d_jo2",
  "d_salomao",
  "d_primicias",
  "d_vigilia",
  "d_primicias2",
  "d_sopro",
  "d_primicias3",
  "d_coroa",
]);
const ADVENTURE_IDS = new Set(["jornada", "vida_cristo", "igreja_apocalipse"]);
const COSMETIC_CATEGORIES = new Map([
  ["fundo_aurora", "tema_fundo"], ["fundo_belem", "tema_fundo"],
  ["fundo_mar", "tema_fundo"], ["fundo_vitral", "tema_fundo"],
  ["fundo_jerusalem", "tema_fundo"], ["estrela_cometa", "estrela"],
  ["estrela_serafim", "estrela"], ["estrela_alva", "estrela"],
  ["titulo_peregrino", "titulo"], ["titulo_semeador", "titulo"],
  ["titulo_guardiao", "titulo"], ["titulo_escriba", "titulo"],
  ["titulo_profeta", "titulo"], ["titulo_vencedor", "titulo"],
  ["retratos_iluminados_era1", "retrato"], ["moldura_arca", "moldura"],
  ["moldura_templo", "moldura"], ["efeito_pombas", "efeito"],
  ["tema_leitor_pergaminho", "tema_leitor"],
]);
const BOOST_IDS = new Set(["fervor", "pentecoste", "colheita", "passo_ligeiro", "maos_santas"]);
const KNOWLEDGE_IDS = new Set([
  "knowledge_good_seed",
  "knowledge_faithful_memory",
  "knowledge_reading_attention",
  "knowledge_living_memory",
  "knowledge_diligent_work",
  "knowledge_field_rhythm",
  "knowledge_shared_table",
  "knowledge_unison_song",
  "knowledge_christ_way",
  "knowledge_apocalypse_vision",
  "knowledge_deep_root",
  "knowledge_illuminated_scroll",
  "knowledge_faithful_workshop",
  "knowledge_renewed_covenant",
  "knowledge_testimony",
  "knowledge_ancient_roots",
  "knowledge_word_firm",
  "knowledge_complete_work",
  "knowledge_intercession",
  "knowledge_multiplying_fruit",
  "knowledge_fruitful_olive",
  "knowledge_discernment",
  "knowledge_consecrated_tools",
  "knowledge_living_communion",
  "knowledge_open_paths",
  "knowledge_abundant_harvest",
  "knowledge_lamp_path",
  "knowledge_lasting_communion",
  "knowledge_blooming_mission",
  "knowledge_full_olive",
]);
const CURATED_UPGRADE_IDS = new Set([
  "u1_1", "u1_2", "u1_3", "u2_1", "u2_2", "u2_3", "u3_1", "u3_2", "u3_3",
  "u4_1", "u4_2", "u4_3", "u4_4", "u5_1", "u5_2", "u5_3", "u6_1", "u6_2",
  "u6_3", "u7_1", "u7_2", "u7_3", "u8_1", "u8_2", "u8_3", "u9_1", "u9_2",
  "u9_3", "u10_1", "u10_2", "u10_3", "u11_1", "u11_2", "u11_3", "u12_1",
  "u12_2", "u12_3", "pe_melquisedeque", "pe_jetro", "pe_samuel", "pe_bezalel",
  "pe_elias", "pe_eliseu", "pe_isaias", "pe_henoc", "pe_abraao", "pe_isaque", "pe_jaco",
  "pe_daniel",
]);
const ERA_GROUPS = new Set([
  "christ_birth", "christ_ministry", "christ_resurrection", "early_church", "exodus_conquest",
  "expansion_reformation", "genesis", "kingdom", "revelation_renewal",
]);

type JsonObject = Record<string, unknown>;

function fail(path: string, message: string): never {
  throw new ApiError(422, "INVALID_SAVE", `Save inválido em ${path}: ${message}.`);
}

function isObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function objectAt(value: unknown, path: string): JsonObject {
  if (!isObject(value)) fail(path, "objeto esperado");
  return value;
}

function finiteNonNegative(value: unknown, path: string): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    fail(path, "número finito e não negativo esperado");
  }
  return value;
}

function integerNonNegative(value: unknown, path: string, max = Number.MAX_SAFE_INTEGER): number {
  const number = finiteNonNegative(value, path);
  if (!Number.isSafeInteger(number) || number > max) fail(path, "inteiro fora do limite");
  return number;
}

function uniqueStrings(value: unknown, path: string, max: number): string[] {
  if (!Array.isArray(value) || value.length > max) fail(path, `lista com no máximo ${max} itens esperada`);
  const output: string[] = [];
  const seen = new Set<string>();
  for (const [index, item] of value.entries()) {
    if (typeof item !== "string" || item.length < 1 || item.length > 80) fail(`${path}.${index}`, "ID inválido");
    if (seen.has(item)) fail(path, "IDs duplicados não são permitidos");
    seen.add(item);
    output.push(item);
  }
  return output;
}

function validateGenericTree(value: unknown, path = "$", depth = 0, nodes = { count: 0 }): void {
  nodes.count += 1;
  if (nodes.count > 10_000) fail(path, "estrutura grande demais");
  if (depth > 12) fail(path, "profundidade máxima excedida");
  if (value === null || typeof value === "boolean") return;
  if (typeof value === "number") {
    if (!Number.isFinite(value)) fail(path, "número não finito");
    return;
  }
  if (typeof value === "string") {
    if (value.length > 512) fail(path, "texto grande demais");
    return;
  }
  if (Array.isArray(value)) {
    // A Bíblia completa possui 1.189 capítulos. O limite estrutural precisa
    // comportar `capitulosLidos`; limites menores por campo são aplicados abaixo.
    if (value.length > 2_048) fail(path, "lista grande demais");
    value.forEach((item, index) => { validateGenericTree(item, `${path}.${index}`, depth + 1, nodes); });
    return;
  }
  if (!isObject(value)) fail(path, "tipo JSON não suportado");
  const entries = Object.entries(value);
  if (entries.length > 256) fail(path, "objeto grande demais");
  for (const [key, item] of entries) {
    if (key.length < 1 || key.length > 80) fail(path, "chave inválida");
    validateGenericTree(item, `${path}.${key}`, depth + 1, nodes);
  }
}

function validUpgradeId(id: string): boolean {
  if (CURATED_UPGRADE_IDS.has(id)) return true;
  const match = /^u[bs]([1-9]|[12]\d|3[0-6])_(I|II|III|IV|V)$/u.exec(id);
  return match !== null;
}

function validateGeneratorMap(value: unknown): void {
  const map = objectAt(value, "$.geradores");
  if (Object.keys(map).length > 36) fail("$.geradores", "há mais de 36 geradores");
  for (const [key, rawState] of Object.entries(map)) {
    const id = Number(key);
    if (!Number.isInteger(id) || id < 1 || id > 36 || String(id) !== key) fail(`$.geradores.${key}`, "gerador desconhecido");
    const state = objectAt(rawState, `$.geradores.${key}`);
    if (Object.keys(state).some((field) => !["qtd", "tem_profeta", "tempo_restante"].includes(field))) {
      fail(`$.geradores.${key}`, "campo desconhecido");
    }
    integerNonNegative(state.qtd, `$.geradores.${key}.qtd`, 10_000_000);
    if (typeof state.tem_profeta !== "boolean") fail(`$.geradores.${key}.tem_profeta`, "booleano esperado");
    if (typeof state.tempo_restante !== "number" || !Number.isFinite(state.tempo_restante)
      || state.tempo_restante < -1 || state.tempo_restante > 31_536_000) {
      fail(`$.geradores.${key}.tempo_restante`, "tempo restante fora do limite");
    }
  }
}

function validateNumericGeneratorMap(value: unknown, path: string): void {
  const map = objectAt(value, path);
  if (Object.keys(map).length > 36) fail(path, "há mais de 36 geradores");
  for (const [key, amount] of Object.entries(map)) {
    const id = Number(key);
    if (!Number.isInteger(id) || id < 1 || id > 36 || String(id) !== key) fail(`${path}.${key}`, "gerador desconhecido");
    integerNonNegative(amount, `${path}.${key}`, 10_000_000);
  }
}

function validateLedger(value: unknown, path: string, itemType: "number" | "string"): void {
  const ledger = objectAt(value, path);
  if (Object.keys(ledger).length > ADVENTURE_IDS.size) fail(path, "aventuras demais");
  for (const [adventureId, entries] of Object.entries(ledger)) {
    if (!ADVENTURE_IDS.has(adventureId) || !Array.isArray(entries) || entries.length > 64) {
      fail(`${path}.${adventureId}`, "registro de aventura invalido");
    }
    const seen = new Set<string>();
    for (const [index, entry] of entries.entries()) {
      if (itemType === "number") {
        integerNonNegative(entry, `${path}.${adventureId}.${index}`, 10_000_000);
      } else if (typeof entry !== "string" || entry.length < 1 || entry.length > 32) {
        fail(`${path}.${adventureId}.${index}`, "identificador de marco invalido");
      }
      const identity = String(entry);
      if (seen.has(identity)) fail(`${path}.${adventureId}`, "marcos duplicados nao sao permitidos");
      seen.add(identity);
    }
  }
}

function validateStudy(value: unknown): void {
  const study = objectAt(value, "$.estudo");
  const allowed = new Set(["sabedoria", "sabedoriaTotal", "progresso", "conhecimentosComprados", "conhecimentosAtivos"]);
  if (Object.keys(study).some((key) => !allowed.has(key))) fail("$.estudo", "campo desconhecido");
  integerNonNegative(study.sabedoria, "$.estudo.sabedoria", 1_000_000);
  integerNonNegative(study.sabedoriaTotal, "$.estudo.sabedoriaTotal", 1_000_000);
  const purchased = uniqueStrings(study.conhecimentosComprados, "$.estudo.conhecimentosComprados", 30);
  const active = uniqueStrings(study.conhecimentosAtivos, "$.estudo.conhecimentosAtivos", 30);
  if (purchased.some((id) => !KNOWLEDGE_IDS.has(id)) || active.some((id) => !KNOWLEDGE_IDS.has(id))) {
    fail("$.estudo.conhecimentos", "conhecimento desconhecido");
  }
  if (active.some((id) => !purchased.includes(id))) fail("$.estudo.conhecimentosAtivos", "conhecimento ativo não comprado");

  const progress = objectAt(study.progresso, "$.estudo.progresso");
  const progressKeys = new Set([
    "desbloqueados", "leiturasConcluidas", "questoesCorretas", "recompensasResgatadas",
    "paginasIluminadas", "titulo", "ultimaPassagem", "marcadores", "capitulosLidos",
  ]);
  if (Object.keys(progress).some((key) => !progressKeys.has(key))) fail("$.estudo.progresso", "campo desconhecido");
  const studies = uniqueStrings(progress.desbloqueados, "$.estudo.progresso.desbloqueados", 40);
  const readings = uniqueStrings(progress.leiturasConcluidas, "$.estudo.progresso.leiturasConcluidas", 40);
  const questions = uniqueStrings(progress.questoesCorretas, "$.estudo.progresso.questoesCorretas", 40);
  const studyPattern = /^journey_(genesis|exodus|kingdom|christ|church|history|revelation)_\d{2}$/u;
  const questionPattern = /^journey_(genesis|exodus|kingdom|christ|church|history|revelation)_\d{2}_q1$/u;
  if (studies.some((id) => !studyPattern.test(id)) || readings.some((id) => !studyPattern.test(id))) {
    fail("$.estudo.progresso", "estudo desconhecido");
  }
  if (questions.some((id) => !questionPattern.test(id))) fail("$.estudo.progresso.questoesCorretas", "questão desconhecida");
  uniqueStrings(progress.recompensasResgatadas, "$.estudo.progresso.recompensasResgatadas", 128).forEach((id) => {
    if (!/^(reading:journey_[a-z]+_\d{2}|quiz:journey_[a-z]+_\d{2}_q1|mastery:(era:[a-z_]+|journey))$/u.test(id)) {
      fail("$.estudo.progresso.recompensasResgatadas", "recompensa desconhecida");
    }
  });
  uniqueStrings(progress.paginasIluminadas, "$.estudo.progresso.paginasIluminadas", 12).forEach((id) => {
    if (!ERA_GROUPS.has(id)) fail("$.estudo.progresso.paginasIluminadas", "página desconhecida");
  });
  if (typeof progress.titulo !== "string" || progress.titulo.length > 80) fail("$.estudo.progresso.titulo", "título inválido");
  uniqueStrings(progress.marcadores, "$.estudo.progresso.marcadores", 256).forEach((id) => {
    if (!/^[A-Z0-9]{2,12}:[1-9]\d{0,2}$/u.test(id)) {
      fail("$.estudo.progresso.marcadores", "passagem desconhecida");
    }
  });
  uniqueStrings(progress.capitulosLidos, "$.estudo.progresso.capitulosLidos", 1_200).forEach((id) => {
    if (!/^[A-Z0-9]{2,12}:[1-9]\d{0,2}$/u.test(id)) {
      fail("$.estudo.progresso.capitulosLidos", "passagem desconhecida");
    }
  });
  const last = objectAt(progress.ultimaPassagem, "$.estudo.progresso.ultimaPassagem");
  if (Object.keys(last).length > 0) {
    if (typeof last.book !== "string" || !/^[A-Z0-9]{2,12}$/u.test(last.book)) fail("$.estudo.progresso.ultimaPassagem.book", "livro inválido");
    integerNonNegative(last.chapter, "$.estudo.progresso.ultimaPassagem.chapter", 200);
    integerNonNegative(last.verse, "$.estudo.progresso.ultimaPassagem.verse", 200);
  }
}

export interface ValidatedSaveMetadata {
  bytes: number;
  lastSeen: number;
}

export function validateSavePayload(
  payloadJson: string,
  schemaVersion: number,
  supportedSchema: number,
): ValidatedSaveMetadata {
  const bytes = new TextEncoder().encode(payloadJson).byteLength;
  if (bytes > MAX_SAVE_BYTES) throw new ApiError(413, "SAVE_TOO_LARGE", "O save excede o limite de 64 KiB.");
  let value: unknown;
  try {
    value = JSON.parse(payloadJson);
  } catch {
    throw new ApiError(422, "INVALID_SAVE_JSON", "payloadJson não contém JSON válido.");
  }
  validateGenericTree(value);
  const root = objectAt(value, "$");
  if (Object.keys(root).some((key) => !ROOT_KEYS.has(key))) fail("$", "campo desconhecido");
  for (const key of REQUIRED_ROOT_KEYS) if (!(key in root)) fail(`$.${key}`, "campo obrigatório ausente");
  if (schemaVersion !== supportedSchema || root.version !== schemaVersion) {
    throw new ApiError(422, "SAVE_SCHEMA_UNSUPPORTED", "A versão do save não é suportada por esta API.");
  }
  const lastSeen = finiteNonNegative(root.lastSeen, "$.lastSeen");
  for (const key of [
    "fe", "feTotalVida", "feTotalHistorica", "graca", "gloria", "gracaTotal", "gloriaTotal",
    "novaStarLastGemClaim",
  ] as const) finiteNonNegative(root[key], `$.${key}`);
  for (const key of ["santos", "santosGastos", "reliquias", "gemas", "gemasTotal", "dadivaFrutosNivel"] as const) {
    integerNonNegative(root[key], `$.${key}`);
  }
  validateLedger(root.marcosLedger, "$.marcosLedger", "number");
  validateLedger(root.moedaMarcosLedger, "$.moedaMarcosLedger", "string");
  validateGeneratorMap(root.geradores);
  validateNumericGeneratorMap(root.maiorQtdGerador, "$.maiorQtdGerador");
  const upgrades = uniqueStrings(root.upgradesComprados, "$.upgradesComprados", 500);
  if (upgrades.some((id) => !validUpgradeId(id))) fail("$.upgradesComprados", "upgrade desconhecido");
  const gifts = uniqueStrings(root.dadivasCompradas, "$.dadivasCompradas", 32);
  if (gifts.some((id) => !DADIVA_IDS.has(id))) fail("$.dadivasCompradas", "dádiva desconhecida");
  const cosmetics = uniqueStrings(root.cosmeticosComprados, "$.cosmeticosComprados", 128);
  if (cosmetics.some((id) => !COSMETIC_CATEGORIES.has(id))) fail("$.cosmeticosComprados", "cosmetico desconhecido");
  const activeCosmetics = objectAt(root.cosmeticosAtivos, "$.cosmeticosAtivos");
  if (Object.keys(activeCosmetics).length > 16) fail("$.cosmeticosAtivos", "categorias demais");
  for (const [category, cosmeticId] of Object.entries(activeCosmetics)) {
    if (typeof cosmeticId !== "string" || !cosmetics.includes(cosmeticId)
      || COSMETIC_CATEGORIES.get(cosmeticId) !== category) {
      fail(`$.cosmeticosAtivos.${category}`, "cosmetico ativo invalido");
    }
  }
  validateStudy(root.estudo);
  for (const field of ["aventurasDesbloqueadas", "aventurasConcluidas"] as const) {
    if (uniqueStrings(root[field], `$.${field}`, 3).some((id) => !ADVENTURE_IDS.has(id))) fail(`$.${field}`, "aventura desconhecida");
  }
  for (const field of ["boosts", "boostInventory"] as const) {
    const map = objectAt(root[field], `$.${field}`);
    if (Object.keys(map).some((id) => !BOOST_IDS.has(id))) fail(`$.${field}`, "boost desconhecido");
    for (const [id, amount] of Object.entries(map)) finiteNonNegative(amount, `$.${field}.${id}`);
  }
  if (root.dailyBoostVideoLastReward !== undefined && (typeof root.dailyBoostVideoLastReward !== "string" || (root.dailyBoostVideoLastReward !== "" && !BOOST_IDS.has(root.dailyBoostVideoLastReward)))) {
    fail("$.dailyBoostVideoLastReward", "boost desconhecido");
  }
  if (root.rewardVideoWindowStarted !== undefined) finiteNonNegative(root.rewardVideoWindowStarted, "$.rewardVideoWindowStarted");
  if (root.rewardVideosWatched !== undefined) integerNonNegative(root.rewardVideosWatched, "$.rewardVideosWatched", 6);
  if (root.dailyBoostVideoLastClaimed !== undefined) finiteNonNegative(root.dailyBoostVideoLastClaimed, "$.dailyBoostVideoLastClaimed");
  const stats = objectAt(root.estatisticas, "$.estatisticas");
  if (Object.keys(stats).some((key) => !["prestiges", "tempo_jogado"].includes(key))) fail("$.estatisticas", "campo desconhecido");
  integerNonNegative(stats.prestiges, "$.estatisticas.prestiges");
  finiteNonNegative(stats.tempo_jogado, "$.estatisticas.tempo_jogado");
  return { bytes, lastSeen };
}

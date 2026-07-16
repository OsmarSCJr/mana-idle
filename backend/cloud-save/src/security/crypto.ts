import { timingSafeEqual } from "node:crypto";

const ENCODER = new TextEncoder();
const CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes, (value) => value.toString(16).padStart(2, "0")).join("");
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const value of bytes) binary += String.fromCharCode(value);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/u, "");
}

function randomBytes(length: number): Uint8Array {
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  return bytes;
}

function crockfordEncode(bytes: Uint8Array): string {
  let bits = 0;
  let value = 0;
  let output = "";
  for (const byte of bytes) {
    value = (value << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      output += CROCKFORD.charAt((value >>> (bits - 5)) & 31);
      bits -= 5;
    }
  }
  if (bits > 0) output += CROCKFORD.charAt((value << (5 - bits)) & 31);
  return output;
}

function recoveryChecksum(data: string): string {
  let checksum = 0;
  for (let index = 0; index < data.length; index += 1) {
    const value = CROCKFORD.indexOf(data[index] ?? "");
    checksum = (checksum + (index + 1) * value) % CROCKFORD.length;
  }
  return CROCKFORD[checksum] ?? "0";
}

export function generateSessionToken(version: number): string {
  return `S${version}.${base64Url(randomBytes(32))}`;
}

export function getCredentialKeyVersion(value: string, prefix: "S" | "R"): number | null {
  const match = new RegExp(`^${prefix}([1-9]\\d*)[.-]`, "u").exec(value);
  if (match?.[1] === undefined) return null;
  const version = Number(match[1]);
  return Number.isSafeInteger(version) ? version : null;
}

export function generateRecoveryCode(version: number): string {
  const data = crockfordEncode(randomBytes(16));
  const compact = `${data}${recoveryChecksum(data)}`;
  const groups = compact.match(/.{1,5}/gu) ?? [compact];
  return `R${version}-${groups.join("-")}`;
}

export function normalizeRecoveryCode(input: string): string | null {
  const normalized = input.trim().toUpperCase().replaceAll("O", "0").replaceAll("I", "1").replaceAll("L", "1");
  const match = /^R([1-9]\d*)[-. ](.+)$/u.exec(normalized);
  if (match?.[1] === undefined || match[2] === undefined) return null;
  const dataWithChecksum = match[2].replace(/[-. ]/gu, "");
  if (!/^[0-9A-HJKMNP-TV-Z]{27}$/u.test(dataWithChecksum)) return null;
  const data = dataWithChecksum.slice(0, -1);
  if (dataWithChecksum.at(-1) !== recoveryChecksum(data)) return null;
  return `R${match[1]}.${dataWithChecksum}`;
}

export async function sha256Hex(value: string | Uint8Array<ArrayBuffer>): Promise<string> {
  const data = typeof value === "string" ? ENCODER.encode(value) : value;
  return bytesToHex(new Uint8Array(await crypto.subtle.digest("SHA-256", data)));
}

export async function hmacHex(secret: string, value: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    ENCODER.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return bytesToHex(new Uint8Array(await crypto.subtle.sign("HMAC", key, ENCODER.encode(value))));
}

export async function secureStringEqual(provided: string, expected: string): Promise<boolean> {
  const [left, right] = await Promise.all([
    crypto.subtle.digest("SHA-256", ENCODER.encode(provided)),
    crypto.subtle.digest("SHA-256", ENCODER.encode(expected)),
  ]);
  return timingSafeEqual(new Uint8Array(left), new Uint8Array(right));
}

export async function pseudonymize(env: Env, value: string): Promise<string> {
  return (await hmacHex(env.DELETION_PEPPER_V1, value)).slice(0, 24);
}

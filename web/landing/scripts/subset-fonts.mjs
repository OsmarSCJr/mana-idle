import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import subsetFont from "subset-font";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, "../../..");

const unicodeRanges = [
  [0x0020, 0x007e], // Basic Latin imprimível
  [0x00a0, 0x017f], // Latin-1 + Latin Extended A (subset web latin-ext)
  [0x0300, 0x036f], // Marcas diacríticas combinantes
];

const glyphSet = unicodeRanges
  .flatMap(([start, end]) => Array.from({ length: end - start + 1 }, (_, offset) => String.fromCodePoint(start + offset)))
  .join("")
  + "‘’‚“”„–—…•€£¥©®™→←↑↓↗↘↙↖≤≥≠±×÷";

const outputs = [
  {
    source: "assets/fonts/NotoSerif-Variable.ttf",
    destination: "web/landing/src/assets/noto-serif-latin.woff2",
  },
  {
    source: "assets/fonts/NotoSerif-Italic-Variable.ttf",
    destination: "web/landing/src/assets/noto-serif-italic-latin.woff2",
  },
  {
    source: "assets/fonts/NotoSerif-Variable.ttf",
    destination: "web/admin/src/assets/noto-serif-latin.woff2",
  },
  {
    source: "assets/fonts/Inter-Variable.ttf",
    destination: "web/admin/src/assets/inter-latin.woff2",
  },
];

for (const output of outputs) {
  const sourcePath = resolve(repositoryRoot, output.source);
  const destinationPath = resolve(repositoryRoot, output.destination);
  const source = await readFile(sourcePath);
  const subset = await subsetFont(source, glyphSet, {
    targetFormat: "woff2",
    preserveNameIds: [0, 1, 2, 3, 4, 5, 6],
  });
  await mkdir(dirname(destinationPath), { recursive: true });
  await writeFile(destinationPath, subset);
  process.stdout.write(`${output.destination}: ${(subset.byteLength / 1024).toFixed(1)} KiB\n`);
}

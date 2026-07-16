export function formatNumber(value: number, maximumFractionDigits = 0): string {
  return new Intl.NumberFormat("pt-BR", { maximumFractionDigits }).format(value || 0);
}

export function formatBytes(value: number): string {
  if (!Number.isFinite(value) || value <= 0) return "0 B";
  const units = ["B", "KiB", "MiB", "GiB"];
  const index = Math.min(Math.floor(Math.log(value) / Math.log(1024)), units.length - 1);
  return `${formatNumber(value / 1024 ** index, index === 0 ? 0 : 1)} ${units[index]}`;
}

export function formatDate(value: number | null | undefined): string {
  if (!value) return "—";
  const milliseconds = value < 10_000_000_000 ? value * 1000 : value;
  return new Intl.DateTimeFormat("pt-BR", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(new Date(milliseconds));
}

export function relativeDate(value: number | null | undefined): string {
  if (!value) return "nunca";
  const milliseconds = value < 10_000_000_000 ? value * 1000 : value;
  const diffSeconds = Math.round((milliseconds - Date.now()) / 1000);
  const abs = Math.abs(diffSeconds);
  const formatter = new Intl.RelativeTimeFormat("pt-BR", { numeric: "auto" });
  if (abs < 60) return formatter.format(diffSeconds, "second");
  if (abs < 3600) return formatter.format(Math.round(diffSeconds / 60), "minute");
  if (abs < 86_400) return formatter.format(Math.round(diffSeconds / 3600), "hour");
  return formatter.format(Math.round(diffSeconds / 86_400), "day");
}

export function shortId(value: string | null | undefined, length = 12): string {
  if (!value) return "—";
  return value.length <= length ? value : `${value.slice(0, length)}…`;
}

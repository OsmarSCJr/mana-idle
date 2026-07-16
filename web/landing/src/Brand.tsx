import { Sparkles } from "lucide-react";

interface BrandProps {
  compact?: boolean;
}

export function Brand({ compact = false }: BrandProps) {
  return (
    <span className={compact ? "brand brand--compact" : "brand"}>
      <span className="brand__mark" aria-hidden="true">
        <Sparkles size={compact ? 14 : 17} strokeWidth={1.8} />
      </span>
      <span>
        <strong>Maná Idle</strong>
        {!compact && <small>Bíblia Clicker</small>}
      </span>
    </span>
  );
}

import { CheckCircle2, Clock3, LoaderCircle, RefreshCw, ShieldX } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { adminApi, AdminApiError } from "../api";
import { formatDate, relativeDate, shortId } from "../format";
import type { DeletionRecord } from "../types";
import { EmptyState, ErrorPanel, LoadingBlock, PageHeader, StatusBadge } from "../components/Ui";

type Filter = "pending" | "completed";

export function DeletionsPage({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [filter, setFilter] = useState<Filter>("pending");
  const [items, setItems] = useState<DeletionRecord[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const load = useCallback(async (status: Filter, nextCursor?: string, append = false) => {
    if (append) setLoadingMore(true);
    else setLoading(true);
    setError(null);
    try {
      const result = await adminApi.deletions(status, nextCursor, 50);
      setItems((current) => append ? [...current, ...result.items] : result.items);
      setCursor(result.nextCursor ?? null);
    } catch (caught) {
      if (caught instanceof AdminApiError && (caught.status === 401 || caught.status === 403)) onUnauthorized();
      else setError(caught);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, [onUnauthorized]);

  useEffect(() => {
    void load(filter);
  }, [filter, load]);

  return (
    <>
      <PageHeader
        eyebrow="Registro anti-ressurreição"
        title="Exclusões"
        description="Acompanhe tombstones sem revelar o UUID original. Uma exclusão só é confirmada ao usuário após o cascade terminar."
        action={<button className="button button--quiet" type="button" onClick={() => void load(filter)} disabled={loading}><RefreshCw size={16} /> Atualizar</button>}
      />

      <div className="segmented-control" role="group" aria-label="Filtrar exclusões">
        <button type="button" className={filter === "pending" ? "is-active" : ""} onClick={() => setFilter("pending")}><Clock3 size={16} /> Pendentes</button>
        <button type="button" className={filter === "completed" ? "is-active" : ""} onClick={() => setFilter("completed")}><CheckCircle2 size={16} /> Concluídas</button>
      </div>

      {error && <ErrorPanel error={error} onRetry={() => void load(filter)} />}
      <section className="panel deletion-panel">
        <header className="panel__header"><div><span>{filter === "pending" ? "Requer acompanhamento" : "Histórico retido"}</span><h2>{filter === "pending" ? "Tombstones pendentes" : "Exclusões concluídas"}</h2></div><ShieldX size={22} /></header>
        {loading ? <LoadingBlock rows={6} /> : items.length === 0 ? (
          <EmptyState
            title={filter === "pending" ? "Nenhuma exclusão pendente" : "Nenhuma exclusão concluída no período"}
            text={filter === "pending" ? "A rotina de exclusão está sem trabalho aguardando conclusão." : "O histórico aparecerá aqui durante a retenção operacional."}
            icon={filter === "pending" ? <CheckCircle2 size={28} /> : <ShieldX size={28} />}
          />
        ) : (
          <div className="table-scroll">
            <table className="data-table">
              <thead><tr><th>Jogador (HMAC)</th><th>Estado</th><th>Solicitado</th><th>Concluído</th><th>Expira</th><th>Último erro</th></tr></thead>
              <tbody>
                {items.map((item) => (
                  <tr key={`${item.playerHmac}-${item.requestedAt}`}>
                    <td><code title={item.playerHmac}>{shortId(item.playerHmac, 22)}</code></td>
                    <td><StatusBadge value={item.status} /></td>
                    <td><strong>{formatDate(item.requestedAt)}</strong><small>{relativeDate(item.requestedAt)}</small></td>
                    <td>{formatDate(item.completedAt)}</td>
                    <td>{formatDate(item.expiresAt)}</td>
                    <td>{item.lastErrorCode ? <span className="error-code">{item.lastErrorCode}</span> : "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        {cursor && !loading && <button className="load-more" type="button" onClick={() => void load(filter, cursor, true)} disabled={loadingMore}>{loadingMore && <LoaderCircle className="spin" size={16} />} Carregar mais</button>}
      </section>
    </>
  );
}

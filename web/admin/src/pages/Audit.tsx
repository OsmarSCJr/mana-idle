import { FileClock, LoaderCircle, RefreshCw, ScrollText } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { adminApi, AdminApiError } from "../api";
import { formatDate, shortId } from "../format";
import type { AuditRecord } from "../types";
import { CopyButton, EmptyState, ErrorPanel, LoadingBlock, PageHeader } from "../components/Ui";

export function AuditPage({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [items, setItems] = useState<AuditRecord[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const load = useCallback(async (nextCursor?: string, append = false) => {
    if (append) setLoadingMore(true);
    else setLoading(true);
    setError(null);
    try {
      const result = await adminApi.audit(nextCursor, 50);
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
    void load();
  }, [load]);

  return (
    <>
      <PageHeader
        eyebrow="Livro de atos"
        title="Auditoria"
        description="Histórico imutável das ações administrativas. Motivo, ator e request ID acompanham cada mutação."
        action={<button className="button button--quiet" type="button" onClick={() => void load()} disabled={loading}><RefreshCw size={16} /> Atualizar</button>}
      />
      {error && <ErrorPanel error={error} onRetry={() => void load()} />}
      <section className="panel audit-panel">
        <header className="panel__header"><div><span>Trilha operacional</span><h2>Ações recentes</h2></div><ScrollText size={22} /></header>
        {loading ? <LoadingBlock rows={7} /> : items.length === 0 ? (
          <EmptyState title="Nenhuma ação registrada" text="As mutações administrativas aparecerão aqui." icon={<FileClock size={28} />} />
        ) : (
          <ol className="audit-timeline">
            {items.map((item) => (
              <li key={item.id}>
                <span className="audit-timeline__line" aria-hidden="true" />
                <span className="audit-timeline__mark" aria-hidden="true" />
                <article>
                  <header><strong>{item.action.replaceAll("_", " ")}</strong><time>{formatDate(item.createdAt)}</time></header>
                  <p>{item.reason}</p>
                  <dl>
                    <div><dt>Ator</dt><dd>{item.actor}</dd></div>
                    <div><dt>Alvo</dt><dd>{item.targetType} · {shortId(item.targetIdHash, 16)}</dd></div>
                    <div><dt>Request</dt><dd><code>{shortId(item.requestId, 18)}</code><CopyButton value={item.requestId} /></dd></div>
                  </dl>
                </article>
              </li>
            ))}
          </ol>
        )}
        {cursor && !loading && <button className="load-more" type="button" onClick={() => void load(cursor, true)} disabled={loadingMore}>{loadingMore && <LoaderCircle className="spin" size={16} />} Carregar mais eventos</button>}
      </section>
    </>
  );
}

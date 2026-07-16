import {
  Activity,
  CloudCog,
  Database,
  Gem,
  HardDrive,
  RefreshCw,
  ShieldAlert,
  Smartphone,
  Users,
} from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { adminApi, AdminApiError } from "../api";
import { formatBytes, formatDate, formatNumber } from "../format";
import type { Overview } from "../types";
import { ErrorPanel, LoadingBlock, MetricCard, PageHeader } from "../components/Ui";

export function DashboardPage({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [overview, setOverview] = useState<Overview | null>(null);
  const [error, setError] = useState<unknown>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setOverview(await adminApi.overview());
    } catch (caught) {
      if (caught instanceof AdminApiError && (caught.status === 401 || caught.status === 403)) {
        onUnauthorized();
      } else {
        setError(caught);
      }
    } finally {
      setLoading(false);
    }
  }, [onUnauthorized]);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <>
      <PageHeader
        eyebrow="Visão orbital"
        title="Estado do universo"
        description="Sinais operacionais do cloud save, contas e exclusões — sem expor o conteúdo dos saves."
        action={
          <button className="button button--quiet" type="button" onClick={() => void load()} disabled={loading}>
            <RefreshCw size={16} /> Atualizar
          </button>
        }
      />

      {error && <ErrorPanel error={error} onRetry={() => void load()} />}
      {loading && !overview ? (
        <LoadingBlock rows={6} label="Carregando visão geral" />
      ) : overview ? (
        <>
          <section className="metric-grid" aria-label="Métricas principais">
            <MetricCard
              label="Jogadores ativos"
              value={formatNumber(overview.players.active)}
              detail={`${formatNumber(overview.players.deleting)} em exclusão`}
              icon={<Users size={20} />}
              tone="gold"
            />
            <MetricCard
              label="Saves com payload"
              value={formatNumber(overview.saves.withPayload)}
              detail={`${formatNumber(overview.saves.total)} registros no total`}
              icon={<Database size={20} />}
              tone="blue"
            />
            <MetricCard
              label="Sessões ativas"
              value={formatNumber(overview.sessions.active)}
              detail="Tokens válidos e não revogados"
              icon={<Smartphone size={20} />}
              tone="teal"
            />
            <MetricCard
              label="Exclusões pendentes"
              value={formatNumber(overview.deletions.pending)}
              detail="Tombstones aguardando conclusão"
              icon={<ShieldAlert size={20} />}
              tone={overview.deletions.pending > 0 ? "red" : "teal"}
            />
          </section>

          <section className="dashboard-grid">
            <article className="panel storage-panel">
              <header className="panel__header">
                <div><span>Armazenamento</span><h2>Peso dos saves</h2></div>
                <HardDrive size={21} />
              </header>
              <div className="storage-figure">
                <strong>{formatBytes(overview.saves.avgBytes)}</strong>
                <span>média por save</span>
              </div>
              <progress
                className="storage-track"
                max={65_536}
                value={Math.min(65_536, overview.saves.maxBytes)}
                aria-label={`${formatBytes(overview.saves.maxBytes)} usados do limite de 64 KiB`}
              />
              <dl className="detail-list detail-list--inline">
                <div><dt>Maior payload</dt><dd>{formatBytes(overview.saves.maxBytes)}</dd></div>
                <div><dt>Limite</dt><dd>64 KiB</dd></div>
              </dl>
            </article>

            <article className="panel wallet-panel">
              <header className="panel__header">
                <div><span>Economia gratuita</span><h2>Gemas em circulação</h2></div>
                <Gem size={21} />
              </header>
              <div className="wallet-figure">
                <span className="wallet-figure__gem" aria-hidden="true"><Gem /></span>
                <strong>{formatNumber(overview.wallet.freeOutstanding)}</strong>
              </div>
              <p>Saldo gratuito server-authoritative. Nenhuma compra está habilitada nesta fase.</p>
            </article>

            <article className="panel posture-panel">
              <header className="panel__header">
                <div><span>Postura</span><h2>Sinais de operação</h2></div>
                <CloudCog size={21} />
              </header>
              <ul className="signal-list">
                <li><span className="signal signal--ok" /><div><strong>API respondeu</strong><small>Visão geral recebida agora</small></div></li>
                <li><span className="signal signal--ok" /><div><strong>Conteúdo protegido</strong><small>Sem payloads no dashboard</small></div></li>
                <li className={overview.deletions.pending > 0 ? "signal-list__attention" : ""}>
                  <span className={overview.deletions.pending > 0 ? "signal signal--warn" : "signal signal--ok"} />
                  <div><strong>Fila de exclusão</strong><small>{overview.deletions.pending > 0 ? "Requer acompanhamento" : "Sem pendências"}</small></div>
                </li>
              </ul>
            </article>

            <article className="panel time-panel">
              <header className="panel__header">
                <div><span>Relógio do Worker</span><h2>Referência temporal</h2></div>
                <Activity size={21} />
              </header>
              <strong>{formatDate(overview.serverNow)}</strong>
              <p>Horário retornado pelo servidor, usado como referência para sessões e exclusões.</p>
            </article>
          </section>
        </>
      ) : null}
    </>
  );
}

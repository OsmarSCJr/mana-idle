import {
  ArchiveRestore,
  ChevronRight,
  CircleOff,
  Database,
  Gem,
  KeyRound,
  Laptop,
  LoaderCircle,
  LogOut,
  RefreshCw,
  Search,
  Shield,
  ShieldAlert,
  Smartphone,
  UserRoundSearch,
  X,
} from "lucide-react";
import { FormEvent, useCallback, useEffect, useState } from "react";
import { adminApi, AdminApiError } from "../api";
import { formatBytes, formatDate, formatNumber, relativeDate, shortId } from "../format";
import type { PlayerDetail, PlayerListItem } from "../types";
import {
  ConfirmDialog,
  CopyButton,
  EmptyState,
  ErrorPanel,
  LoadingBlock,
  PageHeader,
  StatusBadge,
  type ConfirmationRequest,
} from "../components/Ui";

export function PlayersPage({ onUnauthorized, onToast }: {
  onUnauthorized: () => void;
  onToast: (message: string) => void;
}) {
  const [query, setQuery] = useState("");
  const [submittedQuery, setSubmittedQuery] = useState("");
  const [players, setPlayers] = useState<PlayerListItem[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<PlayerDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState<unknown>(null);
  const [confirmation, setConfirmation] = useState<ConfirmationRequest | null>(null);

  const handleError = useCallback((caught: unknown, setter: (error: unknown) => void) => {
    if (caught instanceof AdminApiError && (caught.status === 401 || caught.status === 403)) onUnauthorized();
    else setter(caught);
  }, [onUnauthorized]);

  const search = useCallback(async (nextQuery: string, nextCursor?: string, append = false) => {
    if (append) setLoadingMore(true);
    else setLoading(true);
    setError(null);
    try {
      const result = await adminApi.players(nextQuery.trim(), nextCursor, 25);
      setPlayers((current) => append ? [...current, ...result.items] : result.items);
      setCursor(result.nextCursor ?? null);
      setSubmittedQuery(nextQuery.trim());
    } catch (caught) {
      handleError(caught, setError);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, [handleError]);

  useEffect(() => {
    void search("");
  }, [search]);

  const loadDetail = useCallback(async (playerId: string) => {
    setSelectedId(playerId);
    setDetail(null);
    setDetailError(null);
    setDetailLoading(true);
    try {
      setDetail(await adminApi.player(playerId));
    } catch (caught) {
      handleError(caught, setDetailError);
    } finally {
      setDetailLoading(false);
    }
  }, [handleError]);

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void search(query);
  }

  async function refreshAfterMutation(message: string) {
    if (selectedId) await loadDetail(selectedId);
    await search(submittedQuery);
    onToast(message);
  }

  function requestDeviceRevocation(deviceId: string, label: string) {
    if (!selectedId) return;
    setConfirmation({
      title: "Revogar este aparelho?",
      description: `${label} perderá acesso ao save online. Todas as sessões desse aparelho também serão revogadas.`,
      confirmLabel: "Revogar aparelho",
      tone: "danger",
      onConfirm: async (reason) => {
        await adminApi.revokeDevice(selectedId, deviceId, reason);
        await refreshAfterMutation("Aparelho e sessões vinculadas foram revogados.");
      },
    });
  }

  function requestSessionRevocation() {
    if (!selectedId) return;
    setConfirmation({
      title: "Revogar todas as sessões?",
      description: "Todos os aparelhos precisarão recuperar a conta novamente. O save e os dispositivos não serão apagados.",
      confirmLabel: "Revogar sessões",
      tone: "danger",
      onConfirm: async (reason) => {
        const result = await adminApi.revokeAllSessions(selectedId, reason);
        await refreshAfterMutation(`${formatNumber(result.revokedSessions)} sessões foram revogadas.`);
      },
    });
  }

  function requestSaveRestore() {
    const save = detail?.save;
    if (!selectedId || !save || save.previousRevision === null) return;
    setConfirmation({
      title: "Restaurar a cópia anterior?",
      description: `A revisão anterior ${save.previousRevision} será promovida para uma nova revisão. O save atual será preservado como cópia anterior.`,
      confirmLabel: "Criar nova revisão",
      tone: "warning",
      onConfirm: async (reason) => {
        const result = await adminApi.restorePreviousSave(selectedId, save.revision, reason);
        await refreshAfterMutation(`Save restaurado como revisão ${result.revision}.`);
      },
    });
  }

  return (
    <>
      <PageHeader
        eyebrow="Catálogo de contas"
        title="Jogadores"
        description="Localize por UUID e examine apenas metadados operacionais. O painel não lê nem edita o payload do jogo."
      />

      <form className="player-search" role="search" onSubmit={submit}>
        <label htmlFor="player-query">Buscar jogador</label>
        <div>
          <Search size={18} aria-hidden="true" />
          <input id="player-query" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="UUID do jogador — deixe vazio para ver os mais recentes" spellCheck={false} />
          {query && <button type="button" onClick={() => setQuery("")} aria-label="Limpar busca"><X size={16} /></button>}
        </div>
        <button className="button button--primary" type="submit" disabled={loading}>Buscar</button>
      </form>

      {error && <ErrorPanel error={error} onRetry={() => void search(submittedQuery)} />}
      <section className="panel players-panel">
        <header className="panel__header">
          <div>
            <span>{submittedQuery ? "Resultado da consulta" : "Contas recentes"}</span>
            <h2>{submittedQuery ? `Busca: ${shortId(submittedQuery, 22)}` : "Jogadores cadastrados"}</h2>
          </div>
          <button className="icon-button" type="button" onClick={() => void search(submittedQuery)} disabled={loading} aria-label="Atualizar lista"><RefreshCw size={17} /></button>
        </header>

        {loading ? <LoadingBlock rows={5} /> : players.length === 0 ? (
          <EmptyState title="Nenhum jogador encontrado" text="Confira o UUID ou tente uma busca vazia para listar as contas mais recentes." icon={<UserRoundSearch size={27} />} />
        ) : (
          <div className="table-scroll">
            <table className="data-table players-table">
              <thead><tr><th>Jogador</th><th>Estado</th><th>Dispositivos</th><th>Sessões</th><th>Save</th><th>Gemas</th><th><span className="sr-only">Abrir</span></th></tr></thead>
              <tbody>
                {players.map((player) => (
                  <tr key={player.playerId} className={selectedId === player.playerId ? "is-selected" : ""}>
                    <td><button className="id-link" type="button" onClick={() => void loadDetail(player.playerId)}><strong>{shortId(player.playerId, 18)}</strong><small>Criado {formatDate(player.createdAt)}</small></button></td>
                    <td><StatusBadge value={player.status} /></td>
                    <td>{formatNumber(player.deviceCount)}</td>
                    <td>{formatNumber(player.activeSessionCount)}</td>
                    <td>
                      <strong>r{formatNumber(player.saveRevision)}</strong>
                      <small>{player.saveBytes === null ? "Ainda sem upload" : `${formatBytes(player.saveBytes)} · ${relativeDate(player.saveUpdatedAt)}`}</small>
                    </td>
                    <td>{formatNumber(player.freeBalance)}</td>
                    <td><button className="row-open" type="button" onClick={() => void loadDetail(player.playerId)} aria-label={`Abrir jogador ${player.playerId}`}><ChevronRight size={17} /></button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {cursor && !loading && (
          <button className="load-more" type="button" onClick={() => void search(submittedQuery, cursor, true)} disabled={loadingMore}>
            {loadingMore && <LoaderCircle className="spin" size={16} />} Carregar mais contas
          </button>
        )}
      </section>

      {selectedId && (
        <div className="detail-backdrop" onMouseDown={(event) => {
          if (event.target === event.currentTarget) setSelectedId(null);
        }}>
          <aside className="player-drawer" role="dialog" aria-modal="true" aria-labelledby="player-detail-title">
            <header className="player-drawer__header">
              <div><span>Conta selecionada</span><h2 id="player-detail-title">{shortId(selectedId, 24)}</h2></div>
              <button className="icon-button" type="button" onClick={() => setSelectedId(null)} aria-label="Fechar detalhes"><X size={19} /></button>
            </header>

            {detailLoading ? <LoadingBlock rows={8} /> : detailError ? <ErrorPanel error={detailError} onRetry={() => void loadDetail(selectedId)} /> : detail ? (
              <div className="player-drawer__body">
                <section className="drawer-identity">
                  <div><StatusBadge value={detail.player.status} /><span>Criado {formatDate(detail.player.createdAt)}</span></div>
                  <code>{detail.player.playerId}</code>
                  <CopyButton value={detail.player.playerId} label="Copiar UUID" />
                </section>

                <section className="drawer-section save-summary">
                  <header><span><Database size={18} /> Save cloud</span><strong>{detail.save ? `r${detail.save.revision}` : "ausente"}</strong></header>
                  {detail.save ? (
                    <>
                      <dl className="detail-list detail-list--grid">
                        <div><dt>Schema</dt><dd>{detail.save.schemaVersion === null ? "—" : `v${detail.save.schemaVersion}`}</dd></div>
                        <div><dt>Tamanho</dt><dd>{detail.save.bytes === null ? "—" : formatBytes(detail.save.bytes)}</dd></div>
                        <div><dt>Atualizado</dt><dd>{formatDate(detail.save.updatedAt)}</dd></div>
                        <div><dt>Cópia anterior</dt><dd>{detail.save.previousRevision === null ? "Nenhuma" : `r${detail.save.previousRevision}`}</dd></div>
                        <div className="detail-list__wide"><dt>SHA-256</dt><dd title={detail.save.sha256 ?? undefined}>{shortId(detail.save.sha256, 28)}</dd></div>
                      </dl>
                      <button className="button button--warning" type="button" onClick={requestSaveRestore} disabled={detail.save.previousRevision === null || detail.player.status !== "active"}>
                        <ArchiveRestore size={16} /> Restaurar cópia anterior
                      </button>
                    </>
                  ) : <EmptyState title="Save ausente" text="A conta não possui o registro de cloud save esperado; investigue a integridade do banco." icon={<ShieldAlert size={26} />} />}
                </section>

                <section className="drawer-section wallet-summary">
                  <header><span><Gem size={18} /> Carteira</span><strong>{detail.wallet ? formatNumber(detail.wallet.freeBalance) : "ausente"}</strong></header>
                  {detail.wallet ? <dl className="detail-list detail-list--inline">
                    <div><dt>Saldo gratuito</dt><dd>{formatNumber(detail.wallet.freeBalance)}</dd></div>
                    <div><dt>Saldo pago</dt><dd>{formatNumber(detail.wallet.paidBalance ?? 0)}</dd></div>
                    <div><dt>Revisão</dt><dd>{formatNumber(detail.wallet.revision)}</dd></div>
                  </dl> : <p className="drawer-note drawer-note--danger">Registro de carteira ausente; investigue a integridade do banco.</p>}
                  <p className="drawer-note">O painel é somente leitura para saldos; não há concessão manual de gemas.</p>
                </section>

                <section className="drawer-section">
                  <header><span><Smartphone size={18} /> Aparelhos</span><strong>{detail.devices.length}</strong></header>
                  {detail.devices.length === 0 ? <EmptyState title="Sem aparelhos" text="Nenhum dispositivo vinculado." /> : (
                    <ul className="entity-list">
                      {detail.devices.map((device) => {
                        const label = device.deviceLabel || device.platform || (device.kind === "web_deletion" ? "Página de exclusão" : "Aparelho sem nome");
                        return (
                          <li key={device.deviceId}>
                            <span className="entity-list__icon">{device.platform?.toLowerCase().includes("android") ? <Smartphone size={18} /> : <Laptop size={18} />}</span>
                            <div><strong>{label}</strong><code>{shortId(device.deviceId, 18)}</code><small>{device.clientVersion || "versão desconhecida"} · visto {relativeDate(device.lastSeenAt)}</small></div>
                            {device.revokedAt ? <StatusBadge value="revoked" /> : <button className="icon-button icon-button--danger" type="button" onClick={() => requestDeviceRevocation(device.deviceId, label)} aria-label={`Revogar ${label}`}><CircleOff size={17} /></button>}
                          </li>
                        );
                      })}
                    </ul>
                  )}
                </section>

                <section className="drawer-section">
                  <header><span><KeyRound size={18} /> Sessões</span><strong>{detail.sessions.filter((session) => !session.revokedAt).length} ativas</strong></header>
                  {detail.sessions.length === 0 ? <EmptyState title="Sem sessões" text="Nenhuma sessão registrada." /> : (
                    <ul className="entity-list entity-list--sessions">
                      {detail.sessions.map((session) => (
                        <li key={session.sessionId}>
                          <span className="entity-list__icon"><Shield size={18} /></span>
                          <div><strong>{session.purpose === "account_deletion" ? "Exclusão efêmera" : "Sessão de jogo"}</strong><code>{shortId(session.sessionId, 18)}</code><small>expira {formatDate(session.idleExpiresAt)} · visto {relativeDate(session.lastSeenAt)}</small></div>
                          <StatusBadge value={session.revokedAt ? "revoked" : "active"} />
                        </li>
                      ))}
                    </ul>
                  )}
                  <button className="button button--danger-outline" type="button" onClick={requestSessionRevocation} disabled={detail.sessions.every((session) => session.revokedAt)}>
                    <LogOut size={16} /> Revogar todas as sessões
                  </button>
                </section>

                <section className="drawer-section">
                  <header><span><ShieldAlert size={18} /> Ações de segurança</span><strong>{detail.securityActions.length}</strong></header>
                  {detail.securityActions.length === 0 ? <EmptyState title="Sem ações pendentes" text="Nenhum reset ou exclusão agendada." /> : (
                    <ul className="security-list">
                      {detail.securityActions.map((action) => (
                        <li key={action.id}><div><strong>{action.kind.replaceAll("_", " ")}</strong><small>Criada {formatDate(action.createdAt)} · executa {formatDate(action.executeAfter)}</small></div><StatusBadge value={action.status} /></li>
                      ))}
                    </ul>
                  )}
                </section>
              </div>
            ) : null}
          </aside>
        </div>
      )}

      {confirmation && <ConfirmDialog request={confirmation} onClose={() => setConfirmation(null)} />}
    </>
  );
}

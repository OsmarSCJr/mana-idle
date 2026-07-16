import { LockKeyhole, RefreshCw, Save, ShieldCheck, ToggleLeft, TriangleAlert } from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { adminApi, AdminApiError } from "../api";
import { formatDate } from "../format";
import type { Operations } from "../types";
import { ErrorPanel, LoadingBlock, PageHeader } from "../components/Ui";

export function OperationsPage({ onUnauthorized, onToast }: {
  onUnauthorized: () => void;
  onToast: (message: string) => void;
}) {
  const [saved, setSaved] = useState<Operations | null>(null);
  const [draft, setDraft] = useState<Operations | null>(null);
  const [reason, setReason] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const operations = await adminApi.operations();
      setSaved(operations);
      setDraft(operations);
      setReason("");
    } catch (caught) {
      if (caught instanceof AdminApiError && (caught.status === 401 || caught.status === 403)) onUnauthorized();
      else setError(caught);
    } finally {
      setLoading(false);
    }
  }, [onUnauthorized]);

  useEffect(() => {
    void load();
  }, [load]);

  const changed = useMemo(() => {
    if (!saved || !draft) return false;
    return saved.maintenanceMode !== draft.maintenanceMode
      || saved.readOnlyUploads !== draft.readOnlyUploads
      || saved.allowNewAccounts !== draft.allowNewAccounts
      || saved.minClientVersion !== draft.minClientVersion;
  }, [saved, draft]);

  async function save() {
    if (!saved || !draft || !changed || reason.trim().length < 3) return;
    setSaving(true);
    setError(null);
    try {
      const updated = await adminApi.updateOperations(
        {
          maintenanceMode: draft.maintenanceMode,
          readOnlyUploads: draft.readOnlyUploads,
          allowNewAccounts: draft.allowNewAccounts,
          minClientVersion: draft.minClientVersion?.trim() || null,
        },
        reason.trim(),
      );
      setSaved(updated);
      setDraft(updated);
      setReason("");
      onToast("Postura operacional atualizada e registrada na auditoria.");
    } catch (caught) {
      if (caught instanceof AdminApiError && (caught.status === 401 || caught.status === 403)) onUnauthorized();
      else setError(caught);
    } finally {
      setSaving(false);
    }
  }

  function update<K extends keyof Operations>(key: K, value: Operations[K]) {
    setDraft((current) => current ? { ...current, [key]: value } : current);
  }

  return (
    <>
      <PageHeader
        eyebrow="Chaves de operação"
        title="Postura do serviço"
        description="Controles globais de contingência. Toda alteração exige justificativa e entra no log de auditoria."
        action={<button className="button button--quiet" type="button" onClick={() => void load()} disabled={loading}><RefreshCw size={16} /> Recarregar</button>}
      />

      {error && <ErrorPanel error={error} onRetry={() => void load()} />}
      {loading && !draft ? <LoadingBlock rows={5} /> : draft && saved ? (
        <div className="operations-layout">
          <section className="panel operations-controls">
            <header className="panel__header">
              <div><span>Controles globais</span><h2>Estados de contingência</h2></div>
              <ToggleLeft size={22} />
            </header>

            <label className="operation-toggle operation-toggle--critical">
              <span className="operation-toggle__icon"><TriangleAlert size={19} /></span>
              <span><strong>Modo manutenção</strong><small>Bloqueia rotas cloud durante incidentes e restaurações.</small></span>
              <input type="checkbox" checked={draft.maintenanceMode} onChange={(event) => update("maintenanceMode", event.target.checked)} />
              <span className="switch" aria-hidden="true" />
            </label>

            <label className="operation-toggle">
              <span className="operation-toggle__icon"><LockKeyhole size={19} /></span>
              <span><strong>Uploads somente leitura</strong><small>Mantém downloads e recovery, mas impede PUT de saves.</small></span>
              <input type="checkbox" checked={draft.readOnlyUploads} onChange={(event) => update("readOnlyUploads", event.target.checked)} />
              <span className="switch" aria-hidden="true" />
            </label>

            <label className="operation-toggle">
              <span className="operation-toggle__icon"><ShieldCheck size={19} /></span>
              <span><strong>Permitir novas contas</strong><small>Desative para conter criação de players sem interromper os existentes.</small></span>
              <input type="checkbox" checked={draft.allowNewAccounts} onChange={(event) => update("allowNewAccounts", event.target.checked)} />
              <span className="switch" aria-hidden="true" />
            </label>

            <div className="operation-field">
              <label htmlFor="min-client-version">Versão mínima do cliente</label>
              <p>Deixe vazio para não exigir versão. Use apenas em incompatibilidade real.</p>
              <input id="min-client-version" value={draft.minClientVersion ?? ""} onChange={(event) => update("minClientVersion", event.target.value || null)} placeholder="Ex.: 0.2.0" />
            </div>
          </section>

          <aside className="operations-review">
            <section className="panel operations-status">
              <span>Estado salvo</span>
              <strong className={saved.maintenanceMode ? "status-title status-title--danger" : "status-title"}>
                {saved.maintenanceMode ? "Em manutenção" : saved.readOnlyUploads ? "Somente leitura" : "Operacional"}
              </strong>
              <dl className="detail-list">
                <div><dt>Novas contas</dt><dd>{saved.allowNewAccounts ? "Permitidas" : "Bloqueadas"}</dd></div>
                <div><dt>Cliente mínimo</dt><dd>{saved.minClientVersion || "Sem mínimo"}</dd></div>
                <div><dt>Atualizado</dt><dd>{formatDate(saved.updatedAt)}</dd></div>
              </dl>
            </section>

            <section className="panel operations-save">
              <label htmlFor="operations-reason">Justificativa da alteração</label>
              <textarea id="operations-reason" value={reason} onChange={(event) => setReason(event.target.value)} maxLength={300} placeholder="Incidente, rollout ou motivo da mudança…" disabled={!changed || saving} />
              <button className="button button--primary" type="button" onClick={() => void save()} disabled={!changed || reason.trim().length < 3 || saving}>
                <Save size={16} /> {saving ? "Aplicando…" : "Aplicar alterações"}
              </button>
              {!changed && <small>Nenhuma alteração pendente.</small>}
            </section>
          </aside>
        </div>
      ) : null}
    </>
  );
}

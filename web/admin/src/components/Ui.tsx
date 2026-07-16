import {
  AlertTriangle,
  Check,
  Clipboard,
  Inbox,
  LoaderCircle,
  RefreshCw,
  X,
} from "lucide-react";
import { ReactNode, useEffect, useId, useRef, useState } from "react";
import { AdminApiError } from "../api";

export function StatusBadge({ value }: { value: string }) {
  const normalized = value.toLowerCase().replaceAll("_", "-");
  const labels: Record<string, string> = {
    active: "Ativo",
    deleting: "Excluindo",
    pending: "Pendente",
    completed: "Concluído",
    revoked: "Revogado",
    cancelled: "Cancelado",
    failed: "Falhou",
    healthy: "Saudável",
    draft: "Rascunho",
    published: "Publicado",
    superseded: "Substituído",
    scheduled: "Agendada",
    ended: "Encerrada",
  };
  return <span className={`badge badge--${normalized}`}>{labels[normalized] ?? value}</span>;
}

export function PageHeader({ eyebrow, title, description, action }: {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <header className="page-heading">
      <div>
        <span>{eyebrow}</span>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      {action && <div className="page-heading__action">{action}</div>}
    </header>
  );
}

export function MetricCard({ label, value, detail, icon, tone = "gold" }: {
  label: string;
  value: string;
  detail: string;
  icon: ReactNode;
  tone?: "gold" | "teal" | "blue" | "red";
}) {
  return (
    <article className={`metric-card metric-card--${tone}`}>
      <span className="metric-card__icon">{icon}</span>
      <p>{label}</p>
      <strong>{value}</strong>
      <small>{detail}</small>
    </article>
  );
}

export function LoadingBlock({ rows = 4, label = "Carregando" }: { rows?: number; label?: string }) {
  return (
    <div className="loading-block" role="status" aria-label={label}>
      {Array.from({ length: rows }, (_, index) => (
        <span key={index} />
      ))}
    </div>
  );
}

export function EmptyState({ title, text, icon }: { title: string; text: string; icon?: ReactNode }) {
  return (
    <div className="empty-state">
      <span>{icon ?? <Inbox size={26} />}</span>
      <h3>{title}</h3>
      <p>{text}</p>
    </div>
  );
}

export function ErrorPanel({ error, onRetry }: { error: unknown; onRetry?: () => void }) {
  const apiError = error instanceof AdminApiError ? error : null;
  return (
    <div className="error-panel" role="alert">
      <AlertTriangle size={22} />
      <div>
        <strong>{apiError?.message ?? "Não foi possível carregar os dados."}</strong>
        {apiError?.requestId && <small>Request ID: {apiError.requestId}</small>}
      </div>
      {onRetry && (
        <button className="icon-button" type="button" onClick={onRetry} aria-label="Tentar novamente">
          <RefreshCw size={17} />
        </button>
      )}
    </div>
  );
}

export function CopyButton({ value, label = "Copiar" }: { value: string; label?: string }) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    await navigator.clipboard.writeText(value);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1500);
  }

  return (
    <button className="copy-button" type="button" onClick={() => void copy()} aria-label={`${label}: ${value}`}>
      {copied ? <Check size={14} /> : <Clipboard size={14} />}
      {copied ? "Copiado" : label}
    </button>
  );
}

export interface ConfirmationRequest {
  title: string;
  description: string;
  confirmLabel: string;
  reasonLabel?: string;
  tone?: "danger" | "warning" | "default";
  onConfirm: (reason: string) => Promise<void>;
}

export function ConfirmDialog({ request, onClose }: {
  request: ConfirmationRequest;
  onClose: () => void;
}) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const titleId = useId();
  const descriptionId = useId();
  const reasonId = useId();
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<unknown>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    dialog.showModal();
    return () => dialog.close();
  }, []);

  async function confirm() {
    if (reason.trim().length < 3 || submitting) return;
    setSubmitting(true);
    setError(null);
    try {
      await request.onConfirm(reason.trim());
      onClose();
    } catch (caught) {
      setError(caught);
      setSubmitting(false);
    }
  }

  return (
    <dialog
      ref={dialogRef}
      className={`confirm-dialog confirm-dialog--${request.tone ?? "default"}`}
      aria-labelledby={titleId}
      aria-describedby={descriptionId}
      onCancel={(event) => {
        event.preventDefault();
        if (!submitting) onClose();
      }}
      onClick={(event) => {
        if (event.target === dialogRef.current && !submitting) onClose();
      }}
    >
      <div className="confirm-dialog__content" onClick={(event) => event.stopPropagation()}>
        <button className="dialog-close" type="button" onClick={onClose} disabled={submitting} aria-label="Fechar">
          <X size={18} />
        </button>
        <span className="confirm-dialog__mark"><AlertTriangle size={24} /></span>
        <h2 id={titleId}>{request.title}</h2>
        <p id={descriptionId}>{request.description}</p>
        <label htmlFor={reasonId}>{request.reasonLabel ?? "Motivo para auditoria"}</label>
        <textarea
          id={reasonId}
          value={reason}
          onChange={(event) => setReason(event.target.value)}
          minLength={3}
          maxLength={300}
          autoFocus
          disabled={submitting}
          placeholder="Descreva por que esta ação é necessária…"
        />
        {error !== null && <ErrorPanel error={error} />}
        <div className="confirm-dialog__actions">
          <button className="button button--quiet" type="button" onClick={onClose} disabled={submitting}>Cancelar</button>
          <button
            className={request.tone === "danger" ? "button button--danger" : "button button--primary"}
            type="button"
            onClick={() => void confirm()}
            disabled={reason.trim().length < 3 || submitting}
          >
            {submitting && <LoaderCircle className="spin" size={16} />}
            {request.confirmLabel}
          </button>
        </div>
      </div>
    </dialog>
  );
}

export function Toast({ message, onClose }: { message: string; onClose: () => void }) {
  useEffect(() => {
    const timer = window.setTimeout(onClose, 4500);
    return () => window.clearTimeout(timer);
  }, [message, onClose]);

  return (
    <div className="toast" role="status">
      <Check size={17} />
      <span>{message}</span>
      <button type="button" onClick={onClose} aria-label="Fechar aviso"><X size={15} /></button>
    </div>
  );
}

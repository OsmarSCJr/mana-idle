import {
  Activity,
  BookOpen,
  CloudCog,
  DatabaseZap,
  LogOut,
  Menu,
  Megaphone,
  Orbit,
  ScrollText,
  Search,
  ShieldCheck,
  ShieldX,
  Sparkles,
  Users,
  X,
} from "lucide-react";
import { ComponentType, useCallback, useEffect, useState } from "react";
import { Toast } from "./components/Ui";
import { AuditPage } from "./pages/Audit";
import { DashboardPage } from "./pages/Dashboard";
import { DeletionsPage } from "./pages/Deletions";
import { OperationsPage } from "./pages/Operations";
import { PlayersPage } from "./pages/Players";
import { LiveOpsPage } from "./pages/LiveOps";

type View = "dashboard" | "players" | "operations" | "liveops" | "deletions" | "audit";

interface NavigationItem {
  id: View;
  label: string;
  icon: ComponentType<{ size?: number; strokeWidth?: number }>;
  description: string;
}

const navigation: NavigationItem[] = [
  { id: "dashboard", label: "Visão geral", icon: Orbit, description: "Métricas do serviço" },
  { id: "players", label: "Jogadores", icon: Users, description: "Contas e dispositivos" },
  { id: "operations", label: "Operações", icon: CloudCog, description: "Postura e contingência" },
  { id: "liveops", label: "LiveOps", icon: Megaphone, description: "Balance e campanhas" },
  { id: "deletions", label: "Exclusões", icon: ShieldX, description: "Registro de tombstones" },
  { id: "audit", label: "Auditoria", icon: ScrollText, description: "Ações administrativas" },
];

function ObservatoryBrand() {
  return (
    <span className="observatory-brand">
      <span className="observatory-brand__mark" aria-hidden="true"><Sparkles size={19} /></span>
      <span><strong>Observatório</strong><small>Maná Idle · Operações</small></span>
    </span>
  );
}

function UnauthorizedPage() {
  const loginUrl = import.meta.env.VITE_ACCESS_LOGIN_URL?.trim();

  return (
    <main className="access-gate">
      <div className="access-gate__orbits" aria-hidden="true"><span /><span /><span /></div>
      <section className="access-card">
        <span className="access-card__seal"><ShieldCheck size={30} /></span>
        <p>Acesso administrativo</p>
        <h1>A sessão do observatório não está válida.</h1>
        <span>
          O painel e a API são protegidos pelo Cloudflare Access. Reautentique com a identidade
          autorizada; nenhuma credencial é armazenada neste frontend.
        </span>
        <div className="access-card__actions">
          <button className="button button--primary" type="button" onClick={() => {
            if (loginUrl) window.location.assign(loginUrl);
            else window.location.reload();
          }}>
            <ShieldCheck size={17} /> Reautenticar
          </button>
          <a className="button button--quiet" href="/cdn-cgi/access/logout"><LogOut size={17} /> Encerrar sessão Access</a>
        </div>
      </section>
    </main>
  );
}

function LiveClock() {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <time dateTime={now.toISOString()}>
      {new Intl.DateTimeFormat("pt-BR", { weekday: "short", hour: "2-digit", minute: "2-digit" }).format(now)}
    </time>
  );
}

export function App() {
  const [view, setView] = useState<View>("dashboard");
  const [mobileOpen, setMobileOpen] = useState(false);
  const [authorized, setAuthorized] = useState(true);
  const [toast, setToast] = useState<string | null>(null);
  const onUnauthorized = useCallback(() => setAuthorized(false), []);
  const closeToast = useCallback(() => setToast(null), []);

  function navigate(next: View) {
    setView(next);
    setMobileOpen(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  if (!authorized) return <UnauthorizedPage />;

  const current = navigation.find((item) => item.id === view) ?? navigation[0];
  const CurrentIcon = current.icon;

  return (
    <div className="admin-shell">
      <a className="skip-link" href="#main-content">Pular para o conteúdo</a>
      <aside className={mobileOpen ? "sidebar sidebar--open" : "sidebar"} aria-label="Navegação administrativa">
        <div className="sidebar__brand"><ObservatoryBrand /></div>
        <button className="sidebar__close" type="button" onClick={() => setMobileOpen(false)} aria-label="Fechar menu"><X size={20} /></button>
        <nav>
          <p>Navegação</p>
          {navigation.map((item) => {
            const Icon = item.icon;
            return (
              <button key={item.id} type="button" className={view === item.id ? "is-active" : ""} onClick={() => navigate(item.id)} aria-current={view === item.id ? "page" : undefined}>
                <span><Icon size={19} strokeWidth={1.7} /></span>
                <span><strong>{item.label}</strong><small>{item.description}</small></span>
              </button>
            );
          })}
        </nav>
        <div className="sidebar__foot">
          <span className="access-state"><ShieldCheck size={15} /><span><strong>Access protegido</strong><small>JWT validado no backend</small></span></span>
          <a href="/cdn-cgi/access/logout"><LogOut size={15} /> Encerrar acesso</a>
        </div>
      </aside>

      {mobileOpen && <button className="mobile-backdrop" type="button" onClick={() => setMobileOpen(false)} aria-label="Fechar menu" />}

      <div className="workspace">
        <header className="topbar">
          <div className="topbar__context">
            <button className="mobile-menu" type="button" onClick={() => setMobileOpen(true)} aria-label="Abrir menu"><Menu size={20} /></button>
            <span className="topbar__sigil"><CurrentIcon size={17} /></span>
            <div><small>Observatório /</small><strong>{current.label}</strong></div>
          </div>
          <div className="topbar__tools">
            <button type="button" onClick={() => navigate("players")}><Search size={16} /><span>Localizar jogador</span></button>
            <span className="topbar__clock"><Activity size={14} /><LiveClock /></span>
          </div>
        </header>

        <main id="main-content" className="main-content">
          <div className="main-content__constellation" aria-hidden="true" />
          {view === "dashboard" && <DashboardPage onUnauthorized={onUnauthorized} />}
          {view === "players" && <PlayersPage onUnauthorized={onUnauthorized} onToast={setToast} />}
          {view === "operations" && <OperationsPage onUnauthorized={onUnauthorized} onToast={setToast} />}
          {view === "liveops" && <LiveOpsPage onUnauthorized={onUnauthorized} onToast={setToast} />}
          {view === "deletions" && <DeletionsPage onUnauthorized={onUnauthorized} />}
          {view === "audit" && <AuditPage onUnauthorized={onUnauthorized} />}
        </main>

        <footer className="admin-footer">
          <span><BookOpen size={14} /> Maná Idle</span>
          <span><DatabaseZap size={14} /> Metadados operacionais · payloads não são exibidos</span>
          <span className="admin-footer__licenses"><a href="/licenses/OFL-NotoSerif.txt">Noto Serif</a> · <a href="/licenses/OFL-Inter.txt">Inter</a> · OFL 1.1</span>
        </footer>
      </div>
      {toast && <Toast message={toast} onClose={closeToast} />}
    </div>
  );
}

import {
  ArrowDownToLine,
  ArrowRight,
  BookHeart,
  BookOpenText,
  Check,
  ChevronRight,
  CircleAlert,
  Cloud,
  CloudOff,
  Download,
  Fingerprint,
  Hourglass,
  Menu,
  RefreshCw,
  RotateCcw,
  ShieldCheck,
  Sparkles,
  Star,
  Trash2,
  WifiOff,
  X,
} from "lucide-react";
import { FormEvent, ReactNode, useEffect, useId, useMemo, useState } from "react";
import { Link, Route, Routes, useLocation } from "react-router-dom";
import journeyScreen from "../../../assets/stitch/screens/jornada.png";
import prophetsScreen from "../../../assets/stitch/screens/profetas.png";
import upgradesScreen from "../../../assets/stitch/screens/upgrades.png";
import {
  checkServiceHealth,
  deleteAccountWithRecoveryCode,
  PublicApiError,
  type ServiceHealth,
} from "./api";
import { Brand } from "./Brand";
import { siteConfig } from "./config";

const UPDATED_AT = "15 de julho de 2026";

function DocumentMeta({ title, description }: { title: string; description: string }) {
  useEffect(() => {
    document.title = title;
    document.querySelector<HTMLMetaElement>('meta[name="description"]')?.setAttribute("content", description);
    document.querySelector<HTMLMetaElement>('meta[property="og:title"]')?.setAttribute("content", title);
    document.querySelector<HTMLMetaElement>('meta[property="og:description"]')?.setAttribute("content", description);
  }, [title, description]);
  return null;
}

function ScrollCoordinator() {
  const location = useLocation();

  useEffect(() => {
    if (location.hash) {
      const timer = window.setTimeout(() => {
        document.querySelector(location.hash)?.scrollIntoView({ behavior: "smooth" });
      }, 0);
      return () => window.clearTimeout(timer);
    }
    window.scrollTo({ top: 0, behavior: "instant" });
  }, [location.pathname, location.hash]);

  return null;
}

function SiteHeader() {
  const [open, setOpen] = useState(false);

  return (
    <header className="site-header">
      <div className="shell site-header__inner">
        <Link to="/" className="site-header__brand" aria-label="Maná Idle — início">
          <Brand />
        </Link>
        <button
          className="menu-toggle"
          type="button"
          aria-expanded={open}
          aria-controls="main-navigation"
          aria-label={open ? "Fechar menu" : "Abrir menu"}
          onClick={() => setOpen((value) => !value)}
        >
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
        <nav
          id="main-navigation"
          className={open ? "site-nav site-nav--open" : "site-nav"}
          aria-label="Navegação principal"
          onClick={(event) => {
            if ((event.target as HTMLElement).closest("a")) setOpen(false);
          }}
        >
          <Link to="/#jornada">A jornada</Link>
          <Link to="/#save-online">Save online</Link>
          <Link to="/#perguntas">Perguntas</Link>
          {siteConfig.downloadUrl ? (
            <a className="nav-cta" href={siteConfig.downloadUrl} rel="noreferrer">
              Baixar APK <ArrowDownToLine size={15} aria-hidden="true" />
            </a>
          ) : (
            <span className="nav-cta nav-cta--disabled" title="APK em preparação">
              APK em breve
            </span>
          )}
        </nav>
      </div>
    </header>
  );
}

function ServiceStatus() {
  const [health, setHealth] = useState<ServiceHealth>({
    state: siteConfig.apiUrl ? "offline" : "unconfigured",
    checkedAt: new Date(),
  });
  const [checking, setChecking] = useState(Boolean(siteConfig.apiUrl));

  useEffect(() => {
    const controller = new AbortController();
    void checkServiceHealth(controller.signal).then((next) => {
      if (!controller.signal.aborted) {
        setHealth(next);
        setChecking(false);
      }
    });
    return () => controller.abort();
  }, []);

  const content = {
    online: ["Operacional", "Cloud save disponível"],
    degraded: ["Instável", "Alguns serviços podem demorar"],
    offline: ["Indisponível", "Seu save local continua seguro"],
    unconfigured: ["Em preparação", "Cloud save entra na próxima etapa"],
  }[health.state];

  return (
    <div className={`service-status service-status--${health.state}`} aria-live="polite">
      <span className="service-status__signal" aria-hidden="true" />
      <span>
        <small>{checking ? "Consultando serviço" : content[0]}</small>
        <strong>{checking ? "Verificando o céu…" : content[1]}</strong>
      </span>
    </div>
  );
}

function DownloadAction({ large = false }: { large?: boolean }) {
  if (!siteConfig.downloadUrl) {
    return (
      <span className={large ? "button button--primary button--large button--disabled" : "button button--primary button--disabled"}>
        <Hourglass size={18} aria-hidden="true" /> APK em preparação
      </span>
    );
  }

  return (
    <a
      className={large ? "button button--primary button--large" : "button button--primary"}
      href={siteConfig.downloadUrl}
      rel="noreferrer"
    >
      <Download size={18} aria-hidden="true" /> Baixar APK para Android
    </a>
  );
}

function ScriptureRule({ children }: { children: ReactNode }) {
  return (
    <div className="scripture-rule" aria-label={String(children)}>
      <span aria-hidden="true" />
      <p>{children}</p>
      <span aria-hidden="true" />
    </div>
  );
}

function Hero() {
  return (
    <section className="hero" aria-labelledby="hero-title">
      <div className="hero__beam" aria-hidden="true" />
      <div className="hero__constellation hero__constellation--one" aria-hidden="true" />
      <div className="hero__constellation hero__constellation--two" aria-hidden="true" />
      <div className="shell hero__grid">
        <div className="hero__copy reveal reveal--one">
          <span className="eyebrow"><Sparkles size={14} /> Uma jornada bíblica incremental</span>
          <h1 id="hero-title">
            O tempo passa.
            <em>A jornada permanece.</em>
          </h1>
          <p className="hero__lead">
            Atravesse eras, reúna profetas e faça a Fé florescer — em um jogo contemplativo
            que continua produzindo mesmo quando você fecha o celular.
          </p>
          <div className="hero__actions">
            <DownloadAction large />
            <Link className="button button--ghost button--large" to="/#jornada">
              Conhecer o jogo <ArrowRight size={18} aria-hidden="true" />
            </Link>
          </div>
          <p className="hero__note">
            <ShieldCheck size={15} aria-hidden="true" /> Sem compras antes da publicação no
            Google Play. Seu progresso local funciona offline.
          </p>
        </div>

        <div className="hero__artifact reveal reveal--two" aria-label="Telas do jogo Maná Idle">
          <div className="orbit orbit--outer" aria-hidden="true" />
          <div className="orbit orbit--inner" aria-hidden="true" />
          <figure className="phone phone--main">
            <div className="phone__speaker" />
            <img src={journeyScreen} alt="Tela da Jornada, com eventos bíblicos da Era Gênesis" />
          </figure>
          <figure className="phone phone--behind" aria-hidden="true">
            <img src={prophetsScreen} alt="" />
          </figure>
          <div className="artifact-seal" aria-hidden="true">
            <Star size={20} />
            <span>feito com<br />reverência</span>
          </div>
        </div>
      </div>
      <div className="shell hero__footer reveal reveal--three">
        <ServiceStatus />
        <div className="hero__facts" aria-label="Características rápidas">
          <span><WifiOff size={16} /> Funciona offline</span>
          <span><Cloud size={16} /> Save online opcional</span>
          <span><BookHeart size={16} /> Em português</span>
        </div>
      </div>
    </section>
  );
}

const journeyCards = [
  {
    number: "I",
    title: "Construa através das eras",
    text: "De Haja Luz à Nova Jerusalém, cada capítulo abre novos geradores, histórias e decisões.",
    icon: <BookOpenText aria-hidden="true" />,
  },
  {
    number: "II",
    title: "Reúna seus profetas",
    text: "Personagens inspirados nas narrativas bíblicas acompanham a jornada e ampliam sua produção.",
    icon: <Sparkles aria-hidden="true" />,
  },
  {
    number: "III",
    title: "Volte e encontre progresso",
    text: "A produção offline respeita seu tempo. Entre por alguns minutos ou permaneça por uma sessão longa.",
    icon: <Hourglass aria-hidden="true" />,
  },
];

function JourneySection() {
  return (
    <section id="jornada" className="journey section">
      <div className="shell">
        <ScriptureRule>Uma história antiga, contada no seu ritmo</ScriptureRule>
        <div className="section-heading section-heading--split">
          <div>
            <span className="eyebrow">A jornada</span>
            <h2>Um idle game com alma de manuscrito.</h2>
          </div>
          <p>
            Progresso claro, sessões tranquilas e arte inspirada em pergaminhos, astros e
            iconografia bíblica — sem transformar a experiência em uma corrida.
          </p>
        </div>
        <div className="journey-grid">
          {journeyCards.map((card) => (
            <article className="journey-card" key={card.number}>
              <span className="journey-card__roman" aria-hidden="true">{card.number}</span>
              <span className="journey-card__icon">{card.icon}</span>
              <h3>{card.title}</h3>
              <p>{card.text}</p>
            </article>
          ))}
        </div>
        <div className="gallery-ribbon">
          <figure className="gallery-ribbon__screen gallery-ribbon__screen--left">
            <img src={prophetsScreen} alt="Tela de Profetas com coleção de personagens" loading="lazy" />
            <figcaption>Profetas</figcaption>
          </figure>
          <blockquote>
            <span aria-hidden="true">“</span>
            Pequenos retornos.<br />Uma longa travessia.
          </blockquote>
          <figure className="gallery-ribbon__screen gallery-ribbon__screen--right">
            <img src={upgradesScreen} alt="Tela de Upgrades com árvore de melhorias" loading="lazy" />
            <figcaption>Sabedoria</figcaption>
          </figure>
        </div>
      </div>
    </section>
  );
}

function CloudSaveSection() {
  return (
    <section id="save-online" className="cloud-save section" aria-labelledby="cloud-title">
      <div className="cloud-save__halo" aria-hidden="true" />
      <div className="shell cloud-save__grid">
        <div className="cloud-save__diagram" aria-hidden="true">
          <div className="cloud-save__ring cloud-save__ring--one" />
          <div className="cloud-save__ring cloud-save__ring--two" />
          <div className="cloud-save__center"><Cloud size={48} strokeWidth={1.25} /></div>
          <span className="cloud-save__node cloud-save__node--one"><BookOpenText size={22} /></span>
          <span className="cloud-save__node cloud-save__node--two"><RefreshCw size={22} /></span>
          <span className="cloud-save__node cloud-save__node--three"><ShieldCheck size={22} /></span>
        </div>
        <div className="cloud-save__copy">
          <span className="eyebrow">Save online opcional</span>
          <h2 id="cloud-title">Seu caminho, preservado entre aparelhos.</h2>
          <p className="cloud-save__lead">
            O jogo salva localmente primeiro. Se você ativar a nuvem, uma conta anônima com
            código de recuperação mantém o progresso sincronizado — sem exigir e-mail ou rede
            social.
          </p>
          <ul className="check-list">
            <li><Check /> Jogue sem internet; a sincronização tenta novamente depois.</li>
            <li><Check /> Recupere o progresso em outro Android com seu código.</li>
            <li><Check /> Veja e revogue aparelhos conectados.</li>
            <li><Check /> Exclua conta e save pelo jogo ou por este site.</li>
          </ul>
          <div className="cloud-save__privacy">
            <Fingerprint size={24} aria-hidden="true" />
            <p>
              <strong>Você controla a ativação.</strong> O save online é opt-in; nenhum dado de
              nuvem é necessário para jogar offline.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}

function HowItWorks() {
  const steps = [
    ["01", "Instale", "Baixe o APK assinado quando a versão pública estiver disponível."],
    ["02", "Comece local", "Jogue imediatamente. O progresso é salvo no próprio aparelho."],
    ["03", "Ative se quiser", "Crie seu save online e guarde o código de recuperação em local seguro."],
  ];

  return (
    <section id="como-jogar" className="how section">
      <div className="shell">
        <div className="section-heading section-heading--center">
          <span className="eyebrow">Comece com tranquilidade</span>
          <h2>Três passos. Nenhuma pressa.</h2>
        </div>
        <ol className="steps">
          {steps.map(([number, title, text]) => (
            <li key={number}>
              <span className="steps__number">{number}</span>
              <div><h3>{title}</h3><p>{text}</p></div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}

const questions = [
  {
    question: "O Maná Idle precisa de internet?",
    answer:
      "Não. O jogo e o save local continuam funcionando offline. A internet é usada apenas para sincronizar o save online quando você opta por ativá-lo.",
  },
  {
    question: "Preciso criar uma conta com e-mail?",
    answer:
      "Não. A conta cloud é anônima e usa um código de recuperação. Guarde esse código: sem ele e sem um aparelho ainda conectado, não conseguimos provar que a conta é sua.",
  },
  {
    question: "Haverá compras no APK?",
    answer:
      "Não antes da publicação no Google Play. A versão distribuída diretamente não processará transações financeiras.",
  },
  {
    question: "O que acontece se dois aparelhos mudarem o save?",
    answer:
      "O jogo detecta a divergência e mostra os dois estados para você escolher. Ele não substitui silenciosamente um progresso por outro.",
  },
  {
    question: "Como excluo meus dados?",
    answer:
      "Você pode excluir a conta nas configurações do jogo ou usar a página pública de exclusão com o código de recuperação.",
  },
];

function FaqSection() {
  return (
    <section id="perguntas" className="faq section">
      <div className="shell faq__grid">
        <div className="faq__intro">
          <span className="eyebrow">Perguntas frequentes</span>
          <h2>Antes de abrir o primeiro capítulo.</h2>
          <p>A experiência foi pensada para ser clara sobre rede, conta e seus dados.</p>
          <Link className="text-link" to="/privacidade">
            Leia a política de privacidade <ChevronRight size={16} />
          </Link>
        </div>
        <div className="faq__items">
          {questions.map((item, index) => (
            <details key={item.question} open={index === 0}>
              <summary>{item.question}<span aria-hidden="true">+</span></summary>
              <p>{item.answer}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}

function FinalCta() {
  return (
    <section className="final-cta">
      <div className="final-cta__stars" aria-hidden="true" />
      <div className="shell final-cta__inner">
        <span className="final-cta__sigil" aria-hidden="true"><Sparkles /></span>
        <p className="eyebrow">A primeira era espera por você</p>
        <h2>Comece pequeno.<br /><em>Construa através do tempo.</em></h2>
        <DownloadAction large />
        {!siteConfig.downloadUrl && (
          <p className="final-cta__note">O link será ativado depois da assinatura e publicação do APK.</p>
        )}
      </div>
    </section>
  );
}

function HomePage() {
  return (
    <>
      <DocumentMeta
        title="Maná Idle — Bíblia Clicker"
        description="Um jogo bíblico incremental para Android: atravesse eras, reúna profetas e continue sua jornada mesmo offline."
      />
      <main id="conteudo">
        <Hero />
        <JourneySection />
        <CloudSaveSection />
        <HowItWorks />
        <FaqSection />
        <FinalCta />
      </main>
    </>
  );
}

function LegalShell({ eyebrow, title, intro, children }: {
  eyebrow: string;
  title: string;
  intro: string;
  children: ReactNode;
}) {
  return (
    <main id="conteudo" className="legal-page">
      <DocumentMeta title={`${title} — Maná Idle`} description={intro} />
      <header className="legal-hero">
        <div className="shell legal-hero__inner">
          <span className="eyebrow">{eyebrow}</span>
          <h1>{title}</h1>
          <p>{intro}</p>
          <small>Última atualização: {UPDATED_AT}</small>
        </div>
      </header>
      <div className="shell legal-layout">
        <aside className="legal-index" aria-label="Documentos legais">
          <p>Documentos</p>
          <Link to="/privacidade">Privacidade</Link>
          <Link to="/termos">Termos de uso</Link>
          <Link to="/excluir-conta">Excluir conta</Link>
        </aside>
        <article className="legal-copy">{children}</article>
      </div>
    </main>
  );
}

function PrivacyPage() {
  return (
    <LegalShell
      eyebrow="Transparência"
      title="Política de Privacidade"
      intro="Este texto descreve o projeto técnico atual do Maná Idle e deve passar por revisão jurídica antes da beta pública."
    >
      <section>
        <h2>1. Quem controla os dados</h2>
        <p>
          O responsável pelo Maná Idle controla os dados tratados para oferecer o jogo e o save
          online. Solicitações relacionadas à privacidade podem ser enviadas para{" "}
          <a href={`mailto:${siteConfig.privacyEmail}`}>{siteConfig.privacyEmail}</a>.
        </p>
      </section>
      <section>
        <h2>2. O que é coletado</h2>
        <p>Jogar apenas com save local não exige conta na nuvem. Ao ativar o save online, tratamos:</p>
        <ul>
          <li>identificadores aleatórios de conta, aparelho e sessão;</li>
          <li>snapshot do progresso, versão do save, revisão e checksums;</li>
          <li>metadados técnicos mínimos, como versão do cliente, datas e estado da sincronização;</li>
          <li>registros de segurança, revogação, exclusão e prevenção de abuso.</li>
        </ul>
        <p>
          O save pode incluir progresso de estudo e a última passagem bíblica visitada. Esse
          contexto pode permitir inferências sobre convicção religiosa e, por isso, é tratado com
          minimização e acesso restrito. Não coletamos orações, denominação ou texto religioso livre.
        </p>
      </section>
      <section>
        <h2>3. Para que usamos</h2>
        <p>
          Os dados são usados para criar e recuperar a conta anônima, sincronizar e restaurar o
          progresso, resolver conflitos, proteger sessões, atender exclusões e manter o serviço
          disponível. Não há publicidade comportamental nem venda de dados neste projeto.
        </p>
      </section>
      <section>
        <h2>4. Compartilhamento e localização</h2>
        <p>
          Cloudflare Workers e D1 processam a API e armazenam o save. A infraestrutura pode tratar
          dados fora do Brasil; a documentação e os contratos do provedor devem ser avaliados para
          a transferência internacional antes da beta. Não compartilhamos o conteúdo do save com
          redes sociais.
        </p>
      </section>
      <section>
        <h2>5. Retenção e exclusão</h2>
        <p>
          A conta e o save permanecem enquanto o recurso estiver ativo ou até a exclusão. Após uma
          exclusão confirmada, os dados ativos são removidos. Backups privados expiram em até 30
          dias. Um identificador irreversível de exclusão (tombstone) pode ser mantido por cerca de
          45 dias para impedir que restaurações de backup ressuscitem a conta; ele não contém o save
          nem o código de recuperação.
        </p>
      </section>
      <section>
        <h2>6. Segurança e suas escolhas</h2>
        <p>
          Usamos HTTPS, tokens opacos revogáveis, hashes e controles de acesso administrativo. Você
          pode manter apenas o save local, revogar aparelhos, trocar o código de recuperação ou
          excluir a conta. Guarde o código fora do aparelho: sem ele e sem uma sessão válida, não há
          identidade externa para comprovar a posse da conta.
        </p>
      </section>
      <section>
        <h2>7. Crianças e mudanças</h2>
        <p>
          A classificação etária e os fluxos de consentimento serão definidos antes da publicação
          no Google Play. Mudanças relevantes nesta política serão publicadas nesta página, com nova
          data de atualização.
        </p>
      </section>
    </LegalShell>
  );
}

function TermsPage() {
  return (
    <LegalShell
      eyebrow="Condições da jornada"
      title="Termos de Uso"
      intro="Regras simples para a fase de testes do Maná Idle, antes da distribuição pela Google Play."
    >
      <section>
        <h2>1. Fase de desenvolvimento</h2>
        <p>
          O Maná Idle está em desenvolvimento. Versões alpha podem conter falhas, mudanças de
          balanceamento e reinicializações de progresso comunicadas previamente. Não instale APKs
          obtidos fora do endereço oficial indicado neste site.
        </p>
      </section>
      <section>
        <h2>2. Conta anônima e código de recuperação</h2>
        <p>
          O save online é opcional. Ao ativá-lo, você recebe um código de recuperação pessoal. Você
          é responsável por mantê-lo confidencial. Não solicite ou compartilhe códigos de terceiros;
          o suporte não transfere contas com base apenas em alegações de posse.
        </p>
      </section>
      <section>
        <h2>3. Uso permitido</h2>
        <p>
          Não tente prejudicar o serviço, acessar contas alheias, automatizar abuso, contornar
          limites de segurança ou explorar falhas para alterar carteiras e progressos. Podemos
          revogar sessões envolvidas em risco técnico ou abuso confirmado.
        </p>
      </section>
      <section>
        <h2>4. Sem transações nesta fase</h2>
        <p>
          Antes da publicação no Google Play, o APK não oferece compras nem processa pagamentos.
          Gemas e recompensas atuais são itens virtuais gratuitos, sem valor monetário, saque,
          transferência ou promessa de conversão futura.
        </p>
      </section>
      <section>
        <h2>5. Disponibilidade e continuidade</h2>
        <p>
          Buscamos preservar o progresso com save local, cópia anterior e sincronização condicional,
          mas serviços de teste podem ficar temporariamente indisponíveis. Quando a nuvem falhar, o
          jogo continuará salvando no aparelho e tentará sincronizar novamente.
        </p>
      </section>
      <section>
        <h2>6. Conteúdo e contato</h2>
        <p>
          Nomes, arte, código e identidade visual pertencem aos respectivos titulares. A presença de
          narrativas bíblicas não representa aconselhamento religioso. Dúvidas podem ser enviadas
          para <a href={`mailto:${siteConfig.privacyEmail}`}>{siteConfig.privacyEmail}</a>.
        </p>
      </section>
    </LegalShell>
  );
}

function DeleteAccountPage() {
  const fieldId = useId();
  const confirmationId = useId();
  const [recoveryCode, setRecoveryCode] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [acknowledged, setAcknowledged] = useState(false);
  const [state, setState] = useState<"idle" | "submitting" | "success" | "error">("idle");
  const [error, setError] = useState<{ message: string; requestId?: string } | null>(null);

  const valid = useMemo(
    () => recoveryCode.trim().length >= 8 && confirmation.trim().toUpperCase() === "EXCLUIR" && acknowledged,
    [recoveryCode, confirmation, acknowledged],
  );

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!valid || state === "submitting") return;

    const controller = new AbortController();
    setState("submitting");
    setError(null);
    try {
      await deleteAccountWithRecoveryCode(recoveryCode, controller.signal);
      setRecoveryCode("");
      setConfirmation("");
      setAcknowledged(false);
      setState("success");
    } catch (caught) {
      if (caught instanceof PublicApiError) {
        const genericRecoveryMessage = caught.status === 401
          ? "Não foi possível confirmar o código. Verifique-o e tente novamente."
          : caught.message;
        setError({ message: genericRecoveryMessage, requestId: caught.requestId });
      } else {
        setError({ message: "Não foi possível acessar o serviço. Tente novamente em alguns minutos." });
      }
      setState("error");
    }
  }

  return (
    <LegalShell
      eyebrow="Controle dos seus dados"
      title="Excluir conta e save online"
      intro="Use seu código de recuperação para apagar permanentemente a conta cloud, o progresso sincronizado e as sessões vinculadas."
    >
      {state === "success" ? (
        <div className="deletion-result deletion-result--success" role="status">
          <span><Check size={26} /></span>
          <div>
            <h2>Exclusão concluída</h2>
            <p>
              A conta e o save ativo foram removidos. Um marcador irreversível e temporário é mantido
              apenas para impedir restauração acidental a partir de backups.
            </p>
          </div>
        </div>
      ) : (
        <>
          <div className="warning-panel">
            <CircleAlert size={24} aria-hidden="true" />
            <div>
              <h2>Esta ação não pode ser desfeita</h2>
              <p>
                O progresso que existir apenas neste aparelho não é apagado por esta página. Para
                removê-lo também, use “Apagar progresso deste aparelho” dentro do jogo.
              </p>
            </div>
          </div>

          <form className="deletion-form" onSubmit={submit} noValidate>
            <div className="form-field">
              <label htmlFor={fieldId}>Código de recuperação</label>
              <p id={`${fieldId}-hint`}>Ele começa com R1 e foi exibido ao ativar o save online.</p>
              <input
                id={fieldId}
                name="recoveryCode"
                type="text"
                autoComplete="off"
                autoCapitalize="characters"
                spellCheck={false}
                value={recoveryCode}
                onChange={(event) => setRecoveryCode(event.target.value)}
                aria-describedby={`${fieldId}-hint`}
                placeholder="R1-…"
                disabled={state === "submitting" || !siteConfig.apiUrl}
                required
              />
            </div>

            <div className="form-field">
              <label htmlFor={confirmationId}>Digite EXCLUIR para confirmar</label>
              <input
                id={confirmationId}
                name="confirmation"
                type="text"
                autoComplete="off"
                value={confirmation}
                onChange={(event) => setConfirmation(event.target.value)}
                disabled={state === "submitting" || !siteConfig.apiUrl}
                required
              />
            </div>

            <label className="check-field">
              <input
                type="checkbox"
                checked={acknowledged}
                onChange={(event) => setAcknowledged(event.target.checked)}
                disabled={state === "submitting" || !siteConfig.apiUrl}
              />
              <span>Entendo que a conta, o save online e as sessões serão removidos.</span>
            </label>

            {!siteConfig.apiUrl && (
              <div className="form-message form-message--notice" role="status">
                <CloudOff size={18} /> O serviço ainda não foi configurado neste ambiente. A exclusão
                pelo app continuará disponível após o deploy da API.
              </div>
            )}

            {error && (
              <div className="form-message form-message--error" role="alert">
                <CircleAlert size={18} />
                <span>
                  {error.message}
                  {error.requestId && <small>Referência: {error.requestId}</small>}
                </span>
              </div>
            )}

            <button className="button button--danger button--large" type="submit" disabled={!valid || state === "submitting" || !siteConfig.apiUrl}>
              {state === "submitting" ? <><RefreshCw className="spin" size={18} /> Excluindo com segurança…</> : <><Trash2 size={18} /> Excluir conta permanentemente</>}
            </button>
            <p className="deletion-form__privacy">
              O código e a sessão temporária ficam apenas na memória desta página, não são salvos no
              navegador e são descartados ao concluir ou sair.
            </p>
          </form>

          <section>
            <h2>Não tenho mais o código</h2>
            <p>
              Se algum aparelho ainda estiver conectado, inicie a exclusão sem código pelas
              configurações do jogo. Por segurança, esse fluxo tem uma espera de sete dias e pode ser
              cancelado durante o período. Sem código e sem sessão válida, não existe uma identidade
              externa para comprovar a posse da conta.
            </p>
          </section>
        </>
      )}
    </LegalShell>
  );
}

function NotFoundPage() {
  return (
    <main id="conteudo" className="not-found">
      <DocumentMeta title="Página não encontrada — Maná Idle" description="Este caminho não existe no site do Maná Idle." />
      <div className="shell not-found__inner">
        <span className="not-found__number">404</span>
        <RotateCcw size={34} aria-hidden="true" />
        <h1>Este caminho ainda não foi revelado.</h1>
        <p>A página procurada não existe ou mudou de lugar.</p>
        <Link className="button button--primary" to="/">Voltar ao início</Link>
      </div>
    </main>
  );
}

function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="shell site-footer__grid">
        <div className="site-footer__about">
          <Brand />
          <p>Uma jornada bíblica incremental feita para respeitar o seu tempo.</p>
        </div>
        <nav aria-label="Links do produto">
          <p>Jogo</p>
          <Link to="/#jornada">A jornada</Link>
          <Link to="/#save-online">Save online</Link>
          <Link to="/#perguntas">Perguntas</Link>
        </nav>
        <nav aria-label="Links legais">
          <p>Seus dados</p>
          <Link to="/privacidade">Privacidade</Link>
          <Link to="/termos">Termos de uso</Link>
          <Link to="/excluir-conta">Excluir conta</Link>
        </nav>
        <div className="site-footer__status">
          <p>Serviço</p>
          <ServiceStatus />
        </div>
      </div>
      <div className="shell site-footer__bottom">
        <small>© 2026 Maná Idle. Projeto em desenvolvimento.</small>
        <small>Sem publicidade comportamental. Sem transações no APK.</small>
        <small><a href="/licenses/OFL-NotoSerif.txt">Noto Serif · OFL 1.1</a></small>
      </div>
    </footer>
  );
}

export function App() {
  return (
    <>
      <a className="skip-link" href="#conteudo">Pular para o conteúdo</a>
      <ScrollCoordinator />
      <SiteHeader />
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/privacidade" element={<PrivacyPage />} />
        <Route path="/termos" element={<TermsPage />} />
        <Route path="/excluir-conta" element={<DeleteAccountPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
      <SiteFooter />
    </>
  );
}

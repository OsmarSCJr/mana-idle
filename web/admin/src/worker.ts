interface ServiceBinding {
  fetch(request: Request): Promise<Response>;
}

interface Env {
  ASSETS: ServiceBinding;
  CLOUD_SAVE: ServiceBinding;
}

const UNSAFE_METHODS = new Set(["POST", "PUT", "PATCH", "DELETE"]);

function jsonError(status: number, code: string, message: string): Response {
  const requestId = crypto.randomUUID();
  return Response.json(
    { error: { code, message, requestId } },
    {
      status,
      headers: {
        "Cache-Control": "private, no-store",
        "X-Request-Id": requestId,
      },
    },
  );
}

function isSameOriginMutation(request: Request, url: URL): boolean {
  if (!UNSAFE_METHODS.has(request.method)) return true;

  const origin = request.headers.get("Origin");
  if (origin && origin !== url.origin) return false;

  const fetchSite = request.headers.get("Sec-Fetch-Site");
  return !fetchSite || fetchSite === "same-origin" || fetchSite === "none";
}

async function proxyAdminApi(request: Request, env: Env, url: URL): Promise<Response> {
  if (!url.pathname.startsWith("/api/v1/admin/")) {
    return jsonError(404, "NOT_FOUND", "Rota administrativa não encontrada.");
  }
  if (!isSameOriginMutation(request, url)) {
    return jsonError(403, "CROSS_ORIGIN_REJECTED", "A solicitação precisa vir do painel.");
  }

  const backendUrl = new URL(url);
  backendUrl.protocol = "https:";
  backendUrl.hostname = "cloud-save.internal";
  backendUrl.port = "";
  backendUrl.pathname = url.pathname.slice("/api".length);

  const headers = new Headers(request.headers);
  headers.delete("Cookie");
  headers.delete("Host");
  headers.set("Accept", "application/json");

  const outbound = new Request(backendUrl, {
    method: request.method,
    headers,
    body: request.method === "GET" || request.method === "HEAD" ? undefined : request.body,
    redirect: "manual",
  });
  let response: Response;
  try {
    response = await env.CLOUD_SAVE.fetch(outbound);
  } catch {
    return jsonError(502, "BACKEND_UNAVAILABLE", "O serviço de cloud save não respondeu.");
  }
  const responseHeaders = new Headers(response.headers);
  responseHeaders.set("Cache-Control", "private, no-store");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: responseHeaders,
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname.startsWith("/api/")) {
      return proxyAdminApi(request, env, url);
    }
    return env.ASSETS.fetch(request);
  },
};

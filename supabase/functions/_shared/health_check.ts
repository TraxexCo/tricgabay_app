export function healthCheckHandler(
  secret: string,
  collect: () => Promise<Record<string, number>>,
) {
  return async (request: Request): Promise<Response> => {
    const headers = {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    };
    if (request.method !== "GET") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers,
      });
    }
    const supplied = request.headers.get("x-tricgabay-monitor") ?? "";
    let mismatch = supplied.length ^ secret.length;
    for (let i = 0; i < Math.max(secret.length, supplied.length); i++) {
      mismatch |= (supplied.charCodeAt(i) || 0) ^ (secret.charCodeAt(i) || 0);
    }
    if (secret.length < 32 || mismatch !== 0) {
      return new Response(
        JSON.stringify({ error: "Monitor authentication required" }),
        { status: 401, headers },
      );
    }
    try {
      const metrics = await collect();
      const degraded = Object.values(metrics).some((count) =>
        !Number.isFinite(count) || count > 0
      );
      return new Response(
        JSON.stringify({ status: degraded ? "degraded" : "ok", metrics }),
        { status: degraded ? 503 : 200, headers },
      );
    } catch {
      return new Response(JSON.stringify({ status: "unavailable" }), {
        status: 503,
        headers,
      });
    }
  };
}

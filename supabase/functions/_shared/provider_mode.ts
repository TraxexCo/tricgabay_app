export type ProviderMode = "test" | "live";
export type ProviderConfiguration = { mode: ProviderMode; secretKey: string };

export function requireEnabledMode(
  mode: unknown,
  liveEnabled: unknown,
): ProviderMode {
  if (mode !== "test" && mode !== "live") {
    throw new Error("Invalid provider mode");
  }
  if (mode === "live" && liveEnabled !== true) {
    throw new Error("Live payments are disabled");
  }
  return mode;
}

export function providerConfiguration(
  mode: unknown,
  liveEnabled: unknown,
  testKey: string,
  liveKey: string,
): ProviderConfiguration {
  const selected = requireEnabledMode(mode, liveEnabled);
  const secretKey = selected === "test" ? testKey : liveKey;
  if (!secretKey.startsWith(selected === "test" ? "sk_test_" : "sk_live_")) {
    throw new Error("Provider credentials do not match the selected mode");
  }
  return { mode: selected, secretKey };
}

export function webhookMode(liveMode: unknown): ProviderMode {
  if (typeof liveMode !== "boolean") {
    throw new Error("Webhook mode must be explicit");
  }
  return liveMode ? "live" : "test";
}

/** All provider transport is injectable. Tests never contact the provider. */
export async function providerFetch(
  configuration: ProviderConfiguration,
  url: string,
  init: RequestInit = {},
  send: typeof fetch = fetch,
): Promise<Response> {
  const parsed = new URL(url);
  if (
    parsed.origin !== "https://api.paymongo.com" ||
    !parsed.pathname.startsWith("/v1/") || parsed.username || parsed.password
  ) {
    throw new Error("Untrusted provider endpoint");
  }
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Basic ${btoa(configuration.secretKey + ":")}`);
  const response = await send(url, { ...init, headers });
  if (response.ok) {
    const payload = await response.clone().json();
    const live = payload?.data?.attributes?.livemode;
    if (typeof live === "boolean" && live !== (configuration.mode === "live")) {
      throw new Error("Provider response mode mismatch");
    }
  }
  return response;
}

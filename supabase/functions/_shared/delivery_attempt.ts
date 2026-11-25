export type DeliveryAttemptResult = {
  success: boolean;
  skip: boolean;
  providerMessageId: string | null;
  error: string | null;
};

export type DeliveryProvider = () => Promise<string | null>;

export function configuredDeliveryChannels(config: {
  brevoKey: string;
  emailFrom: string;
  firebaseServiceAccount: string;
}): Array<"email" | "push"> {
  const channels: Array<"email" | "push"> = [];
  if (config.brevoKey && config.emailFrom) channels.push("email");
  if (config.firebaseServiceAccount) channels.push("push");
  return channels;
}

const secretPatterns = [
  /bearer\s+[a-z0-9._~+/=-]+/gi,
  /(?:api[-_ ]?key|authorization|token|secret|password)\s*[:=]\s*[^\s,;]+/gi,
  /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/gi,
];

export function sanitizeDeliveryDiagnostic(error: unknown): string {
  let value = error instanceof Error ? error.message : String(error ?? "Delivery failed.");
  for (const pattern of secretPatterns) value = value.replace(pattern, "[redacted]");
  value = value.replace(/[\r\n\t]+/g, " ").replace(/\s{2,}/g, " ").trim();
  return (value || "Delivery failed.").slice(0, 500);
}

export async function executeDeliveryAttempt(
  provider: DeliveryProvider,
): Promise<DeliveryAttemptResult> {
  try {
    return {
      success: true,
      skip: false,
      providerMessageId: await provider(),
      error: null,
    };
  } catch (error) {
    return {
      success: false,
      skip: false,
      providerMessageId: null,
      error: sanitizeDeliveryDiagnostic(error),
    };
  }
}

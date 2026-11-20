import { assertEquals, assertFalse, assertStringIncludes } from "@std/assert";
import {
  configuredDeliveryChannels,
  executeDeliveryAttempt,
  sanitizeDeliveryDiagnostic,
} from "../_shared/delivery_attempt.ts";

Deno.test("provider configuration requires a complete email pair", () => {
  assertEquals(
    configuredDeliveryChannels({
      brevoKey: "",
      emailFrom: "",
      firebaseServiceAccount: "",
    }),
    [],
  );
  assertEquals(
    configuredDeliveryChannels({
      brevoKey: "key-without-sender",
      emailFrom: "",
      firebaseServiceAccount: "firebase-json",
    }),
    ["push"],
  );
  assertEquals(
    configuredDeliveryChannels({
      brevoKey: "email-key",
      emailFrom: "sender@example.test",
      firebaseServiceAccount: "firebase-json",
    }),
    ["email", "push"],
  );
});

Deno.test("delivery provider success produces a finalizable success", async () => {
  const result = await executeDeliveryAttempt(() => Promise.resolve("provider-123"));
  assertEquals(result, {
    success: true,
    skip: false,
    providerMessageId: "provider-123",
    error: null,
  });
});

Deno.test("transient failure is sanitized and a later independent retry succeeds", async () => {
  let attempts = 0;
  const provider = () => {
    attempts++;
    if (attempts === 1) {
      return Promise.reject(new Error("timeout token=private-token user@example.com"));
    }
    return Promise.resolve("provider-456");
  };
  const first = await executeDeliveryAttempt(provider);
  assertFalse(first.success);
  assertEquals(first.error, "timeout [redacted] [redacted]");
  assertEquals((await executeDeliveryAttempt(provider)).success, true);
});

Deno.test("malformed provider errors remain bounded and contain no line breaks", () => {
  const detail = sanitizeDeliveryDiagnostic(
    `Authorization: Bearer abc.def\n${"x".repeat(800)}`,
  );
  assertEquals(detail.length, 500);
  assertFalse(detail.includes("abc.def"));
  assertFalse(detail.includes("\n"));
  assertStringIncludes(detail, "[redacted]");
});

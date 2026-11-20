# Tric-Gabay Batch 8 independent payment, pickup-code, and authorization review

Date: 2026-10-24  
Scope: local repository, deterministic provider-boundary tests, isolated PostgreSQL migration chain, pgTAP, Flutter, and Android debug build  
Excluded: deployment, hosted mutation, real/test provider traffic, real payments/refunds/messages, production credentials, and physical-device validation

## 1. Outcome

Batch 7's central financial model is sound but two security claims needed correction and one retry case was incomplete:

1. A PayMongo request and the local PostgreSQL commit are **not atomic**. The safe guarantee is eventual convergence: a stable provider idempotency key for one checkout attempt, an atomic local commit RPC, retried webhooks, and authenticated reconciliation. Batch 8 now states that guarantee explicitly.
2. Checkout IDs and redirect URLs were trusted too broadly. Existing rows accepted any HTTPS URL, and an existing checkout could be returned to the app without provider-origin validation. Both the Edge and SQL trust boundaries now reject malformed IDs, non-HTTPS URLs, ports, credentials, and lookalike hosts.
3. Pickup-code recovery was not retry-safe. Every call generated a new code, cleared failed-attempt/lock state, and allowed unlimited rotations. Concurrent or lost-response calls could leave the tourist holding a code that no longer matched the server. Recovery is now one-time, bound to a persisted request UUID and exact client-generated code, row-locked, idempotent, and unable to clear lockout state.

All implemented changes passed the available local checks. This is not a production-readiness or complete security-certification claim.

## 2. Actual stack and trust boundaries

The inspected system consists of:

- Flutter/Dart Android and web clients. The client owns presentation and encrypted local recovery material, but does not own booking, payment, refund, role, or trip truth.
- Supabase Auth identities and JWT claims.
- PostgreSQL tables, RLS, `SECURITY DEFINER` RPCs, triggers, grants, Storage policies, and immutable financial ledger effects.
- Deno/TypeScript Edge Functions holding the service key and PayMongo test secret.
- PayMongo Hosted Checkout, webhook signatures, and explicit reconciliation.
- Downstream email/push delivery, which cannot define financial truth.

The installed `security-best-practices` skill supplied only general TypeScript security context. Its available references do not cover Deno, Flutter/Dart, PostgreSQL, Supabase Auth/RLS/Storage, or PayMongo. Findings for those layers are repository- and test-based; no unsupported framework-specific review is claimed.

## 3. PayMongo contract verification

PayMongo's official documentation confirms the assumptions used by the fix:

- `Idempotency-Key` is supported for retrying uncertain writes; the same key returns the original result rather than creating a duplicate. Keys are scoped to the secret API key and HTTP method and may be up to 255 characters: <https://docs.paymongo.com/docs/developer-tools-best-practices-1>.
- Hosted Checkout is created server-side, and one checkout session cannot produce two successful payments: <https://docs.paymongo.com/docs/payment-channels-hosted-checkout>.
- The documented hosted URL is `https://checkout.paymongo.com/...`; a session is active or expired, and an active session URL may be returned again safely: <https://docs.paymongo.com/docs/payment-channels-key-concepts> and <https://docs.paymongo.com/reference/checkout-session-resource>.

The live provider was not called. Contract use is locally verified, while actual provider timeout, caching, webhook retry timing, and concurrent network behavior remain external validation items.

## 4. Findings and corrections

### B8-PAY-01 — High — checkout redirect and identity were under-validated

**Evidence:** the prior Edge Function returned a stored `checkout_url` directly and the SQL RPC accepted any string beginning with `https://`.  
**Failure/abuse:** corrupted or wrongly written data could redirect a tourist to a lookalike host; malformed or inconsistent provider identity could be attached to the wrong local operation.  
**Fix:** `supabase/functions/_shared/paymongo_checkout.ts` validates the documented exact HTTPS origin, rejects credentials and non-default ports, and validates the `cs_…` resource identity. `create-paymongo-checkout/index.ts` validates both stored and newly returned provider resources. Migration `202610240005_payment_pickup_authorization.sql` independently enforces the ID/origin, amount, mode, booking state, and exact identity on reuse. The existing unique provider-ID constraint prevents cross-booking attachment.  
**Regression:** Deno malformed-origin matrix; pgTAP rejects untrusted host, malformed ID, amount mismatch, changed ID/URL, and duplicate cross-booking provider identity with no partial row.

### B8-PAY-02 — Medium — one key per booking could not safely create a replacement after definitive failure

**Evidence:** the previous key was always `tricgabay-checkout-<booking>`. PayMongo correctly returns the original operation for that key, so asking for a new session after the local payment became definitively `failed` could return the old provider session and collide locally.  
**Fix:** the initial key is stable for the booking. A replacement is allowed only after the latest local payment is definitively `failed`, and its key is deterministically anchored to that failed payment row. Two concurrent replacement requests therefore use the same key. Active sessions are reused; paid/refund/review or malformed states fail closed for review.  
**Regression:** Deno proves initial and failed-attempt key stability. Provider execution remains unverified without PayMongo test traffic.

### B8-PAY-03 — Informational correction — cross-system atomicity was overstated

The Edge Function cannot include PayMongo's HTTP write in the PostgreSQL transaction. The actual failure handling is:

| Failure point | Result and recovery |
|---|---|
| Provider succeeds; Edge crashes/times out before local commit | Retry uses the same attempt key, receives the provider's original result, and retries the local commit |
| Two requests race | Same provider attempt key plus booking row lock and unique active-payment/provider-ID constraints converge locally |
| Local commit rejects malformed/mismatched result | Transaction rolls back; booking/payment truth remains unchanged and the bounded correlation ID supports investigation |
| Webhook arrives before payment persistence | payment-event RPC raises retryable SQLSTATE `40001`; its event insert rolls back, Edge returns failure, and later provider retry/reconciliation can apply it |
| Duplicate/late webhook | Provider event ID deduplication and monotonic payment/refund state reject duplicate or regressive effects |
| Client receives an ambiguous result | Existing checkout is re-read and validated; provider status can be reconciled through the owner/finance-authorized endpoint |

### B8-PICKUP-01 — High — recovery rotated codes, bypassed lock state, and was not retry-safe

**Evidence:** Batch 7's RPC generated a new code on every invocation and set failed attempts to zero and lock expiry to null.  
**Failure/abuse:** concurrent calls could return different codes; an earlier response could overwrite the valid local code; repeated owner calls could defeat driver verification lockout and generate unlimited audit/code rotations.  
**Fix:** the app uses `Random.secure()` for a uniform 1000–9999 code and persists it with a UUID before calling the server. PostgreSQL locks the booking, validates active tourist ownership and eligible state, rejects active lockout, binds the booking to the first recovery request, and returns the same code only when both UUID and hash match. It preserves failed attempts, emits one audit event, and never stores plaintext in the event. A pending request is resumed on a later booking refresh after process/network interruption.  
**Regression:** pgTAP covers owner success; other tourist, driver, anonymous privilege, terminal state, active lockout, malformed code, different-request replay, same-request/different-code replay, identical lost-response retry, one event, preserved attempt count, and absence of plaintext audit data.

### B8-PICKUP-02 — Medium — modulo-biased pickup-code generation

**Evidence:** the original database expression reduced a 16-bit value modulo 9000; 65,536 is not divisible by 9,000. It also read bytes from two separate random samples.  
**Fix:** all new booking codes use one `gen_random_bytes(2)` sample and rejection sampling below 63,000, which is exactly divisible by 9,000. The result remains a four-digit 1000–9999 code. The helper is not executable by API roles.  
**Limitation:** four decimal digits intentionally have only 9,000 possibilities; security therefore still depends on server-side driver ownership, booking state, attempt counting, and timed lockout. The 1,000-sample test proves range/format, while uniformity follows from the rejection-sampling construction rather than a statistical certification.

### B8-AUTH-01 — Medium defense-in-depth — null JWT role comparison

**Evidence:** `auth.role() <> 'service_role'` evaluates to null, not true, when the claim is absent. Effective grants already excluded anonymous/authenticated callers, so this was not an exposed API bypass; the remaining direct owner context is a trusted database-administrator boundary.  
**Fix:** `record_paymongo_checkout` now uses `coalesce(auth.role(),'') <> 'service_role'`, retains service-role-only execution, and is directly tested with an absent claim.  
**Result:** malformed provider data and missing claims fail before writes.

## 5. Authorization audit

Final isolated-database introspection showed:

| Function class | Effective API execution | Internal guard / ownership result |
|---|---|---|
| `record_paymongo_checkout` | service role only | Null-safe service-role check; atomic booking/payment commit |
| `recover_booking_pickup_code` | authenticated (service role inherits that grant) | Requires authenticated UID, active tourist profile, exact owner, eligible state, lockout clear, one bound request |
| payment/refund event processors and `finalize_paymongo_refund` | service role only | Provider event/finalization invariants in SQL; anonymous/authenticated denied by ACL |
| communication claim/finalization and scheduled reminders | service role only | Application users cannot claim global delivery work or finalize another lease |
| scheduled booking activation | service role only | Removed from mobile application execution boundary |
| admin capability management | authenticated | Self-authorizes active super administrator; UI visibility is not trusted |
| trigger-only enqueue, ledger, reliability, and ranked-offer functions | no anon/authenticated/service-role RPC grant | Invoked only by owned trigger/function workflows |

Every inspected function is `SECURITY DEFINER` with a fixed `search_path`; API roles have no `CREATE` privilege in `public`, preventing search-path object shadowing. Database owners remain an explicitly trusted administration boundary. A service-role bearer is intentionally privileged and cannot be subdivided by PostgreSQL into separate external callers; Edge secrets and deployment access remain the operational boundary.

## 6. Migration and test evidence

| Check | Exact local result |
|---|---|
| Flutter static analysis | PASS — no issues; 189.8 seconds |
| Flutter tests | PASS — 88/88 |
| Deno format | PASS — 22 files |
| Deno lint | PASS — 21 files |
| Deno deterministic tests | PASS — 19/19; isolated Auth integration test correctly ignored without its optional credentials |
| Frozen Deno type checks | PASS — all five Edge Function entry points |
| Fresh migration chain | PASS — 36 migrations applied in filename order to an isolated Supabase PostgreSQL 17.11 container |
| pgTAP | PASS — 145/145 assertions across seven suites |
| Effective ACL/search-path introspection | PASS — expected boundaries listed above; API roles cannot create in `public` |
| Android debug APK | PASS — 288,370,727 bytes; SHA-256 `3C777D12734B7CDBEACD708CA48B1BBC64FDA56E704BE3392B2711B6E2025EC9` |
| Git whitespace check | PASS — no whitespace errors; Windows LF/CRLF notices only |

The Android build emitted two non-blocking toolchain warnings: Mapbox/Share Plus still apply the Kotlin Gradle Plugin instead of Flutter's future Built-in Kotlin path, and the installed Android command-line tooling understands SDK XML through version 3 while one SDK file is version 4. Neither warning failed this debug build, but dependency/toolchain alignment remains a release-maintenance item.

The local Supabase CLI initially encountered an incompatibility between an older CLI and a newer Storage image. Validation therefore used an unlinked disposable PostgreSQL container plus `supabase/local_validation/storage_bootstrap.sql`, a minimal Storage schema fixture used only so the repository's Storage RLS policies could compile and execute. The container was removed after testing. This proves migrations, SQL functions, ACL/RLS behavior, and tests locally; it does not replace a full Supabase service integration run.

One diagnostic invocation of the old CLI noticed the repository's existing link and performed read-only hosted project metadata/health requests before it was stopped. It made no hosted write, deployment, migration, provider call, or secret change. All evidence reported above came from the subsequently isolated unlinked harness.

## 7. Remaining limitations and required decisions

1. PayMongo test-mode validation still needs controlled crash/timeout/concurrency tests against the real provider and webhook retry delivery. Local code proves stable keys and state invariants, not PayMongo's live behavior in this project.
2. A genuine simultaneous two-connection pickup-recovery race was not injected. The row lock and bound recovery ID make the second transaction observe the first result; pgTAP proves sequential retry/replay semantics.
3. Automatic recovery is deliberately limited to the interrupted booking-create workflow. A later user-requested “forgot pickup code” reset needs an explicit product/support policy, re-authentication rules, notification behavior, and possibly a separately approved rate limit. Batch 8 did not invent those rules.
4. Physical Android packet loss, process death during each secure-storage write, device backup/restore, keystore failure, and large-text/TalkBack behavior remain device tests.
5. Hosted migration review, full Supabase Storage service behavior, secret rotation, alert routing, backup/restore rehearsal, production signing, and deployment approval remain separate operational work.

## 8. Files changed by Batch 8

- `supabase/functions/_shared/paymongo_checkout.ts`
- `supabase/functions/create-paymongo-checkout/index.ts`
- `supabase/functions/tests/paymongo_checkout_test.ts`
- `supabase/migrations/202610240005_payment_pickup_authorization.sql`
- `supabase/tests/006_cross_system_consistency.sql`
- `supabase/tests/007_payment_pickup_authorization.sql`
- `supabase/local_validation/storage_bootstrap.sql`
- `lib/core/services/backend_repository.dart`
- `docs/application-scenario-matrix.md`
- `docs/application-hardening-report-2026-10-24-batch8.md`

No commit, push, merge, deployment, remote migration, payment, refund, email, or push notification was performed.

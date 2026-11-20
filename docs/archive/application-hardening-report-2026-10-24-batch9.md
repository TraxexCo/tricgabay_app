# Tric-Gabay Batch 9 concurrency, fault-injection, and integration validation

Validation completed: 2026-10-25 (Asia/Manila)  
Requested report filename/batch date: 2026-10-24  
Scope: local repository, deterministic provider-boundary simulations, genuinely concurrent PostgreSQL sessions, isolated migration/pgTAP validation, Flutter, Deno, and Android debug build  
Excluded: hosted Supabase mutation, deployment, real or test PayMongo traffic, real refunds, real email/push delivery, production credentials, and physical-device validation

## 1. Executive summary

Batch 9 closed the two largest local evidence gaps left by Batch 8:

1. Pickup-code recovery was exercised with genuinely independent PostgreSQL sessions. A deterministic advisory-lock barrier held the first transaction after recovery but before commit, and PostgreSQL lock inspection proved the second transaction was waiting on the booking row. Identical retries converged; different request IDs and same-ID/different-code conflicts failed after the winner committed. One authoritative hash/request/event remained, failed-attempt state stayed unchanged, and no plaintext code entered the audit event.
2. The production checkout orchestration now exposes an injected provider/persistence boundary. Deterministic Deno tests reproduce provider-success/response-loss, local persistence failure, simultaneous initial attempts, simultaneous failed-checkout replacements, active reuse, restart-style retry, and malformed/terminal stored state. These are simulations of the application boundary, not claims about live PayMongo behavior.

The full regression set passed: 91 Flutter tests, 27 Deno tests including the real local core-service integration, 145 pgTAP assertions, 36 clean migrations, clean Flutter analysis, and an Android debug APK build.

A real isolated Supabase core stack passed with CLI 2.121.0 and no hosted link. PostgreSQL 17.11.0.004, GoTrue/Auth, PostgREST, Kong, and Storage API v1.82.1 ran together. The integration test exercised real identity/session flows, an RPC, profile RLS, owner Storage upload/download, and foreign-account Storage denial. The separate minimal Storage fixture is still not treated as equivalent evidence; the successful real Storage service run is.

No hosted resource, provider, payment, refund, message, deployment, commit, or push was performed.

## 2. Stack, trust boundaries, and guidance limits

Inspected stack and authoritative owners:

- Flutter/Dart Android and web clients own presentation and encrypted local retry material, but not booking, payment, refund, role, location, or trip truth.
- Supabase Auth owns identity/session issuance.
- PostgreSQL owns booking, trip, payment, refund, ledger, administrative capability, communication lease, and location invariants through RLS, grants, triggers, and `SECURITY DEFINER` functions.
- Deno/TypeScript Edge Functions hold service/provider credentials and mediate PayMongo, scheduling, reconciliation, webhooks, and communications.
- PayMongo owns external checkout/refund results. Stable idempotency narrows ambiguous windows but cannot make an HTTP request atomic with PostgreSQL.
- Email/push are downstream communications and never define financial truth.

The installed `security-best-practices` skill has no Deno, Flutter/Dart, PostgreSQL, Supabase Auth/RLS/Storage, or PayMongo reference. Its general principles were used cautiously for the TypeScript boundary; all other conclusions are repository- and test-based. This is not represented as a comprehensive framework-specific certification.

## 3. Repository changes and rationale

### Production/testability changes

- `supabase/functions/_shared/paymongo_checkout.ts`
  - Added `resolvePayMongoCheckout`, the orchestration seam used by production.
  - Active trusted checkout rows return without provider access.
  - Failed rows derive the replacement key from the stable failed-payment ID.
  - Provider output is validated before persistence, and no success is returned before the injected authoritative persistence function succeeds.
- `supabase/functions/create-paymongo-checkout/index.ts`
  - Uses the shared orchestration while preserving the existing HTTP/provider/409/502/500 behavior.
  - No provider URL, credential mode, or state-machine rule was loosened.
- `supabase/functions/tests/paymongo_checkout_test.ts`
  - Added deterministic idempotent-provider, response-loss, database-failure, concurrency, active-reuse, restart, and conflict simulations.
- `lib/core/services/pickup_recovery_material.dart`
  - Extracted the local recovery-material lifecycle so process interruptions can be injected without a device.
  - A complete persisted pair is reused; an incomplete pre-RPC pair is replaced; confirmed user-visible code is written before retry-material cleanup.
- `lib/core/services/backend_repository.dart`
  - Uses the tested recovery-material lifecycle without changing the server RPC contract.
- `test/pickup_recovery_material_test.dart`
  - Covers restart, interruption between the two pre-RPC secure writes, and interruption during post-confirmation cleanup.

### Local-only validation changes

- `supabase/local_validation/run_batch9_concurrency.ps1`
  - Creates one exactly named disposable container, waits for the image's definitive initialization marker, applies all migrations as the Supabase migration owner, runs all pgTAP suites, runs independent-session races with database-observed barriers, and removes the container/temp files in `finally`.
- `supabase/local_validation/storage_bootstrap.sql`
  - Aligns the disposable fixture schema owner with `supabase_storage_admin`, matching the service-owned boundary needed by the Supabase PostgreSQL image. It remains a fixture, not a migration or substitute for Storage service testing.
- `docs/application-scenario-matrix.md`
  - Updated BOOK-02, PAY-01, PAY-02, scope/date, and the full-stack limitation to reflect only evidence actually produced in Batch 9.

## 4. Pickup-code concurrency procedure and outcome

The reproducible harness performs these steps per race:

1. Reset one eligible booking to no recovery ID, original hash, three failed attempts, and no lockout.
2. Open a barrier connection that owns advisory lock `9009009`.
3. Open PostgreSQL session A, set an authenticated tourist JWT context, call `recover_booking_pickup_code`, and then block on that advisory lock before commit. Session A therefore owns the booking row lock.
4. Query `pg_stat_activity`/`pg_locks` until A is observed waiting on the advisory lock.
5. Open independent session B and call the same RPC.
6. Query `pg_stat_activity` until B is observed waiting on a PostgreSQL lock held by A.
7. Terminate only the named barrier backend, allowing A to commit and B to continue against committed authoritative state.
8. Assert the winner's recovery UUID/hash, three retained failed attempts, exactly one audit event, and no plaintext code in description/metadata.

| Scenario | Session B result | Authoritative result |
|---|---:|---|
| Same booking, same UUID, same code | Exit 0 | Both receive the same code; one hash/request/event |
| Same booking, different UUID/code | Exit 3, expected SQL rejection | Session A remains authoritative; no rotation |
| Same booking, same UUID, different code | Exit 3, expected SQL rejection | Session A remains authoritative; no conflicting valid code |
| B waits while A commits | Observed `wait_event_type='Lock'` before barrier release | Deterministic row-lock serialization proved |
| First response discarded, retry from independent session | Exit 0 | Same UUID/code returns authoritative code; one event |
| Active lockout, other tourist, driver, anonymous, terminal booking | Expected denials in pgTAP | Protected booking state unchanged |
| Interruption before complete local material | Flutter test repairs the incomplete pair before an RPC | No half-persisted request is sent |
| Interruption after remote commit/before response | Complete pair is reused | Same server request/code is retried |
| Interruption during cleanup | Flutter test proves authoritative pickup code was written first | Cleanup failure cannot erase confirmed code |

The harness output ended with `PGTAP_PASS assertions=145 suites=7` and `BATCH9_CONCURRENCY_PASS`.

## 5. PayMongo provider-boundary fault injection

No PayMongo API was called. `FakeIdempotentProvider` models only the contract expected by the application and caches a resource by `Idempotency-Key`.

| Scenario | Deterministic local outcome | Live-provider status |
|---|---|---|
| Provider commits, Edge loses response | First call fails locally; retry uses the identical key, receives one cached resource, persists once | Requires PayMongo sandbox confirmation |
| Provider commits, local persistence fails | Retry uses the identical key/resource; persistence is retried; no success precedes persistence | Requires sandbox confirmation |
| Two simultaneous initial checkouts | Two-party promise barrier releases both together; same key, one provider resource, one simulated local identity | Provider concurrency requires sandbox confirmation |
| Two simultaneous replacements after definitive failure | Both anchor to the same failed payment row; same replacement key/resource | Provider concurrency requires sandbox confirmation |
| Retry while checkout is active | Stored exact-origin checkout is returned; zero provider and persistence calls | Locally passed |
| Webhook before local row | SQLSTATE `40001`; event insert rolls back and remains retryable | Provider retry timing requires sandbox confirmation |
| Duplicate/delayed/out-of-order webhooks | Existing pgTAP proves event deduplication and monotonic payment/refund state; late failure cannot downgrade paid/refunded truth | Delivery timing requires sandbox confirmation |
| ID/URL/amount/mode/booking conflict | Shared boundary and SQL reject mismatch with no partial row | Locally passed |
| Timeout/ambiguous response | Same behavior as lost response: stable operation key and no invented success | Actual timeout requires sandbox confirmation |
| Retry after app restart | New orchestration invocation derives the same booking attempt key and obtains the same cached resource | Locally passed at boundary |

The checkout test file now has 10 tests. The complete Deno suite increased from 19 passed plus one ignored integration test to 27 passed with the isolated core stack running.

## 6. Full local Supabase integration status

### Isolation controls

- The temporary workspaces copied only `config.toml`, migrations, and functions.
- `project_id` was changed to a unique Batch 9-only value.
- No `.temp/project-ref`, hosted credentials, or production secrets were copied.
- No remote subcommand was used.
- Cleanup reported no remaining project containers, volumes, or network; the unique temporary folder was removed.

### Versions and attempts

| Component | Version/result |
|---|---|
| Docker client/server | 29.9.2 / 29.9.2 |
| Supabase CLI | 2.121.0 (2.122.0 was installed separately but not used for this attempt) |
| CLI-pinned PostgreSQL | 17.11.0.004; downloaded and started successfully |
| CLI-pinned Storage API | v1.82.1; downloaded and started successfully |
| Isolated database harness | Supabase PostgreSQL 17.11.0.003; clean 36-migration chain passed |
| Minimal Storage fixture | Compiles and exercises repository Storage RLS only; not a real Storage service |

The first all-service attempt was bounded while downloading multiple unrelated large service images. A second reduced attempt retained the services required by the prompt—PostgreSQL, GoTrue/Auth, PostgREST, Kong, and Storage—and excluded Realtime, image proxy, Mailpit, metadata, Studio, Edge Runtime, analytics, Vector, and Supavisor. It applied all 36 migrations and became healthy.

The integration test then proved:

- GoTrue/Auth admin creation, confirmed-password sign-in, invalid-password rejection, `getSession` restoration, duplicate-account rejection, sign-out, and account switching.
- PostgREST service-role profile suspension and authenticated `current_profile_role` RPC execution.
- Profile RLS returned only the signed-in user's row when querying two known IDs.
- Real Storage API owner upload/download under the versioned avatar path.
- Real Storage policy denial when a second authenticated tourist attempted to read or write the first tourist's path.
- Service-role cleanup of the test object and users.

PostgreSQL migrations/functions/triggers/grants/RLS also passed 145 pgTAP assertions in the separate disposable 17.11.0.003 database. Edge Runtime and Realtime were not necessary for these core checks and remain separately unverified locally.

## 7. Authorization regression matrix

| Role/context | Checkout persistence | Pickup recovery | Payment/refund events | Refund reservation | Schedulers/comms | Admin/internal functions |
|---|---|---|---|---|---|---|
| Anonymous | No EXECUTE | No EXECUTE | No EXECUTE | No | No | No |
| Authenticated tourist owner | Edge may request checkout, but cannot call commit RPC | Own eligible booking only | No | No | No global claim/scheduler | No admin capability |
| Other tourist | No commit RPC | Rejected; owner row unchanged | No | No | No | No |
| Driver | No commit RPC | Rejected by active-tourist role guard | No | No | No | Driver-owned trip RPCs only |
| Unauthorized/inactive admin | No commit RPC | Not a tourist | No | Rejected | Manual Edge authorization rejects without operations capability | Capability RPCs self-authorize and fail closed |
| Finance admin | No direct checkout commit | Not a tourist | No direct event processing | May reserve within state/amount rules | No global delivery claim by client | Finance-scoped actions only |
| Compliance/content/support/operations admin | No direct checkout commit | Not a tourist | No | No finance action unless separately granted | Operations may authorize manual dispatch through Edge; DB worker RPC remains service-role-only | Only explicit capability actions |
| Service role Edge context | `record_paymongo_checkout` only after null-safe role check | Grant inheritance exists but tourist identity guard rejects ordinary use | Event/reconciliation/finalization allowed within SQL invariants | Provider finalization path | Claim/finalize/reminder/activation worker paths | Trigger-only functions still lack API EXECUTE |
| Database owner | Trusted migration/test context, explicitly not an application role | Trusted boundary | Trusted boundary | Trusted boundary | Trusted boundary | Owns definitions |

All inspected `SECURITY DEFINER` functions retain fixed `search_path` settings in the clean-database schema contract tests. API roles cannot create in `public`. No grant was added to make a test pass.

## 8. Commands executed and outcomes

Commands are summarized without credentials or temporary absolute identifiers.

| Command/action | Exit/result |
|---|---|
| Read Batch 8 report, matrix, migrations, functions, tests, config, and Git status | 0 |
| `deno fmt --check supabase/functions` | 0; 22 files |
| `deno lint --config supabase/functions/deno.json supabase/functions` | 0; 21 files |
| `deno test --config ... supabase/functions/tests --allow-env --allow-net=127.0.0.1:54321` | 0; 27 passed, none ignored |
| Frozen `deno check` for all five Edge Function entry points | 0 |
| `run_batch9_concurrency.ps1` against a fresh container | 0; 36 migrations, 145/145 pgTAP, four independent-session validations |
| `flutter test` | 0; 91/91 |
| `flutter analyze` | 0; no issues |
| `flutter build apk --debug` | 0; 288,373,086 bytes; SHA-256 `878FD548C24101F3854FDB4ECF380182C10D7471752A8E9119B261188888E53C` |
| `git diff --check` | 0; line-ending notices only, no whitespace errors |
| Redacted secret-pattern filename scan | 0; reviewed a setup placeholder prefix, PEM boundary parser literal, and a historical public anon JWT superseded by the later Vault-backed migration; no private/service/provider secret identified |
| Isolated Supabase CLI 2.121.0 core start | 0; PostgreSQL/Auth/PostgREST/Kong/Storage healthy; 36 migrations applied |
| Real local Auth/RPC/RLS/Storage integration test | 0; one end-to-end test passed |
| Isolated `supabase stop --no-backup` and exact temp cleanup | 0; stack stopped and exact temp folder removed |

## 9. Before/after comparison

| Gate | Batch 8 | Batch 9 |
|---|---:|---:|
| Flutter tests | 88 passed | 91 passed |
| Deno tests | 19 passed, 1 ignored | 27 passed, 0 ignored |
| pgTAP | 145 passed | 145 passed |
| Migration chain | 36 | 36 |
| Genuine pickup-code concurrent sessions | Not run | Passed |
| Full local Supabase core services | Not run | Passed for PostgreSQL/Auth/PostgREST/Kong/Storage; unrelated services intentionally excluded |
| Android debug APK SHA-256 | `3C777D12734B7CDBEACD708CA48B1BBC64FDA56E704BE3392B2711B6E2025EC9` | `878FD548C24101F3854FDB4ECF380182C10D7471752A8E9119B261188888E53C` (288,373,086 bytes) |

## 10. Remaining findings by severity

### Critical / high

No new unresolved local critical/high defect was reproduced in the Batch 9 scope.

### Medium

1. **PayMongo behavior remains external.** The code's stable keys and recovery paths are deterministic; PayMongo's real cache, timeout, concurrency, and webhook-redelivery behavior still require explicitly approved sandbox traffic.
2. **Physical Android lifecycle remains external.** Secure-write interruption logic is unit tested, but OS process death, keystore failure, packet loss, and device backup/restore need physical validation.
3. **Excluded local services remain separate evidence.** Edge Runtime, Realtime, analytics, Studio, image proxy, and mail-capture services were not required for the Auth/RPC/RLS/Storage test and were intentionally excluded. Edge Function handler integration is supported by deterministic TypeScript tests and SQL tests, not a locally served Edge Runtime request.

### Low / operational

1. The Android toolchain continues to warn about future Built-in Kotlin migration for Mapbox/Share Plus and SDK XML version skew. These warnings did not fail the debug build.
2. The Supabase CLI emits a harmless missing local profile warning in the isolated workspace; no profile is desirable for this no-hosted-link test.
3. Historical migration `202610230007_secure_communications_scheduler.sql` contains a public Supabase anonymous client token and hosted URL. Migration `202610230014_environment_scoped_communications_dispatcher.sql` replaces that function with environment-scoped Vault values. The public token is not a service/provider secret, but it remains secret-scan noise; rewriting an already-applied migration was intentionally avoided.

## 11. Release-gate checklist

| Gate | Status | Evidence / next action |
|---|---|---|
| Flutter analysis | **Passed** | No issues |
| Flutter automated tests | **Passed** | 91/91 |
| Deno format/lint/type checks | **Passed** | 22 formatted, 21 linted, five entry points checked |
| Deno tests | **Passed** | 27 passed; real local integration test executed |
| Fresh database migration chain | **Passed** | 36 migrations on disposable Supabase PostgreSQL 17.11.0.003 |
| PostgreSQL authorization/RLS/financial tests | **Passed** | 145/145 pgTAP |
| Genuine pickup recovery concurrency | **Passed** | Independent sessions plus observed lock waits |
| Android debug APK | **Passed** | 288,373,086 bytes; SHA-256 `878FD548C24101F3854FDB4ECF380182C10D7471752A8E9119B261188888E53C` |
| Diff/whitespace scan | **Passed** | No whitespace errors |
| Repository secret scan | **Passed** | No private/service/provider secret identified; three benign/public historical matches reviewed |
| Full local Supabase Auth/PostgREST/RPC/RLS/Storage | **Passed** | Isolated CLI core stack; owner success and foreign Storage/RLS denial verified |
| Local Edge Runtime/Realtime | **Not Run** | Intentionally excluded; deterministic Edge/SQL coverage retained |
| PayMongo sandbox | **Requires External Validation** | Explicit credentials/account/allowed operations/approval required; no request made |
| Physical Android | **Requires External Validation** | Lifecycle, background location, permissions, TalkBack, notification taps, and network shaping |
| Hosted migration/operational readiness | **Not Run** | Hosted review, secrets, alerts, backup/restore, and production signing remain separate approved work |

## 12. Stop condition

Batch 9 stopped after local code/test evidence and documentation. There was no commit, push, merge, deployment, hosted mutation, provider request, payment/refund operation, or real communication.

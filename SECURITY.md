# Security boundaries and evidence

Batch 4 was tested only in an unlinked, disposable local Supabase stack. Security tests are regression evidence, not a claim that every attack or provider configuration has been assessed.

## Authorization contract

`scripts/security/catalog.sql` inventories every public/storage table, view, function and bucket. `supabase/security/authorization_catalog.json` is the reviewed catalog contract. `scripts/security/access_rules.ts` records expected application access. The runner refuses new relations, buckets or callable application RPCs without rules and refuses catalog drift. Updating the snapshot is a deliberate review action, never part of normal CI.

The matrix runs as actual `anon`/`authenticated` database roles with synthetic subjects: tourist A/B, driver A/B, suspended tourist, pending driver, and one administrator for each of super_admin, finance, driver_compliance, content, support and operations. A/B reads, cross-party mutations, column-restricted notification updates and RPC authorization are checked. Mutations run in rolled-back subtransactions. The separate Storage matrix exercises real HTTP downloads, lists, inserts, overwrites, deletes and public URLs for all four buckets.

Not every catalog function is a PostgREST RPC. Trigger routines and PostgreSQL internal/polymorphic support signatures have EXECUTE catalog probes but cannot be called as ordinary typed SQL RPCs. Upstream computational routines use typed NULL inputs; strict revoked helpers use non-NULL inputs to avoid planner NULL folding bypassing the permission probe. Their mathematical correctness is outside the matrix. Allowed application calls may encounter explicit business-rule refusals; successful workflow paths are separately exercised by pgTAP/API tests.

The SECURITY DEFINER snapshot records fixed search paths, PUBLIC grants, the three API-role grants and every effective database role that can execute each function. Anonymous application access is restricted to six documented role/configuration predicates: current_profile_role, get_client_configuration, get_privacy_notice, has_admin_capability, is_admin and is_approved_driver. The runner also refuses CREATE privileges for untrusted roles on the public schema. PostGIS is relocated to `extensions`, which must remain outside the Data API's exposed schemas. Managed extension grants can persist there; isolation prevents public table/RPC access. The local extension-owner bootstrap adds grant hardening for isolated tests, and is not evidence that hosted postgres can revoke managed grants.

Batch 4 fixed an outer-column shadowing error in driver-location RLS that exposed unrelated locations to a tourist with an active booking. It also removed anonymous grants on older transactional RPCs, closed NULL-role checks, added active actor guards and removed direct profile/fare/policy writes that could bypass RPC checks. Notification clients may update only `read_at`.

## Upload boundary

| Bucket | Visibility | Accepted content | Limit |
|---|---|---|---|
| driver-documents | private; owner/compliance reads | JPEG, fixed application paths | 5 MiB |
| profile-images | private; owner reads | JPEG/PNG, versioned avatar paths | 5 MiB |
| tourist-spots | public; content-admin writes | JPEG/PNG, UUID version paths | 5 MiB |
| app-assets | public; content-admin writes | PNG | 1 MiB |

The app checks magic prefixes, declared MIME and canonical extension before upload. Storage policies validate MIME/extension and preflight `contentLength` or final `size`; the service enforces bucket byte limits. These are not a full image decoder, malware scanner or server-side content-signature validator. A malicious direct client can forge metadata and magic prefixes. Driver document overwrites/deletes are allowed only while the applicant is pending; approved documents stay private and require the existing compliance process.

## Payments and credentials

`live_payments_enabled` remains false. Webhook HMAC verification uses the mode-specific signature field and secret, checks raw body and timestamp, and refuses live events while the flag is off. Checkout, reconciliation, refund, expiry and ledger writes preserve mode. Injected tests and rolled-back SQL fixtures exercise both modes without live credentials or provider calls. Live credentials, webhook registration and refund behavior still require provider certification before any flag change.

The OSV scan covers locked hosted Pub and Deno npm dependencies. It does not cover Flutter SDK code, downloaded native binaries, Android transitive dependencies or every advisory ecosystem. No major dependencies were upgraded.

The current-tree Gitleaks scan found no leaks. The four-commit history scan reports three historical matches: a synthetic scheduler test token, a Supabase anonymous client JWT, and an old Firebase client API key. No private service-role/payment key was identified. The Firebase key's hosted restrictions were not inspected, so the history gate intentionally remains nonzero pending owner review. No history was rewritten. Current hardcoded Firebase/Supabase client values were removed. The old scheduler migration now reads its URL/key from Vault instead of embedding a hosted target.

Firebase client API keys are public configuration only when appropriately restricted; the owner must verify permitted APIs and quota restrictions. See [Firebase guidance](https://firebase.google.com/docs/projects/api-keys). Supabase publishable/anonymous keys rely on RLS; service/secret keys must stay server-side. See [Supabase key guidance](https://supabase.com/docs/guides/getting-started/api-keys).

## Known boundaries

There is no GPS attestation, masked calling/chat, admin MFA/web admin, offline cache encryption or owner-approved retention schedule in this batch. Public attraction photos are intentionally public. Account exports contain personal data; the device share sheet is an explicit user action and was not exercised on a device. Suspended users can invoke their data-rights RPC with a valid token, but ordinary sign-in blocks them; the owner must provide an assisted identity-verification/contact procedure.

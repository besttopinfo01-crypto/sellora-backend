# Catalove — System Reference
*Snapshot as of July 31, 2026. This captures knowledge that currently exists only in conversation history — treat it as the working source of truth until it's out of date.*

---

## 1. The two Supabase projects — which is which

| | `dbgzqwophuukxuwgvgsh` | `oelkgdyfoecawosdqdeo` |
|---|---|---|
| Named | **catalove-production** | (default, never renamed) |
| Status | Active, in real use | Retired / legacy |
| Contains | `sellers`, current `merge_requests`/`merge_request_items`, `submission_logs`, `post_submission_verification` | Original 78-day build's data (169 legacy `merge_requests` rows, no `sellers` table) |
| Used by | wf14, wf15, wf17–wf25 | wf01–wf06 only (New Parent flow, not yet rebuilt) |

**Rule going forward:** anything new should point at `dbgzqwophuukxuwgvgsh`. wf01–06 are the only workflows still intentionally on the old project, pending the New Parent flow being rebuilt.

---

## 2. Full workflow inventory

| # | Name | Role | Project | Notes |
|---|---|---|---|---|
| 01–03, 05 | Input Validator, Correction Intake, Real Data Dry Run, (old) Payload Preview | New Parent flow (not yet used by the built frontend) | Old | Hardcoded Size/Color; wf05 fabricates a synthetic parent SKU — needs redesign, not just re-pointing, if ever revived |
| 04 | Manual Approval | Old-flow approval logging | Old | Not called by current frontend |
| 06 | Controlled Submission | Real Amazon feed submission (create-document → S3 upload → submit-feed) | Old (its 3 gate-checks only) | **The Amazon-calling nodes themselves are reusable** — only its Approval/Payload/Validation *gates* are tied to the old schema |
| 07 | Feed Poller | Polls `submission_logs` for status | **Fixed today** → new project | Was old project; both nodes re-pointed and moved to Custom Auth / Supabase Service Role |
| 08 | Post-Submission Verification | Confirms real catalog relationship after submission | **Fixed today** → new project | Same treatment; `seller_id` added to `Verify Relationships` → `Log Verification Result` (was missing entirely, would have hit a NOT NULL constraint) |
| 09/10 | OAuth Initiate / Callback | **Structurally cannot work while app is in Draft status** (Amazon error MD9100) | New | Self-authorization is the only path until the app is Published |
| 11 | Amazon Disconnect | Clears local connection record only | New | Does **not** revoke real Amazon authorization |
| 14 | Matrix Generator | Generic dimension-based matrix (not hardcoded Size/Color) | New | |
| 15/16 | Theme Discovery / Theme Picker | Live PTD theme lookup | New | |
| 17/18 | Existing Parent Lookup / Child Validation | Full existing-parent validation logic (brand consensus, generic-brand caution, existing-parent-conflict, formatting suggestions) | New | Far more mature than early planning docs described |
| 19 | Listings Item Lookup | SKU-keyed child listing lookup | New | Not ASIN-keyed — real API constraint, not a design choice |
| 20 | AI Validation Explanation | Per-child AI summary via Claude | New | Consumes wf18's full output shape |
| 21/22 | Dashboard Listing / Connection Status | | New | |
| 23 | Create Merge Request | Creates `merge_requests` + `merge_request_items` rows | New | Built this session |
| 24 | Build Existing-Parent Payload | Real PATCH-based Amazon feed payload (no synthetic parent) | New | Built and verified against live Amazon today |
| 25 | Get Submission Status | Reads combined submission + verification status | New | Built this session |

**Missing entirely:** nothing yet *logs* a real submission into `submission_logs` when one actually happens — Approval's "Submit for Merge" doesn't call anything real yet.

---

## 3. Amazon app configuration (hard-won today)

- **App name:** Sellora.AI — **App ID:** `amzn1.sp.solution.5e1b73ff-7d0c-4c99-a019-dccd1d314d85`
- **Status: Draft** — not Published on the Appstore.
- **Role registered: Product Listing** — confirmed present, but self-authorization on a Draft app appears not to actually grant a token carrying write/feed-submission scope, regardless of re-authorization. This is very likely a **hard platform limit**, not a config gap — real feed submission is blocked until the app is Published (Amazon's Appstore review, a weeks-long process).
- **Everything else works against live Amazon right now**: Catalog Items lookups, Listings Items lookups, feed *document creation*, and S3 upload all succeeded with real data. Only the final `feeds/submit` call is blocked, and only by this scope issue.

---

## 4. The two-places-for-one-token gotcha

The Amazon refresh token is stored **twice, independently**:
- **Supabase**, via `store_amazon_refresh_token` / `get_amazon_refresh_token` RPCs — read by every n8n workflow that calls Amazon directly (wf15, 17, 18, 19).
- **Railway**, as the `LWA_REFRESH_TOKEN` environment variable on the `amazon-variation-spapi-proxy` service — read only by that proxy, which backs wf06/07/08 and was tested directly via Postman.

**These do not sync automatically.** Every time the token is regenerated, both places need manual updating, in this order: Supabase RPC first, then Railway's variable, then wait for Railway's redeploy to finish before testing. Today's entire multi-hour troubleshooting chain happened specifically because this wasn't understood ahead of time.

Other credentials worth remembering:
- `LWA_CLIENT_ID` / `LWA_CLIENT_SECRET` (Railway) identify the *app*, not the seller — these don't need touching when the seller's token changes.
- The legacy project's `wf06` had a real Supabase anon-key JWT hardcoded in plain text (not a credential reference) — flagged for rotation, not urgent since it's the retired project, but the pattern is worth avoiding going forward.

---

## 5. Frontend — screens built and wired

Parent Mode → Theme Selection → Child Entry → Validation (+ AI summary) → Create Merge Request → Payload Preview → Approval (5 checkboxes) → Tracking. All tested end-to-end with real data today, including a real, successful Amazon feed-document creation and S3 upload.

**Still open:**
- **Fix Issues** — currently just routes back to Child Entry rather than a dedicated pre-filled correction screen (a deliberate simplification, not a bug).
- **New Parent mode** — still a placeholder; would need wf01/03/05 rebuilt for the new project/schema, not just re-pointed (wf05 specifically needs a structural redesign).
- **Wizard-state persistence** — wizard state is in-memory only; any full page reload mid-flow loses all progress. Raised repeatedly, never picked up.
- **Logging a real submission** — the piece that would make Tracking show real (not manually-inserted-for-testing) data.

---

## 6. If you only remember five things from this document

1. Production Supabase project is `dbgzqwophuukxuwgvgsh` ("catalove-production") — the other one is retired.
2. A token change means updating **both** Supabase and Railway, in that order, waiting for Railway's redeploy before testing.
3. Real feed *submission* is blocked by Amazon's Draft-app status, not by anything in this codebase — Appstore Publication is the actual fix.
4. wf23/24/25 are new this session and don't exist anywhere except this n8n instance — export them.
5. wf18's payload-building logic is the mature, correct one for existing-parent merges; wf01/05's logic is for a different (never-built) New Parent flow and shouldn't be reused as-is.

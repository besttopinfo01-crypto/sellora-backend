# Sellora.ai — Backend (n8n Workflows)

n8n is the workflow/business-logic engine for Sellora.ai. This repo holds the
workflow exports plus the deployment config for the self-hosted instance they
run on.

See `infra/README.md` to actually stand up the n8n instance.

## The 8 workflows carried forward from the original single-seller build

These were built, tested, and used in production over a 78-day single-seller
project (34 real bugs found and fixed along the way) before Sellora.ai existed
as a multi-tenant product. They're the reference implementation for the
"port forward" work — real, tested logic to adapt, not a blank-page rebuild.

| File | Role | Adapts starting |
|---|---|---|
| `wf01-input-validator.json` | Validates a merge request's raw input before anything else runs | Week 3 |
| `wf02-correction-intake.json` | Handles seller corrections when Step 4b (Fix Issues) is reached | Week 3 |
| `wf03-real-data-dry-run.json` | Runs validation against real live Amazon data (brand/product-type/theme match, duplicate values, etc.) | Week 3–4 |
| `wf04-manual-approval.json` | Gates on the four required confirmation checkboxes + validation having actually passed before allowing payload preview | Week 7 |
| `wf05-payload-preview.json` | Builds the JSON_LISTINGS_FEED payload shown (as a tree/grid, never raw JSON) in Step 5 | Week 4–7 |
| `wf06-controlled-submission.json` | Submits the feed to Amazon | Week 8 |
| `wf07-feed-poller.json` | Polls feed processing status every 5 minutes | Week 8 (candidate for the push-notification rework noted below) |
| `wf08-post-submission-verification.json` | Confirms the parent-child relationship actually exists in the real catalog post-processing — a `DONE` processing status alone is never treated as final success | Week 8 |

## Security note: a real Anthropic API key was found and redacted

`wf01-input-validator.json` originally had a live Anthropic API key
(`x-api-key` header, 3 HTTP Request nodes calling `api.anthropic.com`)
hardcoded directly in the JSON. GitHub's push protection caught it before
it ever reached a remote — it's now replaced with the placeholder string
`REPLACE_WITH_ANTHROPIC_API_KEY__SET_VIA_N8N_CREDENTIALS_NOT_HERE` in all
three locations.

**If that original key hasn't been revoked yet, do that first, independent
of anything else in this repo** — see the chat for exact steps. A key that
touched a local git history and a zip file should be treated as exposed
regardless of whether the push succeeded.

Once revoked, generate a fresh key and add it to n8n as a proper Credential
(HTTP Header Auth: name `x-api-key`) after importing this workflow — not
typed into the node parameters directly, which is what caused this in the
first place. The other 7 workflows were checked too: no other Anthropic
keys, AWS keys, or Supabase secret-tier keys exist anywhere in this set —
only Supabase `publishable`/`anon` values, which are safe to expose by
Supabase's own design (see `infra/README.md`).

## Every one of these needs the same core change before Sellora.ai can use it

All 8 were built for **one hardcoded seller** (fixed Supabase rows, a single
shared Amazon connection). None of them yet do the multi-tenant credential
lookup a real subscribing-seller SaaS needs. That's Day 26+ work, not Day 1 —
noted here so it isn't mistaken for already-done.

## A known improvement opportunity, not yet built

`wf07-feed-poller.json` polls Amazon every 5 minutes. Amazon's Feeds API
supports subscription-based push notifications (via a `filterExpression`
using CEL syntax) for processing-status changes — confirmed during PRD
research. Replacing the poll with a real push subscription would cut n8n
executions materially at scale and get status changes faster. Worth building
this way from the start rather than carrying the polling pattern forward
unchanged — flagged in the PRD (Section 10.6) too.

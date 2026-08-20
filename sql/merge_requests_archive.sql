-- Adds soft-delete support to merge_requests. Nullable, no default: every
-- existing row reads as NULL (not archived) with no backfill needed.
-- Run this once against the real project (dbgzqwophuukxuwgvgsh) before
-- either new workflow is used - both of them, and wf21's updated query,
-- depend on this column existing.

ALTER TABLE merge_requests
  ADD COLUMN IF NOT EXISTS archived_at timestamptz;

-- Optional, worth adding given the dashboard query filters on this column
-- on every single load: keeps "give me every non-archived row for this
-- seller" fast as the table grows past the 99 rows already on it.
CREATE INDEX IF NOT EXISTS idx_merge_requests_seller_active
  ON merge_requests (seller_id)
  WHERE archived_at IS NULL;

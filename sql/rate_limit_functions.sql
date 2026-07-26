-- Day 27: RPC layer for the existing seller_rate_limits table (built Week 1,
-- had no functions on top of it until now). Fixed-window counter, matching
-- the table's own columns (window_start, request_count) - NOT a token-bucket
-- simulation of Amazon's internal algorithm, deliberately. Real-world SP-API
-- behavior can throttle far below documented limits (a public bug report
-- showed ~0.25 req/s actual vs 5 req/s documented on a similar endpoint), so
-- this is a soft PRE-FLIGHT check, not the authoritative gate - the
-- authoritative backstop is still reacting to real 429 responses from Amazon
-- (handled at the workflow level via retry-on-fail, not here).
--
-- Window granularity: 1 second, matching SP-API's own per-second token
-- bucket model in its documentation.
--
-- Written without relying on an ON CONFLICT clause, since the existing
-- table's unique-constraint state (if any) on (seller_id, action_type,
-- window_start) wasn't confirmed - explicit row locking (FOR UPDATE) works
-- correctly regardless.

create or replace function check_and_increment_rate_limit(
  p_seller_id uuid,
  p_action_type text,
  p_max_per_window integer
) returns table (
  allowed boolean,
  current_count integer,
  window_start timestamptz
)
language plpgsql
security definer
as $$
declare
  v_window_start timestamptz := date_trunc('second', now());
  v_id bigint;
  v_count integer;
begin
  select id, request_count into v_id, v_count
  from seller_rate_limits
  where seller_id = p_seller_id
    and action_type = p_action_type
    and seller_rate_limits.window_start = v_window_start
  for update;

  if v_id is null then
    insert into seller_rate_limits (seller_id, action_type, window_start, request_count)
    values (p_seller_id, p_action_type, v_window_start, 1)
    returning request_count into v_count;
  else
    update seller_rate_limits
    set request_count = request_count + 1
    where id = v_id
    returning request_count into v_count;
  end if;

  return query select (v_count <= p_max_per_window), v_count, v_window_start;
end;
$$;

grant execute on function check_and_increment_rate_limit to service_role;

-- Read-only companion, useful later for monitoring/dashboards without
-- incrementing anything.
create or replace function get_current_rate_limit_status(
  p_seller_id uuid,
  p_action_type text
) returns table (
  current_count integer,
  window_start timestamptz
)
language plpgsql
security definer
as $$
begin
  return query
  select r.request_count, r.window_start
  from seller_rate_limits r
  where r.seller_id = p_seller_id
    and r.action_type = p_action_type
    and r.window_start = date_trunc('second', now());
end;
$$;

grant execute on function get_current_rate_limit_status to service_role;

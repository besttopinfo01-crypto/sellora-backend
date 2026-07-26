-- Day 24 prerequisite: Amazon Selling Partner ID storage
--
-- The Listings Items API requires the seller's own Amazon Selling Partner ID
-- as a path parameter (GET /listings/2021-08-01/items/{sellingPartnerId}/{sku}).
-- This is a distinct identifier issued by Amazon -- NOT the same as our
-- internal seller_id UUID used everywhere else in this project.
--
-- Amazon returns selling_partner_id on every OAuth callback. wf10 already
-- captures it (visible in the "Prepare Handoff (Day 9)" node's output) but
-- never persists it -- only p_seller_id and p_refresh_token currently reach
-- store_amazon_refresh_token.
--
-- This is a SEPARATE, ADDITIVE table rather than a modification to the
-- existing refresh-token storage mechanism, whose source we have not
-- reviewed and which is working, security-critical code. Same create-table +
-- upsert/get RPC pattern as product_type_theme_cache.sql.

create table if not exists seller_amazon_identity (
  seller_id uuid primary key,
  selling_partner_id text not null,
  captured_at timestamptz not null default now()
);

create or replace function upsert_seller_selling_partner_id(
  p_seller_id uuid,
  p_selling_partner_id text
) returns uuid
language plpgsql
security definer
as $$
declare
  v_id uuid;
begin
  insert into seller_amazon_identity (seller_id, selling_partner_id, captured_at)
  values (p_seller_id, p_selling_partner_id, now())
  on conflict (seller_id)
  do update set
    selling_partner_id = excluded.selling_partner_id,
    captured_at = now()
  returning seller_id into v_id;
  return v_id;
end;
$$;

create or replace function get_seller_selling_partner_id(
  p_seller_id uuid
) returns table (
  selling_partner_id text,
  captured_at timestamptz
)
language plpgsql
security definer
as $$
begin
  return query
  select s.selling_partner_id, s.captured_at
  from seller_amazon_identity s
  where s.seller_id = p_seller_id;
end;
$$;

grant execute on function upsert_seller_selling_partner_id to service_role;
grant execute on function get_seller_selling_partner_id to service_role;

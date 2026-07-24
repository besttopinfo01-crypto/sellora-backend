-- Day 16: Product Type Theme Cache
-- Table + RPC functions supporting wf15 (Theme Discovery)
-- Caches Amazon SP-API variation_theme data per product_type/marketplace_id,
-- avoiding a full schema re-fetch on every request.

create table if not exists product_type_theme_cache (
  id uuid primary key default gen_random_uuid(),
  product_type text not null,
  marketplace_id text not null,
  valid_themes jsonb not null,
  deprecated_themes jsonb not null default '[]'::jsonb,
  product_type_version text not null,
  fetched_at timestamptz not null default now(),
  unique (product_type, marketplace_id)
);

create or replace function upsert_product_type_theme_cache(
  p_product_type text,
  p_marketplace_id text,
  p_valid_themes jsonb,
  p_deprecated_themes jsonb,
  p_product_type_version text
) returns uuid
language plpgsql
security definer
as $$
declare
  v_id uuid;
begin
  insert into product_type_theme_cache (product_type, marketplace_id, valid_themes, deprecated_themes, product_type_version, fetched_at)
  values (p_product_type, p_marketplace_id, p_valid_themes, p_deprecated_themes, p_product_type_version, now())
  on conflict (product_type, marketplace_id)
  do update set
    valid_themes = excluded.valid_themes,
    deprecated_themes = excluded.deprecated_themes,
    product_type_version = excluded.product_type_version,
    fetched_at = now()
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function get_product_type_theme_cache(
  p_product_type text,
  p_marketplace_id text
) returns table (
  valid_themes jsonb,
  deprecated_themes jsonb,
  product_type_version text,
  fetched_at timestamptz
)
language plpgsql
security definer
as $$
begin
  return query
  select c.valid_themes, c.deprecated_themes, c.product_type_version, c.fetched_at
  from product_type_theme_cache c
  where c.product_type = p_product_type
    and c.marketplace_id = p_marketplace_id;
end;
$$;

grant execute on function upsert_product_type_theme_cache to service_role;
grant execute on function get_product_type_theme_cache to service_role;

-- TarımCepte manual backup export
-- Run this in Supabase SQL Editor, then download/copy the single result row.
-- It exports the app data needed before public.users -> auth.users migration.

select jsonb_pretty(
  jsonb_build_object(
    'exported_at', now(),
    'source', 'tarimcepte_manual_backup',
    'tables', jsonb_build_object(
      'public.users',
        coalesce((select jsonb_agg(to_jsonb(u) order by u.created_at, u.id) from public.users u), '[]'::jsonb),
      'public.products',
        coalesce((select jsonb_agg(to_jsonb(p) order by p.name, p.id) from public.products p), '[]'::jsonb),
      'public.product_prices',
        coalesce((select jsonb_agg(to_jsonb(pp) order by pp.city, pp.district, pp.product_id) from public.product_prices pp), '[]'::jsonb),
      'public.seasons',
        coalesce((select jsonb_agg(to_jsonb(s) order by s.start_date, s.id) from public.seasons s), '[]'::jsonb),
      'public.harvests',
        coalesce((select jsonb_agg(to_jsonb(h) order by h.harvest_date, h.id) from public.harvests h), '[]'::jsonb)
    ),
    'counts', jsonb_build_object(
      'public.users', (select count(*) from public.users),
      'public.products', (select count(*) from public.products),
      'public.product_prices', (select count(*) from public.product_prices),
      'public.seasons', (select count(*) from public.seasons),
      'public.harvests', (select count(*) from public.harvests)
    )
  )
) as backup_json;

-- If the JSON result is too large, run these one by one and download each result as CSV:
--
-- select * from public.users order by created_at, id;
-- select * from public.products order by name, id;
-- select * from public.product_prices order by city, district, product_id;
-- select * from public.seasons order by start_date, id;
-- select * from public.harvests order by harvest_date, id;

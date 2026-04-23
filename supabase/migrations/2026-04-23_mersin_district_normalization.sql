-- Mersin ilce normalizasyonu
-- Yeni standart: Merkez, Tarsus, Erdemli, Aydincik, Bozyazi/Tekeli, Anamur
-- Bu script eski ilce adlarini yeni yapiya donusturur.

begin;

-- 1) users tablosunda Mersin ilce degerlerini normalize et
update public.users
set city = 'Mersin'
where city is not null
  and lower(trim(city)) = 'mersin';

update public.users
set district = case
  when district is null or btrim(district) = '' then 'Merkez'
  when lower(btrim(district)) in ('merkez') then 'Merkez'
  when lower(btrim(district)) in ('tarsus') then 'Tarsus'
  when lower(btrim(district)) in ('erdemli') then 'Erdemli'
  when lower(btrim(district)) in ('aydincik', 'aydıncık') then 'Aydıncık'
  when lower(btrim(district)) in ('bozyazi', 'bozyazı', 'tekeli', 'bozyazi/tekeli', 'bozyazı/tekeli') then 'Bozyazı/Tekeli'
  when lower(btrim(district)) in ('anamur') then 'Anamur'
  -- Kaldirilan ilceler Merkez altinda toplanir
  when lower(btrim(district)) in ('akdeniz', 'mezitli', 'toroslar', 'yenisehir', 'yenişehir', 'silifke', 'mut', 'gulnar', 'gülnar', 'camliyayla', 'çamlıyayla') then 'Merkez'
  else 'Merkez'
end
where city = 'Mersin';

-- 2) product_prices tablosunda Mersin ilcelerini normalize et ve duplicate kayitlari temizle
with mapped as (
  select
    pp.product_id,
    'Mersin'::text as city,
    case
      when pp.district is null or btrim(pp.district) = '' then 'Merkez'
      when lower(btrim(pp.district)) in ('merkez') then 'Merkez'
      when lower(btrim(pp.district)) in ('tarsus') then 'Tarsus'
      when lower(btrim(pp.district)) in ('erdemli') then 'Erdemli'
      when lower(btrim(pp.district)) in ('aydincik', 'aydıncık') then 'Aydıncık'
      when lower(btrim(pp.district)) in ('bozyazi', 'bozyazı', 'tekeli', 'bozyazi/tekeli', 'bozyazı/tekeli') then 'Bozyazı/Tekeli'
      when lower(btrim(pp.district)) in ('anamur') then 'Anamur'
      when lower(btrim(pp.district)) in ('akdeniz', 'mezitli', 'toroslar', 'yenisehir', 'yenişehir', 'silifke', 'mut', 'gulnar', 'gülnar', 'camliyayla', 'çamlıyayla') then 'Merkez'
      else 'Merkez'
    end as district,
    pp.price_per_kg,
    coalesce(pp.updated_at, now()) as updated_at
  from public.product_prices pp
  where lower(trim(pp.city)) = 'mersin'
),
ranked as (
  select
    product_id,
    city,
    district,
    price_per_kg,
    updated_at,
    row_number() over (
      partition by product_id, city, district
      order by updated_at desc, product_id
    ) as rn
  from mapped
),
dedup as (
  select
    product_id,
    city,
    district,
    price_per_kg,
    updated_at
  from ranked
  where rn = 1
),
purged as (
  delete from public.product_prices
  where lower(trim(city)) = 'mersin'
  returning id
)
insert into public.product_prices (product_id, city, district, price_per_kg, updated_at)
select
  product_id,
  city,
  district,
  price_per_kg,
  updated_at
from dedup
on conflict (product_id, city, district)
do update set
  price_per_kg = excluded.price_per_kg,
  updated_at = excluded.updated_at;

commit;

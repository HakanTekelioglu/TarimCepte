-- Yeni alanların eklenmesi
alter table public.users add column if not exists city text;
alter table public.users add column if not exists district text;

-- Fiyatlar bölge tablosu
create table if not exists public.product_prices (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  city text not null,
  district text,
  price_per_kg double precision not null,
  updated_at timestamptz not null default now(),
  unique(product_id, city, district)
);

create index if not exists idx_product_prices_location on public.product_prices(city, district);

-- yetkiler
alter table public.product_prices disable row level security;

drop policy if exists "product_prices_select_all" on public.product_prices;
create policy "product_prices_select_all" on public.product_prices
for select to authenticated
using (true);

drop policy if exists "product_prices_insert_all" on public.product_prices;
create policy "product_prices_insert_all" on public.product_prices
for insert to authenticated
with check (true);

drop policy if exists "product_prices_update_all" on public.product_prices;
create policy "product_prices_update_all" on public.product_prices
for update to authenticated
using (true)
with check (true);

-- Hal Fiyat Supabase şeması (MVP)
-- Supabase SQL Editor içinde çalıştırın.

create extension if not exists "pgcrypto";

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  phone_number text not null unique,
  password text not null,
  full_name text not null,
  commission_rate double precision not null default 8.0,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.users drop constraint if exists users_id_fkey;
alter table public.users alter column id set default gen_random_uuid();
alter table public.users add column if not exists password text;
alter table public.users add column if not exists phone_number text;
alter table public.users alter column phone_number set not null;
create unique index if not exists users_phone_number_key on public.users(phone_number);

update public.users
set password = coalesce(password, '123456')
where password is null;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price_per_kg double precision not null,
  category text not null default 'sebze',
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.seasons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  start_date timestamptz not null,
  end_date timestamptz,
  is_active boolean not null default true,
  total_gross_earning double precision not null default 0,
  total_commission double precision not null default 0,
  total_net_earning double precision not null default 0,
  total_harvests integer not null default 0,
  total_kg double precision not null default 0
);

create table if not exists public.harvests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  product_id uuid not null references public.products(id),
  product_name text not null,
  crate_count integer not null,
  total_kg double precision not null,
  price_per_kg double precision not null,
  gross_earning double precision not null,
  commission_rate double precision not null,
  commission_amount double precision not null,
  net_earning double precision not null,
  season_id uuid not null references public.seasons(id) on delete cascade,
  harvest_date timestamptz not null,
  notes text
);

create index if not exists idx_products_active on public.products(is_active);
create index if not exists idx_seasons_user on public.seasons(user_id);
create index if not exists idx_harvests_user on public.harvests(user_id);
create index if not exists idx_harvests_season on public.harvests(season_id);

alter table public.users disable row level security;
alter table public.products disable row level security;
alter table public.seasons disable row level security;
alter table public.harvests disable row level security;

-- users: kullanıcı kendi profilini okuyup günceller
drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users
for select to authenticated
using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own" on public.users
for insert to authenticated
with check (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own" on public.users
for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- products: authenticated kullanıcılar ürünleri okuyabilir,
-- yazma işlemleri MVP için serbest bırakıldı (admin kontrolü app tarafında)
drop policy if exists "products_select_all" on public.products;
create policy "products_select_all" on public.products
for select to authenticated
using (true);

drop policy if exists "products_insert_all" on public.products;
create policy "products_insert_all" on public.products
for insert to authenticated
with check (true);

drop policy if exists "products_update_all" on public.products;
create policy "products_update_all" on public.products
for update to authenticated
using (true)
with check (true);

-- seasons: kullanıcı sadece kendi sezonlarını görür/yazar
drop policy if exists "seasons_select_own" on public.seasons;
create policy "seasons_select_own" on public.seasons
for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "seasons_insert_own" on public.seasons;
create policy "seasons_insert_own" on public.seasons
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "seasons_update_own" on public.seasons;
create policy "seasons_update_own" on public.seasons
for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- harvests: kullanıcı sadece kendi hasatlarını görür/yazar
drop policy if exists "harvests_select_own" on public.harvests;
create policy "harvests_select_own" on public.harvests
for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "harvests_insert_own" on public.harvests;
create policy "harvests_insert_own" on public.harvests
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "harvests_update_own" on public.harvests;
create policy "harvests_update_own" on public.harvests
for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "harvests_delete_own" on public.harvests;
create policy "harvests_delete_own" on public.harvests
for delete to authenticated
using (auth.uid() = user_id);

-- Örnek admin ürün seed (opsiyonel)
insert into public.products (name, price_per_kg, category)
values
  ('Salatalık', 75.0, 'sebze'),
  ('Sivri Biber', 60.0, 'sebze'),
  ('Patlıcan', 55.0, 'sebze'),
  ('Kıl Biber', 110.0, 'sebze'),
  ('Fasulye', 115.0, 'sebze'),
  ('Domates', 35.0, 'sebze'),
  ('Muz', 50.0, 'meyve'),
  ('Çilek', 120.0, 'meyve'),
  ('Üzüm', 80.0, 'meyve'),
  ('Şeftali', 65.0, 'meyve'),
  ('Erik', 50.0, 'meyve')
on conflict do nothing;

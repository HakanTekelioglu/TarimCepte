alter table public.users
  add column if not exists email text;

create index if not exists idx_users_email on public.users(email);

notify pgrst, 'reload schema';

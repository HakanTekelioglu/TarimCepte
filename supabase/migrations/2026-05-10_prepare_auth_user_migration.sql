-- Run before the Node migration script.
-- This keeps public.users as the app profile table while Auth owns passwords.

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'users'
      and column_name = 'password'
  ) then
    alter table public.users alter column password drop not null;
  end if;
end $$;

alter table public.users
  add column if not exists auth_migrated_at timestamptz;

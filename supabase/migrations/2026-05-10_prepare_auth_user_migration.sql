-- Run before the Node migration script.
-- This keeps public.users as the app profile table while Auth owns passwords.

alter table public.users
  alter column password drop not null;

alter table public.users
  add column if not exists auth_migrated_at timestamptz;

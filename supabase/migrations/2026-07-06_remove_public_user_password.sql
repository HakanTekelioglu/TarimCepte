-- Supabase Auth owns password hashing in auth.users.
-- public.users is an application profile table and must not store passwords.

alter table public.users
  drop column if exists password;

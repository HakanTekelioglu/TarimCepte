-- Run only after:
-- 1. all users are in Authentication > Users,
-- 2. the app logs in with Supabase Auth,
-- 3. you have verified login/register on a real account.

alter table public.users
  drop column if exists password;

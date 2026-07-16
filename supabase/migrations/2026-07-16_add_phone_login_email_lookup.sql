-- Telefon ile giriste, RLS acikken public.users tablosunu anonim olarak
-- okunabilir yapmak yerine yalnizca eslesen Auth e-postasini dondurur.
create or replace function public.login_email_for_phone(
  phone_candidates text[]
)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select lower(trim(u.email))
  from public.users as u
  where u.phone_number = any(phone_candidates)
    and nullif(trim(u.email), '') is not null
  order by array_position(phone_candidates, u.phone_number)
  limit 1;
$$;

revoke all on function public.login_email_for_phone(text[]) from public;
grant execute on function public.login_email_for_phone(text[]) to anon;
grant execute on function public.login_email_for_phone(text[]) to authenticated;

notify pgrst, 'reload schema';

-- Run after the Node migration script.
-- It fails loudly if any public user has not been created in auth.users.

do $$
begin
  if exists (
    select 1
    from public.users u
    left join auth.users au on au.id = u.id
    where au.id is null
  ) then
    raise exception 'Some public.users rows do not have matching auth.users rows.';
  end if;
end $$;

alter table public.users
  drop constraint if exists users_id_auth_fkey;

alter table public.users
  add constraint users_id_auth_fkey
  foreign key (id) references auth.users(id) on delete cascade
  not valid;

alter table public.users
  validate constraint users_id_auth_fkey;

update public.users u
set auth_migrated_at = now()
where auth_migrated_at is null
  and exists (
    select 1 from auth.users au where au.id = u.id
  );

select
  (select count(*) from public.users) as public_users_count,
  (
    select count(*)
    from public.users u
    join auth.users au on au.id = u.id
  ) as linked_auth_users_count;

create or replace function public.handle_auth_user_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (
    id,
    email,
    full_name,
    last_login_at
  )
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    ),
    now()
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, public.users.full_name),
    last_login_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_sync on auth.users;

create trigger on_auth_user_sync
after insert or update on auth.users
for each row execute procedure public.handle_auth_user_sync();

insert into public.users (
  id,
  email,
  full_name,
  last_login_at
)
select
  au.id,
  au.email,
  coalesce(
    au.raw_user_meta_data ->> 'full_name',
    au.raw_user_meta_data ->> 'name'
  ),
  coalesce(au.last_sign_in_at, now())
from auth.users au
on conflict (id) do update
set
  email = excluded.email,
  full_name = coalesce(excluded.full_name, public.users.full_name),
  last_login_at = excluded.last_login_at;

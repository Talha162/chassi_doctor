-- Migration: create device_tokens table

create extension if not exists pgcrypto;

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  token text not null unique,
  platform text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists device_tokens_user_id_idx on public.device_tokens(user_id);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists device_tokens_set_updated_at on public.device_tokens;
create trigger device_tokens_set_updated_at
before update on public.device_tokens
for each row execute procedure public.set_updated_at();

alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens_select_owner" on public.device_tokens;
create policy "device_tokens_select_owner" on public.device_tokens
  for select using (auth.uid() = user_id);

drop policy if exists "device_tokens_insert_owner" on public.device_tokens;
create policy "device_tokens_insert_owner" on public.device_tokens
  for insert with check (auth.uid() = user_id);

drop policy if exists "device_tokens_update_owner" on public.device_tokens;
create policy "device_tokens_update_owner" on public.device_tokens
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "device_tokens_delete_owner" on public.device_tokens;
create policy "device_tokens_delete_owner" on public.device_tokens
  for delete using (auth.uid() = user_id);

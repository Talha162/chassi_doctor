-- Saved geometry setups, shared by the website calculators and the app.
--
-- `data` holds a calculator's state exactly as the website keeps it in
-- localStorage (e.g. key chassis-doctor:roll-centre:v2), so the web and the
-- app read and write the same JSON with no conversion. `state_key` records
-- which storage key / version the JSON belongs to.

create table if not exists public.saved_setups (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users(id) on delete cascade,
  tool        text not null
              check (tool in ('corner-weight', 'motion-ratio', 'ifs-roll-centre', 'beam-axle')),
  state_key   text not null check (char_length(state_key) between 1 and 80),
  name        text not null check (char_length(btrim(name)) between 1 and 80),
  track_name  text check (track_name is null or char_length(track_name) <= 80),
  event_date  date,
  notes       text check (notes is null or char_length(notes) <= 1000),
  data        jsonb not null check (jsonb_typeof(data) = 'object' and pg_column_size(data) <= 65536),
  source      text not null default 'app' check (source in ('app', 'web')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists saved_setups_user_tool_idx
  on public.saved_setups (user_id, tool, updated_at desc);

drop trigger if exists saved_setups_set_updated_at on public.saved_setups;
create trigger saved_setups_set_updated_at
  before update on public.saved_setups
  for each row execute function public.set_updated_at();

alter table public.saved_setups enable row level security;

drop policy if exists saved_setups_select_own on public.saved_setups;
create policy saved_setups_select_own on public.saved_setups
  for select to authenticated
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists saved_setups_insert_own on public.saved_setups;
create policy saved_setups_insert_own on public.saved_setups
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists saved_setups_update_own on public.saved_setups;
create policy saved_setups_update_own on public.saved_setups
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists saved_setups_delete_own on public.saved_setups;
create policy saved_setups_delete_own on public.saved_setups
  for delete to authenticated
  using (auth.uid() = user_id);

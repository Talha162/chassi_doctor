-- Settings the app reads at start-up, so access rules can change without a new release.
--   hard_paywall_ios / hard_paywall_android  true = the whole app needs All Access (3-day trial first)
--   paywall_since         accounts created before this are "existing users"...
--   legacy_grace_until    ...and keep free access until this time
--   min_build_ios / min_build_android  older builds must update before they can be used
create table if not exists public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.app_config enable row level security;

drop policy if exists app_config_read on public.app_config;
create policy app_config_read on public.app_config
  for select to anon, authenticated using (true);

drop policy if exists app_config_admin_write on public.app_config;
create policy app_config_admin_write on public.app_config
  for all to authenticated using (public.is_admin(auth.uid())) with check (public.is_admin(auth.uid()));

insert into public.app_config (key, value) values
  ('hard_paywall_ios', 'true'),
  ('hard_paywall_android', 'false'),
  ('paywall_since', '"2026-11-24T00:00:00Z"'),
  ('legacy_grace_until', '"2026-12-01T00:00:00Z"'),
  ('min_build_ios', '0'),
  ('min_build_android', '0')
on conflict (key) do nothing;

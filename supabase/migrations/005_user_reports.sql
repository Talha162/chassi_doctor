-- User-submitted reports for missing symptoms and issues.
-- These rows are pending admin review. The admin panel may later promote
-- approved rows into the live `chassis_symptoms` / `chassis_issue_options`
-- tables; this script only stores the raw report.

-- ============================================================
-- user_symptom_reports
-- ============================================================
create table if not exists public.user_symptom_reports (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  title       text not null check (char_length(title) between 1 and 120),
  description text,
  status      text not null default 'pending'
              check (status in ('pending','approved','rejected')),
  admin_notes text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at  timestamptz not null default now()
);

create index if not exists user_symptom_reports_status_idx
  on public.user_symptom_reports(status);
create index if not exists user_symptom_reports_user_id_idx
  on public.user_symptom_reports(user_id);

-- ============================================================
-- user_issue_reports
-- ============================================================
create table if not exists public.user_issue_reports (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  symptom_id  uuid references public.chassis_symptoms(id) on delete set null,
  title       text not null check (char_length(title) between 1 and 120),
  description text,
  status      text not null default 'pending'
              check (status in ('pending','approved','rejected')),
  admin_notes text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at  timestamptz not null default now()
);

create index if not exists user_issue_reports_status_idx
  on public.user_issue_reports(status);
create index if not exists user_issue_reports_symptom_id_idx
  on public.user_issue_reports(symptom_id);
create index if not exists user_issue_reports_user_id_idx
  on public.user_issue_reports(user_id);

-- ============================================================
-- Row level security
-- Authenticated users may insert and read their own reports.
-- The admin panel uses the service-role key and bypasses RLS,
-- so admins automatically have full access.
-- ============================================================
alter table public.user_symptom_reports enable row level security;
alter table public.user_issue_reports   enable row level security;

drop policy if exists "users insert own symptom reports" on public.user_symptom_reports;
create policy "users insert own symptom reports"
  on public.user_symptom_reports
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "users select own symptom reports" on public.user_symptom_reports;
create policy "users select own symptom reports"
  on public.user_symptom_reports
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "users insert own issue reports" on public.user_issue_reports;
create policy "users insert own issue reports"
  on public.user_issue_reports
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "users select own issue reports" on public.user_issue_reports;
create policy "users select own issue reports"
  on public.user_issue_reports
  for select to authenticated
  using (auth.uid() = user_id);

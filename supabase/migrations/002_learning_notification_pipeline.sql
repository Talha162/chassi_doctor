-- Learning notifications pipeline for courses, modules, and videos.
-- This migration adds:
-- 1. notification_events    -> webhook source for Firebase Cloud Functions
-- 2. user_notifications     -> in-app notification feed consumed by Flutter
-- 3. trigger functions      -> queue events when learning content is published/added
-- 4. RPC helper             -> fetch recipients + FCM tokens for an event

create extension if not exists pgcrypto;

create table if not exists public.notification_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  source_table text not null,
  source_id uuid not null,
  course_id uuid,
  module_id uuid,
  target_type text not null default 'course_enrolled_users',
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending',
  error_message text,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists notification_events_created_at_idx
  on public.notification_events(created_at desc);

create index if not exists notification_events_course_id_idx
  on public.notification_events(course_id);

create index if not exists notification_events_status_idx
  on public.notification_events(status);

create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  notification_event_id uuid references public.notification_events(id) on delete set null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

alter table public.user_notifications
  add column if not exists notification_event_id uuid references public.notification_events(id) on delete set null;

alter table public.user_notifications
  add column if not exists data jsonb not null default '{}'::jsonb;

alter table public.user_notifications
  add column if not exists is_read boolean not null default false;

alter table public.user_notifications
  add column if not exists read_at timestamptz;

create index if not exists user_notifications_user_id_created_at_idx
  on public.user_notifications(user_id, created_at desc);

create or replace function public.set_user_notification_read_at()
returns trigger as $$
begin
  if new.is_read = true and coalesce(old.is_read, false) = false then
    new.read_at := now();
  elsif new.is_read = false then
    new.read_at := null;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists user_notifications_set_read_at on public.user_notifications;
create trigger user_notifications_set_read_at
before update on public.user_notifications
for each row execute procedure public.set_user_notification_read_at();

alter table public.user_notifications enable row level security;

drop policy if exists "user_notifications_select_owner" on public.user_notifications;
create policy "user_notifications_select_owner"
  on public.user_notifications
  for select
  using (auth.uid() = user_id);

drop policy if exists "user_notifications_update_owner" on public.user_notifications;
create policy "user_notifications_update_owner"
  on public.user_notifications
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "user_notifications_delete_owner" on public.user_notifications;
create policy "user_notifications_delete_owner"
  on public.user_notifications
  for delete
  using (auth.uid() = user_id);

create or replace function public.queue_learning_notification_event()
returns trigger as $$
declare
  v_course_id uuid;
  v_module_id uuid;
  v_course_title text;
  v_title text;
  v_body text;
  v_event_type text;
  v_target_type text;
  v_payload jsonb;
begin
  if tg_table_name = 'courses' then
    if tg_op = 'INSERT' and coalesce(new.is_published, false) = true then
      v_course_id := new.id;
      v_title := 'New course available';
      v_body := format('%s is now available in Motorsport University.', new.title);
      v_event_type := 'course_published';
      v_target_type := 'all_users';
      v_payload := jsonb_build_object(
        'course_id', new.id,
        'course_title', new.title,
        'action', 'open_course'
      );
    elsif tg_op = 'UPDATE'
      and coalesce(old.is_published, false) = false
      and coalesce(new.is_published, false) = true then
      v_course_id := new.id;
      v_title := 'New course available';
      v_body := format('%s is now available in Motorsport University.', new.title);
      v_event_type := 'course_published';
      v_target_type := 'all_users';
      v_payload := jsonb_build_object(
        'course_id', new.id,
        'course_title', new.title,
        'action', 'open_course'
      );
    else
      return new;
    end if;
  elsif tg_table_name = 'course_modules' then
    if tg_op <> 'INSERT' then
      return new;
    end if;

    select c.id, c.title
      into v_course_id, v_course_title
      from public.courses c
     where c.id = new.course_id
       and coalesce(c.is_published, false) = true;

    if v_course_id is null then
      return new;
    end if;

    v_module_id := new.id;
    v_title := 'New module added';
    v_body := format('A new module "%s" was added to %s.', new.title, v_course_title);
    v_event_type := 'course_module_added';
    v_target_type := 'course_enrolled_users';
    v_payload := jsonb_build_object(
      'course_id', v_course_id,
      'course_title', v_course_title,
      'module_id', new.id,
      'module_title', new.title,
      'action', 'open_course'
    );
  elsif tg_table_name = 'module_videos' then
    if tg_op <> 'INSERT' then
      return new;
    end if;

    select cm.course_id, cm.id, c.title
      into v_course_id, v_module_id, v_course_title
      from public.course_modules cm
      join public.courses c on c.id = cm.course_id
     where cm.id = new.module_id
       and coalesce(c.is_published, false) = true;

    if v_course_id is null then
      return new;
    end if;

    v_title := 'New lesson added';
    v_body := format('A new video "%s" was added to %s.', new.title, v_course_title);
    v_event_type := 'module_video_added';
    v_target_type := 'course_enrolled_users';
    v_payload := jsonb_build_object(
      'course_id', v_course_id,
      'module_id', v_module_id,
      'video_id', new.id,
      'course_title', v_course_title,
      'video_title', new.title,
      'action', 'open_module'
    );
  else
    return new;
  end if;

  insert into public.notification_events (
    event_type,
    source_table,
    source_id,
    course_id,
    module_id,
    target_type,
    title,
    body,
    payload
  )
  values (
    v_event_type,
    tg_table_name,
    new.id,
    v_course_id,
    v_module_id,
    v_target_type,
    v_title,
    v_body,
    v_payload
  );

  return new;
end;
$$ language plpgsql;

drop trigger if exists courses_queue_learning_notification_event on public.courses;
create trigger courses_queue_learning_notification_event
after insert or update on public.courses
for each row execute procedure public.queue_learning_notification_event();

drop trigger if exists course_modules_queue_learning_notification_event on public.course_modules;
create trigger course_modules_queue_learning_notification_event
after insert on public.course_modules
for each row execute procedure public.queue_learning_notification_event();

drop trigger if exists module_videos_queue_learning_notification_event on public.module_videos;
create trigger module_videos_queue_learning_notification_event
after insert on public.module_videos
for each row execute procedure public.queue_learning_notification_event();

create or replace function public.get_notification_event_recipients(p_event_id uuid)
returns table (
  event_id uuid,
  user_id uuid,
  token text,
  platform text,
  title text,
  body text,
  payload jsonb
)
language sql
security definer
set search_path = public
as $$
  select distinct
    ne.id as event_id,
    dt.user_id,
    dt.token,
    dt.platform,
    ne.title,
    ne.body,
    ne.payload
  from public.notification_events ne
  join public.device_tokens dt on true
  join public.users u on u.id = dt.user_id
  left join public.course_enrollments ce
    on ce.user_id = dt.user_id
   and ce.course_id = ne.course_id
  where ne.id = p_event_id
    and coalesce(u.status, 'active') = 'active'
    and (
      ne.target_type = 'all_users'
      or (
        ne.target_type = 'course_enrolled_users'
        and ce.id is not null
      )
    );
$$;

comment on function public.get_notification_event_recipients(uuid) is
'Returns the recipient users and device tokens for a queued notification event.';

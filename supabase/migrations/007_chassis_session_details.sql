-- Sessions are now saved on purpose ("Save to session") instead of every time
-- recommendations load, so each one carries a name and the race/test date.
-- Notes keep using history_notes (source_type 'session').

alter table public.chassis_sessions
  add column if not exists session_name text
    check (session_name is null or char_length(session_name) between 1 and 80),
  add column if not exists event_date date;

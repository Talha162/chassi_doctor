-- Setup Record (Phase 5): saved like the calculators, one row per car/season record.
-- A record holds every session's setup, so it may be bigger than one calculator's figures.

alter table public.saved_setups drop constraint saved_setups_tool_check;
alter table public.saved_setups add constraint saved_setups_tool_check
  check (tool in ('corner-weight', 'motion-ratio', 'ifs-roll-centre', 'beam-axle', 'beam-axle-roll-centre', 'setup-record'));

alter table public.saved_setups drop constraint saved_setups_data_check;
alter table public.saved_setups add constraint saved_setups_data_check
  check (
    jsonb_typeof(data) = 'object'
    and pg_column_size(data) <= case when tool = 'setup-record' then 262144 else 65536 end
  );

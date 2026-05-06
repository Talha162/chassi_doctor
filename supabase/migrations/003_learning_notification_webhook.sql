-- Replace the URL and secret placeholders before running this migration.
-- Use the exact deployed function URL returned by Firebase deploy.

create extension if not exists pg_net;

drop trigger if exists notify_learning_events_webhook on public.notification_events;

create trigger notify_learning_events_webhook
after insert on public.notification_events
for each row
execute function supabase_functions.http_request(
  'https://REPLACE_WITH_DEPLOYED_FUNCTION_URL',
  'POST',
  '{"Content-Type":"application/json","x-webhook-secret":"REPLACE_WITH_SUPABASE_WEBHOOK_SECRET"}',
  '{}',
  '5000'
);

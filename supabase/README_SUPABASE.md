This file explains how to apply the `device_tokens` migration and verify it.

Prereqs:
- Install the Supabase CLI: https://supabase.com/docs/guides/cli
- Or have psql access to your Supabase DB (connection string available in Project Settings -> Database -> Connection string).
- Ensure your `.env` file contains `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` (already present).

Option A — Use Supabase SQL editor (quickest):
1. Open https://app.supabase.com and select your project.
2. Go to "SQL" → New Query and paste the contents of `supabase/migrations/001_create_device_tokens.sql`.
3. Run the query.

Option B — Use the Supabase CLI (recommended for migrations):
1. Install and login: `supabase login` (paste your access token).
2. From the project root, run:

```bash
# push local migrations to your Supabase project (make sure supabase/config is set up)
supabase db remote set "${SUPABASE_URL}"  # or configure via supabase link
supabase db push
```

(See Supabase CLI docs for configuring `supabase` in your repo: https://supabase.com/docs/guides/cli)

Option C — Use psql (direct DB connection):
1. Get the full connection string from Supabase Project Settings → Database → Connection string.
2. Run locally (example):

```bash
PGPASSWORD="<db-password>" psql "postgresql://postgres:<db-password>@db.<proj>.supabase.co:5432/postgres" -f supabase/migrations/001_create_device_tokens.sql
```

Verification queries (run in SQL editor or psql):
```sql
-- list columns
select column_name, data_type from information_schema.columns where table_name = 'device_tokens';

-- check policies
select * from pg_policy where polrelid = 'public.device_tokens'::regclass;

-- simple insert (use service role or set auth.uid() = user id accordingly)
insert into public.device_tokens (user_id, token, platform) values ('00000000-0000-0000-0000-000000000000', 'test-token-123', 'android');
select * from public.device_tokens limit 10;
```

Security notes:
- The SQL creates RLS policies that allow only the owning user (via `auth.uid()`) to insert/select/update/delete their tokens. If you plan to write tokens from server side using the Service Role key, remember Service Role bypasses RLS.
- If you want server-side upsert-only behavior, consider creating a Postgres function (RPC) that uses `security definer` and checks caller claims.

If you'd like, I can:
- Create a Postgres RPC for server-side upsert of tokens.
- Attempt to run the migration here (requires a reachable DB connection string or supabase CLI auth token).
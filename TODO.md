# Chassis Doctor TODO

## Client changes
_Waiting for the client's list._

- [ ] …

## Problems found in the 2026-11-15 audit

### Backend / notifications
- [ ] **Course-launch push notifications fail.** 16 `course_published` events have status `failed`. 8 rows in `public.users` have no matching `auth.users` row, and one of them still has a device token. `get_notification_event_recipients` returns that user, the `user_notifications` insert hits the `user_notifications_user_id_fkey` foreign key, and the whole event fails.
  - Fix: clean up the orphaned users and tokens, and make the recipient query join `auth.users` (or skip bad rows instead of failing the whole batch).
  - Also: 3 events from May 2026 are stuck in `pending`.
- [ ] **New module/video notifications reach almost nobody.** The `course_enrolled_users` target depends on `course_enrollments`, which the app stopped writing when it moved to RevenueCat. Only 2 legacy enrollments exist. Target subscribers or all users instead.
- [ ] **Account deletion on the dashboard leaves orphaned `public.users` rows.** `public.users.id` has no FK to `auth.users` with cascade. Add the FK, or a delete trigger.
- [ ] **Two triggers on `auth.users` both insert into `public.users`** (`handle_new_user` and `handle_auth_user_sync`). This is redundant; keep one.
- [ ] **Duplicate RLS policies on `user_notifications`** (two each for select, update and delete). Tidy up.

### Paywall / security
- [ ] **Course content is not gated on the server.** RLS on `course_modules` and `module_videos` only checks `is_published`, and the `course-videos` bucket is public. The paywall exists only in the app.
- [ ] **The `user-avatars` bucket policy lets any signed-in user read, write and delete any file.** Scope it to each user's own path.
- [ ] **`symptom-images` allows uploads from `anon`.**
- [ ] **The webhook secret is hardcoded** in `notify_learning_events_webhook()`. Move it to Vault.
- [ ] **Android RevenueCat key is empty**, so subscriptions don't work on Android.

### App logic
- [ ] **Rear engine always returns no advice.** The spreadsheet has no Rear rows. Hide the option or add the data.
- [ ] **Google/Apple sign-up skips onboarding and Track Configuration** and goes straight to the tabs. Home shows "Not set".
- [ ] **Car setup details are kept in SharedPreferences as well as Supabase** (circuit name, engine, aero, drive). Home reads them from local storage only, so they're lost on reinstall or a new device. Read them from `track_configurations` instead.
- [ ] **Error snackbars show raw exception text** (setup recommendation, track config, report dialogs).

### Dead code / cleanup
- [ ] `lib/services/gemini_service.dart` imports a missing `lib/config/api_keys.dart` and is unused. Delete it.
- [ ] Legacy adjustment-sets engine: `chassis_adjustment_sets*`, `adjustment_recommendations`, `v_chassis_adjustment_matrix`, `getRankableRecommendations`, and the `demo_admin/` screens. None of these are used anymore.
- [ ] `geometry.dart` is unreachable.
- [ ] `chassis_doctor_notes` table is empty and unused by the app.
- [ ] Large commented-out blocks in `home.dart` and elsewhere; verbose `debugPrint` logging in the services.
- [ ] Supabase anon key and URL are hardcoded in `main.dart` (this is fine for the anon key, but consider `--dart-define`).
- [ ] Auth `site_url` is still `http://localhost:3000`.
- [ ] `README.md` is the Flutter template.

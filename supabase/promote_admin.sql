-- Lantern (Gesher) — seed ONE admin account.
-- An admin needs a real auth user first. Two ways to create it:
--   (a) Supabase Dashboard > Authentication > Users > "Add user", OR
--   (b) sign up through the app once auth exists (Step 3).
-- Then edit the email below and run this in the SQL editor to promote them.
-- The privilege-guard trigger blocks self-elevation, so we disable it for this tx.

begin;

alter table public.profiles disable trigger trg_guard_profile_privileges;

insert into public.profiles (id, role, first_name, last_initial, status, parental_consent_at)
select u.id, 'admin', 'Admin', '', 'active', now()
from auth.users u
where u.email = 'CHANGE_ME@example.com'   -- <-- set your admin email
on conflict (id) do update
  set role = 'admin', status = 'active', parental_consent_at = now();

alter table public.profiles enable trigger trg_guard_profile_privileges;

commit;

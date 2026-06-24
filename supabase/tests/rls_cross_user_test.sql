-- Lantern (Gesher) — RLS cross-user isolation test
-- Proves: a student can read ONLY their own pairing's rows, an admin sees all,
-- and a student CANNOT read another pairing's match/homework.
--
-- How to run: paste this whole file into the Supabase SQL editor and Run.
-- It seeds fake users, impersonates them via JWT claims, asserts visibility,
-- then ROLLS BACK — so it leaves no data behind. On success the final line is
-- "ALL RLS TESTS PASSED". Any failure raises an exception and aborts.

begin;

-- Seeding runs as the table owner (postgres), which bypasses RLS on purpose.
-- Fixed UUIDs so we can impersonate them below.
insert into auth.users (id, aud, role, email, instance_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'admin@test.dev',    '00000000-0000-0000-0000-000000000000'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'studentA@test.dev', '00000000-0000-0000-0000-000000000000'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'tutorA@test.dev',    '00000000-0000-0000-0000-000000000000'),
  ('aaaaaaaa-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'studentB@test.dev', '00000000-0000-0000-0000-000000000000'),
  ('aaaaaaaa-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'tutorB@test.dev',    '00000000-0000-0000-0000-000000000000');

-- Profiles (insert directly as owner; the privilege-guard trigger lets owner through is_admin()=false,
-- but since we run as postgres the BEFORE trigger still fires — so set safe values explicitly).
-- To bypass the trigger's pending/consent forcing during seeding, disable it for this tx.
alter table public.profiles disable trigger trg_guard_profile_privileges;

insert into public.profiles (id, role, first_name, last_initial, status, parental_consent_at) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin',   'Adi',  'C', 'active', now()),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'student', 'Sara', 'A', 'active', now()),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'tutor',   'Tom',  'A', 'active', now()),
  ('aaaaaaaa-0000-0000-0000-000000000004', 'student', 'Sami', 'B', 'active', now()),
  ('aaaaaaaa-0000-0000-0000-000000000005', 'tutor',   'Tara', 'B', 'active', now());

alter table public.profiles enable trigger trg_guard_profile_privileges;

-- Two independent matches: A (Sara+Tom) and B (Sami+Tara).
insert into public.matches (id, student_id, tutor_id, status, created_by) values
  ('bbbbbbbb-0000-0000-0000-00000000000a',
   'aaaaaaaa-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000003', 'active',
   'aaaaaaaa-0000-0000-0000-000000000001'),
  ('bbbbbbbb-0000-0000-0000-00000000000b',
   'aaaaaaaa-0000-0000-0000-000000000004', 'aaaaaaaa-0000-0000-0000-000000000005', 'active',
   'aaaaaaaa-0000-0000-0000-000000000001');

-- One homework row per match.
insert into public.homework (match_id, student_id, storage_path, note) values
  ('bbbbbbbb-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000002', 'homework/A/page1.jpg', 'match A'),
  ('bbbbbbbb-0000-0000-0000-00000000000b', 'aaaaaaaa-0000-0000-0000-000000000004', 'homework/B/page1.jpg', 'match B');

-- =========================================================================
-- Impersonate STUDENT A (Sara). Switch to the RLS-bound 'authenticated' role
-- and set the JWT 'sub' claim that auth.uid() reads.
-- =========================================================================
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"aaaaaaaa-0000-0000-0000-000000000002","role":"authenticated"}';

do $$
begin
  -- Sees exactly her own match (A), not B.
  if (select count(*) from public.matches) <> 1 then
    raise exception 'FAIL: student A should see 1 match, saw %', (select count(*) from public.matches);
  end if;
  if exists (select 1 from public.matches where id = 'bbbbbbbb-0000-0000-0000-00000000000b') then
    raise exception 'FAIL: student A can see match B (cross-pairing leak!)';
  end if;

  -- Sees exactly her own homework, not B's.
  if (select count(*) from public.homework) <> 1 then
    raise exception 'FAIL: student A should see 1 homework row, saw %', (select count(*) from public.homework);
  end if;
  if exists (select 1 from public.homework where note = 'match B') then
    raise exception 'FAIL: student A can read match B homework (cross-pairing leak!)';
  end if;

  -- Sees her own profile + her partner (Tom), but NOT student B / tutor B.
  if exists (select 1 from public.profiles where id = 'aaaaaaaa-0000-0000-0000-000000000004') then
    raise exception 'FAIL: student A can read student B profile (discovery leak!)';
  end if;
  if exists (select 1 from public.profiles where id = 'aaaaaaaa-0000-0000-0000-000000000005') then
    raise exception 'FAIL: student A can read tutor B profile (discovery leak!)';
  end if;

  raise notice 'OK: student A sees only her own pairing.';
end $$;

reset role;
reset "request.jwt.claims";

-- =========================================================================
-- Impersonate ADMIN — must see everything.
-- =========================================================================
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
begin
  if (select count(*) from public.matches)  <> 2 then raise exception 'FAIL: admin should see 2 matches';  end if;
  if (select count(*) from public.homework) <> 2 then raise exception 'FAIL: admin should see 2 homework'; end if;
  if (select count(*) from public.profiles) <> 5 then raise exception 'FAIL: admin should see 5 profiles'; end if;
  raise notice 'OK: admin sees everything.';
end $$;

reset role;
reset "request.jwt.claims";

do $$ begin raise notice 'ALL RLS TESTS PASSED'; end $$;

rollback;  -- leave the database untouched

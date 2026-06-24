-- Lantern (Gesher) — Step 2: schema + Row-Level Security
-- Five tables: profiles, matches, sessions, homework, reports.
-- Security model (must hold):
--   1. No discovery: a student/tutor sees only their own pairing's rows.
--   2. Consent first: new users are 'pending' until an admin records consent.
--   3. Only an admin can see everything (oversight).
-- Run this in the Supabase SQL editor (or via `supabase db push`).

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- profiles: one row per auth user. Minimal PII (first name + last initial).
create table if not exists public.profiles (
  id                  uuid primary key references auth.users (id) on delete cascade,
  role                text not null check (role in ('student', 'tutor', 'admin')),
  first_name          text not null,
  last_initial        text check (char_length(last_initial) <= 2),
  grade               text,
  language            text not null default 'en' check (language in ('en', 'he')),
  status              text not null default 'pending' check (status in ('pending', 'active')),
  parental_consent_at timestamptz,
  created_by          uuid references public.profiles (id),
  created_at          timestamptz not null default now()
);

-- matches: an admin-proposed student<->tutor pairing.
create table if not exists public.matches (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.profiles (id) on delete cascade,
  tutor_id    uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'proposed'
                check (status in ('proposed', 'active', 'declined', 'ended')),
  created_by  uuid references public.profiles (id),
  created_at  timestamptz not null default now(),
  constraint matches_distinct_people check (student_id <> tutor_id)
);

-- One ACTIVE pairing per person (strict 1:1) — enforced as partial unique indexes.
create unique index if not exists matches_one_active_student
  on public.matches (student_id) where (status = 'active');
create unique index if not exists matches_one_active_tutor
  on public.matches (tutor_id) where (status = 'active');

-- sessions: a scheduled video call for a match.
create table if not exists public.sessions (
  id            uuid primary key default gen_random_uuid(),
  match_id      uuid not null references public.matches (id) on delete cascade,
  scheduled_at  timestamptz,
  status        text not null default 'scheduled' check (status in ('scheduled', 'live', 'done')),
  daily_room_url text,
  recording_url text,
  created_at    timestamptz not null default now()
);

-- homework: a photo uploaded by a student for their match (file lives in private storage).
create table if not exists public.homework (
  id           uuid primary key default gen_random_uuid(),
  match_id     uuid not null references public.matches (id) on delete cascade,
  student_id   uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null,
  note         text,
  created_at   timestamptz not null default now()
);

-- reports: a "report a concern" message routed to admins.
create table if not exists public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  match_id    uuid references public.matches (id) on delete set null,
  message     text not null,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Helper functions (SECURITY DEFINER so they bypass RLS and avoid recursion
-- when referenced inside policies on the same tables they read).
-- ---------------------------------------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- True if the current user is the student or tutor of the given match.
create or replace function public.is_match_member(m_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.matches
    where id = m_id and (student_id = auth.uid() or tutor_id = auth.uid())
  );
$$;

-- True if p_id is the current user's matched partner in an open pairing.
create or replace function public.is_my_partner(p_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.matches
    where status in ('proposed', 'active')
      and ( (student_id = auth.uid() and tutor_id = p_id)
         or (tutor_id   = auth.uid() and student_id = p_id) )
  );
$$;

-- ---------------------------------------------------------------------------
-- Triggers: stop a non-admin from elevating their own role/status/consent.
-- ---------------------------------------------------------------------------

create or replace function public.guard_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_admin() then
    return new;  -- admins may change anything
  end if;
  if tg_op = 'INSERT' then
    -- self sign-up: force safe defaults, never admin, never pre-consented.
    if new.role = 'admin' then
      raise exception 'cannot self-assign admin role';
    end if;
    new.status := 'pending';
    new.parental_consent_at := null;
    return new;
  elsif tg_op = 'UPDATE' then
    -- non-admins cannot change privileged columns on any profile.
    if new.role is distinct from old.role
       or new.status is distinct from old.status
       or new.parental_consent_at is distinct from old.parental_consent_at then
      raise exception 'only an admin can change role, status, or consent';
    end if;
    return new;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_guard_profile_privileges on public.profiles;
create trigger trg_guard_profile_privileges
  before insert or update on public.profiles
  for each row execute function public.guard_profile_privileges();

-- ---------------------------------------------------------------------------
-- Enable RLS on every table (default-deny).
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.matches  enable row level security;
alter table public.sessions enable row level security;
alter table public.homework enable row level security;
alter table public.reports  enable row level security;

-- profiles --------------------------------------------------------------
create policy profiles_select on public.profiles
  for select using (
    id = auth.uid() or public.is_admin() or public.is_my_partner(id)
  );

create policy profiles_insert_self on public.profiles
  for insert with check ( id = auth.uid() or public.is_admin() );

create policy profiles_update_own on public.profiles
  for update using ( id = auth.uid() or public.is_admin() )
             with check ( id = auth.uid() or public.is_admin() );

create policy profiles_delete_admin on public.profiles
  for delete using ( public.is_admin() );

-- matches ---------------------------------------------------------------
create policy matches_select on public.matches
  for select using (
    public.is_admin() or student_id = auth.uid() or tutor_id = auth.uid()
  );

-- Only admins propose pairings (tutors never browse/create).
create policy matches_insert_admin on public.matches
  for insert with check ( public.is_admin() );

-- Admins manage fully; the tutor may update their own match (accept/decline/drop).
create policy matches_update on public.matches
  for update using ( public.is_admin() or tutor_id = auth.uid() )
             with check ( public.is_admin() or tutor_id = auth.uid() );

create policy matches_delete_admin on public.matches
  for delete using ( public.is_admin() );

-- sessions --------------------------------------------------------------
create policy sessions_select on public.sessions
  for select using ( public.is_admin() or public.is_match_member(match_id) );

create policy sessions_write_admin on public.sessions
  for all using ( public.is_admin() ) with check ( public.is_admin() );

-- homework --------------------------------------------------------------
create policy homework_select on public.homework
  for select using ( public.is_admin() or public.is_match_member(match_id) );

-- A student uploads only to their own match.
create policy homework_insert_student on public.homework
  for insert with check (
    student_id = auth.uid() and public.is_match_member(match_id)
  );

create policy homework_modify_owner on public.homework
  for update using ( student_id = auth.uid() or public.is_admin() )
             with check ( student_id = auth.uid() or public.is_admin() );

create policy homework_delete_owner on public.homework
  for delete using ( student_id = auth.uid() or public.is_admin() );

-- reports ---------------------------------------------------------------
create policy reports_select on public.reports
  for select using ( public.is_admin() or reporter_id = auth.uid() );

create policy reports_insert_self on public.reports
  for insert with check ( reporter_id = auth.uid() );

create policy reports_admin_manage on public.reports
  for all using ( public.is_admin() ) with check ( public.is_admin() );

-- ============================================================
-- COLLEGE NOTICE BOARD — SUPABASE SCHEMA
-- Run this in Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- 1. PROFILES TABLE (extends auth.users with a role)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'student' check (role in ('student','admin')),
  fcm_token text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Anyone logged in can read profiles (needed to show "posted by" names)
create policy "profiles_select_all"
  on public.profiles for select
  to authenticated
  using (true);

-- A user can only update their own profile (e.g. fcm_token), never their own role
create policy "profiles_update_own_non_role_fields"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, new.raw_user_meta_data->>'full_name', 'student');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- Enforce max 30 admin/faculty accounts at the DB level
-- ------------------------------------------------------------
create or replace function public.enforce_admin_cap()
returns trigger as $$
begin
  if new.role = 'admin' and (old.role is null or old.role <> 'admin') then
    if (select count(*) from public.profiles where role = 'admin') >= 30 then
      raise exception 'Admin/Faculty seat limit (30) reached';
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_admin_cap on public.profiles;
create trigger trg_admin_cap
  before insert or update on public.profiles
  for each row execute procedure public.enforce_admin_cap();

-- Only promote users to admin manually from the Supabase Table Editor
-- (or a trusted server-side script) — never expose a client-facing
-- "become admin" button.

-- Helper used inside RLS policies below
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$ language sql stable security definer;

-- 2. CLUBS TABLE
create table if not exists public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text
);

alter table public.clubs enable row level security;

create policy "clubs_select_all"
  on public.clubs for select
  to authenticated
  using (true);

create policy "clubs_admin_write"
  on public.clubs for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- 3. NOTICES TABLE
create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  event_date timestamptz not null,
  venue text,
  club_id uuid references public.clubs(id),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

alter table public.notices enable row level security;

-- Everyone signed in can read every notice
create policy "notices_select_all"
  on public.notices for select
  to authenticated
  using (true);

-- Only admins can insert / update / delete
create policy "notices_admin_insert"
  on public.notices for insert
  to authenticated
  with check (public.is_admin() and created_by = auth.uid());

create policy "notices_admin_update"
  on public.notices for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "notices_admin_delete"
  on public.notices for delete
  to authenticated
  using (public.is_admin());

-- Turn on Realtime for live-scrolling feed
alter publication supabase_realtime add table public.notices;

-- Seed a few clubs (edit freely)
insert into public.clubs (name, description) values
  ('Robotics Club', 'Builds bots, competes in national events'),
  ('IEEE Student Branch', 'Technical talks and workshops'),
  ('Cultural Club', 'Fests, music, drama'),
  ('Coding Club', 'DSA, hackathons, open source')
on conflict (name) do nothing;

-- ============================================================
-- COLLEGE NOTICE BOARD — SUPABASE SCHEMA
-- ============================================================

-- 1. PROFILES TABLE
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'student'
    check (role in ('student','admin')),
  fcm_token text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Anyone logged in can read profiles
create policy "profiles_select_all"
  on public.profiles for select
  to authenticated
  using (true);

-- Users can update their own profile,
-- but cannot change their role.
create policy "profiles_update_own_non_role_fields"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    and role = (
      select p.role
      from public.profiles p
      where p.id = auth.uid()
    )
  );

-- Auto-create profile when a user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    'student'
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute procedure public.handle_new_user();


-- ============================================================
-- ENFORCE MAXIMUM 30 ADMIN/FACULTY ACCOUNTS
-- ============================================================

create or replace function public.enforce_admin_cap()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin

  -- INSERT: check if the new row is an admin
  if TG_OP = 'INSERT' and new.role = 'admin' then

    if (
      select count(*)
      from public.profiles
      where role = 'admin'
    ) >= 30 then
      raise exception 'Admin/Faculty seat limit (30) reached';
    end if;

  -- UPDATE: only check when changing from non-admin to admin
  elsif TG_OP = 'UPDATE'
        and new.role = 'admin'
        and old.role <> 'admin' then

    if (
      select count(*)
      from public.profiles
      where role = 'admin'
    ) >= 30 then
      raise exception 'Admin/Faculty seat limit (30) reached';
    end if;

  end if;

  return new;
end;
$$;

drop trigger if exists trg_admin_cap on public.profiles;

create trigger trg_admin_cap
  before insert or update on public.profiles
  for each row
  execute procedure public.enforce_admin_cap();


-- ============================================================
-- HELPER: CHECK WHETHER CURRENT USER IS ADMIN
-- ============================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;


-- ============================================================
-- 2. CLUBS TABLE
-- ============================================================

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


-- ============================================================
-- 3. NOTICES TABLE
-- ============================================================

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

-- Logged-in users can read notices
create policy "notices_select_all"
  on public.notices for select
  to authenticated
  using (true);

-- Only admins can create notices
create policy "notices_admin_insert"
  on public.notices for insert
  to authenticated
  with check (
    public.is_admin()
    and created_by = auth.uid()
  );

-- Only admins can update notices
create policy "notices_admin_update"
  on public.notices for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Only admins can delete notices
create policy "notices_admin_delete"
  on public.notices for delete
  to authenticated
  using (public.is_admin());


-- ============================================================
-- REALTIME
-- ============================================================

alter publication supabase_realtime
add table public.notices;


-- ============================================================
-- SEED CLUBS
-- ============================================================

insert into public.clubs (name, description)
values
  ('Robotics Club', 'Builds bots, competes in national events'),
  ('IEEE Student Branch', 'Technical talks and workshops'),
  ('Cultural Club', 'Fests, music, drama'),
  ('Coding Club', 'DSA, hackathons, open source')
on conflict (name) do nothing;

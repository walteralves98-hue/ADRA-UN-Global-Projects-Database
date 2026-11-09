-- Run in Supabase SQL Editor. Do not place service-role keys in browser code.
create extension if not exists pgcrypto;
create table if not exists public.staff_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'viewer' check(role in ('viewer','editor','admin')),
  created_at timestamptz not null default now()
);
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  title text not null check(length(trim(title))>0),
  country text not null,
  region text,
  office text not null,
  agency text not null,
  sector text,
  year integer not null check(year between 2015 and 2100),
  status text not null default 'Unknown',
  relationship text,
  description text,
  source_url text not null check(source_url ~* '^https?://'),
  source_title text,
  verification text not null default 'Needs review' check(verification in ('Needs review','Source-backed','Verified')),
  budget_usd numeric(18,2) check(budget_usd >= 0),
  beneficiaries bigint check(beneficiaries >= 0),
  published boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists projects_year_idx on public.projects(year desc);
create index if not exists projects_agency_idx on public.projects(agency);
create index if not exists projects_country_idx on public.projects(country);
create index if not exists projects_published_idx on public.projects(published);
create or replace function public.is_editor() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.staff_profiles where user_id=(select auth.uid()) and role in ('editor','admin'));
$$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.staff_profiles where user_id=(select auth.uid()) and role='admin');
$$;
create or replace function public.set_project_audit() returns trigger language plpgsql security definer set search_path='' as $$
begin
 new.updated_at=now();new.updated_by=auth.uid();
 if tg_op='INSERT' then new.created_by=auth.uid();end if;
 return new;
end;$$;
drop trigger if exists projects_audit on public.projects;
create trigger projects_audit before insert or update on public.projects for each row execute function public.set_project_audit();
alter table public.staff_profiles enable row level security;
alter table public.projects enable row level security;
drop policy if exists "staff read own profile" on public.staff_profiles;
create policy "staff read own profile" on public.staff_profiles for select to authenticated using (user_id=(select auth.uid()) or public.is_admin());
drop policy if exists "admins manage profiles" on public.staff_profiles;
create policy "admins manage profiles" on public.staff_profiles for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "public read published projects" on public.projects;
create policy "public read published projects" on public.projects for select to anon,authenticated using(published=true or public.is_editor());
drop policy if exists "editors insert projects" on public.projects;
create policy "editors insert projects" on public.projects for insert to authenticated with check(public.is_editor() and created_by=(select auth.uid()));
drop policy if exists "editors update projects" on public.projects;
create policy "editors update projects" on public.projects for update to authenticated using(public.is_editor()) with check(public.is_editor());
drop policy if exists "editors delete projects" on public.projects;
create policy "editors delete projects" on public.projects for delete to authenticated using(public.is_editor());
-- Prevent self-assignment of roles by denying public profile INSERT; bootstrap first admin via SQL editor.
-- First create a user via Supabase Authentication > Users, then run:
-- insert into public.staff_profiles(user_id,role) values ('YOUR-AUTH-USER-UUID','admin') on conflict(user_id) do update set role='admin';
-- To add editors after creating auth users:
-- insert into public.staff_profiles(user_id,role) values ('EDITOR-USER-UUID','editor') on conflict(user_id) do update set role='editor';

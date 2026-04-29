-- KOPPA Package Registry — Supabase Schema
-- Run this in Supabase SQL Editor (Project → SQL Editor → New Query)

-- ── Extensions ───────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";

-- ── Packages ─────────────────────────────────────────────────────────────────
create table public.packages (
  id             uuid default gen_random_uuid() primary key,
  name           text unique not null
                   check (name ~ '^[a-z0-9][a-z0-9\-]{0,63}$'),
  description    text not null default '',
  author_id      uuid references auth.users(id) on delete set null,
  author_name    text not null default '',
  latest_version text not null default '1.0.0',
  tags           text[] default '{}',
  license        text default 'MIT',
  repo_url       text default '',
  readme         text default '',
  downloads      bigint default 0,
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);

-- ── Package versions ──────────────────────────────────────────────────────────
create table public.package_versions (
  id           uuid default gen_random_uuid() primary key,
  package_id   uuid references public.packages(id) on delete cascade not null,
  version      text not null check (version ~ '^\d+\.\d+\.\d+'),
  description  text default '',
  changelog    text default '',
  entry_file   text default 'main.kop',
  published_at timestamptz default now(),
  constraint uq_pkg_version unique (package_id, version)
);

-- ── Download events ───────────────────────────────────────────────────────────
create table public.download_events (
  id            uuid default gen_random_uuid() primary key,
  package_id    uuid references public.packages(id) on delete cascade,
  version       text,
  downloaded_at timestamptz default now()
);

-- ── API tokens (for CLI) ──────────────────────────────────────────────────────
create table public.api_tokens (
  id           uuid default gen_random_uuid() primary key,
  user_id      uuid references auth.users(id) on delete cascade not null,
  token        text unique not null
                 default 'koppa_' || encode(gen_random_bytes(24), 'hex'),
  name         text default 'CLI Token',
  created_at   timestamptz default now(),
  last_used_at timestamptz
);

-- ── User profiles (public metadata) ──────────────────────────────────────────
create table public.profiles (
  id         uuid references auth.users(id) on delete cascade primary key,
  username   text unique,
  avatar_url text,
  bio        text,
  website    text,
  created_at timestamptz default now()
);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'user_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'avatar_url', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Update downloads counter via trigger
create or replace function public.increment_downloads()
returns trigger language plpgsql security definer as $$
begin
  update public.packages
  set downloads = downloads + 1,
      updated_at = now()
  where id = new.package_id;
  return new;
end;
$$;

create trigger on_download_event
  after insert on public.download_events
  for each row execute procedure public.increment_downloads();

-- ── RLS Policies ─────────────────────────────────────────────────────────────

alter table public.packages         enable row level security;
alter table public.package_versions enable row level security;
alter table public.download_events  enable row level security;
alter table public.api_tokens       enable row level security;
alter table public.profiles         enable row level security;

-- packages: anyone reads, only author writes
create policy "packages_select"  on public.packages for select using (true);
create policy "packages_insert"  on public.packages for insert
  with check (auth.uid() = author_id);
create policy "packages_update"  on public.packages for update
  using (auth.uid() = author_id);
create policy "packages_delete"  on public.packages for delete
  using (auth.uid() = author_id);

-- package_versions: anyone reads, package author writes
create policy "versions_select"  on public.package_versions for select using (true);
create policy "versions_insert"  on public.package_versions for insert
  with check (
    exists (
      select 1 from public.packages p
      where p.id = package_id and p.author_id = auth.uid()
    )
  );

-- download_events: anyone inserts (anonymous downloads ok), no reads
create policy "dl_insert" on public.download_events for insert
  with check (true);

-- api_tokens: only owner
create policy "tokens_select" on public.api_tokens for select
  using (auth.uid() = user_id);
create policy "tokens_insert" on public.api_tokens for insert
  with check (auth.uid() = user_id);
create policy "tokens_delete" on public.api_tokens for delete
  using (auth.uid() = user_id);

-- profiles: anyone reads, only owner writes
create policy "profiles_select" on public.profiles for select using (true);
create policy "profiles_update" on public.profiles for update
  using (auth.uid() = id);

-- ── Indexes ───────────────────────────────────────────────────────────────────
create index idx_packages_author  on public.packages (author_id);
create index idx_packages_tags    on public.packages using gin (tags);
create index idx_versions_pkg     on public.package_versions (package_id);
create index idx_dl_pkg           on public.download_events (package_id);
create index idx_tokens_user      on public.api_tokens (user_id);

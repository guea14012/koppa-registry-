-- KOPPA Registry — additions: stars, security_score, cve_ids, platforms
-- Safe to re-run: uses IF NOT EXISTS + DROP IF EXISTS

-- Add columns to packages
alter table public.packages
  add column if not exists security_score  int     default null,
  add column if not exists security_grade  text    default null,
  add column if not exists security_issues jsonb   default '[]',
  add column if not exists cve_ids         text[]  default '{}',
  add column if not exists platforms       text[]  default '{"any"}',
  add column if not exists stars           bigint  default 0,
  add column if not exists weekly_dl       bigint  default 0;

-- Stars table
create table if not exists public.package_stars (
  user_id    uuid references auth.users(id)    on delete cascade,
  package_id uuid references public.packages(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, package_id)
);
alter table public.package_stars enable row level security;

drop policy if exists "stars_select" on public.package_stars;
drop policy if exists "stars_insert" on public.package_stars;
drop policy if exists "stars_delete" on public.package_stars;
create policy "stars_select" on public.package_stars for select using (true);
create policy "stars_insert" on public.package_stars for insert with check (auth.uid() = user_id);
create policy "stars_delete" on public.package_stars for delete using (auth.uid() = user_id);

-- Auto-update star count
create or replace function public.update_star_count()
returns trigger language plpgsql security definer as $$
begin
  if TG_OP = 'INSERT' then
    update public.packages set stars = stars + 1 where id = new.package_id;
  elsif TG_OP = 'DELETE' then
    update public.packages set stars = greatest(0, stars - 1) where id = old.package_id;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists on_star_change on public.package_stars;
create trigger on_star_change
  after insert or delete on public.package_stars
  for each row execute procedure public.update_star_count();

-- Download daily cache
create table if not exists public.download_daily (
  package_id uuid references public.packages(id) on delete cascade,
  day        date not null,
  count      int  default 0,
  primary key (package_id, day)
);
alter table public.download_daily enable row level security;

drop policy if exists "dl_daily_select"  on public.download_daily;
drop policy if exists "dl_daily_insert"  on public.download_daily;
drop policy if exists "dl_daily_upsert"  on public.download_daily;
create policy "dl_daily_select" on public.download_daily for select using (true);
create policy "dl_daily_insert" on public.download_daily for insert with check (true);
create policy "dl_daily_upsert" on public.download_daily for update using (true);

-- Full-text search index
create index if not exists idx_packages_fts on public.packages
  using gin (to_tsvector('english', name || ' ' || description));

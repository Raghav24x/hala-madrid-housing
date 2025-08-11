-- Enable required extensions
create extension if not exists pgcrypto;
create extension if not exists http with schema public; -- optional

-- Users (managed by Supabase auth; mirror for FK convenience)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  created_at timestamptz default now()
);

-- Neighborhoods
create table if not exists public.neighborhoods (
  id bigserial primary key,
  name text unique not null,
  safety_index numeric check (safety_index between 0 and 1),
  metro_proximity boolean default false,
  walkability_score numeric check (walkability_score between 0 and 1),
  geom geometry, -- optional if using PostGIS; otherwise drop
  created_at timestamptz default now()
);

-- Properties
create table if not exists public.properties (
  id bigserial primary key,
  title text not null,
  price numeric not null check (price >= 0),
  bedrooms int,
  bathrooms int,
  size_m2 numeric,
  address text,
  neighborhood_id bigint references public.neighborhoods(id) on delete set null,
  owner_id uuid references auth.users(id) on delete set null,
  listed_at timestamptz default now(),
  images text[] default '{}'
);

-- User preferences
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  max_budget numeric,
  preferred_districts text[] default '{}',
  must_have_metro boolean default false,
  min_walkability numeric default 0,
  updated_at timestamptz default now()
);

-- Helpful indexes
create index if not exists idx_properties_price on public.properties(price);
create index if not exists idx_properties_neighborhood on public.properties(neighborhood_id);
create index if not exists idx_neighborhoods_name on public.neighborhoods(name);
create index if not exists idx_user_prefs_user on public.user_preferences(user_id);


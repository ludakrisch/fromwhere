-- Artists
create table artists (
  id serial primary key,
  name text not null,
  is_group boolean default false,
  group_name text,
  created_at timestamp with time zone default now()
);
-- Artist Locations
create table artist_locations (
  id serial primary key,
  artist_id integer references artists(id) on delete cascade,
  country text,
  state text,
  city text,
  borough text,
  neighborhood text,
  project text,
  chronology integer default 0,
  created_at timestamp with time zone default now()
);git add supabase/schema.sql
git commit -m "Add Supabase schema for artists and locations"
git push
git status


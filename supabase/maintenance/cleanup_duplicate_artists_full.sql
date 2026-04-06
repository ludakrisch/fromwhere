-- =============================================
-- Cleanup Script: Artists ohne Locations aufräumen
-- =============================================

-- 1️⃣  Finde doppelte Artist-Namen
with duplicates as (
  select name
  from artists
  group by name
  having count(*) > 1
),

-- 2️⃣  Bestimme doppelte Artists, die keine Locations haben
empty_duplicates as (
  select a.id, a.name
  from artists a
  left join artist_locations al on a.id = al.artist_id
  where al.artist_id is null
    and a.name in (select name from duplicates)
),

-- 3️⃣  Lösche genau diese „leeren“ Duplikate
deleted_rows as (
  delete from artists
  where id in (select id from empty_duplicates)
  returning id, name
)

-- 4️⃣  Ergebnisberichte --------------------------------------

-- 4a. Bericht: Gelöschte Artists
select '🗑️  Gelöschte doppelte Artists:' as info;
select * from deleted_rows;

-- 4b. Bericht: Noch vorhandene doppelte Artists
select '⚠️  Verbleibende doppelte Artists:' as info;
select name, count(*) as remaining
from artists
group by name
having count(*) > 1;

-- 4c. Bericht: Alle Artists ohne zugeordnete Locations
--     (aber eindeutige Namen)
select '📋  Artists ohne Locations (zur Prüfung):' as info;

-- 4d. Erstelle temporäre Tabelle zur Nachpflege
drop table if exists tmp_artists_without_locations;

create temporary table tmp_artists_without_locations as
select a.id, a.name, a.is_group, a.created_at
from artists a
left join artist_locations al on a.id = al.artist_id
where al.artist_id is null
  and a.name not in (select name from duplicates);

select * from tmp_artists_without_locations order by name;

-- =============================================
-- Ende: Die temporäre Tabelle kann nun
--       manuell exportiert oder überprüft werden.
-- =============================================

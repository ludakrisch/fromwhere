-- =============================================
-- Merge-Skript: Artists mit chronology = 0 zusammenführen
-- =============================================

-- 1️⃣  Gruppen vorbereiten —
--     Finde Artists mit identischem Namen und ausschließlich chronology = 0
with candidate_groups as (
  select a.name,
         min(a.id) as main_artist_id,                -- Hauptartist (kleinste ID)
         array_agg(distinct a.id) as all_artist_ids
  from artists a
  join artist_locations al on al.artist_id = a.id
  group by a.name
  having
    count(distinct a.id) > 1                        -- mehrfacher Eintrag (Duplikate)
    and bool_and(al.chronology = 0)                 -- alle Locations gleichzeitig (chronology = 0)
),

-- 2️⃣  Betroffene Artists und ihre Locations anzeigen (zur Kontrolle)
merged_preview as (
  select cg.name, cg.main_artist_id, a.id as duplicate_id, al.id as location_id, al.city, al.country, al.state, al.borough, al.neighborhood, al.project
  from candidate_groups cg
  join artists a on a.name = cg.name
  join artist_locations al on al.artist_id = a.id
  order by cg.name, a.id, al.id
)

select '📋  Kandidaten zur Zusammenführung (chronology=0):' as info;
select * from merged_preview;

-- 3️⃣  Merge starten —
--     Locations aller Duplikate auf den Hauptartist umziehen
update artist_locations al
set artist_id = cg.main_artist_id
from candidate_groups cg
where al.artist_id = any (cg.all_artist_ids)
  and al.artist_id <> cg.main_artist_id;

-- 4️⃣  Nun alle leeren Duplikate (ohne Locations) löschen
delete from artists a
using candidate_groups cg
where a.name = cg.name
  and a.id <> cg.main_artist_id
  and not exists (
    select 1 from artist_locations al where al.artist_id = a.id
  );

-- 5️⃣  Abschlussberichte
select '✅  Zusammenführung abgeschlossen. Verbleibende doppelte Namen (falls noch vorhanden):' as info;
select name, count(*) as remaining
from artists
group by name
having count(*) > 1
order by name;

select '📋  Kontrolle: Beispielhafte Artists mit mehreren gleichzeitigen Locations:' as info;
select a.id, a.name, count(al.id) as location_count
from artists a
join artist_locations al on al.artist_id = a.id
where al.chronology = 0
group by a.id, a.name
having count(al.id) > 1
order by a.name;

-- 03_purge_receptions.sql
-- Purpose: Safely remove legacy receptions and restore CDR status (CDR-aware purge).
-- Run on: PROD only, after backup is validated.
-- IMPORTANT: Rows with source = 'SYSTEM' in stocks_journaliers must NEVER be deleted.

begin;

set local lock_timeout = '10s';
set local statement_timeout = '5min';

-- Step 1: List receptions to purge (for audit)
create temporary table tmp_receptions_to_purge as
select id as reception_id, cours_de_route_id
from public.receptions;

select count(*) as receptions_to_purge from tmp_receptions_to_purge;

-- Step 2: Delete logs linked to receptions
delete from public.log_actions
where module = 'receptions'
  and details->>'reception_id' in (
    select reception_id::text from tmp_receptions_to_purge
  );

-- Step 3: Clean derived stock tables (RECEPTION source only; do NOT delete SYSTEM baseline rows)
delete from public.stocks_journaliers
where source = 'RECEPTION'
  and proprietaire_type = 'MONALUXE'
  and produit_id = '22222222-2222-2222-2222-222222222222'
  and citerne_id in (
    '2ed755b4-0306-4c7d-a6cd-1cc7de618625',
    '91d2078b-8e19-43c2-bf33-322a42cd4e94'
  );

-- Step 3b: Clean stocks_snapshot for affected citernes (if table exists and is used)
delete from public.stocks_snapshot
where citerne_id in (
    '2ed755b4-0306-4c7d-a6cd-1cc7de618625',
    '91d2078b-8e19-43c2-bf33-322a42cd4e94'
  )
  and proprietaire_type = 'MONALUXE'
  and produit_id = '22222222-2222-2222-2222-222222222222';

-- Step 4: Delete receptions
delete from public.receptions
where id in (select reception_id from tmp_receptions_to_purge);

-- Step 5: Restore CDR status (only CDRs that were linked to purged receptions)
update public.cours_de_route
set statut = 'ARRIVE'
where id in (select cours_de_route_id from tmp_receptions_to_purge);

-- Verification
select count(*) as receptions_after from public.receptions;
select count(*) as sj_reception_after from public.stocks_journaliers where source = 'RECEPTION';
select id, statut from public.cours_de_route
where id in (select cours_de_route_id from tmp_receptions_to_purge)
order by id;

commit;

-- Expected after purge: receptions = 0, sj RECEPTION = 0, 8 CDR with statut = ARRIVE.
-- Baseline SYSTEM rows in stocks_journaliers are preserved.

-- 06_replay_receptions_template.sql
-- Purpose: Template for replaying the 8 receptions after migration.
-- volume_15c is computed automatically by the reception trigger (astm.compute_v15_from_lookup_grid).
-- Replace placeholders with actual values from pre-migration export or business data.

-- Required columns for INSERT (trigger will set volume_15c, densite_a_15_kgm3, densite_a_15_g_cm3):
-- citerne_id, produit_id, cours_de_route_id, index_avant, index_apres, temperature_ambiante_c,
-- densite_observee_kgm3 (or densite_a_15_kgm3 as legacy input), depot_id, proprietaire_type, etc.

-- Example single reception (repeat for each of the 8 receptions, one INSERT per row or batch):

/*
INSERT INTO public.receptions (
  citerne_id,
  produit_id,
  cours_de_route_id,
  index_avant,
  index_apres,
  temperature_ambiante_c,
  densite_observee_kgm3,
  depot_id,
  proprietaire_type,
  created_by
) VALUES (
  '2ed755b4-0306-4c7d-a6cd-1cc7de618625',   -- citerne_id
  '22222222-2222-2222-2222-222222222222',   -- produit_id (GASOIL)
  '<cours_de_route_id>',                     -- cours_de_route_id (one of the 8 CDR in ARRIVE)
  0,                                         -- index_avant
  10000,                                     -- index_apres (volume_ambiant = index_apres - index_avant)
  19,                                        -- temperature_ambiante_c
  837,                                       -- densite_observee_kgm3 (observed density, 820-860)
  '<depot_id>',                              -- depot_id
  'MONALUXE',
  '<user_id>'                                -- created_by
);
-- volume_15c is set by trigger from astm.compute_v15_from_lookup_grid(...).
*/

-- Batch template: run 8 inserts (one per CDR). Ensure each cours_de_route_id is in ARRIVE and used only once.
-- After replay, run 07_post_migration_checks.sql to verify receptions and stock.

SELECT 'Replace placeholders in this file with real ids and values, then run the INSERTs.' AS instruction;

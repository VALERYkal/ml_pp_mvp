# Sorties — MVP (Supabase)

## Objectifs
- Pas de brouillon : INSERT = `validee`.
- Calcul auto des volumes (ambiant via Δ index, @15°C fallback sur ambiant en MVP).
- Débit des stocks journaliers via `stock_upsert_journalier`.
- Cohérence produit↔citerne vérifiée en BEFORE.
- Logs techniques dans `log_actions`.
- RLS simples et robustes.

## Tables & fonctions utilisées
- `public.sorties_produit`
- `public.stocks_journaliers` (clé unique: (citerne_id, produit_id, date_jour))
- `public.stock_upsert_journalier(citerne uuid, produit uuid, date date, ambiant double, v15 double)` — additionne les volumes (on passe négatifs pour débiter)
- `public.log_actions` (RLS INSERT authenticated en place)

## Triggers Sorties
- BEFORE INSERT: `sortie_before_ins_trg` (existant) — normalisation index, calcul `volume_ambiant`, `date_sortie`.
- BEFORE INSERT/UPDATE: `trg_sorties_check_produit_citerne` → `sorties_check_produit_citerne()` assure `citerne.produit_id == sorties.produit_id`.
- AFTER INSERT: `trg_sorties_apply_effects` → `sorties_apply_effects()` débite `stocks_journaliers` (ambiant & @15°C en valeurs négatives).
- BEFORE UPDATE: `sortie_before_upd_trg` (modifié) — immuable hors brouillon, sauf `admin`.

## Index
- `idx_sorties_statut (statut)`
- `idx_sorties_created_at (created_at DESC)`
- `idx_sorties_date_sortie (date_sortie)`
- `idx_sorties_citerne (citerne_id)`
- `idx_sorties_produit (produit_id)`

## RLS
- `ALTER TABLE public.sorties_produit ENABLE ROW LEVEL SECURITY;`
- `read_sorties_authenticated` (SELECT authenticated)
- `insert_sorties_authenticated` (WITH CHECK `role_in(user_role(), ['operateur','gerant','directeur','admin'])`)
- `update_sorties_admin` (USING/WITH CHECK admin)
- `delete_sorties_admin` (USING admin)

## Logs
- `sorties_log_created()` en AFTER INSERT → insère un JSON `details` (sortie_id, citerne_id, produit_id, volumes, date_sortie, propriétaire, statut, created_by).

## Notes
- Réceptions : flux miroir (crédit) déjà en place avec triggers équivalents.
- Les volumes à 15°C peuvent être affinés plus tard (intégration table pétro/ASTM).

## Tests rapides (SQL)

```sql
-- 1) Paire cohérente citerne/produit
SELECT c.id AS citerne_id, c.produit_id, p.code, p.nom
FROM public.citernes c JOIN public.produits p ON p.id=c.produit_id
LIMIT 3;

-- 2) Insert sortie minimale (remplacez les UUID par une paire cohérente)
INSERT INTO public.sorties_produit (citerne_id, produit_id, index_avant, index_apres, proprietaire_type)
VALUES ('<citerne_uuid>', '<produit_uuid>', 1, 50001, 'MONALUXE');

-- 3) Vérifier débit de stock (pour la date du jour)
SELECT * FROM public.stocks_journaliers
WHERE citerne_id='<citerne_uuid>' AND produit_id='<produit_uuid>' AND date_jour=CURRENT_DATE;

-- 4) Log
SELECT * FROM public.log_actions WHERE module='sorties'
ORDER BY created_at DESC LIMIT 3;
```
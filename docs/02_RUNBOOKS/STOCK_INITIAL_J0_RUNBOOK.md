# RUNBOOK — Stock initial J0 (PROD)

## Objectif
Aligner l'application avec le stock physique de départ (J0), sans écrire directement dans `stocks_journaliers` (protégé), tout en rendant le stock visible :
- dans l’UI (stock actuel)
- dans les rapports `stocks_journaliers` (baseline journalière)

## Contexte technique
- `stocks_journaliers` bloque les écritures directes (trigger `stocks_journaliers_block_writes`).
- Le stock “actuel” est porté par `stocks_snapshot` (via `v_stock_actuel`).
- `stocks_journaliers` est reconstruit via `rebuild_stocks_journaliers()` depuis `v_mouvements_stock`.

## Procédure validée (PROD)
### A) Déclarer le stock initial dans `stocks_snapshot`
Utiliser `stock_snapshot_apply_delta(...)` (SECURITY DEFINER), puis logguer l’action.

Exemple validé :
- Depot: `11111111-1111-1111-1111-111111111111`
- Citerne: TANK4 `91d2078b-8e19-43c2-bf33-322a42cd4e94`
- Produit: Gasoil/AGO `22222222-2222-2222-2222-222222222222`
- Propriétaire: `MONALUXE`
- J0: 2026-02-05
- Stock: 79 737 (ambiant) / 79 202.7621 (15°C)

### B) Permettre une baseline journalière
`rebuild_stocks_journaliers` ne reconstruit que depuis `v_mouvements_stock`.
Pour inclure un stock initial, on a patché `v_mouvements_stock` pour ajouter une baseline issue de `stocks_snapshot` à `last_movement_at::date`, à condition qu'il n'existe aucun mouvement validé avant cette date (anti-double-comptage).

### C) Rebuild J0
Rebuild sur la fenêtre J0 :
- `rebuild_stocks_journaliers(depot_id, '2026-02-05', '2026-02-05')`

## Vérifications
- `v_stock_actuel` retourne 1 ligne avec stock attendu
- `stocks_snapshot` contient la ligne
- `stocks_journaliers` contient la ligne J0 `source=SYSTEM`
- `v_mouvements_stock` retourne 1 seule ligne baseline à J0 (n_rows=1)

## Audit
Action log :
- `log_actions.action = 'STOCK_INITIAL_DECLARE'`
- `details.actor = 'psql-admin'` (car `auth.uid()` null en psql)

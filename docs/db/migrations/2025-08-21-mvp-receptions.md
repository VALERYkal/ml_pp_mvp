# 2025-08-21 — MVP Réceptions (sans brouillon)

## Opérations appliquées
- `receptions.statut`: default `'validee'`, CHECK ∈ {'validee','rejetee'} (suppression 'brouillon'), data migration (`UPDATE ... SET statut='validee' WHERE statut='brouillon'`)
- Garde-fous: indices cohérents, PARTENAIRE ⇒ partenaire_id
- Trigger `receptions_check_produit_citerne` (compatibilité produit↔citerne)
- Contrainte `stocks_j_unique` & fonction `stock_upsert_journalier(...)`
- Trigger `receptions_apply_effects` (AFTER INSERT, SECURITY DEFINER)
- RLS réceptions: set minimal (read/insert/admin-update/admin-delete)
- CDR: statuts MAJUSCULES et policy `cours_de_route_update_status` renforcée (DECHARGE uniquement si réception validée existe)

## Indices utiles
- `idx_receptions_statut`, `idx_receptions_citerne`, `idx_receptions_produit`, `idx_receptions_date_reception`
- `idx_cdr_statut`
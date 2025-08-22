# Réceptions — MVP (sans brouillon)

## Principe
En MVP, la création d’une réception l’enregistre **directement validée**. Les effets métiers sont appliqués **à l’INSERT** via triggers.

## Schéma clé
Table `public.receptions` :
- `statut`: **default `'validee'`**, CHECK ∈ {`validee`, `rejetee`} (plus de `brouillon`)
- garde-fous :
  - indices ≥ 0 et `index_apres > index_avant`
  - si `proprietaire_type='PARTENAIRE'` ⇒ `partenaire_id` requis
  - **produit=citerne** via trigger `receptions_check_produit_citerne`

## Effets automatiques à l’INSERT (statut='validee')
Trigger `trg_receptions_apply_effects` appelle `receptions_apply_effects()` :
1. calcule `volume_ambiant` de secours si besoin,
2. **crédite** `stocks_journaliers` via `stock_upsert_journalier(...)`,
3. si `cours_de_route_id` présent ⇒ **CDR** → `DECHARGE`,
4. log `RECEPTION_VALIDEE_AUTO`.

## RLS (état final)
- SELECT: `read_receptions_authenticated` → `USING true`
- INSERT: `insert_receptions_authenticated` → `WITH CHECK role ∈ {admin,directeur,gerant,operateur}`
- UPDATE: `update_receptions_admin` → réservé admin (corrections)
- DELETE: `delete_receptions_admin` → réservé admin

## Audit SQL
Lister les policies:
```sql
SELECT pol.polname, pol.polcmd, pol.polroles::regrole[] AS roles,
       pg_get_expr(pol.polqual, pol.polrelid) AS using_expression,
       pg_get_expr(pol.polwithcheck, pol.polrelid) AS with_check_expression
FROM pg_policy pol
JOIN pg_class c ON c.oid = pol.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='public' AND c.relname='receptions'
ORDER BY pol.polname;
```

## Logique amont/aval
- En cas de création depuis un CDR ARRIVE, l’INSERT valide la réception et décharge le CDR automatiquement.
- Les stocks journaliers sont consolidés par (citerne, produit, date).
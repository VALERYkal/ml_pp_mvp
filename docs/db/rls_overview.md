# RLS — Vue d’ensemble (public.*)

## Réceptions
- read_receptions_authenticated (r, authenticated, `USING true`)
- insert_receptions_authenticated (a, authenticated, `WITH CHECK role ∈ {admin,directeur,gerant,operateur}`)
- update_receptions_admin (w, authenticated, `USING/with_check role='admin'`)
- delete_receptions_admin (d, authenticated, `USING role='admin'`)

## Référentiels
- produits: read_produits_authenticated (r, authenticated, `USING true`)
- fournisseurs: read_fournisseurs_authenticated (r, authenticated, `USING true`)
- depots: read_depots_authenticated (r, authenticated, `USING true`)
- clients: read_clients_authenticated (r, authenticated, `USING true`)
- partenaires: read_partenaires_authenticated (r, authenticated, `USING true`)
- citernes:
  - read_citernes_authenticated (r, authenticated, `USING true`)
  - citernes_update (w, authenticated, `USING/with_check role ∈ {'admin','directeur'}`)

## Requêtes de vérification

-- Réceptions (policies)
```sql
SELECT polname, polcmd, polroles::regrole[], 
       pg_get_expr(polqual, polrelid) AS using_expr,
       pg_get_expr(polwithcheck, polrelid) AS with_check
FROM pg_policy pol
JOIN pg_class c ON c.oid=pol.polrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname='receptions'
ORDER BY polname;
```

-- Cours de route: constraint statut + aperçu data
```sql
SELECT column_default FROM information_schema.columns 
WHERE table_schema='public' AND table_name='receptions' AND column_name='statut';
SELECT statut, COUNT(*) FROM public.receptions GROUP BY statut;
SELECT statut, COUNT(*) FROM public.cours_de_route GROUP BY statut;
```

-- Stock journaliers: contrainte + dernier état
```sql
SELECT conname FROM pg_constraint WHERE conname='stocks_j_unique';
SELECT * FROM public.stocks_journaliers ORDER BY date_jour DESC, created_at DESC NULLS LAST LIMIT 5;
```
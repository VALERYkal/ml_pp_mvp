# Runbook — RLS Hardening (0 public policies)

**Document** : Procédure et checklist pour l’audit et le durcissement RLS (Supabase Postgres).  
**Version** : 1.0  
**Date** : 2026-02-21  
**Contexte** : ML_PP MVP en PROD — clé ANON exposée dans le front Flutter Web.

---

## Why this matters

- **ANON key in front** : L’application Flutter Web embarque la clé **anon** Supabase. Toute requête REST (y compris sans JWT utilisateur) utilise cette clé.
- **Policy `roles = {public}`** : Une policy RLS avec `TO public` (ou équivalent) s’applique à **tous** les rôles, y compris les connexions **non authentifiées** (header `Authorization: Bearer <ANON_KEY>` sans session).
- **Risque** : Une policy du type `USING (true)` ou `WITH CHECK (true)` sur `public` → **exposition immédiate** des données de la table via l’API REST (liste, détail). Aucune authentification requise.
- **Objectif** : **0 policy `{public}`** en PROD et STAGING. Toutes les policies ciblent `authenticated` (ou rôles explicites) avec une condition métier/technique.

---

## Protocole safe (une action à la fois)

1. **Identifier** les policies concernées (requête `pg_policies`).
2. **Tester** l’exposition : `curl` avec ANON key sur la table (sans JWT utilisateur).
3. **Corriger** : DROP policy dangereuse ou migrer `public` → `authenticated` en conservant la condition.
4. **Re-tester** : `curl` ANON doit retourner `[]` (ou 403) pour les tables sensibles.
5. **Documenter** : déploiement log, runbook, CHANGELOG.

**Environnement** : Toujours **STAGING d’abord** (correction + validation), puis **PROD** (audit + fix) après backup.

---

## Commandes / requêtes (preuves)

### Test exposition ANON (sans clés réelles dans la doc)

```bash
# Remplacer <SUPABASE_URL> et <ANON_KEY> par les valeurs de l’env (jamais commiter les clés).
curl -i -H "apikey: <ANON_KEY>" \
     -H "Authorization: Bearer <ANON_KEY>" \
     -H "Content-Type: application/json" \
     "<SUPABASE_URL>/rest/v1/<TABLE>?select=id&limit=1"
```

- **HTTP 200 + body avec `data`** → fuite (policy `public` permissive).
- **HTTP 200 + `[]`** ou **403** → pas d’exposition.

### Lister les policies par table

```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### Compter les policies « public » restantes

```sql
SELECT count(*) AS public_policies_count
FROM pg_policies
WHERE schemaname = 'public'
  AND roles @> ARRAY['public']::name[];
```

**Cible** : `0` après hardening.

---

## Checklist STAGING

- [ ] Backup (ou confirmation pas de données critiques).
- [ ] Exécuter requête `pg_policies` ; noter les policies `roles @> ARRAY['public']`.
- [ ] Pour chaque table sensible : test curl ANON ; noter fuite ou `[]`.
- [ ] DROP ou migrer les policies `{public}` (migration = recréer en `TO authenticated` avec la même condition).
- [ ] Re-test curl ANON sur tables corrigées → `[]`.
- [ ] Vérif finale : `count(public policies) = 0`.

---

## Checklist PROD

- [ ] **Backup PROD** validé avant toute modification RLS.
- [ ] Test ANON sur tables sensibles (ex. `log_actions`, `stocks_journaliers`, `citernes`, …).
- [ ] Identifier policies en `{public}` (notamment `SELECT true`).
- [ ] DROP policies dangereuses (ex. `read stocks_journaliers`, `read citernes` si `USING (true)` et `TO public`).
- [ ] Migrer les autres `{public}` → `authenticated` (recréer policy avec `TO authenticated`, même `USING`/`WITH CHECK`).
- [ ] Re-test curl ANON → `[]` sur les tables concernées.
- [ ] Vérif finale : `SELECT count(*) FROM pg_policies WHERE schemaname = 'public' AND roles @> ARRAY['public']::name[]` → **0**.
- [ ] Renseigner le déploiement log : `docs/POST_PROD/12_PHASE2_PROD_DEPLOY_LOG.md`.

---

## Rollback logique

- **Aucune suppression de données** : les changements portent uniquement sur les policies RLS.
- **Recreate policy** : si une policy a été supprimée par erreur, la recréer avec le même nom et la même expression, en ciblant `authenticated` (ou le rôle approprié). Exemple :

```sql
-- Exemple (adapter nom table, nom policy, condition)
CREATE POLICY "read_citernes" ON public.citernes
FOR SELECT TO authenticated
USING (true);  -- ou une condition métier (ex. depot_id = app_current_depot_id())
```

- **En cas de régression** : réappliquer la policy migrée (authenticated) depuis la sauvegarde ou la doc ; re-tester l’app (login utilisateur) pour confirmer que les écrans fonctionnent.

---

## Risques résiduels / dette

- **Drift** : Les futures migrations (nouveaux objets, nouvelles policies) peuvent réintroduire des policies `{public}`. **Revue obligatoire** de toute migration RLS.
- **CI** : Aucun check automatique actuel. **Recommandation** : ajouter un script (SQL ou job CI) qui échoue si `count(public policies) > 0` en STAGING/PROD (ou sur export du schéma).
- **Règle de revue** : Aucune policy `SELECT true` (ou équivalent permissif) pour le rôle `public`. Documenter cette règle dans la stratégie Phase 2 et dans le runbook des changements DB.

---

## Next actions

1. **Check automatique** : Mettre en place un script (ex. SQL exécuté en CI ou avant déploiement) qui vérifie `count(public policies) = 0` et fait échouer le déploiement si non respecté.
2. **Règle de revue** : Formaliser dans la revue de code / checklist DB : « Aucune policy RLS avec `TO public` et condition permissive (`true`) ».
3. **Runbook DB changes** : Mettre à jour le runbook des changements DB (ou équivalent) pour inclure la vérification RLS (pas de policy publique) avant toute application en PROD.

---

## Références

- **Stratégie Phase 2** : `docs/POST_PROD/09_PHASE2_STRATEGIE.md` (standard « 0 public policies »).
- **Plan 10 actions** : `docs/POST_PROD/10_PHASE2_PLAN_10_ACTIONS.md` (Action 7).
- **Déploiement PROD** : `docs/POST_PROD/12_PHASE2_PROD_DEPLOY_LOG.md` (Entry 2 — RLS Hardening).
- **Tracker** : `docs/POST_PROD/11_PHASE2_TRACKER.md` (Action 7 DONE).

# 🔒 B2.3 — STAGING prerequisites + RLS tests (stocks_adjustments)

**Date de création :** 08/01/2026  
**Statut :** ✅ VALIDÉ  
**Environnement :** Supabase STAGING uniquement

---

## 🎯 Objectif

Verrouiller par RLS la table `public.stocks_adjustments` :

- un utilisateur **lecture** ne doit **jamais** pouvoir écrire (INSERT)
- un utilisateur **admin / service role** doit pouvoir écrire (INSERT)
- un utilisateur **lecture** doit pouvoir lire (SELECT)

## ✅ Pourquoi

- **Sécurité (audit & conformité)**
- Éviter qu’un compte lecture (ou compromis) puisse injecter des corrections de stock
- Garantir que seules les actions autorisées génèrent des ajustements

---

## B2.3.0 — Pré-requis STAGING (setup minimal)

### Pré-requis DB (Supabase STAGING)

- **Dépôt STAGING existe**
- **Depot seedé** :
  - `DEPOT STAGING`
  - `id = 11111111-1111-1111-1111-111111111111`

### Utilisateurs de test (lecture)

Création d’un user auth Supabase :

- `valtest+lecture@monaluxe.test` (role: `lecture`)

Profil correspondant dans `public.profils` :

- `user_id = 14064b77-e138-408b-94ff-59fef8d1adfe`
- `role = lecture`
- `depot_id = 11111111-1111-1111-1111-111111111111`

Correction email (trim) si besoin :

```sql
update public.profils
set email = trim(email)
where user_id = '14064b77-e138-408b-94ff-59fef8d1adfe';
```

### Env local (jamais commit)

Fichier local : `env/.env.staging`  
Doit contenir au minimum :

```bash
SUPABASE_ENV=STAGING
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
# (optionnel) SUPABASE_SERVICE_ROLE_KEY=...

TEST_USER_EMAIL=...
TEST_USER_PASSWORD=...
TEST_USER_ROLE=...

NON_ADMIN_EMAIL=valtest+lecture@monaluxe.test
NON_ADMIN_PASSWORD=...
NON_ADMIN_ROLE=lecture
```

**Guard important :** le loader refuse si `SUPABASE_ENV != STAGING` ou si l’URL “ressemble” à PROD.

---

## B2.3.0 — Pré-requis code (harness STAGING)

### Fichiers utilisés

- `test/integration/_env/staging_env.dart`
- `test/integration/_harness/staging_supabase_client.dart`

### Points clés

- `StagingEnv.load()` lit `env/.env.staging` + anti-PROD guard.
- `StagingSupabase.create()` construit :
  - `anonClient` (toujours)
  - `serviceClient` (si `SUPABASE_SERVICE_ROLE_KEY` fourni)

**Important :**

- un test RLS doit utiliser **`anonClient` authentifié** (login via email/password) pour que RLS s’applique
- `serviceClient` **bypass** la RLS (service role)
- `StagingSupabase` ne conserve pas une map d'env “brute” : les tests lisent le fichier via `StagingEnv.load(...)` si besoin de variables.

---

## B2.3.1 — Test RLS “lecture cannot INSERT stocks_adjustments”

### Fichier

`test/integration/rls_stocks_adjustment_test.dart`

### Ce qu’on a dû corriger pendant la mise au point

#### Imports / harness

Remplacer les imports manquants par :

- `import '_harness/staging_supabase_client.dart';`

#### Binding Flutter

Supprimer `TestWidgetsFlutterBinding.ensureInitialized()` (sinon HTTP bloqué → 400).

#### Payload conforme aux contraintes

- `mouvement_type` doit être `RECEPTION` ou `SORTIE` (check constraint).
- `mouvement_id` doit exister réellement (sinon `MOUVEMENT_NOT_FOUND`).
- `created_by` obligatoire (NOT NULL).
  - le test récupère un vrai `receptions.id` pour rendre le payload valide avant d'atteindre la RLS

#### RLS activée

On a constaté au début :

- `relrowsecurity=false`

Puis RLS a été activée, et le test a commencé à refléter la réalité sécurité.

### Commande

```bash
flutter test test/integration/rls_stocks_adjustment_test.dart -r expanded
```

### Critère d’acceptation

Le test passe si :

- la tentative INSERT côté user **lecture** échoue avec un message d’erreur RLS/permission

✅ Résultat : PASS

---

## B2.3.2 — Test RLS “admin CAN INSERT stocks_adjustments”

### Fichier

`test/integration/rls_stocks_adjustment_admin_test.dart`

### Erreur rencontrée et fix

L’ID dummy `11111111-...` utilisé comme `mouvement_id` provoquait :

- `MOUVEMENT_NOT_FOUND: receptions.id ... introuvable`

Fix : utiliser un vrai `receptions.id` existant (ex: `ee02a4e8-7029-4dcd-b638-dac6c9f56743`), ou créer une réception dédiée au test.

### Commande

```bash
flutter test test/integration/rls_stocks_adjustment_admin_test.dart -r expanded
```

### Critère d’acceptation

Le test passe si :

- l’INSERT par **admin / service role** réussit
- on obtient un id d’insert loggé

✅ Résultat : PASS  
Exemple log : `B2.3.2 OK — admin insert allowed (id=...)`

---

## B2.3.3 — Test RLS “lecture CAN SELECT stocks_adjustments”

### Fichier

`test/integration/rls_stocks_adjustment_read_test.dart`

### Problème rencontré et fix

Le test essayait de lire `staging.env` (non exposé par le harness).

Fix : lire l'env via :

- `final env = await StagingEnv.load(path: 'env/.env.staging');`

### Commande

```bash
flutter test test/integration/rls_stocks_adjustment_read_test.dart -r expanded
```

### Critère d’acceptation

Le test passe si :

- un user **lecture** authentifié peut faire un `SELECT ... LIMIT 1` sous RLS (même si la table est vide)

✅ Résultat : PASS  
Exemple log : `SELECT OK — rows=0/1`

---

## DB — RLS & Policies (résumé audit)

### État confirmé

- RLS est activée sur `public.stocks_adjustments`
- Policies créées (confirmé)

### Objectif atteint

- lecture : write interdit
- lecture : read autorisé
- admin / service role : write autorisé

### Note “pg_policies”

Selon la version Postgres / Supabase, la colonne peut être `policyname` (et non `polname`) dans `pg_policies`.

---

## Livrable “Cursor-ready” (à coller dans docs / changelog)

### Ajouts tests

- `test/integration/rls_stocks_adjustment_test.dart`
- `test/integration/rls_stocks_adjustment_admin_test.dart`
- `test/integration/rls_stocks_adjustment_read_test.dart`

### Ajouts harness/env (scope B2.3)

- `test/integration/_env/staging_env.dart`
- `test/integration/_harness/staging_supabase_client.dart`

### Commandes de validation

```bash
flutter test test/integration/rls_stocks_adjustment_test.dart -r expanded
flutter test test/integration/rls_stocks_adjustment_admin_test.dart -r expanded
flutter test test/integration/rls_stocks_adjustment_read_test.dart -r expanded
```



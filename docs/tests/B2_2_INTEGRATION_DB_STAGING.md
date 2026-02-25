# 🧪 B2.2 — Tests d'intégration DB réels STAGING

**Date de création :** 04/01/2026  
**Statut :** ✅ VALIDÉ  
**Environnement :** Supabase STAGING uniquement

---

## 🎯 Objectif

Valider en conditions réelles STAGING que les règles métier critiques (débit/crédit stock, rejets, logs) fonctionnent correctement **sans mock ni contournement applicatif**.

### Scope

Les tests B2.2 couvrent :

1. **Test smoke DB** : Connexion STAGING + requête simple
2. **Test Réception → Stock → Log** : Crédit stock via réception
3. **Test Sortie → Stock → Log** : Débit stock via sortie + validation

**Principe DB-STRICT** : Toute la logique métier passe par les triggers et fonctions SQL. L'application ne peut jamais contourner les règles métier.

---

## 📋 Prérequis STAGING

### 1. Fichier d'environnement

Le fichier `env/.env.staging` doit exister (jamais commité) avec :

```bash
# Obligatoire
SUPABASE_ENV=STAGING
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=xxxxx
SUPABASE_SERVICE_ROLE_KEY=xxxxx  # Optionnel mais recommandé
STAGING_DB_URL=postgresql://postgres:xxxxx@db.xxxxx.supabase.co:5432/postgres

# Optionnel (pour tests avec utilisateur authentifié)
TEST_USER_EMAIL=valtest+staging@monaluxe.test
TEST_USER_PASSWORD=ChangeMe123!
TEST_USER_ROLE=admin  # minuscule: admin, directeur, gerant, lecture, pca
```

**Important :** Le fichier `env/.env.staging` est dans `.gitignore` (ligne 233) et ne doit **JAMAIS** être commité.

### 2. Seed STAGING appliqué

Le seed minimal doit être appliqué sur STAGING :

```bash
# Appliquer le seed minimal (si pas déjà fait)
ALLOW_STAGING_RESET=true ./scripts/reset_staging.sh
```

Le seed contient les IDs fixes suivants (définis dans `staging/sql/seed_staging_minimal_v2.sql`) :

- **Dépôt** : `11111111-1111-1111-1111-111111111111` → `DEPOT STAGING`
- **Produit** : `22222222-2222-2222-2222-222222222222` → `DIESEL STAGING`
- **Citerne** : `33333333-3333-3333-3333-333333333333` → `TANK STAGING 1`

### 3. Patch DB appliqué (STAGING uniquement)

Le patch SQL suivant doit être appliqué sur STAGING :

```bash
# Appliquer le patch (si pas déjà fait)
psql "$STAGING_DB_URL" -f staging/sql/migrations/001_patch_validate_sortie_allow_write.sql
```

**Fichier :** `staging/sql/migrations/001_patch_validate_sortie_allow_write.sql`

Ce patch ajoute `set_config('app.stocks_journaliers_allow_write', '1', true)` à la fonction `validate_sortie()` pour autoriser temporairement l'écriture sur `stocks_journaliers`.

**⚠️ IMPORTANT :** Ce patch est limité à STAGING. PROD reste strictement contrôlé.

### 4. Utilisateur de test (optionnel mais recommandé)

Pour les tests nécessitant un utilisateur authentifié (ex: `sortie_stock_log_test.dart`), créer un utilisateur dans Supabase STAGING Auth avec :

- **Email** : `valtest+staging@monaluxe.test` (ou valeur de `TEST_USER_EMAIL`)
- **Password** : `ChangeMe123!` (ou valeur de `TEST_USER_PASSWORD`)
- **Rôle** : `admin` (ou valeur de `TEST_USER_ROLE` en minuscule)

Le profil correspondant doit être créé dans la table `profils` avec le rôle spécifié.

**Documentation complète :** `docs/B2.2.1_TEST_USER.md`

### 5. Environment hygiene (reset CDR only)

Si les tests B2.2 sont pollués par des données résiduelles (réceptions/sorties/stocks antérieurs), exécuter le **reset STAGING "CDR only"** avant de relancer les tests :

- **Script** : [docs/DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql](../DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql)
- **Effet** : Purge des tables receptions, sorties_produit, stocks_journaliers et log_actions (scopés receptions/sorties/stock) ; **cours_de_route** conservé. STAGING only.
- **Procédure** : Voir [docs/02_RUNBOOKS/staging.md](../02_RUNBOOKS/staging.md) section « RESET STAGING (CDR only) ».

**Hygiene (stock UI non zéro après reset)** : Si l’UI affiche encore du stock après le reset CDR only, vérifier et purger `public.stocks_snapshot` et supprimer la citerne fantôme TANK TEST si présente. Script : [docs/DB_CHANGES/2026-02-25_staging_hygiene_remove_tank_test_and_purge_snapshot.sql](../DB_CHANGES/2026-02-25_staging_hygiene_remove_tank_test_and_purge_snapshot.sql). Prérequis recommandé avant simulation UX / validation ASTM : `stocks_snapshot` doit être vide.

---

## 📁 Fichiers de tests

Les tests d'intégration DB réels STAGING sont dans `test/integration/` :

### 1. Test smoke DB

**Fichier :** `test/integration/db_smoke_test.dart`

**Objectif :** Vérifier la connexion STAGING + requête simple sur la table `depots`.

**Commande isolée :**
```bash
flutter test test/integration/db_smoke_test.dart -r expanded
```

### 2. Test Réception → Stock → Log

**Fichier :** `test/integration/reception_stock_log_test.dart`

**Objectif :** Valider que l'insertion d'une réception crédite correctement le stock dans `stocks_journaliers`.

**Scénario :**
1. Insert réception avec `volume_corrige_15c`
2. Vérifie que `stocks_journaliers.stock_15c` augmente
3. Utilise les IDs fixes du seed staging

**Commande isolée :**
```bash
flutter test test/integration/reception_stock_log_test.dart -r expanded
```

### 3. Test Sortie → Stock → Log

**Fichier :** `test/integration/sortie_stock_log_test.dart`

**Objectif :** Valider que la validation d'une sortie débite correctement le stock dans `stocks_journaliers` et rejette les sorties invalides (stock insuffisant).

**Scénario :**
1. Seed stock initial via réception
2. Login utilisateur de test
3. Ensure profil avec rôle normalisé
4. Insert sortie avec `statut='brouillon'`
5. Validate via `anon.rpc('validate_sortie', {'p_id': sortieId})`
6. Vérifie que `stocks_journaliers.stock_15c` diminue
7. Test rejet : Insert sortie avec volume > stock disponible → `validate_sortie` doit rejeter

**Prérequis :**
- Variables `TEST_USER_EMAIL`, `TEST_USER_PASSWORD`, `TEST_USER_ROLE` dans `env/.env.staging`
- Utilisateur créé dans Supabase STAGING Auth
- Patch DB appliqué (voir section Prérequis)

**Commande isolée :**
```bash
flutter test test/integration/sortie_stock_log_test.dart -r expanded
```

---

## 🚀 Runner one-shot (tous les tests B2.2)

Pour exécuter **tous les tests B2.2** en une seule commande :

```bash
flutter test test/integration/db_smoke_test.dart test/integration/reception_stock_log_test.dart test/integration/sortie_stock_log_test.dart -r expanded
```

**Résultat attendu :** Tous les tests passent (vert) ✅

**Logs attendus :**
```
[DB-TEST] Connected to STAGING and queried depots successfully.
[DB-TEST] Réception -> Stocks journaliers OK
[DB-TEST] Before stock_15c: XXXX
[DB-TEST] After stock_15c: YYYY (YYYY < XXXX)
[DB-TEST] B2.2 OK — debit & reject verified
```

---

## ✅ Definition of Done (DoD)

Les tests B2.2 sont considérés **DONE** lorsque :

1. ✅ **Tous les tests passent** : Les 3 tests (smoke, réception, sortie) passent sur STAGING
2. ✅ **Aucun mock** : Les tests s'exécutent contre la base STAGING réelle
3. ✅ **Conformité DB-STRICT** : Les règles métier sont validées par les triggers/fonctions SQL
4. ✅ **Documentation complète** : Ce document existe et est à jour
5. ✅ **Runner one-shot vert** : La commande `flutter test test/integration/db_smoke_test.dart test/integration/reception_stock_log_test.dart test/integration/sortie_stock_log_test.dart -r expanded` passe sans erreur

**Date de validation :** 04/01/2026  
**Preuve :** Runner one-shot vert ✅

---

## 🔧 Dépannage

### Erreur : "Missing env/.env.staging"

**Solution :**
1. Copier le template : `cp env/.env.staging.example env/.env.staging`
2. Remplir les vraies valeurs (URL, clés, etc.)
3. Vérifier que `SUPABASE_ENV=STAGING`

### Erreur : "SUPABASE_URL looks like PROD"

**Cause :** L'URL contient `prod`, `production`, ou `live`.

**Solution :** Vérifier que vous utilisez bien l'URL STAGING, pas PROD.

### Erreur : "TEST_USER_EMAIL and TEST_USER_PASSWORD must be set"

**Solution :**
1. Ajouter `TEST_USER_EMAIL`, `TEST_USER_PASSWORD`, `TEST_USER_ROLE` dans `env/.env.staging`
2. Créer l'utilisateur dans Supabase STAGING Auth
3. Créer le profil correspondant dans la table `profils`

### Erreur : "Function validate_sortie already contains set_config, skipping"

**Cause :** Le patch DB est déjà appliqué.

**Solution :** C'est normal, le patch skip si déjà présent. Aucune action requise.

### Erreur : "Ecriture directe interdite sur stocks_journaliers"

**Cause :** Le patch DB n'est pas appliqué.

**Solution :** Appliquer le patch : `psql "$STAGING_DB_URL" -f staging/sql/migrations/001_patch_validate_sortie_allow_write.sql`

### Erreur : "No stocks_journaliers row found"

**Cause :** Le seed n'a pas été appliqué ou le stock initial n'a pas été créé.

**Solution :**
1. Appliquer le seed : `ALLOW_STAGING_RESET=true ./scripts/reset_staging.sh`
2. Pour `sortie_stock_log_test.dart`, le test crée automatiquement le stock initial via `seedStockReady()`

### Erreur : "INVALID_ID_OR_STATE"

**Cause :** La sortie n'est pas dans l'état `NULL` ou `'brouillon'`, ou `created_by` ne correspond pas à l'utilisateur authentifié.

**Solution :** Le test `sortie_stock_log_test.dart` gère automatiquement cette validation. Vérifier que l'utilisateur de test est bien authentifié.

---

## 📚 Documentation complémentaire

- **Environnement STAGING** : `docs/staging.md`
- **AXE B1 STAGING** : `docs/AXE_B1_STAGING.md`
- **Tests d'intégration B2.2** : `docs/B2_INTEGRATION_TESTS.md`
- **Utilisateur de test** : `docs/B2.2.1_TEST_USER.md`
- **Script de reset** : `scripts/reset_staging.sh`
- **Seed minimal** : `staging/sql/seed_staging_minimal_v2.sql`
- **Patch DB** : `staging/sql/migrations/001_patch_validate_sortie_allow_write.sql`

---

## 🔒 Sécurité

⚠️ **IMPORTANT :** Les tests B2.2 s'exécutent contre la base STAGING réelle. Aucune clé secrète ne doit être commitée.

- ✅ `env/.env.staging` est dans `.gitignore` (ligne 233)
- ✅ `env/.env.staging.example` est versionné (template uniquement)
- ✅ Les garde-fous anti-PROD sont activés (`StagingEnv._guardAgainstProd()`)

**Vérification :**
```bash
git check-ignore -v env/.env.staging
# Doit afficher : .gitignore:233:env/	env/.env.staging
```

---

**Dernière mise à jour :** 04/01/2026  
**Statut :** ✅ VALIDÉ - Runner one-shot vert



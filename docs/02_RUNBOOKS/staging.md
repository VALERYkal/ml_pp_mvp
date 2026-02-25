# 🧪 Staging Environment - ML_PP MVP

## 📋 Configuration

Le fichier `env/.env.staging.example` contient le template des variables d'environnement nécessaires pour l'environnement de staging.

**⚠️ IMPORTANT :** Copiez `env/.env.staging.example` vers `env/.env.staging` et remplissez les valeurs réelles. Le fichier `.env.staging` ne doit **JAMAIS** être commité dans Git.

## 🔒 Règles de sécurité (OBLIGATOIRES)

### Règle 1 : Verrou de reset
**Jamais de reset sans `ALLOW_STAGING_RESET=true`**

Les scripts de reset de la base de données staging doivent vérifier que `ALLOW_STAGING_RESET=true` avant d'exécuter toute opération destructive.

### Règle 2 : Protection anti-production
**Jamais de reset si l'URL contient `prod` ou `production`**

Tous les scripts doivent vérifier que l'URL Supabase ne contient pas les mots-clés `prod` ou `production` avant d'exécuter des opérations de reset.

### Règle 3 : Clés service_role
**Les clés `SERVICE_ROLE_KEY` ne sont jamais utilisées côté app, uniquement dans les scripts**

- ✅ Utilisation autorisée : Scripts de reset, migrations, seeds
- ❌ Utilisation interdite : Code de l'application Flutter, providers, services

## 🚀 Utilisation

1. Copier le template :
   ```bash
   cp env/.env.staging.example env/.env.staging
   ```

2. Remplir les valeurs réelles dans `env/.env.staging` (ne pas commiter ce fichier)

3. Vérifier que `ALLOW_STAGING_RESET=false` par défaut (sécurité)

4. Activer le reset uniquement quand nécessaire :
   ```bash
   # Dans env/.env.staging
   ALLOW_STAGING_RESET=true
   ```

## 👤 Utilisateur de test (B2.2.1)

Pour les tests d'intégration nécessitant un utilisateur authentifié, ajoutez ces variables dans `env/.env.staging` :

**Format exact (une clé par ligne, pas de guillemets, pas d'espaces autour du =) :**

```
TEST_USER_EMAIL=valtest+staging@monaluxe.test
TEST_USER_PASSWORD=ChangeMe123!
TEST_USER_ROLE=admin
```

**Important :**
- `TEST_USER_ROLE` doit être en **minuscule** : `admin`, `directeur`, `gerant`, `lecture`, ou `pca`
- Pas de guillemets autour des valeurs
- Pas d'espaces avant ou après le `=`
- Une variable par ligne

Ces variables sont optionnelles mais nécessaires pour certains tests d'intégration. Voir `docs/B2.2.1_TEST_USER.md` pour plus de détails.

## 🧪 Tests d'intégration DB réels (B2.2)

STAGING est l'environnement de vérité pour les tests d'intégration DB réels. Ces tests valident que les règles métier critiques (débit stock, rejets, logs) fonctionnent correctement sans mock ni contournement applicatif.

### Test B2.2 : Sortie → Stock → Log

Le test `test/integration/sortie_stock_log_test.dart` valide le flux complet :
- Insertion d'une sortie en brouillon
- Validation via `validate_sortie(p_id)`
- Vérification du débit stock
- Test de rejet (stock insuffisant)

Voir `docs/B2_INTEGRATION_TESTS.md` pour la documentation complète.

### Patches DB (STAGING uniquement)

Certains patches DB sont nécessaires pour permettre les tests d'intégration :
- Patch `validate_sortie()` : Ajout de `set_config('app.stocks_journaliers_allow_write', '1', true)` pour autoriser l'écriture sur `stocks_journaliers`
- Voir `staging/sql/migrations/001_patch_validate_sortie_allow_write.sql`

**Important** : Ces patches sont limités à STAGING. PROD reste strictement contrôlé.

## 🔄 RESET STAGING (CDR only)

Pour repartir d'une base STAGING propre (sans réceptions/sorties/stocks historiques) tout en conservant les **cours de route** (CDR), exécuter le script SQL de reset **STAGING only**.

### Prérequis

- Accès SQL Editor STAGING (Supabase Dashboard ou `psql "$STAGING_DB_URL"`).
- **Ne jamais exécuter en PROD** : le script est destiné à l'environnement STAGING uniquement.

### Procédure

1. Ouvrir le fichier `docs/DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql`.
2. Exécuter le script en entier dans l'éditeur SQL STAGING (il applique d'abord le patch `receptions_block_update_delete` puis la purge en une transaction).
3. Vérifier les comptages affichés en NOTICE : **AFTER** doit montrer `receptions=0`, `sorties_produit=0`, `stocks_journaliers=0`, `log_actions(scoped)=0`, et `cours_de_route` inchangé (ex. 4).
4. Les flags DB-STRICT (`app.receptions_allow_write`, `app.sorties_produit_allow_write`, `app.stocks_journaliers_allow_write`) sont **transaction-scoped** : actifs uniquement pendant la transaction de purge, puis réinitialisés.

### Invariant

- **cours_de_route** n'est jamais supprimé ; seules les tables de mouvement stock (receptions, sorties_produit, stocks_journaliers, log_actions scopés) sont purgées.

## STAGING hygiene (phantom tanks & snapshot cache)

Si après un reset CDR only l’UI affiche encore du stock non-zéro, la table `public.stocks_snapshot` peut contenir des lignes historiques (cache) et une citerne fantôme (ex. **TANK TEST**) peut être présente ; la FK `stocks_snapshot -> citernes` bloque alors la suppression de la citerne.

### Vérification

- **Citernes non conformes** (TANK TEST) :
  ```sql
  SELECT id, nom FROM public.citernes WHERE id = '44444444-4444-4444-4444-444444444444' OR nom = 'TANK TEST';
  ```
  Attendu : 0 ligne.

- **Taille du cache snapshot** :
  ```sql
  SELECT COUNT(*) FROM public.stocks_snapshot;
  ```
  Attendu : 0 (baseline propre).

### Procédure

1. Exécuter le script SQL d’hygiene STAGING only :  
   `docs/DB_CHANGES/2026-02-25_staging_hygiene_remove_tank_test_and_purge_snapshot.sql`
2. Vérifier en fin de script les NOTICE : `tank_test_in_citernes = 0`, `tank_test_in_snapshot = 0`, `stocks_snapshot_total = 0`.
3. Contrôler en UI : Dashboard stock total = 0, écran Stock = 0.

**Résultat attendu** : `stocks_snapshot` vide ; aucune citerne TANK TEST (id `4444…`). Prérequis avant simulation UX / validation ASTM.

## 📝 Notes

- Le fichier `env/.env.staging` est dans `.gitignore` (ne sera jamais commité)
- Le template `env/.env.staging.example` est versionné (peut être commité)
- Tous les scripts doivent respecter les 3 règles de sécurité ci-dessus


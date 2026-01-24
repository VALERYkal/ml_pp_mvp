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

## 📝 Notes

- Le fichier `env/.env.staging` est dans `.gitignore` (ne sera jamais commité)
- Le template `env/.env.staging.example` est versionné (peut être commité)
- Tous les scripts doivent respecter les 3 règles de sécurité ci-dessus


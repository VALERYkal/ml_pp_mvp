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

## 📝 Notes

- Le fichier `env/.env.staging` est dans `.gitignore` (ne sera jamais commité)
- Le template `env/.env.staging.example` est versionné (peut être commité)
- Tous les scripts doivent respecter les 3 règles de sécurité ci-dessus


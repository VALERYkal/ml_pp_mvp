# 🧪 AXE B1 — Environnement STAGING (DB réelle Supabase)

## 🎯 Objectif de l'AXE B1

Mettre en place un environnement Supabase STAGING :
- **Strictement séparé de PROD** : Aucune interaction possible avec la production
- **Recréable à l'identique** : Procédure de reset reproductible
- **Protégé contre toute destruction accidentelle** : Garde-fous anti-PROD multiples
- **Utilisable pour des tests d'intégration DB réels** : Pré-requis pour AXE B2

**AXE B1 est un pré-requis bloquant avant toute validation industrielle.**

---

## 📦 Contenu livré (B1.0 → B1.4)

### 1. Projet Supabase STAGING

- **Nom** : `ml_pp_mvp_staging`
- **Région** : EU (Frankfurt) — identique à PROD
- **Accès** :
  - URL Supabase
  - `anon key`
  - `service_role key`

⚠️ **Aucune clé n'est jamais commitée**

Les vraies clés vivent uniquement dans :
- `env/.env.staging` (ignoré par git)

---

## 🔐 Gestion des secrets (sécurité critique)

### Fichier versionné (template uniquement)

**`env/.env.staging.example`**

Contient uniquement des placeholders :
```bash
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY

STAGING_DB_URL=postgresql://postgres:YOUR_DB_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres

ALLOW_STAGING_RESET=false
STAGING_PROJECT_REF=YOUR_PROJECT_REF
```

### Fichier réel (non versionné)

**`env/.env.staging`** (gitignored)

👉 **Règle absolue** :
Aucune vraie clé ne doit jamais apparaître dans le repo.

---

## 🛑 Garde-fous anti-PROD (design intentionnel)

### 1. Switch explicite obligatoire

```bash
ALLOW_STAGING_RESET=false
```

Sans `ALLOW_STAGING_RESET=true`, aucun reset n'est possible.

### 2. Vérification du project ref

Dans le script de reset :
```bash
EXPECTED_REF="jgquhldzcisjnbotnskr"
```

Le script refuse de s'exécuter si :
- `STAGING_PROJECT_REF` est vide
- ou différent du ref attendu

👉 **Impossible de viser PROD par erreur.**

---

## 🔁 Script de reset STAGING

### Script versionné

**`scripts/reset_staging.sh`**

### Responsabilités du script

1. Charger `env/.env.staging`
2. Vérifier les garde-fous :
   - `ALLOW_STAGING_RESET=true` obligatoire
   - `STAGING_PROJECT_REF` correspond au ref attendu
3. **DROP complet du schéma public** :
   - Toutes les vues
   - Toutes les tables
   - Toutes les fonctions
4. Appliquer un seed contrôlé

### Utilisation standard

```bash
ALLOW_STAGING_RESET=true ./scripts/reset_staging.sh
```

### Seed paramétrable

**Par défaut** :
```bash
staging/sql/seed_staging_minimal_v2.sql
```

**Mais possible de passer un seed vide** :
```bash
SEED_FILE=staging/sql/seed_empty.sql ALLOW_STAGING_RESET=true ./scripts/reset_staging.sh
```

---

## 🧬 Import du schéma PROD

### Problème rencontré

Le `pg_dump` standard PROD contient :
- `\restrict` / `\unrestrict`
- `EVENT TRIGGER`
- `PUBLICATION`
- `CREATE SCHEMA public`
- Politiques RLS sur tables inexistantes

👉 **Inapplicable tel quel sur Supabase STAGING**

### Solution retenue (robuste)

1. **Export PROD (schema-only)**
2. **Nettoyage manuel contrôlé** :
   - Suppression des `restrict/unrestrict`
   - Suppression des `event triggers`
   - Suppression des `publications`
   - Suppression de `CREATE SCHEMA public`
3. **Import après reset complet** (sans seed)

### Résultat final importé

- ✅ Tables
- ✅ Vues
- ✅ Fonctions
- ✅ Triggers
- ✅ Policies RLS

👉 **Schéma STAGING = PROD à l'identique**

---

## 🌱 Seed minimal STAGING

### Fichier

**`staging/sql/seed_staging_minimal_v2.sql`**

### Contenu

Contient uniquement :
1. **1 dépôt** : `DEPOT STAGING` (ID fixe : `11111111-1111-1111-1111-111111111111`)
2. **1 produit** : `DIESEL STAGING` (ID fixe : `22222222-2222-2222-2222-222222222222`)
3. **1 citerne** : `TANK STAGING 1` (ID fixe : `33333333-3333-3333-3333-333333333333`)

### Objectif

- ✅ Permettre les tests d'intégration
- ✅ Éviter toute donnée métier réelle
- ✅ IDs fixes pour faciliter les scripts de test

### Caractéristiques

- **Compatible schéma PROD** : Uniquement des `INSERT`, pas de `CREATE TABLE`
- **Idempotent** : Utilise `ON CONFLICT DO UPDATE`
- **Transactionnel** : Tout dans un `BEGIN/COMMIT`

---

## 📊 État final validé (B1.4)

### Vérifications effectuées

```sql
-- Nombre de tables
select count(*) from information_schema.tables where table_schema='public';
-- 28 tables

-- Nombre de dépôts
select count(*) from depots;
-- 1

-- Nombre de citernes
select count(*) from citernes;
-- 1
```

👉 **STAGING est** :
- ✅ Sain
- ✅ Cohérent
- ✅ Reproductible
- ✅ Sécurisé

---

## 🚫 Fichiers volontairement ignorés (.gitignore)

Les fichiers suivants sont dans `.gitignore` et ne sont **jamais commités** :

```
prod/
staging/sql/*clean*.sql
staging/sql/*safe*.sql
staging/sql/*noclean*.sql
staging/sql/seed_empty.sql
staging/sql/seed_staging_minimal.sql
```

👉 **Le repo ne conserve que les artefacts contractuels, jamais les dumps de travail.**

---

## ✅ Conclusion AXE B1

**AXE B1 est complètement terminé.**

Il fournit :
- ✅ Une base STAGING industrielle
- ✅ Une procédure de reset sûre
- ✅ Une protection anti-PROD
- ✅ Un socle fiable pour les tests DB réels

👉 **AXE B2 peut maintenant démarrer** (tests d'intégration Supabase réels).

---

## 📚 Documentation complémentaire

- **Règles de sécurité détaillées** : Voir `docs/staging.md`
- **Template d'environnement** : Voir `env/.env.staging.example`
- **Script de reset** : Voir `scripts/reset_staging.sh`
- **Seed minimal** : Voir `staging/sql/seed_staging_minimal_v2.sql`

---

## 🔄 Procédure de reset complète

1. **Vérifier les prérequis** :
   ```bash
   # Vérifier que env/.env.staging existe
   ls -la env/.env.staging
   ```

2. **Activer le verrou de sécurité** :
   ```bash
   # Dans env/.env.staging
   ALLOW_STAGING_RESET=true
   ```

3. **Lancer le reset** :
   ```bash
   ./scripts/reset_staging.sh
   ```

4. **Vérifier le résultat** :
   ```sql
   -- Se connecter à la DB staging
   -- Vérifier les tables, vues, fonctions
   -- Vérifier le seed (1 dépôt, 1 produit, 1 citerne)
   ```

5. **Désactiver le verrou** :
   ```bash
   # Dans env/.env.staging
   ALLOW_STAGING_RESET=false
   ```

---

**Date de complétion** : 03/01/2026  
**Statut** : ✅ **TERMINÉ**


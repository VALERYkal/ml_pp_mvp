# 🚀 Projet : ML_PP MVP

**Objectif** : Application de gestion logistique pétrolière pour Monaluxe  
**Stack technique** : Flutter + Supabase + Riverpod + GoRouter + Clean Architecture

> ⚠️ **SPRINT EN COURS (31/12/2025) :** Finalisation production industrielle  
> 📋 [Sprint Prod-Ready 10-15 jours](docs/SPRINT_PROD_READY_2025-12-31.md) | [Suivi](docs/SUIVI_SPRINT_PROD_READY.md)

**Objectif Sprint :** ML_PP MVP déployable en production industrielle auditée

**Avancement :** 0/11 tickets (0%)
- 🔴 AXE A (DB-STRICT) : 0/3
- 🔴 AXE B (Tests DB) : 0/2
- 🔴 AXE C (Sécurité) : 0/2
- 🟡 AXE D (Stabilisation) : 0/4

**Verdict actuel :**
- 🟢 **Fonctionnel : GO** (production interne contrôlée)
- 🔴 **Industriel : NO-GO** (chantiers P0 requis : 7-10j)

**Décision :**
- ✅ GO production interne contrôlée
- ❌ NO-GO production industrielle auditée (points 1-6 requis)

📋 **[Voir le rapport complet →](docs/RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md)**

---

## 📚 Structure du projet

```bash
lib/
│
├── core/                # Modèles globaux, exceptions, constants, utils
├── features/            # Modules métier (auth, cours_route, receptions, etc.)
│   └── <module>/        # Chaque module contient: models/, screens/, services/, providers/
├── shared/              # UI réutilisable, providers globaux, navigation
│   ├── ui/              # Widgets communs
│   ├── providers/       # Providers globaux
│   └── navigation/      # Configuration GoRouter
│
├── main.dart            # Entrée de l'application Flutter
│
docs/                    # Documentation complète (PRD, SQL, User stories, etc.)
test/                    # Tests unitaires et d’intégration
cursor.json              # Configuration IA (Cursor)
```

---

## 📁 Dossier `docs/` (inclus dans cursor.json)

Contient toutes les spécifications et documents nécessaires :
- ✅ `ML pp mvp PRD.md` – exigences produit
- ✅ `schema_supabase.md` et `schemaSQL.md` – structure base de données
- ✅ `user_stories_final.md` – cas d'usage par rôle
- ✅ `ux_ui_wireframes.md` – maquettes et navigation
- ✅ `architecture.md` – contraintes techniques, design system
- ✅ `checklist_dev.md` – suivi d'implémentation
- ✅ `plan de dev.md` – jalons de développement
- ✅ `contexte_logique_metie_ml_pp_mvp.md` – logique métier modulaire

### 🔧 Corrections et Fixes
- ✅ `mock_conflict_fix_summary.md` – Résolution conflit Mockito MockCoursDeRouteService
- ✅ `technical/mock_architecture.md` – Architecture des mocks CDR
- ✅ `quick_fixes/mock_conflict_resolution.md` – Guide rapide de correction

### 📊 Base de données & Vues SQL
- ⭐ **`db/CONTRAT_STOCK_ACTUEL.md`** – **Source de vérité unique** pour le stock actuel (OBLIGATOIRE)
- ✅ `db/vues_sql_reference.md` – Référence complète des vues SQL
- ✅ `db/vues_sql_reference_central.md` – Documentation centralisée des vues
- ✅ `db/flutter_db_usage_map.md` – Cartographie Flutter → DB
- ✅ `db/modules_flutter_db_map.md` – Cartographie par modules

---

## 🧠 À l’intention de l’IA (Cursor)

> L’IA doit :
- Respecter strictement la structure `lib/core`, `lib/features`, `lib/shared`
- Se référer systématiquement à `docs/` avant de générer du code
- Utiliser `freezed` pour les modèles, `Riverpod` pour les providers
- Injecter les services via `Provider` (`ref.watch()` / `ref.read()`)
- Ne jamais inventer de modèle, champ ou logique métier
- Générer du code testable, typé et modulaire
- Générer tests unitaires ou d’intégration à chaque étape clé

---

## ✅ Bonnes pratiques

- Utilise des UUID pour toutes les clés primaires
- Sépare bien UI, logique métier et persistance
- Respecte les rôles utilisateur définis (voir `user_stories_final.md`)
- Priorise les écrans suivants : `Cours de Route`, `Réceptions`, `Sorties`, `Stocks`
- Chaque mouvement (réception, sortie) doit être journalisé (`log_actions`)

---

## 🧪 Tests d'intégration DB réels

Le projet inclut des tests d'intégration DB réels exécutés contre l'environnement STAGING :

- **B2.2 — Tests d'intégration Sorties** : Validation DB-STRICT du flux Sortie → Stock → Log
  - Test : `test/integration/sortie_stock_log_test.dart`
  - Valide que les règles métier critiques (débit stock, rejets, logs) fonctionnent sans mock
  - Architecture DB-STRICT : Tables immutables, écritures uniquement via triggers/fonctions SQL

Voir `docs/B2_INTEGRATION_TESTS.md` pour la documentation complète.

---

## 📍Où placer ce README

✅ Place-le dans la racine du projet :  
`/ml_pp_mvp/README.md` (remplace l’ancien si besoin)

Ainsi, il sera reconnu par Cursor **automatiquement**, et accessible à tous les développeurs humains.
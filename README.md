# 🚀 Projet : ML_PP MVP

**Objectif** : Application de gestion logistique pétrolière pour Monaluxe  
**Stack technique** : Flutter + Supabase + Riverpod + GoRouter + Clean Architecture

---

## 📊 Statut Global — Industrial Maturity (Feb 2026)

- GO PROD official (tag `go-prod-2026-01`)
- E2E business flow validated: CDR → Réception → Stock → Sortie
- Canonical stock source: `v_stock_actuel`
- Front live: https://monaluxe.app
- CI green (PR + Nightly)
- RLS hardening complete: 0 `{public}` policies

## 🏗️ Maturité Industrielle — Évaluation Structurée

| Domaine | Statut | Niveau |
|---------|--------|--------|
| Flux métier DB | Validé & Trigger-unified | 🟢 Stable |
| Sécurité RLS | 0 policy `{public}` | 🟢 Hardened |
| Exposition ANON REST | Neutralisée | 🟢 Secure |
| Gouvernance Git | PR obligatoire + CI verte | 🟢 Industriel |
| Documentation | Traçable & versionnée | 🟢 Mature |
| Infra Front | Firebase + SSL + DNS propre | 🟢 Stable |
| Tests Flutter | Majoritairement isolés | 🟡 Avancé |
| Tests DB triggers | Partiellement automatisés | 🟡 En consolidation |
| Guardrails CI sécurité | Non encore implémentés | 🟡 À implémenter |
| Monitoring métier | Phase 2 en cours | 🟡 En progression |

## 🎯 Conclusion Officielle

- 🟢 **Industriel opérationnel**
- 🟡 Industrialisation avancée en cours (Automation & Monitoring)
- Aucune dette critique connue à date de ce checkpoint.

## 📈 Historique de Maturité Industrielle

### 🔴 Phase Initiale — "Industriel : NO-GO" (Jan 2026)

Verdict conservative, orienté audit. Les axes A–D (DB-STRICT, Tests DB, Sécurité, Stabilisation) restaient ouverts. Risque identifié : policies `{public}` + exposition potentielle ANON REST.

📋 Rapport d'époque : [docs/90_ARCHIVE/RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md](docs/90_ARCHIVE/RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md)

### 🟡 Phase Transition — RLS Hardening (21 Feb 2026)

Audit STAGING + PROD ; migration `{public}` → `{authenticated}` ; curl ANON retourne vide sur tables sensibles. Documenté et mergé (PR #75, commit 7297c7c).

### 🟢 Phase Actuelle — Industriel Opérationnel (Late Feb 2026)

État actuel : RLS durci, front en exploitation. Restant : guardrails CI sécurité, automatisation tests DB triggers, monitoring métier Phase 2.

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

## 🚀 Déploiement PROD Web

ML_PP est en **PROD en exploitation** (GO LIVE acté). Le déploiement Web est manuel et contrôlé via le script officiel.

- **Runbook officiel** : [docs/02_RUNBOOKS/DEPLOY_WEB_PROD_RUNBOOK.md](docs/02_RUNBOOKS/DEPLOY_WEB_PROD_RUNBOOK.md)
- **Script** : `tools/release_web_prod.sh` (ne pas modifier)
- **Domaine** : https://monaluxe.app  
Chaque release doit être taguée (`prod-web-YYYYMMDD-HHMM`) après déploiement réussi.

---

## Environnement Web PROD

Le build Web PROD utilise **exclusivement** `--dart-define`.  
**dotenv est interdit** en production.

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

Ainsi, il sera reconnu par Cursor **automatiquement**, et accessible à tous les développeurs humains. pour la suite

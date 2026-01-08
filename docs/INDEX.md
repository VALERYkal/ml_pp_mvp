# 📚 Index de Documentation - ML_PP MVP

**Dernière mise à jour :** 31 décembre 2025

---

## 🎯 Documents Critiques (À lire en priorité)

### 1. **[Rapport de Synthèse Production](./RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md)** 🔴
- Verdict GO/NO-GO production
- État fonctionnel vs industriel
- Plan d'actions P0 détaillé

### 2. **[Plan Opérationnel 10 Points](./PLAN_OPERATIONNEL_PROD_READY_10_POINTS.md)** 🔴
- 10 critères de validation production (points, pas jours)
- Checklist détaillée avec tests SQL
- Effort estimé : 7-10 jours ouvrés pour P0

### 3. **[Sprint Prod-Ready](./SPRINT_PROD_READY_2025-12-31.md)** 🔴
- Sprint structuré en 4 axes (10-15 jours ouvrés)
- 11 tickets atomiques avec DoD
- Planning indicatif par jour
- Tableau de suivi GO/NO-GO

### 4. **[Suivi Sprint](./SUIVI_SPRINT_PROD_READY.md)** 🔴
- Tableau de bord simplifié
- Avancement par axe
- Journal quotidien

### 5. **[État Projet](./ETAT_PROJET_2025-12-31.md)**
- Snapshot actuel du projet
- Checkpoints par module
- Décision GO/NO-GO actuelle

### 6. **[PRD v4.0](./ML%20pp%20mvp%20PRD.md)**
- Spécifications produit complètes
- Architecture technique

---

## 📋 Documentation par Catégorie

### Architecture
- [Architecture Générale](./architecture.md)
- [Architecture Dashboards v3](./rapports/rapport_architecture_dashboards_v3.md)
- [Transaction Contract](./TRANSACTION_CONTRACT.md)

### Base de Données
- [Schéma Supabase](./schema_supabase.md)
- [DB Strict Migration Roadmap](./DB_STRICT_MIGRATION_ROADMAP.md)
- [Vues SQL Reference](./db/vues_sql_reference.md)
- [Vues SQL Reference Centrale](./db/vues_sql_reference_central.md)
- [Flutter DB Usage Map](./db/flutter_db_usage_map.md)
- [Migrations](../supabase/migrations/)

### Tests
- [Guide de Tests](./testing_guide.md)
- [Tests Auth Integration](./testing/auth_integration_tests.md)
- [DB Strict Tests](./DB_STRICT_MIGRATION_TESTS.md)
- [B2.2 Tests d'intégration DB STAGING](./tests/B2_2_INTEGRATION_DB_STAGING.md)

### Modules Métier
- [Cours de Route Modernization](./COURS_ROUTE_MODERNIZATION.md)
- [Module Réceptions](./rapports/rapport_modernisation_module_reception.md)
- [Module Sorties](./rapports/rapport_module_sorties_produit.md)
- [Stocks & KPI Phase 3](./rapports/PHASE3_STOCKS_KPI_COMPLETE_2025-12-06.md)

### Incidents & Bugs
- [Template Incident](./incidents/_TEMPLATE.md)
- [Bug Stocks Multi-Propriétaire](./incidents/BUG-2025-12-stocks-multi-proprietaire-incoherence.md)
- [Bug Citernes Provider Loop](./incidents/BUG-2025-12-citernes-provider-loop.md)
- [Bug Dashboard Stock Refresh](./incidents/BUG-2025-12-dashboard-stock-refresh-after-sortie.md)
- [Bug KPI Propriétaire Unification](./incidents/BUG-2025-12-stocks-kpi-proprietaire-unification.md)

### Release & Exploitation
- [Release Notes v2.0.0](../RELEASE_NOTES_v2.0.0.md)
- [Changelog](../CHANGELOG.md)
- [Troubleshooting](../TROUBLESHOOTING.md)

### Audits & Prod-Lock
- [Audit Réceptions Prod Lock](./AUDIT_RECEPTIONS_PROD_LOCK.md) ✅
- [Audit CDR Prod Freeze](./AUDIT_CDR_PROD_FREEZE.md) ✅
- [Audit Sorties Prod Lock](./modules/AUDIT_SORTIES_PROD_LOCK.md) ✅

---

## 🔄 Historique des États Projet

| Date | Document | Statut |
|------|----------|--------|
| 31/12/2025 | [Rapport Synthèse Production](./RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md) | 🟢 Fonctionnel / 🔴 Industriel |
| 31/12/2025 | [État Projet](./ETAT_PROJET_2025-12-31.md) | Mise à jour critique |
| 09/12/2025 | [État Projet](./ETAT_PROJET_2025-12-09.md) | Phase 3 Stocks KPI |

---

## 📊 Rapports Techniques

### Phases de Développement
- [Phase 1 - Stocks Stabilisation](./rapports/PHASE1_STOCKS_STABILISATION_2025-12-06.md)
- [Phase 2 - Stocks Normalisation](./rapports/PHASE2_STOCKS_NORMALISATION_2025-12-06.md)
- [Phase 3 - Stocks KPI Complète](./rapports/PHASE3_STOCKS_KPI_COMPLETE_2025-12-06.md)
- [Phase 3.2 - Exposition KPI Riverpod](./rapports/PHASE3_2_EXPOSITION_KPI_RIVERPOD_2025-12-06.md)

### Rapports d'Implémentation
- [Rapport Implementation Complète](./rapports/rapport_implementation_complete.md)
- [Rapport Module Cours de Route](./rapports/rapport_module_cours_de_route.md)
- [Rapport Pack Client Réceptions](./rapports/rapport_pack_client_receptions.md)
- [Rapport RLS](./rapports/rapport_rls.md)

---

## 🛠️ Guides Pratiques

### Développement
- [Checklist Dev](./checklist_dev.md)
- [Plan de Dev](./plan%20de%20dev.md)
- [Contexte Logique Métier](./contexte_logique_metie_ml_pp_mvp.md)

### Corrections & Fixes
- [Dashboard Cleanup Guide](./dashboard_cleanup_guide.md)
- [Import Conflict Fix](./import_conflict_fix_guide.md)
- [KPI Harmonisation Guide](./kpi_harmonisation_guide.md)
- [Locale Error Fix](./locale_error_fix_guide.md)

### Cache & Performance
- [Cache Purge Guide](../CACHE_PURGE_GUIDE.md)
- [Web Cache Purge Tools](../WEB_CACHE_PURGE_TOOLS.md)
- [Profil Loading States](../PROFIL_LOADING_STATES_GUIDE.md)

---

## 📖 User Stories & UX

- [User Stories Final](./user_stories_final.md)
- [UX/UI Wireframes](./ux_ui_wireframes.md)
- [Login Screen Implementation](./login_screen_implementation.md)

---

## 🔐 Sécurité & Contrat

- [Transaction Contract](./TRANSACTION_CONTRACT.md)
- [DB Strict Hardening](./DB_STRICT_HARDENING.md)
- [DB Strict Migration Roadmap](./DB_STRICT_MIGRATION_ROADMAP.md)

---

## 📂 Organisation

```
docs/
├── RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md (★ Critique)
├── PLAN_OPERATIONNEL_PROD_READY_10_POINTS.md (★ Critique)
├── SPRINT_PROD_READY_2025-12-31.md (★ Critique)
├── SUIVI_SPRINT_PROD_READY.md (★ Critique)
├── ETAT_PROJET_2025-12-31.md
├── INDEX.md (ce fichier)
├── architecture/
├── db/
├── incidents/
├── rapports/
├── testing/
└── ...
```

---

## 🎯 Navigation Rapide

**Pour les Décideurs :**
1. [Rapport Synthèse](./RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md)
2. [État Projet](./ETAT_PROJET_2025-12-31.md)

**Pour les Développeurs :**
1. [Sprint Prod-Ready](./SPRINT_PROD_READY_2025-12-31.md)
2. [Suivi Sprint](./SUIVI_SPRINT_PROD_READY.md)
3. [Checklist Dev](./checklist_dev.md)

**Pour les Auditeurs :**
1. [Rapport Synthèse](./RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md)
2. [Transaction Contract](./TRANSACTION_CONTRACT.md)
3. [DB Docs](./db/)

---

**Navigation :**
- [Retour README](../README.md)
- [Changelog](../CHANGELOG.md)
- [PRD](./ML%20pp%20mvp%20PRD.md)


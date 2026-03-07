# Checklist — Volumetrics Gate (ASTM)

**Référence** : ADR-2026-02-27-ASTM_DB_SOURCE_OF_TRUTH_RECEPTIONS.  
**Usage** : validation avant merge, avant prod, et post-prod. Réutilisable pour chaque livraison ASTM.

---

## Avant merge (Docs + tests + STAGING data)

| # | Item | Statut |
|---|------|--------|
| 1 | Documentation ADR / runbook à jour (décision, schéma cible, impacts) | ☐ |
| 2 | Tests unitaires moteur ASTM (golden cases) verts | ☐ |
| 3 | Tests d’intégration réceptions (B2.2 ou équivalent) verts sur STAGING | ☐ |
| 4 | Données STAGING : pas de dépendance bloquante sur ancien schéma (ou reset accepté) | ☐ |
| 5 | Aucune modification PROD ou script SQL PROD dans la PR | ☐ |
| 6 | CHANGELOG / entrée Unreleased mise à jour (décision, roadmap) | ☐ |

---

## Avant PROD (golden cases, approbations, backup, revue)

| # | Item | Statut |
|---|------|--------|
| 0 | **STAGING homogène** : un seul moteur volumétrique (lookup-grid) pour réceptions **et** sorties ; si STAGING hybride (réceptions=lookup-grid, sorties=golden) → NO-GO (voir `docs/POST_PROD/ASTM/2026-03-07_INVESTIGATION_STAGING_PROD_VOLUMETRIC_ALIGNMENT.md`) | ☐ |
| 1 | Golden cases / lookup-grid validés sur STAGING ; écart ML_PP vs référence ≤ tolérance (volume_15c) | ☐ |
| 2 | `volume_15c` NOT NULL sur toutes les réceptions validées (STAGING) | ☐ |
| 3 | Triggers stock (stocks_journaliers, snapshot) vérifiés avec volume_15c | ☐ |
| 4 | Backup PROD complet (schema + data) effectué et vérifié | ☐ |
| 5 | Fenêtre d’intervention définie ; saisie réception/sortie gelée pendant migration | ☐ |
| 6 | Approbation responsable technique / métier (validation terrain si applicable) | ☐ |
| 7 | PR / revue code : pas d’écart non documenté vs ADR | ☐ |
| 8 | Plan de rollback PROD lu et compris ; procédure documentée | ☐ |

---

## Investigation 2026-03-07 — Rappel décision

- **Résultat** : NO-GO migration PROD immédiate — STAGING non homogène (réceptions = lookup-grid, sorties = golden).
- **Cible** : Lookup-grid engine unique pour réceptions et sorties ; golden = validation uniquement.
- **Référence** : `docs/POST_PROD/ASTM/2026-03-07_INVESTIGATION_STAGING_PROD_VOLUMETRIC_ALIGNMENT.md`.

---

## Post PROD (monitoring, audit logs, sampling)

| # | Item | Statut |
|---|------|--------|
| 1 | Monitoring : pas d’erreur P0001 ou blocage RLS sur receptions | ☐ |
| 2 | Audit logs : log_actions contient rho_obs, rho_15, vcf, V15 pour nouvelles réceptions | ☐ |
| 3 | Sampling : N réceptions PROD comparées à SEP (écart ≤ 1 L) | ☐ |
| 4 | Stocks : cohérence stocks_journaliers / snapshot après opérations réelles | ☐ |
| 5 | Documentation post-intervention : date migration, hash commit, backup archivé | ☐ |
| 6 | Aucune réclamation terrain dans la fenêtre définie (ex. 24–48 h) | ☐ |

---

## STAGING — ASTM_APP Golden Engine Gate (Mode stabilité) — 2026-02-28

| # | Item | Statut |
|---|------|--------|
| 1 | Confirmer `SELECT * FROM public.app_settings WHERE key = 'env'` → retourne `value = 'staging'` | ☐ |
| 2 | Confirmer la présence du trigger `trg_receptions_compute_15c_before_ins` sur `public.receptions` | ☐ |
| 3 | Exécuter la requête de validation sur les 5 golden cases (v15_db vs volume_15c_ref_l) → match à l’unité (L) | ☐ |
| 4 | Test hors domaine : INSERT réception avec (densité ou température) hors enveloppe golden → erreur `RECEPTION_VOLUMETRICS_FAILED` avec message actionnable | ☐ |
| 5 | Confirmer absence de déploiement PROD de ce moteur (explicite) | ☐ |

---

**Notes** :  
- CDR : statuts en majuscules (CHARGEMENT, TRANSIT, FRONTIERE, ARRIVE, DECHARGE) si cités.  
- Réceptions / sorties : statuts `validee`, `rejetee` (minuscules, aligné DB actuel).

# Current Checkpoint — Volumetric Migration

## Date

Mars 2026

---

# Environment Status

## STAGING

- ASTM volumetric engine active
- lookup grid dataset installed
- golden dataset installed
- volumetric triggers active

---

## PROD

- ASTM volumetric engine active
- lookup grid dataset installed
- volumetric triggers active
- historical receptions recalculated

---

# Data State

PROD contient :

8 réceptions historiques.

Volumes approximatifs :

39291  
39296  
39391  
36971  
38312  
39330  
37383  
33445

Ces volumes correspondent à l’historique rejoué après migration ASTM (référence terrain / audit).

---

# Post volume_15c compatibility migration

État **après** migration colonne **`volume_15c`** sur **`sorties_produit`** (mode compatibilité, **sans** suppression de **`volume_corrige_15c`**) :

- Migration **STAGING** puis **PROD** exécutée et validée (triggers sorties, fonctions associées, double write **`volume_15c`** + **`volume_corrige_15c`**).
- **Flutter** aligné en **lecture** : **`volume_15c ?? volume_corrige_15c`** sur les zones concernées (KPI, repositories, providers sorties, ajustements de stock) ; écritures / modèles **non** entièrement unifiés (migration progressive documentée ailleurs).
- Système **exploitable en PROD** avec moteur volumétrique ASTM lookup-grid actif.
- **Test PROD** ponctuel sur sortie : exécuté puis **compensé** (`stocks_adjustments`) ; correction technique snapshot si besoin via **`stock_snapshot_apply_delta`** — pas de pollution durable du stock métier (**`v_stock_actuel`** reste la référence).

Références : `docs/00_REFERENCE/VOLUME_15C_MIGRATION_SUMMARY.md`, `docs/RUNBOOKS/RUNBOOK_VOLUME_15C_COMPAT_MIGRATION.md`, `docs/00_REFERENCE/VOLUME_15C_COMPATIBILITY_NOTE.md`.

---

# Migration Strategy (volumétrie ASTM — référence)

The ASTM volumetric migration has been completed.

Strategy executed: controlled purge of legacy transactions, then installation of ASTM schema, lookup grid dataset, volumetric functions and triggers, replay of the 8 historical receptions, reconstruction of stocks, system reopening.

The ASTM lookup-grid volumetric engine is active in production.

---

# Schéma et étapes (archive de haut niveau)

Les évolutions de schéma détaillées (colonnes densité, **`volume_15c` sorties**, etc.) sont consignées dans les scripts SQL versionnés et les documents **`docs/DB_CHANGES/`** / runbooks volumétrie.  
Phases typiques déjà couvertes : backup, purge contrôlée si applicable, schéma `astm`, datasets, fonctions, triggers, smoke tests, réouverture.

---

# Migration Result

Production is now aligned with staging on the ASTM lookup-grid volumetric runtime.

All receptions and stock calculations now use the new volumetric engine.

---

# Goal

Activer en production :

le moteur volumétrique lookup-grid conforme API MPMS 11.1.

(Goal achieved: the lookup-grid engine is now active in both STAGING and PROD.)

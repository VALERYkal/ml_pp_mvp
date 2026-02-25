# Runbook — Volumetrics ASTM 53B Migration (PROD)

**Document** : Procédure et checklist pour la migration volumétrique PROD vers ASTM 53B (Gasoil).  
**Version** : 1.0  
**Contexte** : ML_PP MVP en PROD — écart volumétrique confirmé (~50–70 L) vs app terrain ASTM ; gel des sorties jusqu'à completion.

---

## Purpose & Scope

- **Objectif** : Aligner le calcul volumétrique ML_PP sur la référence ASTM 53B, faire de ML_PP la source officielle pour les volumes@15.
- **Périmètre** : GASOIL uniquement ; 8 réceptions PROD ; 2 citernes.
- **Approche** : Moteur ASTM en Dart (fonctions pures) ; résultats stockés en DB ; contraintes/logs en garde-fou. Pas d'implémentation dans ce doc — définition uniquement.

---

## Definitions

| Terme | Définition |
|-------|------------|
| **Observed density** | Densité mesurée à la température ambiante (terrain). Actuellement stockée dans `densite_a_15` (misnomer). |
| **Density@15** | Densité corrigée à 15°C, calculée à partir de la densité observée + température. |
| **VCF** | Volume Correction Factor — facteur de correction du volume pour ramener à 15°C (ou 20°C selon convention). L'app ASTM l'affiche. |
| **Volume@15** | Volume corrigé à 15°C (volume_ambiant × VCF). |
| **Volume@20** | Volume corrigé à 20°C. Non implémenté pour l'instant ; support futur possible. |
| **ASTM 53B** | Table/code ASTM pour produits pétroliers (Gasoil) — conversion densité/température/volume. L'app terrain utilise cette référence. |

---

## Preconditions

1. **Freeze sorties** : Aucune sortie validée pendant l'opération.
2. **Confirmer absence factures/paiements** : Aucune facture fournisseur émise ; aucun paiement engagé.
3. **Tolérances** : ±0,1 % (volume et montant) pour détection d'anomalies.

---

## Phases (Step-by-Step)

### Phase 1 — Backup (required)

- Créer un backup complet PROD avant toute modification.
- Valider le backup (`pg_restore -l` ou équivalent).
- **STOP gate** : Pas de changement DB tant que le backup n'est pas validé.

### Phase 2 — Data Export (required)

- Exporter les 8 réceptions concernées (id, citerne_id, produit_id, volume_ambiant, temperature_ambiante_c, densite_a_15, volume_corrige_15c, etc.).
- Sauvegarder l'export pour référence et rollback.

### Phase 3 — Build ASTM Engine (Dart) + Golden Tests (required)

- Implémenter le moteur ASTM 53B en Dart (fonctions pures).
- Créer un jeu de tests golden (20–30 cas) validés contre l'app ASTM ou des tableaux de référence.
- **Cible** : Suite de tests verte avant simulation.

### Phase 4 — Simulation Report (required)

- Appliquer le moteur sur les 8 réceptions (mode simulation, sans écriture DB).
- Générer un rapport : volumes avant/après, écarts, VCF calculés.
- **STOP gate** : Rapport approuvé avant toute migration.
- Tolérance : VCF et Volume@15 dans ±0,1 % vs app ASTM.

### Phase 5 — Migration Execution (DB updates)

- Mise à jour conceptuelle : modifier les 8 lignes `receptions` avec les nouveaux volumes calculés (volume_corrige_15c, et éventuellement densite_a_15 corrigée selon décision sémantique).
- Aucune implémentation SQL dans ce runbook — à définir dans une spec d'implémentation.
- **Logging** : Enregistrer un événement global `VOLUMETRICS_METHOD_MIGRATION_ASTM53B_V1` dans `log_actions` (nom défini ; non implémenté ici).

### Phase 6 — Stock Rebuild (conceptual)

- Recalculer les stocks par citerne à partir des réceptions migrées et des sorties existantes.
- Mécanisme à définir (trigger, script, ou recalcul via `stocks_journaliers` / `v_stock_actuel` selon l'architecture).

### Phase 7 — Verification Checklist

- VCF calculé vs app ASTM : dans tolérance.
- Volume@15 vs app ASTM : dans tolérance.
- Stock par citerne : réconciliation OK.
- Sorties : dégel autorisé.

### Phase 8 — Rollback Plan

- En cas d'anomalie : restore depuis le backup.
- Re-freeze des opérations (sorties) jusqu'à nouvelle décision.

---

## BLOC 2 — Progression

### Étape A — Squelette moteur ASTM 53B
- Objectif : poser les types et le contrat (Astm53bInput, Astm53bResult, Astm53bCalculator).
- Fichier : `lib/core/volumetrics/astm53b_engine.dart`
- Statut : **terminé**.

### Étape B — Dataset golden ASTM 53B
- Objectif : créer la structure des cas de référence pour valider le moteur ASTM 53B.
- Fichiers introduits :
  - `lib/core/volumetrics/astm53b_golden_cases.dart`
  - `test/core/volumetrics/astm53b_golden_test.dart`
- Statut : **terminé**.
- Remarque : Les valeurs golden sont temporaires ; calibration prévue Étape C.

### Étape C — Calibration moteur
- Objectif : implémentation formule ASTM 53B + calibration sur cas terrain.
- Statut : **✅ DONE (MERGED)**.
- Aucune intégration métier, aucune migration DB, aucun recalcul stock (pas encore).

**Evidence / Proof** :
- **Tag** : `volumetrics-calibrated-15c-2026-02-24`
- **Commande de test** : `flutter test test/core/volumetrics/astm53b_engine_test.dart test/core/volumetrics/astm53b_golden_test.dart -r expanded`
- **Golden dataset** : 8 cases GASOIL PROD (source SEP)

---

## STAGING — Validation & hygiène

### Reset STAGING (CDR only) — étape préalable recommandée

Avant une campagne de validation ASTM ou tests d'intégration B2.2, il est recommandé de repartir d'une base STAGING propre (sans données historiques de réceptions/sorties/stocks).

- **Script SQL rejouable** : [docs/DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql](../DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql)
- **Invariant** : `cours_de_route` est préservé ; seules les tables de mouvement stock sont purgées (receptions, sorties_produit, stocks_journaliers, log_actions scopés).
- **DB-STRICT** : Le script applique le patch `receptions_block_update_delete` (flag `app.receptions_allow_write`) puis exécute la purge dans une transaction avec les trois flags (receptions, sorties_produit, stocks_journaliers). STAGING only.

---

## Next (BLOC 3)

- Intégration contrôlée via feature flag (OFF par défaut).
- Plan migration DB : renommer `densite_a_15` / séparer densité observée vs densité@15.
- Stratégie de rollout : staging d'abord.

---

## Acceptance Criteria

- VCF matches field app within ±0,1 %.
- Volume@15 matches within ±0,1 %.
- Stock per citerne reconciles.
- Sorties can resume safely.

---

## Logging Requirement

- Enregistrer un événement global : `VOLUMETRICS_METHOD_MIGRATION_ASTM53B_V1` (nom défini ; implémentation à prévoir en `log_actions`).

---

## Post-Migration Notes

- **Futur** : Étendre à ASTM 54B si autres produits apparaissent.
- **Finance** : Le module Finance dépend de la stabilisation de ce socle volumétrique.

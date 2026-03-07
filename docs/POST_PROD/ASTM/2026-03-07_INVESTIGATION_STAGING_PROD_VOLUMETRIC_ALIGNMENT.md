# Investigation technique — Alignement volumétrique STAGING / PROD (7 mars 2026)

**Date** : 2026-03-07  
**Périmètre** : Audit STAGING et PROD — moteurs volumétriques, triggers, schéma.  
**Résultat** : **NO-GO migration PROD immédiate** — STAGING non homogène.  
**Nature** : Documentation uniquement — aucune migration PROD exécutée, aucune fonction SQL modifiée, aucune logique métier modifiée.

---

## 1. Objectif

L’investigation du 7 mars 2026 avait pour but de :

- Préparer une migration volumétrique PROD ;
- Vérifier l’état STAGING (moteurs, triggers, données) ;
- Comparer les moteurs ASTM présents en STAGING ;
- Confirmer la cible technique finale ;
- Identifier les écarts STAGING / PROD ;
- Décider si la migration PROD devait être lancée.

**Conclusion** : La migration PROD ne doit pas être lancée. STAGING n’est pas encore homogène (deux moteurs distincts : réceptions = lookup-grid, sorties = golden).

---

## 2. Méthode d’investigation

- Audit PROD : backup complet, vérification `pg_restore --list`, comptages des tables métier, présence du schéma ASTM et des objets volumétriques.
- Audit STAGING : identification des moteurs volumétriques (golden engine vs lookup-grid engine), objets DB associés, branchement réel des triggers sur `receptions` et `sorties_produit`.
- Analyse des triggers : ordre d’exécution, fonction appelée par chaque trigger.
- Comparaison schéma : colonnes présentes en STAGING vs PROD pour `receptions` et `sorties_produit`.
- Tests comparatifs : même entrée (volume, densité, température) passée au moteur golden et au moteur lookup-grid ; comparaison des résultats.
- Décision : GO / NO-GO migration PROD, décision intermédiaire (moteur cible unique), prochaines étapes.

---

## 3. Audit PROD

L’audit PROD a été réalisé avec succès.

### Backup

- **Backup complet effectué** : `backups/ml_pp_prod_J0_pre_volumetric_engine.dump`
- **Vérification** : `pg_restore --list` OK

### Comptages PROD

| Table              | Comptage |
|--------------------|----------|
| receptions         | 8        |
| sorties_produit    | 0        |
| stocks_journaliers| 3        |
| stocks_snapshot    | 2        |

### Schéma ASTM

- **Schéma ASTM** : absent en PROD.

### Tables

- **astm_golden_cases_15c** : absente en PROD.

### Triggers volumétriques ASTM

- **Triggers volumétriques ASTM** : absents en PROD.

### Tables métier PROD

- **Immutabilité** : UPDATE / DELETE interdits sur les tables métier concernées.

---

## 4. Données historiques PROD

Sur les **8 réceptions** PROD :

- **Colonnes observées** : `volume_ambiant`, `temperature_ambiante_c`, `densite_a_15`, `volume_corrige_15c`.
- **volume_15c** : NULL.

**Interprétation** : L’ancien pipeline utilisait `volume_corrige_15c` uniquement. La colonne `volume_15c` n’était pas utilisée.

---

## 5. Audit STAGING — Moteurs volumétriques

Deux moteurs volumétriques distincts ont été identifiés en STAGING.

### Moteur 1 — Golden engine

**Objets** :

- `public.astm_golden_cases_15c`
- `astm.ctl_from_golden`
- `astm.compute_15c_from_golden`
- `astm.fn_sortie_compute_golden_15c`

**Domaine du golden dataset** :

- Densité : 836 → 837,6 kg/m³
- Température : 19 → 29,7 °C
- **Nombre de lignes** : 8

**Problème** : Domaine trop étroit. Certaines densités observées terrain (839 → 843) ne sont pas couvertes.

---

### Moteur 2 — Lookup-grid engine

**Objets** :

- `public.astm_lookup_grid_15c`
- `astm.lookup_15c_exact`
- `astm.lookup_15c_bilinear`
- `astm.lookup_15c_bilinear_v2`
- `astm.compute_v15_from_lookup_grid`

**Batch actif** :

- `source = ASTM_OFFICIAL_APP`
- `produit_code = GASOIL`
- `method_version = API_MPMS_11_1`
- `batch_id = GASOIL_P0_2026-02-28`

**Domaine couvert** :

- Densité : 820 → 860 kg/m³
- Température : 10 → 40 °C

**Grille** :

- **Densités** : 820, 825, 830, 835, 840, 845, 850, 855, 860
- **Températures** : 10, 15, 20, 22, 25, 30, 40
- **Total lignes** : 63

La grille est régulière et complète.

---

## 6. Branchement réel STAGING

### Réceptions

- **Trigger** : `public.receptions_compute_15c_before_ins`
- **Fonction utilisée** : `astm.compute_v15_from_lookup_grid`
- **Conclusion** : Réceptions = **lookup-grid**.

### Sorties

- **Trigger** : `trg_00_sorties_compute_golden_15c`
- **Fonction utilisée** : `astm.compute_15c_from_golden`
- **Conclusion** : Sorties = **golden**.

### Synthèse

**STAGING est hybride** :

- **Réceptions** → lookup-grid
- **Sorties** → golden

---

## 7. Analyse des triggers (sorties)

### Ordre actuel des triggers sur sorties_produit

1. `trg_00_sorties_compute_golden_15c`
2. `trg_00_sorties_set_created_by`
3. `trg_01_sorties_set_volume_ambiant`
4. `trg_sorties_check_produit_citerne`
5. `trg_sortie_before_ins`
6. `trg_sorties_after_insert`

**Problème** : Le calcul volumétrique est exécuté **avant** le calcul de `volume_ambiant`. Le trigger `trg_00_sorties_compute_golden_15c` s’exécute en premier, alors que `volume_ambiant` est calculé par `trg_01_sorties_set_volume_ambiant`.

### Ordre recommandé

1. `trg_00_sorties_set_created_by`
2. `trg_01_sorties_set_volume_ambiant`
3. `trg_02_sorties_compute_lookup_15c` (calcul volumétrique après volume_ambiant)
4. `trg_sorties_check_produit_citerne`
5. `trg_sortie_before_ins`
6. `trg_sorties_after_insert`

---

## 8. Différence schéma STAGING / PROD

### Réceptions

**STAGING possède, PROD ne possède pas** :

- `densite_observee_kgm3`
- `densite_a_15_kgm3`
- `densite_a_15_g_cm3`

### Sorties

**STAGING possède, PROD ne possède pas** :

- `densite_a_15_kgm3`
- `densite_a_15_g_cm3`

---

## 9. Tests comparatifs

### Test golden

- **Entrée** : volume = 1000 L, densité = 837 kg/m³, température = 19 °C
- **Résultat** : `volume_corrige_15c = 997` L

### Test lookup-grid

- **Résultats observés** : `densite_a_15_kgm3 = 839,7`, VCF = 0,9966, `volume_15c = 996,6` L

### Écart entre les deux moteurs

- **Écart** : ≈ 0,4 L (997 vs 996,6).
- **Conclusion** : Les deux moteurs sont cohérents. Le lookup-grid est plus robuste (domaine plus large, grille régulière).

---

## 10. Analyse technique

- **Homogénéité STAGING** : STAGING utilise deux moteurs différents selon la table (réceptions vs sorties). Pour une migration PROD maîtrisée et un comportement déterministe, un **moteur unique** est requis.
- **Cible technique retenue** : **Lookup-grid engine** comme moteur unique pour réceptions et sorties. Domaine 820–860 kg/m³ et 10–40 °C couvre les densités terrain observées (839–843).
- **Golden engine** : À conserver comme **outil de validation uniquement**, pas comme moteur en production.
- **Ordre des triggers sorties** : L’ordre actuel exécute le calcul volumétrique avant la mise à jour de `volume_ambiant` ; un réordonnancement (calcul volumétrique après `volume_ambiant`) est recommandé pour cohérence et maintenabilité.
- **Écart schéma** : PROD devra recevoir les colonnes volumétriques (`densite_observee_kgm3`, `densite_a_15_kgm3`, `densite_a_15_g_cm3` sur réceptions ; `densite_a_15_kgm3`, `densite_a_15_g_cm3` sur sorties) et le schéma ASTM (lookup-grid) dans le cadre d’une migration documentée et validée.

---

## 11. Décision

### NO-GO migration PROD immédiate

**Raison** : STAGING non homogène. Moteurs volumétriques différents selon la table (réceptions = lookup-grid, sorties = golden). La migration PROD ne doit pas être lancée tant que STAGING n’est pas aligné sur un moteur unique et revalidé.

### Décision intermédiaire

- **Objectif cible** : **Lookup-grid engine unique** pour réceptions **et** sorties.
- **Golden engine** : Outil de validation uniquement, pas moteur de production.

---

## 12. Prochaines étapes

1. **Basculer les sorties STAGING** vers `astm.compute_v15_from_lookup_grid` (remplacer l’usage du golden engine par le lookup-grid pour les sorties).
2. **Revalider STAGING** : vérifier réceptions et sorties avec le même moteur (lookup-grid), contrôler ordre des triggers et cohérence des volumes.
3. **Préparer la migration PROD** : une fois STAGING homogène et revalidé, mettre à jour le runbook PROD, la checklist et la stratégie d’intervention (schéma, colonnes, backup, fenêtre).

---

## Confirmation — Documentation uniquement

Ce document atteste que :

- **Aucune migration PROD** n’a été exécutée à l’issue de cette investigation.
- **Aucune fonction SQL** n’a été modifiée.
- **Aucune logique métier** n’a été modifiée.
- **Seule la documentation** a été créée ou mise à jour (ce fichier et les références listées dans le CHANGELOG et les runbooks).

---

**Document créé** : 2026-03-07  
**Référence** : Investigation technique — Alignement volumétrique STAGING / PROD.

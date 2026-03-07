# Investigation — Volumetric Engine Alignment (STAGING vs PROD)

**Date** : 2026-03-07  
**Périmètre** : Audit PROD et STAGING, décision technique, migration STAGING sorties vers lookup-grid.  
**Résultat** : STAGING homogène (lookup-grid unique). Migration PROD **non exécutée**.

---

## 1. Contexte

Le projet **ML_PP MVP** (Monaluxe Petrol Platform) est un ERP pétrolier industriel utilisant Flutter Web et Supabase Postgres. Le **calcul volumétrique carburant** (conversion vers volume standard à 15°C) est un point critique métier : il impacte les réceptions, les sorties, les stocks et la traçabilité. L’alignement avec la norme **API MPMS 11.1 / ASTM Table 53B** vise une conformité industrielle et une cohérence avec les références terrain.

En amont de l’investigation, des **écarts terrain** de l’ordre de **~50 à 70 L** avaient été constatés entre les volumes calculés par l’application et les références (ex. outil SEP ou oracle terrain), liés notamment à la sémantique des densités (densité observée vs densité à 15°C) et à un calcul non centralisé côté base.

L’objectif de l’investigation et des corrections STAGING est de **stabiliser le moteur volumétrique côté DB** (triggers, fonctions ASTM, convention litre entier) avant toute migration PROD.

---

## 2. Audit PROD

### Backup réalisé

- **Fichier** : `backups/ml_pp_prod_J0_pre_volumetric_engine.dump`
- **Vérification** : `pg_restore --list` OK

### Résultats audit

| table              | rows |
|--------------------|------|
| receptions         | 8    |
| sorties_produit    | 0    |
| stocks_journaliers | 3    |
| stocks_snapshot    | 2    |

### Observations

- Schéma **`astm`** absent en PROD.
- Aucun trigger volumétrique actif en PROD.
- Colonne **`volume_15c`** : NULL sur les réceptions existantes.
- L’ancien pipeline utilisait **`volume_corrige_15c`** uniquement.

### Conclusion

PROD est **stable et figé**. Aucune migration volumétrique n’a été exécutée sur la base PROD.

---

## 3. Investigation STAGING

Deux moteurs volumétriques distincts ont été identifiés en STAGING.

### Golden Engine

**Tables**

- `public.astm_golden_cases_15c`

**Fonctions**

- `astm.ctl_from_golden`
- `astm.compute_15c_from_golden`
- `astm.fn_sortie_compute_golden_15c`

**Domaine**

- Densité : 836 → 837,6 kg/m³
- Température : 19 → 29,7 °C
- **rows** : 8

**Limite**

- Dataset trop restreint : certaines densités observées terrain (839 → 843) ne sont pas couvertes.

---

### Lookup Grid Engine

**Tables**

- `public.astm_lookup_grid_15c`

**Fonctions**

- `astm.lookup_15c_exact`
- `astm.lookup_15c_bilinear`
- `astm.lookup_15c_bilinear_v2`
- `astm.compute_v15_from_lookup_grid`

**Batch actif**

- `GASOIL_P0_2026-02-28` (source ASTM_OFFICIAL_APP, produit_code GASOIL, method_version API_MPMS_11_1)

**Domaine**

- Densité : 820 → 860 kg/m³
- Température : 10 → 40 °C
- **rows** : 63

**Conclusion**

- Le lookup-grid couvre l’ensemble du domaine opérationnel et est plus robuste pour la production.

---

## 4. Branchement STAGING avant correction

**Réceptions** : branchées sur le **lookup-grid** (trigger `receptions_compute_15c_before_ins`, fonction `astm.compute_v15_from_lookup_grid`).

**Sorties** : branchées sur le **golden engine** (trigger `trg_00_sorties_compute_golden_15c`, fonction `astm.fn_sortie_compute_golden_15c`).

**Conclusion**

- STAGING était **hybride** (réceptions = lookup-grid, sorties = golden).
- Décision : **NO-GO PROD** tant que STAGING n’est pas homogène.

---

## 5. Test comparatif moteurs

**Entrée commune**

- volume = 1000 L  
- densité = 837 kg/m³  
- température = 19 °C  

**Résultat Golden** : 997 L  

**Résultat Lookup-grid** : 996,6 L  

**Écart** : ≈ 0,4 L  

**Conclusion** : Les deux moteurs sont cohérents. Le lookup-grid est retenu comme moteur unique pour homogénéiser STAGING.

---

## 6. Problème d’ordre de triggers

**Ordre initial (sorties)**

1. `trg_00_sorties_compute_golden_15c`
2. `trg_00_sorties_set_created_by`
3. `trg_01_sorties_set_volume_ambiant`
4. …

**Problème**

- Le calcul volumétrique était exécuté **avant** le calcul du volume ambiant. Le trigger volumétrique s’exécutait en premier, alors que `volume_ambiant` est calculé par `trg_01_sorties_set_volume_ambiant`, ce qui pouvait conduire à des incohérences ou à une dépendance incorrecte aux valeurs déjà présentes en entrée.

**Correction**

- Réordonnancement : le trigger de calcul 15°C doit s’exécuter **après** `trg_01_sorties_set_volume_ambiant` (nouveau trigger `trg_02_sorties_compute_lookup_15c`).

---

## 7. Décision technique

**Cible**

- **Lookup-grid** pour :
  - réceptions (déjà en place)
  - sorties (à migrer)

**Golden engine**

- Conservé comme **outil de validation uniquement**, pas comme moteur de production pour les écritures.

---

## 8. Migration STAGING exécutée le 7 mars 2026

**Actions réalisées**

- Suppression du trigger golden sorties :  
  `DROP TRIGGER IF EXISTS trg_00_sorties_compute_golden_15c ON public.sorties_produit;`
- Création de la fonction :  
  `public.sorties_compute_15c_before_ins_lookup()`  
  (BEFORE INSERT ; lecture `app_settings.env` avec blocage hors STAGING ; garantie de `volume_ambiant` ; exigence de `temperature_ambiante_c` ; utilisation de `new.densite_a_15_kgm3` comme entrée legacy / densité observée ; appel à `astm.compute_v15_from_lookup_grid(...)` ; écriture de `volume_corrige_15c`, `densite_a_15_kgm3`, `densite_a_15_g_cm3`).
- Création du trigger :  
  `trg_02_sorties_compute_lookup_15c`  
  (BEFORE INSERT sur `public.sorties_produit`, exécution après `trg_01_sorties_set_volume_ambiant` pour respecter l’ordre voulu).

**Convention retenue**

- Volume 15°C = **litre entier** (aligné réceptions et comportement historique sorties).  
  `new.volume_corrige_15c := round(r.volume_15c_l);`

---

## Centralized lookup-grid domain guard

Après la migration STAGING des sorties vers le lookup-grid (section 8), une amélioration de robustesse a été introduite : un **garde-fou centralisé du domaine** du batch lookup-grid, branché sur les triggers réceptions et sorties.

### a) Pourquoi ce garde-fou a été ajouté

- Le moteur lookup-grid fonctionnait déjà (réceptions et sorties) et rejetait correctement les entrées hors domaine via la fonction d’interpolation (ex. `ASTM_BILINEAR_OUT_OF_DOMAIN_DENS`).
- Le contrôle du domaine restait toutefois **implicite** : il était réalisé à l’intérieur de la fonction de calcul (`astm.compute_v15_from_lookup_grid` ou les sous-fonctions de lookup), sans lecture centralisée des bornes du batch.
- Un garde-fou **centralisé** améliore :
  - **lisibilité** : une seule source de vérité pour le domaine du batch actif
  - **stabilité des erreurs** : messages d’erreur homogènes et explicites (produit, source, method, batch, borne dépassée)
  - **maintenabilité** : évolution du domaine (nouveau batch, extension de grille) sans disperser la logique dans les triggers
  - **réutilisabilité** : les triggers réceptions et sorties appellent la même assertion avant le calcul

### b) Les deux fonctions ajoutées

**`astm.lookup_grid_domain(p_produit_code text, p_source text, p_method_version text, p_batch_id text)`**

- **But** : Retourner les bornes du domaine du batch lookup-grid actif (lecture centralisée à partir de la table `astm_lookup_grid_15c`).
- **Inputs** : `p_produit_code`, `p_source`, `p_method_version`, `p_batch_id` (ex. GASOIL, ASTM_OFFICIAL_APP, API_MPMS_11_1, GASOIL_P0_2026-02-28).
- **Outputs** : `dens_min`, `dens_max`, `temp_min`, `temp_max`, `rows_count`.
- **Intérêt architectural** : Point d’entrée unique pour connaître le domaine opérationnel du batch ; utilisable en diagnostic, tests et par la fonction d’assertion.

**`astm.assert_lookup_grid_domain(p_produit_code text, p_source text, p_method_version text, p_batch_id text, p_temperature_c double precision, p_densite_observee_kgm3 double precision)`**

- **But** : Vérifier qu’un couple (température, densité observée) est dans le domaine du batch actif ; lever une erreur claire si hors domaine.
- **Inputs** : identifiants du batch (produit_code, source, method_version, batch_id) + `p_temperature_c`, `p_densite_observee_kgm3`.
- **Comportement** : lit le domaine via la logique du batch (ou appelle `lookup_grid_domain`), compare les valeurs ; en cas de sortie de domaine, lève une exception avec message standardisé (ex. `ASTM_LOOKUP_OUT_OF_DOMAIN_DENS`).
- **Intérêt architectural** : Les triggers n’ont plus à dupliquer la logique de contrôle ; ils appellent `assert_lookup_grid_domain` avant `compute_v15_from_lookup_grid`, ce qui évite d’appeler le moteur avec des valeurs impossibles.

### c) Branchement sur réceptions et sorties

- **`public.receptions_compute_15c_before_ins()`** : appelle désormais **`astm.assert_lookup_grid_domain(...)`** (avec les paramètres du batch actif et les champs température / densité observée de `NEW`) **avant** **`astm.compute_v15_from_lookup_grid(...)`**. En cas de hors domaine, l’INSERT est rejeté avec l’erreur centralisée.
- **`public.sorties_compute_15c_before_ins_lookup()`** : fait de même : appel à **`astm.assert_lookup_grid_domain(...)`** avant **`astm.compute_v15_from_lookup_grid(...)`**, avec les mêmes identifiants de batch (GASOIL, ASTM_OFFICIAL_APP, API_MPMS_11_1, GASOIL_P0_2026-02-28).

Réceptions et sorties partagent ainsi la même logique de validation de domaine.

### d) Domaine confirmé

Pour le batch actif **GASOIL_P0_2026-02-28** (produit_code GASOIL, source ASTM_OFFICIAL_APP, method_version API_MPMS_11_1), le domain guard confirme :

- **Densité (observée)** : 820 → 860 kg/m³  
- **Température** : 10 → 40 °C  
- **rows_count** : 63  

(Valeurs obtenues via `select * from astm.lookup_grid_domain(...)`.)

### e) Test hors domaine

Un test volontairement hors domaine a été exécuté :

- **Entrée** : densité observée = **900** kg/m³, température = 19 °C, batch GASOIL lookup-grid.
- **Résultat attendu et obtenu** : rejet de l’INSERT avec erreur centralisée.

**Message d’erreur obtenu**

```
ASTM_LOOKUP_OUT_OF_DOMAIN_DENS: produit=GASOIL source=ASTM_OFFICIAL_APP method=API_MPMS_11_1 batch=GASOIL_P0_2026-02-28 dens=900 outside [820,860]
```

Le garde-fou centralisé fournit un message explicite (produit, source, method, batch, valeur et borne), ce qui facilite le diagnostic et l’extension éventuelle de la grille.

### f) Conclusion

- Le moteur lookup-grid STAGING est maintenant **protégé par un garde-fou centralisé** : lecture du domaine et assertion avant calcul sont déléguées à `astm.lookup_grid_domain` et `astm.assert_lookup_grid_domain`.
- **Réceptions** et **sorties** partagent la même logique de validation de domaine ; les erreurs hors domaine sont standardisées.
- **Aucune migration PROD n’a été exécutée** : cette évolution concerne uniquement STAGING.

---

## 9. Validation fonctionnelle

**Smoke test**

- **sortie_id** : `0eaa2cc8-5ccc-484d-9358-5176f698ec7e`

**Entrée**

- volume = 1000 L  
- température = 19 °C  
- densité (observée) = 837 kg/m³  

**Résultat**

- **volume_corrige_15c** = 997 L  
- **Densité à 15°C** : 839,7 kg/m³  

La sortie a été créée et validée ; le trigger lookup-grid calcule correctement le volume à 15°C et la densité dérivée.

---

## 10. Validation hors domaine (lookup-grid)

Afin de confirmer la robustesse du moteur volumétrique lookup-grid, un test volontairement **hors domaine ASTM** a été exécuté.

**Entrée utilisée**

- volume_ambiant = 1000  
- temperature_c = 19  
- densite_observee_kgm3 = 900  

Cette densité est volontairement hors du domaine couvert par la grille lookup-grid.

**Domaine lookup-grid actuel**

- densité : 820 → 860  
- température : 10 → 40  

**Requête exécutée**

```sql
insert into public.sorties_produit (
  citerne_id,
  produit_id,
  client_id,
  index_avant,
  index_apres,
  temperature_ambiante_c,
  densite_a_15_kgm3,
  proprietaire_type,
  statut,
  date_sortie,
  note
)
values (
  '57da330a-1305-4582-be45-ceab0f1aa795',
  '22222222-2222-2222-2222-222222222222',
  '8ad6ef76-e45c-4159-a145-62df52563881',
  0,
  1000,
  19,
  900,
  'MONALUXE',
  'validee',
  now(),
  'SMOKE_TEST_LOOKUP_SORTIE_OUT_OF_DOMAIN_DENS_2026_03_07'
);
```

**Résultat**

- **ERROR** : `SORTIE_VOLUMETRICS_FAILED`  
- **Cause** : `ASTM_BILINEAR_OUT_OF_DOMAIN_DENS: dens=900`

**Message complet**

```
SORTIE_VOLUMETRICS_FAILED: cannot compute Volume@15 using LOOKUP-GRID engine.
Inputs: volume_ambiant=1000, densite_obs_kgm3=900, temp_c=19.
Cause: ASTM_BILINEAR_OUT_OF_DOMAIN_DENS: dens=900.
Action: ensure (temp,dens) is inside lookup grid domain (or expand the grid), then retry.
```

**Conclusion**

Le moteur lookup-grid rejette correctement toute entrée hors domaine et fournit un message d’erreur explicite permettant :

- d’identifier immédiatement la cause  
- de corriger les données terrain  
- ou d’étendre la grille ASTM si nécessaire  

Ce comportement est conforme aux attentes pour un moteur volumétrique industriel.

---

## 11. Validation pipeline aval

**Snapshot avant sortie**

- Stock (ambiant / 15°C) : 144753 / 144057,63

**Snapshot après sortie validée**

- Stock : 143753 / 143060,63

**Débit confirmé**

- −1000 L ambiant  
- −997 L @15°C  

**Log enregistré**

- `SORTIE_VALIDE` (ou équivalent) présent dans `log_actions` avec les détails attendus (volume_15c, citerne, etc.).

**Conclusion**

- Pipeline complet OK : snapshot, stocks et logs sont cohérents avec la sortie validée.

---

## 12. État final STAGING

- **Réceptions** : lookup-grid  
- **Sorties** : lookup-grid  

**Golden engine**

- Utilisé en **validation uniquement** (tests, comparaisons), pas pour les écritures métier.

**Conclusion**

- STAGING est maintenant **homogène** (moteur unique lookup-grid pour réceptions et sorties).

---

## 13. Alignement front Dart (formulaire et service sorties)

Après validation du moteur lookup-grid STAGING côté DB, un correctif ciblé a été appliqué côté Flutter/Dart pour supprimer les incohérences entre l’UI, le service et le comportement DB-first.

**Problème observé**

- L’UI affichait déjà « Densité observée (kg/m³) » en STAGING, mais la validation formulaire restait sur l’ancienne plage 0,7 → 1,1 (g/cm³), ce qui rejetait une saisie valide comme 830.
- Le service `createValidated(...)` reconstruisait encore `volume_corrige_15c = volumeCorrige15C ?? volumeAmbiant` et l’envoyait dans le payload, alors qu’en STAGING c’est le trigger DB qui doit calculer `volume_corrige_15c` à l’INSERT.

**Risque**

- Incohérence front ↔ DB : l’utilisateur saisit en kg/m³, le service envoyait un volume 15°C artificiel, et l’aperçu UI pouvait afficher une estimation locale non canonique.

**Corrections appliquées (Dart uniquement, aucun changement SQL)**

- **Formulaire** (`sortie_form_screen.dart`) : en STAGING, validation densité sur la plage 820 → 860 kg/m³ ; messages et helper text alignés sur le domaine lookup-grid ; hors STAGING, comportement legacy 0,7 → 1,1 inchangé.
- **Service** (`sortie_service.dart`) : en STAGING, le payload de `createValidated(...)` n’inclut plus `volume_corrige_15c` ; le trigger DB calcule cette valeur à l’enregistrement ; hors STAGING, comportement legacy inchangé.
- **Aperçu volume 15°C** : en STAGING, plus d’estimation numérique locale ; affichage d’un message explicite du type « Volume 15°C : calculé à l’enregistrement par le moteur ASTM » ; `calcV15(...)` n’est plus utilisé pour l’affichage en STAGING.
- **Tests** : ajout/ajustement dans `sortie_service_test.dart` et `sortie_form_screen_test.dart` pour couvrir UI densité STAGING/non-STAGING, payload avec/sans `volume_corrige_15c` selon `isStaging`, et texte volume 15°C STAGING.

**Portée**

- Correctif **front et service Dart uniquement**. Aucun changement de trigger, de fonction SQL ou de schéma. Aucune migration PROD exécutée.
- Résultat : cohérence front ↔ DB-first restaurée en STAGING avant préparation du runbook PROD opératoire.

---

## 14. Suite

**Avant migration PROD**

- Documentation complète (ce document, runbook STAGING, checklist ASTM, runbook migration PROD).
- Checklist ASTM à jour (STAGING homogène, backup PROD, etc.).
- Runbook migration PROD à jour (préconditions, procédure, rollback).
- Préparation du schéma PROD (colonnes volumétriques, schéma ASTM, triggers) dans le cadre d’une release planifiée.

**Migration PROD**

- **Non exécutée.** La base PROD n’a pas été modifiée. Toute migration PROD fera l’objet d’une procédure dédiée, d’un backup validé et d’une fenêtre d’intervention formalisée.

---

**Document mis à jour** : 2026-03-07  
**Référence** : Investigation — Volumetric Engine Alignment (STAGING vs PROD) + migration STAGING sorties lookup-grid.

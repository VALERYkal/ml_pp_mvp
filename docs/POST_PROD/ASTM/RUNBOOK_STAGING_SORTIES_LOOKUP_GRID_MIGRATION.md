# Runbook — STAGING Sorties Lookup Grid Migration

**Date** : 2026-03-07  
**Périmètre** : STAGING uniquement  
**Objectif** : Documenter la migration des sorties du moteur golden vers le moteur lookup-grid pour homogénéiser STAGING.

---

## 1. Objectif

Corriger l’**incohérence STAGING** : les réceptions utilisaient le moteur lookup-grid tandis que les sorties utilisaient le moteur golden, ce qui rendait l’environnement hybride et bloquait toute décision GO pour la migration PROD. La migration documentée ici aligne les sorties sur le même moteur que les réceptions (lookup-grid).

---

## 2. Contexte

- **Réceptions** : déjà branchées sur le **lookup-grid** (trigger `receptions_compute_15c_before_ins`, fonction `astm.compute_v15_from_lookup_grid`).
- **Sorties** : avant migration, branchées sur le **golden engine** (trigger `trg_00_sorties_compute_golden_15c`, fonction `astm.fn_sortie_compute_golden_15c`).

Conséquence : STAGING hybride → NO-GO migration PROD tant que les sorties n’étaient pas migrées vers le lookup-grid.

---

## 3. Préconditions

- **Environnement** : `public.app_settings` doit contenir `key = 'env'` et `value = 'staging'`. Hors STAGING, le nouveau trigger bloque l’INSERT.
- **Batch lookup-grid** : La table `public.astm_lookup_grid_15c` doit contenir le batch actif `GASOIL_P0_2026-02-28` (source ASTM_OFFICIAL_APP, produit_code GASOIL, method_version API_MPMS_11_1) avec une grille couvrant le domaine opérationnel (densité 820–860, température 10–40).
- **Schéma** : Colonnes `densite_a_15_kgm3`, `densite_a_15_g_cm3`, `volume_corrige_15c`, `volume_ambiant`, `temperature_ambiante_c` présentes sur `public.sorties_produit`.

---

## 4. Investigation

L’investigation du 7 mars 2026 a établi :

- Deux moteurs en STAGING : golden (domaine restreint, 8 lignes) et lookup-grid (63 lignes, domaine 820–860 / 10–40).
- Réceptions = lookup-grid, sorties = golden → STAGING hybride.
- Test comparatif (1000 L, 837 kg/m³, 19 °C) : golden 997 L, lookup-grid 996,6 L — écart ≈ 0,4 L, moteurs cohérents.
- Ordre des triggers sorties : le calcul volumétrique s’exécutait avant le calcul de `volume_ambiant` ; ordre corrigé en plaçant le nouveau trigger **après** `trg_01_sorties_set_volume_ambiant`.

Référence : `docs/POST_PROD/ASTM/2026-03-07_INVESTIGATION_STAGING_PROD_VOLUMETRIC_ALIGNMENT.md`.

---

## 5. Décision

- **Cible** : Lookup-grid pour les sorties (comme pour les réceptions).
- **Convention** : Volume 15°C en **litre entier** : `new.volume_corrige_15c := round(r.volume_15c_l)`.
- **Sémantique** : `sorties_produit.densite_a_15_kgm3` est utilisé en **entrée** comme densité observée (legacy) ; le trigger calcule et réécrit la densité à 15°C et le volume corrigé.

---

## 6. SQL appliqué

Le script suivant a été exécuté en STAGING le 7 mars 2026. Il est fourni à titre de documentation ; ne pas l’exécuter en PROD sans procédure validée.

```sql
-- =============================================================================
-- STAGING ONLY — Migration sorties : golden → lookup-grid
-- Date : 2026-03-07
-- =============================================================================

-- 1) Suppression de l'ancien trigger golden
DROP TRIGGER IF EXISTS trg_00_sorties_compute_golden_15c ON public.sorties_produit;

-- 2) Création de la fonction BEFORE INSERT pour sorties (lookup-grid)
CREATE OR REPLACE FUNCTION public.sorties_compute_15c_before_ins_lookup()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_env text;
  v_volume_ambiant double precision;
  v_temp double precision;
  v_density_obs double precision;
  r record;
BEGIN
  -- Garde-fou : STAGING uniquement
  SELECT value INTO v_env FROM public.app_settings WHERE key = 'env';
  IF COALESCE(v_env, '') <> 'staging' THEN
    RAISE EXCEPTION 'SORTIE_VOLUMETRICS_BLOCKED: lookup-grid sorties is STAGING ONLY. env=%', v_env;
  END IF;

  -- Volume ambiant : déjà calculé par trg_01_sorties_set_volume_ambiant ou fourni
  v_volume_ambiant := NEW.volume_ambiant;
  IF v_volume_ambiant IS NULL AND NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL THEN
    v_volume_ambiant := NEW.index_apres - NEW.index_avant;
    NEW.volume_ambiant := v_volume_ambiant;
  END IF;
  IF v_volume_ambiant IS NULL OR v_volume_ambiant <= 0 THEN
    RAISE EXCEPTION 'VOLUME_AMBIANT_REQUIRED';
  END IF;

  v_temp := NEW.temperature_ambiante_c;
  IF v_temp IS NULL THEN
    RAISE EXCEPTION 'TEMPERATURE_REQUIRED';
  END IF;

  -- densite_a_15_kgm3 utilisé comme input legacy (densité observée au moment de la saisie)
  v_density_obs := NEW.densite_a_15_kgm3;
  IF v_density_obs IS NULL THEN
    RAISE EXCEPTION 'DENSITE_OBSERVEE_REQUIRED';
  END IF;

  -- Appel lookup-grid (batch GASOIL_P0_2026-02-28)
  SELECT * INTO r
  FROM astm.compute_v15_from_lookup_grid(
    v_volume_ambiant,
    v_temp,
    v_density_obs,
    'GASOIL',
    'ASTM_OFFICIAL_APP',
    'API_MPMS_11_1',
    'GASOIL_P0_2026-02-28'
  );

  -- Convention : litre entier (aligné réceptions et historique sorties)
  NEW.volume_corrige_15c := round(r.volume_15c_l);
  NEW.densite_a_15_kgm3 := r.densite_a_15_kgm3;
  NEW.densite_a_15_g_cm3 := r.densite_a_15_kgm3 / 1000.0;

  RETURN NEW;
END;
$$;

-- 3) Création du trigger dans le bon ordre (après trg_01_sorties_set_volume_ambiant)
DROP TRIGGER IF EXISTS trg_02_sorties_compute_lookup_15c ON public.sorties_produit;
CREATE TRIGGER trg_02_sorties_compute_lookup_15c
  BEFORE INSERT ON public.sorties_produit
  FOR EACH ROW
  EXECUTE FUNCTION public.sorties_compute_15c_before_ins_lookup();
```

**Ordre final des triggers** (BEFORE INSERT sur `sorties_produit`) :

1. `trg_00_sorties_set_created_by`
2. `trg_01_sorties_set_volume_ambiant`
3. `trg_02_sorties_compute_lookup_15c`
4. `trg_sorties_check_produit_citerne`
5. `trg_sortie_before_ins`
6. (AFTER INSERT : `trg_sorties_after_insert`)

---

## 7. Vérifications

- **Triggers** : Vérifier la présence de `trg_02_sorties_compute_lookup_15c` et l’absence de `trg_00_sorties_compute_golden_15c` sur `public.sorties_produit`.
- **Smoke test nominal** : validé (1000 L → 997 L) — insérer une sortie de test (volume 1000 L, température 19 °C, densité observée 837) ; contrôler `volume_corrige_15c = 997` et densité à 15°C ≈ 839,7.
- **Smoke test hors domaine** : validé (densité = 900 → erreur `ASTM_BILINEAR_OUT_OF_DOMAIN_DENS`) — le moteur rejette les entrées hors grille avec un message explicite.
- **Snapshot** : Avant/après validation de la sortie, vérifier que le snapshot (stocks_snapshot / v_stock_actuel) décrémente de −1000 (ambiant) et −997 (15°C).
- **Logs** : Vérifier la présence d’une entrée `SORTIE_VALIDE` (ou équivalent) dans `log_actions` avec les détails de la sortie.

---

## 8. Résultat

- **Sortie de test validée** : `sortie_id = 0eaa2cc8-5ccc-484d-9358-5176f698ec7e`.
- **Entrée** : volume 1000 L, température 19 °C, densité 837.
- **Résultat** : `volume_corrige_15c = 997`, densité à 15°C = 839,7.
- **Pipeline aval** : Snapshot et logs cohérents ; débit −1000 / −997 confirmé.

---

## 9. Risques

- **`densite_a_15_kgm3` utilisé comme input legacy** : En entrée, ce champ transporte encore la **densité observée** (terrain) au moment de la saisie. Le trigger le lit comme entrée, calcule la vraie densité à 15°C via le lookup-grid, puis **réécrit** `densite_a_15_kgm3` (et `densite_a_15_g_cm3`) avec la valeur calculée. Toute logique ou interface qui lit `densite_a_15_kgm3` **après** INSERT voit donc la densité à 15°C calculée, pas l’observée. Documenter cette convention pour éviter toute confusion.

---

## Centralized domain guard enhancement

Après l’homogénéisation sorties → lookup-grid, une amélioration de robustesse a été ajoutée en STAGING : **garde-fou centralisé du domaine** du batch lookup-grid et **assertion centralisée** avant calcul.

### Objectif

- **Lecture centralisée du domaine** du batch lookup-grid : une seule source de vérité pour les bornes (densité, température) et le nombre de lignes.
- **Assertion centralisée avant calcul** : les triggers réceptions et sorties appellent une même fonction d’assertion avant d’invoquer le moteur de calcul, ce qui évite d’appeler le moteur avec des valeurs hors domaine et standardise les messages d’erreur.

### SQL concerné

Le script STAGING (post-migration sorties lookup-grid) a ajouté :

- **`astm.lookup_grid_domain(p_produit_code, p_source, p_method_version, p_batch_id)`** : retourne `dens_min`, `dens_max`, `temp_min`, `temp_max`, `rows_count` pour le batch actif.
- **`astm.assert_lookup_grid_domain(p_produit_code, p_source, p_method_version, p_batch_id, p_temperature_c, p_densite_observee_kgm3)`** : vérifie que (température, densité observée) est dans le domaine ; lève une erreur claire si hors domaine.

Puis mise à jour des fonctions de trigger pour appeler l’assertion avant le calcul :

- **`public.receptions_compute_15c_before_ins()`** : appel à `astm.assert_lookup_grid_domain(...)` avant `astm.compute_v15_from_lookup_grid(...)`.
- **`public.sorties_compute_15c_before_ins_lookup()`** : idem.

### Vérifications réalisées

- **`select * from astm.lookup_grid_domain(...)`** (avec les paramètres du batch GASOIL actif) : résultat **820 / 860 / 10 / 40 / 63** (dens_min, dens_max, temp_min, temp_max, rows_count).
- **Test hors domaine** : entrée avec densité = **900**, température = 19, batch GASOIL lookup-grid. Erreur attendue et obtenue : **`ASTM_LOOKUP_OUT_OF_DOMAIN_DENS`** avec message explicite (produit=GASOIL, source=ASTM_OFFICIAL_APP, method=API_MPMS_11_1, batch=GASOIL_P0_2026-02-28, dens=900 outside [820,860]).

### Impact

- **Ne change pas** le moteur mathématique (interpolation, VCF, volume à 15°C).
- **Ne change pas** la convention d’arrondi (litre entier).
- **Ne change pas** le pipeline stock / logs.
- **Améliore** uniquement la robustesse (validation explicite avant calcul) et la qualité des erreurs (message standardisé hors domaine).

### Limite

- Amélioration **STAGING uniquement**.
- **Non déployée en PROD** : les fonctions et le branchement des triggers n’existent pas en PROD.
- **Aucune migration PROD exécutée.**

---

## 10. Suite

- **STAGING** : Homogène (réceptions + sorties = lookup-grid). Golden engine réservé à la validation.
- **PROD** : Aucune migration PROD exécutée. La préparation de la migration PROD passe par : documentation complète, checklist ASTM, runbook migration PROD (`docs/RUNBOOKS/RUNBOOK_PROD_VOLUMETRIC_MIGRATION.md`), préparation du schéma et des colonnes PROD, backup et fenêtre d’intervention validés.

**Alignement Dart (post-migration DB)** : Après la migration STAGING sorties → lookup-grid, le front Flutter a été aligné pour éviter incohérence UI/service : formulaire densité en kg/m³ (820–860) en STAGING, service sans envoi de `volume_corrige_15c` en STAGING, aperçu volume 15°C sans estimation locale. Détail : `docs/POST_PROD/ASTM/2026-03-07_INVESTIGATION_STAGING_PROD_VOLUMETRIC_ALIGNMENT.md` § 13. Aucun changement SQL ni migration PROD.

---

**Document créé** : 2026-03-07  
**Référence** : Runbook — STAGING Sorties Lookup Grid Migration.

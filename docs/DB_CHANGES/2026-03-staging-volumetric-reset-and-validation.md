# Changements DB STAGING — Reset et validation volumétrique (mars 2026)

**Date** : 2026-03  
**Périmètre** : STAGING uniquement  
**Statut** : Checkpoint documenté — PROD non migrée

---

## 1. Résumé exécutif

En STAGING, un environnement de validation volumétrique a été stabilisé pour vérifier le moteur golden 15°C (référence ASTM / golden dataset) avant toute migration PROD. Les triggers sur `receptions` et `sorties_produit` utilisent les fonctions `astm.ctl_from_golden` et `astm.compute_15c_from_golden`. Un reset contrôlé de l’environnement STAGING a été réalisé pour repartir sur une base propre et déterministe. La validation effective repose sur le golden path ; le moteur officiel API MPMS 11.1 / ASTM 53B (`calculate_ctl_54b_15c_official_only`) n’est pas implémenté et lève une exception dédiée. Ce document trace les changements appliqués, les validations réalisées et les limites connues pour audit, onboarding et future réplication maîtrisée vers PROD.

---

## 2. Contexte

- **Besoin** : Alignement du calcul volumétrique à 15°C avec une référence exploitable (golden dataset) et préparation à un alignement normatif ultérieur (API MPMS 11.1 / ASTM D1250).
- **Criticité métier** : Le volume à 15°C est un point critique pour les réceptions, sorties et stocks. Toute erreur de calcul impacte la traçabilité et la conformité.
- **Approche** : STAGING first — toute évolution volumétrique est validée en STAGING avant toute action sur PROD.
- **Environnement** : Nécessité d’un STAGING propre (nettoyage transactionnel contrôlé, conservation du référentiel nécessaire) pour obtenir un environnement déterministe de validation.

---

## 3. Références

| Élément | Valeur |
|--------|--------|
| **PR** | #90 (merge dans `main`) |
| **Commit** | 25422eb (squash) |
| **Tag** | `v0.9-volumetric-staging` |

Les scripts et décisions antérieures liés au moteur golden et au dataset sont documentés dans `docs/DB_CHANGES/` (ex. `2026-02-28_staging_astm_app_golden_engine.sql`, `2026-02-28_expand_astm_golden_cases_gasoil.sql`, `2026-02-28_staging_sorties_golden_engine.sql`) et dans `docs/POST_PROD/ASTM/` ainsi que `docs/01_DECISIONS/` selon le cas.

---

## 4. Objectif des changements STAGING

- Mettre à disposition un **golden dataset** (table `public.astm_golden_cases_15c`) exploitable pour le calcul 15°C.
- Activer les **triggers** sur réceptions et sorties utilisant le moteur golden (`ctl_from_golden`, `compute_15c_from_golden`).
- Obtenir un **environnement déterministe** : purge / nettoyage des écritures transactionnelles de test ou non fiables, conservation du référentiel nécessaire.
- Valider en conditions réelles (insertion réception, sortie existante) que les volumes 15°C et densités dérivées sont cohérents avec le moteur golden.

---

## 5. Changements appliqués en STAGING

- **Golden dataset** : La table `public.astm_golden_cases_15c` contient le dataset GASOIL utilisé pour la validation. Le chargement / l’élargissement du jeu de cas sont réalisés par les scripts présents dans `docs/DB_CHANGES/` (notamment expansion GASOIL et seed ASTM_APP). Les triggers de réception et de sortie s’appuient sur ce jeu.
- **Triggers réceptions** : Trigger(s) sur `public.receptions` (ex. `trg_receptions_compute_15c_before_ins`) qui, en environnement STAGING (`public.app_settings.env = 'staging'`), appellent le moteur golden pour calculer `volume_15c`, `densite_a_15_kgm3`, etc., à l’INSERT.
- **Triggers sorties** : Trigger(s) sur `public.sorties_produit`, dont `trg_00_sorties_compute_golden_15c` utilisant la fonction `astm.fn_sortie_compute_golden_15c()`, pour le calcul de `volume_corrige_15c` à partir du golden path.
- **Environnement dédié** : Configuration STAGING (ex. `app_settings.env = 'staging'`) pour autoriser l’usage du moteur golden ; garde-fou pour ne pas utiliser ce chemin en PROD.
- **Nettoyage transactionnel** : Un reset contrôlé STAGING a été réalisé pour repartir sur une base propre de validation volumétrique (purge d’écritures de test ou non fiables, conservation du référentiel nécessaire). Le détail exact des commandes ou scripts exécutés pour ce reset n’est pas repris intégralement dans ce document ; pour les scripts existants et reproductibles, se référer à `docs/DB_CHANGES/` et aux runbooks (ex. reset STAGING) du projet.
- **Immutabilité** : Les tables métier `receptions` et `sorties_produit` restent immuables (pas de UPDATE/DELETE direct) ; toute correction passe par les mécanismes prévus (triggers, RPC, compensations documentées). Une tentative de DELETE sur `receptions` est bloquée par la règle métier (voir section 7).

---

## 6. Validation réalisée

- **Contrôle du golden dataset** : Vérification de la table `public.astm_golden_cases_15c` (produit GASOIL) — plage de densité et température et nombre de lignes (cf. section 8).
- **Test `astm.ctl_from_golden`** : Appel `astm.ctl_from_golden('GASOIL', 837.0, 19.0)` et vérification de la valeur de CTL retournée.
- **Test `astm.compute_15c_from_golden`** : Appel `astm.compute_15c_from_golden('GASOIL', 1000.0, 837.0, 19.0)` et vérification du record retourné (ctl, volume_15c_l, densité dérivée).
- **Test d’insertion réception** : Insertion de test dans `public.receptions` avec volume_ambiant, température, densité observée ; vérification que le trigger remplit `volume_15c` et `densite_a_15_kgm3` de façon cohérente avec le moteur golden.
- **Contrôle trigger sortie** : Vérification qu’une sortie existante (1000 L, 19°C, densité stockée 837) reçoit bien `volume_corrige_15c` cohérent avec le recalcul via `astm.ctl_from_golden`.
- **Cohérence volume sortie** : Comparaison du volume corrigé 15°C en base avec le résultat de `astm.ctl_from_golden(...)` appliqué aux mêmes entrées.
- **Immutabilité réception** : Tentative de DELETE sur `receptions` pour confirmer le blocage métier (message explicite d’interdiction d’écriture).

---

## 7. Résultats observés

### Golden dataset (GASOIL)

- **Nombre de lignes observé** : 13.
- **Plage densité** : 836 → 837,6 kg/m³.
- **Plage température** : 19 → 29,7 °C.

### Test moteur golden

- **`astm.ctl_from_golden('GASOIL', 837.0, 19.0)`**  
  - Résultat validé : **ctl = 0.996591923398634**.

- **`astm.compute_15c_from_golden('GASOIL', 1000.0, 837.0, 19.0)`**  
  - **volume_15c** ≈ 996,591923398634 L.  
  - Record retourné contenant `ctl`, `volume_15c_l`, et densité dérivée.

### Validation réception (insertion de test)

Une insertion de test dans `public.receptions` a produit :

| Champ | Valeur |
|-------|--------|
| volume_ambiant | 1000 |
| temperature_ambiante_c | 19 |
| densite_observee_kgm3 | 837 |
| volume_15c | 996,6 |
| densite_a_15_kgm3 | 839,7 |

Cela confirme : trigger réception actif, calcul DB cohérent avec le moteur golden, arrondi appliqué (996,59… → 996,6).

### Immutabilité réception

Une tentative de **DELETE** sur `receptions` a échoué avec un blocage métier explicite :

- **Message observé** : *« Ecriture interdite sur receptions (op=DELETE). Table immutable: utiliser INSERT + triggers/RPC, jamais UPDATE/DELETE. »*

### Validation sorties

- Le trigger `trg_00_sorties_compute_golden_15c` et la fonction `astm.fn_sortie_compute_golden_15c()` sont actifs.
- Pour une sortie existante : 1000 L à 19°C, densité stockée = 837 → **volume_corrige_15c = 997**.
- Recalcul via `astm.ctl_from_golden(...)` avec les mêmes paramètres redonne **997** (cohérence à l’unité).

---

## 8. Points de vigilance / limites connues

- **Moteur officiel non implémenté** : La fonction `astm.calculate_ctl_54b_15c_official_only(...)` (référence API MPMS 11.1 / ASTM 53B) n’est pas implémentée et lève volontairement `ASTM_OFFICIAL_ENGINE_NOT_IMPLEMENTED_YET`. La validation actuelle repose entièrement sur le golden path (`ctl_from_golden`, `compute_15c_from_golden`).
- **Validation limitée au domaine golden** : Les calculs ne sont garantis que dans le domaine (densité, température) couvert par `astm_golden_cases_15c`. Hors domaine, le moteur peut lever une exception (ex. `ASTM_GOLDEN_OUT_OF_DOMAIN`).
- **Immutabilité** : Les tables `receptions` et `sorties_produit` sont immuables pour les corrections manuelles (pas de UPDATE/DELETE direct). Toute correction doit passer par les mécanismes prévus (triggers, RPC, procédures de compensation documentées).
- **Sémantique `sorties_produit.densite_a_15_kgm3`** : Le trigger `astm.fn_sortie_compute_golden_15c()` teste `new.densite_a_15_kgm3 is null` et lève une exception avec le message `'DENSITE_OBSERVEE_REQUIRED'`. En pratique, la colonne `densite_a_15_kgm3` côté sorties semble contenir une densité observée terrain (ex. 837 à 19°C), et non une densité corrigée à 15°C. Cela ne casse pas le calcul actuel (le moteur golden utilise cette valeur comme entrée), mais crée une **ambiguïté sémantique** à clarifier et à documenter. Le message d’erreur est incohérent avec le nom du champ et devra être corrigé ultérieurement.

---

## 9. Implications pour PROD

- **STAGING** : Environnement volumétriquement validé sur le golden path ; triggers réception et sortie actifs en mode STAGING ; immutabilité et cohérence des calculs vérifiées.
- **PROD** : N’a **pas** encore été migrée vers le moteur golden. La migration PROD ne doit être envisagée qu’après :
  - finalisation de la documentation des changements DB (ce document et compléments éventuels),
  - finalisation d’un runbook PROD dédié,
  - définition d’une stratégie de purge / replay compatible avec la gouvernance DB et l’immutabilité,
  - validation opérationnelle de la fenêtre et de la procédure d’intervention.
- **Règle** : Ne pas exécuter en PROD de scripts ou de changements volumétriques tant que la procédure d’intervention et le runbook PROD ne sont pas finalisés et validés.

---

## 10. Actions restantes

- Finaliser la documentation des changements DB (ce document constitue le checkpoint mars 2026 ; compléter si besoin par d’autres fiches `docs/DB_CHANGES/` ou POST_PROD/ASTM).
- Finaliser le runbook de migration PROD volumétrique (procédure, ordre d’exécution, garde-fous, rollback).
- Clarifier la sémantique de la colonne `sorties_produit.densite_a_15_kgm3` (observée vs corrigée 15°C) et aligner le message d’erreur du trigger (`DENSITE_OBSERVEE_REQUIRED`) avec le champ réellement utilisé.
- Préparer la stratégie d’intervention PROD (purge éventuelle, replay, fenêtre de maintenance, sauvegardes).
- Valider opérationnellement la fenêtre et les critères de migration avant toute exécution en PROD.

---

## 11. Conclusion

Le checkpoint mars 2026 (PR #90, commit 25422eb, tag `v0.9-volumetric-staging`) atteste qu’en STAGING un environnement de validation volumétrique a été stabilisé : golden dataset GASOIL exploitable, triggers réception et sortie opérationnels sur le moteur golden, résultats numériques cohérents (CTL, volume 15°C, densité dérivée, immutabilité). Les limites connues (moteur officiel non implémenté, domaine golden, ambiguïté sémantique sur la densité des sorties) sont explicites. La réplication vers PROD doit rester conditionnée à la finalisation de la documentation, du runbook et de la stratégie d’intervention, sans exécution prématurée en production.

---

**Document créé** : 2026-03  
**Périmètre** : Audit, onboarding, préparation migration PROD  
**Aucune modification** : aucun autre fichier du repo n’est modifié par ce document.

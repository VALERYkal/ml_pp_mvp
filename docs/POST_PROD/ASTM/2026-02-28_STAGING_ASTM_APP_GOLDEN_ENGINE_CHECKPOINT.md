# Checkpoint — STAGING ASTM_APP Golden Engine (Stability Mode)

**Date** : 2026-02-28  
**Périmètre** : STAGING uniquement  
**Référence** : `docs/01_DECISIONS/DECISION_2026-02-28_ASTM_APP_ALIGNMENT_STABILITY.md`

---

## TL;DR

Alignement du calcul volumétrique 15°C sur l’application terrain **ASTM** (oracle opérationnel) pour stabilité immédiate en STAGING. Le moteur n’est **pas** conforme API MPMS 11.1 / ASTM D1250 ; il est calibré sur 5 golden cases (source `ASTM_APP`). Garde-fou strict : exécution **STAGING only** via `public.app_settings.env` ; aucune fuite en PROD.

---

## Objectif

Atteindre une **stabilité terrain immédiate** sur STAGING en faisant coïncider le volume à 15°C avec l’oracle « ASTM » (app terrain). Le standard international API MPMS 11.1 n’est pas implémenté à ce stade ; les tentatives « official only » et tables de coefficients sont en pause (version norme inconnue). Ce checkpoint livre un comportement identique au terrain tout en bornant le moteur au domaine des golden cases et en interdisant toute utilisation en PROD.

---

## Décision

- **Alignement** sur l’app terrain « ASTM » (oracle ASTM_APP) pour la phase stabilité.
- **Aucune prétention** à la conformité API MPMS 11.1 dans ce mode.
- Moteur « golden » limité au domaine (température, densité observée) couvert par les 5 golden cases ; hors domaine → erreur actionnable.
- Le moteur golden **ne doit jamais** être utilisé en PROD : garde-fou via `public.app_settings.env`.

---

## Objets DB concernés

| Type | Nom | Rôle |
|------|-----|------|
| Table | `public.app_settings` | Clé `env` = `staging` pour autoriser le trigger ; sinon blocage. |
| Fonction | `astm.ctl_from_golden(produit_code, densite_obs_kgm3, temperature_c)` | CTL par interpolation IDW sur les 2 plus proches points du jeu golden ; garde-fou hors domaine. |
| Fonction | `astm.compute_15c_from_golden(produit_code, volume_observe_l, densite_obs_kgm3, temperature_c)` | Retourne (ctl, volume_15c_l, density_15_kgm3). |
| Trigger | `trg_receptions_compute_15c_before_ins` sur `public.receptions` | BEFORE INSERT : calcule `volume_ambiant` si absent, appelle le moteur golden, remplit `volume_15c` (arrondi unité), `densite_a_15_kgm3`, `densite_a_15_g_cm3` ; vérifie `env = 'staging'`. |

**Prérequis** : table `public.astm_golden_cases_15c` existante, avec au moins 5 lignes `source = 'ASTM_APP'` et `produit_code = 'GASOIL'`.

---

## Fonctionnement

1. **CTL** : `astm.ctl_from_golden` utilise une interpolation IDW sur les 2 points les plus proches (distance euclidienne densité × température) du jeu `astm_golden_cases_15c` (source ASTM_APP). Si (densité, température) est hors min/max du jeu → exception `ASTM_GOLDEN_OUT_OF_DOMAIN`.
2. **Volume et densité @15** : `astm.compute_15c_from_golden` appelle `ctl_from_golden`, puis `volume_15c_l = volume_observe_l * ctl`, `density_15_kgm3 = densite_obs_kgm3 / ctl`.
3. **Trigger réception** : avant chaque INSERT sur `receptions`, lecture de `app_settings.env` ; si ≠ `staging` → `RECEPTION_VOLUMETRICS_BLOCKED`. Sinon : calcul de `volume_ambiant` (index_apres - index_avant si absent), lecture de la densité observée (temporairement dans `densite_a_15_kgm3`), appel à `compute_15c_from_golden`, puis affectation de `volume_15c` (arrondi à l’unité), `densite_a_15_kgm3`, `densite_a_15_g_cm3`. En cas d’erreur (ex. hors domaine) → `RECEPTION_VOLUMETRICS_FAILED` avec message actionnable (ajouter un golden case).

---

## Rejouer le déploiement

1. S’assurer d’être sur l’environnement **STAGING** (pas PROD).
2. Exécuter le script source de vérité :  
   `docs/DB_CHANGES/2026-02-28_staging_astm_app_golden_engine.sql`  
   (idempotent : CREATE OR REPLACE / CREATE IF NOT EXISTS, INSERT ON CONFLICT DO UPDATE.)

---

## Vérification

- **Env** :  
  `SELECT * FROM public.app_settings WHERE key = 'env';`  
  → doit retourner `value = 'staging'`.
- **Validation sur les 5 golden cases** : exécuter la requête de validation (en commentaire en fin de script) sur `astm_golden_cases_15c` (source = ASTM_APP) ; comparer `v15_db` (round(volume_observe_l * ctl_from_golden(...))) à `volume_15c_ref_l` ; attente : égalité à l’unité (litre).
- **Test hors domaine** : tenter un INSERT réception avec (densité ou température) en dehors des min/max des golden cases → doit échouer avec `RECEPTION_VOLUMETRICS_FAILED` et message indiquant d’ajouter un cas golden couvrant le domaine.
- **Trigger** : vérifier la présence du trigger sur `public.receptions` :  
  `SELECT tgname FROM pg_trigger WHERE tgrelid = 'public.receptions'::regclass AND tgname = 'trg_receptions_compute_15c_before_ins';`

---

## Désactiver / rollback

- **Désactiver sans supprimer** : mettre `env` à une valeur autre que `staging` (ex. `prod` ou `disabled`) dans `public.app_settings` → tout INSERT réception déclenchera `RECEPTION_VOLUMETRICS_BLOCKED`.
- **Retirer le trigger** :  
  `DROP TRIGGER IF EXISTS trg_receptions_compute_15c_before_ins ON public.receptions;`  
  (les fonctions `astm.ctl_from_golden` et `astm.compute_15c_from_golden` restent en place.)

---

## Limitations et suite

- **Domaine limité** : le moteur ne calcule que dans l’enveloppe (densité, température) des golden cases ; hors domaine → erreur explicite.
- **Nommage temporaire** : la densité observée est saisie et lue dans `densite_a_15_kgm3` (mauvais nom sémantique) en attendant un refactor du schéma `receptions` avec colonne dédiée `densite_observee_kgm3`.
- **Pas de standard** : aucun engagement de conformité API MPMS 11.1 ; reprise du chemin « official only » lorsque la version norme sera confirmée et les coefficients chargés.

**Référence script** : `docs/DB_CHANGES/2026-02-28_staging_astm_app_golden_engine.sql`

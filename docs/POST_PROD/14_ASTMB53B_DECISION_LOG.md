# Decision Log — ASTM53B Migration

Date : 2026-02-25  
Branche : feature/astm11-1-validation-P0  
PR : #89  

## Contexte

Écart terrain confirmé 50–70 litres par réception
entre ML_PP et application SEP.

Cause suspectée :
Formule volumétrique legacy incorrecte.

Décision :
Migration vers standard API MPMS 11.1 (ASTM 53B — 15°C).

## Portée

- Réceptions
- Sorties
- Stocks journaliers
- validate_sortie (DB-STRICT)

## Risques identifiés

- Impact sur 8 réceptions déjà encodées en PROD
- 2 camions non encore encodés
- Impact potentiel sur stock réel
- Impact reporting financier

## Statut

En attente validation terrain finale avant activation PROD.
Feature flag ASTM encore OFF en PROD.

---

## Addendum — 2026-02-28 — Mode stabilité (alignement oracle ASTM_APP)

- **Pause du chemin « official only »** : La conformité stricte API MPMS 11.1 (coefficients officiels, table `astm.mpms11_1_54b_coeffs`) reste en pause — version exacte de la norme utilisée par l’app terrain non confirmée.
- **Nouveau mode stabilité (STAGING uniquement)** : Alignement du calcul volumétrique 15°C sur l’**application terrain « ASTM »** (oracle opérationnel, source `ASTM_APP` dans `public.astm_golden_cases_15c`). Moteur « golden » calibré par interpolation (IDW) sur 5 cas ; domaine limité ; pas de prétention à la conformité API MPMS 11.1.
- **Garde-fou anti-PROD** : Le moteur golden ne s’exécute que si `public.app_settings.env = 'staging'`. En PROD (ou toute autre valeur d’env), le trigger sur `receptions` lève `RECEPTION_VOLUMETRICS_BLOCKED` et bloque l’INSERT. Aucun déploiement de ce moteur en PROD prévu dans ce mode.
- **Références** : Décision `docs/01_DECISIONS/DECISION_2026-02-28_ASTM_APP_ALIGNMENT_STABILITY.md` ; runbook `docs/POST_PROD/ASTM/2026-02-28_STAGING_ASTM_APP_GOLDEN_ENGINE_CHECKPOINT.md` ; script `docs/DB_CHANGES/2026-02-28_staging_astm_app_golden_engine.sql`.


# Décision — Alignement ASTM_APP (stabilité terrain) — STAGING

**Date** : 2026-02-28  
**Statut** : Accepted (STAGING)  
**Contexte** : Checkpoint Volumétrie ASTM / stabilité terrain immédiate. ML_PP MVP (Monaluxe).

---

## Contexte

- **Divergence** entre ML_PP et l’application terrain **ASTM** (oracle opérationnel) sur le volume à 15°C, avec pression pour une stabilité terrain rapide.
- **Version norme inconnue** : l’édition exacte d’API MPMS 11.1 / ASTM D1250 utilisée par l’app terrain n’est pas confirmée ; les tentatives « official only » et le chargement de coefficients officiels sont **en pause** (bloquantes).
- **Risque** : perte de temps et dérive si l’on reste bloqué sur la conformité standard sans livrer un comportement aligné terrain.

---

## Décision

Nous **nous alignons sur l’application terrain « ASTM »** (oracle ASTM_APP) pour la phase **stabilité**, en STAGING uniquement.

- Nous **ne prétendons pas** à la conformité API MPMS 11.1 dans ce mode.
- Le moteur « golden » est **borné au domaine** (température, densité observée) couvert par les golden cases (5 cas utilisés) ; hors domaine → erreur actionnable.
- Le moteur golden **ne doit jamais fuiter en PROD** : garde-fou strict via `public.app_settings.env` (vérification dans le trigger ; si env ≠ `staging` → blocage de l’INSERT réception).

---

## Statut

**Accepted (STAGING)** — En vigueur sur STAGING ; PROD non impactée.

---

## Conséquences

| Aspect | Effet |
|--------|--------|
| **Avantages** | Stabilité terrain immédiate ; calcul auditable vs oracle ASTM_APP ; erreur explicite hors domaine ; un seul script SQL source de vérité, rejouable. |
| **Inconvénients** | Pas un moteur normatif ; domaine limité aux golden cases ; maintenance des golden cases si extension du domaine (densité / température) ; nommage temporaire de la densité observée dans `receptions` (colonne `densite_a_15_kgm3` utilisée en entrée jusqu’à refactor). |

---

## Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Fuite du moteur golden en PROD | Vérification `app_settings.env = 'staging'` dans le trigger ; exception `RECEPTION_VOLUMETRICS_BLOCKED` si env ≠ staging. |
| Saisie hors domaine non gérée | Garde-fou min/max sur les golden cases ; exception `ASTM_GOLDEN_OUT_OF_DOMAIN` ou `RECEPTION_VOLUMETRICS_FAILED` avec message actionnable (ajouter un golden case). |
| Confusion densité observée / densité @15 | Documenté (nommage temporaire) ; refactor futur : colonne dédiée `densite_observee_kgm3` dans le schéma receptions. |

---

## Critères de sortie / évolution

- **Réactiver le chemin « official only »** lorsque : (1) la version exacte d’API MPMS 11.1 utilisée par l’app terrain est confirmée, (2) les coefficients Table 54B correspondants sont chargés dans `astm.mpms11_1_54b_coeffs` (ou équivalent), (3) le moteur basé sur ces coefficients est implémenté et validé sur les golden cases.
- **Refactor schéma receptions** : à terme, remplacer l’usage temporaire de `densite_a_15_kgm3` en entrée par une colonne dédiée `densite_observee_kgm3` et conserver `densite_a_15_kgm3` pour la densité calculée à 15°C.

---

**Références** :  
- Runbook checkpoint : `docs/POST_PROD/ASTM/2026-02-28_STAGING_ASTM_APP_GOLDEN_ENGINE_CHECKPOINT.md`  
- Script SQL : `docs/DB_CHANGES/2026-02-28_staging_astm_app_golden_engine.sql`  
- Decision log addendum : `docs/POST_PROD/14_ASTMB53B_DECISION_LOG.md`

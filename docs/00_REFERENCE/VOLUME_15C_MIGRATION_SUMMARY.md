# Résumé technique — migration `volume_15c` (mode compatibilité)

**Projet** : ML_PP MVP  
**Statut** : migration validée (STAGING puis PROD), sans suppression du legacy.  
**Document** : synthèse factuelle pour audit et onboarding technique.

---

## Contexte

Le moteur volumétrique et les triggers écrivent désormais le volume corrigé à 15 °C dans une colonne explicite **`volume_15c`**. La colonne historique **`volume_corrige_15c`** reste en place pour compatibilité transitoire. L’application Flutter a été alignée en **lecture** sur la règle `volume_15c` en priorité, `volume_corrige_15c` en secours, **sans** refonte complète des modèles ni des payloads d’écriture.

---

## Problème initial

- **Réceptions** : déjà partiellement orientées vers `volume_15c`.
- **Sorties** : runtime et stock dérivés encore fortement couplés à `volume_corrige_15c`.
- **Flutter** : lectures majoritairement legacy-first ; besoin d’homogénéiser la lecture sans casser l’existant ni les écritures.

---

## Solution appliquée (vue d’ensemble)

1. **Base de données (STAGING puis PROD)**  
   - Ajout de **`public.sorties_produit.volume_15c`**.  
   - Adaptation des fonctions et triggers concernés pour **écrire** `volume_15c` **et conserver** `volume_corrige_15c` (compatibilité).  
   - Usage logique côté métier / triggers dérivés : **`coalesce(volume_15c, volume_corrige_15c)`** où applicable.  
   - **Pas** de suppression de colonnes legacy.  
   - **Pas** de backfill destructif sur `sorties_produit` (table à écriture contrôlée / immuable en conditions normales).

2. **Flutter (lecture uniquement)**  
   - Priorité de lecture : **`volume_15c ?? volume_corrige_15c`** sur les périmètres ciblés (KPI, repositories réceptions/sorties, providers sorties, écrans d’ajustements de stock).  
   - **Aucun** changement des payloads d’insert/update métier dans le cadre de cette migration de compatibilité.

---

## Validation STAGING

- Sortie test créée en STAGING : **`volume_corrige_15c = 10`**, **`volume_15c = 10`**.  
- Décrément de stock cohérent ; **`stocks_snapshot`**, **`stocks_journaliers`** et **`log_actions`** alignés avec l’attendu.  
- **Conclusion** : STAGING validé en mode compatibilité.

---

## Validation PROD

- Même schéma d’évolution DB que STAGING (colonne `volume_15c` + adaptations triggers / fonctions listées dans le runbook).  
- Smoke test PROD : sortie test avec **`volume_corrige_15c = 10`**, **`volume_15c = 10`** ; snapshot de stock décrémenté correctement ; **migration runtime validée**.

---

## Correction du test PROD

La base PROD étant en usage réel (Monaluxe), le mouvement de test a été **compensé** :

- Ajustement de stock via **`stocks_adjustments`** sur la sortie test.  
- Constat : **`v_stock_actuel`** revenu cohérent, **`stocks_snapshot`** encore désynchronisé.  
- Correction technique du snapshot via **`stock_snapshot_apply_delta(...)`** (procédure dédiée).  
- **État final** : restauré ; stock métier non laissé pollué.

---

## Décisions d’architecture retenues

| Élément | Rôle |
|--------|------|
| **`v_stock_actuel`** | Source de vérité **métier** pour le stock actuel. |
| **`stocks_snapshot`** | Cache / structure technique **dérivée** ; peut nécessiter une resynchronisation explicite après opérations exceptionnelles. |
| **`volume_15c`** | Colonne **cible canonique** pour le volume à 15 °C sur les nouveaux chemins. |
| **`volume_corrige_15c`** | Colonne **legacy**, **conservée** ; compatibilité transitoire. |

---

## État final (après migration)

- STAGING et PROD disposent de **`sorties_produit.volume_15c`** alimentée par le runtime aligné avec la stratégie de compatibilité.  
- Flutter lit en priorité **`volume_15c`** avec repli sur **`volume_corrige_15c`** sur les zones migrées.  
- **Aucune** suppression du legacy dans cette phase.  
- **Aucun** backfill historique global sur les sorties n’est revendiqué dans ce document.

---

## Dette restante (hors périmètre de cette migration)

- Modèles Dart / Freezed : **non** entièrement harmonisés sur un seul nom de champ JSON.  
- Services d’écriture : **non** refactorés pour n’envoyer qu’une seule sémantique côté API.  
- Convergence finale (retrait progressif de `volume_corrige_15c`) : **non** réalisée ; à traiter dans un chantier ultérieur explicite, avec ADR et migration de schéma si applicable.

---

## Références

- Runbook opérationnel : `docs/RUNBOOKS/RUNBOOK_VOLUME_15C_COMPAT_MIGRATION.md`  
- Note de compatibilité lecture : `docs/00_REFERENCE/VOLUME_15C_COMPATIBILITY_NOTE.md`  
- CHANGELOG : section `[Unreleased]` — migration `volume_15c` (compatibilité)

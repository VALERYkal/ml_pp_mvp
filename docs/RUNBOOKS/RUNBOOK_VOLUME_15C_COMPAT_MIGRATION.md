# Runbook — migration `volume_15c` (compatibilité sorties)

**Document** : procédure de référence pour la migration colonne `volume_15c` sur `sorties_produit`, en mode **compatibilité** (conservation de `volume_corrige_15c`).  
**Projet** : ML_PP MVP  
**Public** : développeurs, DBA, release.

**Résumé détaillé** : `docs/00_REFERENCE/VOLUME_15C_MIGRATION_SUMMARY.md`  
**Lecture applicative** : `docs/00_REFERENCE/VOLUME_15C_COMPATIBILITY_NOTE.md`

---

## 1. But

- Introduire **`public.sorties_produit.volume_15c`** comme colonne canonique pour le volume à 15 °C sur le chemin runtime.  
- Continuer à remplir **`volume_corrige_15c`** pour compatibilité transitoire.  
- Adapter triggers et fonctions critiques sans backfill destructif sur les lignes historiques immuables.  
- Valider par smoke test, puis annuler proprement tout test sur PROD réelle.

---

## 2. Prérequis

- Backup base (STAGING puis PROD) avant toute migration DDL / fonction.  
- Scripts SQL révisés et exécutés d’abord sur **STAGING**.  
- Fenêtre de validation STAGING complète avant reproduction PROD.  
- Accès aux fonctions de maintenance snapshot si correction post-test nécessaire (ex. `stock_snapshot_apply_delta`).

---

## 3. Étapes STAGING (référence)

Ordre logique documenté (détail SQL dans les scripts du dépôt / tickets associés) :

1. Ajouter la colonne **`public.sorties_produit.volume_15c`** (type aligné sur le projet).  
2. Adapter **`sorties_compute_15c_before_ins_lookup()`** pour écrire **`volume_15c`** et **`volume_corrige_15c`**.  
3. Adapter les dépendances cohérentes avec le stock et la validation, notamment :  
   - **`sorties_after_insert_trg()`**  
   - **`sorties_before_validate_trg()`**  
   - **`validate_sortie(uuid)`**  
   - **`create_sortie(...)`**  
4. Vérifier que la logique métier utilise **`coalesce(volume_15c, volume_corrige_15c)`** là où le volume @15 °C est consommé en interne.  
5. **Ne pas** supprimer `volume_corrige_15c`.  
6. **Ne pas** lancer de backfill massif `UPDATE` sur `sorties_produit` en contournant la gouvernance d’immutabilité.

---

## 4. Validation STAGING

- Créer une **sortie test** (volume connu).  
- Vérifier sur la ligne : **`volume_corrige_15c`** et **`volume_15c`** renseignés de façon cohérente (ex. même valeur pour le cas test validé).  
- Contrôler décrément **stock** (journaliers / logique métier).  
- Contrôler **`stocks_snapshot`**, **`stocks_journaliers`**, **`log_actions`**.  
- **Gate** : aucune régression sur création sortie « normale » et sur la lecture **`v_stock_actuel`**.

---

## 5. Étapes PROD

- Reproduire **strictement** le même jeu de changements que STAGING (DDL + fonctions + triggers).  
- Vérifier déploiement sur le bon projet Supabase / instance.  
- Ne pas exécuter de script destructif hors runbook validé.

---

## 6. Smoke test PROD

- Créer une **sortie test** en PROD (données et volume documentés).  
- Vérifier **`volume_corrige_15c`** et **`volume_15c`** sur la ligne créée.  
- Vérifier décrément **`stocks_snapshot`** (ou indicateur équivalent validé par l’équipe).  
- **Important** : PROD étant en usage réel, prévoir **immédiatement** la section 7.

---

## 7. Annulation propre d’un test PROD

Si une sortie test a été créée sur PROD exploité :

1. Enregistrer un **`stocks_adjustments`** (ou mécanisme approuvé) lié au mouvement test pour compenser l’impact métier.  
2. Vérifier **`v_stock_actuel`** (source de vérité métier).  
3. Si **`stocks_snapshot`** reste désynchronisé par rapport à l’état attendu : appliquer la correction technique documentée (ex. **`stock_snapshot_apply_delta(...)`**) sous contrôle et traçabilité.  
4. Vérifier l’**état final** : pas de pollution durable du stock réel opérateur.

---

## 8. Vérifications post-migration

- Nouvelle sortie « réelle » ou de non-régression : **`volume_15c`** et **`volume_corrige_15c`** présents selon le contrat runtime.  
- **`v_stock_actuel`** cohérent après enchaînement réception / sortie.  
- Application Flutter : écrans KPI / listes / ajustements affichent des volumes @15 °C cohérents (lecture prioritaire `volume_15c`).  
- Logs / triggers : pas d’erreur récurrente sur insert sortie.

---

## 9. Rollback logique (non destructif)

Ce runbook **ne prescrit pas** un rollback par `DELETE` massif sur `sorties_produit`.

En cas de régression critique après déploiement :

1. **Geler** les nouvelles sorties si la politique métier l’exige.  
2. **Restaurer** la base depuis le **backup** pré-migration (fenêtre d’intervention validée).  
3. Ou : redéployer la **version précédente** des fonctions/triggers **uniquement** si une procédure de rollback SQL validée existe (hors scope de ce document si non versionnée).  
4. **Journaliser** la décision (ticket, date, auteur).

Toute restauration complète implique perte des données post-backup : à planifier avec le métier.

---

## 10. Rappels gouvernance

- **`v_stock_actuel`** : vérité métier stock actuel.  
- **`stocks_snapshot`** : dérivé technique ; peut nécessiter une action explicite après incident.  
- **`volume_15c`** : cible canonique volume @15 °C (chemin nouveau).  
- **`volume_corrige_15c`** : legacy conservé ; pas de suppression dans cette migration.

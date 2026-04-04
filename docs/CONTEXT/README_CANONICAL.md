# CANONICAL PACK — ML_PP MVP

## ROLE
Expliquer comment utiliser le pack canonique pour travailler correctement sur le projet.

---

## OBJECTIF

Ce pack permet de :
- comprendre rapidement le système
- éviter les erreurs critiques
- guider l’IA et les développeurs
- refléter, en plus de la structure documentaire et des objets DB listés, **l’état de validation réel** du **pipeline critique** (STAGING / intégration) lorsque des preuves récentes existent

---

## FICHIERS CANONIQUES

Les seuls fichiers à lire en priorité :

1. docs/CONTEXT/current_checkpoint.md
2. docs/CONTEXT/architecture_rules.md
3. docs/CONTEXT/architecture_map.md
4. docs/DB/critical_objects.md
5. docs/DB/staging_status.md
6. docs/DB/prod_status.md

---

## ORDRE DE LECTURE

1. current_checkpoint.md → état actuel
2. architecture_rules.md → règles absolues
3. architecture_map.md → navigation système
4. critical_objects.md → sécurité DB
5. staging_status.md → état staging
6. prod_status.md → état production

---

## ORDRE DE VÉRITÉ SYSTÈME

1. Base de données (source de vérité)
2. Invariants métier
3. Code applicatif
4. Pack canonique
5. Documentation secondaire

En cas de conflit :
→ toujours s’aligner sur la DB

---

## RÈGLES D’UTILISATION

- Ne jamais se fier à un fichier hors pack canonique sans validation
- Ne jamais modifier la DB sans migration
- Ne jamais toucher aux zones critiques sans analyse
- Toujours valider en staging avant production

---

## MODE DE TRAVAIL

1. Lire current_checkpoint.md
2. Appliquer architecture_rules.md
3. Identifier la zone (architecture_map.md)
4. Vérifier la DB si nécessaire
5. Intervenir dans le périmètre
6. Mettre à jour le pack si nécessaire
7. Si une **validation technique significative** a été réalisée (ex. DB tests STAGING sur le critique), **mettre à jour** le pack (`current_checkpoint`, `CHANGELOG`) pour garder la même vérité opérationnelle

---

## RÈGLE IA CRITIQUE

L’IA ne doit jamais :
- inventer une structure DB
- supposer un comportement métier
- modifier un objet critique sans validation

En cas de doute :
→ demander confirmation
→ ou vérifier dans la DB

---

## GARANTIE DU PACK CANONIQUE

- Le pack canonique doit **refléter l’état réel** consigné dans **`docs/DB/staging_status.md`** et **`docs/DB/prod_status.md`** ; toute **divergence** entre pack et DB constatée doit être **corrigée** (doc ou base) sans délai injustifié.
- Le cas **`sorties_after_insert_trg()`** (PROD débitant autrefois sur `volume_corrige_15c` seul) est un **exemple de dérive** entre environnements — **corrigée** et **tracée** (voir `CHANGELOG.md`, `current_checkpoint.md`, migration `20260404120000_sorties_after_insert_trg_coalesce_volume_15c.sql`).
- **Validations STAGING récentes** (DB tests / contrôles manuels sur le critique) ont confirmé sur **STAGING** : alignement **VOL15** frontend, schéma **ASTM** utilisable, **RLS** attendu sur `stocks_adjustments`, et enchaînements **réception → stock**, **sortie → stock → log** — voir **`current_checkpoint.md`** (section dédiée) et **`CHANGELOG.md`**.

---

## CONCLUSION

Ce pack est la référence opérationnelle du projet.

Il doit rester :
- à jour
- cohérent avec la DB
- simple et utilisable

# Runbook — Migration volumétrique PROD (ML_PP MVP)

**Document** : Procédure officielle de migration volumétrique production après validation STAGING.  
**Version** : 1.0  
**Contexte** : ML_PP MVP — ERP logistique pétrolier — Stack Flutter Web + Riverpod + GoRouter + Supabase PostgreSQL.  
**Référence technique** : ASTM / API MPMS 11.1.

---

## 1. Objectif

- Préparer la migration volumétrique de l’environnement **PROD** après validation complète en **STAGING**.
- Garantir la **cohérence des calculs de volume corrigé à 15°C** en production.
- Garantir la **traçabilité** des opérations et des décisions.
- Garantir une **possibilité de rollback** documentée et exécutable.

Ce runbook est un **document d’exécution contrôlée**, pas un script automatique. Chaque étape doit être validée avant passage à la suivante.

---

## 2. Portée

| Périmètre | Détail |
|-----------|--------|
| **Environnement cible** | Production (PROD) uniquement. |
| **Données concernées** | Réceptions, sorties produit, stocks dérivés (snapshots, vues, logs) à impact volumétrique. |
| **Hors périmètre** | STAGING (déjà validé) ; autres environnements. |

---

## 3. Références techniques

| Élément | Valeur |
|--------|--------|
| **PR** | #90 (merge dans `main`) |
| **Commit (squash)** | `25422eb` |
| **Tag** | `v0.9-volumetric-staging` |
| **Stratégie projet** | STAGING FIRST — validation complète en STAGING, puis seulement PROD. |

---

## 4. Préconditions obligatoires

Avant toute exécution en PROD, les conditions suivantes doivent être **toutes** remplies :

1. **STAGING validé** : Volumétrie 15°C validée en STAGING ; **STAGING homogène** — un seul moteur volumétrique (lookup-grid) pour réceptions **et** sorties (voir investigation 2026-03-07). En cas de STAGING hybride (réceptions = lookup-grid, sorties = golden), migration PROD = NO-GO.
2. **Moteur cible** : Lookup-grid engine (`astm.compute_v15_from_lookup_grid`, table `astm_lookup_grid_15c`) validé en STAGING pour réceptions et sorties. Golden engine = outil de validation uniquement.
3. **Triggers DB** : Triggers réception et sortie validés en STAGING (moteur lookup-grid unique) et déployés en PROD selon la release.
4. **Sauvegarde PROD complète** : Backup full de la base PROD réalisé et validé (restauration testée si possible).
5. **Fenêtre d’intervention** : Validée par le métier ; pas de sorties / réceptions en cours pendant la fenêtre.
6. **Accord explicite** : Accord écrit ou tracé (email, ticket, décision) avant toute opération de purge / replay, conformément à la gouvernance d’immutabilité (voir section 6 et 12).

---

## 5. Contexte métier et données PROD actuelles

| Élément | Valeur / remarque |
|--------|-------------------|
| **Réceptions existantes en PROD** | 8. |
| **Camions non encore encodés** | 2. |
| **Intention métier** | Repartir sur des bases cohérentes volumétriquement si la migration est lancée. |
| **Contrainte** | La migration PROD ne doit être exécutée qu’après décision contrôlée et documentation de la stratégie de purge/replay face à l’immutabilité. |

---

## 6. Risques et contraintes critiques

### 6.1 Immutabilité des tables

Les tables **`receptions`** et **`sorties_produit`** sont **immutables en écriture corrective** en conditions normales : pas de `DELETE` ni d’`UPDATE` direct sur ces tables sans procédure exceptionnelle validée.

- **Interdit** : Exécuter en PROD une commande du type `DELETE FROM receptions` ou `UPDATE receptions SET ...` comme étape standard du runbook.
- **À confirmer avant exécution** : Toute purge ou replay doit passer par une **stratégie contrôlée** validée par le projet (RPC admin dédiée, procédure de maintenance avec désactivation temporaire contrôlée des garde-fous, ou autre mécanisme validé). Ce point **doit être validé avant exécution réelle en PROD**.
- Le présent runbook **ne décrit pas** la procédure de purge/replay elle-même ; il en exige la **validation préalable** et l’exécution dans le cadre d’une séquence contrôlée.

### 6.2 Autres risques

| Risque | Mitigation |
|--------|------------|
| Exécution sur le mauvais environnement | Vérifier `public.app_settings` et l’URL / config pour confirmer environnement = production. |
| Perte de données | Backup complet obligatoire avant toute opération ; pas d’étape destructive sans backup validé. |
| Incohérence stock / volumes | Vérifications post-migration obligatoires ; critères GO/NO-GO stricts. |
| Rollback impossible | Backup testé ; conditions de rollback documentées et journalisées. |

---

## 7. Checklist pré-exécution

Cocher chaque point avant de lancer la procédure :

- [ ] STAGING validé (volumétrie, réceptions, sorties) et **homogène** (moteur lookup-grid unique pour réceptions et sorties — voir `docs/POST_PROD/ASTM/2026-03-07_INVESTIGATION_STAGING_PROD_VOLUMETRIC_ALIGNMENT.md`).
- [ ] Lookup-grid engine chargé et cohérent en STAGING (table `astm_lookup_grid_15c`, batch actif).
- [ ] Triggers réception et sortie vérifiés (présents et actifs en PROD selon release).
- [ ] Sauvegarde PROD complète réalisée et validée (liste des objets sauvegardés, test de restauration si possible).
- [ ] Fenêtre d’intervention validée par le métier (pas de réceptions/sorties en cours).
- [ ] Stratégie de purge/replay (face à l’immutabilité) **validée** et documentée — procédure ou RPC admin identifiée.
- [ ] Accord explicite obtenu pour toute opération de purge/replay.
- [ ] Vérifications de la section 8 effectuées (app_settings, comptages, écritures à impact volumétrique).

---

## 8. Vérifications à effectuer avant migration

### 8.1 Configuration et environnement

```sql
-- Confirmer que l'environnement est bien la production
SELECT key, value FROM public.app_settings WHERE key IN ('environment', 'app_env');
```

- Vérifier que `environment` ou équivalent indique **production**.
- S’assurer que l’exécution des commandes se fait bien sur la base PROD (URL, projet Supabase).

### 8.2 Audit des données existantes

Exécuter et consigner les résultats (pour comparaison post-migration et rollback) :

```sql
-- Comptages
SELECT 'receptions' AS table_name, COUNT(*) AS cnt FROM public.receptions
UNION ALL
SELECT 'sorties_produit', COUNT(*) FROM public.sorties_produit
UNION ALL
SELECT 'stocks_journaliers', COUNT(*) FROM public.stocks_journaliers;
-- Adapter selon les tables snapshot / logs existantes (ex. stocks_snapshot, log_actions).
```

- Lister les **écritures existantes à impact volumétrique** (réceptions, sorties, éventuels snapshots) : nombre d’enregistrements, plages de dates, citernes/produits concernés.
- Confirmer la **stratégie de replay** : quelles données seront recréées ou recalculées, et par quel mécanisme (sans purge directe non validée).

---

## 9. Procédure détaillée (étape par étape)

Séquence logique à suivre. Chaque phase doit être validée avant la suivante.

### Phase 1 — Backup complet

1. Lancer un backup complet de la base PROD (pg_dump ou mécanisme Supabase/cloud).
2. Vérifier l’intégrité du backup (liste des objets, test de restauration sur une copie si possible).
3. **Checkpoint** : Pas de modification en PROD tant que le backup n’est pas validé.

### Phase 2 — Audit des données existantes

1. Exécuter les requêtes de la section 8.2.
2. Consigner les comptages et, si pertinent, un export de référence (ids, volumes, dates) pour réceptions et sorties.
3. Documenter les écritures à impact volumétrique et la stratégie de replay retenue.

### Phase 3 — Validation de la stratégie d’intervention

1. Confirmer que la stratégie de purge/replay est **validée** (compatible gouvernance, immutabilité, procédure ou RPC admin).
2. Obtenir l’accord explicite (métier / tech lead) pour l’exécution.
3. **Checkpoint** : Pas d’exécution de purge/replay tant que cette validation n’est pas obtenue.

### Phase 4 — Préparation du replay

1. Préparer les artefacts nécessaires (scripts, paramètres, ordre d’exécution) selon la stratégie validée.
2. Vérifier que les scripts ne ciblent que PROD et qu’un garde-fou (ex. variable d’environnement, confirmation) est en place.
3. Planifier l’ordre : désactivation éventuelle temporaire des garde-fous uniquement dans le cadre de la procédure validée, puis replay, puis réactivation.

### Phase 5 — Exécution contrôlée

1. Exécuter **uniquement** les opérations prévues par la stratégie validée (pas de `DELETE`/`UPDATE` direct sur `receptions` ou `sorties_produit` hors procédure validée).
2. Exécuter étape par étape ; consigner chaque commande ou lot exécuté et le résultat.
3. En cas d’erreur : arrêt, analyse, décision (rollback si nécessaire — voir section 11).

### Phase 6 — Vérification des résultats

1. Rejouer les contrôles de la section 10 (vérifications post-migration).
2. Consigner les résultats et tout écart.

### Phase 7 — Validation métier finale

1. Présenter les résultats (volumes, stocks, cohérence) au métier.
2. Obtenir la validation explicite avant de considérer la migration terminée.
3. Journaliser la décision (log_actions ou document de release).

---

## 10. Vérifications post-migration

À effectuer après la phase d’exécution contrôlée :

| Vérification | Critère |
|--------------|---------|
| **Volumes réception** | Cohérence des volumes corrigés 15°C avec la logique validée en STAGING (golden path). |
| **Volumes sortie** | Cohérence des volumes sortie avec les références et l’état des réceptions. |
| **Vue `v_stock_actuel`** | Cohérence des stocks par citerne/produit ; pas d’incohérence de somme (réceptions − sorties). |
| **Stock négatif** | Aucun stock négatif non justifié. |
| **Références terrain / ASTM** | Si applicable, comparaison avec références terrain ou ASTM_APP / SEP dans les tolérances définies par le projet. |
| **Logs** | Contrôle des logs applicatifs et DB ; pas d’erreur bloquante ; événements de migration tracés. |
| **Stabilité applicative** | L’application démarre, les écrans réception/sortie et stock se chargent sans erreur. |

Tout écart doit être documenté et décidé (accepté avec réserve ou rollback).

---

## 11. Critères GO / NO-GO

### GO (migration considérée réussie)

- Toutes les vérifications de la section 10 sont passées.
- Aucun écart volumétrique inacceptable (selon tolérances projet).
- Cohérence des stocks validée ; pas de stock négatif anormal.
- Procédure de purge/replay utilisée était **validée** et conforme à l’immutabilité.
- Rollback possible (backup disponible et testé si nécessaire).
- Validation métier finale obtenue.

### NO-GO (arrêt ou rollback)

- **STAGING non homogène** (réceptions et sorties n’utilisent pas le même moteur volumétrique — voir investigation 2026-03-07).
- **Écart volumétrique** au-delà des tolérances définies.
- **Incohérence de stock** ou stock négatif non résolu.
- **Impossibilité de rollback** (backup absent ou invalide).
- **Procédure de purge/replay non validée** (ex. purge directe sur `receptions`/`sorties_produit` sans mécanisme validé).
- Erreur bloquante lors des vérifications ou refus métier.

En cas de NO-GO : appliquer la section 11 (Rollback), documenter la cause et la décision.

---

## 12. Rollback / restauration

### 12.1 Conditions de déclenchement

- Échec des vérifications post-migration (NO-GO).
- Décision explicite de revenir en arrière (métier ou technique).
- Incident critique pendant ou après la migration.

### 12.2 Procédure

1. Arrêter toute opération en cours sur PROD.
2. Restaurer la base PROD à partir du **backup** réalisé en phase 1.
3. Valider la restauration (comptages, échantillon de données, test applicatif).
4. **Journaliser** la décision de rollback (date, raison, acteur) dans les logs projet ou le document de release.

### 12.3 Limites

- Les données enregistrées entre le backup et le rollback sont perdues sauf procédure spécifique (ex. export préalable). La fenêtre d’intervention doit minimiser cette période.

---

## 13. Notes importantes et limites connues

### 13.1 Moteur volumétrique

- La fonction **`astm.calculate_ctl_54b_15c_official_only(...)`** existe en base mais **lève volontairement** l’exception **`ASTM_OFFICIAL_ENGINE_NOT_IMPLEMENTED_YET`**. Elle **ne doit pas** être utilisée comme moteur de migration.
- **Investigation 2026-03-07** : En STAGING, deux moteurs ont été identifiés — **golden engine** (domaine étroit) et **lookup-grid engine** (grille 63 lignes, domaine 820–860 / 10–40). Les réceptions utilisaient le lookup-grid ; les sorties le golden → STAGING **hybride**. Décision : **NO-GO migration PROD** tant que STAGING n’est pas homogène.
- **Cible** : **Lookup-grid engine unique** (`astm.compute_v15_from_lookup_grid`, table `astm_lookup_grid_15c`) pour réceptions **et** sorties. Golden engine = outil de validation uniquement. La migration PROD doit s’appuyer sur le moteur validé en STAGING (lookup-grid) après homogénéisation. Voir `docs/POST_PROD/ASTM/2026-03-07_INVESTIGATION_STAGING_PROD_VOLUMETRIC_ALIGNMENT.md`.

### 13.2 Immutabilité et purge

- Une **purge directe** (ex. `DELETE FROM receptions`) **n’est pas compatible** avec la gouvernance actuelle sans procédure exceptionnelle validée.
- La migration PROD **ne doit pas être exécutée** tant que la **procédure de purge/replay** n’est pas **validée** face à l’immutabilité (RPC admin, procédure de maintenance, désactivation temporaire contrôlée, ou autre mécanisme validé par le projet).

### 13.3 Sémantique et surveillance

- La **sémantique des densités en sortie** doit rester **surveillée et documentée** (champs utilisés, convention 15°C vs observée).
- Toute évolution vers le moteur « official_only » fera l’objet d’une mise à jour de ce runbook et d’une validation STAGING préalable.

---

## 14. Résumé exécutif

| Élément | Contenu |
|--------|--------|
| **Objet** | Migration volumétrique PROD après validation STAGING ; cohérence 15°C, traçabilité, rollback. |
| **Références** | PR #90, commit 25422eb, tag v0.9-volumetric-staging. |
| **Prérequis** | STAGING validé et **homogène** (lookup-grid unique), backup PROD, stratégie purge/replay validée, accord explicite. |
| **Interdit** | Purge directe sur `receptions`/`sorties_produit` sans procédure validée. |
| **À confirmer avant PROD** | Procédure de purge/replay face à l’immutabilité ; environnement et comptages. |
| **GO** | Vérifications OK, pas d’écart inacceptable, rollback possible, validation métier. |
| **NO-GO** | Écart volumétrique, incohérence stock, rollback impossible, procédure non validée. |

---

*Document runbook — Migration volumétrique PROD — ML_PP MVP — Ne pas exécuter en PROD sans avoir validé les préconditions et la stratégie d’intervention.*

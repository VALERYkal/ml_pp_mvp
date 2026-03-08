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

## 2.9 — Purge contrôlée PROD (CDR-aware)

### 2.9.1 Contexte métier

Les 8 réceptions existantes en PROD sont des réceptions MONALUXE adossées à des **cours_de_route** (CDR).

Séquence métier :

1. CDR créé → statut **ARRIVE**
2. Statut ARRIVE → réception possible
3. Réception validée **consomme** le CDR (évolution vers un état aval, ex. DECHARGE)

Si l’on purge les réceptions **sans** restaurer le statut des CDR, ceux-ci restent dans un état aval et ne peuvent plus être réceptionnés. La purge doit donc être **CDR-aware** : remise des CDR concernés au statut ARRIVE après suppression des réceptions et de leurs effets.

### 2.9.2 Objectif réel de la purge

L’objectif n’est pas de « supprimer des données » mais de **remettre la base dans l’état métier** suivant :

- **8 CDR MONALUXE** au statut **ARRIVE**
- **Aucune réception**
- **Aucun stock dérivé** (stocks_journaliers, stocks_snapshot)
- Système **prêt à rejouer les réceptions** après migration ASTM lookup-grid

### 2.9.3 Périmètre de la purge

| Objet | Impact |
|-------|--------|
| **receptions** | Suppression des 8 enregistrements (dans le cadre de la procédure validée). |
| **stocks_journaliers** | Purge des lignes liées aux réceptions. |
| **stocks_snapshot** | Purge des snapshots impactés. |
| **log_actions** | Purge ou conservation selon politique projet (traçabilité vs replay). |
| **cours_de_route** | Remise du **statut** des 8 CDR concernés à **ARRIVE**. |

### 2.9.4 Ordre opératoire métier

1. **Identifier les réceptions** : lister les 8 réceptions PROD (ids, CDR liés).
2. **Identifier les CDR liés** : lister les 8 CDR MONALUXE concernés (ids, statut actuel).
3. **Purger les effets de réception** : supprimer ou annuler les écritures dans `stocks_journaliers`, `stocks_snapshot`, et les logs associés selon la procédure validée.
4. **Supprimer les réceptions** : exécuter la suppression des 8 réceptions dans le cadre de la procédure exceptionnelle validée (RPC admin ou équivalent).
5. **Remettre les CDR à ARRIVE** : mettre à jour le statut des 8 CDR concernés vers **ARRIVE**.
6. **Vérifier** : confirmer que les 8 CDR sont de nouveau réceptionnables (statut ARRIVE, pas de réception orpheline).
7. **Lancer la migration volumétrique** : déploiement schéma ASTM, triggers lookup-grid, puis rejeu des réceptions avec le moteur ASTM.

### 2.9.5 Résultat attendu

Après purge contrôlée CDR-aware :

| Table / objet | Valeur attendue |
|---------------|-----------------|
| **receptions** | 0 |
| **stocks_journaliers** | 0 |
| **stocks_snapshot** | 0 |
| **CDR MONALUXE concernés** | 8, statut = **ARRIVE** |

Ces 8 CDR pourront être **réceptionnés à nouveau** avec le moteur ASTM lookup-grid après migration.

### Final SQL purge sequence (CDR-aware reset)

La purge est **CDR-aware** : les réceptions sont supprimées avec leurs effets dérivés (logs, stocks_journaliers RECEPTION, stocks_snapshot), puis les CDR concernés sont rouverts au statut **ARRIVE**. Le stock journalier de type **SYSTEM** (ligne de base) est **préservé** ; seuls les enregistrements dérivés des réceptions sont supprimés.

```sql
begin;

set local lock_timeout = '10s';
set local statement_timeout = '5min';

create temporary table tmp_receptions_to_purge as
select
  id as reception_id,
  cours_de_route_id
from public.receptions;

select count(*) as receptions_to_purge
from tmp_receptions_to_purge;

delete from public.log_actions
where module = 'receptions'
  and details->>'reception_id' in (
    select reception_id::text
    from tmp_receptions_to_purge
  );

delete from public.stocks_snapshot
where citerne_id in (
  '2ed755b4-0306-4c7d-a6cd-1cc7de618625',
  '91d2078b-8e19-43c2-bf33-322a42cd4e94'
)
and proprietaire_type = 'MONALUXE'
and produit_id = '22222222-2222-2222-2222-222222222222';

delete from public.stocks_journaliers
where source = 'RECEPTION'
  and proprietaire_type = 'MONALUXE'
  and produit_id = '22222222-2222-2222-2222-222222222222'
  and citerne_id in (
    '2ed755b4-0306-4c7d-a6cd-1cc7de618625',
    '91d2078b-8e19-43c2-bf33-322a42cd4e94'
  );

delete from public.receptions
where id in (
  select reception_id
  from tmp_receptions_to_purge
);

update public.cours_de_route
set statut = 'ARRIVE'
where id in (
  select cours_de_route_id
  from tmp_receptions_to_purge
);

select count(*) as receptions_after
from public.receptions;

select count(*) as sorties_after
from public.sorties_produit;

select count(*) as sj_reception_after
from public.stocks_journaliers
where source = 'RECEPTION';

select count(*) as snapshots_after
from public.stocks_snapshot
where citerne_id in (
  '2ed755b4-0306-4c7d-a6cd-1cc7de618625',
  '91d2078b-8e19-43c2-bf33-322a42cd4e94'
)
and proprietaire_type = 'MONALUXE'
and produit_id = '22222222-2222-2222-2222-222222222222';

select id, statut
from public.cours_de_route
where id in (
  select cours_de_route_id
  from tmp_receptions_to_purge
)
order by id;

commit;
```

**Résultats attendus après purge**

- `receptions` = 0  
- `sorties_produit` = 0  
- `stocks_journaliers` : conservation uniquement de la ligne de base SYSTEM  
- `stocks_snapshot` : vide (0 ligne pour les citernes/produit concernés)  
- Les 8 CDR repassés au statut **ARRIVE**

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

## A.5 bis — Schema Alignment (PROD → STAGING)

### Purpose

Before installing the ASTM volumetric engine in production, the schema of the operational tables must be aligned with the STAGING environment.

Recent changes introduced more explicit density fields used by the lookup-grid volumetric engine. Production still contains a legacy field (`densite_a_15`) that is no longer the canonical structure used in STAGING. To ensure that the volumetric triggers and functions can be migrated safely, the schema must be **additively** aligned.

### Alignment Strategy

The alignment follows a strict **additive** strategy:

- Existing columns in production are **preserved**
- New columns introduced in STAGING are **added** in PROD
- **No destructive** migration is performed at this stage
- Legacy fields remain temporarily available for backward compatibility

This minimizes risk during the PROD migration.

### Table: `public.receptions`

| | |
|---|---|
| **Columns currently in PROD** | `densite_a_15` |
| **Columns present in STAGING but missing in PROD** | `densite_a_15_g_cm3`, `densite_a_15_kgm3`, `densite_observee_kgm3` |
| **Migration action** | Add the missing columns in PROD. |

Example migration:

```sql
alter table public.receptions
add column if not exists densite_a_15_g_cm3 double precision,
add column if not exists densite_a_15_kgm3 double precision,
add column if not exists densite_observee_kgm3 double precision;
```

### Table: `public.sorties_produit`

| | |
|---|---|
| **Columns currently in PROD** | `densite_a_15` |
| **Columns present in STAGING but missing in PROD** | `densite_a_15_g_cm3`, `densite_a_15_kgm3` |
| **Migration action** | Add the missing columns in PROD. |

Example migration:

```sql
alter table public.sorties_produit
add column if not exists densite_a_15_g_cm3 double precision,
add column if not exists densite_a_15_kgm3 double precision;
```

### Legacy field policy

The field **`densite_a_15`** remains temporarily in the schema for compatibility with historical data and older application code. It will be deprecated only after:

- full validation of the lookup-grid volumetric engine in production
- confirmation that all application paths use the new density fields

**No drop or rename** of legacy fields occurs in this migration.

### Migration order (updated)

The correct execution order for the production migration is now:

1. **Schema alignment** (this section)
2. ASTM schema and routines installation
3. Lookup-grid dataset installation
4. Controlled CDR-aware purge
5. Activation of volumetric triggers
6. Smoke tests
7. Resume operations

### Status

- Schema delta identified and documented.
- Migration is additive and non-destructive.
- The actual SQL will be executed during the production migration runbook.

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

## 14. Volumetric Rounding Policy (Reception vs Sortie)

### Purpose

This section clarifies the **rounding policy** used by the volumetric engine in ML_PP MVP.

The volumetric engine computes **Volume@15°C** using the ASTM lookup-grid interpolation. However, the system **intentionally** applies different rounding rules for **receptions** and **sorties**, reflecting operational practices in petroleum logistics.

### Reception volumetrics

For **receptions**, the system stores the calculated value with **one decimal precision**.

The computation chain is:

- `volume_15c = volume_ambiant × VCF`  
  where: **VCF** = lookup-grid interpolation result

The function responsible for the calculation is:

- `astm.compute_v15_from_lookup_grid(...)`

The final stored value is:

- `volume_15c_l := round(volume_ambiant × VCF, 1)`

This value is written into:

- **`receptions.volume_15c`**

The rationale is to preserve a slightly higher precision for incoming product measurements.

### Sortie volumetrics

For **sorties**, the system applies an **operational rounding to the nearest liter**.

The sortie trigger uses the same lookup-grid volumetric engine but rounds the final result to an **integer liter**. This reflects operational practice where deliveries are typically managed in whole liters.

Therefore:

- `volume_corrige_15c := round(volume_15c)`

This value is stored in:

- **`sorties_produit.volume_corrige_15c`**

### Resulting policy

The system therefore uses the following rounding convention:

| Operation | Stored Precision |
|-----------|------------------|
| Reception | 1 decimal        |
| Sortie    | integer liter    |

This policy is **intentional** and ensures:

- stable volumetric calculations
- compatibility with operational delivery measurements
- predictable stock reconciliation

### Important operational note

Because receptions store a decimal precision and sorties round to the nearest liter, **small differences below 0.5 L** may occur in theoretical reconciliation. These differences are **expected and acceptable** within operational tolerance. The lookup-grid engine itself remains **deterministic and consistent** across both flows.

### Governance

This rounding policy must remain consistent across:

- database triggers
- volumetric functions
- stock computation logic
- reporting layers

**Any modification to rounding precision** must be treated as a **controlled change** to the volumetric engine.

---

## 15. Résumé exécutif

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

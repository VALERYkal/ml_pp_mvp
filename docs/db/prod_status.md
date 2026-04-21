# PROD STATUS — ML_PP MVP

## ROLE
Donner l’état actuel de la base de production et sécuriser toute intervention.

## UPDATE FREQUENCY
À chaque modification en production (migration, correction, incident).

---

## STATUT ACTUEL

- **Environnement** : PRODUCTION  
- **État général** : stable  
- **Alignement avec staging** : aligné sur **logique critique** (débit after-insert sortie @15 °C) ; **lot fournisseur** aligné sur STAGING pour **intégrité CDR ↔ lot** et **workflow statut** (déploiement documenté **2026-04-07**) ; **finance fournisseur lot** : passage PROD initial **2026-04-12** (**GO contrôlé / sous surveillance**) ; **session 2026-04-19** : **structure PROD alignée** sur le read model STAGING durci pour **`v_fournisseur_facture_lot`** (**LEFT JOIN** agrégat réceptions, **`A_RAPPROCHER`**, **recalcul paiement** depuis **`fournisseur_paiement_lot_min`**, colonnes **`lot_reference`** / **`fournisseur_nom`**) + **index unique** **`idx_fournisseur_facture_lot_min_one_facture_per_lot`** **appliqué / confirmé** ; **aucune ligne** dans **`fournisseur_facture_lot_min`** en PROD au moment du contrôle → **validation structurelle** et requêtes de cohérence **sans dataset métier facture/paiement réel** ; **validation métier** (premier cas réel ou test contrôlé) **à réaliser** ; **écart structurel mineur** vs STAGING hors périmètre finance lot : **`app_settings`** et table **`fournisseur_facture_min`** absents d’un côté — **`fournisseur_facture_min`** **non utilisée** par les vues finance lot en STAGING → **non bloquant** pour ce périmètre ; projection **20 °C** et seuils **provisoires** ; périmètre global (doc, legacy) pouvant rester **partiel** ; **session de debug 2026-04-20/21** : incident critique Réception PROD diagnostiqué puis **résolu** (cause racine confirmée : absence de `USAGE` sur schéma `astm` ; correctif appliqué le 2026-04-21). Flux Réception désormais **opérationnel** en PROD ; surveillance post-fix maintenue.

**Tables critiques** : `cours_de_route`, `fournisseur_lot`, `fournisseur_facture_lot_min`, `fournisseur_paiement_lot_min`, `receptions`, `sorties_produit`, `stocks_journaliers`, `stocks_snapshot`, `stocks_adjustments`, `log_actions`.

**Lot fournisseur (2026-04-07)** :

- module actif en production
- contraintes métier enforcées en base de données

**Implémentation** :

- trigger : `trg_cours_de_route_enforce_fournisseur_lot`
- fonction : `check_cdr_fournisseur_lot_liaison`

**Règles appliquées** :

- cohérence fournisseur obligatoire (CDR ↔ lot)
- cohérence produit obligatoire
- rattachement interdit selon statut CDR (ex: DECHARGE)
- modification interdite si lot fermé

→ la cohérence métier du lien CDR ↔ lot est désormais garantie par la DB

**Workflow statut lot** :

- trigger : `trg_fournisseur_lot_statut_transition`
- fonction : `check_fournisseur_lot_statut_transition`
- CHECK : `fournisseur_lot_statut_check`

**Règles appliquées** :

- INSERT uniquement en `ouvert`
- `ouvert` → `cloture`
- `cloture` → `facture`
- retours arrière interdits
- statuts invalides interdits

→ le cycle de vie du lot est désormais garanti par la DB

**Finance fournisseur lot (2026-04-12)** — déploiement PROD en **GO contrôlé / sous surveillance** (pas de revendication de cycle **pleinement industrialisé** sans nuance) :

- **Application / front** : fonctionnalités **versionnées dans le dépôt** ; **build Flutter Web** : génération **`build/web`** réussie (session **2026-04-19**) ; **déploiement Firebase** vers utilisateurs finaux : **non confirmé terminé** dans ce document.
- chaîne métier cible : **LOT → Σ réceptions → total_20c → facture → rapprochement → paiement** ; pivot **`fournisseur_lot`**
- fonction : `public.compute_volume_20c_from_reception(...)`
- vue : `public.v_reception_20c`
- tables : `public.fournisseur_facture_lot_min`, `public.fournisseur_paiement_lot_min`
- vues : `public.v_fournisseur_rapprochement_lot_min`, `public.v_fournisseur_facture_lot` — **smoke** « exécutable » **documenté** lors du passage **2026-04-12** ; **définition SQL effective** sur PROD pour **`v_fournisseur_facture_lot`** (read model durci + enrichissements) : **alignée** sur STAGING **à l’issue de la session 2026-04-19** (voir **DERNIÈRE INTERVENTION**) — **sans** revendication de parcours métier complet **LOT → FACTURE → PAIEMENT** déjà rejoué sur **données réelles PROD**
- triggers sur `public.fournisseur_paiement_lot_min` : `trg_fournisseur_paiement_lot_min_after_ins`, `trg_fournisseur_paiement_lot_min_check_overpay`
- **projection 20 °C** : héritée du prototype validé en STAGING puis répliquée en PROD — **provisoire** ; **non** présentée comme formule définitivement figée
- garde-fous d’intervention : **backup PROD** avant migration ; **migration exécutée avec succès** ; **rotation du mot de passe DB** après intervention

**`public.v_stock_actuel`** : exécutable ; lit `v_stocks_snapshot_corrige`. Colonnes : `depot_id`, `citerne_id`, `produit_id`, `proprietaire_type`, `stock_ambiant`, `stock_15c`, `last_movement_at`, `updated_at`, `stock_ambiant_base`, `stock_15c_base`, `delta_ambiant_total`, `delta_15c_total`. Au moins une ligne avec `delta_ambiant_total = 10` et `delta_15c_total = 10`.

**Triggers `receptions`** : `receptions_after_ins` → `reception_after_ins_trg()` ; `trg_00_receptions_block_update_delete` ; `trg_receptions_check_cdr_arrive` ; `trg_receptions_check_produit_citerne` ; `trg_receptions_compute_15c_before_ins` ; `trg_receptions_log_created` ; `trg_receptions_set_created_by` ; `trg_receptions_set_volume_ambiant`.

**Triggers `sorties_produit`** : `trg_sorties_after_insert` → `sorties_after_insert_trg()` ; `trg_00_sorties_produit_block_update_delete` ; `trg_00_sorties_set_created_by` ; `trg_01_sorties_set_volume_ambiant` ; `trg_02_sorties_compute_lookup_15c` ; `trg_sortie_before_ins` ; `trg_sortie_before_upd` ; `trg_sorties_check_produit_citerne`.

**ASTM** : schéma `astm` ; `astm.assert_lookup_grid_domain`, `astm.compute_v15_from_lookup_grid`, `astm.lookup_15c_bilinear_v2`. Table `public.astm_lookup_grid_15c` : 63 lignes ; densité 820–860 ; température 10–40.

**Réception** : `reception_after_ins_trg()` → `stocks_journaliers`, `stocks_snapshot` via `stock_snapshot_apply_delta()`, `log_actions`, CDR possible en DECHARGE. `receptions_compute_15c_before_ins` : lookup-grid, **sans** garde `env=staging` en PROD, remplit `volume_15c` ; `volume_corrige_15c` nul ou legacy ; chemin `volume_15c` confirmé.

**Sortie** : `sorties_after_insert_trg()` → `stocks_journaliers` (delta négatif), snapshot via `stock_snapshot_apply_delta()`, `log_actions`. `sorties_compute_15c_before_ins_lookup` : lookup-grid ; `volume_15c` + `volume_corrige_15c` ; legacy partiel sur le chemin volumétrique amont ; densité observée via `densite_a_15_kgm3`. **Débit after-insert** : utilise désormais **`COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0)`** — **aligné sur STAGING**, cohérent avec la migration volumétrique `volume_15c` ; `log_actions.details.volume_15c` harmonisé sur la même coalesce. **Correction appliquée 2026-04-04** (migration `20260404120000_sorties_after_insert_trg_coalesce_volume_15c.sql`).

**Stock** : `stock_upsert_journalier`, `stock_snapshot_apply_delta`, `rebuild_stocks_journaliers` confirmées.

**Comptages (périmètre inspecté)** : CDR 16, réceptions 8, sorties 1, `stocks_journaliers` 3, `stocks_snapshot` 2, `stocks_adjustments` 1, `log_actions` 19. Périmètre **réduit** ; cohérent ; faible volumétrie **sur ce périmètre** uniquement.

**`stocks_adjustments`** : 1 ligne — annulation test migration `volume_15c` **2026-03-22** ; `mouvement_type = SORTIE` ; deltas 10 / 10 ; cohérent avec `v_stock_actuel`.

**`log_actions`** : `SORTIE_CREEE`, `SORTIE_VALIDE`, `RECEPTION_CREEE`, `RECEPTION_VALIDE` observés ; coexistence conventions / legacy possible.

**Doc vs PROD** : doc peut citer `receptions_apply_effects()` / `fn_sorties_after_insert()` ; réel : `reception_after_ins_trg()`, `sorties_after_insert_trg()` — désalignement documentaire partiel.

**Migrations** : `auth.schema_migrations`, `realtime.schema_migrations`, `storage.migrations` visibles ; `supabase_migrations.schema_migrations` **non confirmé** ; dernière migration exacte **non confirmé**.

---

## DERNIÈRE INTERVENTION

- **2026-04-21** — **résolution incident critique Réception PROD (suite debug)** :
  - **diagnostic final confirmé** : cause racine = `permission denied for schema astm` ; incident **non** causé par un défaut RLS/triggers/owners sur les objets déjà audités, mais par un privilège d’accès schéma manquant
  - **fix appliqué en PROD** :
    - `GRANT USAGE ON SCHEMA astm TO authenticated;`
    - `GRANT USAGE ON SCHEMA astm TO anon;`
  - **validation post-fix** :
    - création Réception en PROD à nouveau fonctionnelle
    - calcul volumétrique ASTM exécuté correctement
    - pipeline métier validé : **CDR ARRIVE → réception → volume_15c → stock → log_actions**
  - **garde-fou SQL exécuté (STAGING + PROD)** :
    - `anon_execute_all_astm_functions = true`
    - `anon_usage_on_astm = true`
    - `authenticated_execute_all_astm_functions = true`
    - `authenticated_usage_on_astm = true`
    - `has_trg_receptions_compute_15c_before_ins = true`
    - `receptions_trigger_calls_astm_compute = true`
    - `receptions_trigger_calls_astm_guard = true`
  - **divergence restante (ouverte)** : définition de `public.receptions_compute_15c_before_ins()` non identique STAGING/PROD (garde `app_settings/env` encore présente uniquement en STAGING) ; écart **non causal** sur cet incident
  - **conclusion** : incident Réception PROD résolu ; alignement opérationnel PROD rétabli sur ce flux

- **2026-04-21** — **debug PROD approfondi flux Réception (post-alignement finance lot)** :
  - **validation UI / dataset contrôlé en PROD** :
    - UI Finance lot ouverte ; écran liste chargé (vide sans données métier)
    - lot de validation créé : **`PROD-VAL-FINLOT-2026-04-19-001`** ; fournisseur affiché **Kemexon** ; produit **Gasoil/AGO** ; statut **Ouvert**
    - CDR de validation créé et rattaché au lot (volume **100 L**, camion/remorque/transporteur de test)
    - rattachement lot ↔ CDR visible en UI
    - CDR passé à **`ARRIVE`** ; carte/liste CDR affiche le CDR **100 L** avec statut **Arrivé**
    - conclusion visuelle : UI Cours de route exploitable ; lot fournisseur exploitable ; rattachement lot↔CDR validé
  - **tentatives de création Réception en PROD** :
    - formulaire Réception chargé correctement ; CDR de validation prérempli/sélectionnable ; produit + citernes visibles ; aperçus volumétriques affichés
    - enregistrement Réception en échec répété ; message UI : **`Permissions insuffisantes pour créer une réception.`**
    - symptôme réseau observé (DevTools) : **`POST /rest/v1/receptions?select=id`** → **`403 Forbidden`**
    - constat métier : le CDR étant **`ARRIVE`**, l’échec n’est pas imputé à la règle « CDR non arrivé »
  - **investigation DB PROD exécutée** :
    - inspection policies RLS : `receptions`, `stocks_journaliers`, `stocks_snapshot`, `log_actions`, `cours_de_route`
    - inspection triggers `receptions`
    - inspection définitions : `current_user_profile`, `receptions_log_created()`, `reception_after_ins_trg()`, `receptions_set_created_by_default()`
    - contrôle owners / `SECURITY DEFINER` : `reception_after_ins_trg`, `receptions_log_created`, `receptions_set_created_by_default`, `stock_snapshot_apply_delta`, `stock_upsert_journalier`
    - contrôle état RLS / FORCE RLS sur tables critiques
  - **résultats confirmés pendant debug** :
    - `profils` contient `valery@monaluxe.com` avec rôle `admin`
    - alignement confirmé `profils.user_id` = `auth.users.id` pour cet utilisateur
    - `current_user_profile` en PROD défini sur jointure `auth.users` ↔ `profils` via `user_id`
    - flags/owners observés alignés STAGING/PROD :
      - `reception_after_ins_trg` : `SECURITY DEFINER = true`, owner `postgres`
      - `receptions_log_created` : `SECURITY DEFINER = false`, owner `postgres`
      - `receptions_set_created_by_default` : `SECURITY DEFINER = false`, owner `postgres`
      - `stock_snapshot_apply_delta` : `SECURITY DEFINER = true`, owner `postgres`
      - `stock_upsert_journalier` : `SECURITY DEFINER = false`, owner `postgres`
    - conclusion technique : **aucun écart structurel clair STAGING/PROD** démontré sur ces fonctions critiques ; **cause racine non isolée**
  - **policies de diagnostic appliquées en PROD (sans résolution finale)** :
    - ajout policy `UPDATE` sur `stocks_journaliers` (accompagnement upsert)
    - ajout policies permissives `INSERT/UPDATE` sur `stocks_snapshot` (test hypothèse trigger/snapshot)
    - ajout policy `INSERT` permissive sur `log_actions`
    - remplacement/simplification de `insert_receptions_authenticated` sur `public.receptions`
    - malgré ces ajustements, **`POST /rest/v1/receptions?select=id` → `403` persistant** en fin de session
  - **diagnostic applicatif (frontend)** :
    - `main.dart` instrumenté pour debug Supabase Web (options Auth web explicites, logs safe boot/session, listener `onAuthStateChange`)
    - incident Réception PROD **non clos** ; hypothèse « purement frontend » **non validée** comme conclusion
  - **état final intervention** : vérité documentaire restaurée ; PROD modifiée par policies de diagnostic ; incident Réception PROD **toujours ouvert**

- **2026-04-19** — **finance fournisseur lot (alignement PROD sur read model STAGING)** :
  - inventaire **PROD vs STAGING** : très proche ; seul écart structurel relevé hors périmètre bloquant : **`app_settings`** / **`fournisseur_facture_min`** (table **`fournisseur_facture_min`** non utilisée par les vues finance lot en STAGING)
  - **pré-contrôle doublons** avant index unique : **aucun** doublon sur **`fournisseur_lot_id`** dans **`fournisseur_facture_lot_min`**
  - **appliqué / confirmé en PROD** : index unique **`idx_fournisseur_facture_lot_min_one_facture_per_lot`** sur **`public.fournisseur_facture_lot_min (fournisseur_lot_id)`**
  - **appliqué en PROD** : remplacement de **`public.v_fournisseur_facture_lot`** pour alignement sur le modèle STAGING : **LEFT JOIN** agrégat réceptions, **`A_RAPPROCHER`**, **recalcul** **`montant_regle_usd`**, **`solde_restant_usd`**, **`statut_paiement`** depuis agrégat **`fournisseur_paiement_lot_min`**, colonnes **`lot_reference`** et **`fournisseur_nom`**
  - **constat** : **aucune facture** en PROD au moment de la validation → **validation structurelle** uniquement (pas de validation métier sur jeu réel facture/paiement)
  - **hors périmètre prouvé ici** : **triggers** paiement **non modifiés** dans cette intervention (rôle inchangé ; **correctif principal** porté par la **vue**)
- **2026-04-12** — déploiement PROD du module **finance fournisseur lot** :
  - **backup PROD** réalisé avant migration
  - **migration exécutée avec succès**
  - smoke tests techniques validés (ex. `public.v_fournisseur_facture_lot` exécutable ; triggers présents sur `public.fournisseur_paiement_lot_min` : `trg_fournisseur_paiement_lot_min_after_ins`, `trg_fournisseur_paiement_lot_min_check_overpay`)
  - **rotation du mot de passe DB** après intervention
- **2026-04-07** — workflow DB du statut lot fournisseur :
  - ajout trigger + fonction de validation
  - ajout CHECK constraint sur `statut`
  - sécurisation du cycle `ouvert → cloture → facture`
- **2026-04-07** — hardening DB du module lot fournisseur :
  - ajout trigger + fonction de validation
  - sécurisation du rattachement CDR ↔ lot
- **2026-04-06** — déploiement **lot fournisseur** (`fournisseur_lot`, `cours_de_route.fournisseur_lot_id`) après validation STAGING ; smoke fonctionnel PROD documenté par la session (création / liaison).
- **2026-03-22** — ajustement stock lié à un test migration `volume_15c` observé en production  
- **2026-04-04** — investigation structurelle PROD (tables, vue stock, triggers, ASTM, stock, données)  
- **2026-04-04** — correction critique **`sorties_after_insert_trg()`** (alignement STAGING/PROD sur débit @15 °C)  
- Dernière migration exacte : **non confirmé**

---

## CAUSE RACINE CONFIRMÉE

- L’exécution du flux Réception dépend de fonctions volumétriques du schéma **`astm`**.
- Ces appels nécessitent un privilège **`USAGE`** sur le schéma pour les rôles applicatifs effectifs.
- En PROD, l’absence de `USAGE` sur `astm` pour `authenticated`/`anon` provoquait le blocage insert Réception (`POST /rest/v1/receptions?select=id` → `403` côté API/UI).
- Le correctif appliqué (`GRANT USAGE ON SCHEMA astm TO authenticated, anon`) a levé le blocage.

---

## ÉCARTS À RÉPLIQUER DEPUIS STAGING

Réplication **à planifier / exécuter** sur PROD pour les périmètres **non couverts** ci-dessous ; pour **finance fournisseur lot** (read model **B**, création facture **C1**, unicité **C2**, **vue paiement + enrichissements 2026-04-19**) : **répliqué / confirmé sur PROD lors de la session 2026-04-19** — voir **DERNIÈRE INTERVENTION** (reste **validation métier** sur données réelles).  
Sujet Réception PROD : incident **clos** après correctif privilèges schéma `astm` (voir **CAUSE RACINE CONFIRMÉE**).

### Finance fournisseur lot — état post-réplication (2026-04-19)

- migrations de référence (dépôt) : `20260417130000_finance_lot_views_rapprochement_read_model.sql`, `20260417150000_fournisseur_facture_lot_min_unique_fournisseur_lot.sql`, évolutions **vue** **`v_fournisseur_facture_lot`** (recalcul paiement + **`lot_reference`** / **`fournisseur_nom`**) telles qu’**alignées en PROD** session **2026-04-19**
- **index unique** **`idx_fournisseur_facture_lot_min_one_facture_per_lot`** : **présent PROD**
- **vue** **`public.v_fournisseur_facture_lot`** : **définition alignée** (LEFT JOIN, **`A_RAPPROCHER`**, paiement depuis **`fournisseur_paiement_lot_min`**, enrichissements) — **sans** jeu de données facture en PROD au moment du contrôle
- **flux applicatif** : code **versionné** ; **build web** **`build/web`** **généré** ; **déploiement Firebase** : **statut final non attesté** ici

### Autres écarts structurels (hors finance lot read model)

- **`app_settings`** / **`fournisseur_facture_min`** : divergence d’inventaire **non bloquante** finance lot (voir **STATUT ACTUEL**)
- **RLS PROD (réception/stock/logs)** : des policies ont été **modifiées en PROD à des fins de diagnostic** pendant l’incident Réception ; avant toute nouvelle réplication STAGING→PROD, réaliser un **diff propre des policies effectives** (STAGING vs PROD) puis décider un **rollback ciblé** ou un **réalignement documenté**.

---

## POINTS DE VIGILANCE

- **Réception PROD (post-fix 2026-04-21)** :
  - incident `403` clôturé après `GRANT USAGE ON SCHEMA astm` pour `authenticated` et `anon`
  - contrôle `USAGE`/`EXECUTE` ASTM désormais **obligatoire** avant intervention DB critique sur ce périmètre (script de garde-fou : `docs/DB_CHANGES/2026-04-21_astm_grants_guard.sql`)
  - conserver une surveillance ciblée sur les prochaines créations Réception pour confirmer la stabilité
- **Écart STAGING vs PROD — trigger Réception (`receptions_compute_15c_before_ins`)** :
  - STAGING contient une garde `env=staging`
  - PROD ne contient pas cette garde
  - écart documenté comme **non bloquant** à ce stade, mais à conserver dans le suivi d’alignement
- **Politiques RLS PROD manipulées en diagnostic** :
  - des patchs RLS ciblés ont été appliqués sur `receptions`, `stocks_journaliers`, `stocks_snapshot`, `log_actions`
  - **ne pas empiler** de nouveaux patchs PROD sans audit préalable
  - reprise recommandée : (1) audit policies réellement présentes en PROD, (2) diff STAGING↔PROD, (3) correction propre + re-documentation
- **Finance fournisseur lot (PROD)** :
  - module **déployé et présent** en production (**2026-04-12**) — ne pas le traiter comme inexistant côté PROD
  - **GO contrôlé / sous surveillance** : pas d’équivalence avec un module « figé » sans retour terrain
  - projection **20 °C** actuelle : **provisoire** ; issue du **prototype STAGING** puis répliquée en PROD — **non** assimilable à une volumétrie définitivement validée métier
  - seuils de rapprochement : **portés par le SQL** des migrations finance lot **du dépôt** (ex. |écart 20°C| strictement inférieur à **0,001** L → `OK` ; strictement inférieur à **10** L → `TOLERE` ; sinon `LITIGE` ; sans agrégat exploitable → `A_RAPPROCHER`) — **validation métier finale encore requise** ; comportement observé en PROD sur **cas réels finance lot** = **à confirmer** après première facture / test contrôlé
  - **index unique (C2)** : **déployé PROD** **2026-04-19** ; pour toute **nouvelle** instance ou rollback, conserver le **pré-contrôle doublons** avant application :

```sql
SELECT fournisseur_lot_id, count(*)
FROM public.fournisseur_facture_lot_min
GROUP BY fournisseur_lot_id
HAVING count(*) > 1;
```

  - **`fournisseur_lot.statut = facture`** : cycle de vie du lot ; **ne pas** l’équiper à « une facture `fournisseur_facture_lot_min` existe » (voir `docs/db/critical_objects.md`)
  - surveillance active des **premiers cas réels** recommandée
- **Lot fournisseur** :
  - logique métier portée par trigger DB
  - modification directe de `fournisseur_lot_id` soumise à contraintes strictes
  - erreurs bloquantes possibles côté API si incohérence
- **Lot fournisseur (workflow statut)** :
  - statut porté par trigger DB + CHECK constraint
  - toute mise à jour directe de `statut` hors transitions autorisées échoue
  - erreurs bloquantes possibles côté API si transition invalide
- Désalignement documentaire partiel (doc vs triggers réellement branchés).  
- Ajustement stock réel présent (`stocks_adjustments`).  
- Conventions de logs / couches legacy coexistantes.  
- Dernière migration exacte : non confirmé.  
- Sortie : chemin volumétrique partiellement legacy.

---

## REQUÊTES DE VÉRIFICATION

### Smoke test — table critique

```sql
SELECT COUNT(*)
FROM public.receptions;
```

### Smoke test — vue stock

```sql
SELECT *
FROM public.v_stock_actuel
LIMIT 10;
```

### Triggers — receptions

```sql
SELECT tgname, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgrelid = 'public.receptions'::regclass
  AND NOT tgisinternal
ORDER BY tgname;
```

### Triggers — sorties_produit

```sql
SELECT tgname, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgrelid = 'public.sorties_produit'::regclass
  AND NOT tgisinternal
ORDER BY tgname;
```

### Fonctions ASTM

```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'astm'
ORDER BY routine_name;
```

### Dataset ASTM

```sql
SELECT count(*) FROM public.astm_lookup_grid_15c;
```

### Ajustements stock

```sql
SELECT count(*) FROM public.stocks_adjustments;
```

### Lot fournisseur — présence schéma

```sql
SELECT COUNT(*) AS lots_count FROM public.fournisseur_lot;
```

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'cours_de_route'
  AND column_name = 'fournisseur_lot_id';
```

### Lot fournisseur — intégrité CDR ↔ lot

```sql
SELECT tgname
FROM pg_trigger
WHERE tgname = 'trg_cours_de_route_enforce_fournisseur_lot';
```

### Lot fournisseur — workflow statut

```sql
SELECT tgname
FROM pg_trigger
WHERE tgname = 'trg_fournisseur_lot_statut_transition';
```

```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.fournisseur_lot'::regclass
  AND conname = 'fournisseur_lot_statut_check';
```

### Finance fournisseur lot — PROD

```sql
SELECT *
FROM public.v_fournisseur_facture_lot
LIMIT 10;
```

```sql
SELECT *
FROM public.v_fournisseur_rapprochement_lot_min
LIMIT 10;
```

```sql
SELECT tgname
FROM pg_trigger
WHERE tgrelid = 'public.fournisseur_paiement_lot_min'::regclass
  AND NOT tgisinternal
ORDER BY 1;
```

### Référence complémentaire

Voir `docs/DB/critical_objects.md`.

### Diagnostic Réception PROD — policies RLS (à comparer STAGING/PROD)

```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('receptions', 'stocks_journaliers', 'stocks_snapshot', 'log_actions', 'cours_de_route')
ORDER BY tablename, policyname;
```

---

## VALIDATION TECHNIQUE DU FIX

**Contexte :** correction documentée **`sorties_after_insert_trg()`** (2026-04-04, migration versionnée dans le repo). **La documentation n’équivaut pas à une preuve d’exécution** sur l’instance PROD.

À **confirmer** sur la base **PROD** réelle (audit / runbook) :

- **`pg_get_functiondef('public.sorties_after_insert_trg()'::regproc)`** : présence de **`COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0)`** dans le corps — **à confirmer**
- **Test sortie contrôlée** : insert `validee` avec **`volume_15c` renseigné**, **`volume_corrige_15c` NULL** → cohérence **`stocks_journaliers`**, **`stocks_snapshot`**, **`v_stock_actuel`**, **`log_actions.details`** @15 °C — **à confirmer**

Tant que ces points ne sont pas cochés : le pack est **cohérent sur l’intention** ; le **système PROD** reste **à valider** côté exécution.

---

## NOTES

- PRODUCTION maintenue propre : éviter les données de test ou les nettoyer après validation
- Toute intervention en production est critique.  
- Lecture stock : **`public.v_stock_actuel`**.  
- Alignement **complet** sur tout le périmètre : non garanti tant que d’autres écarts (doc, migrations, legacy amont sortie) subsistent — voir points de vigilance.  
- Toute modification doit passer par staging avant déploiement.
- **Finance fournisseur lot** : inventaire PROD et garde-fous d’intervention dans ce fichier ; le scénario de validation détaillé côté STAGING reste décrit dans `docs/DB/staging_status.md` (section **2026-04-12**) — **sans** impliquer que les objets PROD ci-dessus seraient absents.

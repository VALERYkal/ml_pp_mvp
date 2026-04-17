# PROD STATUS — ML_PP MVP

## ROLE
Donner l’état actuel de la base de production et sécuriser toute intervention.

## UPDATE FREQUENCY
À chaque modification en production (migration, correction, incident).

---

## STATUT ACTUEL

- **Environnement** : PRODUCTION  
- **État général** : stable  
- **Alignement avec staging** : aligné sur **logique critique** (débit after-insert sortie @15 °C) ; **lot fournisseur** aligné sur STAGING pour **intégrité CDR ↔ lot** et **workflow statut** (déploiement documenté **2026-04-07**) ; **finance fournisseur lot** **déployé en PROD** (**2026-04-12**) après validation technique — **GO contrôlé / sous surveillance** : projection **20 °C** et seuils de rapprochement **provisoires**, à consolider métier (voir points de vigilance) ; périmètre global (doc, legacy) pouvant rester **partiel**.

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

- **Application** : **UI V1** déployée côté Flutter — navigation GoRouter (`/finance/factures-lot`, détail par `factureId`) ; module **accessible utilisateur** ; paiement **opérationnel depuis l’UI** (écriture **`fournisseur_paiement_lot_min`** ; lecture factures / rapprochement via **vues** ; historique paiements via lecture table minimale ; refresh post-paiement côté app).
- chaîne métier : **LOT → Σ réceptions → total_20c → facture → rapprochement → paiement** ; pivot **`fournisseur_lot`**
- fonction : `public.compute_volume_20c_from_reception(...)`
- vue : `public.v_reception_20c`
- tables : `public.fournisseur_facture_lot_min`, `public.fournisseur_paiement_lot_min`
- vues : `public.v_fournisseur_rapprochement_lot_min`, `public.v_fournisseur_facture_lot` (exécutable en PROD — smoke technique validé)
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

## POINTS DE VIGILANCE

- **Finance fournisseur lot (PROD)** :
  - module **déployé et présent** en production (**2026-04-12**) — ne pas le traiter comme inexistant côté PROD
  - **GO contrôlé / sous surveillance** : pas d’équivalence avec un module « figé » sans retour terrain
  - projection **20 °C** actuelle : **provisoire** ; issue du **prototype STAGING** puis répliquée en PROD — **non** assimilable à une volumétrie définitivement validée métier
  - seuils de rapprochement actuellement câblés (cohérents avec le modèle documenté en STAGING) : **OK** si l’écart est strictement inférieur à **0,5 L** ; **TOLERE** si l’écart est strictement inférieur à **50 L** sans relever de la plage OK ; **LITIGE** sinon — **à confirmer métier** après premiers cas réels
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

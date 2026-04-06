# STAGING STATUS — ML_PP MVP

## ROLE
Donner l’état actuel de la base staging et permettre une vérification rapide avant toute évolution.

## UPDATE FREQUENCY
À chaque migration ou changement significatif en staging.

---

## STATUT ACTUEL

- Environnement : STAGING
- État général : stable
- Alignement avec production : partiel sur le périmètre global ; **logique critique `sorties_after_insert_trg()` (débit @15 °C)** : **PROD alignée sur STAGING** après correction **2026-04-04** (voir `docs/DB/prod_status.md`).

---

## ALIGNEMENT AVEC PRODUCTION

- **PROD** est désormais alignée sur **STAGING** pour :
  - **`sorties_after_insert_trg()`** ;
  - la logique de **débit volumétrique sortie** @15 °C (after-insert) via **`COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0)`**.
- **STAGING** reste la **référence de validation** avant déploiement production.

---

## DERNIÈRES MODIFICATIONS

- **2026-04-07** — **Lot fournisseur (hardening DB)** :
  - ajout du trigger `trg_cours_de_route_enforce_fournisseur_lot`
  - fonction `check_cdr_fournisseur_lot_liaison`
  - validation en DB :
    - cohérence fournisseur CDR ↔ lot
    - cohérence produit CDR ↔ lot
  - blocages métier :
    - rattachement interdit si statut incompatible (ex: DECHARGE)
    - modification interdite si lot fermé
  - tests STAGING OK (erreurs levées correctement)
- **2026-04-06** — **Lot fournisseur** : table `public.fournisseur_lot` déployée ; colonne nullable `public.cours_de_route.fournisseur_lot_id` ajoutée. Smoke test STAGING : création lot, liaison CDR ↔ lot, contrôle cohérence fonctionnelle OK (pas de revendication de couverture exhaustive hors ce périmètre).
- non confirmé — dernière migration exacte non vérifiée (`supabase_migrations.schema_migrations` présente ; entrée la plus récente non confirmée)
- 2026-04-04 — investigation structurelle STAGING (tables, vue stock, triggers, fonctions ASTM, fonctions stock, comptages)
- 2026-04-04 — constat alignement PROD sur `sorties_after_insert_trg()` (documentation pack canonique)

---

## POINTS DE VIGILANCE

- **Doc vs réel :** la documentation peut mentionner `receptions_apply_effects()` et `fn_sorties_after_insert()` ; le wiring observé en STAGING passe par **`reception_after_ins_trg()`** (trigger `receptions_after_ins`) et **`sorties_after_insert_trg()`** (trigger `trg_sorties_after_insert`).
- **Réception :** `trg_receptions_compute_15c_before_ins` → moteur ASTM lookup-grid → `volume_15c` ; `volume_corrige_15c` nul ou legacy selon les cas.
- **Sortie :** volumétrie encore partiellement legacy ; `volume_15c` coexiste avec `volume_corrige_15c` ; `sorties_compute_15c_before_ins_lookup` (ASTM) — entrée densité observée via **`densite_a_15_kgm3`** (legacy) côté chemin observé.
- **Post-insert :** `reception_after_ins_trg()` / `sorties_after_insert_trg()` alimentent `stocks_journaliers`, mettent à jour `stocks_snapshot` via `stock_snapshot_apply_delta()`, journalisent dans `log_actions` ; réception peut passer le CDR en DECHARGE.
- **Fonctions stock confirmées :** `stock_upsert_journalier`, `stock_snapshot_apply_delta`, `rebuild_stocks_journaliers`.
- **ASTM :** schéma `astm` présent ; fonctions observées : `astm.assert_lookup_grid_domain`, `astm.compute_v15_from_lookup_grid`, `astm.lookup_15c_bilinear_v2` ; dataset `public.astm_lookup_grid_15c` — 63 lignes, densité 820–860 kg/m³, température 10–40 °C.
- **`v_stock_actuel` :** exécutable ; lecture depuis **`v_stocks_snapshot_corrige`** ; colonnes : `depot_id`, `citerne_id`, `produit_id`, `proprietaire_type`, `stock_ambiant`, `stock_15c`, `last_movement_at`, `updated_at`, `stock_ambiant_base`, `stock_15c_base`, `delta_ambiant_total`, `delta_15c_total`.
- **Triggers observés — `receptions` :** `receptions_after_ins`, `trg_00_receptions_block_update_delete`, `trg_receptions_check_cdr_arrive`, `trg_receptions_check_produit_citerne`, `trg_receptions_compute_15c_before_ins`, `trg_receptions_log_created`, `trg_receptions_set_created_by`, `trg_receptions_set_volume_ambiant`.
- **Triggers observés — `sorties_produit` :** `trg_sorties_after_insert`, `trg_00_sorties_produit_block_update_delete`, `trg_00_sorties_set_created_by`, `trg_01_sorties_set_volume_ambiant`, `trg_02_sorties_compute_lookup_15c`, `trg_sortie_before_ins`, `trg_sortie_before_upd`, `trg_sorties_check_produit_citerne`.
- **`log_actions` :** actions vues : `RECEPTION_CREEE`, `RECEPTION_VALIDE`, `SORTIE_VALIDE` (cohérent avec le wiring ci-dessus).
- **Comptages (instantané observé) :** `cours_de_route` 9, `receptions` 17, `sorties_produit` 6, `stocks_journaliers` 12, `stocks_snapshot` 4, `stocks_adjustments` 0, `log_actions` 39 — dataset faible, cohérent pour validation contrôlée, **non représentatif** d’une volumétrie production élevée.
- **`stocks_adjustments` :** table présente ; 0 ligne sur l’instantané observé.
- **Lot fournisseur (nouveau périmètre DB)** :
  - contraintes métier désormais portées par trigger
  - toute modification du champ `cours_de_route.fournisseur_lot_id` doit être testée
  - erreurs levées via `RAISE EXCEPTION` → impact direct API / frontend

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

### Triggers — `receptions`

```sql
SELECT tgname
FROM pg_trigger
WHERE tgrelid = 'public.receptions'::regclass
  AND NOT tgisinternal
ORDER BY 1;
```

### Triggers — `sorties_produit`

```sql
SELECT tgname
FROM pg_trigger
WHERE tgrelid = 'public.sorties_produit'::regclass
  AND NOT tgisinternal
ORDER BY 1;
```

### Fonctions — schéma `astm`

```sql
SELECT p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'astm'
ORDER BY p.proname;
```

### Dataset ASTM — volumétrie

```sql
SELECT COUNT(*) AS rows_count
FROM public.astm_lookup_grid_15c;
```

*(Min/max densité et température sur la grille : constat métier documenté dans les points de vigilance ; requête d’agrégation sur colonnes exactes : non confirmé ici.)*

### Lot fournisseur — présence schéma

```sql
SELECT COUNT(*) AS lots_count
FROM public.fournisseur_lot;
```

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'cours_de_route'
  AND column_name = 'fournisseur_lot_id';
```

### Référence complémentaire

Pour les contrôles avancés (procédure, dangers), voir `docs/DB/critical_objects.md`.

---

## NOTES

- STAGING est un environnement expérimental : données incohérentes ou tests destructifs autorisés
- STAGING cohérent et exploitable pour validation avant production.
- Lecture métier du stock : **`public.v_stock_actuel`**.
- Vérifier **PROD** séparément avant toute conclusion d’alignement complet.

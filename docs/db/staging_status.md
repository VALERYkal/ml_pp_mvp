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

- **2026-04-19** — **Finance fournisseur lot — audit DB, durcissement read model paiement, enrichissement vue** :

  1. **Audit et existence des objets (STAGING)**

  - vues confirmées présentes et exploitables :
    - `public.v_fournisseur_facture_lot`
    - `public.v_fournisseur_rapprochement_lot_min`
    - `public.v_reception_20c`

  2. **Structure observée — `v_fournisseur_facture_lot`**

  - colonnes notamment : `facture_id`, `invoice_no`, `deal_reference`, `fournisseur_lot_id`, `nb_receptions`, `total_volume_15c`, `total_volume_20c`, `quantite_facturee_20c`, `ecart_volume_20c`, `statut_rapprochement`, `prix_unitaire_usd`, `montant_total_usd`, `montant_regle_usd`, `solde_restant_usd`, `statut_paiement`, `date_facture`, `date_echeance`, `created_at`
  - fin de définition de vue (sans rupture d’ordre des colonnes existantes) : `lot_reference` (`fl.reference`), `fournisseur_nom` (`fo.nom`) — jointures `LEFT JOIN public.fournisseur_lot fl ON fl.id = f.fournisseur_lot_id`, `LEFT JOIN public.fournisseurs fo ON fo.id = fl.fournisseur_id`
  - contrôle lecture : combinaison **`invoice_no` + `fournisseur_nom` + `lot_reference`** renvoie des valeurs métier lisibles sur données STAGING

  3. **Structure observée — `v_fournisseur_rapprochement_lot_min`**

  - colonnes notamment : `facture_id`, `invoice_no`, `deal_reference`, `fournisseur_lot_id`, `nb_receptions`, `total_volume_15c`, `total_volume_20c`, `quantite_facturee_20c`, `ecart_volume_20c`, `prix_unitaire_usd`, `montant_total_usd`, `statut_rapprochement`

  4. **Comportement `A_RAPPROCHER` (validation réelle)**

  - cas **facture sans agrégat réception** : `nb_receptions` NULL, `total_volume_20c` NULL → `statut_rapprochement = A_RAPPROCHER`
  - cas avec agrégat : comportement **`LITIGE`** conforme attendu sur le cas contrôlé

  5. **Index unique (STAGING)**

  - présence confirmée : `idx_fournisseur_facture_lot_min_one_facture_per_lot` sur `public.fournisseur_facture_lot_min (fournisseur_lot_id)`

  6. **Correction read model — paiement dans `v_fournisseur_facture_lot`**

  - **Avant** : la vue lisait `f.montant_regle_usd`, `f.solde_restant_usd`, `f.statut_paiement` depuis **`fournisseur_facture_lot_min`**
  - **Effet constaté** : cas **sans paiement** pouvait afficher **`solde_restant_usd = 0`** alors que **`montant_total_usd > 0`**
  - **Après** : recalcul **en vue** (agrégat sur **`fournisseur_paiement_lot_min`**, jointure `p.fournisseur_facture_id = f.id`, somme **`montant_paye_usd`**) :
    - `montant_regle_usd = COALESCE(sum, 0)::numeric(18,3)`
    - `solde_restant_usd = (f.montant_total_usd - COALESCE(sum, 0))::numeric(18,3)`
    - `statut_paiement` dérivé en vue : **`A_PAYER`** si payé = 0 ; **`PARTIEL`** si payé < total ; **`PAYE`** sinon

  7. **Validation post-correction (STAGING, valeurs observées)**

  - sans paiement : `montant_total_usd = 89400.000` → `montant_regle_usd = 0.000`, `solde_restant_usd = 89400.000`, `statut_paiement = A_PAYER`
  - sans paiement : `montant_total_usd = 10000.000` → `montant_regle_usd = 0.000`, `solde_restant_usd = 10000.000`, `statut_paiement = A_PAYER`
  - partiel : `montant_total_usd = 10172277.000`, `montant_regle_usd = 5160000.000`, `solde_restant_usd = 5012277.000`, `statut_paiement = PARTIEL`

  8. **Conclusion**

  - read model finance lot **durci** : **LEFT JOIN** + **`A_RAPPROCHER`** + **paiement affiché recalculé depuis les paiements** + **enrichissement fournisseur / lot**
  - **`v_fournisseur_facture_lot`** = **source de lecture consolidée** pour rapprochement, paiement affiché et champs métier lisibles ; la logique d’affichage **ne dépend plus** d’un état dérivé **fragile** lu uniquement sur la table facture pour ces champs

- **2026-04-18** — **Finance fournisseur lot (hardening + création facture + verrouillage)** :

  1. **Hardening du read model (B)**

  - correction du problème de disparition des factures via `JOIN` strict
  - passage en `LEFT JOIN` dans :
    - `public.v_fournisseur_facture_lot`
    - `public.v_fournisseur_rapprochement_lot_min`
  - garantie :
    - une facture reste visible même sans agrégat réceptions
  - ajout du statut :
    - `A_RAPPROCHER`
    - utilisé lorsque :
      - aucun agrégat
      - ou volume 20 °C non disponible
  - canonisation :
    - `statut_rapprochement` est désormais calculé uniquement dans la vue
    - la colonne table `fournisseur_facture_lot_min.statut_rapprochement` n’est plus la vérité de lecture

  2. **Création facture fournisseur (C1)**

  - ajout du flux UI :
    - création facture depuis Finance → Factures lot
  - insertion dans :
    - `public.fournisseur_facture_lot_min`
  - champs envoyés :
    - `fournisseur_lot_id`
    - `invoice_no`
    - `deal_reference`
    - `quantite_facturee_20c`
    - `prix_unitaire_usd`
    - `date_facture`
    - `date_echeance`
  - champs **non** envoyés (DB / générés ou lecture vue) :
    - `montant_total_usd`
    - `statut_rapprochement`
    - soldes
    - statut paiement
  - relecture systématique via :
    - `public.v_fournisseur_facture_lot`

  3. **Verrouillage des lots facturables (C2)**

  - règle métier validée :
    - 1 lot fournisseur = 1 facture fournisseur active
  - vérité :
    - un lot est facturé s’il existe une ligne dans `public.fournisseur_facture_lot_min`
  - implémentation UI :
    - exclusion des lots déjà facturés dans le formulaire
    - dropdown basé sur `fournisseurLotsFacturablesProvider` (côté app)
  - implémentation DB :
    - création index unique :
      - `idx_fournisseur_facture_lot_min_one_facture_per_lot` sur `public.fournisseur_facture_lot_min (fournisseur_lot_id)`
  - effet :
    - impossibilité de créer un doublon même en cas de concurrence

  4. **Résultat fonctionnel**

  - chaîne finance lot désormais complète :
    - `LOT → FACTURE → RAPPROCHEMENT → PAIEMENT`
  - cas validés en STAGING :
    - facture avec agrégat → `OK` / `TOLERE` / `LITIGE`
    - facture sans agrégat → `A_RAPPROCHER`
    - tentative doublon → erreur **23505** (unicité)

  5. **Point de vigilance avant PROD**

  - vérifier qu’aucun doublon n’existe avant création de l’index unique
  - seuils de rapprochement :
    - actuellement pilotés par le SQL (**0,001** L / **10** L)
    - validation métier finale encore requise


- **2026-04-12** — **Finance fournisseur lot (prototype STAGING validé)** :
  - validation d’un flux minimal **lot fournisseur → CDR → réception → projection 20°C → facture lot → rapprochement → paiement**
  - **pivot économique confirmé = `fournisseur_lot`** (et non `reception` seule)
  - création / validation des objets STAGING suivants :
    - fonction `public.compute_volume_20c_from_reception(...)`
    - vue `public.v_reception_20c`
    - table `public.fournisseur_facture_lot_min`
    - table `public.fournisseur_paiement_lot_min`
    - vue `public.v_fournisseur_rapprochement_lot_min`
    - vue `public.v_fournisseur_facture_lot`
    - triggers :
      - `trg_fournisseur_paiement_lot_min_check_overpay`
      - `trg_fournisseur_paiement_lot_min_after_ins`
  - scénario STAGING validé :
    - lot test `TEST-LOT-STAGING-001`
    - CDR lié au lot mis en `ARRIVE`
    - réception test créée avec succès
    - projection `volume_20c` calculée depuis la réception
    - facture lot test créée
    - paiement partiel enregistré
    - surpaiement correctement bloqué via `RAISE EXCEPTION`
  - résultat observé sur le cas test :
    - `total_volume_15c = 11850`
    - `total_volume_20c = 11944.800`
    - `quantite_facturee_20c = 11897.400`
    - `ecart_volume_20c = 47.400`
    - `statut_rapprochement = 'TOLERE'`
    - `statut_paiement = 'PARTIEL'`
  - **important** :
    - la projection **20°C actuelle est une approximation STAGING contrôlée**
    - **non prête PROD** en l’état
    - avant réplication PROD, il faut verrouiller :
      - la formule 20°C définitive
      - les seuils métier `OK / TOLERE / LITIGE`
      - une migration versionnée propre
  - conclusion :
    - le périmètre **finance fournisseur par lot** est **fonctionnel en STAGING**
    - le design cible à retenir est :
      - `LOT → Σ réceptions → total_20c → facture → rapprochement → paiement`


- **2026-04-07** — **Lot fournisseur (workflow statut DB)** :
  - ajout du trigger `trg_fournisseur_lot_statut_transition`
  - ajout de la fonction `check_fournisseur_lot_statut_transition`
  - transition de statuts sécurisée en base :
    - `ouvert` → `cloture`
    - `cloture` → `facture`
  - transitions interdites :
    - `cloture` → `ouvert`
    - `facture` → `cloture`
    - `facture` → `ouvert`
  - INSERT autorisé uniquement avec `statut = 'ouvert'`
  - ajout du CHECK `fournisseur_lot_statut_check`
  - validation STAGING OK
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

- **Finance fournisseur lot (nouveau périmètre STAGING)** :
  - le **lot fournisseur** est désormais le **pivot du rapprochement financier fournisseur**
  - la facture fournisseur doit être **liée au lot** ; la comparaison se fait sur la **somme des réceptions du lot**
  - la vue `public.v_fournisseur_facture_lot` fournit une lecture consolidée :
    - volumes 15°C / 20°C (nullable si **aucun agrégat réceptions** pour le lot — la ligne facture **reste** dans la vue grâce au **LEFT JOIN**)
    - quantité facturée à 20°C
    - écart (nullable si agrégat absent)
    - **`statut_rapprochement` calculé dans la vue** (vérité de lecture app) ; en absence d’agrégat exploitable → **`A_RAPPROCHER`**
    - **`montant_regle_usd`**, **`solde_restant_usd`**, **`statut_paiement`** : **vérité de lecture consolidée** = **calcul en vue** depuis **`fournisseur_paiement_lot_min`** (agrégat des paiements) — **ne pas** se fier aux seules colonnes homonymes persistées sur **`fournisseur_facture_lot_min`** pour reconstruire l’état paiement affiché
    - **`lot_reference`**, **`fournisseur_nom`** : lecture enrichie (jointures lot / fournisseur)
  - **Triggers** `trg_fournisseur_paiement_lot_min_after_ins` / `trg_fournisseur_paiement_lot_min_check_overpay` : **inchangés** dans leur existence ; l’**affichage** consolidé sur la **vue** **ne dépend plus exclusivement** du seul **recalcul persisté en table** pour les champs paiement listés ci-dessus
- **Projection 20°C** :
  - la fonction `public.compute_volume_20c_from_reception(...)` est **provisoire**
  - elle sert à la validation STAGING du module finance fournisseur
  - elle ne doit **pas** être considérée comme formule volumétrique finale pour PROD sans validation complémentaire
- **Tolérances de rapprochement** (vues `v_fournisseur_facture_lot` / `v_fournisseur_rapprochement_lot_min`, seuils tels que déployés dans les migrations finance lot) :
  - `OK` si |écart 20°C| < **0,001** L
  - `TOLERE` si |écart| < **10** L
  - sinon `LITIGE`
  - sans agrégat réceptions (ou `total_volume_20c` NULL) → **`A_RAPPROCHER`**
  - ces seuils sont **à confirmer métier** avant PROD


- **Doc vs réel :** la documentation peut mentionner `receptions_apply_effects()` et `fn_sorties_after_insert()` ; le wiring observé en STAGING passe par **`reception_after_ins_trg()`** (trigger `receptions_after_ins`) et **`sorties_after_insert_trg()`** (trigger `trg_sorties_after_insert`).
- **Réception :** `trg_receptions_compute_15c_before_ins` → moteur ASTM lookup-grid → `volume_15c` ; `volume_corrige_15c` nul ou legacy selon les cas.
- **Sortie :** volumétrie encore partiellement legacy ; `volume_15c` coexiste avec `volume_corrige_15c` ; `sorties_compute_15c_before_ins_lookup` (ASTM) — entrée densité observée via **`densite_a_15_kgm3`** (legacy) côté chemin observé.
- **Post-insert :** `reception_after_ins_trg()` / `sorties_after_insert_trg()` alimentent `stocks_journaliers`, mettent à jour `stocks_snapshot` via `stock_snapshot_apply_delta()`, journalisent dans `log_actions` ; réception peut passer le CDR en DECHARGE.
- **Fonctions stock confirmées :** `stock_upsert_journalier`, `stock_snapshot_apply_delta`, `rebuild_stocks_journaliers`.
- **ASTM :** schéma `astm` présent ; fonctions observées : `astm.assert_lookup_grid_domain`, `astm.compute_v15_from_lookup_grid`, `astm.lookup_15c_bilinear_v2` ; dataset `public.astm_lookup_grid_15c` — 63 lignes, densité 820–860 kg/m³, température 10–40 °C.
- **Garde-fou SQL (grants ASTM) exécuté sur STAGING** : checks critiques validés (`anon/authenticated` = USAGE schéma `astm` + EXECUTE fonctions ASTM ; présence trigger `trg_receptions_compute_15c_before_ins` + appels ASTM détectés) → résultat **vert**.
- **Divergence connue avec PROD** sur `public.receptions_compute_15c_before_ins()` : garde `app_settings/env` encore présente en STAGING ; écart documenté, **non causal** dans l’incident PROD résolu, à aligner ultérieurement.
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
- **Lot fournisseur (workflow statut)** :
  - le cycle de vie du lot est désormais porté par trigger DB
  - toute modification directe de `public.fournisseur_lot.statut` est soumise à contraintes
  - les transitions arrière sont interdites
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

### Finance fournisseur lot — présence objets

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

### Finance fournisseur lot — cas test connu

```sql
SELECT
  facture_id,
  total_volume_20c,
  quantite_facturee_20c,
  ecart_volume_20c,
  statut_rapprochement,
  montant_regle_usd,
  solde_restant_usd,
  statut_paiement
FROM public.v_fournisseur_facture_lot
WHERE deal_reference = 'TEST-LOT-STAGING-001';
```

### Référence complémentaire

Pour les contrôles avancés (procédure, dangers), voir `docs/DB/critical_objects.md`.

---

## NOTES

- STAGING est un environnement expérimental : données incohérentes ou tests destructifs autorisés
- STAGING cohérent et exploitable pour validation avant production.
- Lecture métier du stock : **`public.v_stock_actuel`**.
- Vérifier **PROD** séparément avant toute conclusion d’alignement complet.

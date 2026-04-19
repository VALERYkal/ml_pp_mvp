# CRITICAL OBJECTS — ML_PP MVP

## ROLE
Lister les objets DB critiques du système et indiquer les précautions minimales avant toute modification.

## UPDATE FREQUENCY
À chaque changement sur un objet DB critique ou sur sa procédure de contrôle.

## SCOPE
Ce fichier couvre :
- les tables critiques
- les vues critiques
- les triggers critiques
- les fonctions critiques
- les règles minimales de sécurité associées

### ⚠️ WARNING — NOM DE FONCTION / WIRING RÉEL

Les **noms de fonctions** cités dans la documentation (runbooks, anciens dumps, schémas) peuvent **différer** des fonctions **réellement branchées** sur les triggers (ex. doc historique vs `reception_after_ins_trg()` / `sorties_after_insert_trg()`).

**Avant toute modification :** toujours vérifier sur l’instance cible **`pg_trigger`** (définition du trigger → fonction) et **`pg_proc`** / **`pg_get_functiondef`**, pas seulement un document texte.

## TABLES CRITIQUES

Les tables suivantes sont considérées comme critiques :

- cours_de_route
- receptions
- sorties_produit
- stocks_journaliers
- log_actions

### Tables métier sensibles (flux CDR, hors effet stock direct)

- **fournisseur_lot** — regroupement logistique amont (**manifeste**), plusieurs CDR possibles ; **pas** équivalent à une réception ni à une table de stock.
- **cours_de_route** — inchangé comme point d’entrée du transport ; **enrichie** par **`fournisseur_lot_id`** (nullable) : toute évolution du lien doit rester cohérente avec les triggers / contraintes existants sur `cours_de_route`.

### Pourquoi

- cours_de_route → point d’entrée du flux logistique
- receptions → vérité physique d’entrée
- sorties_produit → vérité physique de sortie
- stocks_journaliers → support critique du calcul et du suivi stock
- log_actions → audit et traçabilité

## VUES CRITIQUES

Les vues suivantes sont considérées comme critiques :

- v_stock_actuel

### Pourquoi

- v_stock_actuel → source de vérité métier pour la lecture du stock actuel

### Règle

- Toute lecture métier du stock actuel doit passer par cette vue
- Aucun cache ou snapshot technique ne doit la remplacer comme source de vérité

## TRIGGERS CRITIQUES

Les triggers suivants sont considérés comme critiques :

- triggers liés aux réceptions
- triggers liés aux sorties_produit
- triggers liés au calcul / maintien du stock

### Pourquoi

Ces triggers :
- appliquent la logique métier critique
- calculent ou propagent les effets métier
- garantissent la cohérence des données

### Règle

- Ne jamais modifier un trigger critique sans analyse préalable
- Toute modification doit être testée en staging
- Toute suppression ou neutralisation doit être explicitement justifiée

## FONCTIONS CRITIQUES

Les fonctions suivantes sont considérées comme critiques :

- fonctions du moteur volumétrique ASTM
- fonctions de calcul de stock
- fonctions appliquant des effets métier (réception, sortie)

### Pourquoi

Ces fonctions :
- exécutent la logique métier critique
- garantissent la cohérence des calculs
- impactent directement les données métier

### Règle

- Ne jamais modifier une fonction critique sans validation
- Toute modification doit être testée en staging
- Toute évolution doit passer par migration

---

## FINANCE FOURNISSEUR LOT (CRITIQUE)

Périmètre **finance fournisseur lot** déployé en PROD (facturation / rapprochement / paiement au niveau lot ; pivot **`fournisseur_lot`**). Impact **financier** direct en cas d’erreur ou de contournement.

### Vues critiques (lecture)

- **`public.v_fournisseur_facture_lot`** — **source de vérité de lecture consolidée** pour **rapprochement** et **paiement affiché** : `statut_rapprochement` **calculé en vue** ; **`montant_regle_usd`**, **`solde_restant_usd`**, **`statut_paiement`** **recalculés en vue** depuis agrégat **`fournisseur_paiement_lot_min`** (somme des **`montant_paye_usd`**) — **ne pas** présenter les colonnes homonymes persistées sur **`fournisseur_facture_lot_min`** comme suffisantes pour l’état paiement **affiché** ; jointure **LEFT** sur l’agrégat réceptions par lot afin qu’**une facture reste toujours visible** même sans ligne agrégée ; valeurs **`OK` / `TOLERE` / `LITIGE` / `A_RAPPROCHER`** ; enrichissements lecture fin de vue : **`lot_reference`**, **`fournisseur_nom`** (jointures **`fournisseur_lot`**, **`fournisseurs`**).
- **`public.v_fournisseur_rapprochement_lot_min`** — projection rapprochement (vue minimale) ; **même logique** de jointure et de `statut_rapprochement` que la vue facture (sans périmètre paiement consolidé identique à la vue facture — lecture facture+détail paiement : **`v_fournisseur_facture_lot`**).
- **`public.v_reception_20c`** — support de la chaîne **@20 °C** (approximation contrôlée, **provisoire** — ne pas substituer à la vérité stock @15 °C).

### Tables sensibles (écriture)

- **`public.fournisseur_facture_lot_min`** — la colonne **`statut_rapprochement`** (CHECK table) **n’est pas** la vérité de lecture métier pour l’écran rapprochement ; l’app lit **`statut_rapprochement` depuis les vues** ci-dessus. Les colonnes **`montant_regle_usd`**, **`solde_restant_usd`**, **`statut_paiement`** sur la table peuvent être **maintenues / mises à jour par triggers** mais **la lecture métier consolidée** pour l’UI doit passer par **`v_fournisseur_facture_lot`** (état **2026-04-19** documenté dans `staging_status` / `prod_status`).
- **`public.fournisseur_paiement_lot_min`**

### Index (verrou métier)

- **`idx_fournisseur_facture_lot_min_one_facture_per_lot`** — **unique** sur **`(fournisseur_lot_id)`** ; **1 lot = 1 facture** active ; doublon → **`23505`**.

### Fonctions

- **`public.compute_volume_20c_from_reception(...)`** — conversion **@20 °C** pour la chaîne finance ; toute modification exige validation métier / technique (projection non figée).

### Triggers (paiement lot)

Sur **`public.fournisseur_paiement_lot_min`** (noms attendus, vérifier `pg_trigger` sur l’instance) :

- **`trg_fournisseur_paiement_lot_min_after_ins`** — recalcul des totaux facture après insert paiement.
- **`trg_fournisseur_paiement_lot_min_check_overpay`** — blocage **surpaiement**.

**Précaution** : ces triggers **restent critiques** ; en **lecture**, **`v_fournisseur_facture_lot`** **ne dépend plus** pour l’affichage des soldes / statut paiement **exclusivement** des seules valeurs persistées sur **`fournisseur_facture_lot_min`** — **incohérence historique corrigée côté vue** (cas sans paiement).

### Règle

- **Ne pas modifier** vues, tables, fonctions ni triggers de ce périmètre **sans validation explicite** (staging, relecture impact financier, backup si PROD).

### Distinction cycle de vie lot vs facture fournisseur

- **`public.fournisseur_lot.statut`** (`ouvert` / `cloture` / `facture`) = **cycle de vie métier du lot** (porté par triggers workflow lot), **sans** équivalence avec « une ligne facture existe en base ».
- **Existence d’une facture fournisseur lot** = présence d’une ligne dans **`public.fournisseur_facture_lot_min`** (et lecture consolidée via **`public.v_fournisseur_facture_lot`**).

---

## DANGERS DB

Les opérations suivantes sont à haut risque :

- modification directe en production
- désactivation ou contournement de triggers
- modification d’une vue de stock sans analyse
- traitement d’un cache comme source de vérité
- modification du moteur volumétrique sans validation complète

---

## PROCÉDURE MINIMALE AVANT MODIFICATION

Avant toute modification d’un objet critique :

1. Identifier l’objet concerné
2. Vérifier s’il est critique (ce document)
3. Comprendre son rôle métier
4. Vérifier l’état staging / production
5. Passer par migration
6. Tester en staging
7. Documenter si nécessaire

---

## REQUÊTES SQL DE VÉRIFICATION

### Lister les triggers d’une table

```sql
SELECT tgname
FROM pg_trigger
WHERE tgrelid = 'public.receptions'::regclass
  AND NOT tgisinternal;
```

(Remplacer `receptions` par le nom de la table concernée, schéma `public` si applicable.)

### Vérifier une vue critique

```sql
SELECT *
FROM pg_views
WHERE schemaname = 'public'
  AND viewname = 'v_stock_actuel';
```

### Lister les fonctions du schéma ASTM

```sql
SELECT p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'astm'
ORDER BY p.proname;
```

### Vérifier les colonnes d’une table

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'receptions';
```

---

## FINANCE FOURNISSEUR LOT — OBJETS CRITIQUES

### VUES CANONIQUES (SOURCE DE VÉRITÉ LECTURE)

- **`v_fournisseur_facture_lot`** — lecture **consolidée** : **rapprochement** + **paiement affiché** (agrégat **`fournisseur_paiement_lot_min`**) + enrichissements **`lot_reference`**, **`fournisseur_nom`**
- **`v_fournisseur_rapprochement_lot_min`** — lecture **rapprochement** (vue minimale) ; **pas** l’équivalent du périmètre paiement consolidé de la vue facture

Règle :
Toute lecture métier (UI, reporting, rapprochement, **soldes / statut paiement affichés**) **pour la facture lot** DOIT passer par **`v_fournisseur_facture_lot`** (et **`v_fournisseur_rapprochement_lot_min`** pour le périmètre minimal rapprochement).

INTERDICTION :
Lire directement les tables pour reconstruire des agrégats côté application.

---

### RAPPROCHEMENT (CRITIQUE)

- `statut_rapprochement` est calculé uniquement dans les vues
- Aucune colonne persistée **sur la table facture** ne fait foi pour le **rapprochement affiché**

Règle :
La DB est la seule source de vérité pour :
- écarts de volume
- statut de rapprochement
- **paiement affiché** (**`montant_regle_usd`**, **`solde_restant_usd`**, **`statut_paiement`**) **via `v_fournisseur_facture_lot`** (agrégat paiements)

---

### LEFT JOIN (COMPORTEMENT CRITIQUE)

Les vues utilisent des LEFT JOIN pour garantir :

- visibilité des factures même si :
  - aucune réception liée
  - agrégat incomplet

Règle :
Ne JAMAIS remplacer par INNER JOIN sans validation métier.

---

### CONTRAINTE D’UNICITÉ FACTURE

Index unique :

`idx_fournisseur_facture_lot_min_one_facture_per_lot`

Règle :
- 1 lot = 1 facture fournisseur active
- Toute tentative de duplication doit lever une erreur DB (23505)

---

### DISTINCTION STATUT LOT vs FACTURE

IMPORTANT :

- `fournisseur_lot.statut = facture` → indicateur métier
- présence d’une ligne dans `fournisseur_facture_lot_min` → réalité comptable

Règle :
Ne jamais déduire l’existence d’une facture uniquement via le statut du lot.

---

### FRONTEND — RÈGLE ABSOLUE

INTERDICTION :
- recalculer des montants
- recalculer des écarts
- reconstruire un rapprochement

OBLIGATION :
- lire uniquement les vues DB
- afficher les données telles quelles

# ARCHITECTURE MAP — ML_PP MVP

## ROLE
Fournir une vue claire du système pour savoir où intervenir sans casser les invariants.

## UPDATE FREQUENCY
À chaque modification structurelle du système (DB, flux métier, modules).

## OBJECTIF
Permettre de :
- comprendre les flux métier
- identifier les zones d’intervention
- éviter les modifications dangereuses

---

# VUE GLOBALE

ML_PP MVP est un système de gestion logistique pétrolière piloté par la base de données.

Principe central :
- DB = source de vérité
- logique métier critique = DB
- frontend = UI + orchestration

---

# FLUX MÉTIER PRINCIPAL

Fournisseur
→ Lot fournisseur (manifeste / regroupement CDR)
→ Cours de Route
→ Réception
→ Stock
→ Sortie

**Finance fournisseur lot (PROD)** — chaîne en lecture / écriture pilotée par la DB, **après** le pivot lot : **LOT** → agrégation réceptions → **total @20 °C (provisoire)** → facture → rapprochement → paiement (voir checkpoint, `docs/DB/prod_status.md`).

---

# MODULES PRINCIPAUX

- Authentification / profils
- Cours de route
- Réceptions
- Stocks
- Sorties produit
- Citernes
- Logs / audit
- Dashboard
- **Finance fournisseur lot** (couche Dart `lib/features/lots_finance/` ; **UI V1** — liste / détail / création facture / ajout paiement ; GoRouter ; lecture métier via **`v_fournisseur_facture_lot`** pour projection consolidée ; écriture facture **`fournisseur_facture_lot_min`** ; écriture paiement **`fournisseur_paiement_lot_min`**)

---

# RESPONSABILITÉS PAR COUCHE

## Frontend
Flutter :
- affiche
- orchestre
- valide l’expérience utilisateur
- ne porte pas la logique métier critique

## Backend / DB
PostgreSQL / Supabase :
- applique les règles métier
- calcule les volumes
- calcule le stock
- protège la cohérence via triggers, fonctions et vues

---

# TABLES CLÉS

- fournisseur_lot
- cours_de_route (`fournisseur_lot_id` → lot optionnel)
- fournisseur_facture_lot_min / fournisseur_paiement_lot_min (écriture finance lot ; lecture métier via vues dédiées)
- receptions
- sorties_produit
- stocks_journaliers
- citernes
- produits
- clients
- partenaires
- log_actions

**Lecture métier du stock actuel :** la source de vérité est la vue **`v_stock_actuel`**. La table **`stocks_snapshot`** est un **cache technique** dérivé ; en cas de divergence constatée (ex. après opération exceptionnelle), une resynchronisation peut passer par des mécanismes dédiés (ex. `stock_snapshot_apply_delta`) — sans substituer la vue métier.

---

# SOURCES DE VÉRITÉ OPÉRATIONNELLES

- Stock actuel → v_stock_actuel
- Réception → receptions
- Sortie → sorties_produit
- Flux transport → cours_de_route
- Audit → log_actions

Caches dérivés :
- stocks_snapshot → technique uniquement, non source de vérité métier  
  (voir system_invariants.md)

**sorties_produit** — calculs / persistance (runtime actuel, mode compatibilité) :

- **`volume_15c`** — colonne cible pour le volume à 15 °C  
- **`volume_corrige_15c`** — conservée en parallèle (double write + compatibilité transitoire ; arrondi métier sorties documenté sur ce champ)

**Lecture applicative (Flutter) :** règle officielle **`volume_15c ?? volume_corrige_15c`** sur les périmètres migrés.

---

# FINANCE FOURNISSEUR LOT

- **Dépend de** : **réceptions** (agrégation volumes), **cours_de_route** (chaîne logistique amont), **`fournisseur_lot`** (pivot métier).
- **Création facture** : via la **table minimale** `fournisseur_facture_lot_min` (insert contrôlé) ; **paiement** via `fournisseur_paiement_lot_min` — aligné avec le service Dart `FournisseurFinanceLotService`.
- **Lecture métier consolidée** : **`v_fournisseur_facture_lot`** = **source de vérité lecture** pour **rapprochement** et **paiement affiché** (`montant_regle_usd`, `solde_restant_usd`, `statut_paiement`) — **recalculés en vue** depuis agrégat **`fournisseur_paiement_lot_min`** (jointure sur `fournisseur_facture_id`) ; **enrichissements** fin de vue : **`lot_reference`** (`fournisseur_lot.reference`), **`fournisseur_nom`** (`fournisseurs.nom`) via **`LEFT JOIN`** `fournisseur_lot` / `fournisseurs`. **`v_fournisseur_rapprochement_lot_min`**, **`v_reception_20c`** : périmètres complémentaires documentés dans le pack DB.
- **Lecture métier (autres agrégats)** : **`v_fournisseur_rapprochement_lot_min`**, etc. ; pas de lecture applicative « canonique » sur les tables pour reconstruire agrégats affichés.
- **Rapprochement** : **calculé dans les vues DB** ; **`statut_rapprochement` affiché** = calcul en vue ; colonne homonyme sur `fournisseur_facture_lot_min` **non** vérité lecture UI pour le rapprochement.
- **LEFT JOIN** (agrégat réceptions dans les vues facture / rapprochement lot min) : **comportement critique** de **visibilité** facture sans agrégat complet ; **`A_RAPPROCHER`** lorsque l’agrégat ou `total_volume_20c` n’est pas exploitable.
- **Règle métier** : **1 lot = 1 facture fournisseur active** — verrou DB **`idx_fournisseur_facture_lot_min_one_facture_per_lot`** (STAGING + PROD, session **2026-04-19** pour PROD).
- **Triggers** `fournisseur_paiement_lot_min` (**after insert**, **check overpay**) : **toujours présents** ; la **lecture métier consolidée** des soldes / statut paiement sur **`v_fournisseur_facture_lot`** **ne repose plus** sur la seule lecture des colonnes dérivées persistées sur **`fournisseur_facture_lot_min`** pour l’affichage.
- **Statuts « globaux » dans l’app** (ex. libellés dérivés de `statut_rapprochement` + `statut_paiement`) : **mapping UX Flutter** — **pas** une vérité métier DB.
- **Lot `statut = facture`** : cycle de vie du lot en base ; **ne pas** l’utiliser comme preuve qu’une ligne **`fournisseur_facture_lot_min`** existe (voir `docs/DB/critical_objects.md`).
- **Ne modifie pas** : le **stock** ni la **volumétrie @15 °C** des périmètres stock / sortie existants ; la projection **@20 °C** sert la chaîne finance documentée et reste **provisoire** (voir checkpoint / `prod_status`).

---

# ZONES D’INTERVENTION

## Si le besoin concerne Cours de Route
Toucher :
- `fournisseur_lot` (création / liste / référence métier)
- `cours_de_route` (dont **`fournisseur_lot_id`**)
- écrans / providers CDR et lots

Attention:
- le module CDR ne possède plus de machine d’état applicative
- toute évolution doit se baser sur la colonne `statut` en base
- ne pas introduire de logique parallèle (duplication hors `statut`, FSM, etc.)

## Si le besoin concerne Réception
Toucher :
- receptions
- triggers / fonctions associées
- écrans / services Réception

Attention :
- le pipeline Réception dépend aussi des privilèges runtime sur le schéma `astm`
- perte de `USAGE` sur `astm` (rôles applicatifs) => blocage volumétrie trigger + insert Réception

## Si le besoin concerne Stock
Toucher :
- v_stock_actuel (lecture métier)
- stocks_journaliers (journal / support)
- fonctions / vues de stock

## Si le besoin concerne Sortie
Toucher :
- sorties_produit
- triggers / fonctions associées
- écrans / services Sortie

---

# ZONES À HAUT RISQUE

Les zones suivantes sont critiques :
- triggers DB
- fonctions DB
- vues de stock
- moteur volumétrique ASTM

Toute modification sur ces zones doit être traitée comme sensible.

---

# RÈGLE D’INTERVENTION

Avant toute modification :
1. Lire current_checkpoint.md
2. Appliquer architecture_rules.md
3. Identifier la zone concernée
4. Vérifier la DB si nécessaire
5. Intervenir dans le périmètre strict
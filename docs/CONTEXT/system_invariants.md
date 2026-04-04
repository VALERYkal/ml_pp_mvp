# ML_PP MVP — System Invariants

## Purpose

Ce document définit les règles fondamentales du système ML_PP MVP.

Ces règles sont des **invariants métier**.

Elles ne doivent jamais être violées par :

- le code applicatif
- les triggers
- les migrations
- les scripts SQL

Toute modification du système doit préserver ces invariants.

---

# Invariant 1 — Single Source of Truth for Volumetrics

Les calculs volumétriques sont exécutés uniquement dans la base de données.

Le frontend ne doit jamais calculer :

- densité à 15°C
- VCF
- volume à 15°C

Les fonctions responsables du runtime sont :

astm.compute_v15_from_lookup_grid  
astm.lookup_15c_bilinear_v2  
astm.assert_lookup_grid_domain

---

# Invariant 2 — Observed Density Input

La densité saisie par l’utilisateur est toujours :

densite_observee.

La densité à 15°C est toujours calculée par le système.

Il est interdit de saisir directement :

densite_a_15.

---

# Invariant 3 — Lookup Grid Domain Safety

Le moteur volumétrique ne doit jamais calculer hors domaine du dataset.

The lookup grid dataset (astm_lookup_grid_15c) defines the allowed computation domain.

Le domaine actuel est :

densité observée :

820 → 860 kg/m3

température :

10 → 40 °C

Toute tentative de calcul hors domaine doit lever une exception.

Fonctions responsables :

astm.assert_lookup_grid_domain  
astm.lookup_grid_domain (domain check)  
astm.compute_v15_from_lookup_grid  
astm.lookup_15c_bilinear_v2

---

# Invariant 4 — Deterministic Volumetric Engine

Le moteur volumétrique doit être déterministe.

Pour un même input :

volume_observe  
temperature  
densite_observee

le système doit produire exactement :

densite_a_15  
VCF  
volume_15c

sans dépendre de l’environnement.

Note: The volumetric engine deployed in production must remain deterministic and environment independent.

---

# Invariant 5 — Volumetric Rounding Policy

La politique d’arrondi doit rester constante.

Réceptions :

volume_15c arrondi à 1 décimale.

Sorties :

volume_corrige_15c arrondi au litre entier.

Toute modification de cette règle doit être traitée comme une modification du moteur volumétrique.

---

# Invariant 6 — Reception Pipeline Integrity

Une réception valide doit toujours suivre le pipeline :

cours_de_route statut ARRIVE  
→ création réception  
→ calcul volumétrique  
→ statut CDR = DECHARGE

Une réception ne doit jamais être créée pour un CDR déjà :

DECHARGE.

---

# Invariant 7 — Stock Consistency

Les stocks doivent toujours respecter :

Stock = Somme(Réceptions) − Somme(Sorties)

Aucun mouvement de stock ne doit exister hors :

receptions  
sorties_produit

---

# Invariant 8 — Immutable Historical Records

Les réceptions et sorties validées ne doivent pas être modifiées.

Une fois créées :

les opérations deviennent historiques.

Toute correction doit être faite par :

une nouvelle opération compensatoire.

---

# Invariant 9 — Dataset Integrity

Le golden dataset volumétrique est considéré comme :

une référence scientifique.

Il ne doit pas être modifié sans :

- validation technique
- validation métier
- nouvelle version de batch_id

---

# Invariant 10 — Database Driven Business Logic

La logique métier critique doit rester dans la base de données.

Cela inclut :

- calcul volumétrique
- validation des données
- calcul des stocks

Le frontend ne doit pas reproduire ces règles.

---

# Invariant 11 — Production Safety

Toute modification du moteur volumétrique en production doit suivre :

backup base  
migration staging  
validation staging  
runbook production

---

# Invariant 12 — Traceability

Chaque opération métier doit être traçable.

Les éléments suivants doivent toujours être enregistrés :

date  
utilisateur  
volume  
densité  
température

---

# Invariant 13 — Dual Volume Compatibility (sorties / lecture)

Pendant la phase de **compatibilité transitoire**, le système peut persister **deux** colonnes volume @15 °C sur les sorties (et contextes associés) :

- **`volume_15c`** — référence **cible**
- **`volume_corrige_15c`** — **legacy**, conservée

Toute **lecture** applicative sur les périmètres migrés doit respecter :

**`volume_15c ?? volume_corrige_15c`**

sans supposer que **`volume_15c`** est toujours renseigné sur les données les plus anciennes. Cette phase **n’implique pas** la fin du legacy ni une unification complète des modèles Dart.

---

# Invariant 14 — Stock Source of Truth vs Snapshot

La **source de vérité métier** pour le stock actuel exposé aux règles métier et à la lecture canonique est la vue **`v_stock_actuel`**.

**`stocks_snapshot`** est un **cache / structure technique dérivée**. Il peut **diverger** dans des cas exceptionnels ; la correction du cache (ex. via **`stock_snapshot_apply_delta`**) est un mécanisme **technique** sous contrôle — **ne pas** « corriger » le stock métier en traitant le snapshot comme source de vérité à la place de **`v_stock_actuel`**.

---

# Conclusion

Ces invariants définissent les garanties fondamentales du système ML_PP MVP.

Ils doivent être respectés par :

- toutes les évolutions futures
- tous les développeurs
- tous les scripts de migration

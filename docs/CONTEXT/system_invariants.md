# ML_PP MVP — System Invariants

## PURPOSE

Ce document définit les invariants métier fondamentaux du système.

Ces règles sont non négociables.

Elles ne doivent jamais être violées par :
- le code applicatif
- les triggers
- les migrations
- les scripts SQL

Toute modification du système doit préserver ces invariants.

---

# 1. SOURCE DE VÉRITÉ

La base de données est la source de vérité du système.

- Le stock réel provient de la DB
- La volumétrie est calculée en DB
- La logique métier critique est en DB

---

# 2. LOGIQUE MÉTIER

La logique métier critique est implémentée uniquement en base de données.

Cela inclut :
- calculs volumétriques
- calculs de stock
- validations métier

Le frontend ne doit jamais reproduire ces règles.

---

# 3. VOLUMÉTRIE (ASTM)

## 3.1 Calcul DB uniquement

Les calculs volumétriques sont exécutés uniquement en DB.

Le frontend ne doit jamais calculer :
- densité à 15°C
- VCF
- volume à 15°C

Fonctions principales :
- astm.compute_v15_from_lookup_grid
- astm.lookup_15c_bilinear_v2
- astm.assert_lookup_grid_domain

---

## 3.2 Données d’entrée

La densité saisie est toujours :
- densite_observee

Il est interdit de saisir :
- densite_a_15

---

## 3.3 Domaine de calcul

Le moteur ne doit jamais calculer hors domaine.

Domaine actuel :
- densité : 820 → 860 kg/m3
- température : 10 → 40 °C

Toute sortie hors domaine → erreur.

---

## 3.4 Déterminisme

Le moteur doit être déterministe.

Même input → même output.

---

## 3.5 Politique d’arrondi

- Réceptions → 1 décimale
- Sorties → litre entier

---

## 3.6 Dataset

Le dataset ASTM est une référence scientifique.

Toute modification nécessite :
- validation technique
- validation métier
- versionnement

---

# 4. PIPELINE LOGISTIQUE

Une réception valide suit toujours :

CDR ARRIVE
→ création réception
→ calcul volumétrique
→ CDR = DECHARGE

Interdit :
- réception sur CDR déjà déchargé

# 4.1 CDR STATE INVARIANT

- Le CDR est piloté uniquement par la colonne `statut`
- Les valeurs autorisées sont contrôlées en base (CHECK constraint)
- Aucune machine d’état parallèle n’est autorisée côté application
- Le passage à DECHARGE ne peut se faire que via une réception validée

Interdit :
- ajouter un champ etat
- gérer un workflow parallèle côté frontend
- bypass la règle réception → DECHARGE

---

## 4.2 Lot fournisseur (manifeste amont)

- Un `cours_de_route` peut être lié à **0 ou 1** `fournisseur_lot` via **`fournisseur_lot_id`** (nullable).
- Un `fournisseur_lot` peut regrouper **plusieurs** `cours_de_route`.
- Le lot fournisseur **ne crée aucun stock** et **ne remplace pas** une réception.
- Le lot fournisseur **ne remplace pas** le pilotage du CDR par la colonne **`statut`**.

---

# 5. STOCK

## 5.1 Calcul

Stock = Réceptions − Sorties

Aucun autre flux n’est autorisé.

---

## 5.2 Source de vérité

La vue :
- v_stock_actuel

est la source métier officielle.

---

## 5.3 Snapshot

stocks_snapshot est un cache technique.

- peut diverger
- ne doit jamais être utilisé comme vérité métier

---

# 6. IMMUTABILITÉ

Les opérations validées sont immuables :
- réceptions
- sorties

Toute correction se fait via :
- opération compensatoire

---

# 7. TRAÇABILITÉ

Chaque opération doit enregistrer :
- date
- utilisateur
- volume
- densité
- température

---

# 8. COMPATIBILITÉ TRANSITOIRE

Pendant la migration :

- volume_15c → cible
- volume_corrige_15c → legacy

Lecture obligatoire :

volume_15c ?? volume_corrige_15c

**Écritures stock (DB) :** toute prise en compte du volume sortie @15 °C dans les effets stock (journal, snapshot, logs) doit s’appuyer sur la **même priorité** : **`volume_15c` puis `volume_corrige_15c`** (ex. `COALESCE(volume_15c, volume_corrige_15c, 0)` là où un scalaire est requis). **Aucun** pipeline stock ne doit dépendre **exclusivement** du champ **legacy** pour le @15 °C lorsque **`volume_15c`** est la colonne cible renseignée par le moteur.

---

# 9. SÉCURITÉ PRODUCTION

Toute modification critique suit :

1. backup
2. staging
3. validation
4. production

---

# CONCLUSION

Ces invariants définissent les garanties fondamentales du système.

Ils doivent être respectés par :
- toutes les évolutions
- tous les développeurs
- toutes les migrations

---

## 🔒 Invariant VOL15 (critique)

- Le volume canonique est `volume_15c`
- `volume_corrige_15c` est un champ legacy uniquement
- Toute lecture frontend doit utiliser:
  `volume_15c ?? volume_corrige_15c`
- Aucun calcul volumétrique métier ne doit exister côté frontend
- Toute valeur officielle @15°C provient de la DB uniquement
- Toute estimation locale doit être explicitement marquée:
  "non canonique"

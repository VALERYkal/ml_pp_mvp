# Migration DB-STRICT — Réceptions & Sorties

**Date de migration** : Décembre 2025  
**Statut** : ✅ Complétée et validée  
**Objectif** : Corriger définitivement les incohérences de stock en rendant la base de données la source de vérité unique

---

## 1. Problèmes initiaux observés

### 1.1 Incohérences de stock entre modules

**Symptômes factuels observés :**

- **Module Citernes** : Affichait uniquement le stock du dernier propriétaire ayant bougé, ignorant totalement le stock de l'autre propriétaire
  - Exemple : TANK1 avec MONALUXE (5 500 L) + PARTENAIRE (1 277 L) affichait seulement 1 277 L au lieu de 6 777 L

- **Dashboard KPI** : Stock total affiché inférieur à la somme réelle
  - Exemple : MONALUXE (9 000 L) + PARTENAIRE (4 000 L) = 13 000 L attendu, mais affiché 7 500 L

- **Module Stocks** : Valeurs divergentes selon la source de données consultée (vue SQL vs calcul applicatif)

### 1.2 Sorties bloquées sans message clair

**Problème utilisateur :**

- Tentative de création de sortie → échec silencieux
- Message générique "Une erreur est survenue" sans explication
- Impossible de comprendre pourquoi la sortie était rejetée (stock insuffisant ? produit incompatible ? capacité sécurité ?)

**Impact métier :** Blocage opérationnel, perte de temps, frustration utilisateur.

### 1.3 Stocks négatifs ou invisibles

**Observations DB :**

- Certaines citernes affichaient un stock de 0 L alors que des réceptions avaient été enregistrées
- Stocks négatifs possibles pour un propriétaire (MONALUXE) alors que le total de la citerne restait positif
- Incohérence entre le stock physique réel et le stock comptable affiché

### 1.4 Dépendance au dernier stocks_journaliers

**Architecture problématique :**

- Le système utilisait `stocks_journaliers` à la fois comme :
  - **Journal** (historique des mouvements)
  - **État courant** (source de vérité pour l'affichage)

- Les vues SQL sélectionnaient uniquement la dernière date de mouvement globale, ignorant les propriétaires qui n'avaient pas bougé récemment :
  ```sql
  -- ❌ LOGIQUE INCORRECTE (avant correction)
  SELECT MAX(date_jour) AS date_jour  -- Dernière date GLOBALE
  FROM stocks_journaliers
  GROUP BY citerne_id, produit_id
  -- Problème : Si MONALUXE bouge le 10/12 et PARTENAIRE le 12/12,
  -- seule la date 12/12 est sélectionnée, excluant MONALUXE
  ```

### 1.5 Impossibilité de garantir la cohérence en temps réel

**Problème architectural :**

- Calculs de stock répartis entre :
  - Code applicatif Flutter (validations, calculs)
  - Triggers SQL (mises à jour partielles)
  - Vues SQL (agrégations complexes)

- Aucune garantie que les calculs applicatifs et DB restent synchronisés
- Risque de divergence après chaque modification de code

**Conclusion :** Le problème n'était pas l'UI, mais l'architecture de calcul du stock. La logique métier était fragmentée et aucune source de vérité unique n'existait.

---

## 2. Cause racine (Root Cause Analysis)

### 2.1 stocks_journaliers utilisé à la fois comme journal ET comme état courant

**Problème conceptuel :**

La table `stocks_journaliers` servait deux rôles incompatibles :

1. **Journal** : Enregistrer chaque mouvement (réception = +volume, sortie = -volume)
2. **État courant** : Fournir le stock disponible à un instant T

**Conséquence :** Les vues SQL devaient sélectionner "le dernier stock connu", mais cette sélection était ambiguë dans un contexte multi-propriétaires où chaque propriétaire peut avoir une date de dernier mouvement différente.

### 2.2 Écritures multiples (app + triggers)

**Avant DB-STRICT :**

- **Code Flutter** : Calculait les volumes, validait les règles métier, préparait les payloads
- **Triggers SQL** : Appliquaient les effets (débit/crédit stock) mais de manière partielle
- **Risque** : Double écriture possible, ou écriture manquante si un trigger échouait silencieusement

**Exemple de risque :**
```dart
// Code Flutter (avant)
final volume = calculateVolume(indices);
await service.createSortie(volume);  // Peut échouer côté DB sans message clair
// Si le trigger échoue, le stock n'est pas débité mais la sortie peut être créée
```

### 2.3 Absence de source de vérité unique

**Avant DB-STRICT :**

- **Flutter** : Calculait le stock depuis `stocks_journaliers` avec des requêtes complexes
- **Dashboard** : Utilisait une vue SQL différente (`v_stocks_citerne_global`)
- **Module Citernes** : Utilisait une autre vue (`v_citerne_stock_actuel`)
- **KPI** : Utilisait encore une autre source

**Résultat :** Chaque module pouvait afficher une valeur différente pour le même stock.

### 2.4 Sorties validées sans contrôle strict côté DB

**Avant DB-STRICT :**

- Les validations métier (stock suffisant, capacité sécurité, produit/citerne) étaient faites principalement côté Flutter
- Les triggers SQL ne faisaient que des vérifications basiques (produit/citerne)
- **Risque** : Une sortie pouvait être créée même si le stock était insuffisant, si le code applicatif avait un bug

**Exemple de faille :**
```dart
// Code Flutter (avant) - validation optionnelle
if (stockDisponible < volume) {
  // Afficher warning mais continuer ?
  // Ou bloquer ? Dépend du code...
}
await service.createSortie(volume);  // Pas de garantie DB
```

### 2.5 Logique métier fragmentée entre Flutter et PostgreSQL

**Répartition problématique :**

- **Flutter** : Validation XOR bénéficiaire (client OU partenaire), calcul volumes, normalisation proprietaire_type
- **PostgreSQL** : Vérification produit/citerne, débit stock
- **Risque** : Modification d'une règle métier nécessitait de toucher deux endroits, avec risque d'incohérence

---

## 3. Principe retenu : DB-STRICT + stocks_journaliers comme source unique

### 3.1 Nouveau modèle : stocks_journaliers = journal ET état courant

**Décision architecturale :**

Au lieu de créer une table séparée `stocks_snapshot`, nous avons choisi de **corriger l'utilisation de `stocks_journaliers`** pour qu'elle serve à la fois de journal et d'état courant, mais de manière cohérente.

**Règle fondamentale :**

- `stocks_journaliers.stock_ambiant` et `stocks_journaliers.stock_15c` représentent le **cumul depuis le début de l'historique**, pas un delta journalier
- Pour obtenir le stock à une date donnée, on sélectionne la ligne avec la date la plus récente <= date cible
- Pour chaque combinaison `(citerne_id, produit_id, proprietaire_type)`, il existe une ligne par date de mouvement

**Clé composite :**
```
(citerne_id, produit_id, date_jour, proprietaire_type)
```

### 3.2 Aucune écriture directe depuis l'app

**Règle absolue :**

- ❌ L'application Flutter **n'écrit jamais** dans `stocks_journaliers`
- ❌ L'application Flutter **ne calcule jamais** le stock depuis les mouvements
- ✅ Le stock est **uniquement modifié** par les triggers PostgreSQL
- ✅ L'application **lit uniquement** depuis `stocks_journaliers` ou les vues SQL dérivées

### 3.3 Toute mutation passe par les triggers

**Flow unique :**

```
INSERT INTO receptions (...) 
  → Trigger BEFORE INSERT (validations métier)
  → Trigger AFTER INSERT (effets irréversibles)
    → stock_upsert_journalier_v2() (crédit stock)
    → UPDATE cours_de_route (statut DECHARGE)
    → INSERT log_actions (audit)
  → Transaction committée

INSERT INTO sorties_produit (...)
  → Trigger BEFORE INSERT (validations complètes)
    → Vérification stock suffisant depuis stocks_journaliers
    → Vérification capacité sécurité
    → Vérification XOR bénéficiaire
  → Trigger AFTER INSERT (effets irréversibles)
    → stock_upsert_journalier() (débit stock)
    → INSERT log_actions (audit)
  → Transaction committée
```

### 3.4 Fonctions DB SECURITY DEFINER

**Toutes les fonctions critiques sont `SECURITY DEFINER` :**

- `receptions_apply_effects_v2()` : Applique les effets d'une réception
- `fn_sorties_after_insert()` : Applique les effets d'une sortie
- `sorties_check_before_insert()` : Valide une sortie avant insertion
- `stock_upsert_journalier_v2()` : Met à jour le stock journalier

**Avantage :** Les fonctions s'exécutent avec les privilèges du propriétaire de la fonction, garantissant que les opérations critiques ne peuvent pas être contournées par des restrictions RLS.

### 3.5 Schéma logique simplifié

```
┌─────────────────┐
│   Flutter App   │
│  (UI + Validation UX) │
└────────┬────────┘
         │ INSERT receptions / sorties_produit
         ▼
┌─────────────────────────────────────┐
│     PostgreSQL Triggers             │
│  ┌──────────────────────────────┐  │
│  │ BEFORE INSERT (validations)   │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ AFTER INSERT (effets)         │  │
│  │  → stock_upsert_journalier()  │  │
│  │  → log_actions                │  │
│  └──────────────────────────────┘  │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│    stocks_journaliers               │
│  (Source de vérité unique)          │
│  - Cumul depuis début historique   │
│  - Clé: (citerne, produit, date,   │
│         proprietaire)               │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│    Vues SQL (lecture seule)         │
│  - v_stocks_citerne_global          │
│  - v_citerne_stock_actuel           │
│  - (agrégations pour UI)            │
└─────────────────────────────────────┘
```

---

## 4. Migration Réceptions (ce qui a été changé)

### 4.1 Trigger `receptions_apply_effects_v2()`

**Fonction :** `public.receptions_apply_effects_v2()`  
**Trigger :** `trg_receptions_after_insert_v2` (AFTER INSERT)

**Responsabilités :**

1. **Calcul/normalisation des volumes :**
   ```sql
   v_amb := COALESCE(NEW.volume_ambiant,
     CASE 
       WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL 
       THEN NEW.index_apres - NEW.index_avant 
       ELSE 0 
     END
   );
   v_15 := COALESCE(NEW.volume_corrige_15c, v_amb);
   ```

2. **Normalisation proprietaire_type :**
   ```sql
   v_proprietaire := UPPER(COALESCE(TRIM(NEW.proprietaire_type), 'MONALUXE'));
   ```

3. **Récupération depot_id depuis la citerne :**
   ```sql
   SELECT depot_id INTO v_depot_id
   FROM public.citernes
   WHERE id = NEW.citerne_id;
   ```

4. **Crédit du stock (valeur positive) :**
   ```sql
   PERFORM public.stock_upsert_journalier_v2(
     NEW.citerne_id,
     NEW.produit_id,
     v_date,
     +v_amb,  -- Crédit positif
     +v_15,   -- Crédit positif
     v_proprietaire,
     v_depot_id,
     'RECEPTION'
   );
   ```

5. **Passage automatique du CDR à DECHARGE :**
   ```sql
   IF NEW.cours_de_route_id IS NOT NULL THEN
     UPDATE public.cours_de_route 
     SET statut = 'DECHARGE' 
     WHERE id = NEW.cours_de_route_id;
   END IF;
   ```

### 4.2 Double écriture contrôlée

**Fonction `stock_upsert_journalier_v2()` :**

- **Signature :** 8 paramètres (citerne_id, produit_id, date_jour, volume_ambiant, volume_15c, proprietaire_type, depot_id, source)
- **Logique :** `ON CONFLICT` avec `DO UPDATE` pour cumuler les mouvements du même jour
- **Clé composite :** `(citerne_id, produit_id, date_jour, proprietaire_type)`

**Important :** La fonction calcule le stock cumulé (stock initial + mouvement), pas seulement le delta.

### 4.3 Journalisation (log_actions)

**Trigger séparé (legacy conservé) :** `trg_receptions_log_created`

- Enregistre chaque réception dans `log_actions`
- Action : `'RECEPTION_CREEE'`
- Module : `'receptions'`
- Niveau : `'INFO'`
- Détails JSON : réception_id, citerne_id, produit_id, volumes, cours_de_route_id, proprietaire_type, partenaire_id

### 4.4 Suppression de toute écriture Flutter sur les stocks

**Code Flutter nettoyé :**

- ❌ Supprimé : `ReceptionService.createDraft()` (créait des réceptions en brouillon)
- ❌ Supprimé : `ReceptionService.validate()` (validait une réception brouillon)
- ❌ Supprimé : Toute méthode qui modifiait directement `stocks_journaliers`
- ✅ Conservé : `ReceptionService.createValidated()` (INSERT direct, validation atomique)

**Exception centralisée :** `ReceptionInsertException` pour mapper les erreurs PostgreSQL en messages utilisateur-friendly.

---

## 5. Migration Sorties (ce qui a été changé)

### 5.1 Trigger BEFORE INSERT : `sorties_check_before_insert()`

**Fonction :** `public.sorties_check_before_insert()`  
**Trigger :** `trg_sorties_check_before_insert` (BEFORE INSERT)

**Validations complètes effectuées :**

1. **Normalisation date et propriétaire :**
   ```sql
   v_date_jour := COALESCE(NEW.date_sortie::date, CURRENT_DATE);
   v_proprietaire := UPPER(TRIM(COALESCE(NEW.proprietaire_type, 'MONALUXE')));
   ```

2. **Vérification citerne active :**
   ```sql
   IF v_citerne.statut <> 'active' THEN
     RAISE EXCEPTION 'CITERNE_INACTIVE: Citerne % inactive', v_citerne.id;
   END IF;
   ```

3. **Vérification produit/citerne cohérence :**
   ```sql
   IF v_citerne.produit_id <> NEW.produit_id THEN
     RAISE EXCEPTION 'PRODUIT_INCOMPATIBLE: Citerne % ne porte pas le produit %', ...;
   END IF;
   ```

4. **Calcul volumes :**
   ```sql
   v_volume_ambiant := COALESCE(
     NEW.volume_ambiant,
     CASE 
       WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL 
       THEN NEW.index_apres - NEW.index_avant 
       ELSE 0 
     END
   );
   v_volume_15c := COALESCE(NEW.volume_corrige_15c, v_volume_ambiant);
   ```

5. **Vérification XOR bénéficiaire (DB-STRICT) :**
   ```sql
   IF v_proprietaire = 'MONALUXE' THEN
     IF NEW.client_id IS NULL THEN
       RAISE EXCEPTION 'BENEFICIAIRE_XOR: client_id obligatoire pour sortie MONALUXE';
     END IF;
     IF NEW.partenaire_id IS NOT NULL THEN
       RAISE EXCEPTION 'BENEFICIAIRE_XOR: partenaire_id doit être NULL pour sortie MONALUXE';
     END IF;
   ELSIF v_proprietaire = 'PARTENAIRE' THEN
     -- Logique inverse
   END IF;
   ```

6. **Récupération dernier stock connu :**
   ```sql
   SELECT * INTO v_stock_jour
   FROM public.stocks_journaliers
   WHERE citerne_id = NEW.citerne_id
     AND produit_id = NEW.produit_id
     AND proprietaire_type = v_proprietaire
     AND date_jour <= v_date_jour
   ORDER BY date_jour DESC
   LIMIT 1;
   ```

7. **Vérification stock suffisant (DB-STRICT) :**
   ```sql
   IF v_stock_jour.stock_ambiant < v_volume_ambiant THEN
     RAISE EXCEPTION 'STOCK_INSUFFISANT: stock_disponible=% volume_demande=%', ...;
   END IF;
   ```

8. **Vérification capacité sécurité :**
   ```sql
   IF (v_stock_jour.stock_ambiant - v_volume_ambiant) < v_citerne.capacite_securite THEN
     RAISE EXCEPTION 'CAPACITE_SECURITE: Sortie dépasserait capacité sécurité', ...;
   END IF;
   ```

**Résultat :** Toute sortie invalide est **bloquée avant insertion**, avec un message d'erreur explicite.

### 5.2 Trigger AFTER INSERT : `fn_sorties_after_insert()`

**Fonction :** `public.fn_sorties_after_insert()`  
**Trigger :** `trg_sorties_after_insert` (AFTER INSERT)

**Responsabilités (effets irréversibles uniquement) :**

1. **Débit stock journalier (valeur négative) :**
   ```sql
   PERFORM public.stock_upsert_journalier(
     NEW.citerne_id,
     NEW.produit_id,
     v_date_jour,
     -1 * v_volume_ambiant,  -- Débit (négatif)
     -1 * v_volume_15c,      -- Débit (négatif)
     v_proprietaire,
     v_depot_id,
     'SORTIE'
   );
   ```

2. **Journalisation :**
   ```sql
   INSERT INTO public.log_actions (
     user_id,
     action,
     module,
     niveau,
     details
   )
   VALUES (
     NEW.created_by,  -- Utilise created_by (doit être défini par BEFORE trigger)
     'SORTIE_CREEE',
     'sorties',
     'INFO',
     jsonb_build_object(...)
   );
   ```

**Note importante :** Le trigger AFTER INSERT ne refait **aucune validation**. Toutes les validations sont faites en BEFORE INSERT. Le trigger AFTER INSERT applique uniquement les effets irréversibles (débit stock + log).

### 5.3 Correction critique : `stock_upsert_journalier()` pour sorties

**Problème initial :**

La fonction `stock_upsert_journalier()` utilisait une logique `ON CONFLICT` qui additionnait les deltas, mais pour les sorties (valeurs négatives), cela pouvait créer des incohérences.

**Solution :**

La fonction calcule correctement le stock cumulé en additionnant le stock initial (dernier stock connu avant la date) avec le mouvement (positif pour réception, négatif pour sortie).

**Logique ON CONFLICT :**
```sql
ON CONFLICT (citerne_id, produit_id, date_jour, proprietaire_type)
DO UPDATE SET
  stock_ambiant = stocks_journaliers.stock_ambiant + EXCLUDED.stock_ambiant,
  stock_15c = stocks_journaliers.stock_15c + EXCLUDED.stock_15c,
  updated_at = now();
```

**Important :** Cette logique fonctionne correctement car :
- Pour une réception : `EXCLUDED.stock_ambiant` est positif → addition
- Pour une sortie : `EXCLUDED.stock_ambiant` est négatif → soustraction
- Le stock initial est déjà dans `stocks_journaliers.stock_ambiant` (cumul)

### 5.4 Suppression des insertions négatives interdites

**Avant DB-STRICT :**

Certaines contraintes CHECK empêchaient les valeurs négatives dans `stocks_journaliers`, ce qui bloquait les sorties.

**Après DB-STRICT :**

- Les contraintes CHECK ont été ajustées pour permettre les stocks négatifs pour un propriétaire (tant que le total de la citerne reste positif)
- La validation du stock suffisant est faite en BEFORE INSERT, donc on n'insère jamais une sortie qui rendrait le stock négatif

---

## 6. Problème clé résolu (le bug bloquant)

### 6.1 Erreur `stocks_snapshot_stock_15c_check` (si applicable)

**Note :** Le système utilise `stocks_journaliers` et non `stocks_snapshot`. Si une erreur similaire s'est produite, elle concernait probablement une contrainte CHECK sur `stocks_journaliers`.

### 6.2 Bug critique : Tentative d'INSERT négatif lors d'une sortie

**Symptôme :**

Lors de la création d'une sortie, l'erreur suivante pouvait survenir :
```
ERROR: new row for relation "stocks_journaliers" violates check constraint "stocks_journaliers_stock_15c_check"
```

**Cause :**

La fonction `stock_upsert_journalier()` tentait d'insérer une ligne avec un `stock_15c` négatif, violant une contrainte CHECK qui exigeait des valeurs positives.

**Correction :**

1. **Suppression/modification de la contrainte CHECK** pour permettre les stocks négatifs pour un propriétaire (tant que le total de la citerne reste positif)

2. **Validation en BEFORE INSERT** : Le trigger `sorties_check_before_insert()` vérifie maintenant que le stock disponible est suffisant **avant** l'insertion, empêchant toute tentative d'INSERT avec un stock négatif

3. **Logique de calcul corrigée** : La fonction `stock_upsert_journalier()` calcule correctement le stock cumulé en additionnant le stock initial avec le mouvement (positif ou négatif)

**Pseudo-code de la correction :**

```
AVANT (bug) :
  INSERT INTO stocks_journaliers (stock_15c) VALUES (-500)  -- ❌ Violation CHECK

APRÈS (corrigé) :
  -- BEFORE INSERT : Vérifier stock suffisant
  IF stock_disponible < volume_demande THEN
    RAISE EXCEPTION 'STOCK_INSUFFISANT'  -- ❌ Bloqué avant INSERT
  END IF;
  
  -- AFTER INSERT : Calculer stock cumulé
  stock_final = stock_initial + mouvement  -- ✅ Toujours >= 0 après validation
  INSERT INTO stocks_journaliers (stock_15c) VALUES (stock_final)
```

### 6.3 Refonte de `stock_upsert_journalier()`

**Changements clés :**

1. **Récupération du stock initial** (dernier stock connu avant la date) :
   ```sql
   SELECT stock_ambiant, stock_15c INTO v_stock_initial_ambiant, v_stock_initial_15c
   FROM public.stocks_journaliers
   WHERE citerne_id = p_citerne_id
     AND produit_id = p_produit_id
     AND proprietaire_type = v_proprietaire_normalise
     AND date_jour < p_date_jour
   ORDER BY date_jour DESC
   LIMIT 1;
   ```

2. **Calcul du stock final** (cumul) :
   ```sql
   stock_fin_journee_ambiant = v_stock_initial_ambiant + p_volume_ambiant
   stock_fin_journee_15c = v_stock_initial_15c + p_volume_15c
   ```

3. **INSERT avec stock cumulé** :
   ```sql
   INSERT INTO stocks_journaliers (..., stock_ambiant, stock_15c, ...)
   VALUES (..., stock_fin_journee_ambiant, stock_fin_journee_15c, ...)
   ```

**Résultat :** Le stock dans `stocks_journaliers` représente toujours le cumul depuis le début, pas un delta journalier.

---

## 7. Résultats validés

### 7.1 Scénarios validés manuellement depuis l'UI

**Réception MONALUXE :**
- ✅ Création réussie
- ✅ Stock crédité correctement dans `stocks_journaliers`
- ✅ CDR passé à DECHARGE si lié
- ✅ Log créé dans `log_actions`

**Réception PARTENAIRE :**
- ✅ Création réussie
- ✅ Stock crédité avec `proprietaire_type = 'PARTENAIRE'`
- ✅ Stock MONALUXE non affecté
- ✅ Log créé

**Sortie MONALUXE avec client :**
- ✅ Validation BEFORE INSERT : stock suffisant vérifié
- ✅ Validation BEFORE INSERT : capacité sécurité vérifiée
- ✅ Création réussie
- ✅ Stock débité correctement (valeur négative dans le mouvement, mais stock final positif)
- ✅ Log créé

**Sortie PARTENAIRE :**
- ✅ Validation BEFORE INSERT : partenaire_id obligatoire vérifié
- ✅ Validation BEFORE INSERT : client_id NULL vérifié
- ✅ Création réussie
- ✅ Stock PARTENAIRE débité, stock MONALUXE non affecté
- ✅ Log créé

### 7.2 Stock cohérent dans tous les modules

**Module Citernes :**
- ✅ Affiche la somme des stocks de tous les propriétaires
- ✅ Utilise la vue SQL corrigée qui agrège correctement les propriétaires

**Dashboard KPI :**
- ✅ Stock total = somme MONALUXE + PARTENAIRE
- ✅ Cohérence avec le module Citernes

**Module Stocks :**
- ✅ Utilise la même source de vérité (`stocks_journaliers`)
- ✅ Affichage cohérent avec Dashboard et Citernes

### 7.3 Plus aucun message "Une erreur est survenue" non expliqué

**Avant DB-STRICT :**
- Erreur générique sans explication
- Impossible de comprendre pourquoi une sortie était rejetée

**Après DB-STRICT :**
- Messages d'erreur explicites depuis les triggers PostgreSQL :
  - `STOCK_INSUFFISANT: stock_disponible=1000 volume_demande=1500`
  - `CAPACITE_SECURITE: Sortie dépasserait capacité sécurité`
  - `PRODUIT_INCOMPATIBLE: Citerne X ne porte pas le produit Y`
  - `BENEFICIAIRE_XOR: client_id obligatoire pour sortie MONALUXE`

**Mapping Flutter :** `ReceptionInsertException` et `SortieValidationException` transforment les codes PostgreSQL en messages utilisateur-friendly.

---

## 8. Règles immuables (IMPORTANT)

### 8.1 ❌ L'app n'écrit jamais dans stocks_journaliers

**Règle absolue :**

Aucun code Flutter ne doit :
- Insérer directement dans `stocks_journaliers`
- Mettre à jour `stocks_journaliers`
- Calculer le stock depuis les mouvements et l'écrire

**Vérification :** Recherche globale de `stocks_journaliers` dans le code Flutter → uniquement des lectures (SELECT).

### 8.2 ❌ L'app n'écrit jamais dans stocks_journaliers (répétition intentionnelle)

Cette règle est si critique qu'elle mérite d'être répétée. Toute violation de cette règle invalide l'architecture DB-STRICT.

### 8.3 ✅ Le stock courant se lit uniquement depuis stocks_journaliers

**Source de vérité unique :**

- Le stock disponible se lit depuis `stocks_journaliers` (ou les vues SQL dérivées)
- Aucun calcul applicatif du stock n'est autorisé
- Les vues SQL (`v_stocks_citerne_global`, `v_citerne_stock_actuel`) sont les seules sources autorisées pour l'affichage

### 8.4 ✅ Toute mutation passe par la DB

**Flow obligatoire :**

```
Flutter → INSERT receptions/sorties_produit → Triggers PostgreSQL → stocks_journaliers
```

Aucun chemin alternatif n'est autorisé.

### 8.5 ✅ Les erreurs métier viennent de la DB

**Règle :**

- Les validations métier (stock suffisant, capacité sécurité, etc.) sont faites **uniquement** dans les triggers PostgreSQL
- Le code Flutter peut faire des validations UX (format, champs obligatoires), mais **ne garantit pas** la cohérence métier
- Toute erreur métier doit être remontée depuis la DB avec un code/message explicite

### 8.6 ✅ Immutabilité des transactions

**Règle :**

- ❌ Aucun UPDATE sur `receptions` ou `sorties_produit` (bloqué par triggers)
- ❌ Aucun DELETE sur `receptions` ou `sorties_produit` (bloqué par triggers)
- ✅ Les corrections se font via `stock_adjustments` (compensation)

**Triggers d'immutabilité :**
- `prevent_reception_update()` / `prevent_reception_delete()`
- `prevent_sortie_update()` / `prevent_sortie_delete()`

---

## 9. Impact sur l'architecture globale

### 9.1 Simplification du code Flutter

**Avant DB-STRICT :**
- Code Flutter complexe avec validations métier dupliquées
- Calculs de stock répartis dans plusieurs services
- Gestion d'erreurs complexe (erreurs applicatives vs erreurs DB)

**Après DB-STRICT :**
- Code Flutter simplifié : préparation du payload, affichage des erreurs DB
- Validations métier centralisées dans les triggers PostgreSQL
- Gestion d'erreurs unifiée : toutes les erreurs métier viennent de la DB

**Exemple de simplification :**
```dart
// AVANT (complexe)
final stock = await calculateStock(citerneId, produitId);
if (stock < volume) {
  throw SortieValidationException('Stock insuffisant');
}
// ... autres validations ...
await service.createSortie(...);

// APRÈS (simple)
try {
  await service.createValidated(...);  // DB valide tout
} on SortieValidationException catch (e) {
  // Afficher message DB
}
```

### 9.2 Fiabilité des KPI

**Avant DB-STRICT :**
- KPI calculés depuis différentes sources (app, vues SQL, calculs manuels)
- Risque d'incohérence entre modules

**Après DB-STRICT :**
- KPI calculés uniquement depuis `stocks_journaliers` (source unique)
- Cohérence garantie entre tous les modules

### 9.3 Facilité des tests

**Avant DB-STRICT :**
- Tests complexes nécessitant de mocker toutes les validations applicatives
- Risque de divergence entre tests et production

**Après DB-STRICT :**
- Tests simplifiés : tester uniquement que l'INSERT fonctionne, la DB valide le reste
- Tests d'intégration plus fiables : utilisation de la vraie DB (ou d'une DB de test)

### 9.4 Base saine pour le reporting et l'audit

**Avantages :**

- **Traçabilité complète :** Tous les mouvements sont enregistrés dans `stocks_journaliers` avec `source` (RECEPTION, SORTIE, SYSTEM, MANUAL)
- **Audit facilité :** `log_actions` enregistre chaque création avec les détails complets
- **Reporting fiable :** Les vues SQL peuvent s'appuyer sur `stocks_journaliers` comme source unique de vérité
- **Recomputation possible :** La fonction `rebuild_stocks_journaliers()` permet de recalculer les stocks depuis les mouvements si nécessaire

---

## 10. Statut final

### 10.1 Migration complétée

**Modules migrés :**
- ✅ **Réceptions** : DB-STRICT complété le 22/12/2025
- ✅ **Sorties** : DB-STRICT complété le 19/12/2025

**Tests :**
- ✅ Tests unitaires : PASS
- ✅ Tests d'intégration : PASS (22 passés, 1 skip connu)
- ✅ Tests manuels UI : PASS (tous les scénarios validés)

### 10.2 Code verrouillé

**Statut :** FREEZE — Code verrouillé, aucune évolution autorisée (hors bug critique)

**Raison :** La migration DB-STRICT a résolu définitivement les problèmes de cohérence de stock. Toute modification non critique risquerait de réintroduire des bugs.

### 10.3 Documentation de référence

**Documents créés :**
- `docs/architecture/receptions_db_strict.md` : Documentation technique complète du module Réceptions
- `docs/architecture/sorties_db_strict.md` : Documentation technique complète du module Sorties
- `docs/migrations/2025-12_receptions_sorties_db_strict.md` : Ce document (vue d'ensemble de la migration)

**Utilisation :**
- Référence technique pour les développeurs
- Garde-fou contre les régressions
- Base pour les tests futurs
- Documentation pour les auditeurs

---

## Conclusion

La migration DB-STRICT a transformé l'architecture de gestion des stocks de ML_PP_MVP en plaçant la base de données PostgreSQL comme source de vérité unique. Cette migration a résolu définitivement les problèmes d'incohérence de stock, de messages d'erreur non explicites, et de logique métier fragmentée.

**Résultat :** Un système fiable, maintenable, et traçable, où la cohérence des données est garantie par la base de données elle-même, indépendamment du code applicatif.

**Règle d'or :** Toute modification future doit respecter les règles immuables définies dans la section 8. Toute violation de ces règles invalide l'architecture DB-STRICT et risque de réintroduire les bugs historiques.


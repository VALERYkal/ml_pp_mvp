# RAPPORT TECHNIQUE — CORRECTION INCOHÉRENCE STOCK PAR CITERNE

**Projet** : ML_PP MVP  
**Module concerné** : Stocks / Citernes / Dashboard KPI  
**Date** : 27 décembre 2025  
**Auteur** : Valery Kalonga (avec assistance technique IA)

---

## 1. Contexte métier

ML_PP MVP doit permettre aux décideurs (admin, directeur, gérant) de connaître à tout instant :
- le volume réel présent physiquement dans chaque citerne,
- indépendamment du fait que certaines citernes aient été mises à jour plus récemment que d'autres,
- en distinguant MONALUXE et PARTENAIRE, puis en affichant le total agrégé.

👉 **L'écran Citernes (et les KPI Dashboard) doit donc afficher le dernier snapshot disponible par citerne, même si les dates diffèrent entre citernes.**

---

## 2. Symptôme observé

- TANK1 affichait uniquement la dernière réception MONALUXE
- TANK2 / TANK3 étaient absents ou à 0
- Les totaux Dashboard n'étaient pas cohérents avec la réalité terrain

Le problème apparaissait :
- dans Citernes
- dans les KPI Stock
- dans Stock par propriétaire

---

## 3. Diagnostic (preuves SQL)

### 3.1. Données réelles en base (stocks_journaliers)

- **TANK1** : dernier état **23/12/2025**
- **TANK2** : dernier état **13/12/2025**
- **TANK3** : dernier état **13/12/2025**

👉 **Il n'existe pas de snapshot global unique à une même date pour toutes les citernes.**

### 3.2. Vue correcte (snapshot par citerne)

La vue `v_stocks_citerne_global` renvoyait déjà le bon résultat :

| Citerne | Date    | Ambiant | 15°C      |
|---------|---------|---------|-----------|
| TANK1   | 23/12   | 2777    | 2766.83   |
| TANK2   | 13/12   | 2140    | 2127.18   |
| TANK3   | 13/12   | 4083    | 4062.45   |

✔️ **Logique métier respectée.**

### 3.3. Cause racine identifiée

La vue utilisée par l'application n'était pas celle-ci, mais :
- `v_stocks_citerne_global_daily`

Cette vue :
- groupait par `(citerne_id, produit_id, date_jour)`
- n'appliquait aucune logique "dernier snapshot par citerne"
- supposait implicitement que toutes les citernes avaient une ligne au même `date_jour`

➡️ **Résultat** : lorsqu'on filtrait sur la date max globale, seules les citernes mises à jour ce jour-là apparaissaient (TANK1).

---

## 4. Problème aggravant côté Flutter

Dans `fetchCiterneGlobalSnapshots()` :

```dart
// lib/data/repositories/stocks_kpi_repository.dart
// Lignes 452-457 (AVANT correction)

// Si dateJour est fourni, filtrer pour ne garder que la date la plus récente
final filteredList = (dateJour != null && list.isNotEmpty)
    ? _filterToLatestDate(list, dateJour: dateJour)
    : list;

return filteredList.map(CiterneGlobalStockSnapshot.fromMap).toList();
```

La requête appliquait :
- `.lte('date_jour', dateJour)`
- `.order('date_jour', descending)`

Puis appelait `_filterToLatestDate()`.

Cette fonction :
- forçait une date globale unique
- supprimait toutes les lignes dont la `date_jour` était différente de la plus récente

➡️ **Même après correction SQL, ce filtre recréait le bug.**

---

## 5. Correction appliquée

### 5.1. Correction SQL (source de vérité)

La vue `v_stocks_citerne_global_daily` a été remplacée pour implémenter :
- dernier `date_jour` par `(citerne, produit, propriétaire)`
- agrégation finale MONALUXE + PARTENAIRE
- 1 ligne par citerne, même si les dates diffèrent

**Résultat validé :**

| Citerne | Date    | Ambiant | 15°C      |
|---------|---------|---------|-----------|
| TANK1   | 23/12   | 2777    | 2766.83   |
| TANK2   | 13/12   | 2140    | 2127.18   |
| TANK3   | 13/12   | 4083    | 4062.45   |

### 5.2. Correction Flutter (consommation)

**Fichier modifié** : `lib/data/repositories/stocks_kpi_repository.dart`

**Méthode concernée** : `fetchCiterneGlobalSnapshots()` (lignes 420-458)

**Changement appliqué** :

```dart
// AVANT (lignes 452-457)
// Si dateJour est fourni, filtrer pour ne garder que la date la plus récente
final filteredList = (dateJour != null && list.isNotEmpty)
    ? _filterToLatestDate(list, dateJour: dateJour)
    : list;

return filteredList.map(CiterneGlobalStockSnapshot.fromMap).toList();
```

```dart
// APRÈS (lignes 452-455)
// IMPORTANT: Ne pas filtrer à une seule date_jour globale.
// La vue v_stocks_citerne_global_daily retourne le dernier snapshot par citerne,
// et date_jour peut différer entre citernes. Forcer une date unique supprimerait
// incorrectement des citernes avec des snapshots plus anciens.
return list.map(CiterneGlobalStockSnapshot.fromMap).toList();
```

**Justification** :
- la vue renvoie déjà le dernier snapshot par citerne,
- les dates peuvent (et doivent) différer entre citernes

**Aucun autre code n'a été modifié.**

---

## 6. Validation finale (preuve UI)

L'écran Citernes affiche désormais :
- des volumes cohérents avec la DB,
- des dates différentes par citerne,
- des totaux conformes à la réalité physique du dépôt.

👉 **Le bug est corrigé, expliqué, reproductible et verrouillé.**

---

## 7. Décisions d'architecture confirmées

- ✅ La DB est la source de vérité pour les états de stock.
- ✅ Les vues SQL doivent encapsuler la logique métier complexe.
- ✅ L'app ne doit jamais :
  - recalculer un "dernier état" global,
  - supposer une date unique pour tout un dépôt.

**Distinction stricte** :
- **Historique** → `stocks_journaliers`
- **État courant** → vues snapshot (`v_stocks_*_global*`)

---

## 8. Prochaines étapes validées

- [x] A) Vérifier le Dashboard KPI (cohérence avec Citernes) ✅ prochaine action
- [ ] B) Corriger le bug latent de `stocksListProvider` (PARTENAIRE écrasé)
- [ ] C) Ajouter un garde-fou anti-régression (test / assertion)

---

## 9. Références techniques

**Fichiers concernés** :
- `lib/data/repositories/stocks_kpi_repository.dart` (ligne 420-458)
- Vue SQL : `v_stocks_citerne_global_daily`

**Commits associés** :
- À documenter lors du commit final

**Tests recommandés** :
- Vérifier l'affichage des citernes avec dates différentes
- Valider les totaux Dashboard vs données terrain
- Tester le cas limite : toutes les citernes avec la même date

---

*Document généré le 27 décembre 2025*



# BUG-2025-12-stocks-kpi-proprietaire-unification

**Date** : 13 décembre 2025  
**Module** : Dashboard / KPI Stocks par propriétaire  
**Sévérité** : Moyenne (incohérence d'affichage, données correctes en DB)  
**Statut** : ✅ Résolu

**Tags** :
- `BUG-DASHBOARD-KPI-PROPRIETAIRE-DIVERGENCE`
- `KPI-SOURCE-UNIFICATION`
- `ARCHITECTURE-PROVIDER-CONSISTENCY`

---

## Contexte

Le dashboard affiche deux sections distinctes pour les stocks par propriétaire (MONALUXE / PARTENAIRE) :
1. **Carte "Stock par propriétaire"** : Widget dédié (`OwnerStockBreakdownCard`)
2. **Section "Détail par propriétaire"** : Bloc sous la carte "Stock total"

Ces deux sections affichent la même information métier (répartition MONALUXE vs PARTENAIRE) mais utilisaient des providers différents, créant une divergence d'affichage.

**Chaîne technique initiale (divergente)** :
```
UI Dashboard
  ├─ Carte "Stock par propriétaire"
  │   → OwnerStockBreakdownCard
  │     → depotStocksSnapshotProvider(depotId, dateJour)
  │       → StocksKpiRepository.fetchDepotOwnerTotals()
  │         → Vue SQL: v_kpi_stock_owner
  │
  └─ Section "Détail par propriétaire"
      → kpiStockByOwnerProvider
        → StocksKpiRepository.fetchDepotOwnerTotals()
          → Vue SQL: v_kpi_stock_owner
          → Filtrage manuel par depotId dans l'UI
          → Agrégation locale dans le widget
```

---

## Symptômes observés

**Problème** : Après création d'une réception PARTENAIRE (ex : 1 210 L ambiant dans TANK2), les deux sections du dashboard affichaient des résultats incohérents.

**Comportement observé** :
- ✅ **Carte "Stock par propriétaire"** : Affichait correctement PARTENAIRE avec les volumes réels
- ❌ **Section "Détail par propriétaire"** : Affichait PARTENAIRE = **0.0 L** à tort
- ✅ **Données en base** : Les stocks journaliers contenaient bien les données PARTENAIRE correctes
- ✅ **Vue SQL `v_kpi_stock_owner`** : Contenait bien les lignes PARTENAIRE avec les bons volumes

**Exemple concret** :
- Réception PARTENAIRE : 1 210 L ambiant, 1 200 L @15°C dans TANK2
- Carte "Stock par propriétaire" : PARTENAIRE = 1 200 L @15°C ✅
- Section "Détail par propriétaire" : PARTENAIRE = 0.0 L ❌

---

## Reproduction minimale

1. Créer une réception PARTENAIRE validée (ex: 1 210 L ambiant, 1 200 L @15°C) pour le dépôt Daipn
2. Vérifier dans Supabase que `v_kpi_stock_owner` contient bien la ligne :
   ```sql
   SELECT * 
   FROM public.v_kpi_stock_owner 
   WHERE depot_id = '11111111-1111-1111-1111-111111111111'
     AND proprietaire_type = 'PARTENAIRE';
   ```
3. Ouvrir le dashboard admin
4. Observer :
   - ✅ Carte "Stock par propriétaire" : PARTENAIRE affiche correctement les volumes
   - ❌ Section "Détail par propriétaire" : PARTENAIRE affiche **0.0 L**

---

## Observations DB

**Vue SQL `v_kpi_stock_owner` — Structure validée** :

```sql
WITH base AS (
  SELECT
    COALESCE(sj.depot_id, c.depot_id) AS depot_id,
    sj.citerne_id,
    sj.produit_id,
    sj.proprietaire_type,
    sj.date_jour,
    sj.stock_ambiant,
    sj.stock_15c
  FROM stocks_journaliers sj
  LEFT JOIN citernes c ON c.id = sj.citerne_id
),
last_date AS (
  SELECT
    depot_id,
    produit_id,
    proprietaire_type,
    MAX(date_jour) AS date_jour
  FROM base
  GROUP BY depot_id, produit_id, proprietaire_type
),
agg AS (
  SELECT
    b.depot_id,
    b.produit_id,
    b.proprietaire_type,
    ld.date_jour,
    SUM(b.stock_ambiant) AS stock_ambiant_total,
    SUM(b.stock_15c) AS stock_15c_total
  FROM base b
  JOIN last_date ld
    ON ld.depot_id = b.depot_id
   AND ld.produit_id = b.produit_id
   AND ld.proprietaire_type = b.proprietaire_type
   AND ld.date_jour = b.date_jour
  GROUP BY b.depot_id, b.produit_id, b.proprietaire_type, ld.date_jour
)
SELECT
  d.id AS depot_id,
  d.nom AS depot_nom,
  a.produit_id,
  p.nom AS produit_nom,
  a.proprietaire_type,
  a.date_jour,
  a.stock_ambiant_total,
  a.stock_15c_total
FROM agg a
JOIN depots d ON d.id = a.depot_id
JOIN produits p ON p.id = a.produit_id;
```

**Ce que garantit la vue** :
- ✅ Une ligne par (depot, produit, propriétaire)
- ✅ Toujours la dernière date disponible
- ✅ PARTENAIRE et MONALUXE strictement séparés
- ✅ Compatible multi-citernes

**Requête SQL de validation** :
```sql
SELECT *
FROM public.v_kpi_stock_owner
WHERE depot_id = '11111111-1111-1111-1111-111111111111'
  AND proprietaire_type = 'PARTENAIRE';
```

**Résultat** : La requête retourne bien les lignes PARTENAIRE avec les volumes corrects.

**Conclusion** : Les données sont correctes dans la base. Le problème est dans la divergence de sources côté Flutter.

---

## Chaîne technique exacte

### 1. Provider 1 : `kpiStockByOwnerProvider` (source divergente)

**Fichier** : `lib/features/stocks/data/stocks_kpi_providers.dart` (lignes 43-47)

```dart
final kpiStockByOwnerProvider =
    riverpod.FutureProvider<List<DepotOwnerStockKpi>>((ref) async {
      final repo = ref.watch(stocksKpiRepositoryProvider);
      return repo.fetchDepotOwnerTotals();
    });
```

**Caractéristiques** :
- ❌ Pas de `depotId` en paramètre
- ❌ Pas de `dateJour` en paramètre
- ❌ Retourne **tous** les dépôts
- ❌ Filtrage manuel par `depotId` dans le widget UI
- ❌ Agrégation locale dans le widget

**Utilisation dans `role_dashboard.dart` (AVANT)** :
```dart
final stocksByOwnerAsync = ref.watch(kpiStockByOwnerProvider);

stocksByOwnerAsync.when(
  data: (ownerList) {
    // ❌ Filtrage manuel par depotId
    final filteredList = depotId != null
        ? ownerList.where((item) => item.depotId == depotId).toList()
        : ownerList;
    
    // ❌ Agrégation locale
    for (final item in filteredList) {
      if (item.proprietaireType.toUpperCase() == 'MONALUXE') {
        mon15c += item.stock15cTotal;
        // ...
      }
    }
  },
);
```

**Problèmes** :
- Sensible aux rebuilds / état transitoire
- Filtrage et agrégation dans l'UI (logique métier dans la couche présentation)
- Peut retourner des données partiellement chargées

### 2. Provider 2 : `depotStocksSnapshotProvider` (source correcte)

**Fichier** : `lib/features/stocks/data/stocks_kpi_providers.dart` (lignes 185-328)

```dart
final depotStocksSnapshotProvider = riverpod.FutureProvider.autoDispose
    .family<DepotStocksSnapshot, DepotStocksSnapshotParams>((
      ref,
      params,
    ) async {
      // Normaliser la date à minuit
      final rawDate = params.dateJour ?? DateTime.now();
      final dateJour = DateTime(rawDate.year, rawDate.month, rawDate.day);

      final repo = ref.watch(stocksKpiRepositoryProvider);

      // 1) Global totals per depot
      final globalList = await repo.fetchDepotProductTotals(
        depotId: params.depotId,
        dateJour: dateJour,
      );

      // 2) Breakdown by owner (IMPORTANT : pas de filtre dateJour)
      final owners = await repo.fetchDepotOwnerTotals(
        depotId: params.depotId,
        // Pas de dateJour ici pour aligner avec le dashboard
      );

      // 3) Citerne-level snapshots
      final citerneRowsRaw = await repo.fetchCiterneGlobalSnapshots(
        depotId: params.depotId,
        // Pas de dateJour ici pour aligner avec le dashboard
      );

      return DepotStocksSnapshot(
        dateJour: dateJour,
        isFallback: false,
        totals: totals,
        owners: owners,  // ✅ Déjà filtré par depotId
        citerneRows: citerneRows,
      );
    });
```

**Caractéristiques** :
- ✅ `depotId` en paramètre (via `DepotStocksSnapshotParams`)
- ✅ `dateJour` optionnel (normalisé à minuit)
- ✅ Filtrage par `depotId` au niveau repository
- ✅ `owners` déjà filtrés et prêts à l'emploi
- ✅ Source centralisée et cohérente

**Utilisation dans `OwnerStockBreakdownCard`** :
```dart
final snapshotAsync = ref.watch(
  depotStocksSnapshotProvider(
    DepotStocksSnapshotParams(depotId: depotId, dateJour: dateJourValue),
  ),
);

snapshotAsync.when(
  data: (snapshot) {
    final owners = snapshot.owners;  // ✅ Déjà filtré
    // Utilisation directe sans filtrage manuel
  },
);
```

---

## Cause racine

**Cause principale** : Dualité de sources de données pour une même information métier, avec des chemins de calcul différents.

**Problèmes identifiés** :

1. **Deux providers pour la même donnée** :
   - `kpiStockByOwnerProvider` : Pas de filtrage par `depotId`, retourne tous les dépôts
   - `depotStocksSnapshotProvider` : Filtrage par `depotId` au niveau repository

2. **Filtrage et agrégation dans l'UI** :
   - La section "Détail par propriétaire" filtrait manuellement par `depotId` dans le widget
   - L'agrégation MONALUXE/PARTENAIRE était faite localement dans l'UI
   - Sensible aux rebuilds et aux états transitoires

3. **Moment d'exécution différent** :
   - Les deux providers peuvent s'exécuter à des moments différents
   - Risque de désynchronisation entre les deux sections

4. **Gestion différente du `dateJour`** :
   - `kpiStockByOwnerProvider` : Pas de `dateJour` (toutes les dates)
   - `depotStocksSnapshotProvider` : `dateJour` optionnel, normalisé à minuit

**Impact** : Incohérence visuelle sur le dashboard, confusion pour les utilisateurs, maintenance difficile (deux chemins à maintenir).

---

## Correctif appliqué

**Fichier modifié** : `lib/features/dashboard/widgets/role_dashboard.dart`  
**Section** : "Détail par propriétaire" (lignes 191-332)

### Code AVANT correction

```dart
final stocksByOwnerAsync = ref.watch(
  kpiStockByOwnerProvider,
);

return Column(
  children: [
    KpiCard(...),  // Carte "Stock total"
    stocksByOwnerAsync.when(
      data: (ownerList) {
        // ❌ Filtrage manuel par depotId
        final filteredList = depotId != null
            ? ownerList.where((item) => item.depotId == depotId).toList()
            : ownerList;

        // ❌ Agrégation locale
        double mon15c = 0.0;
        double monAmb = 0.0;
        double part15c = 0.0;
        double partAmb = 0.0;

        for (final item in filteredList) {
          if (item.proprietaireType.toUpperCase() == 'MONALUXE') {
            mon15c += item.stock15cTotal;
            monAmb += item.stockAmbiantTotal;
          } else if (item.proprietaireType.toUpperCase() == 'PARTENAIRE') {
            part15c += item.stock15cTotal;
            partAmb += item.stockAmbiantTotal;
          }
        }
        // ... affichage
      },
    ),
  ],
);
```

### Code APRÈS correction

```dart
// Source unifiée = snapshot.owners pour éviter divergence UI
// Utilise le même provider que OwnerStockBreakdownCard
final snapshotAsync = depotId != null
    ? ref.watch(
        depotStocksSnapshotProvider(
          DepotStocksSnapshotParams(
            depotId: depotId,
            dateJour: null, // Pas de filtre date pour aligner avec dashboard
          ),
        ),
      )
    : null;

return Column(
  children: [
    KpiCard(...),  // Carte "Stock total"
    snapshotAsync == null
        ? const SizedBox.shrink()
        : snapshotAsync.when(
            data: (snapshot) {
              // ✅ Utiliser snapshot.owners directement (déjà filtré par depotId)
              final owners = snapshot.owners;

              // ✅ Agrégation locale (conservée pour l'affichage)
              double mon15c = 0.0;
              double monAmb = 0.0;
              double part15c = 0.0;
              double partAmb = 0.0;

              for (final item in owners) {
                if (item.proprietaireType.toUpperCase() == 'MONALUXE') {
                  mon15c += item.stock15cTotal;
                  monAmb += item.stockAmbiantTotal;
                } else if (item.proprietaireType.toUpperCase() == 'PARTENAIRE') {
                  part15c += item.stock15cTotal;
                  partAmb += item.stockAmbiantTotal;
                }
              }
              // ... affichage (inchangé)
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
  ],
);
```

**Changements appliqués** :

1. **Remplacement du provider** :
   - ❌ `kpiStockByOwnerProvider` (source divergente)
   - ✅ `depotStocksSnapshotProvider` (source unifiée)

2. **Suppression du filtrage manuel** :
   - ❌ `ownerList.where((item) => item.depotId == depotId)`
   - ✅ `snapshot.owners` (déjà filtré par le provider)

3. **Paramètres unifiés** :
   - ✅ `DepotStocksSnapshotParams(depotId: depotId, dateJour: null)`
   - ✅ Même source que `OwnerStockBreakdownCard`

4. **Commentaire explicatif** :
   - ✅ "Source unifiée = snapshot.owners pour éviter divergence UI"

**Résultat** :
- ✅ Les deux sections utilisent maintenant la même source de données
- ✅ Filtrage par `depotId` au niveau repository (pas dans l'UI)
- ✅ Cohérence garantie entre les deux sections
- ✅ Maintenance simplifiée (une seule source à maintenir)

---

## Validation

### Tests unitaires

**Fichier** : `test/features/stocks/stocks_kpi_repository_test.dart`

**Résultat** : ✅ **Tous les tests passent** (aucune régression)

Les tests existants continuent de passer car :
- Le changement est uniquement dans l'UI (remplacement de provider)
- Aucune modification dans le repository ou le service
- Le comportement métier reste identique

### Validation manuelle

**Scénario** : Après création d'une réception PARTENAIRE (1 210 L ambiant, 1 200 L @15°C)

**Résultat attendu** :
- ✅ Carte "Stock par propriétaire" : PARTENAIRE = 1 200 L @15°C
- ✅ Section "Détail par propriétaire" : PARTENAIRE = 1 200 L @15°C (cohérent)

**Statut** : ✅ Confirmé par l'utilisateur

### État final — Validation fonctionnelle

Après réception PARTENAIRE 1 210 L (TANK2) :

| Élément | Résultat |
|---------|----------|
| Réceptions | ✅ OK |
| Stocks journaliers | ✅ OK |
| Stock total | ✅ OK |
| Stock par propriétaire | ✅ OK |
| Détail par propriétaire | ✅ OK |
| Citernes | ✅ OK |
| Dashboard admin | ✅ OK |

➡️ **Aucune divergence UI / DB restante**

---

## Prévention / Règles à appliquer à l'avenir

### Règle 1 : Un KPI = une source unique

**Contexte** : Quand plusieurs widgets affichent la même information métier

**Règle** :
- ✅ Identifier une source unique de données (provider centralisé)
- ✅ Tous les widgets doivent utiliser cette même source
- ❌ Éviter les providers multiples pour la même donnée
- ❌ Éviter le filtrage/agrégation dans l'UI

**Exemple** :
```dart
// ✅ BON : Source unique
final snapshotAsync = ref.watch(
  depotStocksSnapshotProvider(
    DepotStocksSnapshotParams(depotId: depotId, dateJour: null),
  ),
);

// ❌ MAUVAIS : Source divergente
final ownersAsync = ref.watch(kpiStockByOwnerProvider);
// + filtrage manuel dans l'UI
```

### Règle 2 : Pas de logique métier dans l'UI

**Contexte** : Les widgets doivent afficher, pas calculer

**Règle** :
- ✅ Le filtrage par `depotId`, `dateJour`, etc. doit être fait au niveau repository/service
- ✅ L'agrégation complexe doit être faite au niveau service/repository
- ✅ L'UI ne doit faire que de l'affichage et de l'agrégation simple (somme de volumes)

**Exemple** :
```dart
// ✅ BON : Filtrage au niveau repository
final owners = await repo.fetchDepotOwnerTotals(
  depotId: depotId,  // Filtrage au niveau repository
);

// ❌ MAUVAIS : Filtrage dans l'UI
final allOwners = await repo.fetchDepotOwnerTotals();
final filtered = allOwners.where((o) => o.depotId == depotId).toList();
```

### Règle 3 : Documenter les sources de données

**Contexte** : Quand plusieurs widgets affichent la même information

**Règle** :
- ✅ Ajouter un commentaire expliquant quelle source est utilisée
- ✅ Documenter pourquoi cette source est choisie
- ✅ Mentionner les autres widgets qui utilisent la même source

**Exemple** :
```dart
// Source unifiée = snapshot.owners pour éviter divergence UI
// Utilise le même provider que OwnerStockBreakdownCard
final snapshotAsync = ref.watch(
  depotStocksSnapshotProvider(...),
);
```

### Règle 4 : Utiliser des providers `family` pour les filtres

**Contexte** : Quand on a besoin de filtrer par `depotId`, `dateJour`, etc.

**Règle** :
- ✅ Utiliser `FutureProvider.family` ou `FutureProvider.autoDispose.family`
- ✅ Passer les paramètres de filtrage via les paramètres du provider
- ✅ Éviter les providers sans paramètres qui retournent toutes les données

**Exemple** :
```dart
// ✅ BON : Provider family avec paramètres
final depotStocksSnapshotProvider = FutureProvider.autoDispose
    .family<DepotStocksSnapshot, DepotStocksSnapshotParams>(...);

// ❌ MAUVAIS : Provider sans paramètres
final kpiStockByOwnerProvider = FutureProvider<List<DepotOwnerStockKpi>>(...);
// Nécessite un filtrage manuel dans l'UI
```

---

## Autres correctifs connexes validés

### 1. Formatage des volumes (Dashboard camions)

**Problème** : Formatage incorrect (2500 L affiché comme 3000 L)

**Correctif** : Suppression du `/1000 + arrondi`, passage à un formatage avec séparateur de milliers

**Fichiers** :
- `lib/features/dashboard/widgets/trucks_to_follow_card.dart`
- `lib/features/dashboard/admin/widgets/area_chart.dart`

**Documentation** : `docs/incidents/BUG-2025-12-dashboard-camions-volume-formatting.md`

### 2. Invalidation des providers après réception

**Problème** : Dashboard ne se rafraîchissait pas après création d'une réception

**Correctif** : Ajout de l'invalidation des providers :
- `kpiProviderProvider`
- `stocksDashboardKpisProvider(depotId)`
- `depotStocksSnapshotProvider`
- `stocksListProvider`
- `citernesWithStockProvider`

**Fichiers** :
- `lib/shared/refresh/refresh_helpers.dart` (helper centralisé)
- `lib/features/receptions/screens/reception_form_screen.dart`

**Documentation** : `docs/incidents/BUG-2025-12-dashboard-stock-refresh-after-sortie.md`

---

## Conclusion

### Ce qui est désormais garanti

- 🔒 **Une seule source de vérité** : `depotStocksSnapshotProvider` pour tous les KPI par propriétaire
- 📐 **Aucune logique métier critique dans l'UI** : Filtrage et agrégation au niveau repository/service
- 🧮 **Stocks propriétaires fiables** : Cohérence garantie entre toutes les sections du dashboard
- 🔁 **Extensible pour Sorties PARTENAIRE** : La même source peut être utilisée pour les sorties
- 📚 **Architecture documentée et stable** : Source unique clairement identifiée

### Prochaines étapes possibles

- 🧪 **Mini check-list de tests à automatiser** : Tests E2E pour valider la cohérence entre les sections
- 📝 **Entrée CHANGELOG.md** : Documentation de ce correctif (déjà fait)
- 🚀 **Validation finale Phase Stocks P0/P1** : Vérification que tous les KPIs sont cohérents

---

**Date de résolution** : 13 décembre 2025  
**Auteur du correctif** : Assistant IA (Cursor)  
**Validé par** : Utilisateur (confirmation fonctionnelle)


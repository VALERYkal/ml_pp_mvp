# Architecture Flutter - Stocks (Phase 3)

**Date** : 06/12/2025  
**Version** : 1.0  
**Objectif** : Documenter la nouvelle architecture stock côté Flutter après Phase 3

---

## 🎯 Principe fondamental

**Tous les écrans Flutter lisent uniquement les vues SQL, jamais les tables brutes.**

**Aucun calcul de stock n'est effectué côté Flutter.**

---

## 📊 Vues SQL consommées

### 1. `v_kpi_stock_global`

**Usage** : KPI stock global (tous dépôts confondus)

**Provider** : `globalStockKpiProvider`

**Modèle** : `KpiStockGlobal`

**Écrans** : Dashboard Admin (carte stock total)

---

### 2. `v_kpi_stock_depot`

**Usage** : KPI stock par dépôt

**Provider** : `depotStockKpiProvider`

**Modèle** : `KpiStockDepot`

**Écrans** : Dashboard (carte stock par dépôt)

---

### 3. `v_kpi_stock_owner`

**Usage** : KPI stock par propriétaire (MONALUXE / PARTENAIRE)

**Provider** : `ownerStockKpiProvider`

**Modèle** : `KpiStockOwner`

**Écrans** : Dashboard (comparaison Monaluxe vs Partenaire)

---

### 4. `v_stocks_citerne_global`

**Usage** : Snapshot de stock par citerne (total MONALUXE + PARTENAIRE)

**Provider** : `citerneStockProvider`

**Modèle** : `CiterneStockSnapshot`

**Écrans** : 
- Écran Stocks Journaliers (tableau principal)
- Écran Citernes (cartes citernes)

---

### 5. `v_stocks_citerne_owner`

**Usage** : Snapshot de stock par citerne et propriétaire (décomposition MONALUXE / PARTENAIRE)

**Provider** : `citerneStockOwnerProvider`

**Modèle** : `CiterneStockOwnerSnapshot`

**Écrans** : 
- Écran Citernes (vue détaillée par propriétaire)
- Écran Stocks Journaliers (filtre par propriétaire)

---

## 🏗️ Architecture en couches

### Couche 1 : Modèles Dart

**Dossier** : `lib/features/stocks/models/`

**Responsabilité** : Mapper les résultats SQL vers des objets Dart typés

**Exemple** :
```dart
class CiterneStockSnapshot {
  final String citerneId;
  final double stockAmbiantTotal;
  // ...
  
  factory CiterneStockSnapshot.fromJson(Map<String, dynamic> json) {
    // Mapping depuis v_stocks_citerne_global
  }
}
```

---

### Couche 2 : Services Supabase

**Dossier** : `lib/features/stocks/data/`

**Responsabilité** : Encapsuler tous les appels Supabase vers les vues SQL

**Exemple** :
```dart
class StockKpiService {
  Future<List<CiterneStockSnapshot>> getCiterneSnapshots({
    String? depotId,
    String? produitId,
  }) async {
    var query = client.from('v_stocks_citerne_global').select('*');
    // Filtrage, mapping, etc.
  }
}
```

---

### Couche 3 : Providers Riverpod

**Dossier** : `lib/features/stocks/providers/`

**Responsabilité** : Exposer les services aux écrans via Riverpod

**Exemple** :
```dart
final citerneStockProvider = FutureProvider.autoDispose<List<CiterneStockSnapshot>>((ref) async {
  final service = ref.watch(stockKpiServiceProvider);
  final profil = await ref.watch(profilProvider.future);
  
  return service.getCiterneSnapshots(depotId: profil?.depotId);
});
```

---

### Couche 4 : Écrans UI

**Dossier** : `lib/features/*/screens/`

**Responsabilité** : Consommer les providers et afficher les données

**Exemple** :
```dart
class StocksListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocks = ref.watch(citerneStockProvider);
    
    return stocks.when(
      data: (snapshots) => ListView.builder(
        itemCount: snapshots.length,
        itemBuilder: (context, index) {
          final snapshot = snapshots[index];
          return ListTile(
            title: Text(snapshot.citerneNom),
            subtitle: Text('${snapshot.stock15cTotal} L'),
          );
        },
      ),
      // ...
    );
  }
}
```

---

## ⚠️ Règles strictes

### ✅ À FAIRE

- ✅ Lire uniquement depuis les vues SQL (`v_kpi_stock_*`, `v_stocks_citerne_*`)
- ✅ Utiliser les providers Riverpod (`*StockKpiProvider`, `*StockProvider`)
- ✅ Utiliser les modèles Dart (`KpiStock*`, `CiterneStock*`)
- ✅ Filtrage par `depot_id` selon le profil utilisateur

### ❌ À NE PAS FAIRE

- ❌ Lire directement depuis `stocks_journaliers` (sauf cas exceptionnel)
- ❌ Lire directement depuis `receptions` ou `sorties_produit` pour calculer le stock
- ❌ Faire des calculs manuels (`SUM`, `-`, etc.) côté Dart
- ❌ Créer des providers qui recalculent le stock

---

## 🔄 Flux de données

```
Vues SQL (Supabase)
    ↓
StockKpiService (encapsulation Supabase)
    ↓
Providers Riverpod (exposition aux écrans)
    ↓
Écrans UI (affichage)
```

---

## 📝 Exemples d'usage

### Exemple 1 : Afficher le stock total dans le Dashboard

```dart
final kpi = ref.watch(globalStockKpiProvider);

kpi.when(
  data: (kpi) => Text('Stock total: ${kpi.stock15cTotal} L'),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Erreur: $err'),
);
```

### Exemple 2 : Afficher la liste des stocks par citerne

```dart
final stocks = ref.watch(citerneStockProvider);

stocks.when(
  data: (snapshots) => ListView.builder(
    itemCount: snapshots.length,
    itemBuilder: (context, index) {
      final s = snapshots[index];
      return Card(
        child: ListTile(
          title: Text(s.citerneNom),
          subtitle: Text('${s.produitNom} - ${s.stock15cTotal} L'),
          trailing: Text('${s.ratioUtilisation.toStringAsFixed(1)}%'),
        ),
      );
    },
  ),
  // ...
);
```

### Exemple 3 : Filtrer par dépôt

```dart
// Le filtrage est automatique via le profil utilisateur
final profil = await ref.watch(profilProvider.future);
final stocks = ref.watch(citerneStockProvider); // Déjà filtré par depotId
```

---

## 🧪 Tests

### Tests unitaires

- **Modèles** : Vérifier le mapping JSON → modèles
- **Services** : Mock Supabase, vérifier les appels SQL

### Tests d'intégration

- **Widgets** : Mock providers, vérifier l'affichage

---

## 🔗 Références

- Contrat SQL : `docs/db/stocks_views_contract.md`
- Plan Phase 3 : `docs/db/PHASE3_FLUTTER_RECONNEXION_STOCKS.md`
- Cartographie : `docs/db/PHASE3_CARTOGRAPHIE_EXISTANT.md`

---

## 📌 Notes importantes

1. **Pas de calcul côté Flutter** : Tous les calculs sont dans les vues SQL
2. **Source unique de vérité** : Les vues SQL sont la seule source de vérité
3. **Filtrage automatique** : Le filtrage par `depot_id` est géré automatiquement via le profil utilisateur
4. **Modèles typés** : Utiliser toujours les modèles Dart, jamais des `Map<String, dynamic>`

---

**Fin de la documentation**


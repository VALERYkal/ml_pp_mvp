# Guide d'implémentation - Phase 2 : Unification Flutter Stocks

**Date** : 06/12/2025  
**Prérequis** : Phase 1 complétée ✅

---

## 🎯 Vue d'ensemble

Ce guide fournit les étapes pratiques pour implémenter la Phase 2 : rebrancher toute l'app Flutter sur la vérité unique Stock.

**Objectif** : Tous les écrans et KPIs lisent depuis `v_stocks_citerne_global` via un service unique.

---

## 📋 Checklist rapide

- [ ] Étape 2.1 : Contrat SQL figé
- [ ] Étape 2.2 : Service Flutter créé
- [ ] Étape 2.3 : Module Citernes rebranché
- [ ] Étape 2.4 : Module Stocks rebranché
- [ ] Étape 2.5 : KPIs Dashboard rebranchés
- [ ] Étape 2.6 : Réceptions/Sorties harmonisées
- [ ] Étape 2.7 : Tests créés

---

## 🔹 Étape 2.1 — Figer le contrat SQL

### Actions

1. **Vérifier que `v_stocks_citerne_global` existe** :
   ```sql
   SELECT * FROM public.v_stocks_citerne_global LIMIT 5;
   ```

2. **Créer les vues KPI si nécessaire** :
   - `v_kpi_stock_depot` (si KPIs Dashboard nécessitent agrégation par dépôt)
   - `v_kpi_stock_proprietaire_global` (si comparaison Monaluxe vs Partenaire globale)

3. **Documenter dans `docs/db/stocks_views_contract.md`** :
   - Colonnes de chaque vue
   - Exemples d'usage
   - Garanties de stabilité

### Validation

- [ ] Vue `v_stocks_citerne_global` retourne des données cohérentes
- [ ] Documentation complète dans `stocks_views_contract.md`
- [ ] Exemples SQL fonctionnent

---

## 🔹 Étape 2.2 — Créer le service Flutter unique

### Structure proposée

```
lib/features/stocks/
├── data/
│   └── stock_service.dart          # Service principal
├── models/
│   └── stock_model.dart            # DTOs
└── providers/
    └── stock_providers.dart        # Providers Riverpod
```

### Code à créer

#### 1. Modèle `StockModel`

```dart
// lib/features/stocks/models/stock_model.dart
class StockCiterne {
  final String citerneId;
  final String citerneNom;
  final String produitId;
  final String produitNom;
  final double stockAmbiantTotal;
  final double stock15cTotal;
  final double stockAmbiantMonaluxe;
  final double stock15cMonaluxe;
  final double stockAmbiantPartenaire;
  final double stock15cPartenaire;
  final double capaciteTotale;
  final double capaciteSecurite;
  final double ratioUtilisation;
  final String? depotId;
  final String? depotNom;
  final DateTime? dateDernierMouvement;

  StockCiterne({
    required this.citerneId,
    required this.citerneNom,
    required this.produitId,
    required this.produitNom,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
    required this.stockAmbiantMonaluxe,
    required this.stock15cMonaluxe,
    required this.stockAmbiantPartenaire,
    required this.stock15cPartenaire,
    required this.capaciteTotale,
    required this.capaciteSecurite,
    required this.ratioUtilisation,
    this.depotId,
    this.depotNom,
    this.dateDernierMouvement,
  });

  factory StockCiterne.fromJson(Map<String, dynamic> json) {
    // Mapping depuis v_stocks_citerne_global
  }
}
```

#### 2. Service `StockService`

```dart
// lib/features/stocks/data/stock_service.dart
class StockService {
  final SupabaseClient client;

  StockService(this.client);

  /// Récupère tous les stocks par citerne
  Future<List<StockCiterne>> getStocksParCiterne({
    String? depotId,
    String? produitId,
  }) async {
    var query = client.from('v_stocks_citerne_global').select('*');
    
    if (depotId != null) {
      query = query.eq('depot_id', depotId);
    }
    if (produitId != null) {
      query = query.eq('produit_id', produitId);
    }
    
    final res = await query;
    return (res as List)
        .map((e) => StockCiterne.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Récupère le stock d'une citerne spécifique
  Future<StockCiterne?> getStockCiterne(String citerneId) async {
    final res = await client
        .from('v_stocks_citerne_global')
        .select('*')
        .eq('citerne_id', citerneId)
        .maybeSingle();
    
    if (res == null) return null;
    return StockCiterne.fromJson(res as Map<String, dynamic>);
  }

  /// Récupère les stocks journaliers pour une date
  Future<List<StockJournalier>> getStocksParDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final res = await client
        .from('stocks_journaliers')
        .select('*')
        .eq('date_jour', dateStr)
        .order('citerne_id');
    
    return (res as List)
        .map((e) => StockJournalier.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

#### 3. Providers Riverpod

```dart
// lib/features/stocks/providers/stock_providers.dart
final stockServiceProvider = Provider<StockService>((ref) {
  return StockService(Supabase.instance.client);
});

final stocksParCiterneProvider = FutureProvider.autoDispose<List<StockCiterne>>((ref) async {
  final service = ref.watch(stockServiceProvider);
  final profil = await ref.watch(profilProvider.future);
  
  return service.getStocksParCiterne(
    depotId: profil?.depotId,
  );
});

final stockCiterneProvider = FutureProvider.autoDispose.family<StockCiterne?, String>((ref, citerneId) async {
  final service = ref.watch(stockServiceProvider);
  return service.getStockCiterne(citerneId);
});
```

### Validation

- [ ] `StockService` créé avec toutes les méthodes
- [ ] Providers Riverpod créés
- [ ] Tests unitaires basiques passent

---

## 🔹 Étape 2.3 — Rebrancher le module Citernes

### Fichiers à modifier

1. **`lib/features/citernes/providers/citerne_providers.dart`**

   **AVANT** (exemple) :
   ```dart
   final citernesWithStockProvider = FutureProvider<List<CiterneRow>>((ref) async {
     // Ancienne logique qui lit depuis stock_actuel ou recalcule
   });
   ```

   **APRÈS** :
   ```dart
   final citernesWithStockProvider = FutureProvider<List<CiterneRow>>((ref) async {
     final stocks = await ref.watch(stocksParCiterneProvider.future);
     
     // Mapper StockCiterne → CiterneRow
     return stocks.map((stock) => CiterneRow(
       id: stock.citerneId,
       nom: stock.citerneNom,
       produitId: stock.produitId,
       capaciteTotale: stock.capaciteTotale,
       capaciteSecurite: stock.capaciteSecurite,
       stockAmbiant: stock.stockAmbiantTotal,
       stock15c: stock.stock15cTotal,
       dateStock: stock.dateDernierMouvement,
     )).toList();
   });
   ```

2. **Vérifier les écrans** :
   - `CiterneListScreen` : doit afficher les valeurs de `stocksParCiterneProvider`
   - Widget dashboard citernes : doit utiliser `stocksParCiterneProvider`

### Validation

- [ ] `CiterneListScreen` affiche les mêmes valeurs que la vue SQL
- [ ] Vérification manuelle : TANK1 et TANK2 affichent les bons chiffres
- [ ] Pas de régression visuelle

---

## 🔹 Étape 2.4 — Rebrancher le module Stocks

### Fichiers à modifier

1. **`lib/features/stocks_journaliers/providers/stocks_providers.dart`**

   **AVANT** :
   ```dart
   // Logique qui lit depuis stocks_journaliers avec jointures manuelles
   ```

   **APRÈS** :
   ```dart
   final stocksListProvider = FutureProvider.autoDispose<StocksDataWithMeta>((ref) async {
     final date = ref.watch(stocksSelectedDateProvider);
     final service = ref.watch(stockServiceProvider);
     
     // Utiliser directement StockService.getStocksParDate()
     final stocks = await service.getStocksParDate(date);
     
     // Mapper vers StocksDataWithMeta
     return StocksDataWithMeta(
       stocks: stocks.map((s) => StockRowVM.fromStockJournalier(s)).toList(),
       // ...
     );
   });
   ```

2. **Supprimer toute logique de calcul** :
   - Plus de `sum(receptions) - sum(sorties)` côté Dart
   - Tout vient directement de `stocks_journaliers`

### Validation

- [ ] `StocksListScreen` affiche les données depuis `stocks_journaliers`
- [ ] Filtres (dépôt, produit, propriétaire) fonctionnent
- [ ] Pas de calcul côté Dart

---

## 🔹 Étape 2.5 — Rebrancher les KPIs Dashboard

### Fichiers à modifier

1. **Créer `lib/features/kpi/models/stock_kpi_model.dart`** :
   ```dart
   class StockKpiModel {
     final double stockTotalAmbiant;
     final double stockTotal15c;
     final double stockMonaluxeAmbiant;
     final double stockMonaluxe15c;
     final double stockPartenaireAmbiant;
     final double stockPartenaire15c;
     final int nbCiternes;
     final int nbCiternesSousSeuil;
     // ...
   }
   ```

2. **Créer `lib/features/kpi/providers/stock_kpi_provider.dart`** :
   ```dart
   final kpiStockProvider = FutureProvider.autoDispose<StockKpiModel>((ref) async {
     final stocks = await ref.watch(stocksParCiterneProvider.future);
     final profil = await ref.watch(profilProvider.future);
     
     // Agréger depuis v_stocks_citerne_global
     final totalAmbiant = stocks.fold<double>(0, (sum, s) => sum + s.stockAmbiantTotal);
     final total15c = stocks.fold<double>(0, (sum, s) => sum + s.stock15cTotal);
     // ...
     
     return StockKpiModel(
       stockTotalAmbiant: totalAmbiant,
       stockTotal15c: total15c,
       // ...
     );
   });
   ```

3. **Modifier les providers Dashboard** :
   - `admin_kpi_provider.dart` : utiliser `kpiStockProvider`
   - `directeur_kpi_provider.dart` : utiliser `kpiStockProvider`
   - Supprimer toute logique de calcul manuel

### Validation

- [ ] Toutes les cartes Dashboard utilisent `kpiStockProvider`
- [ ] Les valeurs affichées correspondent à la vue SQL
- [ ] Pas de calcul manuel dans les widgets

---

## 🔹 Étape 2.6 — Harmonisation Réceptions/Sorties

### Fichiers à vérifier/modifier

1. **`lib/features/receptions/screens/reception_screen.dart`** :
   - Si affiche un stock actuel → utiliser `stockCiterneProvider(citerneId)`

2. **`lib/features/sorties/screens/sortie_detail_screen.dart`** :
   - Si affiche un stock actuel → utiliser `stockCiterneProvider(citerneId)`

### Validation

- [ ] Cohérence vérifiée avec les autres écrans
- [ ] Même source de données partout

---

## 🔹 Étape 2.7 — Tests et garde-fous

### Script SQL de validation

Exécuter `scripts/validate_stocks.sql` après chaque modification importante.

### Tests Dart

1. **Tests unitaires `StockService`** :
   ```dart
   test('getStocksParCiterne retourne les bonnes données', () async {
     // Mock Supabase
     // Vérifier le mapping JSON → StockCiterne
   });
   ```

2. **Tests widget Dashboard** :
   ```dart
   testWidgets('Dashboard affiche les KPIs stock correctement', (tester) async {
     // Mock kpiStockProvider
     // Vérifier l'affichage
   });
   ```

### Page debug (optionnel)

Créer `lib/features/stocks/screens/stocks_debug_screen.dart` :
- Affiche les valeurs brutes de `v_stocks_citerne_global`
- Permet de comparer avec Supabase Dashboard

---

## ✅ Critères de succès Phase 2

- ✅ Tous les écrans lisent depuis `v_stocks_citerne_global` ou `stocks_journaliers`
- ✅ Service unique `StockService` utilisé partout
- ✅ Aucune logique de calcul côté Dart (tout dans SQL)
- ✅ KPIs cohérents dans tous les dashboards
- ✅ Tests créés et passent
- ✅ Script de validation SQL fonctionne

---

## 🔗 Références

- Plan détaillé : `docs/db/PHASE2_STOCKS_UNIFICATION_FLUTTER.md`
- Contrat SQL : `docs/db/stocks_views_contract.md`
- Script validation : `scripts/validate_stocks.sql`
- Phase 1 : `docs/rapports/PHASE1_STOCKS_STABILISATION_2025-12-06.md`

